import streamlit as st
import sys
import pandas as pd
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from utils import (
    inject_global_css, render_avatar_header, render_disclaimer,
    render_sidebar, check_portal,
    load_model, tts_button, chat_message, AVATARS, AGE_RANGES, DIAG_GROUPS
)

st.set_page_config(page_title="DailyGuard — Patient Companion", page_icon="🛡️", layout="wide")
inject_global_css()
render_sidebar()
check_portal(["patient", "medical", "both"])
render_avatar_header("dailyguard")

model_suivi, feats_suivi = load_model("dailyguard_suivi")
model_comp, feats_comp = load_model("dailyguard_compagnon")
model_rappel, feats_rappel = load_model("dailyguard_rappel")

chat_message("dailyguard",
    "Hi! I'm <strong>DailyGuard</strong>, your daily companion. I monitor follow-up quality, "
    "assess digital companion eligibility, and detect medication reminder needs."
)

tabs = st.tabs(["Follow-Up Quality", "Digital Companion", "Medication Reminder"])


def build_shared_form(form_key):
    with st.form(form_key):
        c1, c2 = st.columns(2)
        with c1:
            age = st.selectbox("Age range", list(AGE_RANGES.keys()), format_func=lambda x: AGE_RANGES[x], index=6, key=f"{form_key}_age")
            gender = st.selectbox("Gender", ["Female", "Male"], key=f"{form_key}_gen")
            race = st.selectbox("Race", ["Caucasian","AfricanAmerican","Hispanic","Asian","Other","Unknown"], key=f"{form_key}_race")
            time_hosp = st.slider("Days in hospital", 1, 14, 5, key=f"{form_key}_time")
            num_meds = st.slider("Number of medications", 1, 50, 12, key=f"{form_key}_meds")
            num_diag = st.slider("Number of diagnoses", 1, 16, 6, key=f"{form_key}_diag")
        with c2:
            total_visits = st.slider("Total prior visits (year)", 0, 30, 2, key=f"{form_key}_vis")
            num_lab = st.slider("Lab procedures", 1, 100, 40, key=f"{form_key}_lab")
            num_proc = st.slider("Procedures", 0, 6, 1, key=f"{form_key}_proc")
            diag1 = st.selectbox("Primary diagnosis", DIAG_GROUPS, key=f"{form_key}_d1")
            diag2 = st.selectbox("Secondary diagnosis", DIAG_GROUPS, index=9, key=f"{form_key}_d2")
            diag3 = st.selectbox("Tertiary diagnosis", DIAG_GROUPS, index=9, key=f"{form_key}_d3")

        c3, c4 = st.columns(2)
        with c3:
            a1c = st.selectbox("HbA1c result", ["Not_Tested","Norm",">7",">8"], key=f"{form_key}_a1c")
            glu = st.selectbox("Glucose serum", ["Not_Tested","Norm",">200",">300"], key=f"{form_key}_glu")
        with c4:
            insulin_p = st.selectbox("On insulin?", [0,1], format_func=lambda x: "Yes" if x else "No", key=f"{form_key}_ins")
            metformin_p = st.selectbox("On metformin?", [0,1], format_func=lambda x: "Yes" if x else "No", key=f"{form_key}_met")

        c5, c6 = st.columns(2)
        with c5:
            dmmed = st.selectbox("Diabetes medication?", ["Yes","No"], key=f"{form_key}_dm")
            num_changes = st.slider("Medication changes", 0, 15, 1, key=f"{form_key}_chg")
        with c6:
            admission = st.selectbox("Admission type", [1,2,3], format_func=lambda x: {1:"Emergency",2:"Urgent",3:"Elective"}.get(x), key=f"{form_key}_adm")
            discharge = st.selectbox("Discharge to", [1,3,6], format_func=lambda x: {1:"Home",3:"SNF",6:"Home health"}.get(x), key=f"{form_key}_dis")
            n_out = st.number_input("Outpatient visits", 0, 50, 1, key=f"{form_key}_no")
            n_er = st.number_input("Emergency visits", 0, 30, 0, key=f"{form_key}_ne")
            n_inp = st.number_input("Inpatient visits", 0, 20, 1, key=f"{form_key}_ni")

        submitted = st.form_submit_button("Analyze", type="primary", use_container_width=True)

    data = {
        "age_ordinal": age, "gender": gender, "race": race,
        "time_in_hospital": time_hosp, "num_medications": num_meds,
        "number_diagnoses": num_diag, "total_prior_visits": total_visits,
        "num_lab_procedures": num_lab, "num_procedures": num_proc,
        "diag_1_group": diag1, "diag_2_group": diag2, "diag_3_group": diag3,
        "A1Cresult": a1c, "max_glu_serum": glu,
        "insulin_prescrite": insulin_p, "metformin_prescrite": metformin_p,
        "diabetesMed": dmmed, "num_med_changes": num_changes,
        "admission_type_id": admission, "discharge_disposition_id": discharge,
        "number_outpatient": n_out, "number_emergency": n_er, "number_inpatient": n_inp,
    }
    return submitted, data


def predict_safe(mdl, feats, data):
    row = pd.DataFrame([data])
    for f in feats:
        if f not in row.columns: row[f] = 0
    return mdl.predict_proba(row[feats])[0][1]


def render_binary_result(title, prob, pos_label, neg_label, color_pos, color_neg, desc):
    is_pos = prob > 0.5
    color = color_pos if is_pos else color_neg
    label = pos_label if is_pos else neg_label

    st.markdown(f"""
    <div class="result-container" style="text-align:center; border-left:4px solid {color};">
        <div style="font-size:0.8rem; color:var(--text-secondary); text-transform:uppercase; letter-spacing:2px;">{title}</div>
        <div style="font-size:2.5rem; font-weight:900; color:{color}; margin:0.5rem 0;">{prob*100:.0f}%</div>
        <div style="font-size:1rem; font-weight:700; color:{color};">{label}</div>
        <div class="risk-gauge" style="margin-top:1rem;">
            <div class="risk-fill" style="width:{prob*100:.0f}%; background:{color};"></div>
        </div>
        <p style="color:var(--text-secondary); font-size:0.8rem; margin-top:0.75rem;">{desc}</p>
    </div>
    """, unsafe_allow_html=True)
    return is_pos


with tabs[0]:
    sub, data = build_shared_form("suivi")
    if sub:
        prob = predict_safe(model_suivi, feats_suivi, data)
        is_good = render_binary_result(
            "Follow-Up Quality Prediction", prob,
            "GOOD FOLLOW-UP EXPECTED", "AT RISK — May be insufficient",
            "#10B981", "#EF4444",
            "Composite: HbA1c + glucose tested + adequate prior visits"
        )
        if not is_good:
            st.markdown('<div class="section-title"><span>Recommendations</span></div>', unsafe_allow_html=True)
            for r in ["Order HbA1c test before discharge", "Schedule glucose monitoring protocol",
                       "Book outpatient follow-up within 7 days", "Set up phone check-in at day 3"]:
                st.markdown(f'<div class="advice-card warning"><span>&#x1F4CC;</span><span>{r}</span></div>', unsafe_allow_html=True)

        chat_message("dailyguard", f"Follow-up quality: <strong>{prob*100:.0f}%</strong> probability of adequate monitoring." + (" Looks good!" if is_good else " Some interventions recommended."))
        tts_button(f"Follow-up quality prediction: {prob*100:.0f} percent probability of adequate monitoring.", AVATARS["dailyguard"]["color"])
        render_disclaimer()

with tabs[1]:
    sub2, data2 = build_shared_form("compagnon")
    if sub2:
        prob2 = predict_safe(model_comp, feats_comp, data2)
        is_stable = render_binary_result(
            "Digital Companion Eligibility", prob2,
            "ELIGIBLE — Stable for digital companion", "NOT YET — Needs intensive care",
            "#10B981", "#F59E0B",
            "Criteria: not readmitted + stable treatment + good follow-up"
        )
        if is_stable:
            st.markdown('<div class="section-title"><span>Digital Companion Features</span></div>', unsafe_allow_html=True)
            for f in ["Daily medication reminders via app", "Weekly symptom self-assessment",
                       "Educational diabetes content", "Direct messaging with care team", "Blood sugar tracking"]:
                st.markdown(f'<div class="advice-card success"><span>&#x1F4F1;</span><span>{f}</span></div>', unsafe_allow_html=True)

        chat_message("dailyguard", f"Digital companion eligibility: <strong>{prob2*100:.0f}%</strong>." + (" Patient is a good candidate!" if is_stable else " More intensive monitoring recommended first."))
        tts_button(f"Digital companion assessment: {prob2*100:.0f} percent probability of eligibility.", AVATARS["dailyguard"]["color"])
        render_disclaimer()

with tabs[2]:
    sub3, data3 = build_shared_form("rappel")
    if sub3:
        prob3 = predict_safe(model_rappel, feats_rappel, data3)
        is_risky = render_binary_result(
            "Medication Forgetfulness Risk", prob3,
            "HIGH RISK — Needs reminder support", "LOW RISK — Likely manages independently",
            "#EF4444", "#10B981",
            "Based on: polypharmacy + age + comorbidity count"
        )
        if is_risky:
            st.markdown('<div class="section-title"><span>Recommended Interventions</span></div>', unsafe_allow_html=True)
            for r in [
                "Set up a pill organizer with daily compartments",
                "Enable medication reminder app or smart alerts",
                "Simplify medication schedule (ask pharmacist)",
                "Involve a family member or caregiver",
                "Consider blister pack pharmacy service",
            ]:
                st.markdown(f'<div class="advice-card warning"><span>&#x23F0;</span><span>{r}</span></div>', unsafe_allow_html=True)

        chat_message("dailyguard",
            f"Medication forgetfulness risk: <strong>{prob3*100:.0f}%</strong>." +
            (" High risk — reminder support strongly recommended." if is_risky else " Low risk — patient likely manages well."))
        tts_button(f"Medication forgetfulness risk: {prob3*100:.0f} percent.", AVATARS["dailyguard"]["color"])

        st.markdown("""
        <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:14px; padding:1rem 1.2rem; margin-top:1rem;">
            <span style="font-size:0.8rem; color:#94A3B8;">
                <strong>Models:</strong> DecisionTree (balanced) &bull;
                Follow-up: ROC-AUC 0.944 &bull; Companion: ROC-AUC 0.837 &bull; Reminder: ROC-AUC 1.000
            </span>
        </div>
        """, unsafe_allow_html=True)
        render_disclaimer()
