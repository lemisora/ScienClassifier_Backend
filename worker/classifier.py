import logging
import re

from worker.keywords import CATEGORIES

log = logging.getLogger(__name__)

# Thresholds por modo
_KEYWORD_THRESHOLD = 0.08   # ~4+ coincidencias de ~50 keywords
_ZERO_SHOT_THRESHOLD = 0.30  # probabilidad NLI independiente

# Etiquetas en inglés para el modelo NLI (entiende mejor inglés)
_LABELS_EN: dict[str, str] = {
    "matemáticas":      "mathematics and statistics",
    "física":           "physics",
    "química":          "chemistry",
    "biología":         "biology and life sciences",
    "computación":      "computer science and software engineering",
    "ingeniería":       "engineering and technology",
    "medicina":         "medicine and health sciences",
    "ciencias sociales": "social sciences and humanities",
}

_zero_shot_pipeline = None


def _get_zero_shot():
    global _zero_shot_pipeline
    if _zero_shot_pipeline is None:
        from transformers import pipeline as hf_pipeline
        log.info("Cargando modelo zero-shot (primera vez, puede tardar ~30s)...")
        _zero_shot_pipeline = hf_pipeline(
            "zero-shot-classification",
            model="typeform/distilbert-base-uncased-mnli",
            device=-1,  # CPU
        )
        log.info("Modelo zero-shot listo.")
    return _zero_shot_pipeline


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
        scores = _score_zero_shot(text)
        threshold = _ZERO_SHOT_THRESHOLD
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
    Usa un modelo NLI (distilbert-base-uncased-mnli) para clasificación zero-shot.
    Pasa los primeros ~1500 chars (abstract + intro) al modelo.
    Fallback a keyword si el modelo falla.
    """
    try:
        clf = _get_zero_shot()
        snippet = text[:1500].strip()
        en_labels = list(_LABELS_EN.values())

        result = clf(
            snippet,
            candidate_labels=en_labels,
            hypothesis_template="This scientific article is about {}.",
            multi_label=True,
        )

        label_to_cat = {v: k for k, v in _LABELS_EN.items()}
        scores: dict[str, float] = {}
        for lbl, score in zip(result["labels"], result["scores"]):
            if lbl in label_to_cat:
                scores[label_to_cat[lbl]] = score

        for cat in CATEGORIES:
            scores.setdefault(cat, 0.0)

        return scores

    except Exception as exc:
        log.error("Zero-shot falló, usando keyword como fallback: %s", exc)
        return _score_keyword(_clean_text(text))


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
