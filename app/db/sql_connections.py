import os
from datetime import datetime

from sqlalchemy import (
    Boolean, DateTime, ForeignKey,
    Integer, String, Text, create_engine,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://admin:admin_password_segura@localhost:5432/postgres",
)

# psycopg2 soporta multi-host en connect_args pero SQLAlchemy no lo parsea en la URL.
# Si la URL tiene comas (patroni1:5432,patroni2:5432,...) extraemos los hosts y los
# pasamos via connect_args para que libpq haga el failover automático.
def _build_engine():
    import re
    m = re.match(
        r"postgresql(?:\+psycopg2)?://([^:]+):([^@]+)@(.+)/([^?]+)(.*)",
        DATABASE_URL,
    )
    if m:
        user, password, hostpart, dbname, qs = m.groups()
        if "," in hostpart:
            hosts, ports = [], []
            for hp in hostpart.split(","):
                h, _, p = hp.partition(":")
                hosts.append(h.strip())
                ports.append((p or "5432").strip())
            extra = {}
            if "target_session_attrs=read-write" in qs:
                extra["target_session_attrs"] = "read-write"
            return create_engine(
                "postgresql+psycopg2://",
                connect_args={
                    "host": ",".join(hosts),
                    "port": ",".join(ports),
                    "user": user,
                    "password": password,
                    "dbname": dbname,
                    **extra,
                },
                pool_pre_ping=True,
            )
    return create_engine(DATABASE_URL, pool_pre_ping=True)


engine = _build_engine()
SessionLocal = sessionmaker(bind=engine)


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    username: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    documents: Mapped[list["Document"]] = relationship(
        "Document",
        back_populates="owner",
        cascade="all, delete-orphan",
    )


class Document(Base):
    __tablename__ = "documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    object_key: Mapped[str] = mapped_column(String(512), nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="pending")  # pending | processing | done | error

    # Campos para APA7
    title: Mapped[str | None] = mapped_column(String(512), nullable=True)
    authors: Mapped[str | None] = mapped_column(Text, nullable=True)
    year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    journal: Mapped[str | None] = mapped_column(String(256), nullable=True)

    owner: Mapped["User"] = relationship("User", back_populates="documents")
    categories: Mapped[list["DocumentCategory"]] = relationship(
        "DocumentCategory",
        back_populates="document",
        cascade="all, delete-orphan",
    )


class DocumentCategory(Base):
    __tablename__ = "document_categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    document_id: Mapped[int] = mapped_column(Integer, ForeignKey("documents.id"), nullable=False)
    category: Mapped[str] = mapped_column(String(128), nullable=False)
    score: Mapped[int] = mapped_column(Integer, nullable=False)  # 0-100 (porcentaje)

    document: Mapped["Document"] = relationship("Document", back_populates="categories")


def create_tables() -> None:
    Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
