# 07 — Alternative objectives (not readmission)

The dataset was published for readmission, so **ask the professor** whether we can choose our own target.

## Option 1 — Length of stay (bed management)
- **OM:** plan beds and staff by knowing, at admission, how long a patient will stay.
- **ODS:** predict `time_in_hospital` (regression, or short / medium / long classification).
- **Trap:** use only admission-time info (age, admission type/source, past visits, diagnosis, specialty). `num_lab_procedures` and `num_medications` accumulate during the stay → leakage.

## Option 2 — Missed HbA1c test (quality of care)
- **OM:** make sure diabetic patients get the key diabetes test (most never did, per the original paper).
- **ODS:** classify at admission who is likely to leave without an HbA1c test (target: `A1Cresult` = not measured); remind the doctor.
- **Why strong:** backed by the dataset's own paper, rarely chosen.

## Option 3 — Patient segmentation
- **OM:** design targeted care programs for different kinds of diabetic patients.
- **ODS:** clustering (K-Prototypes, or K-Means after encoding), then profile each group (e.g. "young, frequent ER visits", "elderly, heart problems, on insulin").
- **Note:** clustering is an official UCI task for this dataset; evaluate by usefulness and interpretability of the groups.

## Option 4 — Discharge destination
- **OM:** organize care-facility placements early so patients don't occupy beds they no longer need.
- **ODS:** classify `discharge_disposition_id` (home / home with care / facility) from admission-time info.

## Recommendation
- **Bold:** main OM = HbA1c testing (option 2), secondary OM = segmentation (option 3).
- **Safe but different:** main OM = readmission, secondary OM = segmentation or length of stay.

Whatever the choice: split by patient, avoid leakage, honest metrics, deploy a tool that answers a real question.
