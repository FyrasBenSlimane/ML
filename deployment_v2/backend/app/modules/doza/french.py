"""Spell an integer 0–100 in English words, for the spoken text.

The avatar reads the `narrative` aloud, so we write "sixty-two percent"
rather than "62 %" (numbers spelled out, per the spec). The module/function
names are kept for backward compatibility.
"""

_ONES = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    "seventeen", "eighteen", "nineteen",
]
_TENS = {
    20: "twenty", 30: "thirty", 40: "forty", 50: "fifty",
    60: "sixty", 70: "seventy", 80: "eighty", 90: "ninety",
}


def _sub_hundred(n: int) -> str:
    if n < 20:
        return _ONES[n]
    d, u = (n // 10) * 10, n % 10
    base = _TENS[d]
    return base if u == 0 else f"{base}-{_ONES[u]}"


def en_lettres(n: int) -> str:
    """Integer 0–100 in words."""
    n = int(round(n))
    if n <= 0:
        return "zero"
    if n >= 100:
        return "one hundred"
    return _sub_hundred(n)


def pourcent(n: int) -> str:
    """\"sixty-two percent\"."""
    return f"{en_lettres(n)} percent"
