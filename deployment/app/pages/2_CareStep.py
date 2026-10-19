import streamlit as st
import sys
import pandas as pd
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from utils import (
    inject_global_css, render_avatar_header, render_risk_result,
    render_disclaimer, render_sidebar, check_portal,
    load_model, tts_button, chat_message,
    generate_reasons, AVATARS, AGE_RANGES, DIAG_PLAIN
)

st.set_page_config(page_title="CareStep — Recovery Companion", page_icon="🏃", layout="wide")
inject_global_css()
render_sidebar()
check_portal(["patient", "medical", "both"])
render_avatar_header("carestep")

model, features = load_model("carestep")

chat_message("carestep",
    "Welcome! I'm <strong>CareStep</strong>, your personal 30-day recovery coach. "
    "I'll assess your risk and create a tailored recovery plan with daily check-ins."
)

tabs = st.tabs(["Risk Assessment", "30-Day Action Plan", "Daily Check-In", "Care Team Summary"])

with tabs[0]:
    with st.form("carestep_form"):
        c1, c2 = st.columns(2)
        with c1:
            st.markdown("##### About You")
            age = st.selectbox("Age range", list(AGE_RANGES.keys()),
                               format_func=lambda x: AGE_RANGES[x], index=6)
            gender = st.selectbox("Gender", ["Female", "Male"])
            race = st.selectbox("Race/Ethnicity",
                ["Caucasian", "AfricanAmerican", "Hispanic", "Asian", "Other", "Unknown"])
            time_hosp = st.slider("Days in hospital", 1, 14, 5)
            num_proc = st.slider("Procedures performed", 0, 6, 1)
            num_lab = st.slider("Lab tests done", 1, 100, 40)
        with c2:
            st.markdown("##### Medications & Health")
            num_meds = st.slider("Current medications", 1, 50, 12)
            num_diag = st.slider("Number of diagnoses", 1, 16, 6)
            total_visits = st.slider("Prior visits (past year)", 0, 30, 3)
            num_changes = st.slider("Medication changes this stay", 0, 15, 2)
            insulin = st.selectbox("On insulin?", ["No", "Yes"])
            metformin = st.selectbox("On metformin?", ["No", "Yes"])

        c3, c4 = st.columns(2)
        with c3:
            diag1 = st.selectbox("Primary diagnosis", list(DIAG_PLAIN.keys()),
                                 format_func=lambda x: DIAG_PLAIN[x])
            diag2 = st.selectbox("Secondary diagnosis", list(DIAG_PLAIN.keys()),
                                 format_func=lambda x: DIAG_PLAIN[x], index=9)
            diag3 = st.selectbox("Tertiary diagnosis", list(DIAG_PLAIN.keys()),
                                 format_func=lambda x: DIAG_PLAIN[x], index=9)
        with c4:
            a1c = st.selectbox("HbA1c result", ["Not_Tested", "Norm", ">7", ">8"],
                format_func=lambda x: {"Not_Tested":"Not tested","Norm":"Normal",">7":"Above 7%",">8":"Above 8%"}[x])
            glu = st.selectbox("Glucose result", ["Not_Tested", "Norm", ">200", ">300"],
                format_func=lambda x: {"Not_Tested":"Not tested","Norm":"Normal",">200":"Above 200",">300":"Above 300"}[x])
            dmmed = st.selectbox("On diabetes medication?", ["Yes", "No"])

        submitted = st.form_submit_button("Generate My Recovery Plan", type="primary", use_container_width=True)

    if submitted:
        row = pd.DataFrame([{
            "age_ordinal": age, "gender": gender, "race": race,
            "time_in_hospital": time_hosp, "num_medications": num_meds,
            "number_diagnoses": num_diag, "total_prior_visits": total_visits,
            "num_lab_procedures": num_lab, "num_procedures": num_proc,
            "diag_1_group": diag1, "diag_2_group": diag2, "diag_3_group": diag3,
            "A1Cresult": a1c, "max_glu_serum": glu,
            "insulin_prescrite": 1 if insulin == "Yes" else 0,
            "metformin_prescrite": 1 if metformin == "Yes" else 0,
            "diabetesMed": dmmed, "num_med_changes": num_changes,
        }])
        prob = model.predict_proba(row[features])[0][1]

        st.session_state["cs_prob"] = prob
        st.session_state["cs_row"] = row.iloc[0]
        st.session_state["cs_level"] = "HIGH" if prob >= 0.25 else ("MEDIUM" if prob >= 0.14 else "LOW")

        level, advice = render_risk_result(prob, "carestep")
        reasons = generate_reasons(row.iloc[0], features)

        st.markdown('<div class="section-title"><span>Your Risk Factors</span></div>', unsafe_allow_html=True)
        for r in reasons:
            st.markdown(f'<div class="advice-card warning"><span>&#9888;&#65039;</span><span>{r}</span></div>', unsafe_allow_html=True)

        chat_message("carestep",
            f"Your risk score is <strong>{prob*100:.0f}%</strong> ({level}). "
            "Check the <strong>30-Day Action Plan</strong> tab for your personalized recovery roadmap!")
        tts_button(f"Your risk score is {prob*100:.0f} percent, rated {level}. Check the Action Plan tab for your recovery roadmap.", AVATARS["carestep"]["color"])
        render_disclaimer()

with tabs[1]:
    if "cs_prob" not in st.session_state:
        st.info("Complete the Risk Assessment first to generate your plan.")
    else:
        prob = st.session_state["cs_prob"]
        level = st.session_state["cs_level"]
        row = st.session_state["cs_row"]

        chat_message("carestep", f"Here's your personalized 30-day plan based on your <strong>{level}</strong> risk level ({prob*100:.0f}%).")

        plans = {
            "Week 1 — Intensive Phase (Days 1-7)": [
                "Take all medications exactly as prescribed",
                "Book a follow-up appointment (before day 7)" if level != "LOW" else "Keep your next scheduled appointment",
                "Measure blood sugar every morning" if row.get("insulin_prescrite", 0) == 1 else "Check blood sugar at least 3 times this week",
                "Use a pill organizer for all medications" if row.get("num_medications", 0) >= 8 else "Set daily medication reminders",
                "Ask your doctor about an HbA1c test" if row.get("A1Cresult","") == "Not_Tested" else "Keep your HbA1c follow-up",
            ],
            "Week 2-3 — Stabilization (Days 8-21)": [
                "Continue daily medication checks",
                "Attend your follow-up visit",
                "Report any new symptoms to your care team",
                "Start light physical activity as approved",
                "Review your diet plan with your care team",
            ],
            "Week 4 — Autonomy (Days 22-30)": [
                "Maintain your medication routine",
                "Prepare questions for your next doctor visit",
                "Review your progress and celebrate wins",
                "Schedule your next follow-up",
            ],
        }

        for phase, items in plans.items():
            st.markdown(f'<div class="section-title"><span>{phase}</span></div>', unsafe_allow_html=True)
            for item in items:
                st.markdown(f'<div class="advice-card success"><span>&#x1F4CC;</span><span>{item}</span></div>', unsafe_allow_html=True)

        tts_button("Week one is intensive: take your medications, book a follow-up, and monitor daily. Weeks two and three focus on stabilization. Week four is about building autonomy.", AVATARS["carestep"]["color"])

with tabs[2]:
    if "cs_prob" not in st.session_state:
        st.info("Complete the Risk Assessment first.")
    else:
        level = st.session_state["cs_level"]
        day = st.slider("Simulation day (1-30)", 1, 30, 1)

        chat_message("carestep", f"Day {day} check-in! Let me know how you're doing today.")

        with st.form(f"checkin_{day}"):
            q1 = st.selectbox("Did you take all medications today?", ["Yes", "Partially", "No"])
            q2 = st.selectbox("Did you check your blood sugar?", ["Yes", "No"])
            q3 = st.slider("Blood sugar reading (mg/dL)", 60, 400, 150)
            q4 = st.selectbox("Any new symptoms?", ["None", "Mild", "Concerning"])
            q5 = st.selectbox("Follow-up appointment booked?", ["Yes", "Not yet", "Already attended"])
            check_submitted = st.form_submit_button("Submit Check-In", type="primary", use_container_width=True)

        if check_submitted:
            score = 0
            alerts = []
            if q1 == "Yes": score += 30
            elif q1 == "Partially": score += 15
            else: alerts.append("Missed medications — contact your pharmacist")
            if q2 == "Yes": score += 20
            else: alerts.append("Please check your blood sugar daily")
            if 80 <= q3 <= 180: score += 25
            elif q3 > 300: alerts.append(f"Blood sugar {q3} is very high — contact your doctor")
            elif q3 > 200: score += 10; alerts.append(f"Blood sugar {q3} is elevated — monitor closely")
            elif q3 < 70: alerts.append(f"Blood sugar {q3} is dangerously low — seek immediate help")
            else: score += 15
            if q4 == "None": score += 15
            elif q4 == "Concerning": alerts.append("New concerning symptoms — call your care team today")
            else: score += 5
            if q5 in ("Yes", "Already attended"): score += 10
            elif day >= 5: alerts.append("Follow-up not booked yet — please schedule one")
            score = min(score, 100)

            score_color = "#10B981" if score >= 80 else ("#F59E0B" if score >= 50 else "#EF4444")

            c1, c2 = st.columns(2)
            with c1:
                st.markdown(f"""
                <div class="metric-card">
                    <div class="metric-value" style="color: {score_color};">{score}%</div>
                    <div class="metric-label">Daily Adherence Score</div>
                    <div class="risk-gauge" style="margin-top: 0.5rem;">
                        <div class="risk-fill" style="width:{score}%; background:{score_color};"></div>
                    </div>
                </div>
                """, unsafe_allow_html=True)
            with c2:
                if alerts:
                    for alert in alerts:
                        st.markdown(f'<div class="advice-card warning"><span>&#9888;&#65039;</span><span>{alert}</span></div>', unsafe_allow_html=True)
                else:
                    st.markdown('<div class="advice-card success"><span>&#x2705;</span><span>Great job! All checks passed today.</span></div>', unsafe_allow_html=True)

            msg = f"Your adherence score is {score}%." + (f" Alert: {alerts[0]}" if alerts else " Keep it up!")
            chat_message("carestep", msg)
            tts_button(f"Day {day} check-in complete. {msg}", AVATARS["carestep"]["color"])

with tabs[3]:
    if "cs_prob" not in st.session_state:
        st.info("Complete the Risk Assessment first.")
    else:
        prob = st.session_state["cs_prob"]
        level = st.session_state["cs_level"]
        reasons = generate_reasons(st.session_state["cs_row"], features)

        chat_message("carestep", "Here's a summary for your care team.")

        st.markdown(f"""
        <div class="result-container" style="border-left: 4px solid {AVATARS['carestep']['color']};">
            <h4 style="color: {AVATARS['carestep']['color']}; margin: 0 0 0.5rem;">Patient Summary</h4>
            <table style="width:100%; font-size:0.9rem;">
                <tr><td style="color:var(--text-secondary); padding:0.3rem 0;">Discharge Risk</td>
                    <td style="color:var(--text-primary);"><strong>{prob*100:.0f}%</strong> ({level})</td></tr>
                <tr><td style="color:var(--text-secondary); padding:0.3rem 0;">Key Risk Factors</td>
                    <td style="color:var(--text-primary);">{', '.join(reasons[:3]) if reasons else 'None identified'}</td></tr>
                <tr><td style="color:var(--text-secondary); padding:0.3rem 0;">Recommended Action</td>
                    <td style="color:var(--text-primary);">{'Urgent follow-up within 48h' if level == 'HIGH' else 'Follow-up within 7 days' if level == 'MEDIUM' else 'Standard follow-up'}</td></tr>
            </table>
        </div>
        """, unsafe_allow_html=True)

        st.markdown('<div class="section-title"><span>Suggested Questions for Doctor</span></div>', unsafe_allow_html=True)
        questions = [
            "Should medication doses be adjusted based on recent blood sugar readings?",
            "Can the medication schedule be simplified to improve adherence?",
            "Should an HbA1c test be scheduled?" if st.session_state["cs_row"].get("A1Cresult") == "Not_Tested" else "When should the next HbA1c test be?",
            "What warning signs should the patient watch for at home?",
        ]
        for q in questions:
            st.markdown(f'<div class="advice-card success"><span>&#10067;</span><span>{q}</span></div>', unsafe_allow_html=True)

        tts_button(f"Care team summary: {level} risk at {prob*100:.0f} percent. Key factors: {', '.join(reasons[:2]) if reasons else 'none major'}.", AVATARS["carestep"]["color"])
