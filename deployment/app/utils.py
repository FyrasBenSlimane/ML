import streamlit as st
import streamlit.components.v1 as components
import joblib
import pandas as pd
import numpy as np
from pathlib import Path
import base64
import plotly.graph_objects as go

MODEL_DIR = Path(__file__).resolve().parent.parent / "models"
AVATAR_DIR = Path(__file__).resolve().parent / "static" / "avatars"


def get_avatar_b64(filename):
    path = AVATAR_DIR / filename
    if not path.exists():
        return ""
    with open(path, "rb") as f:
        data = base64.b64encode(f.read()).decode()
    ext = path.suffix.lstrip(".")
    if ext == "jpg":
        ext = "jpeg"
    return f"data:image/{ext};base64,{data}"


AVATARS = {
    "teemo": {
        "name": "Teemo",
        "title": "Readmission Risk Intelligence",
        "owner": "Ryma",
        "color": "#0D9488",
        "gradient": "linear-gradient(135deg, #0D9488, #14B8A6)",
        "image": "teemo.jpg",
        "audience": "both",
        "desc": "Full readmission prediction with SHAP explanations, cost analysis, fairness audit, and a patient-friendly view.",
        "personality": "warm and reassuring",
    },
    "carestep": {
        "name": "CareStep",
        "title": "Recovery Companion",
        "owner": "Fyras",
        "color": "#059669",
        "gradient": "linear-gradient(135deg, #059669, #10B981)",
        "image": "fyras.png",
        "audience": "both",
        "desc": "Your personal 30-day recovery coach with daily check-ins, action plans, and care team summaries.",
        "personality": "motivational and encouraging",
    },
    "medoracle": {
        "name": "MedOracle",
        "title": "Clinical Analytics Engine",
        "owner": "Faycel",
        "color": "#7C3AED",
        "gradient": "linear-gradient(135deg, #7C3AED, #8B5CF6)",
        "image": "faycel.png",
        "audience": "doctor",
        "desc": "Advanced predictive analytics with what-if simulator and comprehensive clinical risk assessment.",
        "personality": "precise and analytical",
    },
    "rxpredict": {
        "name": "RxPredict",
        "title": "Treatment Predictor",
        "owner": "Emna",
        "color": "#D97706",
        "gradient": "linear-gradient(135deg, #D97706, #F59E0B)",
        "image": "emna.png",
        "audience": "doctor",
        "desc": "Predicts whether a patient's treatment will change and whether insulin therapy will be needed.",
        "personality": "knowledgeable and methodical",
    },
    "dailyguard": {
        "name": "DailyGuard",
        "title": "Patient Companion",
        "owner": "Fatma",
        "color": "#2563EB",
        "gradient": "linear-gradient(135deg, #2563EB, #3B82F6)",
        "image": "fatma.png",
        "audience": "both",
        "desc": "Daily guardian monitoring follow-up quality, treatment adherence, and medication reminder risk.",
        "personality": "caring and attentive",
    },
    "bedsense": {
        "name": "BedSense",
        "title": "Bed Planning Intelligence",
        "owner": "Najd",
        "color": "#DC2626",
        "gradient": "linear-gradient(135deg, #DC2626, #EF4444)",
        "image": "najd.png",
        "audience": "doctor",
        "desc": "Predicts readmission probability and expected length of stay for optimal bed allocation.",
        "personality": "efficient and organized",
    },
}


def inject_global_css():
    # Animated background blobs injected as real HTML
    st.markdown("""
    <div class="bg-blobs">
        <div class="blob blob-1"></div>
        <div class="blob blob-2"></div>
        <div class="blob blob-3"></div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap');

    :root {
        --bg-primary: #F0FDFA;
        --bg-card: #FFFFFF;
        --bg-glass: rgba(255, 255, 255, 0.75);
        --glass-border: rgba(13, 148, 136, 0.12);
        --text-primary: #0F172A;
        --text-secondary: #64748B;
        --accent: #0D9488;
        --accent-light: #14B8A6;
        --accent-bg: rgba(13, 148, 136, 0.06);
        --shadow-sm: 0 1px 3px rgba(0,0,0,0.04);
        --shadow-md: 0 4px 20px rgba(0,0,0,0.06);
        --shadow-lg: 0 8px 40px rgba(0,0,0,0.08);
        --shadow-glow: 0 0 40px rgba(13,148,136,0.12);
        --risk-low: #10B981;
        --risk-medium: #F59E0B;
        --risk-high: #EF4444;
        --radius: 20px;
    }

    * { font-family: 'Inter', sans-serif !important; }

    /* ── Animated Background Blobs ── */
    .bg-blobs {
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        pointer-events: none;
        z-index: 0;
        overflow: hidden;
    }
    .blob {
        position: absolute;
        border-radius: 50%;
        filter: blur(80px);
        opacity: 0.5;
    }
    .blob-1 {
        width: 500px; height: 500px;
        background: radial-gradient(circle, rgba(13,148,136,0.18), transparent 70%);
        top: -10%; left: -5%;
        animation: blobMove1 18s ease-in-out infinite alternate;
    }
    .blob-2 {
        width: 400px; height: 400px;
        background: radial-gradient(circle, rgba(124,58,237,0.12), transparent 70%);
        bottom: -10%; right: -5%;
        animation: blobMove2 22s ease-in-out infinite alternate;
    }
    .blob-3 {
        width: 350px; height: 350px;
        background: radial-gradient(circle, rgba(45,212,191,0.12), transparent 70%);
        top: 40%; left: 50%;
        animation: blobMove3 20s ease-in-out infinite alternate;
    }
    @keyframes blobMove1 {
        0% { transform: translate(0, 0) scale(1); }
        50% { transform: translate(80px, 60px) scale(1.15); }
        100% { transform: translate(40px, -30px) scale(0.95); }
    }
    @keyframes blobMove2 {
        0% { transform: translate(0, 0) scale(1); }
        50% { transform: translate(-70px, -50px) scale(1.1); }
        100% { transform: translate(-30px, 40px) scale(1.05); }
    }
    @keyframes blobMove3 {
        0% { transform: translate(0, 0) scale(0.9); }
        50% { transform: translate(-50px, 30px) scale(1.1); }
        100% { transform: translate(60px, -40px) scale(1); }
    }

    .stApp {
        background: var(--bg-primary) !important;
    }
    .main .block-container {
        max-width: 1100px;
        padding: 2rem 1.5rem;
        position: relative;
        z-index: 1;
    }

    #MainMenu, footer, header { visibility: hidden; }
    .stDeployButton { display: none; }

    /* ── Hero Section ── */
    .hero-section {
        background: linear-gradient(135deg, #0D9488 0%, #0F766E 30%, #14B8A6 70%, #2DD4BF 100%);
        background-size: 200% 200%;
        animation: heroGradient 10s ease-in-out infinite;
        border-radius: var(--radius);
        padding: 2.5rem 2rem;
        position: relative;
        overflow: hidden;
        margin-bottom: 1.5rem;
        box-shadow: 0 8px 40px rgba(13,148,136,0.2), 0 0 80px rgba(13,148,136,0.1);
    }
    @keyframes heroGradient {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
    }
    .hero-section::before {
        content: '';
        position: absolute;
        top: -60%; right: -30%;
        width: 500px; height: 500px;
        background: radial-gradient(circle, rgba(255,255,255,0.15) 0%, transparent 70%);
        border-radius: 50%;
        animation: heroOrb1 8s ease-in-out infinite alternate;
    }
    .hero-section::after {
        content: '';
        position: absolute;
        bottom: -40%; left: -20%;
        width: 400px; height: 400px;
        background: radial-gradient(circle, rgba(255,255,255,0.08) 0%, transparent 70%);
        border-radius: 50%;
        animation: heroOrb1 12s ease-in-out infinite alternate-reverse;
    }
    @keyframes heroOrb1 {
        0% { transform: translate(0, 0); }
        100% { transform: translate(30px, -20px); }
    }
    .hero-content { position: relative; z-index: 1; }
    .hero-title {
        font-size: 2rem; font-weight: 800; color: #FFFFFF;
        margin: 0 0 0.5rem; line-height: 1.2;
        text-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .hero-subtitle {
        font-size: 1rem; color: rgba(255,255,255,0.9);
        margin: 0; max-width: 500px;
    }

    /* ── Glass Card ── */
    .glass-card {
        background: var(--bg-glass);
        backdrop-filter: blur(24px);
        -webkit-backdrop-filter: blur(24px);
        border: 1px solid var(--glass-border);
        border-radius: var(--radius);
        padding: 1.5rem;
        transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        box-shadow: var(--shadow-md);
        position: relative;
        overflow: hidden;
    }
    .glass-card::before {
        content: '';
        position: absolute;
        top: 0; left: -100%;
        width: 60%; height: 100%;
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.15), transparent);
        transition: left 0.6s ease;
    }
    .glass-card:hover::before { left: 120%; }
    .glass-card:hover {
        transform: translateY(-6px);
        box-shadow: var(--shadow-lg), var(--shadow-glow);
        border-color: rgba(13,148,136,0.3);
    }

    /* ── Portal Card ── */
    .portal-card {
        background: var(--bg-card);
        border: 2px solid var(--glass-border);
        border-radius: var(--radius);
        padding: 2rem 1.5rem;
        text-align: center;
        cursor: pointer;
        transition: all 0.35s ease;
        box-shadow: var(--shadow-sm);
    }
    .portal-card:hover {
        transform: translateY(-4px);
        box-shadow: var(--shadow-lg);
        border-color: var(--accent);
    }
    .portal-card.active {
        border-color: var(--accent);
        background: var(--accent-bg);
        box-shadow: var(--shadow-glow);
    }
    .portal-icon {
        width: 64px; height: 64px;
        border-radius: 16px;
        display: flex; align-items: center; justify-content: center;
        font-size: 1.8rem;
        margin: 0 auto 1rem;
    }
    .portal-title {
        font-size: 1.2rem; font-weight: 700;
        color: var(--text-primary); margin: 0 0 0.5rem;
    }
    .portal-desc {
        font-size: 0.85rem;
        color: var(--text-secondary); margin: 0;
    }

    /* ── Avatar Card ── */
    .avatar-card {
        background: var(--bg-card);
        border: 1px solid var(--glass-border);
        border-radius: var(--radius);
        padding: 1.5rem;
        text-align: center;
        transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        box-shadow: var(--shadow-sm);
        cursor: pointer;
        height: 100%;
        position: relative;
        overflow: hidden;
    }
    .avatar-card::after {
        content: '';
        position: absolute;
        bottom: 0; left: 0; right: 0;
        height: 3px;
        background: linear-gradient(90deg, var(--accent), var(--accent-light));
        transform: scaleX(0);
        transition: transform 0.4s ease;
    }
    .avatar-card:hover::after { transform: scaleX(1); }
    .avatar-card:hover {
        transform: translateY(-8px);
        box-shadow: var(--shadow-lg), 0 0 30px rgba(13,148,136,0.12);
    }
    .avatar-card:hover .avatar-img-wrap {
        transform: scale(1.08);
        box-shadow: 0 8px 25px rgba(0,0,0,0.15);
    }
    .avatar-img-wrap {
        width: 100px; height: 100px;
        border-radius: 50%;
        margin: 0 auto 1rem;
        overflow: hidden;
        border: 3px solid;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        transition: all 0.4s ease;
    }
    .avatar-img-wrap img {
        width: 100%; height: 100%;
        object-fit: cover;
    }
    .avatar-name {
        font-size: 1.1rem; font-weight: 700;
        color: var(--text-primary); margin: 0 0 0.25rem;
    }
    .avatar-role {
        font-size: 0.8rem; font-weight: 500;
        margin: 0 0 0.5rem;
    }
    .avatar-desc-text {
        font-size: 0.78rem;
        color: var(--text-secondary);
        line-height: 1.4;
        margin: 0;
    }

    /* ── Badge ── */
    .badge {
        display: inline-block;
        padding: 0.2rem 0.7rem;
        border-radius: 100px;
        font-size: 0.7rem;
        font-weight: 600;
        letter-spacing: 0.5px;
        text-transform: uppercase;
    }
    .badge-patient { background: rgba(13,148,136,0.1); color: #0D9488; }
    .badge-doctor { background: rgba(124,58,237,0.1); color: #7C3AED; }
    .badge-both { background: rgba(5,150,105,0.1); color: #059669; }

    /* ── Chat Bubbles ── */
    .chat-row {
        display: flex; gap: 0.75rem; margin: 0.75rem 0;
        align-items: flex-start;
        animation: chatSlideIn 0.5s cubic-bezier(0.16,1,0.3,1) forwards;
    }
    @keyframes chatSlideIn {
        from { opacity: 0; transform: translateX(-12px); }
        to { opacity: 1; transform: translateX(0); }
    }
    .chat-row.user {
        flex-direction: row-reverse;
        animation-name: chatSlideInRight;
    }
    @keyframes chatSlideInRight {
        from { opacity: 0; transform: translateX(12px); }
        to { opacity: 1; transform: translateX(0); }
    }
    .chat-avatar {
        width: 46px; height: 46px; border-radius: 50%;
        overflow: hidden; flex-shrink: 0;
        border: 2px solid var(--glass-border);
        box-shadow: 0 2px 8px rgba(0,0,0,0.06);
    }
    .chat-avatar img { width: 100%; height: 100%; object-fit: cover; }
    .chat-bubble {
        max-width: 80%;
        padding: 1rem 1.3rem;
        border-radius: 18px;
        font-size: 0.9rem;
        line-height: 1.6;
        color: var(--text-primary);
    }
    .chat-bubble.ai {
        background: var(--bg-card);
        border: 1px solid var(--glass-border);
        border-top-left-radius: 4px;
        box-shadow: var(--shadow-sm);
    }
    .chat-bubble.user-msg {
        background: linear-gradient(135deg, var(--accent), var(--accent-light));
        color: white;
        border-top-right-radius: 4px;
        box-shadow: 0 4px 12px rgba(13,148,136,0.2);
    }

    /* ── Page Header ── */
    .page-header {
        background: linear-gradient(135deg, var(--header-color, #0D9488), var(--header-color-end, #14B8A6));
        border-radius: var(--radius);
        padding: 2rem 2rem 2rem 2.5rem;
        display: flex;
        align-items: center;
        gap: 2rem;
        margin-bottom: 1.5rem;
        position: relative;
        overflow: hidden;
        box-shadow: var(--shadow-lg), 0 0 60px rgba(13,148,136,0.15);
    }
    .page-header::before {
        content: '';
        position: absolute;
        top: -60%; right: -25%;
        width: 400px; height: 400px;
        background: radial-gradient(circle, rgba(255,255,255,0.15) 0%, transparent 70%);
        border-radius: 50%;
        animation: headerOrb 8s ease-in-out infinite alternate;
    }
    .page-header::after {
        content: '';
        position: absolute;
        bottom: -50%; left: -10%;
        width: 250px; height: 250px;
        background: radial-gradient(circle, rgba(255,255,255,0.08) 0%, transparent 70%);
        border-radius: 50%;
        animation: headerOrb 12s ease-in-out infinite alternate-reverse;
    }
    @keyframes headerOrb {
        0% { transform: translate(0, 0) scale(1); }
        100% { transform: translate(20px, -15px) scale(1.15); }
    }
    .page-header-avatar {
        width: 110px; height: 110px;
        border-radius: 50%;
        overflow: hidden;
        border: 3px solid rgba(255,255,255,0.6);
        flex-shrink: 0;
        box-shadow: 0 8px 30px rgba(0,0,0,0.2), 0 0 20px rgba(255,255,255,0.15);
        position: relative; z-index: 1;
        animation: avatarFloat 4s ease-in-out infinite;
    }
    .page-header-avatar::after {
        content: '';
        position: absolute;
        inset: -4px;
        border-radius: 50%;
        background: conic-gradient(from 0deg, rgba(255,255,255,0.3), transparent 40%, rgba(255,255,255,0.2), transparent 80%);
        animation: avatarRingSpin 6s linear infinite;
        z-index: -1;
    }
    @keyframes avatarFloat {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-8px); }
    }
    @keyframes avatarRingSpin {
        100% { transform: rotate(360deg); }
    }
    .page-header-avatar img { width: 100%; height: 100%; object-fit: cover; }
    .page-header-info { position: relative; z-index: 1; }
    .page-header-name {
        font-size: 2rem; font-weight: 800; color: white; margin: 0;
        text-shadow: 0 2px 10px rgba(0,0,0,0.15);
    }
    .page-header-title {
        font-size: 0.95rem; color: rgba(255,255,255,0.9);
        margin: 0.3rem 0 0;
    }

    /* ── Teemo Special (bigger avatar + animated gradient) ── */
    .page-header.teemo-header {
        background: linear-gradient(135deg, #0D9488, #0D9488cc, #2DD4BF, #0D9488);
        background-size: 300% 300%;
        animation: teemoGrad 8s ease-in-out infinite;
        box-shadow: 0 10px 50px rgba(13,148,136,0.3), 0 0 80px rgba(13,148,136,0.12);
        padding: 2.5rem 2rem;
    }
    @keyframes teemoGrad {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
    }
    .page-header.teemo-header .page-header-avatar {
        width: 150px; height: 150px;
        border-width: 4px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.25), 0 0 40px rgba(13,148,136,0.35);
    }
    .page-header.teemo-header .page-header-name {
        font-size: 2.4rem;
    }

    /* ── Risk Display ── */
    .risk-container {
        background: var(--bg-card);
        border: 1px solid var(--glass-border);
        border-radius: var(--radius);
        padding: 2rem;
        text-align: center;
        box-shadow: var(--shadow-md);
        margin: 1rem 0;
    }
    .risk-circle {
        width: 130px; height: 130px;
        border-radius: 50%;
        display: inline-flex;
        align-items: center; justify-content: center;
        flex-direction: column;
        border: 4px solid;
        margin: 1rem 0;
    }
    .risk-pct {
        font-size: 2.2rem; font-weight: 900; line-height: 1;
    }
    .risk-label-text {
        font-size: 0.7rem; font-weight: 700;
        letter-spacing: 2px; text-transform: uppercase;
    }
    .risk-bar {
        width: 100%; height: 10px;
        background: #E2E8F0;
        border-radius: 5px;
        overflow: hidden;
        margin: 1rem 0 0.5rem;
    }
    .risk-fill {
        height: 100%; border-radius: 5px;
        transition: width 1.5s ease;
        position: relative; overflow: hidden;
    }
    .risk-fill::after {
        content: '';
        position: absolute; top: 0; left: -100%;
        width: 200%; height: 100%;
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent);
        animation: shimmer 2s infinite;
    }
    @keyframes shimmer { 100% { left: 100%; } }

    /* ── Metric Card ── */
    .metric-card {
        background: var(--bg-card);
        border: 1px solid var(--glass-border);
        border-radius: 16px;
        padding: 1.2rem;
        text-align: center;
        box-shadow: var(--shadow-sm);
        transition: all 0.3s ease;
        position: relative;
        overflow: hidden;
    }
    .metric-card::before {
        content: '';
        position: absolute;
        top: 0; left: 0; right: 0;
        height: 3px;
        background: linear-gradient(90deg, var(--accent), var(--accent-light));
        opacity: 0;
        transition: opacity 0.3s ease;
    }
    .metric-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); }
    .metric-card:hover::before { opacity: 1; }
    .metric-value {
        font-size: 1.8rem; font-weight: 800; line-height: 1.2;
    }
    .metric-label {
        font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.3rem;
    }

    /* ── Advice Card ── */
    .advice-card {
        border-radius: 14px;
        padding: 1rem 1.2rem;
        margin: 0.5rem 0;
        display: flex; align-items: flex-start; gap: 0.75rem;
        font-size: 0.88rem;
        line-height: 1.5;
        color: var(--text-primary);
    }
    .advice-card.warning {
        background: rgba(245,158,11,0.06);
        border: 1px solid rgba(245,158,11,0.15);
    }
    .advice-card.success {
        background: rgba(16,185,129,0.06);
        border: 1px solid rgba(16,185,129,0.15);
    }

    /* ── Section Title ── */
    .section-title {
        font-size: 1.15rem; font-weight: 700;
        color: var(--text-primary);
        margin: 1.5rem 0 0.75rem;
        display: flex; align-items: center; gap: 0.6rem;
    }
    .section-title::after {
        content: ''; flex: 1; height: 1px;
        background: linear-gradient(90deg, var(--glass-border), transparent);
    }

    /* ── Disclaimer ── */
    .disclaimer {
        background: rgba(245,158,11,0.06);
        border: 1px solid rgba(245,158,11,0.15);
        border-left: 4px solid #F59E0B;
        border-radius: 0 14px 14px 0;
        padding: 1rem 1.2rem;
        margin: 1rem 0;
        font-size: 0.83rem;
        color: var(--text-secondary);
        line-height: 1.5;
    }

    /* ── TTS Button ── */
    .tts-btn {
        display: inline-flex; align-items: center; gap: 8px;
        padding: 10px 20px; border-radius: 100px;
        background: rgba(13,148,136,0.08);
        border: 1px solid rgba(13,148,136,0.2);
        color: var(--accent); cursor: pointer;
        font-size: 0.85rem; font-weight: 500;
        transition: all 0.3s ease;
    }
    .tts-btn:hover {
        background: rgba(13,148,136,0.15);
        transform: scale(1.03);
    }

    /* ── Animations ── */
    @keyframes fadeInUp {
        from { opacity: 0; transform: translateY(24px); }
        to { opacity: 1; transform: translateY(0); }
    }
    @keyframes fadeInScale {
        from { opacity: 0; transform: scale(0.92) translateY(12px); }
        to { opacity: 1; transform: scale(1) translateY(0); }
    }
    .fade-in { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) forwards; }
    .fade-d1 { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.1s forwards; opacity: 0; }
    .fade-d2 { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.2s forwards; opacity: 0; }
    .fade-d3 { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.3s forwards; opacity: 0; }
    .fade-d4 { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.4s forwards; opacity: 0; }
    .scale-in { animation: fadeInScale 0.6s cubic-bezier(0.16,1,0.3,1) forwards; }

    @keyframes pulse-ring {
        0%, 100% { box-shadow: 0 0 0 0 var(--pulse-color, rgba(13,148,136,0.3)); }
        50% { box-shadow: 0 0 0 12px transparent; }
    }

    @keyframes float {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-8px); }
    }
    .float-anim { animation: float 3s ease-in-out infinite; }

    @keyframes breathe {
        0%, 100% { box-shadow: 0 0 15px rgba(13,148,136,0.2); }
        50% { box-shadow: 0 0 35px rgba(13,148,136,0.4); }
    }

    @keyframes speakPulse {
        0%, 100% { transform: scaleY(0.4); }
        50% { transform: scaleY(1); }
    }
    .speaking-bars {
        display: inline-flex; gap: 3px; align-items: center; height: 18px; vertical-align: middle;
    }
    .speaking-bars span {
        width: 3px; border-radius: 3px; background: var(--accent);
        animation: speakPulse 0.8s ease-in-out infinite;
    }
    .speaking-bars span:nth-child(1) { height: 8px; animation-delay: 0s; }
    .speaking-bars span:nth-child(2) { height: 14px; animation-delay: 0.15s; }
    .speaking-bars span:nth-child(3) { height: 10px; animation-delay: 0.3s; }
    .speaking-bars span:nth-child(4) { height: 16px; animation-delay: 0.1s; }
    .speaking-bars span:nth-child(5) { height: 6px; animation-delay: 0.25s; }

    /* ── Sidebar ── */
    [data-testid="stSidebar"] {
        background: linear-gradient(180deg, #FFFFFF 0%, #F8FDFC 100%) !important;
        border-right: 1px solid var(--glass-border) !important;
        box-shadow: 4px 0 20px rgba(0,0,0,0.03);
    }
    [data-testid="stSidebar"] [data-testid="stMarkdownContainer"] p {
        color: var(--text-primary);
    }
    [data-testid="stSidebar"] .stPageLink a {
        border-radius: 10px !important;
        transition: all 0.3s ease !important;
    }
    [data-testid="stSidebar"] .stPageLink a:hover {
        background: rgba(13,148,136,0.06) !important;
    }

    /* ── Streamlit Form Overrides ── */
    .stSelectbox > div > div,
    .stNumberInput > div > div > input,
    .stTextInput > div > div > input {
        border-color: #E2E8F0 !important;
        border-radius: 12px !important;
        background: white !important;
    }
    .stSelectbox > div > div:focus-within,
    .stNumberInput > div > div:focus-within {
        border-color: var(--accent) !important;
        box-shadow: 0 0 0 2px rgba(13,148,136,0.15) !important;
    }

    button[kind="primary"] {
        background: linear-gradient(135deg, #0D9488, #14B8A6) !important;
        border: none !important;
        border-radius: 12px !important;
        font-weight: 600 !important;
        padding: 0.6rem 2rem !important;
        box-shadow: 0 4px 12px rgba(13,148,136,0.25) !important;
        transition: all 0.3s ease !important;
    }
    button[kind="primary"]:hover {
        box-shadow: 0 6px 20px rgba(13,148,136,0.35) !important;
        transform: translateY(-1px);
    }

    .stTabs [data-baseweb="tab-list"] {
        gap: 4px;
        background: #F1F5F9;
        border-radius: 12px;
        padding: 4px;
    }
    .stTabs [data-baseweb="tab"] {
        border-radius: 10px !important;
        font-weight: 500 !important;
        padding: 8px 16px !important;
    }
    .stTabs [aria-selected="true"] {
        background: white !important;
        box-shadow: var(--shadow-sm) !important;
        color: var(--accent) !important;
    }

    /* ── Aliases for page compatibility ── */
    .result-container {
        background: var(--bg-card);
        border: 1px solid var(--glass-border);
        border-radius: var(--radius);
        padding: 2rem;
        box-shadow: var(--shadow-md);
        margin: 1rem 0;
    }
    .risk-gauge {
        width: 100%; height: 10px;
        background: #E2E8F0;
        border-radius: 5px;
        overflow: hidden;
        margin: 0.5rem 0;
    }

    ::-webkit-scrollbar { width: 6px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #CBD5E1; border-radius: 3px; }

    /* ── How-It-Works Steps ── */
    .step-card {
        background: var(--bg-card);
        border: 1px solid var(--glass-border);
        border-radius: 16px;
        padding: 1.5rem;
        text-align: center;
        box-shadow: var(--shadow-sm);
    }
    .step-number {
        width: 40px; height: 40px;
        border-radius: 12px;
        display: inline-flex;
        align-items: center; justify-content: center;
        font-size: 1rem; font-weight: 800;
        color: white; margin-bottom: 0.75rem;
    }
    .step-title {
        font-size: 0.95rem; font-weight: 700;
        color: var(--text-primary); margin: 0 0 0.3rem;
    }
    .step-desc {
        font-size: 0.8rem; color: var(--text-secondary);
        line-height: 1.4; margin: 0;
    }

    /* ── Team Section ── */
    .team-card {
        text-align: center;
    }
    .team-avatar {
        width: 56px; height: 56px;
        border-radius: 50%;
        margin: 0 auto 0.5rem;
        overflow: hidden;
        border: 2px solid var(--glass-border);
    }
    .team-avatar img { width: 100%; height: 100%; object-fit: cover; }
    .team-name {
        font-size: 0.85rem; font-weight: 600;
        color: var(--text-primary); margin: 0;
    }
    .team-role {
        font-size: 0.72rem; color: var(--text-secondary); margin: 0;
    }
    </style>
    """, unsafe_allow_html=True)


def load_model(name):
    model_path = MODEL_DIR / f"{name}_model.joblib"
    feat_path = MODEL_DIR / f"{name}_features.joblib"
    if not model_path.exists():
        model_path = MODEL_DIR / f"{name}.joblib"
    return joblib.load(model_path), joblib.load(feat_path)


def load_model_ab(base_name):
    model_a = joblib.load(MODEL_DIR / f"{base_name}_model_a.joblib")
    feats_a = joblib.load(MODEL_DIR / f"{base_name}_features_a.joblib")
    model_b = joblib.load(MODEL_DIR / f"{base_name}_model_b.joblib")
    feats_b = joblib.load(MODEL_DIR / f"{base_name}_features_b.joblib")
    return model_a, feats_a, model_b, feats_b


def tts_button(text, color="#0D9488", voice_gender="female"):
    escaped = text.replace("'", "\\'").replace('"', '\\"').replace('\n', ' ')
    components.html(f"""
    <style>
    @keyframes btnSpeakPulse {{
        0%, 100% {{ transform: scaleY(0.3); }}
        50% {{ transform: scaleY(1); }}
    }}
    .tts-bars {{ display: none; gap: 2px; align-items: center; height: 16px; }}
    .tts-bars.active {{ display: inline-flex; }}
    .tts-bars span {{
        width: 3px; border-radius: 2px; background: {color};
        animation: btnSpeakPulse 0.7s ease-in-out infinite;
    }}
    .tts-bars span:nth-child(1) {{ height: 6px; animation-delay: 0s; }}
    .tts-bars span:nth-child(2) {{ height: 12px; animation-delay: 0.1s; }}
    .tts-bars span:nth-child(3) {{ height: 8px; animation-delay: 0.2s; }}
    .tts-bars span:nth-child(4) {{ height: 14px; animation-delay: 0.15s; }}
    </style>
    <div style="margin: 0.5rem 0;">
        <button id="ttsBtn" onclick="speak()" style="
            display: inline-flex; align-items: center; gap: 8px;
            padding: 10px 22px; border-radius: 100px;
            background: {color}12; border: 1px solid {color}33;
            color: {color}; cursor: pointer; font-size: 14px;
            font-weight: 600; font-family: 'Inter', sans-serif;
            transition: all 0.3s ease;
        " onmouseover="this.style.background='{color}22'; this.style.transform='scale(1.03)'"
          onmouseout="this.style.background='{color}12'; this.style.transform='scale(1)'">
            <svg id="ttsIcon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="2">
                <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
                <path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07"/>
            </svg>
            <span id="ttsLabel">Listen to Summary</span>
            <span class="tts-bars" id="ttsBars"><span></span><span></span><span></span><span></span></span>
        </button>
    </div>
    <script>
    function getVoice() {{
        const voices = window.speechSynthesis.getVoices();
        const gender = '{voice_gender}';
        if (gender === 'female') {{
            const femaleNames = ['Zira', 'Samantha', 'Karen', 'Victoria', 'Google UK English Female',
                                  'Microsoft Zira', 'Google US English', 'Fiona', 'Moira', 'Tessa'];
            for (const name of femaleNames) {{
                const v = voices.find(v => v.name.includes(name));
                if (v) return v;
            }}
            const fem = voices.find(v => v.name.toLowerCase().includes('female') || v.name.includes('Zira'));
            if (fem) return fem;
        }}
        return voices.find(v => v.lang.startsWith('en')) || voices[0] || null;
    }}
    function speak() {{
        const btn = document.getElementById('ttsBtn');
        const bars = document.getElementById('ttsBars');
        const label = document.getElementById('ttsLabel');
        if (window.speechSynthesis.speaking) {{
            window.speechSynthesis.cancel();
            bars.classList.remove('active');
            label.textContent = 'Listen to Summary';
            return;
        }}
        const u = new SpeechSynthesisUtterance('{escaped}');
        u.lang = 'en-US';
        u.rate = 0.92;
        u.pitch = 1.1;
        const v = getVoice();
        if (v) u.voice = v;
        u.onstart = () => {{ bars.classList.add('active'); label.textContent = 'Speaking...'; }};
        u.onend = () => {{ bars.classList.remove('active'); label.textContent = 'Listen to Summary'; }};
        window.speechSynthesis.speak(u);
    }}
    window.speechSynthesis.onvoiceschanged = () => {{}};
    </script>
    """, height=55)


def render_avatar_header(key):
    a = AVATARS[key]
    img_b64 = get_avatar_b64(a["image"])
    aud_class = "badge-" + a["audience"]
    aud_label = {"patient": "Patient Portal", "doctor": "Doctor Portal", "both": "Shared Portal"}[a["audience"]]
    img_html = f'<img src="{img_b64}" alt="{a["name"]}">' if img_b64 else f'<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:2rem;color:white;">{a["name"][0]}</div>'

    extra_class = " teemo-header" if key == "teemo" else ""
    bars_html = ""
    if key == "teemo":
        bars_html = '<span class="speaking-bars"><span></span><span></span><span></span><span></span><span></span></span>'

    st.markdown(f"""
    <div class="page-header{extra_class} fade-in" style="--header-color: {a['color']}; --header-color-end: {a['color']}cc;">
        <div class="page-header-avatar">{img_html}</div>
        <div class="page-header-info">
            <p class="page-header-name">{a['name']}</p>
            <p class="page-header-title">{a['title']} &mdash; by {a['owner']}</p>
            <div style="margin-top: 0.5rem;">
                <span class="badge {aud_class}">{aud_label}</span>
                {bars_html}
            </div>
        </div>
    </div>
    """, unsafe_allow_html=True)


def chat_message(key, text, is_user=False):
    a = AVATARS[key]
    img_b64 = get_avatar_b64(a["image"])
    if is_user:
        st.markdown(f"""
        <div class="chat-row user">
            <div class="chat-avatar" style="background: #E2E8F0;">
                <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:1.2rem;">👤</div>
            </div>
            <div class="chat-bubble user-msg">{text}</div>
        </div>
        """, unsafe_allow_html=True)
    else:
        img_html = f'<img src="{img_b64}">' if img_b64 else f'<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:1.2rem;background:{a["color"]}22;color:{a["color"]};">{a["name"][0]}</div>'
        st.markdown(f"""
        <div class="chat-row">
            <div class="chat-avatar" style="border-color: {a['color']}33;">{img_html}</div>
            <div class="chat-bubble ai">{text}</div>
        </div>
        """, unsafe_allow_html=True)


def render_risk_result(probability, avatar_key="teemo"):
    a = AVATARS[avatar_key]
    pct = probability * 100
    if pct < 14:
        level, color, emoji = "LOW", "var(--risk-low)", "&#x1F7E2;"
        advice = "Your risk is below the hospital average. Keep following your care plan."
    elif pct < 25:
        level, color, emoji = "MEDIUM", "var(--risk-medium)", "&#x1F7E0;"
        advice = "Your risk is moderate. A follow-up within 7 days is recommended."
    else:
        level, color, emoji = "HIGH", "var(--risk-high)", "&#x1F534;"
        advice = "Your risk is elevated. Please schedule an urgent follow-up and medication review."

    st.markdown(f"""
    <div class="risk-container fade-in">
        <div style="font-size:0.8rem; color:var(--text-secondary); text-transform:uppercase;
                    letter-spacing:2px; margin-bottom:0.5rem;">30-Day Readmission Risk</div>
        <div class="risk-circle" style="border-color:{color}; --pulse-color:{color}40;
             animation: pulse-ring 2s infinite;">
            <div class="risk-pct" style="color:{color};">{pct:.0f}%</div>
            <div class="risk-label-text" style="color:{color};">{level}</div>
        </div>
        <div style="font-size:0.85rem; color:var(--text-secondary); margin-top:0.5rem;">
            Hospital average: ~11% &nbsp; {emoji} {level} RISK
        </div>
        <div class="risk-bar">
            <div class="risk-fill" style="width:{min(pct,100):.0f}%; background:{color};"></div>
        </div>
    </div>
    """, unsafe_allow_html=True)
    return level, advice


def render_advice_cards(reasons, actions):
    st.markdown('<div class="section-title">Why This Risk Level</div>', unsafe_allow_html=True)
    for r in reasons:
        st.markdown(f"""
        <div class="advice-card warning">
            <span style="font-size:1.1rem;">&#9888;&#65039;</span>
            <span>{r}</span>
        </div>
        """, unsafe_allow_html=True)

    st.markdown('<div class="section-title">What You Can Do</div>', unsafe_allow_html=True)
    for a in actions:
        st.markdown(f"""
        <div class="advice-card success">
            <span style="font-size:1.1rem;">&#x2705;</span>
            <span>{a}</span>
        </div>
        """, unsafe_allow_html=True)


def generate_reasons(row, feature_names):
    reasons = []
    if "total_prior_visits" in row.index and row.get("total_prior_visits", 0) >= 3:
        reasons.append(f"Multiple prior visits ({int(row['total_prior_visits'])} total) suggest a complex health situation")
    if "num_medications" in row.index and row["num_medications"] >= 10:
        reasons.append(f"Taking {int(row['num_medications'])} medications increases interaction and adherence risk")
    if "insulin_prescrite" in row.index and row["insulin_prescrite"] == 1:
        reasons.append("Insulin therapy requires careful monitoring after discharge")
    if "time_in_hospital" in row.index and row["time_in_hospital"] >= 7:
        reasons.append(f"Extended hospital stay ({int(row['time_in_hospital'])} days) indicates higher severity")
    if "A1Cresult" in row.index and row["A1Cresult"] == "Not_Tested":
        reasons.append("HbA1c was not tested this stay — an important diabetes marker was missed")
    if "number_diagnoses" in row.index and row["number_diagnoses"] >= 7:
        reasons.append(f"{int(row['number_diagnoses'])} diagnoses indicate multiple health conditions")
    if "age_ordinal" in row.index and row["age_ordinal"] >= 7:
        age_ranges = {7: "70-80", 8: "80-90", 9: "90+"}
        reasons.append(f"Age range ({age_ranges.get(int(row['age_ordinal']), '70+')}) is a non-modifiable risk factor")
    if "num_med_changes" in row.index and row["num_med_changes"] >= 2:
        reasons.append(f"{int(row['num_med_changes'])} medication changes during this stay need careful follow-up")
    return reasons[:5] if reasons else ["No major individual risk factors — overall pattern contributes to the score"]


def generate_actions(reasons, level):
    actions = []
    if level in ("HIGH", "MEDIUM"):
        actions.append("Book a follow-up appointment within 7 days of discharge")
    if any("medication" in r.lower() for r in reasons):
        actions.append("Ask your pharmacist to review all medications for interactions")
    if any("insulin" in r.lower() for r in reasons):
        actions.append("Monitor blood sugar daily and follow your insulin schedule")
    if any("HbA1c" in r for r in reasons):
        actions.append("Ask your doctor about scheduling an HbA1c test")
    if any("prior visit" in r.lower() or "hospital stay" in r.lower() for r in reasons):
        actions.append("Discuss a home health visit or phone check-in with your care team")
    if level == "HIGH":
        actions.append("Go to the ER if blood sugar stays very high/low, or you feel confused or short of breath")
    if not actions:
        actions.append("Continue following your care team's discharge instructions")
        actions.append("Keep all scheduled follow-up appointments")
    return actions


def render_disclaimer():
    st.markdown("""
    <div class="disclaimer">
        <strong>&#9888;&#65039; Important:</strong> This is a <strong>decision-support tool, not a diagnosis</strong>.
        It does not replace your doctor's judgment. Always follow your care team's advice.
    </div>
    """, unsafe_allow_html=True)


def make_gauge_chart(value, title, color):
    fig = go.Figure(go.Indicator(
        mode="gauge+number",
        value=value,
        domain={'x': [0, 1], 'y': [0, 1]},
        title={'text': title, 'font': {'size': 14, 'color': '#64748B'}},
        number={'font': {'size': 36, 'color': '#0F172A'}, 'suffix': '%'},
        gauge={
            'axis': {'range': [0, 100], 'tickcolor': '#94A3B8', 'tickfont': {'color': '#94A3B8'}},
            'bar': {'color': color},
            'bgcolor': '#F1F5F9',
            'bordercolor': '#E2E8F0',
            'steps': [
                {'range': [0, 14], 'color': 'rgba(16,185,129,0.08)'},
                {'range': [14, 25], 'color': 'rgba(245,158,11,0.08)'},
                {'range': [25, 100], 'color': 'rgba(239,68,68,0.08)'}
            ],
            'threshold': {
                'line': {'color': '#EF4444', 'width': 2},
                'thickness': 0.8, 'value': 25
            }
        }
    ))
    fig.update_layout(
        paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
        font={'color': '#0F172A'}, height=250,
        margin=dict(l=20, r=20, t=40, b=10)
    )
    return fig


def check_login():
    if not st.session_state.get("logged_in"):
        st.markdown("""
        <div class="glass-card" style="text-align:center; padding:3rem;">
            <div style="font-size:3rem; margin-bottom:1rem;">&#x1F512;</div>
            <h3 style="color:var(--text-primary); margin:0 0 0.5rem;">Please Log In</h3>
            <p style="color:var(--text-secondary);">Go to the Home page to log in first.</p>
        </div>
        """, unsafe_allow_html=True)
        st.stop()


def check_portal(allowed):
    check_login()
    portal = st.session_state.get("portal_type", "")
    if portal not in allowed:
        label = "Medical Staff" if "medical" in allowed else "Patient"
        st.markdown(f"""
        <div class="glass-card" style="text-align:center; padding:3rem;">
            <div style="font-size:3rem; margin-bottom:1rem;">&#x26D4;</div>
            <h3 style="color:var(--text-primary); margin:0 0 0.5rem;">Access Restricted</h3>
            <p style="color:var(--text-secondary);">This page is only available to <strong>{label}</strong> portal users.</p>
        </div>
        """, unsafe_allow_html=True)
        st.stop()


def render_sidebar():
    with st.sidebar:
        if st.session_state.get("logged_in"):
            portal = st.session_state.get("portal_type", "")
            name = st.session_state.get("user_name", "User")
            portal_icon = "&#x1F3E5;" if portal == "medical" else "&#x1F9D1;&#x200D;&#x2695;&#xFE0F;"
            portal_label = "Medical Portal" if portal == "medical" else "Patient Portal"
            portal_color = "#7C3AED" if portal == "medical" else "#0D9488"
            st.markdown(f"""
            <div style="background:{portal_color}11; border:1px solid {portal_color}22;
                        border-radius:14px; padding:1rem; margin-bottom:1rem; text-align:center;">
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


AGE_RANGES = {
    0: "0-10", 1: "10-20", 2: "20-30", 3: "30-40", 4: "40-50",
    5: "50-60", 6: "60-70", 7: "70-80", 8: "80-90", 9: "90-100"
}

DIAG_GROUPS = ["Circulatory", "Respiratory", "Digestive", "Diabetes",
               "Injury", "Musculoskeletal", "Genitourinary", "Neoplasms",
               "External", "Other"]

DIAG_PLAIN = {
    "Circulatory": "Heart or blood vessel problem",
    "Respiratory": "Breathing or lung problem",
    "Digestive": "Stomach or digestive problem",
    "Diabetes": "Diabetes complication",
    "Injury": "Injury or accident",
    "Musculoskeletal": "Bone, joint, or muscle problem",
    "Genitourinary": "Kidney or urinary problem",
    "Neoplasms": "Cancer or tumor",
    "External": "External cause",
    "Other": "Other medical condition",
}
