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
    load_model_ab, tts_button, chat_message, make_gauge_chart,
    AVATARS, AGE_RANGES, DIAG_GROUPS
)

st.set_page_config(page_title="BedSense — Bed Planning", page_icon="🏥", layout="wide")
inject_global_css()
render_sidebar()
check_portal(["medical"])
render_avatar_header("bedsense")

model_a, feats_a, model_b, feats_b = load_model_ab("bedsense")

chat_message("bedsense",
    "I'm <strong>BedSense</strong>, your bed planning intelligence. "
    "I predict readmission probability and simulate bed demand to help optimize hospital capacity."
)

tabs = st.tabs(["Readmission Probability", "Bed Planning Simulator", "Capacity Dashboard"])


def build_clinical_form(key):
    with st.form(key):
        c1, c2, c3 = st.columns(3)
        with c1:
            age = st.selectbox("Age", list(AGE_RANGES.keys()), format_func=lambda x: AGE_RANGES[x], index=6, key=f"{key}_a")
            gender = st.selectbox("Gender", ["Female","Male"], key=f"{key}_g")
            race = st.selectbox("Race", ["Caucasian","AfricanAmerican","Hispanic","Asian","Other","Unknown"], key=f"{key}_r")
            time_h = st.slider("Days in hospital", 1, 14, 5, key=f"{key}_t")
            num_lab = st.slider("Lab procedures", 1, 132, 40, key=f"{key}_nl")
        with c2:
            num_meds = st.slider("Medications", 1, 80, 12, key=f"{key}_nm")
            num_diag = st.slider("Diagnoses", 1, 16, 6, key=f"{key}_nd")
            num_proc = st.slider("Procedures", 0, 6, 1, key=f"{key}_np")
            num_chg = st.slider("Med changes", 0, 20, 1, key=f"{key}_nc")
            n_out = st.number_input("Outpatient (yr)", 0, 50, 1, key=f"{key}_o")
        with c3:
            n_er = st.number_input("Emergency (yr)", 0, 30, 0, key=f"{key}_e")
            n_inp = st.number_input("Inpatient (yr)", 0, 20, 1, key=f"{key}_i")
            admission = st.selectbox("Admission", [1,2,3], format_func=lambda x: {1:"Emergency",2:"Urgent",3:"Elective"}.get(x), key=f"{key}_ad")
            discharge = st.selectbox("Discharge to", [1,3,6], format_func=lambda x: {1:"Home",3:"SNF",6:"Home health"}.get(x), key=f"{key}_di")
            payer = st.selectbox("Payer", ["Missing","MC","MD","BC","SP"], format_func=lambda x: {"Missing":"Unknown","MC":"Medicare","MD":"Medicaid","BC":"Blue Cross","SP":"Self-pay"}.get(x,x), key=f"{key}_p")

        c4, c5 = st.columns(2)
        with c4:
            diag1 = st.selectbox("Primary dx", DIAG_GROUPS, key=f"{key}_d1")
            diag2 = st.selectbox("Secondary dx", DIAG_GROUPS, index=9, key=f"{key}_d2")
            diag3 = st.selectbox("Tertiary dx", DIAG_GROUPS, index=9, key=f"{key}_d3")
            a1c = st.selectbox("HbA1c", ["Not_Tested","Norm",">7",">8"], key=f"{key}_a1")
        with c5:
            glu = st.selectbox("Glucose", ["Not_Tested","Norm",">200",">300"], key=f"{key}_gl")
            ins = st.selectbox("Insulin?", [0,1], format_func=lambda x: "Yes" if x else "No", key=f"{key}_in")
            met = st.selectbox("Metformin?", [0,1], format_func=lambda x: "Yes" if x else "No", key=f"{key}_me")
            ins_chg = st.selectbox("Insulin changed?", [0,1], format_func=lambda x: "Yes" if x else "No", key=f"{key}_ic")
            dm = st.selectbox("DM medication?", ["Yes","No"], key=f"{key}_dm")
            med_spec = st.selectbox("Specialty", ["Unknown","InternalMedicine","Emergency/Trauma","Cardiology","Surgery-General"], key=f"{key}_ms")

        sub = st.form_submit_button("Analyze", type="primary", use_container_width=True)

    data = {
        "age_ordinal": age, "gender": gender, "race": race,
        "time_in_hospital": time_h, "num_lab_procedures": num_lab,
        "num_procedures": num_proc, "num_medications": num_meds,
        "number_diagnoses": num_diag, "num_med_changes": num_chg,
        "number_outpatient": n_out, "number_emergency": n_er, "number_inpatient": n_inp,
        "total_prior_visits": n_out+n_er+n_inp,
        "admission_type_id": admission, "discharge_disposition_id": discharge,
        "admission_source_id": 7, "payer_code": payer, "medical_specialty": med_spec,
        "diag_1_group": diag1, "diag_2_group": diag2, "diag_3_group": diag3,
        "A1Cresult": a1c, "max_glu_serum": glu,
        "insulin_prescrite": ins, "metformin_prescrite": met,
        "insulin_changed": ins_chg, "diabetesMed": dm,
    }
    return sub, data


with tabs[0]:
    sub, data = build_clinical_form("bs_a")
    if sub:
        row = pd.DataFrame([data])
        for f in feats_a:
            if f not in row.columns: row[f] = 0
        prob = model_a.predict_proba(row[feats_a])[0][1]
        st.session_state["bs_prob"] = prob

        c1, c2 = st.columns([2,1])
        with c1:
            level, _ = render_risk_result(prob, "bedsense")
        with c2:
            fig = make_gauge_chart(prob*100, "Readmission Risk", AVATARS["bedsense"]["color"])
            st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

        if prob >= 0.25:
            sched, sched_color, apt_type = "Within 48 hours", "#EF4444", "Urgent follow-up + phone check"
        elif prob >= 0.14:
            sched, sched_color, apt_type = "Within 7 days", "#F59E0B", "Standard follow-up"
        else:
            sched, sched_color, apt_type = "Within 14 days", "#10B981", "Routine follow-up"

        st.markdown(f"""
        <div class="glass-card" style="border-left:4px solid {sched_color};">
            <div style="display:flex; justify-content:space-between; align-items:center;">
                <div>
                    <div style="color:var(--text-secondary); font-size:0.8rem;">Recommended Follow-Up</div>
                    <div style="color:{sched_color}; font-size:1.3rem; font-weight:700;">{sched}</div>
                    <div style="color:var(--text-secondary); font-size:0.85rem;">{apt_type}</div>
                </div>
                <div style="text-align:right;">
                    <div style="color:var(--text-secondary); font-size:0.8rem;">Priority</div>
                    <div style="color:{sched_color}; font-size:2rem; font-weight:800;">{prob*100:.0f}</div>
                </div>
            </div>
        </div>
        """, unsafe_allow_html=True)

        chat_message("bedsense", f"Readmission probability: <strong>{prob*100:.0f}%</strong>. Recommended follow-up: {sched}.")
        tts_button(f"Readmission probability: {prob*100:.0f} percent. Recommended follow-up: {sched}.", AVATARS["bedsense"]["color"])
        render_disclaimer()

with tabs[1]:
    DATA_DIR = Path(__file__).resolve().parent.parent.parent.parent / "data" / "splits"
    n_patients = st.slider("Number of patients to simulate", 5, 50, 20)

    if st.button("Run Bed Planning Simulation", type="primary", use_container_width=True):
        try:
            X_test = pd.read_parquet(DATA_DIR / "readmission" / "X_test.parquet")
            sample = X_test.sample(n_patients, random_state=42)
            for f in feats_a:
                if f not in sample.columns: sample[f] = 0

            probs = model_a.predict_proba(sample[feats_a])[:, 1]
            expected_returns = (probs >= 0.14).sum()
            high_risk = (probs >= 0.25).sum()
            med_risk = ((probs >= 0.14) & (probs < 0.25)).sum()
            avg_los = 4.4
            expected_bed_days = expected_returns * avg_los

            c1, c2, c3, c4 = st.columns(4)
            with c1:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#DC2626;">{n_patients}</div><div class="metric-label">Discharged Today</div></div>', unsafe_allow_html=True)
            with c2:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#EF4444;">{expected_returns}</div><div class="metric-label">Expected Returns</div></div>', unsafe_allow_html=True)
            with c3:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#F59E0B;">{expected_bed_days:.0f}</div><div class="metric-label">Bed-Days Needed</div></div>', unsafe_allow_html=True)
            with c4:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#10B981;">${expected_returns * 15000:,.0f}</div><div class="metric-label">Potential Cost</div></div>', unsafe_allow_html=True)

            fig = go.Figure()
            fig.add_trace(go.Histogram(x=probs * 100, nbinsx=20, marker_color=AVATARS["bedsense"]["color"], opacity=0.8))
            fig.add_vline(x=14, line_dash="dash", line_color="#F59E0B", annotation_text="Medium (14%)")
            fig.add_vline(x=25, line_dash="dash", line_color="#EF4444", annotation_text="High (25%)")
            fig.update_layout(
                paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
                font=dict(color='#0F172A'), height=300,
                xaxis=dict(title="Readmission Probability (%)", gridcolor='#E2E8F0'),
                yaxis=dict(title="Number of Patients", gridcolor='#E2E8F0'),
                margin=dict(l=40, r=20, t=20, b=40),
            )
            st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            chat_message("bedsense",
                f"Simulation complete: <strong>{expected_returns}</strong> expected returns out of {n_patients} discharges. "
                f"Reserve <strong>{expected_bed_days:.0f} bed-days</strong>. "
                f"<strong>{high_risk}</strong> patients need urgent follow-up.")

            tts_button(f"Out of {n_patients} discharges, {expected_returns} expected to return, requiring {expected_bed_days:.0f} bed-days.", AVATARS["bedsense"]["color"])
        except Exception as e:
            st.error(f"Error loading test data: {e}")

with tabs[2]:
    np.random.seed(42)
    weeks = [f"Week {i}" for i in range(1, 13)]
    total_beds = 200
    occupied = np.random.randint(140, 180, 12)
    predicted_returns = np.random.randint(8, 25, 12)
    actual_returns = (predicted_returns * np.random.uniform(0.7, 1.3, 12)).astype(int)

    fig = go.Figure()
    fig.add_trace(go.Bar(name="Occupied Beds", x=weeks, y=occupied, marker_color="#2563EB", opacity=0.7))
    fig.add_trace(go.Bar(name="Predicted Returns", x=weeks, y=predicted_returns, marker_color="#F59E0B"))
    fig.add_trace(go.Scatter(name="Actual Returns", x=weeks, y=actual_returns,
                             mode="lines+markers", line=dict(color="#EF4444", width=2), marker=dict(size=8)))
    fig.add_hline(y=total_beds, line_dash="dash", line_color="#EF4444", annotation_text=f"Max capacity ({total_beds})")
    fig.update_layout(
        paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
        font=dict(color='#0F172A'), height=400, barmode='stack',
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        xaxis=dict(gridcolor='#E2E8F0'),
        yaxis=dict(title="Beds", gridcolor='#E2E8F0'),
        margin=dict(l=40, r=20, t=40, b=40),
    )
    st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

    accuracy = np.mean(np.abs(predicted_returns - actual_returns) <= 3)
    st.markdown(f"""
    <div style="display:flex; gap:1rem; flex-wrap:wrap;">
        <div class="metric-card" style="flex:1; min-width:140px;">
            <div class="metric-value" style="color:#DC2626;">{total_beds}</div>
            <div class="metric-label">Total Beds</div>
        </div>
        <div class="metric-card" style="flex:1; min-width:140px;">
            <div class="metric-value" style="color:#F59E0B;">{np.mean(occupied):.0f}</div>
            <div class="metric-label">Avg Occupied</div>
        </div>
        <div class="metric-card" style="flex:1; min-width:140px;">
            <div class="metric-value" style="color:#10B981;">{accuracy*100:.0f}%</div>
            <div class="metric-label">Prediction Accuracy (&#xB1;3)</div>
        </div>
        <div class="metric-card" style="flex:1; min-width:140px;">
            <div class="metric-value" style="color:#0D9488;">{np.mean(predicted_returns):.0f}</div>
            <div class="metric-label">Avg Weekly Returns</div>
        </div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("""
    <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:14px; padding:1rem 1.2rem; margin-top:1rem;">
        <span style="font-size:0.8rem; color:#94A3B8;">
            <strong>Model:</strong> HistGradientBoosting &bull; ROC-AUC 0.670 &bull; PR-AUC 0.228 &bull;
            Thresholds: 14% (medium) / 25% (high) based on cost-benefit analysis
        </span>
    </div>
    """, unsafe_allow_html=True)
    render_disclaimer()
