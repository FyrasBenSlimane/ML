"""
Human-readable labels for coded UCI fields (IDs_mapping.csv of dataset 296).
Served to the app through /teemo/meta so the form and the explanations use
exactly one vocabulary.
"""

ADMISSION_TYPE = {
    1: "Emergency", 2: "Urgent", 3: "Elective", 4: "Newborn",
    5: "Not available", 6: "Not recorded", 7: "Trauma center", 8: "Not mapped",
}

DISCHARGE_DISPOSITION = {
    1: "Home", 2: "Another short-term hospital", 3: "Skilled nursing facility",
    4: "Intermediate care facility", 5: "Another inpatient facility",
    6: "Home with home-health service", 7: "Left against medical advice",
    8: "Home with IV provider", 9: "Admitted as inpatient here",
    10: "Neonate transfer", 12: "Still a patient", 15: "Swing bed",
    16: "Outpatient at another institution", 17: "Outpatient at this institution",
    18: "Not recorded", 22: "Rehabilitation facility", 23: "Long-term care hospital",
    24: "Medicaid nursing facility", 25: "Not mapped", 27: "Federal facility",
    28: "Psychiatric hospital",
}

ADMISSION_SOURCE = {
    1: "Physician referral", 2: "Clinic referral", 3: "HMO referral",
    4: "Transfer from a hospital", 5: "Transfer from a nursing facility",
    6: "Transfer from another facility", 7: "Emergency room",
    8: "Court / law enforcement", 9: "Not available", 10: "Critical-access hospital",
    11: "Normal delivery", 13: "Sick baby", 14: "Extramural birth", 17: "Not recorded",
    20: "Not mapped", 22: "Transfer within same facility", 25: "Ambulatory surgery center",
}

PAYER = {
    "Missing": "Not recorded", "MC": "Medicare", "MD": "Medicaid", "HM": "HMO",
    "SP": "Self-pay", "BC": "Blue Cross / Blue Shield", "WC": "Workers' compensation",
    "CH": "CHAMPUS (military)", "OT": "Other",
}

AGE = {
    "[0-10)": "0–9", "[10-20)": "10–19", "[20-30)": "20–29", "[30-40)": "30–39",
    "[40-50)": "40–49", "[50-60)": "50–59", "[60-70)": "60–69", "[70-80)": "70–79",
    "[80-90)": "80–89", "[90-100)": "90+",
}

A1C = {"Not_Tested": "Not tested", "Norm": "Normal", ">7": "Above 7%", ">8": "Above 8%"}
GLUCOSE = {"Not_Tested": "Not tested", "Norm": "Normal", ">200": "Above 200 mg/dL",
           ">300": "Above 300 mg/dL"}

DIAGNOSIS = {
    "Circulatory": "Circulatory system", "Respiratory": "Respiratory system",
    "Digestive": "Digestive system", "Diabetes": "Diabetes", "Injury": "Injury / poisoning",
    "Musculoskeletal": "Musculoskeletal", "Genitourinary": "Genitourinary",
    "Neoplasms": "Neoplasms (tumours)", "External": "External cause / supplementary",
    "Other": "Other",
}

MED_STATUS = {"No": "Not prescribed", "Steady": "Steady dose", "Up": "Dose increased",
              "Down": "Dose decreased"}

RACE = {"AfricanAmerican": "African American"}


def specialty(code: str) -> str:
    """'Surgery-Cardiovascular/Thoracic' -> 'Surgery · Cardiovascular/Thoracic'."""
    if code == "Unknown":
        return "Not recorded"
    out = code.replace("-", " · ")
    for a, b in [("InternalMedicine", "Internal medicine"),
                 ("GeneralPractice", "General practice"),
                 ("ObstetricsandGynecology", "Obstetrics & gynecology"),
                 ("PhysicalMedicineandRehabilitation", "Physical medicine & rehab"),
                 ("Emergency/Trauma", "Emergency / trauma")]:
        out = out.replace(a, b)
    return out


def payer(code: str) -> str:
    return PAYER.get(code, f"Plan {code}")


def options_with_labels(field: str, values):
    """[{value, label}] for a categorical field, in the given order."""
    table = {
        "admission_type_id": ADMISSION_TYPE, "discharge_disposition_id": DISCHARGE_DISPOSITION,
        "admission_source_id": ADMISSION_SOURCE, "age": AGE, "A1Cresult": A1C,
        "max_glu_serum": GLUCOSE, "diag_1_group": DIAGNOSIS, "diag_2_group": DIAGNOSIS,
        "diag_3_group": DIAGNOSIS, "race": RACE,
    }.get(field)
    out = []
    for v in values:
        if field == "medical_specialty":
            label = specialty(v)
        elif field == "payer_code":
            label = payer(v)
        elif table is not None:
            label = table.get(v, str(v))
        elif field in MED_FIELDS:
            label = MED_STATUS.get(v, v)
        else:
            label = str(v)
        out.append({"value": v, "label": label})
    return out


MED_FIELDS = {
    "metformin", "repaglinide", "nateglinide", "glimepiride", "glipizide",
    "glyburide", "pioglitazone", "rosiglitazone", "insulin", "glipizide-metformin",
}
