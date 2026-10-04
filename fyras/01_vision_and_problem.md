# 01 — Vision and problem

## The problem
About 1 in 9 diabetic hospital stays in the dataset ends with a readmission within 30 days. Each one costs on average about $15,200 (AHRQ HCUP, 2018) and harms the patient.

Many readmissions start with small things at home:
- a changed insulin dose the patient doesn't follow correctly,
- many medications, some forgotten or mixed up,
- no follow-up appointment booked in the first week,
- blood sugar going out of control without anyone noticing,
- a missing HbA1c test, so the doctor lacks the full picture.

## The gap
Most readmission projects stop at a **score on the discharge day**. After that, the patient goes home and nobody knows what happens until they come back.

| Typical project | CareStep |
|---|---|
| Predicts risk once, at discharge | Predicts risk, then **follows the patient for 30 days** |
| Used by hospital staff only | Used by the **patient**, with the care team informed |
| Says "high risk" | Says **why**, and **what to do today** |
| Ends with a number | Ends with a **plan, daily checks, alerts and a summary** |

## The product in one page
**CareStep** is a 30-day recovery companion.

1. **Discharge day:** the patient answers about 10 simple questions. The model gives a risk level (low / medium / high) and the main reasons.
2. **Personal plan:** each changeable reason becomes an action, e.g. "insulin changed" → "take your new insulin dose as prescribed".
3. **Daily check-in (30 days):** 3–5 short questions about what the patient did that day.
4. **Alerts:** warning answers trigger advice to contact a doctor, or emergency services for danger signs.
5. **Summary:** each week, a summary of the patient's days and a list of questions to bring to the next appointment.

## Who uses it
| User | What they get |
|---|---|
| Patient | Risk level, personal checklist, daily questions, reminders |
| Family / caregiver | Same view (with the patient's consent), to help at home |
| Care team (nurse, doctor) | Alerts, adherence scores, weekly summaries |

## Why this stands out
- It answers a question nobody else in the class asks: **what happens after discharge?**
- It uses the model's explanations to drive real actions, not just a chart.
- It is honest about what the data can and cannot support.
