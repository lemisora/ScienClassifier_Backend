import re
from io import BytesIO

import pdfplumber
from fastapi import HTTPException
from langdetect import detect, LangDetectException

ALLOWED_LANGUAGES = {"es", "en"}
MIN_TEXT_LENGTH = 100
ISSN_PATTERN = re.compile(
    r"\b(?:[ep]\s*[- ]?)?ISSN(?:\s*(?:\(|:)?\s*(?:online|print)\)?)?\s*[:#]?\s*([0-9]{4})[\s\-–—]?([0-9]{3}[0-9Xx])\b",
    re.IGNORECASE,
)


def validate_pdf(data: bytes) -> str:
    """
    Valida que el archivo sea un PDF con texto extraíble en español o inglés.
    Devuelve el texto extraído para reutilizarlo en el worker.
    Lanza HTTPException 400 si falla cualquier check.
    """
    _check_magic_number(data)
    text = _extract_text(data)
    _check_issn(text)
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


# Función para encontrar ISSN en el texto extraído mediante patrón regex
def _check_issn(text: str) -> None:
    normalized_text = _normalize_issn_text(text)
    matches = ISSN_PATTERN.findall(normalized_text[:60000])
    if any(_is_valid_issn("".join(m)) for m in matches):
        return
    raise HTTPException(
        status_code=400,
        detail="No se detectó un ISSN válido en el documento. Debe ser un artículo científico.",
    )


# Función para validar un ISSN de acuerdo al formato
def _is_valid_issn(issn: str) -> bool:
    compact = re.sub(r"[\s\-–—]", "", issn).upper()
    if len(compact) != 8 or not compact[:7].isdigit() or compact[7] not in "0123456789X":
        return False

    total = sum(int(digit) * weight for digit, weight in zip(compact[:7], range(8, 1, -1)))
    remainder = total % 11
    check = (11 - remainder) % 11
    expected = "X" if check == 10 else str(check)
    return compact[7] == expected


def _normalize_issn_text(text: str) -> str:
    return (
        text.replace("\u00A0", " ")  # non-breaking space
        .replace("\u2010", "-")      # hyphen
        .replace("\u2011", "-")      # non-breaking hyphen
        .replace("\u2012", "-")      # figure dash
        .replace("\u2013", "-")      # en dash
        .replace("\u2014", "-")      # em dash
    )


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
