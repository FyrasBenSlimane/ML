"""Écrire un entier 0–100 en toutes lettres (français), pour le texte parlé.

L'avatar lit la `narrative` à voix haute : on y écrit donc « soixante-deux pour
cent » plutôt que « 62 % », conformément à la spec (nombres en toutes lettres).
"""

_UNITES = [
    "zéro", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf",
    "dix", "onze", "douze", "treize", "quatorze", "quinze", "seize",
    "dix-sept", "dix-huit", "dix-neuf",
]
_DIZAINES = {
    20: "vingt", 30: "trente", 40: "quarante", 50: "cinquante", 60: "soixante",
    80: "quatre-vingt",
}


def _sous_cent(n: int) -> str:
    if n < 20:
        return _UNITES[n]
    if n < 70:
        d, u = (n // 10) * 10, n % 10
        base = _DIZAINES[d]
        if u == 0:
            return base
        if u == 1:
            return f"{base} et un"
        return f"{base}-{_UNITES[u]}"
    if n < 80:  # 70–79 : soixante-dix, soixante et onze, soixante-douze…
        u = n - 60
        if u == 11:
            return "soixante et onze"
        return f"soixante-{_UNITES[u]}"
    # 80–99 : quatre-vingts, quatre-vingt-un, quatre-vingt-dix…
    u = n - 80
    if u == 0:
        return "quatre-vingts"
    return f"quatre-vingt-{_UNITES[u]}"


def en_lettres(n: int) -> str:
    """Entier 0–100 en toutes lettres."""
    n = int(round(n))
    if n <= 0:
        return "zéro"
    if n >= 100:
        return "cent"
    return _sous_cent(n)


def pourcent(n: int) -> str:
    """« soixante-deux pour cent »."""
    return f"{en_lettres(n)} pour cent"
