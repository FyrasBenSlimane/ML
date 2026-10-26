"""Écrire un entier 0–100 en toutes lettres (français), pour le texte parlé."""

_UNITES = [
    "zéro", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf",
    "dix", "onze", "douze", "treize", "quatorze", "quinze", "seize",
    "dix-sept", "dix-huit", "dix-neuf",
]
_DIZAINES = {20: "vingt", 30: "trente", 40: "quarante", 50: "cinquante",
             60: "soixante", 80: "quatre-vingt"}


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
    if n < 80:
        u = n - 60
        return "soixante et onze" if u == 11 else f"soixante-{_UNITES[u]}"
    u = n - 80
    return "quatre-vingts" if u == 0 else f"quatre-vingt-{_UNITES[u]}"


def en_lettres(n: int) -> str:
    n = int(round(n))
    if n <= 0:
        return "zéro"
    if n >= 100:
        return "cent"
    return _sous_cent(n)


def pourcent(n: int) -> str:
    return f"{en_lettres(n)} pour cent"
