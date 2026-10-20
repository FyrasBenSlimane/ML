import streamlit as st
import sys
import numpy as np
import pandas as pd
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from utils import (
    inject_global_css, render_avatar_header, render_risk_result,
    render_disclaimer, render_sidebar, check_portal,
    load_model, tts_button, chat_message,
    generate_reasons, generate_actions, AVATARS, AGE_RANGES, DIAG_PLAIN
)

st.set_page_config(page_title="CareStep — Recovery Companion", page_icon="🏃", layout="wide")
inject_global_css()
render_sidebar()
check_portal(["patient", "medical", "both"])
render_avatar_header("carestep")

model, features = load_model("carestep")

DIAG_GROUPS = {
    "circulatory": "Heart or blood vessel problem",
    "respiratory": "Breathing or lung problem",
    "digestive": "Stomach or digestive problem",
    "diabetes": "Diabetes complication",
    "injury": "Injury or accident",
    "infection_renal": "Kidney, urinary or infection",
    "other": "Other medical condition",
}

INSULIN_OPTIONS = {
    "No": "Not on insulin",
    "Steady": "Insulin — no change",
    "Up": "Insulin — dose increased",
    "Down": "Insulin — dose decreased",
}

DISCHARGE_OPTIONS = {
    "home": "Going home alone",
    "home_with_help": "Going home with help",
    "facility": "Going to a facility (rehab, nursing)",
}

chat_message("carestep",
    "Welcome! I'm <strong>CareStep</strong>, your personal 30-day recovery coach. "
    "Answer a few simple questions and I'll create a tailored recovery plan with daily check-ins."
)

tabs = st.tabs(["🩺 Risk Assessment", "📋 30-Day Action Plan", "✅ Daily Check-In", "👨‍⚕️ Care Team Summary"])

# ── Tab 1: Risk Assessment ──────────────────────────────────────────────────

with tabs[0]:
    st.markdown("""
    <div class="glass-card fade-in" style="margin-bottom:1.5rem; padding:1.2rem 1.5rem;">
        <div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:0.3rem;">
            <span style="font-size:1.3rem;">📝</span>
            <span style="font-weight:700; color:var(--text-primary); font-size:1rem;">Tell us about your situation</span>
        </div>
        <p style="color:var(--text-secondary); font-size:0.85rem; margin:0;">
            All questions use simple, patient-friendly language. Only 12 pieces of information — no lab codes needed.
        </p>
    </div>
    """, unsafe_allow_html=True)

    with st.form("carestep_form"):
        st.markdown("##### 👤 About You")
        c1, c2 = st.columns(2)
        with c1:
            age = st.selectbox("Your age range", list(AGE_RANGES.keys()),
                               format_func=lambda x: AGE_RANGES[x], index=6)
            gender = st.selectbox("Gender", ["Female", "Male"])
        with c2:
            time_hosp = st.slider("Days spent in hospital this stay", 1, 14, 5)
            discharge = st.selectbox("Where are you going after discharge?",
                list(DISCHARGE_OPTIONS.keys()),
                format_func=lambda x: DISCHARGE_OPTIONS[x])

        st.markdown("##### 💊 Medications & Treatment")
        c3, c4 = st.columns(2)
        with c3:
            num_meds = st.slider("Total medications you take", 1, 50, 12)
            insulin = st.selectbox("Insulin status",
                list(INSULIN_OPTIONS.keys()),
                format_func=lambda x: INSULIN_OPTIONS[x])
        with c4:
            med_change = st.selectbox("Were medications changed this stay?",
                ["Yes", "No"], format_func=lambda x: "Yes — medications were changed" if x == "Yes" else "No changes")
            a1c_tested = st.selectbox("Was HbA1c tested this stay?",
                ["No", "Yes"], format_func=lambda x: "Yes — HbA1c was tested" if x == "Yes" else "No — not tested")

        st.markdown("##### 🏥 Medical History")
        c5, c6 = st.columns(2)
        with c5:
            diag_group = st.selectbox("Main reason for this hospital visit",
                list(DIAG_GROUPS.keys()),
                format_func=lambda x: DIAG_GROUPS[x])
            inpatient = st.slider("Hospital stays in the past year", 0, 10, 0,
                help="How many times you were admitted as an inpatient")
        with c6:
            emergency = st.slider("ER visits in the past year", 0, 10, 0,
                help="How many times you went to the emergency room")
            outpatient_raw = st.slider("Outpatient visits in the past year", 0, 20, 2,
                help="Clinic or doctor visits (not ER or hospital stays)")

        submitted = st.form_submit_button("🔍  Assess My Risk", type="primary", use_container_width=True)

    if submitted:
        inpatient_cap = min(inpatient, 3)
        emergency_cap = min(emergency, 3)
        if outpatient_raw == 0:
            outpatient_bkt = 0
        elif outpatient_raw <= 2:
            outpatient_bkt = 1
        elif outpatient_raw <= 5:
            outpatient_bkt = 2
        else:
            outpatient_bkt = 3

        gender_bin = 1 if gender == "Male" else 0
        a1c_val = 1 if a1c_tested == "Yes" else 0
        change_val = "No" if med_change == "Yes" else "Ch"

        row_dict = {f: 0 for f in features}
        row_dict["age_ord"] = age
        row_dict["gender_bin"] = gender_bin
        row_dict["inpatient_cap"] = inpatient_cap
        row_dict["emergency_cap"] = emergency_cap
        row_dict["outpatient_bkt"] = outpatient_bkt
        row_dict["time_in_hospital"] = time_hosp
        row_dict["num_medications"] = num_meds
        row_dict["a1c_tested"] = a1c_val

        diag_col = f"diag_group_{diag_group}"
        if diag_col in row_dict:
            row_dict[diag_col] = 1

        insulin_col = f"insulin_{insulin}"
        if insulin_col in row_dict:
            row_dict[insulin_col] = 1

        if change_val == "No":
            row_dict["change_No"] = 1

        discharge_col = f"discharge_group_{discharge}"
        if discharge_col in row_dict:
            row_dict[discharge_col] = 1

        row_df = pd.DataFrame([row_dict])[features]
        prob = model.predict_proba(row_df)[0][1]

        human_row = pd.Series({
            "total_prior_visits": inpatient + emergency + outpatient_raw,
            "num_medications": num_meds,
            "insulin_prescrite": 0 if insulin == "No" else 1,
            "time_in_hospital": time_hosp,
            "A1Cresult": "Not_Tested" if a1c_tested == "No" else "Tested",
            "number_diagnoses": 3,
            "age_ordinal": age,
            "num_med_changes": 1 if med_change == "Yes" else 0,
        })

        st.session_state["cs_prob"] = prob
        st.session_state["cs_row"] = human_row
        st.session_state["cs_level"] = "HIGH" if prob >= 0.25 else ("MEDIUM" if prob >= 0.14 else "LOW")
        st.session_state["cs_inputs"] = {
            "age": age, "gender": gender, "time_hosp": time_hosp,
            "discharge": discharge, "num_meds": num_meds, "insulin": insulin,
            "med_change": med_change, "a1c_tested": a1c_tested,
            "diag_group": diag_group, "inpatient": inpatient,
            "emergency": emergency, "outpatient_raw": outpatient_raw,
        }

        level, advice = render_risk_result(prob, "carestep")
        reasons = generate_reasons(human_row, features)
        actions = generate_actions(reasons, level)

        st.markdown('<div class="section-title"><span>Why This Risk Level</span></div>', unsafe_allow_html=True)
        for r in reasons:
            st.markdown(f'<div class="advice-card warning"><span>⚠️</span><span>{r}</span></div>', unsafe_allow_html=True)

        st.markdown('<div class="section-title"><span>What You Can Do</span></div>', unsafe_allow_html=True)
        for a in actions:
            st.markdown(f'<div class="advice-card success"><span>✅</span><span>{a}</span></div>', unsafe_allow_html=True)

        chat_message("carestep",
            f"Your 30-day readmission risk is <strong>{prob*100:.0f}%</strong> ({level}). "
            f"{advice} "
            "Head to the <strong>30-Day Action Plan</strong> tab for your personalized roadmap!")
        tts_button(
            f"Your readmission risk is {prob*100:.0f} percent, rated {level}. {advice} "
            "Check the Action Plan tab for your personalized recovery roadmap.",
            AVATARS["carestep"]["color"])
        render_disclaimer()

# ── Tab 2: 30-Day Action Plan ───────────────────────────────────────────────

with tabs[1]:
    if "cs_prob" not in st.session_state:
        st.markdown("""
        <div class="glass-card" style="text-align:center; padding:3rem;">
            <div style="font-size:2.5rem; margin-bottom:0.8rem;">📋</div>
            <h3 style="color:var(--text-primary); margin:0 0 0.5rem;">No plan yet</h3>
            <p style="color:var(--text-secondary);">Complete the <strong>Risk Assessment</strong> tab first to generate your personalized 30-day plan.</p>
        </div>
        """, unsafe_allow_html=True)
    else:
        prob = st.session_state["cs_prob"]
        level = st.session_state["cs_level"]
        inputs = st.session_state.get("cs_inputs", {})

        on_insulin = inputs.get("insulin", "No") != "No"
        a1c_not_tested = inputs.get("a1c_tested", "No") == "No"
        many_meds = inputs.get("num_meds", 0) >= 8
        high_risk = level in ("HIGH", "MEDIUM")

        chat_message("carestep",
            f"Here's your personalized <strong>30-day recovery plan</strong> based on your "
            f"<strong>{level}</strong> risk level ({prob*100:.0f}%). Each week builds on the last.")

        week1 = [
            ("💊", "Take all medications exactly as prescribed — set a daily alarm"),
        ]
        if high_risk:
            week1.append(("📅", "Book a follow-up appointment within 7 days"))
        else:
            week1.append(("📅", "Keep your next scheduled follow-up appointment"))
        if on_insulin:
            week1.append(("🩸", "Measure blood sugar every morning and evening"))
        else:
            week1.append(("🩸", "Check blood sugar at least 3 times this week"))
        if many_meds:
            week1.append(("💼", f"Use a pill organizer for your {inputs.get('num_meds', 0)} medications"))
        else:
            week1.append(("⏰", "Set daily medication reminders on your phone"))
        if a1c_not_tested:
            week1.append(("🧪", "Ask your doctor about scheduling an HbA1c test"))

        week2 = [
            ("💊", "Continue daily medication routine"),
            ("🏥", "Attend your follow-up visit — bring your blood sugar log"),
            ("📞", "Report any new symptoms to your care team immediately"),
            ("🚶", "Start light physical activity as approved by your doctor"),
            ("🥗", "Review your diet plan — aim for consistent meal timing"),
        ]

        week4 = [
            ("🎯", "Maintain your medication and monitoring routine"),
            ("📝", "Write down questions for your next doctor visit"),
            ("📊", "Review your 30-day progress — celebrate your wins!"),
            ("📅", "Schedule your next monthly follow-up"),
        ]
        if level == "HIGH":
            week4.append(("🚨", "Keep emergency numbers accessible — call if blood sugar spikes"))

        phases = [
            ("Week 1 — Intensive Phase", "Days 1–7: Building your foundation", week1, "#059669"),
            ("Weeks 2–3 — Stabilization", "Days 8–21: Strengthening your routine", week2, "#0D9488"),
            ("Week 4 — Independence", "Days 22–30: Taking the lead", week4, "#2563EB"),
        ]

        for title, subtitle, items, color in phases:
            st.markdown(f"""
            <div class="glass-card fade-in" style="margin-bottom:1rem; border-left:4px solid {color};">
                <div style="font-weight:700; color:{color}; font-size:1.05rem; margin-bottom:0.2rem;">{title}</div>
                <div style="font-size:0.8rem; color:var(--text-secondary); margin-bottom:0.8rem;">{subtitle}</div>
            </div>
            """, unsafe_allow_html=True)
            for icon, item in items:
                st.markdown(f'<div class="advice-card success"><span style="font-size:1.1rem;">{icon}</span><span>{item}</span></div>', unsafe_allow_html=True)

        tts_button(
            "Week one is your intensive phase: take medications on time, book a follow-up, and monitor daily. "
            "Weeks two and three focus on stabilizing your routine and building good habits. "
            "Week four is about taking the lead on your own recovery.",
            AVATARS["carestep"]["color"])

# ── Tab 3: Daily Check-In ───────────────────────────────────────────────────

with tabs[2]:
    if "cs_prob" not in st.session_state:
        st.markdown("""
        <div class="glass-card" style="text-align:center; padding:3rem;">
            <div style="font-size:2.5rem; margin-bottom:0.8rem;">✅</div>
            <h3 style="color:var(--text-primary); margin:0 0 0.5rem;">Check-In Locked</h3>
            <p style="color:var(--text-secondary);">Complete the <strong>Risk Assessment</strong> first to unlock daily check-ins.</p>
        </div>
        """, unsafe_allow_html=True)
    else:
        level = st.session_state["cs_level"]

        st.markdown("""
        <div class="glass-card fade-in" style="margin-bottom:1rem;">
            <div style="display:flex; align-items:center; gap:0.6rem;">
                <span style="font-size:1.3rem;">📆</span>
                <span style="font-weight:700; color:var(--text-primary);">Pick your day and tell me how you're doing</span>
            </div>
        </div>
        """, unsafe_allow_html=True)

        day = st.slider("Recovery Day", 1, 30, 1,
            help="Slide to the day of your recovery to log your check-in")

        if day <= 7:
            phase_label, phase_color = "Intensive Phase", "#059669"
        elif day <= 21:
            phase_label, phase_color = "Stabilization", "#0D9488"
        else:
            phase_label, phase_color = "Independence", "#2563EB"

        st.markdown(f"""
        <div style="display:inline-block; padding:0.3rem 0.8rem; border-radius:100px;
                    background:{phase_color}15; color:{phase_color}; font-size:0.8rem;
                    font-weight:600; margin-bottom:1rem;">
            Day {day} — {phase_label}
        </div>
        """, unsafe_allow_html=True)

        chat_message("carestep", f"Day <strong>{day}</strong> check-in! Let's see how your recovery is going today. 💪")

        with st.form(f"checkin_{day}"):
            c1, c2 = st.columns(2)
            with c1:
                q1 = st.selectbox("💊 Did you take all medications today?",
                    ["Yes", "Partially", "No"])
                q2 = st.selectbox("🩸 Did you check your blood sugar?",
                    ["Yes", "No"])
                q3 = st.slider("Blood sugar reading (mg/dL)", 60, 400, 150,
                    help="Enter your most recent blood sugar reading")
            with c2:
                q4 = st.selectbox("🤒 Any new symptoms today?",
                    ["None", "Mild (manageable)", "Concerning (unusual)"])
                q5 = st.selectbox("📅 Follow-up appointment status",
                    ["Booked", "Not yet booked", "Already attended"])
                q6 = st.selectbox("🚶 Physical activity today?",
                    ["Yes — took a walk or exercised", "Light activity", "No activity"])

            check_submitted = st.form_submit_button("📊  Submit Check-In", type="primary", use_container_width=True)

        if check_submitted:
            score = 0
            alerts = []
            tips = []

            if q1 == "Yes":
                score += 25
                tips.append("Great medication adherence!")
            elif q1 == "Partially":
                score += 12
                alerts.append("Missed some medications — set a reminder and take them now if safe")
            else:
                alerts.append("⚠️ Missed medications — contact your pharmacist about catching up safely")

            if q2 == "Yes":
                score += 20
            else:
                alerts.append("Please check your blood sugar daily — it helps track your recovery")

            if 80 <= q3 <= 180:
                score += 20
                tips.append("Blood sugar in healthy range!")
            elif q3 > 300:
                alerts.append(f"Blood sugar {q3} mg/dL is critically high — contact your doctor NOW")
            elif q3 > 200:
                score += 8
                alerts.append(f"Blood sugar {q3} mg/dL is elevated — monitor closely and hydrate")
            elif q3 < 70:
                alerts.append(f"Blood sugar {q3} mg/dL is dangerously low — eat something sweet and seek help if dizzy")
            else:
                score += 14

            if q4 == "None":
                score += 15
            elif "Concerning" in q4:
                alerts.append("New concerning symptoms — call your care team today")
            else:
                score += 8
                tips.append("Mild symptoms noted — track them and mention at your next visit")

            if q5 == "Already attended":
                score += 10
                tips.append("Follow-up completed!")
            elif q5 == "Booked":
                score += 8
            elif day >= 5:
                alerts.append("Follow-up not booked yet — please schedule within this week")

            if "Yes" in q6:
                score += 10
            elif "Light" in q6:
                score += 5

            score = min(score, 100)

            if score >= 80:
                score_color, score_label = "#10B981", "Excellent"
            elif score >= 60:
                score_color, score_label = "#0D9488", "Good"
            elif score >= 40:
                score_color, score_label = "#F59E0B", "Needs Attention"
            else:
                score_color, score_label = "#EF4444", "Alert"

            st.markdown(f"""
            <div class="glass-card fade-in" style="text-align:center; margin:1rem 0; padding:1.5rem;">
                <div style="font-size:0.75rem; color:var(--text-secondary); text-transform:uppercase;
                            letter-spacing:2px; margin-bottom:0.5rem;">Day {day} Adherence Score</div>
                <div class="risk-circle" style="border-color:{score_color}; margin:0.5rem auto;">
                    <div class="risk-pct" style="color:{score_color};">{score}%</div>
                    <div class="risk-label-text" style="color:{score_color};">{score_label}</div>
                </div>
                <div class="risk-bar" style="max-width:300px; margin:1rem auto 0;">
                    <div class="risk-fill" style="width:{score}%; background:{score_color};"></div>
                </div>
            </div>
            """, unsafe_allow_html=True)

            if alerts:
                st.markdown('<div class="section-title"><span>⚠️ Alerts</span></div>', unsafe_allow_html=True)
                for alert in alerts:
                    st.markdown(f'<div class="advice-card warning"><span>🔔</span><span>{alert}</span></div>', unsafe_allow_html=True)

            if tips:
                st.markdown('<div class="section-title"><span>🌟 Wins Today</span></div>', unsafe_allow_html=True)
                for tip in tips:
                    st.markdown(f'<div class="advice-card success"><span>⭐</span><span>{tip}</span></div>', unsafe_allow_html=True)

            msg = f"Day {day} score: {score}% ({score_label})."
            if alerts:
                msg += f" Heads up: {alerts[0]}"
            elif tips:
                msg += f" {tips[0]}"
            chat_message("carestep", msg)
            tts_button(f"Day {day} check-in complete. {msg}", AVATARS["carestep"]["color"])

# ── Tab 4: Care Team Summary ────────────────────────────────────────────────

with tabs[3]:
    if "cs_prob" not in st.session_state:
        st.markdown("""
        <div class="glass-card" style="text-align:center; padding:3rem;">
            <div style="font-size:2.5rem; margin-bottom:0.8rem;">👨‍⚕️</div>
            <h3 style="color:var(--text-primary); margin:0 0 0.5rem;">Summary Not Ready</h3>
            <p style="color:var(--text-secondary);">Complete the <strong>Risk Assessment</strong> first to generate the care team summary.</p>
        </div>
        """, unsafe_allow_html=True)
    else:
        prob = st.session_state["cs_prob"]
        level = st.session_state["cs_level"]
        inputs = st.session_state.get("cs_inputs", {})
        human_row = st.session_state["cs_row"]
        reasons = generate_reasons(human_row, features)

        color = "#EF4444" if level == "HIGH" else ("#F59E0B" if level == "MEDIUM" else "#10B981")

        chat_message("carestep", "Here's a summary you can share with your care team or bring to your next appointment.")

        dot = '🔴' if level == 'HIGH' else '🟡' if level == 'MEDIUM' else '🟢'
        age_display = AGE_RANGES.get(inputs.get('age', 6), '60-70')
        gender_display = inputs.get('gender', 'N/A')
        stay_display = f"{inputs.get('time_hosp', 'N/A')} days"
        discharge_display = DISCHARGE_OPTIONS.get(inputs.get('discharge', ''), 'N/A')
        meds_display = str(inputs.get('num_meds', 'N/A'))
        insulin_display = INSULIN_OPTIONS.get(inputs.get('insulin', ''), 'N/A')
        diag_display = DIAG_GROUPS.get(inputs.get('diag_group', ''), 'N/A')
        a1c_display = inputs.get('a1c_tested', 'N/A')

        header_html = (
            f'<div class="glass-card fade-in" style="border-left:4px solid {color}; margin-bottom:1rem;">'
            f'<div style="display:flex;align-items:center;gap:0.8rem;margin-bottom:1rem;">'
            f'<div style="width:48px;height:48px;border-radius:50%;background:{color}15;display:flex;align-items:center;justify-content:center;">'
            f'<span style="font-size:1.3rem;color:{color};">{dot}</span></div>'
            f'<div><div style="font-weight:800;font-size:1.2rem;color:var(--text-primary);">'
            f'{level} Risk — {prob*100:.0f}% readmission probability</div>'
            f'<div style="font-size:0.85rem;color:var(--text-secondary);">'
            f'CareStep AI Assessment · 30-Day Readmission</div></div></div></div>'
        )
        st.markdown(header_html, unsafe_allow_html=True)

        td1 = 'style="color:var(--text-secondary);padding:0.5rem 0;width:40%;"'
        td2 = 'style="color:var(--text-primary);font-weight:500;"'
        sep = 'style="border-bottom:1px solid #e5e7eb;"'
        rows = (
            f'<tr {sep}><td {td1}>Age Range</td><td {td2}>{age_display}</td></tr>'
            f'<tr {sep}><td {td1}>Gender</td><td {td2}>{gender_display}</td></tr>'
            f'<tr {sep}><td {td1}>Hospital Stay</td><td {td2}>{stay_display}</td></tr>'
            f'<tr {sep}><td {td1}>Discharge To</td><td {td2}>{discharge_display}</td></tr>'
            f'<tr {sep}><td {td1}>Medications</td><td {td2}>{meds_display}</td></tr>'
            f'<tr {sep}><td {td1}>Insulin</td><td {td2}>{insulin_display}</td></tr>'
            f'<tr {sep}><td {td1}>Primary Diagnosis</td><td {td2}>{diag_display}</td></tr>'
            f'<tr><td {td1}>HbA1c Tested</td><td {td2}>{a1c_display}</td></tr>'
        )
        table_html = f'<div class="glass-card fade-in"><table style="width:100%;font-size:0.88rem;border-collapse:collapse;">{rows}</table></div>'
        st.markdown(table_html, unsafe_allow_html=True)

        if reasons and reasons[0] != "No major individual risk factors — overall pattern contributes to the score":
            st.markdown('<div class="section-title"><span>Key Risk Factors</span></div>', unsafe_allow_html=True)
            for r in reasons[:4]:
                st.markdown(f'<div class="advice-card warning"><span>⚠️</span><span>{r}</span></div>', unsafe_allow_html=True)

        st.markdown('<div class="section-title"><span>Recommended Actions</span></div>', unsafe_allow_html=True)
        rec_actions = []
        if level == "HIGH":
            rec_actions.append("🚨 Urgent follow-up within 48 hours of discharge")
        elif level == "MEDIUM":
            rec_actions.append("📅 Schedule follow-up within 7 days of discharge")
        else:
            rec_actions.append("📅 Keep standard follow-up schedule")

        if inputs.get("a1c_tested") == "No":
            rec_actions.append("🧪 Order HbA1c test — not done this stay")
        if inputs.get("num_meds", 0) >= 10:
            rec_actions.append("💊 Pharmacist medication reconciliation recommended")
        if inputs.get("insulin", "No") != "No":
            rec_actions.append("🩸 Provide blood glucose monitoring supplies and education")

        for a in rec_actions:
            st.markdown(f'<div class="advice-card success"><span>{a.split(" ")[0]}</span><span>{" ".join(a.split(" ")[1:])}</span></div>', unsafe_allow_html=True)

        st.markdown('<div class="section-title"><span>Questions for Your Doctor</span></div>', unsafe_allow_html=True)
        questions = [
            "Should my medication doses be adjusted based on recent blood sugar readings?",
            "Can my medication schedule be simplified to help me stay on track?",
        ]
        if inputs.get("a1c_tested") == "No":
            questions.append("When should I get an HbA1c test done?")
        else:
            questions.append("What does my HbA1c result mean for my daily routine?")
        questions.append("What warning signs should I watch for at home?")
        if level == "HIGH":
            questions.append("Should I consider home health visits or phone check-ins?")

        for q in questions:
            st.markdown(f'<div class="advice-card success"><span>❓</span><span>{q}</span></div>', unsafe_allow_html=True)

        summary_text = (
            f"Patient at {level} risk with {prob*100:.0f}% readmission probability. "
            f"Key factors: {', '.join(reasons[:2]) if reasons else 'no major individual factors'}. "
            f"{'Urgent follow-up recommended.' if level == 'HIGH' else 'Standard follow-up plan in place.'}"
        )
        tts_button(summary_text, AVATARS["carestep"]["color"])
        render_disclaimer()
