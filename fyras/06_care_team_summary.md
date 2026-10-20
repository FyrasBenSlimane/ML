# 06 — Summary for the care team and questions for the doctor

## Goal
Make the patient **active** in their own care, and give the care team **useful information** before the next visit, without asking them to read 30 days of raw answers.

## Weekly summary (generated every 7 days and before each appointment)
Contents:
1. Risk level at discharge and top reasons
2. Adherence score for the week, with trend
3. Key facts per plan item
4. Alerts raised and whether they were resolved
5. Questions for the doctor

### Example
> **CareStep summary — Week 1 (days 1–7)**
> Risk at discharge: 🔴 HIGH — insulin increased, 2 hospital stays last year, 17 medicines
>
> **Adherence: 74% 🟠** (needs support)
> - Insulin taken as prescribed: 6/7 days
> - All medicines taken: 5/7 days
> - Blood sugar measured: 7/7 days — above 300 on day 3 and day 4
> - Swelling or breathlessness: none reported
> - Follow-up visit: booked on day 5 (for day 9)
> - HbA1c test: not asked yet
>
> **Alerts:** 2 orange (high blood sugar, day 3 and 4) — patient contacted doctor on day 4
>
> **Questions to ask your doctor:**
> 1. My blood sugar was above 300 twice this week. Should my insulin dose be adjusted?
> 2. I sometimes forget my evening medicines. Can my schedule be simplified?
> 3. Should I have an HbA1c test?

## How questions are generated
Rule-based templates, triggered by the week's data:
| Condition | Question generated |
|---|---|
| Blood sugar out of range ≥ 2 days | "My blood sugar was [high/low] [n] times. Should my treatment be adjusted?" |
| Medicines missed ≥ 2 days | "I sometimes forget my medicines. Can my schedule be simplified?" |
| No HbA1c and not asked | "Should I have an HbA1c test?" |
| New symptoms reported | "I noticed [symptom] on [days]. Is this related to my condition?" |
| Insulin recently changed | "Is my new insulin dose working well?" |

## Care team dashboard
| Column | Example |
|---|---|
| Patient | Mr. K. |
| Risk level | 🔴 High |
| Day | 6 / 30 |
| Weekly adherence | 74% 🟠 |
| Open alerts | 1 orange |
| Last check-in | Today |
| Follow-up | Booked (day 9) |

Sorted by: open red alerts → open orange alerts → lowest adherence → highest risk.

## Sharing and consent
- The patient chooses to share the summary with their care team and/or a family member.
- The patient can view and download every summary.
