# 01 — The problem

## In plain words
When a diabetic patient leaves the hospital, some come back within a month because their health gets worse at home: a changed insulin dose, too many medications, no follow-up. In this dataset, about **1 in 9 encounters** ends with a readmission within 30 days.

## Why it matters
- **For the patient:** they get sicker, with more complications and risk.
- **For the hospital:** each 30-day readmission costs on average about **$15,200 (AHRQ HCUP, 2018)** and about **$20,329 (2022)**. The 30-day readmission rate is also a quality measure used by CMS.
- Many of these readmissions are avoidable with simple actions: a follow-up call, a medication review, an early clinic visit.

## The real question
The hospital cannot give extra attention to everyone. So:

> **On the day a patient leaves, which patients are most likely to come back, so we can focus our limited help on them?**

## What the model does
It reads the patient's hospital record (age, past visits, diagnoses, medications, lab tests, length of stay) and gives:
1. a **risk score** (e.g. "34% chance of returning within 30 days"),
2. the **reasons** behind it (e.g. "3 hospital stays last year, insulin was changed").

**Analogy:** airport security can't search every bag, so it uses signals to decide which bags deserve a closer look. Our model is that signal for the hospital.

## One sentence for the professor
> We predict which diabetic patients are likely to be readmitted within 30 days of discharge, so the hospital can focus its limited follow-up resources on them and prevent avoidable readmissions.

## The clinical story behind the data
The original paper (Strack et al., 2014) found that HbA1c (average blood sugar over 2–3 months) was measured in only a minority of encounters, a gap in diabetes care. We use this as an EDA insight.
