import streamlit as st
import sys
import pandas as pd
import numpy as np
import plotly.graph_objects as go
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from utils import (
    inject_global_css, render_avatar_header, render_risk_result,
    render_advice_cards, render_disclaimer, render_sidebar,
    load_model, tts_button, chat_message, make_gauge_chart,
    generate_reasons, generate_actions, check_portal,
    AVATARS, AGE_RANGES, DIAG_GROUPS, DIAG_PLAIN
)

st.set_page_config(page_title="Teemo — Readmission Intelligence", page_icon="🏥", layout="wide")
inject_global_css()
render_sidebar()

portal = st.session_state.get("portal_type", "patient")
if portal == "patient":
    check_portal(["patient", "both"])
else:
    check_portal(["medical", "both", "patient"])

render_avatar_header("teemo")

MODEL_DIR = Path(__file__).resolve().parent.parent.parent / "models"
DATA_DIR = Path(__file__).resolve().parent.parent.parent.parent / "data" / "splits"

import joblib

@st.cache_resource
def load_full_model():
    base = joblib.load(MODEL_DIR / "teemo_full_base.joblib")
    calibrator = joblib.load(MODEL_DIR / "teemo_full_calibrator.joblib")
    features = joblib.load(MODEL_DIR / "teemo_full_features.joblib")
    cat_cols = joblib.load(MODEL_DIR / "teemo_full_catcols.joblib")
    return base, calibrator, features, cat_cols

@st.cache_resource
def load_patient_model():
    return load_model("teemo")

full_base, full_calibrator, full_features, full_catcols = load_full_model()
patient_model, patient_features = load_patient_model()


def predict_full(df):
    for c in full_catcols:
        if c in df.columns:
            df[c] = df[c].astype("category")
    raw = full_base.predict_proba(df[full_features])[:, 1]
    cal = full_calibrator.predict(raw)
    return cal


COST_READMIT = 15_000
COST_INTERVENTION = 300
P_PREVENTION = 0.25
OPTIMAL_THRESHOLD = COST_INTERVENTION / (P_PREVENTION * COST_READMIT)


if portal == "patient":
    tabs = st.tabs(["My Risk Assessment"])
    tab_patient = tabs[0]
    tab_nurse = tab_coordinator = tab_manager = None
else:
    tabs = st.tabs(["Nurse View", "Coordinator View", "Manager View", "Patient View"])
    tab_nurse, tab_coordinator, tab_manager, tab_patient = tabs


def build_full_form(key):
    with st.form(key):
        st.markdown("##### Demographics & Admission")
        c1, c2, c3 = st.columns(3)
        with c1:
            age = st.selectbox("Age range", list(AGE_RANGES.keys()), format_func=lambda x: AGE_RANGES[x], index=6, key=f"{key}_age")
            gender = st.selectbox("Gender", ["Female", "Male"], key=f"{key}_gen")
            race = st.selectbox("Race", ["Caucasian", "AfricanAmerican", "Hispanic", "Asian", "Other", "Unknown"], key=f"{key}_race")
        with c2:
            admission_type = st.selectbox("Admission type", [1, 2, 3], format_func=lambda x: {1: "Emergency", 2: "Urgent", 3: "Elective"}.get(x), key=f"{key}_adm")
            discharge = st.selectbox("Discharge to", [1, 3, 6], format_func=lambda x: {1: "Home", 3: "SNF", 6: "Home health"}.get(x), key=f"{key}_dis")
            admission_source = st.selectbox("Admission source", [1, 2, 7], format_func=lambda x: {1: "Physician referral", 2: "Clinic referral", 7: "ER"}.get(x), key=f"{key}_src")
        with c3:
            payer = st.selectbox("Payer", ["Missing", "MC", "MD", "BC", "SP"], format_func=lambda x: {"Missing": "Unknown", "MC": "Medicare", "MD": "Medicaid", "BC": "Blue Cross", "SP": "Self-pay"}.get(x, x), key=f"{key}_pay")
            med_spec = st.selectbox("Specialty", ["Unknown", "InternalMedicine", "Emergency/Trauma", "Cardiology", "Surgery-General", "Nephrology", "Orthopedics", "Pulmonology", "Family/GeneralPractice"], key=f"{key}_spec")

        st.markdown("##### Clinical Measures")
        c4, c5, c6 = st.columns(3)
        with c4:
            time_h = st.slider("Days in hospital", 1, 14, 5, key=f"{key}_time")
            num_lab = st.slider("Lab procedures", 1, 132, 40, key=f"{key}_lab")
            num_proc = st.slider("Procedures", 0, 6, 1, key=f"{key}_proc")
        with c5:
            num_meds = st.slider("Medications", 1, 80, 15, key=f"{key}_meds")
            num_diag = st.slider("Diagnoses", 1, 16, 7, key=f"{key}_diag")
            num_chg = st.slider("Med changes", 0, 20, 2, key=f"{key}_chg")
        with c6:
            n_out = st.number_input("Outpatient (yr)", 0, 50, 1, key=f"{key}_out")
            n_er = st.number_input("Emergency (yr)", 0, 30, 0, key=f"{key}_er")
            n_inp = st.number_input("Inpatient (yr)", 0, 20, 1, key=f"{key}_inp")

        st.markdown("##### Diagnoses & Treatment")
        c7, c8 = st.columns(2)
        with c7:
            diag1 = st.selectbox("Primary dx group", DIAG_GROUPS, key=f"{key}_d1")
            diag2 = st.selectbox("Secondary dx group", DIAG_GROUPS, index=9, key=f"{key}_d2")
            diag3 = st.selectbox("Tertiary dx group", DIAG_GROUPS, index=9, key=f"{key}_d3")
            a1c = st.selectbox("HbA1c", ["Not_Tested", "Norm", ">7", ">8"], key=f"{key}_a1c")
            glu = st.selectbox("Glucose", ["Not_Tested", "Norm", ">200", ">300"], key=f"{key}_glu")
        with c8:
            insulin_p = st.selectbox("Insulin?", [0, 1], format_func=lambda x: "Yes" if x else "No", key=f"{key}_ins")
            metformin_p = st.selectbox("Metformin?", [0, 1], format_func=lambda x: "Yes" if x else "No", key=f"{key}_met")
            insulin_chg = st.selectbox("Insulin changed?", [0, 1], format_func=lambda x: "Yes" if x else "No", key=f"{key}_ic")
            dmmed = st.selectbox("DM medication?", ["Yes", "No"], key=f"{key}_dm")
            metformin_val = st.selectbox("Metformin Rx", ["No", "Steady", "Up", "Down"], key=f"{key}_metv")
            repaglinide = st.selectbox("Repaglinide", ["No", "Steady", "Up", "Down"], key=f"{key}_rep")

        sub = st.form_submit_button("Analyze Patient", type="primary", use_container_width=True)

    data = {
        "age_ordinal": age, "gender": gender, "race": race,
        "admission_type_id": admission_type, "discharge_disposition_id": discharge,
        "admission_source_id": admission_source, "payer_code": payer,
        "medical_specialty": med_spec, "time_in_hospital": time_h,
        "num_lab_procedures": num_lab, "num_procedures": num_proc,
        "num_medications": num_meds, "number_diagnoses": num_diag,
        "num_med_changes": num_chg,
        "number_outpatient": n_out, "number_emergency": n_er,
        "number_inpatient": n_inp, "total_prior_visits": n_out + n_er + n_inp,
        "diag_1_group": diag1, "diag_2_group": diag2, "diag_3_group": diag3,
        "A1Cresult": a1c, "max_glu_serum": glu,
        "insulin_prescrite": insulin_p, "metformin_prescrite": metformin_p,
        "insulin_changed": insulin_chg, "diabetesMed": dmmed,
        "metformin": metformin_val, "repaglinide": repaglinide,
        "nateglinide": "No", "glimepiride": "No", "glipizide": "No",
        "glyburide": "No", "pioglitazone": "No", "rosiglitazone": "No",
        "insulin": "Steady" if insulin_p else "No",
        "glipizide-metformin": "No",
        "age": AGE_RANGES.get(age, "60-70"),
    }
    return sub, data


# ════════════════════════════════════════
#  NURSE VIEW
# ════════════════════════════════════════
if tab_nurse is not None:
    with tab_nurse:
        chat_message("teemo",
            "Welcome, nurse. I'm <strong>Teemo</strong> — Ryma's full readmission model. "
            "Enter a patient's complete clinical data for risk assessment with "
            "<strong>SHAP explanations</strong> and <strong>cost-based threshold</strong> analysis."
        )

        sub, data = build_full_form("nurse")
        if sub:
            row = pd.DataFrame([data])
            for f in full_features:
                if f not in row.columns:
                    row[f] = 0
            prob = predict_full(row)[0]

            st.session_state["teemo_prob"] = prob
            st.session_state["teemo_row"] = data

            c1, c2 = st.columns([2, 1])
            with c1:
                level, advice = render_risk_result(prob, "teemo")
            with c2:
                fig = make_gauge_chart(prob * 100, "Calibrated Risk", AVATARS["teemo"]["color"])
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            st.markdown('<div class="section-title"><span>Cost-Based Threshold Analysis</span></div>', unsafe_allow_html=True)

            net_benefit = prob * P_PREVENTION * COST_READMIT - COST_INTERVENTION
            flag = prob >= OPTIMAL_THRESHOLD
            flag_color = "#10B981" if flag else "#64748B"
            flag_label = "FLAG — Intervene" if flag else "Below threshold"

            st.markdown(f"""
            <div class="glass-card" style="border-left:4px solid {flag_color};">
                <div style="display:flex; justify-content:space-between; flex-wrap:wrap; gap:1rem;">
                    <div>
                        <div style="font-size:0.75rem; color:var(--text-secondary); text-transform:uppercase; letter-spacing:1px;">Decision</div>
                        <div style="font-size:1.3rem; font-weight:800; color:{flag_color};">{flag_label}</div>
                        <div style="font-size:0.85rem; color:var(--text-secondary); margin-top:0.3rem;">
                            Optimal threshold: {OPTIMAL_THRESHOLD*100:.1f}% &bull; Patient risk: {prob*100:.1f}%
                        </div>
                    </div>
                    <div style="text-align:right;">
                        <div style="font-size:0.75rem; color:var(--text-secondary);">Expected Net Benefit</div>
                        <div style="font-size:1.5rem; font-weight:800; color:{'#10B981' if net_benefit > 0 else '#EF4444'};">
                            ${net_benefit:,.0f}
                        </div>
                        <div style="font-size:0.75rem; color:var(--text-secondary);">
                            Readmit cost: ${COST_READMIT:,} &bull; Intervention: ${COST_INTERVENTION} &bull; Prevention: {P_PREVENTION*100:.0f}%
                        </div>
                    </div>
                </div>
            </div>
            """, unsafe_allow_html=True)

            st.markdown('<div class="section-title"><span>SHAP Feature Explanations</span></div>', unsafe_allow_html=True)

            try:
                import shap
                for c in full_catcols:
                    if c in row.columns:
                        row[c] = row[c].astype("category")
                explainer = shap.TreeExplainer(full_base)
                shap_values = explainer.shap_values(row[full_features])
                if isinstance(shap_values, list):
                    sv = shap_values[1][0]
                else:
                    sv = shap_values[0]

                feat_importance = sorted(zip(full_features, sv), key=lambda x: abs(x[1]), reverse=True)[:10]
                names = [f[0] for f in feat_importance]
                vals = [f[1] for f in feat_importance]
                colors = ["#EF4444" if v > 0 else "#10B981" for v in vals]

                fig = go.Figure(go.Bar(
                    x=vals, y=names, orientation="h",
                    marker_color=colors,
                    text=[f"{v:+.3f}" for v in vals],
                    textposition="outside",
                    textfont=dict(color="#0F172A", size=11),
                ))
                fig.update_layout(
                    title=dict(text="Top 10 Features Driving This Prediction", font=dict(size=14, color="#64748B")),
                    paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
                    font=dict(color="#0F172A"), height=380,
                    margin=dict(l=20, r=80, t=40, b=20),
                    xaxis=dict(title="SHAP Value (impact on risk)", gridcolor="#E2E8F0", zeroline=True, zerolinecolor="#94A3B8"),
                    yaxis=dict(autorange="reversed"),
                )
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

                st.markdown("""
                <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:14px; padding:0.8rem 1.2rem; font-size:0.8rem; color:#64748B;">
                    <strong>Reading SHAP:</strong> Red bars push risk <strong>higher</strong>, green bars push it <strong>lower</strong>.
                    Longer bars = stronger influence on this patient's score.
                </div>
                """, unsafe_allow_html=True)
            except Exception as e:
                st.warning(f"SHAP explanations unavailable: {e}")

            reasons = generate_reasons(pd.Series(data), full_features)
            actions = generate_actions(reasons, level)
            render_advice_cards(reasons, actions)

            chat_message("teemo",
                f"Risk: <strong>{prob*100:.1f}%</strong> ({level}). "
                f"{'Intervention recommended' if flag else 'Below cost threshold'}. "
                f"Net benefit: <strong>${net_benefit:,.0f}</strong>."
            )
            tts_button(
                f"Patient risk is {prob*100:.0f} percent, rated {level}. "
                f"{'Intervention is recommended' if flag else 'Below the cost threshold'}. "
                f"Expected net benefit is {net_benefit:,.0f} dollars.",
                AVATARS["teemo"]["color"]
            )
            render_disclaimer()

            st.markdown(f"""
            <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:14px; padding:1rem 1.2rem; margin-top:1rem;">
                <span style="font-size:0.8rem; color:#94A3B8;">
                    <strong>Model:</strong> LightGBM (calibrated, isotonic) &bull; 38 features &bull;
                    ROC-AUC: 0.667 &bull; PR-AUC: 0.223 (1.96x baseline) &bull;
                    Cost threshold: {OPTIMAL_THRESHOLD*100:.1f}%
                </span>
            </div>
            """, unsafe_allow_html=True)


# ════════════════════════════════════════
#  COORDINATOR VIEW
# ════════════════════════════════════════
if tab_coordinator is not None:
    with tab_coordinator:
        chat_message("teemo",
            "Coordinator view: rank today's discharges by readmission risk. "
            "Prioritize follow-up calls for the highest-risk patients."
        )

        n_patients = st.slider("Number of discharges to rank", 10, 100, 30, key="coord_n")

        if st.button("Load & Rank Discharges", type="primary", use_container_width=True, key="coord_btn"):
            try:
                X_test = pd.read_parquet(DATA_DIR / "readmission" / "X_test.parquet")
                sample = X_test.sample(n_patients, random_state=42)
                probs = predict_full(sample.copy())

                results = pd.DataFrame({
                    "Patient #": range(1, n_patients + 1),
                    "Risk (%)": (probs * 100).round(1),
                    "Level": ["HIGH" if p >= 0.25 else "MEDIUM" if p >= OPTIMAL_THRESHOLD else "LOW" for p in probs],
                    "Flag": ["INTERVENE" if p >= OPTIMAL_THRESHOLD else "-" for p in probs],
                    "Net Benefit ($)": [round(p * P_PREVENTION * COST_READMIT - COST_INTERVENTION) for p in probs],
                    "Age": sample["age_ordinal"].map(AGE_RANGES).values if "age_ordinal" in sample.columns else "N/A",
                    "Meds": sample["num_medications"].values.astype(int) if "num_medications" in sample.columns else 0,
                }).sort_values("Risk (%)", ascending=False).reset_index(drop=True)

                flagged = (results["Flag"] == "INTERVENE").sum()
                high = (results["Level"] == "HIGH").sum()
                total_savings = results.loc[results["Net Benefit ($)"] > 0, "Net Benefit ($)"].sum()

                c1, c2, c3, c4 = st.columns(4)
                with c1:
                    st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#0D9488;">{n_patients}</div><div class="metric-label">Discharged Today</div></div>', unsafe_allow_html=True)
                with c2:
                    st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#EF4444;">{flagged}</div><div class="metric-label">Flagged for Intervention</div></div>', unsafe_allow_html=True)
                with c3:
                    st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#F59E0B;">{high}</div><div class="metric-label">High Risk</div></div>', unsafe_allow_html=True)
                with c4:
                    st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#10B981;">${total_savings:,.0f}</div><div class="metric-label">Potential Savings</div></div>', unsafe_allow_html=True)

                st.dataframe(results, use_container_width=True, height=400)

                thresholds = np.arange(0.05, 0.50, 0.01)
                capture_rates = [(probs >= t).mean() * 100 for t in thresholds]

                fig = go.Figure()
                fig.add_trace(go.Scatter(x=thresholds * 100, y=capture_rates, mode="lines",
                    line=dict(color=AVATARS["teemo"]["color"], width=2), fill="tozeroy",
                    fillcolor="rgba(13,148,136,0.1)"))
                fig.add_vline(x=OPTIMAL_THRESHOLD * 100, line_dash="dash", line_color="#EF4444",
                    annotation_text=f"Cost-optimal ({OPTIMAL_THRESHOLD*100:.1f}%)")
                fig.update_layout(
                    paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
                    font=dict(color="#0F172A"), height=300,
                    xaxis=dict(title="Threshold (%)", gridcolor="#E2E8F0"),
                    yaxis=dict(title="Capture Rate (%)", gridcolor="#E2E8F0"),
                    margin=dict(l=40, r=20, t=20, b=40),
                )
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

                chat_message("teemo",
                    f"Ranked <strong>{n_patients}</strong> discharges. "
                    f"<strong>{flagged}</strong> flagged for intervention. "
                    f"Potential savings: <strong>${total_savings:,.0f}</strong>."
                )
            except Exception as e:
                st.error(f"Error loading test data: {e}")


# ════════════════════════════════════════
#  MANAGER VIEW
# ════════════════════════════════════════
if tab_manager is not None:
    with tab_manager:
        chat_message("teemo",
            "Manager dashboard: monthly KPIs, estimated cost savings, "
            "<strong>fairness audit</strong> (race, gender, age, payer), and drift monitoring."
        )

        st.markdown('<div class="section-title"><span>Monthly Performance KPIs</span></div>', unsafe_allow_html=True)

        try:
            X_test = pd.read_parquet(DATA_DIR / "readmission" / "X_test.parquet")
            y_test = pd.read_parquet(DATA_DIR / "readmission" / "y_test.parquet").values.ravel()
            probs = predict_full(X_test.copy())

            from sklearn.metrics import roc_auc_score, average_precision_score, recall_score, precision_score
            roc = roc_auc_score(y_test, probs)
            pr_auc = average_precision_score(y_test, probs)
            preds_opt = (probs >= OPTIMAL_THRESHOLD).astype(int)
            recall = recall_score(y_test, preds_opt)
            precision = precision_score(y_test, preds_opt)
            flagged_pct = preds_opt.mean() * 100

            total_flagged = preds_opt.sum()
            estimated_prevented = int(total_flagged * P_PREVENTION * y_test[preds_opt == 1].mean())
            monthly_savings = estimated_prevented * COST_READMIT - total_flagged * COST_INTERVENTION

            c1, c2, c3, c4 = st.columns(4)
            with c1:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#0D9488;">{roc:.3f}</div><div class="metric-label">ROC-AUC</div></div>', unsafe_allow_html=True)
            with c2:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#7C3AED;">{pr_auc:.3f}</div><div class="metric-label">PR-AUC ({pr_auc/y_test.mean():.1f}x base)</div></div>', unsafe_allow_html=True)
            with c3:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#D97706;">{recall*100:.0f}%</div><div class="metric-label">Recall @ {OPTIMAL_THRESHOLD*100:.1f}%</div></div>', unsafe_allow_html=True)
            with c4:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#10B981;">${monthly_savings:,.0f}</div><div class="metric-label">Est. Monthly Savings</div></div>', unsafe_allow_html=True)

            c5, c6, c7, c8 = st.columns(4)
            with c5:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#2563EB;">{precision*100:.0f}%</div><div class="metric-label">Precision @ threshold</div></div>', unsafe_allow_html=True)
            with c6:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#DC2626;">{flagged_pct:.0f}%</div><div class="metric-label">Flagged for Follow-up</div></div>', unsafe_allow_html=True)
            with c7:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#059669;">{estimated_prevented}</div><div class="metric-label">Est. Prevented Readmits</div></div>', unsafe_allow_html=True)
            with c8:
                st.markdown(f'<div class="metric-card"><div class="metric-value" style="color:#0F172A;">{len(y_test):,}</div><div class="metric-label">Patients Evaluated</div></div>', unsafe_allow_html=True)

            # Fairness Audit
            st.markdown('<div class="section-title"><span>Fairness Audit</span></div>', unsafe_allow_html=True)

            def fairness_panel(group_col, group_name, df, y_true, pred_probs):
                if group_col not in df.columns:
                    return
                groups_u = df[group_col].unique()
                rows = []
                for g in sorted(groups_u, key=str):
                    mask = df[group_col] == g
                    if mask.sum() < 30:
                        continue
                    g_y = y_true[mask]
                    g_p = pred_probs[mask]
                    g_pred = (g_p >= OPTIMAL_THRESHOLD).astype(int)
                    rec = recall_score(g_y, g_pred, zero_division=0)
                    rows.append({
                        "Group": str(g), "N": int(mask.sum()),
                        "Base Rate": f"{g_y.mean()*100:.1f}%",
                        "Recall": f"{rec*100:.0f}%",
                        "Avg Pred": f"{g_p.mean()*100:.1f}%",
                        "Cal. Gap": f"{(g_p.mean() - g_y.mean())*100:+.1f}pp",
                    })
                if rows:
                    recalls = [float(r["Recall"].replace("%", "")) for r in rows]
                    gap = max(recalls) - min(recalls)
                    gap_color = "#10B981" if gap < 10 else ("#F59E0B" if gap < 20 else "#EF4444")
                    st.markdown(f"""
                    <div style="display:flex; align-items:center; gap:0.75rem; margin:0.75rem 0 0.3rem;">
                        <strong style="color:var(--text-primary);">{group_name}</strong>
                        <span style="background:{gap_color}15; color:{gap_color}; padding:0.2rem 0.6rem;
                                     border-radius:100px; font-size:0.75rem; font-weight:600;">
                            Recall Gap: {gap:.0f}pp
                        </span>
                    </div>
                    """, unsafe_allow_html=True)
                    st.dataframe(pd.DataFrame(rows), use_container_width=True, hide_index=True)

            fairness_panel("race", "Race", X_test, y_test, probs)
            fairness_panel("gender", "Gender", X_test, y_test, probs)

            if "age_ordinal" in X_test.columns:
                X_tmp = X_test.copy()
                X_tmp["age_group"] = X_tmp["age_ordinal"].map(AGE_RANGES)
                fairness_panel("age_group", "Age Group", X_tmp, y_test, probs)

            fairness_panel("payer_code", "Payer", X_test, y_test, probs)

            # Drift
            st.markdown('<div class="section-title"><span>Drift Monitor</span></div>', unsafe_allow_html=True)
            mean_pred = probs.mean()
            base_rate = y_test.mean()
            psi = abs(mean_pred - base_rate) / base_rate
            drift_status = "STABLE" if psi < 0.1 else ("WARNING" if psi < 0.2 else "DRIFT DETECTED")
            drift_color = "#10B981" if psi < 0.1 else ("#F59E0B" if psi < 0.2 else "#EF4444")

            st.markdown(f"""
            <div class="glass-card" style="border-left:4px solid {drift_color};">
                <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap;">
                    <div>
                        <div style="font-size:0.75rem; color:var(--text-secondary); text-transform:uppercase;">Model Drift Status</div>
                        <div style="font-size:1.3rem; font-weight:800; color:{drift_color};">{drift_status}</div>
                    </div>
                    <div style="text-align:right; font-size:0.8rem; color:var(--text-secondary);">
                        Mean prediction: {mean_pred*100:.1f}% &bull;
                        Actual base rate: {base_rate*100:.1f}% &bull;
                        Relative shift: {psi*100:.1f}%
                    </div>
                </div>
            </div>
            """, unsafe_allow_html=True)

            chat_message("teemo",
                f"KPIs: ROC-AUC <strong>{roc:.3f}</strong>, PR-AUC <strong>{pr_auc:.3f}</strong>. "
                f"Est. <strong>{estimated_prevented}</strong> readmissions prevented, "
                f"saving <strong>${monthly_savings:,.0f}</strong>. Drift: {drift_status}."
            )
        except Exception as e:
            st.error(f"Error computing metrics: {e}")

        st.markdown("""
        <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:14px; padding:1rem 1.2rem; margin-top:1rem;">
            <span style="font-size:0.8rem; color:#94A3B8;">
                <strong>Model:</strong> LightGBM (calibrated) &bull; 38 features &bull;
                ROC-AUC: 0.667 &bull; PR-AUC: 0.223 &bull;
                Cost: $15K readmit / $300 intervention / 25% prevention
            </span>
        </div>
        """, unsafe_allow_html=True)
        render_disclaimer()


# ════════════════════════════════════════
#  PATIENT VIEW
# ════════════════════════════════════════
if tab_patient is not None:
    with tab_patient:
        chat_message("teemo",
            "Hi! I'm <strong>Teemo</strong>, your friendly health companion. "
            "Answer a few simple questions so I can check your risk of returning to the hospital within 30 days."
        )

        with st.form("patient_form"):
            c1, c2 = st.columns(2)
            with c1:
                st.markdown("##### About You")
                age = st.selectbox("Age range", list(AGE_RANGES.keys()), format_func=lambda x: AGE_RANGES[x], index=6, key="pat_age")
                gender = st.selectbox("Gender", ["Female", "Male"], key="pat_gen")
                race = st.selectbox("Race", ["Caucasian", "AfricanAmerican", "Hispanic", "Asian", "Other", "Unknown"], key="pat_race")
                time_h = st.slider("Days in hospital", 1, 14, 5, key="pat_time")
                num_proc = st.slider("Procedures done", 0, 6, 1, key="pat_proc")
                num_lab = st.slider("Lab tests", 1, 100, 40, key="pat_lab")
            with c2:
                st.markdown("##### Your Medications")
                num_meds = st.slider("Current medications", 1, 50, 12, key="pat_meds")
                num_diag = st.slider("Number of conditions", 1, 16, 6, key="pat_diag")
                total_visits = st.slider("Prior visits (past year)", 0, 30, 3, key="pat_vis")
                num_chg = st.slider("Medication changes this stay", 0, 15, 2, key="pat_chg")
                insulin = st.selectbox("On insulin?", ["No", "Yes"], key="pat_ins")
                metformin = st.selectbox("On metformin?", ["No", "Yes"], key="pat_met")

            c3, c4 = st.columns(2)
            with c3:
                diag1 = st.selectbox("Main reason for visit", list(DIAG_PLAIN.keys()), format_func=lambda x: DIAG_PLAIN[x], key="pat_d1")
                diag2 = st.selectbox("Second condition", list(DIAG_PLAIN.keys()), format_func=lambda x: DIAG_PLAIN[x], index=9, key="pat_d2")
                diag3 = st.selectbox("Third condition", list(DIAG_PLAIN.keys()), format_func=lambda x: DIAG_PLAIN[x], index=9, key="pat_d3")
            with c4:
                a1c = st.selectbox("HbA1c test", ["Not_Tested", "Norm", ">7", ">8"],
                    format_func=lambda x: {"Not_Tested": "Not tested", "Norm": "Normal", ">7": "Above 7%", ">8": "Above 8%"}[x], key="pat_a1c")
                glu = st.selectbox("Glucose test", ["Not_Tested", "Norm", ">200", ">300"],
                    format_func=lambda x: {"Not_Tested": "Not tested", "Norm": "Normal", ">200": "Above 200", ">300": "Above 300"}[x], key="pat_glu")
                dmmed = st.selectbox("On diabetes medication?", ["Yes", "No"], key="pat_dm")

            submitted = st.form_submit_button("Check My Risk", type="primary", use_container_width=True)

        if submitted:
            row = pd.DataFrame([{
                "age_ordinal": age, "gender": gender, "race": race,
                "time_in_hospital": time_h, "num_medications": num_meds,
                "number_diagnoses": num_diag, "total_prior_visits": total_visits,
                "num_lab_procedures": num_lab, "num_procedures": num_proc,
                "diag_1_group": diag1, "diag_2_group": diag2, "diag_3_group": diag3,
                "A1Cresult": a1c, "max_glu_serum": glu,
                "insulin_prescrite": 1 if insulin == "Yes" else 0,
                "metformin_prescrite": 1 if metformin == "Yes" else 0,
                "diabetesMed": dmmed, "num_med_changes": num_chg,
            }])
            prob = patient_model.predict_proba(row[patient_features])[0][1]
            level, advice = render_risk_result(prob, "teemo")

            reasons = generate_reasons(row.iloc[0], patient_features)
            actions = generate_actions(reasons, level)
            render_advice_cards(reasons, actions)

            chat_message("teemo", f"Your risk score is <strong>{prob*100:.0f}%</strong> ({level}). {advice}")
            tts_button(f"Your risk score is {prob*100:.0f} percent, rated {level}. {advice}", AVATARS["teemo"]["color"])

            st.markdown("""
            <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:14px; padding:1rem 1.2rem; margin-top:1rem;">
                <span style="font-size:0.8rem; color:#94A3B8;">
                    <strong>Model:</strong> LightGBM (patient-friendly) &bull; 18 features &bull;
                    ROC-AUC: 0.628 &bull; PR-AUC: 0.183 &bull; Retains ~82% of full model accuracy
                </span>
            </div>
            """, unsafe_allow_html=True)
            render_disclaimer()
