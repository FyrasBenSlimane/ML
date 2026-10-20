# 05 — Daily check-in, adherence score and alerts

## Design principles
- **Short:** 3–5 questions, under 1 minute.
- **Personal:** questions come from the patient's own plan (see 04).
- **Simple answers:** yes / no, a number, or a choice.
- **Safe:** some answers trigger immediate advice.

## 30-day schedule
| Phase | Days | Focus | Questions per day |
|---|---|---|---|
| Intensive | 1–7 | Medication changes, follow-up booking, warning signs | 4–5 |
| Stabilization | 8–21 | Habits, follow-up attendance, symptoms | 3–4 |
| Autonomy | 22–30 | Routine checks, end-of-program review | 2–3 |

High-risk patients keep daily check-ins for the full 30 days; low-risk patients may switch to every other day after day 14.

## Question bank (examples)
| ID | Question | Answer | Source |
|---|---|---|---|
| Q-INS | Did you take your insulin as prescribed today? | Yes / Partly / No | Insulin changed |
| Q-MED | Did you take all your medicines today? | Yes / Partly / No | Many medications |
| Q-GLU | What was your blood sugar this morning? (mg/dL) | Number / Not measured | Base plan |
| Q-SYM | Did you feel shaky, confused, very thirsty or faint today? | Yes / No | Base plan |
| Q-HRT | Any new swelling or shortness of breath today? | Yes / No | Heart problem |
| Q-FUB | Have you booked your follow-up visit? | Yes / No | Past stays |
| Q-FUA | Did you attend your follow-up visit? | Yes / Not yet / Missed | Past stays |
| Q-A1C | Have you asked about an HbA1c test? | Yes / No | No HbA1c |
| Q-EAT | Did you eat your regular meals today? | Yes / No | Base plan |

## Adherence score
Each question has a weight according to its importance for the patient.

```
daily_score  = Σ (weight_i × points_i) / Σ weight_i     (points: Yes = 1, Partly = 0.5, No = 0)
weekly_score = mean of daily_scores over the last 7 days  (missed check-in day = 0)
```

| Question type | Weight (illustrative) |
|---|---|
| Insulin / medicines | 3 |
| Follow-up booked / attended | 3 |
| Blood sugar measured | 2 |
| Meals, HbA1c question | 1 |

| Weekly score | Status |
|---|---|
| ≥ 80% | 🟢 On track |
| 50–79% | 🟠 Needs support (care team informed) |
| < 50% | 🔴 Falling behind (care team calls the patient) |

## Alert levels
Thresholds are **illustrative**. Hypoglycemia levels follow common diabetes guidance (below 70 mg/dL is low, below 54 is clinically significant); every rule must be validated by clinicians before real use.

| Level | Trigger examples | Message to patient | Care team |
|---|---|---|---|
| 🔴 Emergency | Blood sugar < 54; confusion or fainting; severe shortness of breath; chest pain | "Call emergency services now." | Notified immediately |
| 🟠 Contact doctor today | Blood sugar < 70 or > 300; insulin missed 2 days in a row; new swelling; follow-up not booked by day 5 | "Contact your doctor today." | Added to today's call list |
| 🟡 Reminder | One missed medicine; follow-up not booked yet (days 1–4) | "Remember to…" | Visible in summary |
| ⚪ Missed check-in | No answer for 2 days in a row | Reminder notification | Flagged if high-risk |

## Example rule logic
```python
def check_alerts(answers, history, day):
    alerts = []
    glu = answers.get("Q-GLU")
    if answers.get("Q-SYM") == "Yes" or (glu is not None and glu < 54):
        alerts.append(("RED", "Call emergency services now."))
    elif glu is not None and (glu < 70 or glu > 300):
        alerts.append(("ORANGE", "Contact your doctor today about your blood sugar."))
    if answers.get("Q-INS") == "No" and history.last("Q-INS") == "No":
        alerts.append(("ORANGE", "You missed your insulin two days in a row. Contact your doctor."))
    if day >= 5 and not history.ever("Q-FUB", "Yes"):
        alerts.append(("ORANGE", "Please book your follow-up visit today."))
    return alerts
```
