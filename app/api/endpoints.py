from datetime import datetime

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import RedirectResponse
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session

from app.core.jwt_connections import (
    create_access_token,
    get_current_admin,
    get_current_user_id,
    hash_password,
    verify_password,
)
from app.db.sql_connections import Document, User, get_db
from app.services.minio_connection import (
    delete_pdf,
    delete_pdfs,
    get_presigned_url,
    upload_pdf,
)
from app.services.pdf_validator import validate_pdf
from app.services.rabbitmq_connection import enqueue_pdf

router = APIRouter()


# ================================================================
# Schemas
# ================================================================

class RegisterRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class CategoryOut(BaseModel):
    category: str
    score: int

    model_config = {"from_attributes": True}


class DocumentOut(BaseModel):
    id: int
    filename: str
    uploaded_at: datetime
    title: str | None
    authors: str | None
    year: int | None
    journal: str | None
    categories: list[CategoryOut] = []

    model_config = {"from_attributes": True}


class UserOut(BaseModel):
    id: int
    username: str
    is_admin: bool

    model_config = {"from_attributes": True}


class UpdateUserRequest(BaseModel):
    username: str | None = None
    password: str | None = None


class DocumentIdsRequest(BaseModel):
    document_ids: list[int]


# ================================================================
# Auth
# ================================================================

@router.post("/auth/register", status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="El usuario ya existe")
    user = User(username=body.username, password_hash=hash_password(body.password))
    db.add(user)
    db.commit()
    return {"message": "Usuario registrado"}


@router.post("/auth/login", response_model=TokenResponse)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == form.username).first()
    if not user or not verify_password(form.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    token = create_access_token(user.id, user.is_admin)
    return TokenResponse(access_token=token)


# ================================================================
# Documentos — usuario común
# ================================================================

@router.post("/documents", status_code=status.HTTP_201_CREATED)
def upload_document(
    file: UploadFile = File(...),
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    if file.content_type != "application/pdf":
        raise HTTPException(status_code=400, detail="Solo se aceptan archivos PDF")

    data = file.file.read()
    validate_pdf(data)
    object_key = upload_pdf(user_id=user_id, filename=file.filename, data=data)

    doc = Document(user_id=user_id, filename=file.filename, object_key=object_key)
    db.add(doc)
    db.commit()
    db.refresh(doc)

    enqueue_pdf(document_id=doc.id, object_key=object_key)

    return {"id": doc.id, "filename": doc.filename, "object_key": object_key}


@router.get("/documents", response_model=list[DocumentOut])
def list_documents(
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    return db.query(Document).filter(Document.user_id == user_id).all()


@router.get("/documents/{document_id}/download")
def download_document(
    document_id: int,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    doc = _get_own_document(document_id, user_id, db)
    url = get_presigned_url(doc.object_key)
    return RedirectResponse(url)


@router.delete("/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(
    document_id: int,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    doc = _get_own_document(document_id, user_id, db)
    delete_pdf(doc.object_key)
    db.delete(doc)
    db.commit()


@router.post("/documents/delete-batch", status_code=status.HTTP_204_NO_CONTENT)
def delete_documents_batch(
    body: DocumentIdsRequest,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    docs = (
        db.query(Document)
        .filter(Document.id.in_(body.document_ids), Document.user_id == user_id)
        .all()
    )
    if len(docs) != len(body.document_ids):
        raise HTTPException(status_code=404, detail="Uno o más documentos no encontrados")
    delete_pdfs([d.object_key for d in docs])
    for doc in docs:
        db.delete(doc)
    db.commit()


# ================================================================
# Citas APA7
# ================================================================

@router.post("/documents/apa7")
def generate_apa7(
    body: DocumentIdsRequest,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    docs = (
        db.query(Document)
        .filter(Document.id.in_(body.document_ids), Document.user_id == user_id)
        .all()
    )
    if not docs:
        raise HTTPException(status_code=404, detail="Documentos no encontrados")
    return {"citations": [_format_apa7(d) for d in docs]}


# ================================================================
# Admin
# ================================================================

@router.get("/admin/users", response_model=list[UserOut])
def list_users(_: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    return db.query(User).all()


@router.delete("/admin/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    _: int = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    # Los documentos en MinIO se eliminan en cascada por la relación ORM
    keys = [d.object_key for d in user.documents]
    if keys:
        delete_pdfs(keys)
    db.delete(user)
    db.commit()


@router.patch("/admin/users/{user_id}", response_model=UserOut)
def update_user(
    user_id: int,
    body: UpdateUserRequest,
    _: int = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if body.username:
        user.username = body.username
    if body.password:
        user.password_hash = hash_password(body.password)
    db.commit()
    db.refresh(user)
    return user


@router.delete("/admin/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete_document(
    document_id: int,
    _: int = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    doc = db.query(Document).filter(Document.id == document_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Documento no encontrado")
    delete_pdf(doc.object_key)
    db.delete(doc)
    db.commit()


# ================================================================
# Helpers
# ================================================================

def _get_own_document(document_id: int, user_id: int, db: Session) -> Document:
    doc = db.query(Document).filter(
        Document.id == document_id,
        Document.user_id == user_id,
    ).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Documento no encontrado")
    return doc


def _format_apa7(doc: Document) -> str:
    authors = doc.authors or "Autor desconocido"
    year = f"({doc.year})" if doc.year else "(s.f.)"
    title = doc.title or doc.filename
    journal = doc.journal or "Sin fuente"
    return f"{authors} {year}. {title}. {journal}."
