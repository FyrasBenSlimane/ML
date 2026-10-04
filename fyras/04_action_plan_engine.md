# 04 — Action plan engine (SHAP → personal checklist)

## Principle
For each patient, SHAP tells us which features pushed their risk up. We keep only the **changeable** ones and translate them into actions and daily questions.

## Step by step
1. Compute SHAP values for the patient's prediction.
2. Keep features with a **positive** contribution (they increase risk).
3. Classify each as **changeable** or **not changeable**.
4. Rank changeable factors by SHAP value; keep the top 3.
5. Look up each factor in the rule table → actions + daily questions.
6. Add the **base plan** that every patient receives.
7. Explain non-changeable factors in plain words, without actions.

## Changeable vs. not changeable
| Factor | Changeable? | How it is used |
|---|---|---|
| Insulin changed | ✅ | Insulin adherence actions |
| Other diabetes medicines changed | ✅ | Medication review |
| Many medications | ✅ | Pill organizer, pharmacist review |
| No HbA1c test | ✅ | Ask for the test |
| Frequent past hospital stays / ER visits | ✅ (indirectly) | Early follow-up visit, closer monitoring |
| Main reason (heart, breathing…) | ✅ (monitoring) | Condition-specific symptom checks |
| Discharge to home with help / facility | ⚠️ Partly | Coordinate with caregiver |
| Age | ❌ | Explained only |
| Gender | ❌ | Never shown as a reason |

## Rule table
| Risk factor | Actions | Daily question(s) | Days |
|---|---|---|---|
| Insulin changed | Take insulin exactly as newly prescribed; keep the new dose written down | "Did you take your insulin as prescribed today?" | 1–30 |
| Other diabetes medicines changed | Ask the pharmacist to explain the changes | "Did you take your diabetes pills as prescribed today?" | 1–30 |
| Many medications (≥ 15, illustrative) | Use a weekly pill organizer; medication review within 7 days | "Did you take all your medicines today?" / "Has a pharmacist reviewed your medicines?" | 1–30 / 1–7 |
| No HbA1c test | Ask the doctor for an HbA1c test at the follow-up visit | "Have you asked about an HbA1c test?" | 1–14 |
| ≥ 1 hospital stay or ER visit in past year | Book a follow-up visit within 7 days | "Have you booked your follow-up visit?" then "Did you attend it?" | 1–7, then until done |
| Heart problem as main reason | Weigh yourself daily; watch swelling and breathlessness | "Any new swelling or shortness of breath today?" | 1–30 |
| Breathing problem as main reason | Watch breathing, use inhalers as prescribed | "Is your breathing worse than yesterday?" | 1–30 |
| Infection / kidney as main reason | Finish antibiotics, drink fluids as advised | "Any fever or pain when urinating?" | 1–14 |
| Discharge home with help | Share the plan with the caregiver | "Did someone help you with your medicines today?" | 1–30 |

## Base plan (every patient)
| Action | Daily question |
|---|---|
| Check blood sugar as instructed | "What was your blood sugar this morning?" |
| Know the warning signs | "Did you feel shaky, confused, very thirsty or faint today?" |
| Eat regular meals | "Did you eat your regular meals today?" |

## Example output
Patient: 68 y.o., 2 hospital stays last year, insulin increased, 17 medicines, no HbA1c test, heart problem.

> **Your risk level: 🔴 HIGH**
> **Main reasons you can act on:**
> 1. Your insulin dose was increased
> 2. You were in hospital twice last year
> 3. You take 17 different medicines
>
> **Also considered (not something you can change):** your age.
>
> **Your plan:**
> - Take your new insulin dose exactly as written
> - Book a follow-up visit before day 7
> - Use a pill organizer and ask a pharmacist to review your medicines
> - Weigh yourself every morning and watch for swelling
> - Ask your doctor about an HbA1c test

## Rules for safe wording
- Never say "you will be readmitted"; say "your risk is higher than average".
- Never suggest changing a dose; always "as prescribed" or "ask your doctor".
- Every plan ends with when to call a doctor and when to call emergency services.
