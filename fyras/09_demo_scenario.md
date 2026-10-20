# 09 — Demo scenario: Mr. K.'s 30 days

*A fictional patient used to show the full flow. All values are illustrative.*

## Day 0 — Discharge
Mr. K., 68, leaves hospital after 6 days for a heart problem. He answers the discharge questions:

| Question | Answer |
|---|---|
| Age | 68 |
| Hospital stays in past year | 2 |
| ER visits in past year | 1 |
| Days in hospital | 6 |
| Main reason | Heart problem |
| Number of medicines | 17 |
| Insulin changed | Increased |
| HbA1c test this stay | No |
| Going to | Home |

**Model output:**
> Risk: **27%** (average 11%) → 🔴 **HIGH**
> Reasons (SHAP): 2 hospital stays last year · insulin increased · 17 medicines · heart problem · no HbA1c test · age (not changeable)

**His plan:**
1. Take the new insulin dose exactly as written
2. Book a follow-up visit before day 7
3. Use a pill organizer; ask a pharmacist to review his medicines
4. Weigh himself daily and watch for swelling or breathlessness
5. Ask his doctor about an HbA1c test
6. Measure blood sugar every morning

## Days 1–7 — Intensive phase
| Day | Key answers | Score | Alert |
|---|---|---|---|
| 1 | Insulin ✅, medicines ✅, sugar 180, follow-up not booked | 85% | 🟡 Reminder: book follow-up |
| 2 | Insulin ✅, medicines partly, sugar 210 | 75% | — |
| 3 | Insulin ✅, medicines ❌, sugar 315 | 55% | 🟠 High sugar → contact doctor |
| 4 | Insulin ❌, medicines ✅, sugar 305 | 50% | 🟠 High sugar → contact doctor |
| 5 | Insulin ✅, medicines ✅, sugar 220, **follow-up booked (day 9)** | 90% | — |
| 6 | Insulin ✅, medicines ✅, sugar 190 | 100% | — |
| 7 | Insulin ✅, medicines ✅, sugar 170 | 100% | — |

**Weekly adherence: 79% 🟠** → the care team calls him on day 4 after the second orange alert; his doctor adjusts the treatment.

**Week 1 summary sent to his doctor**, with questions:
1. My blood sugar was above 300 twice. Should my insulin be adjusted?
2. I forget my evening medicines sometimes. Can my schedule be simplified?
3. Should I have an HbA1c test?

## Days 8–21 — Stabilization
- Day 9: follow-up visit attended ✅; HbA1c test ordered ✅.
- Day 12: new swelling in the ankles → 🟠 contact doctor; diuretic dose checked the same day.
- Weekly adherence: 88% 🟢, then 92% 🟢.

## Days 22–30 — Autonomy
- 2–3 questions per day; blood sugar stable between 130 and 180.
- Day 30: final summary and end-of-program message.

> **Final summary:** 30 days completed · adherence 87% · 4 alerts, all resolved · follow-up attended · HbA1c done · no readmission.

## What the jury sees
1. The model turning answers into a risk and reasons
2. Reasons becoming a personal plan
3. Daily answers becoming scores and alerts
4. Alerts leading to action before a readmission
5. A summary that makes the next doctor visit more useful

## Contrast: a patient falling behind
Mrs. L., 🔴 high risk, stops answering on day 3 and never books her follow-up.
- Day 5: ⚪ missed check-ins (2 days) + 🟠 follow-up not booked → flagged at the top of the care team dashboard.
- Day 5: the nurse calls her and books the visit.

This shows the second value of the tool: **silence is also a signal.**
