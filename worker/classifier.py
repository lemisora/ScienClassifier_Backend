import re

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

from worker.keywords import CATEGORIES, SCORE_THRESHOLD


def classify(text: str) -> dict:
    """
    Clasifica el texto de un PDF usando TF-IDF contra las keywords por categoría.

    Devuelve:
    {
        "categories": [{ "category": str, "score": float }, ...],  # solo >= umbral
        "title":   str | None,
        "authors": str | None,
        "year":    int | None,
    }
    """
    clean = _clean_text(text)
    scores = _score_categories(clean)
    filtered = {cat: round(score, 4) for cat, score in scores.items() if score >= SCORE_THRESHOLD}
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
    text = text.lower()
    text = re.sub(r"[^a-záéíóúüñàâèêîôùûçäöü\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _score_categories(text: str) -> dict[str, float]:
    category_names = list(CATEGORIES.keys())
    # Cada categoría se representa como un documento de keywords
    category_docs = [" ".join(kws) for kws in CATEGORIES.values()]

    vectorizer = TfidfVectorizer(ngram_range=(1, 2))
    # Ajustar sobre keywords + el texto del artículo
    vectorizer.fit(category_docs + [text])

    article_vec = vectorizer.transform([text])
    category_vecs = vectorizer.transform(category_docs)

    similarities = cosine_similarity(article_vec, category_vecs)[0]

    # Normalizar a 0-1 respecto al máximo obtenido
    max_score = similarities.max()
    if max_score == 0:
        return {cat: 0.0 for cat in category_names}

    normalized = similarities / max_score
    return dict(zip(category_names, normalized.tolist()))


def _extract_title(text: str) -> str | None:
    # El título suele estar en las primeras líneas no vacías
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    for line in lines[:5]:
        # Descarta líneas que parezcan autores, fechas o muy cortas
        if len(line) > 20 and not re.search(r"\d{4}", line):
            return line
    return lines[0] if lines else None


def _extract_authors(text: str) -> str | None:
    # Busca patrones comunes: "Autor1, Autor2" o líneas con múltiples nombres propios
    patterns = [
        r"(?:authors?|autores?)[:\s]+([^\n]{5,120})",
        r"(?:by|por)[:\s]+([^\n]{5,120})",
    ]
    for pattern in patterns:
        match = re.search(pattern, text[:2000], re.IGNORECASE)
        if match:
            return match.group(1).strip()
    return None


def _extract_year(text: str) -> int | None:
    # Busca años entre 1900 y 2099 en las primeras 500 chars
    match = re.search(r"\b(19|20)\d{2}\b", text[:500])
    if match:
        return int(match.group())
    return None
