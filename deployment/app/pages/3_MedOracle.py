import streamlit as st
import sys
import pandas as pd
import numpy as np
import plotly.graph_objects as go
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from utils import (
    inject_global_css, render_avatar_header, render_risk_result,
    render_disclaimer, render_sidebar, check_portal,
    load_model, tts_button, chat_message, make_gauge_chart,
    AVATARS, AGE_RANGES, DIAG_GROUPS
)

st.set_page_config(page_title="MedOracle — Clinical Analytics", page_icon="🔮", layout="wide")
inject_global_css()
render_sidebar()
check_portal(["medical"])
render_avatar_header("medoracle")

model, features = load_model("medoracle")
DATA_DIR = Path(__file__).resolve().parent.parent.parent.parent / "data" / "splits"

chat_message("medoracle",
    "I'm <strong>MedOracle</strong>, your clinical analytics engine. "
    "I use the full 38-feature model for maximum predictive power. "
    "Designed for clinicians with access to complete patient data."
)

tabs = st.tabs(["Clinical Assessment", "What-If Simulator", "Batch Analysis"])

with tabs[0]:
    with st.form("medoracle_form"):
        st.markdown("##### Demographics & Admission")
        c1, c2, c3 = st.columns(3)
        with c1:
            age = st.selectbox("Age range", list(AGE_RANGES.keys()), format_func=lambda x: AGE_RANGES[x], index=6)
            gender = st.selectbox("Gender", ["Female", "Male"])
            race = st.selectbox("Race", ["Caucasian", "AfricanAmerican", "Hispanic", "Asian", "Other", "Unknown"])
        with c2:
            admission_type = st.selectbox("Admission type", [1,2,3,4,5,6,7,8],
                format_func=lambda x: {1:"Emergency",2:"Urgent",3:"Elective",4:"Newborn",5:"Not Available",6:"NULL",7:"Trauma",8:"Not Mapped"}.get(x,str(x)))
            discharge_disp = st.selectbox("Discharge disposition", [1,2,3,4,5,6,7,8,9,10,15,22,23,24,25,26,27,28,29,30],
                format_func=lambda x: {1:"Home",2:"Short-term hospital",3:"SNF",4:"ICF",5:"Other facility",6:"Home health",7:"AMA",8:"Home IV",9:"Admitted inpatient",10:"Neuro facility",15:"Swing bed",22:"Rehab",23:"Long-term care",24:"Medicaid facility",25:"Psych hospital",26:"Critical access",27:"Federal hospital",28:"Psych (Medicare)",29:"Not mapped",30:"Still patient"}.get(x,str(x)))
            admission_source = st.selectbox("Admission source", [1,2,3,4,5,6,7,8,9,10,17,20,22,25,26],
                format_func=lambda x: {1:"Physician referral",2:"Clinic referral",3:"HMO referral",4:"Transfer",5:"Transfer SNF",6:"Transfer other",7:"ER",8:"Court/law",9:"Not available",10:"Transfer hosp",17:"NULL",20:"Not mapped",22:"Transfer rehab",25:"Transfer critical",26:"Transfer ambulatory"}.get(x,str(x)))
        with c3:
            payer = st.selectbox("Payer code", ["Missing","MC","MD","BC","SP","CM","HM","OT","DM","OG","CH"],
                format_func=lambda x: {"Missing":"Unknown","MC":"Medicare","MD":"Medicaid","BC":"Blue Cross","SP":"Self-pay","CM":"Commercial","HM":"HMO","OT":"Other","DM":"DMO","OG":"OtherGov","CH":"CHAMPUS"}.get(x,x))
            med_specialty = st.selectbox("Medical specialty",
                ["Unknown","InternalMedicine","Emergency/Trauma","Family/GeneralPractice","Cardiology","Surgery-General","Nephrology","Orthopedics","Orthopedics-Reconstructive","Radiologist","Pulmonology","Psychiatry","ObstetricsandGynecology","Pediatrics","Gastroenterology","Urology"])

        st.markdown("##### Clinical Measures")
        c4, c5, c6 = st.columns(3)
        with c4:
            time_hosp = st.slider("Days in hospital", 1, 14, 5)
            num_lab = st.slider("Lab procedures", 1, 132, 40)
            num_proc = st.slider("Procedures", 0, 6, 1)
        with c5:
            num_meds = st.slider("Number of medications", 1, 80, 15)
            num_diag = st.slider("Number of diagnoses", 1, 16, 7)
            num_changes = st.slider("Medication changes", 0, 20, 2)
        with c6:
            n_out = st.number_input("Outpatient visits (year)", 0, 50, 1)
            n_er = st.number_input("Emergency visits (year)", 0, 30, 0)
            n_inp = st.number_input("Inpatient visits (year)", 0, 20, 1)

        st.markdown("##### Diagnoses & Treatment")
        c7, c8 = st.columns(2)
        with c7:
            diag1 = st.selectbox("Primary diagnosis group", DIAG_GROUPS)
            diag2 = st.selectbox("Secondary diagnosis group", DIAG_GROUPS, index=9)
            diag3 = st.selectbox("Tertiary diagnosis group", DIAG_GROUPS, index=9)
        with c8:
            a1c = st.selectbox("HbA1c result", ["Not_Tested", "Norm", ">7", ">8"])
            glu = st.selectbox("Glucose serum", ["Not_Tested", "Norm", ">200", ">300"])
            dmmed = st.selectbox("Diabetes medication?", ["Yes", "No"])
            insulin_p = st.selectbox("Insulin prescribed?", [0, 1], format_func=lambda x: "Yes" if x else "No")
            metformin_p = st.selectbox("Metformin prescribed?", [0, 1], format_func=lambda x: "Yes" if x else "No")
            insulin_chg = st.selectbox("Insulin changed?", [0, 1], format_func=lambda x: "Yes" if x else "No")

        submitted = st.form_submit_button("Run Clinical Analysis", type="primary", use_container_width=True)

    if submitted:
        row_dict = {
            "age_ordinal": age, "gender": gender, "race": race,
            "admission_type_id": admission_type, "discharge_disposition_id": discharge_disp,
            "admission_source_id": admission_source, "payer_code": payer,
            "medical_specialty": med_specialty, "time_in_hospital": time_hosp,
            "num_lab_procedures": num_lab, "num_procedures": num_proc,
            "num_medications": num_meds, "number_diagnoses": num_diag,
            "number_outpatient": n_out, "number_emergency": n_er, "number_inpatient": n_inp,
            "total_prior_visits": n_out + n_er + n_inp,
            "diag_1_group": diag1, "diag_2_group": diag2, "diag_3_group": diag3,
            "A1Cresult": a1c, "max_glu_serum": glu, "diabetesMed": dmmed,
            "insulin_prescrite": insulin_p, "metformin_prescrite": metformin_p,
            "insulin_changed": insulin_chg, "num_med_changes": num_changes,
        }
        row = pd.DataFrame([row_dict])
        for f in features:
            if f not in row.columns:
                row[f] = 0

        prob = model.predict_proba(row[features])[0][1]
        st.session_state["mo_prob"] = prob
        st.session_state["mo_row"] = row_dict

        level, advice = render_risk_result(prob, "medoracle")
        fig = make_gauge_chart(prob * 100, "Readmission Probability", AVATARS["medoracle"]["color"])
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

        chat_message("medoracle", f"Analysis complete. Readmission probability: <strong>{prob*100:.1f}%</strong> ({level}). Check the What-If Simulator to explore intervention scenarios.")
        tts_button(f"Clinical analysis complete. Readmission probability is {prob*100:.1f} percent, classified as {level} risk.", AVATARS["medoracle"]["color"])
        render_disclaimer()

with tabs[1]:
    if "mo_row" not in st.session_state:
        st.info("Run a Clinical Assessment first to enable the What-If Simulator.")
    else:
        base_row = st.session_state["mo_row"].copy()
        base_prob = st.session_state["mo_prob"]

        chat_message("medoracle", f"Baseline risk: <strong>{base_prob*100:.1f}%</strong>. Let me show you how different interventions could change this.")

        scenarios = []
        if base_row.get("A1Cresult") == "Not_Tested":
            alt = base_row.copy(); alt["A1Cresult"] = "Norm"
            r = pd.DataFrame([alt])
            for f in features:
                if f not in r.columns: r[f] = 0
            scenarios.append(("If HbA1c had been tested (normal)", model.predict_proba(r[features])[0][1]))

        if base_row.get("num_medications", 0) >= 10:
            alt = base_row.copy(); alt["num_medications"] = max(base_row["num_medications"] - 5, 1)
            r = pd.DataFrame([alt])
            for f in features:
                if f not in r.columns: r[f] = 0
            scenarios.append((f"Medications reduced to {alt['num_medications']}", model.predict_proba(r[features])[0][1]))

        if base_row.get("number_inpatient", 0) >= 1:
            alt = base_row.copy(); alt["number_inpatient"] = 0; alt["total_prior_visits"] = base_row.get("number_outpatient",0)+base_row.get("number_emergency",0)
            r = pd.DataFrame([alt])
            for f in features:
                if f not in r.columns: r[f] = 0
            scenarios.append(("If no prior inpatient stays", model.predict_proba(r[features])[0][1]))

        alt = base_row.copy(); alt["discharge_disposition_id"] = 6
        r = pd.DataFrame([alt])
        for f in features:
            if f not in r.columns: r[f] = 0
        scenarios.append(("Discharged with home health services", model.predict_proba(r[features])[0][1]))

        if scenarios:
            names = ["Current"] + [s[0] for s in scenarios]
            probs = [base_prob * 100] + [s[1] * 100 for s in scenarios]
            colors = ["#7C3AED"] + ["#10B981" if p < base_prob*100 else "#EF4444" for p in probs[1:]]

            fig = go.Figure(go.Bar(
                x=probs, y=names, orientation='h',
                marker_color=colors,
                text=[f"{p:.1f}%" for p in probs],
                textposition="outside",
                textfont=dict(color="#0F172A")
            ))
            fig.update_layout(
                paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
                font=dict(color='#0F172A'), height=60 + len(names) * 60,
                margin=dict(l=20, r=80, t=10, b=10),
                xaxis=dict(title="Readmission Probability (%)", gridcolor='#E2E8F0'),
                yaxis=dict(autorange="reversed"),
            )
            st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})
        else:
            st.info("No significant what-if scenarios available.")

        tts_button("The what-if simulator shows how changing different factors affects readmission risk.", AVATARS["medoracle"]["color"])

with tabs[2]:
    st.markdown("""
    <p style="color:var(--text-secondary); font-size:0.9rem;">
        Load sample patients from the test set to rank by readmission risk.
        Designed for care coordinators to prioritize follow-up calls.
    </p>
    """, unsafe_allow_html=True)

    if st.button("Load Sample Patients (from test set)", type="primary", use_container_width=True):
        try:
            X_test = pd.read_parquet(DATA_DIR / "readmission" / "X_test.parquet")
            sample = X_test.sample(20, random_state=42)
            for f in features:
                if f not in sample.columns: sample[f] = 0
            probs = model.predict_proba(sample[features])[:, 1]

            results = pd.DataFrame({
                "Patient #": range(1, 21),
                "Risk (%)": (probs * 100).round(1),
                "Level": ["HIGH" if p >= 0.25 else "MEDIUM" if p >= 0.14 else "LOW" for p in probs],
                "Age": sample["age_ordinal"].map(AGE_RANGES).values,
                "Meds": sample["num_medications"].values.astype(int),
                "Diagnoses": sample["number_diagnoses"].values.astype(int),
            }).sort_values("Risk (%)", ascending=False).reset_index(drop=True)

            high_count = (results["Level"] == "HIGH").sum()
            med_count = (results["Level"] == "MEDIUM").sum()

            c1, c2, c3 = st.columns(3)
            with c1:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#EF4444;">{high_count}</div><div class="metric-label">High Risk</div></div>', unsafe_allow_html=True)
            with c2:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#F59E0B;">{med_count}</div><div class="metric-label">Medium Risk</div></div>', unsafe_allow_html=True)
            with c3:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#10B981;">{20-high_count-med_count}</div><div class="metric-label">Low Risk</div></div>', unsafe_allow_html=True)

            st.dataframe(results, use_container_width=True, height=400)
        except Exception as e:
            st.error(f"Could not load test data: {e}")

    st.markdown("""
    <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:14px; padding:1rem 1.2rem; margin-top:1rem;">
        <span style="font-size:0.8rem; color:#94A3B8;">
            <strong>Model:</strong> XGBoost &bull; 38 clinical features &bull;
            Calibrated (isotonic) &bull; ROC-AUC: 0.658 &bull; PR-AUC: 0.221 (1.95x baseline)
        </span>
    </div>
    """, unsafe_allow_html=True)
    render_disclaimer()
