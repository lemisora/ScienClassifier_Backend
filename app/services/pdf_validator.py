from io import BytesIO

import pdfplumber
from fastapi import HTTPException
from langdetect import detect, LangDetectException

ALLOWED_LANGUAGES = {"es", "en"}
MIN_TEXT_LENGTH = 100


def validate_pdf(data: bytes) -> str:
    """
    Valida que el archivo sea un PDF con texto extraíble en español o inglés.
    Devuelve el texto extraído para reutilizarlo en el worker.
    Lanza HTTPException 400 si falla cualquier check.
    """
    _check_magic_number(data)
    text = _extract_text(data)
    _check_language(text)
    return text


def _check_magic_number(data: bytes) -> None:
    if not data.startswith(b"%PDF-"):
        raise HTTPException(status_code=400, detail="El archivo no es un PDF válido")


def _extract_text(data: bytes) -> str:
    try:
        with pdfplumber.open(BytesIO(data)) as pdf:
            text = "\n".join(
                page.extract_text() or "" for page in pdf.pages
            ).strip()
    except Exception:
        raise HTTPException(status_code=400, detail="No se pudo leer el PDF")

    if len(text) < MIN_TEXT_LENGTH:
        raise HTTPException(
            status_code=400,
            detail="PDF sin texto extraíble — no se aceptan documentos escaneados",
        )
    return text


def _check_language(text: str) -> None:
    try:
        lang = detect(text[:2000])
    except LangDetectException:
        raise HTTPException(status_code=400, detail="No se pudo detectar el idioma del documento")

    if lang not in ALLOWED_LANGUAGES:
        raise HTTPException(
            status_code=400,
            detail=f"Idioma no permitido: '{lang}'. Solo se aceptan artículos en español o inglés",
        )
