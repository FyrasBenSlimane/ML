import streamlit as st
import sys
import pandas as pd
import plotly.graph_objects as go
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from utils import (
    inject_global_css, render_avatar_header, render_disclaimer,
    render_sidebar, check_portal,
    load_model, tts_button, chat_message, AVATARS, AGE_RANGES, DIAG_GROUPS
)

st.set_page_config(page_title="RxPredict — Treatment Predictor", page_icon="💊", layout="wide")
inject_global_css()
render_sidebar()
check_portal(["medical"])
render_avatar_header("rxpredict")

model_change, feats_change = load_model("rxpredict_change")
model_insulin, feats_insulin = load_model("rxpredict_insulin")

chat_message("rxpredict",
    "I'm <strong>RxPredict</strong>. I answer two critical questions at admission:<br>"
    "<strong>1.</strong> Will this patient's treatment change during their stay?<br>"
    "<strong>2.</strong> Will they need insulin?"
)

with st.form("rx_form"):
    st.markdown("##### Patient Information")
    c1, c2, c3 = st.columns(3)
    with c1:
        age = st.selectbox("Age range", list(AGE_RANGES.keys()), format_func=lambda x: AGE_RANGES[x], index=6)
        gender = st.selectbox("Gender", ["Female", "Male"])
        race = st.selectbox("Race", ["Caucasian", "AfricanAmerican", "Hispanic", "Asian", "Other", "Unknown"])
        time_hosp = st.slider("Days in hospital", 1, 14, 5)
        admission_type = st.selectbox("Admission type", [1,2,3,5],
            format_func=lambda x: {1:"Emergency",2:"Urgent",3:"Elective",5:"Not Available"}.get(x,str(x)))
    with c2:
        num_meds = st.slider("Current medications", 1, 80, 12)
        num_diag = st.slider("Number of diagnoses", 1, 16, 6)
        num_lab = st.slider("Lab procedures", 1, 132, 40)
        num_proc = st.slider("Procedures", 0, 6, 1)
        num_changes = st.slider("Prior medication changes", 0, 20, 1)
    with c3:
        n_out = st.number_input("Outpatient visits (year)", 0, 50, 1)
        n_er = st.number_input("Emergency visits (year)", 0, 30, 0)
        n_inp = st.number_input("Inpatient visits (year)", 0, 20, 1)
        discharge = st.selectbox("Discharge disposition", [1,3,6],
            format_func=lambda x: {1:"Home",3:"SNF",6:"Home health"}.get(x,str(x)))
        dmmed = st.selectbox("Diabetes medication?", ["Yes", "No"])

    c4, c5 = st.columns(2)
    with c4:
        diag1 = st.selectbox("Primary diagnosis", DIAG_GROUPS)
        diag2 = st.selectbox("Secondary diagnosis", DIAG_GROUPS, index=9)
        diag3 = st.selectbox("Tertiary diagnosis", DIAG_GROUPS, index=9)
    with c5:
        a1c = st.selectbox("HbA1c result", ["Not_Tested", "Norm", ">7", ">8"])
        glu = st.selectbox("Glucose serum", ["Not_Tested", "Norm", ">200", ">300"])
        insulin_p = st.selectbox("Currently on insulin?", [0, 1], format_func=lambda x: "Yes" if x else "No")
        metformin_p = st.selectbox("Currently on metformin?", [0, 1], format_func=lambda x: "Yes" if x else "No")

    submitted = st.form_submit_button("Predict Treatment Path", type="primary", use_container_width=True)

if submitted:
    base = {
        "age_ordinal": age, "gender": gender, "race": race,
        "time_in_hospital": time_hosp, "num_medications": num_meds,
        "number_diagnoses": num_diag, "total_prior_visits": n_out+n_er+n_inp,
        "num_lab_procedures": num_lab, "num_procedures": num_proc,
        "diag_1_group": diag1, "diag_2_group": diag2, "diag_3_group": diag3,
        "A1Cresult": a1c, "max_glu_serum": glu,
        "admission_type_id": admission_type, "discharge_disposition_id": discharge,
        "diabetesMed": dmmed, "num_med_changes": num_changes,
        "number_outpatient": n_out, "number_emergency": n_er, "number_inpatient": n_inp,
        "insulin_prescrite": insulin_p, "metformin_prescrite": metformin_p,
    }

    row_c = pd.DataFrame([base])
    for f in feats_change:
        if f not in row_c.columns: row_c[f] = 0
    prob_change = model_change.predict_proba(row_c[feats_change])[0][1]

    row_i = pd.DataFrame([base])
    for f in feats_insulin:
        if f not in row_i.columns: row_i[f] = 0
    prob_insulin = model_insulin.predict_proba(row_i[feats_insulin])[0][1]

    st.markdown('<div class="section-title"><span>Prediction Results</span></div>', unsafe_allow_html=True)

    c1, c2 = st.columns(2)
    with c1:
        chg_color = "#EF4444" if prob_change > 0.6 else ("#F59E0B" if prob_change > 0.4 else "#10B981")
        chg_label = "LIKELY" if prob_change > 0.5 else "UNLIKELY"
        st.markdown(f"""
        <div class="result-container" style="text-align:center; border-left:4px solid {chg_color};">
            <div style="font-size:0.8rem; color:var(--text-secondary); text-transform:uppercase; letter-spacing:2px;">Treatment Change</div>
            <div style="font-size:3rem; font-weight:900; color:{chg_color}; margin:0.5rem 0;">{prob_change*100:.0f}%</div>
            <div style="font-size:1rem; font-weight:700; color:{chg_color};">{chg_label}</div>
            <div class="risk-gauge" style="margin-top:1rem;">
                <div class="risk-fill" style="width:{prob_change*100:.0f}%; background:{chg_color};"></div>
            </div>
            <p style="color:var(--text-secondary); font-size:0.8rem; margin-top:0.5rem;">Probability medication will be changed</p>
        </div>
        """, unsafe_allow_html=True)

    with c2:
        ins_color = "#EF4444" if prob_insulin > 0.6 else ("#F59E0B" if prob_insulin > 0.3 else "#10B981")
        ins_label = "LIKELY" if prob_insulin > 0.5 else "UNLIKELY"
        st.markdown(f"""
        <div class="result-container" style="text-align:center; border-left:4px solid {ins_color};">
            <div style="font-size:0.8rem; color:var(--text-secondary); text-transform:uppercase; letter-spacing:2px;">Insulin Need</div>
            <div style="font-size:3rem; font-weight:900; color:{ins_color}; margin:0.5rem 0;">{prob_insulin*100:.0f}%</div>
            <div style="font-size:1rem; font-weight:700; color:{ins_color};">{ins_label}</div>
            <div class="risk-gauge" style="margin-top:1rem;">
                <div class="risk-fill" style="width:{prob_insulin*100:.0f}%; background:{ins_color};"></div>
            </div>
            <p style="color:var(--text-secondary); font-size:0.8rem; margin-top:0.5rem;">Probability insulin will be needed</p>
        </div>
        """, unsafe_allow_html=True)

    st.markdown('<div class="section-title"><span>Clinical Decision Matrix</span></div>', unsafe_allow_html=True)

    if prob_change > 0.5 and prob_insulin > 0.5:
        scenario = "Both treatment change and insulin adjustment are likely"
        reco = "Prepare pharmacy consult and insulin protocol. Alert endocrinology if available."
        color = "#EF4444"
    elif prob_change > 0.5:
        scenario = "Treatment change likely, but insulin stable"
        reco = "Review current medication interactions. Consider pharmacy review on discharge."
        color = "#F59E0B"
    elif prob_insulin > 0.5:
        scenario = "Insulin adjustment likely, treatment otherwise stable"
        reco = "Prepare insulin titration protocol. Ensure patient education on injection technique."
        color = "#F59E0B"
    else:
        scenario = "Treatment likely to remain stable"
        reco = "Standard monitoring. Continue current regimen with routine checks."
        color = "#10B981"

    st.markdown(f"""
    <div class="glass-card" style="border-left:4px solid {color};">
        <div style="font-weight:700; color:var(--text-primary); margin-bottom:0.5rem;">{scenario}</div>
        <div style="color:var(--text-secondary); font-size:0.9rem;">{reco}</div>
    </div>
    """, unsafe_allow_html=True)

    fig = go.Figure()
    fig.add_trace(go.Bar(name="Treatment Change", x=["Treatment Change"], y=[prob_change*100],
        marker_color=chg_color, text=[f"{prob_change*100:.1f}%"], textposition="outside", textfont=dict(color="#0F172A")))
    fig.add_trace(go.Bar(name="Insulin Need", x=["Insulin Need"], y=[prob_insulin*100],
        marker_color=ins_color, text=[f"{prob_insulin*100:.1f}%"], textposition="outside", textfont=dict(color="#0F172A")))
    fig.update_layout(
        paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
        font=dict(color='#0F172A'), height=300,
        margin=dict(l=20, r=20, t=10, b=10),
        yaxis=dict(title="Probability (%)", gridcolor='#E2E8F0', range=[0, 105]),
        showlegend=False, barmode='group',
    )
    st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

    chat_message("rxpredict",
        f"Treatment change: <strong>{prob_change*100:.0f}%</strong> ({chg_label}). "
        f"Insulin need: <strong>{prob_insulin*100:.0f}%</strong> ({ins_label}). "
        f"{scenario}.")

    tts_button(f"Treatment change probability: {prob_change*100:.0f} percent. Insulin need: {prob_insulin*100:.0f} percent. {scenario}.", AVATARS["rxpredict"]["color"])

    st.markdown("""
    <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:14px; padding:1rem 1.2rem; margin-top:1rem;">
        <span style="font-size:0.8rem; color:#94A3B8;">
            <strong>Models:</strong> DecisionTree (max_depth=8, balanced) &bull;
            Treatment change: ROC-AUC 0.941 &bull; Insulin: ROC-AUC 0.986
        </span>
    </div>
    """, unsafe_allow_html=True)
    render_disclaimer()
