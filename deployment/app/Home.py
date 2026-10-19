import streamlit as st
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from utils import inject_global_css, AVATARS, get_avatar_b64

PAGE_MAP = {
    "teemo": "pages/1_Teemo.py",
    "carestep": "pages/2_CareStep.py",
    "medoracle": "pages/3_MedOracle.py",
    "rxpredict": "pages/4_RxPredict.py",
    "dailyguard": "pages/5_DailyGuard.py",
    "bedsense": "pages/6_BedSense.py",
}

st.set_page_config(
    page_title="ReadmitGuard",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="collapsed",
)

inject_global_css()

if st.session_state.get("logged_in"):
    with st.sidebar:
        portal = st.session_state.get("portal_type", "")
        name = st.session_state.get("user_name", "User")
        portal_color = "#7C3AED" if portal == "medical" else "#0D9488"
        portal_label = "Medical Portal" if portal == "medical" else "Patient Portal"
        st.markdown(f"""
        <div style="text-align:center; padding:1rem 0 0.5rem;">
            <div style="font-size:1.6rem; font-weight:800; color:#0D9488;">ReadmitGuard</div>
            <div style="font-size:0.75rem; color:#64748B; margin-top:2px;">AI-Powered Health Platform</div>
        </div>
        <div style="background:{portal_color}11; border:1px solid {portal_color}22;
                    border-radius:14px; padding:1rem; margin:0.5rem 0; text-align:center;">
            <div style="font-size:0.75rem; color:{portal_color}; font-weight:600;
                        text-transform:uppercase; letter-spacing:1px;">{portal_label}</div>
            <div style="font-size:1rem; font-weight:700; color:var(--text-primary);
                        margin-top:0.3rem;">Welcome, {name}</div>
        </div>
        """, unsafe_allow_html=True)
        if st.button("Logout", use_container_width=True):
            for k in ["logged_in", "user_name", "portal_type"]:
                st.session_state.pop(k, None)
            st.rerun()

    portal = st.session_state["portal_type"]
    name = st.session_state["user_name"]

    st.markdown(f"""
    <div class="hero-section fade-in">
        <div class="hero-content">
            <p class="hero-title">Welcome back, {name}!</p>
            <p class="hero-subtitle">
                You are logged into the <strong>{"Medical" if portal == "medical" else "Patient"} Portal</strong>.
                Select an avatar from the sidebar to begin.
            </p>
            <div style="display:flex; gap:0.75rem; margin-top:1.5rem; flex-wrap:wrap;">
                <div style="background:rgba(255,255,255,0.2); border-radius:12px; padding:0.5rem 1rem;">
                    <div style="font-size:1.3rem; font-weight:800; color:white;">99,340</div>
                    <div style="font-size:0.7rem; color:rgba(255,255,255,0.8);">Patient Records</div>
                </div>
                <div style="background:rgba(255,255,255,0.2); border-radius:12px; padding:0.5rem 1rem;">
                    <div style="font-size:1.3rem; font-weight:800; color:white;">6</div>
                    <div style="font-size:0.7rem; color:rgba(255,255,255,0.8);">AI Avatars</div>
                </div>
                <div style="background:rgba(255,255,255,0.2); border-radius:12px; padding:0.5rem 1rem;">
                    <div style="font-size:1.3rem; font-weight:800; color:white;">130</div>
                    <div style="font-size:0.7rem; color:rgba(255,255,255,0.8);">US Hospitals</div>
                </div>
            </div>
        </div>
    </div>
    """, unsafe_allow_html=True)

    if portal == "patient":
        visible = {k: v for k, v in AVATARS.items() if v["audience"] in ("patient", "both")}
    else:
        visible = dict(AVATARS)

    st.markdown('<div class="section-title fade-d1"><span>Your Available Avatars</span></div>', unsafe_allow_html=True)

    keys = list(visible.keys())
    row_size = 3
    for i in range(0, len(keys), row_size):
        row_keys = keys[i:i + row_size]
        cols = st.columns(row_size)
        for j, key in enumerate(row_keys):
            a = AVATARS[key]
            img_b64 = get_avatar_b64(a["image"])
            aud_class = "badge-" + a["audience"]
            aud_label = {"patient": "Patient", "doctor": "Doctor", "both": "Shared"}[a["audience"]]
            img_html = f'<img src="{img_b64}" alt="{a["name"]}">' if img_b64 else f'<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:2rem;color:white;background:{a["gradient"]};">{a["name"][0]}</div>'
            with cols[j]:
                st.markdown(f"""
                <div class="avatar-card fade-d{min(j+1, 4)}">
                    <div class="avatar-img-wrap" style="border-color:{a['color']};">
                        {img_html}
                    </div>
                    <p class="avatar-name">{a['name']}</p>
                    <p class="avatar-role" style="color:{a['color']};">{a['title']}</p>
                    <p class="avatar-desc-text">{a['desc']}</p>
                    <div style="margin-top:0.75rem; display:flex; justify-content:space-between; align-items:center;">
                        <span class="badge {aud_class}">{aud_label}</span>
                        <span style="font-size:0.72rem; color:#94A3B8;">by {a['owner']}</span>
                    </div>
                </div>
                """, unsafe_allow_html=True)
                if st.button(f"Open {a['name']}", key=f"go_{key}", use_container_width=True):
                    st.switch_page(PAGE_MAP[key])
        st.markdown("<div style='height:0.75rem;'></div>", unsafe_allow_html=True)

    st.markdown("""
    <div style="text-align:center; padding:2rem 0 1rem; border-top:1px solid rgba(13,148,136,0.1); margin-top:2rem;">
        <p style="color:#94A3B8; font-size:0.78rem; margin:0;">
            ReadmitGuard &mdash; Advanced ML Course Project &bull; UCI Dataset #296 &bull; Decision-support tool, not a diagnosis
        </p>
    </div>
    """, unsafe_allow_html=True)

else:
    st.markdown("""
    <style>
    [data-testid="stSidebar"] { display: none !important; }
    .main .block-container { max-width: 600px; padding-top: 4rem; }
    </style>
    """, unsafe_allow_html=True)

    teemo_b64 = get_avatar_b64("teemo.jpg")
    logo_html = f'<img src="{teemo_b64}" style="width:80px;height:80px;border-radius:50%;border:3px solid rgba(13,148,136,0.3);object-fit:cover;">' if teemo_b64 else '<div style="width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,#0D9488,#14B8A6);display:flex;align-items:center;justify-content:center;font-size:2rem;color:white;">R</div>'

    st.markdown(f"""
    <div style="text-align:center; margin-bottom:2rem;" class="fade-in">
        <div style="display:inline-block; margin-bottom:1rem;">{logo_html}</div>
        <h1 style="color:var(--text-primary); font-size:2rem; font-weight:800; margin:0;">
            Welcome to <span style="color:#0D9488;">ReadmitGuard</span>
        </h1>
        <p style="color:var(--text-secondary); font-size:0.95rem; margin-top:0.5rem;">
            AI-powered diabetes readmission prevention platform
        </p>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("""
    <div class="glass-card fade-d1" style="padding:2rem;">
        <h3 style="color:var(--text-primary); text-align:center; margin:0 0 1.5rem; font-size:1.2rem;">
            Sign In to Continue
        </h3>
    </div>
    """, unsafe_allow_html=True)

    with st.form("login_form"):
        user_name = st.text_input("Your Name", placeholder="Enter your name...")
        portal_choice = st.radio(
            "Select Your Portal",
            ["Patient Portal", "Medical Portal"],
            captions=[
                "For patients: understand your risk, get recovery advice, track your health",
                "For medical staff: clinical analytics, SHAP explanations, fairness audit, batch analysis"
            ],
            index=0,
        )
        submitted = st.form_submit_button("Sign In", type="primary", use_container_width=True)

    if submitted:
        if not user_name.strip():
            st.error("Please enter your name.")
        else:
            st.session_state["logged_in"] = True
            st.session_state["user_name"] = user_name.strip()
            st.session_state["portal_type"] = "patient" if portal_choice == "Patient Portal" else "medical"
            st.rerun()

    st.markdown("""
    <div style="display:flex; justify-content:center; gap:1.5rem; margin-top:2rem; flex-wrap:wrap;" class="fade-d2">
        <div style="text-align:center;">
            <div style="font-size:1.5rem; font-weight:800; color:#0D9488;">99,340</div>
            <div style="font-size:0.75rem; color:var(--text-secondary);">Patient Records</div>
        </div>
        <div style="text-align:center;">
            <div style="font-size:1.5rem; font-weight:800; color:#7C3AED;">6</div>
            <div style="font-size:0.75rem; color:var(--text-secondary);">AI Avatars</div>
        </div>
        <div style="text-align:center;">
            <div style="font-size:1.5rem; font-weight:800; color:#D97706;">11</div>
            <div style="font-size:0.75rem; color:var(--text-secondary);">ML Models</div>
        </div>
        <div style="text-align:center;">
            <div style="font-size:1.5rem; font-weight:800; color:#059669;">130</div>
            <div style="font-size:0.75rem; color:var(--text-secondary);">US Hospitals</div>
        </div>
    </div>

    <div style="text-align:center; padding:2rem 0 1rem; margin-top:2rem;">
        <p style="color:#94A3B8; font-size:0.78rem; margin:0;">
            ReadmitGuard &mdash; Advanced ML Course Project &bull; UCI Dataset #296<br>
            Diabetes 130-US Hospitals (1999-2008) &bull; Decision-support tool, not a diagnosis
        </p>
    </div>
    """, unsafe_allow_html=True)
