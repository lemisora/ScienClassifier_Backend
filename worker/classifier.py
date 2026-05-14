import logging
import re

from worker.keywords import CATEGORIES

log = logging.getLogger(__name__)

# Thresholds por modo
_KEYWORD_THRESHOLD = 0.08   # ~4+ coincidencias de ~50 keywords
_ZERO_SHOT_THRESHOLD = 0.15  # similitud coseno — relevante > 0.15, no relacionado < 0.05

# Descripciones semánticas por categoría (usadas para embeddings)
_CATEGORY_DESCRIPTIONS: dict[str, str] = {
    "matemáticas":       "mathematics algebra calculus statistics probability theorems proofs equations topology numerical analysis linear algebra",
    "física":            "physics quantum mechanics relativity thermodynamics electromagnetism particles waves astrophysics Hamiltonian Schrödinger equation nuclear",
    "química":           "chemistry molecules reactions synthesis organic compounds polymers catalysts spectroscopy electrochemistry thermochemistry bonds reagents",
    "biología":          "biology cells DNA proteins evolution organisms genetics ecosystems metabolism species genome bacteria viruses reproduction",
    "computación":       "computer science algorithms machine learning neural networks deep learning software databases artificial intelligence programming data structures",
    "ingeniería":        "engineering design structures circuits automation manufacturing robotics materials sensors control systems CAD mechanical hydraulic",
    "medicina":          "medicine disease diagnosis treatment patients clinical trials drugs surgery vaccines oncology hospital symptoms pathology biomarkers",
    "ciencias sociales": "social sciences society culture economics politics psychology behavior education sociology anthropology democracy inequality",
}

_st_model = None
_cat_embeddings = None


def _get_st_model():
    global _st_model, _cat_embeddings
    if _st_model is None:
        from sentence_transformers import SentenceTransformer
        log.info("Cargando modelo sentence-transformers all-MiniLM-L6-v2 (~22MB)...")
        _st_model = SentenceTransformer("all-MiniLM-L6-v2")
        _cat_embeddings = _st_model.encode(
            list(_CATEGORY_DESCRIPTIONS.values()), convert_to_tensor=True
        )
        log.info("Modelo listo.")
    return _st_model, _cat_embeddings


def _strip_cid(text: str) -> str:
    return re.sub(r"\(cid:\d+\)", "", text)


def classify(text: str, mode: str = "keyword") -> dict:
    """
    Clasifica el texto de un PDF.

    mode="keyword"   → conteo directo de keywords por categoría (rápido)
    mode="zero_shot" → modelo NLI distilbert-mnli (mayor precisión semántica)

    Devuelve:
    {
        "categories": [{"category": str, "score": float}, ...],
        "title":   str | None,
        "authors": str | None,
        "year":    int | None,
    }
    """
    text = _strip_cid(text)
    clean = _clean_text(text)

    if mode == "zero_shot":
        try:
            scores = _score_zero_shot(text)
            threshold = _ZERO_SHOT_THRESHOLD
        except Exception as exc:
            log.warning("Zero-shot falló, usando keyword como fallback: %s", exc)
            scores = _score_keyword(clean)
            threshold = _KEYWORD_THRESHOLD
    else:
        scores = _score_keyword(clean)
        threshold = _KEYWORD_THRESHOLD

    filtered = {cat: round(score, 4) for cat, score in scores.items() if score >= threshold}
    categories = sorted(
        [{"category": cat, "score": score} for cat, score in filtered.items()],
        key=lambda x: x["score"],
        reverse=True,
    )

    return {
        "categories": categories,
        "title": _extract_title(text),
        "authors": _extract_authors(text),
        "year": _extract_year(text),
    }


def _clean_text(text: str) -> str:
    text = re.sub(r"\(cid:\d+\)", "", text)
    text = text.lower()
    text = re.sub(r"[^a-záéíóúüñàâèêîôùûçäöü\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _score_keyword(text: str) -> dict[str, float]:
    """
    Cuenta cuántas keywords de cada categoría aparecen en el texto.
    Normaliza por el total de keywords de la categoría.
    No usa TF-IDF: evita que palabras diagnósticas queden penalizadas por IDF bajo.
    """
    scores: dict[str, float] = {}
    for cat, keywords in CATEGORIES.items():
        if not keywords:
            scores[cat] = 0.0
            continue
        matches = sum(1 for kw in keywords if kw.lower() in text)
        scores[cat] = matches / len(keywords)
    return scores


def _score_zero_shot(text: str) -> dict[str, float]:
    """
    Usa sentence-transformers (all-MiniLM-L6-v2, 22MB) para clasificar
    mediante similitud coseno entre el texto y las descripciones de cada categoría.
    Lanza excepción si el modelo falla (el caller maneja el fallback con el threshold correcto).
    """
    from sentence_transformers import util as st_util
    model, cat_embeddings = _get_st_model()
    snippet = text[:1500].strip()
    text_emb = model.encode(snippet, convert_to_tensor=True)
    similarities = st_util.cos_sim(text_emb, cat_embeddings)[0].tolist()
    return dict(zip(_CATEGORY_DESCRIPTIONS.keys(), similarities))


# ── Extracción de metadatos ────────────────────────────────────────────────────

def _extract_title(text: str) -> str | None:
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    for line in lines[:5]:
        if len(line) > 20 and not re.search(r"\d{4}", line):
            return line
    return lines[0] if lines else None


_AUTHOR_NOISE = re.compile(
    r"universidad|instituto|facultad|departamento|dedicatoria|agradec|"
    r"amor|dios|familia|abstract|resumen|introduccion|keywords|copyright|"
    r"cuando|donde|aunque|sobre|para|durante|mientras|porque",
    re.IGNORECASE,
)


def _looks_like_names(text: str) -> bool:
    if re.search(r"@|\bhttp\b|\.com\b|\.org\b", text):
        return False
    if len(text) > 120:
        return False
    if _AUTHOR_NOISE.search(text):
        return False
    return bool(re.search(r"[A-ZÁÉÍÓÚ][a-záéíóúA-ZÁÉÍÓÚ]{2,}", text))


def _extract_authors(text: str) -> str | None:
    match = re.search(r"(?:authors?|autores?)[:\s]+([^\n]{5,120})", text[:2000], re.IGNORECASE)
    if match:
        candidate = match.group(1).strip()
        if _looks_like_names(candidate):
            return candidate

    lines = [l.strip() for l in text.split("\n") if l.strip()]
    for line in lines[1:10]:
        if (re.match(r"^[A-ZÁÉÍÓÚ][a-záéíóú]{2,}[\s,]+[A-ZÁÉÍÓÚ]", line)
                and _looks_like_names(line)):
            return line
    return None


def _extract_year(text: str) -> int | None:
    match = re.search(r"\b(19|20)\d{2}\b", text[:500])
    return int(match.group()) if match else None
