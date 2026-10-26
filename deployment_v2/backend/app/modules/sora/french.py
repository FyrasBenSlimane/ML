"""Spell an integer 0–100 in English words, for the spoken text."""

_ONES = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    "seventeen", "eighteen", "nineteen",
]
_TENS = {20: "twenty", 30: "thirty", 40: "forty", 50: "fifty",
         60: "sixty", 70: "seventy", 80: "eighty", 90: "ninety"}


def _sous_cent(n: int) -> str:
    if n < 20:
        return _ONES[n]
    d, u = (n // 10) * 10, n % 10
    base = _TENS[d]
    return base if u == 0 else f"{base}-{_ONES[u]}"


def en_lettres(n: int) -> str:
    n = int(round(n))
    if n <= 0:
        return "zero"
    if n >= 100:
        return "one hundred"
    return _sous_cent(n)


def pourcent(n: int) -> str:
    return f"{en_lettres(n)} percent"
