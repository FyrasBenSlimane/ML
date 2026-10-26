import streamlit as st
import sys
import logging
import pandas as pd
import numpy as np
import plotly.graph_objects as go
from datetime import date, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[3]))
from utils import (
    inject_global_css, render_avatar_header, render_disclaimer, render_sidebar,
    check_portal, tts_button, chat_message, AVATARS, AGE_RANGES,
)

st.set_page_config(page_title="BedSense — Bed Planning", page_icon="🏥", layout="wide")
inject_global_css()
render_sidebar()
check_portal(["medical"])
render_avatar_header("bedsense")

GREEN, AMBER, RED = "#10B981", "#F59E0B", "#EF4444"
BLUE, TEAL, PURPLE, INK, MUTED, GRID = "#2563EB", "#0D9488", "#7C3AED", "#0F172A", "#64748B", "#E2E8F0"
STATUS = {
    "ok": (GREEN, "✓", "Enough beds"),
    "tight": (AMBER, "⚠", "Tight"),
    "over": (RED, "⛔", "Beds missing"),
}
LEVEL = {
    "Low": (GREEN, "🟢", "✓", "Low risk"),
    "Medium": (AMBER, "🟠", "⚠", "Medium risk"),
    "High": (RED, "🔴", "▲", "High risk"),
}
SHORT_ADVICE = {"High": "Visit within 7 days + call", "Medium": "Visit within 2 weeks", "Low": "Usual check-up"}


def rgba(hex_color, alpha):
    h = hex_color.lstrip("#")
    return f"rgba({int(h[0:2], 16)},{int(h[2:4], 16)},{int(h[4:6], 16)},{alpha})"


def plot_config(filename):
    return {"displaylogo": False, "modeBarButtons": [["toImage"]],
            "toImageButtonOptions": {"format": "png", "scale": 2, "filename": filename}}


def html(markup):
    st.markdown(" ".join(line.strip() for line in markup.splitlines()), unsafe_allow_html=True)


def style_fig(fig, height=360, **layout):
    fig.update_layout(
        paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
        font=dict(color=INK, family="Inter, sans-serif", size=13), height=height,
        margin=dict(l=10, r=10, t=10, b=10), hoverlabel=dict(font_family="Inter, sans-serif"),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="left", x=0),
        **layout,
    )
    fig.update_xaxes(gridcolor=GRID, zeroline=False)
    fig.update_yaxes(gridcolor=GRID, zeroline=False)
    return fig


def chart_title(text, sub=""):
    html(f"""<div class="bs-chart-title"><div class="bs-chart-head">{text}</div>
             {f'<div class="bs-chart-sub">{sub}</div>' if sub else ''}</div>""")


def fold(title, items, icon="💡"):
    lis = "".join(f"<li>{i}</li>" for i in items)
    html(f'<details class="bs-more"><summary>{icon} {title}</summary><ul>{lis}</ul></details>')


def how_to_read(items):
    fold("How to read this chart", items, "📖")


def kpi(icon, value, label, sub, color, tip):
    return (f'<div class="bs-kpi" style="--kpi:{color};" title="{tip}">'
            f'<div class="bs-kpi-top"><span class="bs-kpi-icon" style="color:{color};">{icon}</span>'
            f'<span class="bs-kpi-help" aria-label="{tip}">?</span></div>'
            f'<div class="bs-kpi-value">{value}</div><div class="bs-kpi-label">{label}</div>'
            f'<div class="bs-kpi-sub">{sub}</div></div>')


def day_name(d):
    return d.strftime("%a %d %b")


def plural(n, word, many=None):
    return f"{n} {word if n == 1 else (many or word + 's')}"


def friendly_error(what):
    html(f"""<div class="bs-alert tight"><div class="bs-alert-icon">🛠️</div><div>
             <div class="bs-alert-title">{what} could not be shown</div>
             <div class="bs-alert-text">Please reload the page. If this keeps happening, contact the IT team
             and tell them which tab you were on.</div></div></div>""")


html("""
<style>
.bs-kpis { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:1rem; margin:0.5rem 0 1.2rem; }
.bs-kpi { background:var(--bg-glass); border:1px solid var(--glass-border); border-top:4px solid var(--kpi);
          border-radius:var(--radius); padding:1rem 1.2rem; box-shadow:var(--shadow-md);
          transition:transform .25s ease, box-shadow .25s ease; animation:bsUp .45s ease both; }
.bs-kpi:hover { transform:translateY(-3px); box-shadow:var(--shadow-lg); }
.bs-kpi-top { display:flex; justify-content:space-between; align-items:center; }
.bs-kpi-icon { font-size:1.3rem; font-weight:800; }
.bs-kpi-help { width:20px; height:20px; border-radius:50%; border:1px solid var(--glass-border); color:var(--text-secondary);
               font-size:.72rem; display:inline-flex; align-items:center; justify-content:center; cursor:help; }
.bs-kpi-value { font-size:2.1rem; font-weight:800; color:var(--kpi); line-height:1.1; margin-top:.3rem; }
.bs-kpi-label { font-weight:700; color:var(--text-primary); font-size:.92rem; }
.bs-kpi-sub { color:var(--text-secondary); font-size:.8rem; margin-top:.15rem; }
.bs-alert { display:flex; gap:.9rem; align-items:flex-start; border-radius:16px; padding:1rem 1.2rem; margin:.2rem 0 1rem;
            border:1px solid; border-left-width:6px; animation:bsUp .45s ease both; }
.bs-alert.over { background:rgba(239,68,68,.06); border-color:rgba(239,68,68,.25); border-left-color:#EF4444; }
.bs-alert.tight { background:rgba(245,158,11,.07); border-color:rgba(245,158,11,.28); border-left-color:#F59E0B; }
.bs-alert.ok { background:rgba(16,185,129,.07); border-color:rgba(16,185,129,.25); border-left-color:#10B981; }
.bs-alert-icon { font-size:1.5rem; line-height:1.2; }
.bs-alert-title { font-weight:800; color:var(--text-primary); }
.bs-alert-text { color:var(--text-secondary); font-size:.9rem; margin-top:.15rem; }
.bs-chart-title { margin:1.3rem 0 .2rem; }
.bs-chart-head { font-size:1.12rem; font-weight:800; color:var(--text-primary); }
.bs-chart-sub { font-size:.84rem; color:var(--text-secondary); margin-top:.1rem; }
.bs-more { background:var(--bg-glass); border:1px solid var(--glass-border); border-radius:14px; padding:.55rem 1rem;
           margin:.1rem 0 1rem; }
.bs-more summary { cursor:pointer; font-weight:600; font-size:.88rem; color:var(--accent); list-style:none; }
.bs-more summary::-webkit-details-marker { display:none; }
.bs-more summary::after { content:"＋"; float:right; color:var(--text-secondary); }
.bs-more[open] summary::after { content:"－"; }
.bs-more ul { margin:.6rem 0 .2rem 1.1rem; padding:0; color:var(--text-secondary); font-size:.87rem; }
.bs-more li { margin:.25rem 0; }
.bs-pill { display:inline-flex; align-items:center; gap:.35rem; padding:.25rem .7rem; border-radius:100px;
           font-size:.8rem; font-weight:700; }
.bs-estimate { display:inline-block; padding:.15rem .55rem; border-radius:100px; background:rgba(100,116,139,.12);
               color:var(--text-secondary); font-size:.72rem; font-weight:700; letter-spacing:.5px; text-transform:uppercase;
               vertical-align:middle; margin-left:.4rem; }
.bs-day { background:var(--bg-glass); border:1px solid var(--glass-border); border-radius:var(--radius); padding:1.1rem 1.3rem;
          box-shadow:var(--shadow-md); animation:bsUp .35s ease both; margin-bottom:.5rem; }
.bs-day-grid { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:.8rem; margin-top:.8rem; }
.bs-day-num { font-size:1.5rem; font-weight:800; color:var(--text-primary); }
.bs-day-lbl { font-size:.78rem; color:var(--text-secondary); }
.bs-week { background:var(--bg-glass); border:1px solid var(--glass-border); border-radius:var(--radius); padding:1rem 1.2rem;
           box-shadow:var(--shadow-sm); margin-bottom:1rem; }
.bs-week-row { display:flex; justify-content:space-between; gap:.5rem; padding:.45rem 0; border-bottom:1px solid var(--glass-border);
               font-size:.9rem; }
.bs-week-row:last-child { border-bottom:none; }
.bs-week-row span:first-child { color:var(--text-secondary); }
.bs-week-row span:last-child { font-weight:700; color:var(--text-primary); text-align:right; white-space:nowrap; }
.bs-card { background:var(--bg-glass); border:1px solid var(--glass-border); border-left:5px solid var(--lvl);
           border-radius:var(--radius); padding:1.2rem 1.4rem; box-shadow:var(--shadow-md); animation:bsUp .35s ease both; }
.bs-card h4 { margin:0 0 .3rem; color:var(--lvl); font-size:1.1rem; font-weight:800; }
.bs-card p { margin:.25rem 0; color:var(--text-primary); font-size:.93rem; }
.bs-card ul { margin:.3rem 0 .2rem 1.1rem; padding:0; color:var(--text-secondary); font-size:.88rem; }
.bs-todo { margin-top:.7rem; padding:.7rem .9rem; border-radius:12px; background:var(--accent-bg); font-size:.9rem;
           color:var(--text-primary); }
.bs-skel { border-radius:16px; background:linear-gradient(90deg,#E2E8F0 25%,#F1F5F9 37%,#E2E8F0 63%);
           background-size:400% 100%; animation:bsShimmer 1.3s ease infinite; }
.bs-skel-grid { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:1rem; margin:1rem 0; }
@keyframes bsShimmer { 0% { background-position:100% 50%; } 100% { background-position:0 50%; } }
@keyframes bsUp { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:none; } }
@media (max-width: 900px) {
  .bs-kpis, .bs-skel-grid { grid-template-columns:repeat(2,minmax(0,1fr)); }
  .bs-day-grid { grid-template-columns:repeat(2,minmax(0,1fr)); }
}
@media (max-width: 520px) {
  .bs-kpis, .bs-skel-grid, .bs-day-grid { grid-template-columns:1fr; }
  .bs-kpi-value { font-size:1.7rem; }
}
</style>
""")

chat_message("bedsense",
    "I'm <strong>BedSense</strong>, your bed planning assistant. I look at every patient in hospital "
    "and every patient sent home in the last 30 days, and tell you <strong>how many beds you will need "
    "each day</strong>, where beds may run short, and which patients need close follow-up.")

loading = st.empty()
with loading.container():
    html('<div class="bs-skel-grid">' + '<div class="bs-skel" style="height:118px;"></div>' * 4 + '</div>'
         '<div class="bs-skel" style="height:56px; margin-bottom:1rem;"></div>'
         '<div class="bs-skel" style="height:340px;"></div>')

try:
    from capalit_ml import planning as P

    @st.cache_resource(show_spinner=False)
    def get_simulation(day_iso):
        return P.simulate(today=date.fromisoformat(day_iso))

    sim = get_simulation(date.today().isoformat())
    SERVICES = P.services(sim)
except Exception:
    loading.empty()
    html("""<div class="glass-card" style="text-align:center; padding:2.5rem;">
            <div style="font-size:2.5rem;">🛠️</div>
            <h3 style="color:var(--text-primary); margin:.5rem 0;">Bed planning is not available right now</h3>
            <p style="color:var(--text-secondary);">The planning files could not be opened. Please check that the
            <strong>capalit_ml</strong> folder sits next to the <strong>deployment</strong> folder, then reload
            this page. If it still does not work, contact the IT team.</p></div>""")
    st.stop()
loading.empty()


# ── Tab 1: Bed Planning ─────────────────────────────────────────────────────

def tab_planning():
    f1, f2, f3 = st.columns([1, 1, 1])
    with f1:
        period = st.selectbox("Period", [7, 14, 28], index=1,
                              format_func=lambda d: {7: "Next 7 days", 14: "Next 2 weeks", 28: "Next 4 weeks"}[d],
                              help="How far ahead you want to look.")
    with f2:
        service = st.selectbox("Service", ["Whole hospital"] + SERVICES,
                               help="Look at one service only. Its beds are its share of the hospital's beds.")
    svc = None if service == "Whole hospital" else service
    plan = P.daily_plan(sim, svc, period)
    full = P.daily_plan(sim, svc)
    follow = P.followup_list(sim, svc)
    found = P.alerts(plan)
    today_row = plan.iloc[0]
    cap = int(today_row["capacity"])
    with f3:
        html(f"""<div style="padding-top:1.9rem; color:var(--text-secondary); font-size:.85rem;">
                 📅 Today is <strong>{day_name(sim.today)}</strong> · <strong>{cap}</strong> beds
                 {'in this service' if svc else 'in the hospital'}</div>""")

    need_today = int(round(today_row["beds_needed"]))
    free_today = cap - need_today
    n_over = int((plan["status"] == "over").sum())
    n_tight = int((plan["status"] == "tight").sum())
    n_high = int((follow["level"] == "High").sum())
    occ_color = RED if need_today > cap else (AMBER if today_row["status"] == "tight" else GREEN)

    html('<div class="bs-kpis">'
         + kpi("🛏️", need_today, "Beds needed today", f"{round(100 * need_today / cap)}% of {cap} beds",
               occ_color, "Patients already here, plus today's admissions, plus patients expected to come back.")
         + kpi("✓" if free_today > 0 else "⛔", max(free_today, 0), "Free beds today",
               f"{-free_today} beds missing" if free_today < 0 else "ready for new patients",
               GREEN if free_today > 0.1 * cap else (AMBER if free_today > 0 else RED),
               "Beds left once everyone expected today has a bed.")
         + kpi("▲", n_high, "High-risk patients", "need close follow-up", RED if n_high else GREEN,
               "Patients in hospital now or sent home in the last 30 days who are most likely to come back.")
         + kpi("⛔" if n_over else ("⚠" if n_tight else "✓"), n_over, "Days with beds missing",
               f"+ {plural(n_tight, 'tight day')} · next {period} days",
               RED if n_over else (AMBER if n_tight else GREEN),
               "Days when more beds will be needed than the service has.")
         + '</div>')

    over_alerts = [a for a in found if a["severity"] == "over"]
    if over_alerts:
        a = over_alerts[0]
        more = len(found) - 1
        html(f"""<div class="bs-alert over"><div class="bs-alert-icon">⛔</div><div>
                 <div class="bs-alert-title">About {plural(a['shortfall'], 'bed')} will be missing on {day_name(a['date'])}</div>
                 <div class="bs-alert-text">{a['action']} These are suggestions to discuss with the team.
                 {f'<br><strong>{plural(more, "other day")}</strong> {"also needs" if more == 1 else "also need"} attention (see below).' if more else ''}
                 </div></div></div>""")
    elif found:
        html(f"""<div class="bs-alert tight"><div class="bs-alert-icon">⚠</div><div>
                 <div class="bs-alert-title">Beds will be tight on {plural(len(found), 'day')}, first on {day_name(found[0]['date'])}</div>
                 <div class="bs-alert-text">Beds should be enough, but with little room to spare. {found[0]['action']}</div>
                 </div></div>""")
    else:
        html(f"""<div class="bs-alert ok"><div class="bs-alert-icon">✓</div><div>
                 <div class="bs-alert-title">There will be enough beds every day for the next {period} days</div>
                 <div class="bs-alert-text">No action needed. This page updates every day.</div></div></div>""")
    if len(found) > 1:
        fold(f"See all {len(found)} days that need attention",
             [f"{STATUS[a['severity']][1]} <strong>{a['title']}</strong> — {a['action']}" for a in found], "📋")

    # Daily beds chart
    if n_over:
        worst = plan.loc[plan["shortfall"].idxmax()]
        headline = f"About {plural(int(worst['shortfall']), 'bed')} will be missing on {day_name(worst['date'])}"
    elif n_tight:
        headline = f"Beds will be tight on {plural(n_tight, 'day')}, but should be enough"
    else:
        headline = f"There will be enough beds every day for the next {period} days"
    chart_title(headline, "Beds needed each day, compared with the beds the service has.")

    x = pd.to_datetime(plan["date"])
    fig = go.Figure()
    for col, name, color in [
        ("current_patients", "Patients already in hospital", BLUE),
        ("new_patients", "New admissions", TEAL),
        ("expected_returns", "Patients expected to come back", PURPLE),
    ]:
        fig.add_trace(go.Scatter(
            x=x, y=plan[col], name=name, stackgroup="beds", mode="lines", line=dict(width=0.5, color=color),
            fillcolor=rgba(color, 0.7), hovertemplate=f"{name}: %{{y:.0f}} beds<extra></extra>"))
    fig.add_trace(go.Scatter(x=x, y=plan["beds_safe"], name="To be safe (9 times out of 10)", mode="lines",
                             line=dict(color=MUTED, width=1.5, dash="dot"),
                             hovertemplate="To be safe, plan for: %{y:.0f} beds<extra></extra>"))
    fig.add_trace(go.Scatter(x=x, y=plan["capacity"], name="Beds available", mode="lines",
                             line=dict(color=INK, width=2.5, dash="dash"),
                             hovertemplate="Beds available: %{y:.0f}<extra></extra>"))
    for d in plan.loc[plan["status"] == "over", "date"]:
        ts = pd.Timestamp(d)
        fig.add_vrect(x0=ts - pd.Timedelta(hours=12), x1=ts + pd.Timedelta(hours=12),
                      fillcolor="rgba(239,68,68,0.16)", line_width=0, layer="above")
    top = max(plan["beds_safe"].max(), cap) * 1.08
    style_fig(fig, 420, hovermode="x unified")
    fig.update_layout(legend_traceorder="normal")
    fig.update_yaxes(title_text="Beds", range=[0, top])
    fig.update_xaxes(title_text="", tickformat="%a %d %b", rangeslider=dict(visible=period > 7, thickness=0.06),
                     range=[x.iloc[0] - pd.Timedelta(hours=12), x.iloc[-1] + pd.Timedelta(hours=12)])
    st.plotly_chart(fig, use_container_width=True, config=plot_config("beds-per-day"))
    how_to_read([
        "Each colour is a group of patients who will need a bed that day; stacked together they show <strong>all the beds needed</strong>.",
        "The <strong>black dashed line</strong> is the number of beds available. When the colours go above it, beds are missing.",
        "<strong>Red bands</strong> mark the days when beds will be missing.",
        "The <strong>grey dotted line</strong> is a safe plan: on 9 days out of 10, fewer beds than this will be needed.",
        "Patients who come back can return any day within 30 days of going home, so their beds are spread over that time.",
        "Hover over a day to see the numbers. Drag the edges of the small bar under the chart to zoom on a few days. "
        "The camera icon saves the chart as a picture.",
    ])

    # Calendar + weekly bars
    c_left, c_right = st.columns([1.15, 1])
    with c_left:
        chart_title("Day by day: click a day to see the details",
                    "✓ green = enough beds · ⚠ orange = tight · ⛔ red = beds missing")
        cal = plan.copy()
        cal["weekday"] = [d.strftime("%a") for d in cal["date"]]
        week_start = [d - timedelta(days=d.weekday()) for d in cal["date"]]
        cal["week"] = [f"Week of {d.strftime('%d %b')}" for d in week_start]
        weeks_order = list(dict.fromkeys(cal["week"]))
        cfig = go.Figure(go.Scatter(
            x=cal["weekday"], y=cal["week"], mode="markers+text",
            marker=dict(symbol="square", size=46, color=[STATUS[s][0] for s in cal["status"]],
                        line=dict(color="white", width=2), opacity=0.92),
            text=[f"<b>{d.day}</b><br>{STATUS[s][1]}" for d, s in zip(cal["date"], cal["status"])],
            textfont=dict(color="white", size=12),
            selected=dict(marker=dict(opacity=1)),
            unselected=dict(marker=dict(opacity=0.55), textfont=dict(color="white")),
            customdata=np.stack([cal["day"].astype(str), [day_name(d) for d in cal["date"]],
                                 cal["beds_needed"].round().astype(int).astype(str), cal["capacity"].astype(str),
                                 [STATUS[s][2] for s in cal["status"]]], axis=1),
            hovertemplate="<b>%{customdata[1]}</b><br>%{customdata[2]} of %{customdata[3]} beds needed"
                          "<br>%{customdata[4]}<extra></extra>"))
        style_fig(cfig, 80 + 62 * len(weeks_order), showlegend=False)
        cfig.update_xaxes(categoryorder="array", categoryarray=["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                          side="top", showgrid=False, fixedrange=True)
        cfig.update_yaxes(categoryorder="array", categoryarray=weeks_order[::-1], showgrid=False, fixedrange=True)
        event = st.plotly_chart(cfig, use_container_width=True, on_select="rerun", selection_mode="points",
                                key=f"bs_cal_{svc}_{period}", config={"displayModeBar": False})
        try:
            points = event["selection"]["points"]
        except (KeyError, TypeError):
            points = []
        default_day = int(over_alerts[0]["day"]) if over_alerts else 0
        clicked = int(float(points[0]["customdata"][0])) if points and points[0].get("customdata") is not None else None
        if clicked is not None and clicked != st.session_state.get("bs_cal_clicked"):
            st.session_state["bs_day"] = clicked
        st.session_state["bs_cal_clicked"] = clicked
        sel = st.session_state.get("bs_day", default_day)
        sel = sel if sel < len(plan) else default_day
        sel = st.selectbox("Or pick a day", list(plan["day"]), index=int(sel),
                           format_func=lambda d: day_name(plan.loc[d, "date"]), key=f"bs_pick_{svc}_{period}_{sel}")
        st.session_state["bs_day"] = sel

    with c_right:
        weeks = P.weekly_plan(plan)
        short_weeks = weeks[weeks["margin"] < 0]
        if len(short_weeks):
            w = short_weeks.iloc[0]
            wh = f"{w['label']}: {plural(int(-w['margin']), 'bed')} missing on the busiest day"
        else:
            wh = "Every week has spare beds, even on its busiest day"
        chart_title(wh, "Most beds needed in the week, compared with the beds available.")
        wl = [f"{r.label}<br>{r.start.strftime('%d %b')}–{r.end.strftime('%d %b')}" for r in weeks.itertuples()]
        wfig = go.Figure()
        wfig.add_trace(go.Bar(x=wl, y=weeks["capacity"], name="Beds available", marker_color="#CBD5E1",
                              hovertemplate="Beds available: %{y}<extra></extra>"))
        wfig.add_trace(go.Bar(x=wl, y=weeks["peak_beds"], name="Beds needed on the busiest day",
                              marker_color=[RED if m < 0 else (AMBER if m < 0.1 * c else TEAL)
                                            for m, c in zip(weeks["margin"], weeks["capacity"])],
                              text=[f"{-m} missing" if m < 0 else f"{m} spare" for m in weeks["margin"]],
                              textposition="outside", textfont=dict(size=12, color=INK),
                              hovertemplate="Busiest day: %{y} beds<extra></extra>"))
        style_fig(wfig, 80 + 62 * max(len(weeks_order), 3), barmode="group", bargap=0.3)
        wfig.update_yaxes(title_text="Beds", range=[0, weeks[["capacity", "peak_beds"]].max().max() * 1.2])
        st.plotly_chart(wfig, use_container_width=True, config=plot_config("beds-per-week"))
        how_to_read([
            "Grey bars: beds the service has. Coloured bars: beds needed on the <strong>busiest day</strong> of that week.",
            "The number above each coloured bar says how many beds are <strong>spare</strong> or <strong>missing</strong> that day.",
            "Red = beds missing, orange = less than 1 bed in 10 spare, teal = comfortable.",
        ])

    r = plan.loc[sel]
    color, icon, word = STATUS[r["status"]]
    gap = int(r["capacity"] - round(r["beds_needed"]))
    day_alert = next((a for a in found if a["day"] == sel), None)
    n_new = int(r["admissions_planned"])
    arriving_new = f"{n_new} arriving that day" if n_new else "nobody new arriving that day"
    n_back = r["returns_arriving"]
    arriving_back = f"about {round(n_back)} arriving that day" if n_back >= 0.5 else "less than 1 arriving that day"
    html(f"""<div class="bs-day" style="border-top:4px solid {color};">
        <div style="display:flex; justify-content:space-between; flex-wrap:wrap; gap:.5rem; align-items:center;">
          <div style="font-size:1.15rem; font-weight:800; color:var(--text-primary);">📅 {r['date'].strftime('%A %d %B')}</div>
          <span class="bs-pill" style="background:{rgba(color, .1)}; color:{color};">{icon} {word}</span>
        </div>
        <div class="bs-day-grid">
          <div><div class="bs-day-num">{round(r['beds_needed'])} / {int(r['capacity'])}</div><div class="bs-day-lbl">beds needed / beds available</div></div>
          <div><div class="bs-day-num" style="color:{color};">{abs(gap)}</div><div class="bs-day-lbl">{'beds missing' if gap < 0 else 'beds free'}</div></div>
          <div><div class="bs-day-num">{int(r['nurses_needed'])} / {int(r['nurses_on_duty'])}</div><div class="bs-day-lbl">nurses needed per shift / on duty (estimate)</div></div>
          <div><div class="bs-day-num">{int(r['current_patients'])}</div><div class="bs-day-lbl">patients already in hospital</div></div>
          <div><div class="bs-day-num">{int(r['new_patients'])}</div><div class="bs-day-lbl">new admissions in a bed ({arriving_new})</div></div>
          <div><div class="bs-day-num">{round(r['expected_returns'])}</div><div class="bs-day-lbl">beds for patients coming back ({arriving_back})</div></div>
        </div>
        {f'<div class="bs-todo">💡 <strong>What to do:</strong> {day_alert["action"]}</div>' if day_alert else ''}
    </div>""")

    # Staff
    peak_gap = plan.loc[plan["staff_gap"].idxmax()]
    per_nurse = sim.cfg["hospital"]["patients_per_nurse"]
    if peak_gap["staff_gap"] > 0:
        sh = f"About {plural(int(peak_gap['staff_gap']), 'more nurse')} needed per shift on {day_name(peak_gap['date'])}"
    else:
        sh = "There should be enough nurses on every shift"
    html(f"""<div class="bs-chart-title"><div class="bs-chart-head">{sh}<span class="bs-estimate">Estimate</span></div>
             <div class="bs-chart-sub">Nurses needed per shift (1 nurse for every {per_nurse} patients) compared with nurses on duty.</div></div>""")
    sfig = go.Figure()
    sfig.add_trace(go.Bar(x=x, y=plan["nurses_needed"], name="Nurses needed per shift",
                          marker_color=[RED if g > 0 else TEAL for g in plan["staff_gap"]],
                          hovertemplate="Nurses needed: %{y}<extra></extra>"))
    sfig.add_trace(go.Scatter(x=x, y=plan["nurses_on_duty"], name="Nurses on duty", mode="lines",
                              line=dict(color=INK, width=2.5, dash="dash"),
                              hovertemplate="Nurses on duty: %{y}<extra></extra>"))
    style_fig(sfig, 300, hovermode="x unified")
    sfig.update_yaxes(title_text="Nurses per shift",
                      range=[0, max(plan["nurses_needed"].max(), plan["nurses_on_duty"].max()) * 1.15])
    sfig.update_xaxes(tickformat="%a %d %b")
    st.plotly_chart(sfig, use_container_width=True, config=plot_config("nurses-per-shift"))
    how_to_read([
        "This is an <strong>estimate</strong>: it comes from the number of beds needed, not from the staff rota.",
        f"We count 1 nurse for every {per_nurse} patients. Red bars are shifts with fewer nurses on duty than needed.",
        "The patients-per-nurse ratio and the nurses on duty are set in the planning settings file.",
    ])

    # This week vs next week
    chart_title("This week compared with next week")
    cmp = P.week_compare(full)
    if len(cmp) == 2:
        tw, nw = cmp.loc["This week"], cmp.loc["Next week"]

        def change(a, b):
            if round(b) == round(a):
                return '<span style="color:var(--text-secondary);">= same</span>'
            up = b > a
            return f'<span style="color:{RED if up else GREEN};">{"↑" if up else "↓"} {abs(round(b - a))}</span>'

        rows = [
            ("Beds needed on the busiest day", int(tw["peak_beds"]), int(nw["peak_beds"])),
            ("Beds needed on an average day", round(tw["avg_needed"]), round(nw["avg_needed"])),
            ("Days with beds missing", int(tw["critical_days"]), int(nw["critical_days"])),
            ("Patients expected to come back", round(tw["returns"]), round(nw["returns"])),
            ("Nurses needed per shift (busiest day)", int(tw["nurses_peak"]), int(nw["nurses_peak"])),
        ]
        w1, w2 = st.columns(2)
        for col, title, wk, is_next in [(w1, "This week", tw, False), (w2, "Next week", nw, True)]:
            body = "".join(
                f'<div class="bs-week-row"><span>{label}</span><span>{b if is_next else a}'
                f'{" &nbsp;" + change(a, b) if is_next else ""}</span></div>'
                for label, a, b in rows)
            with col:
                html(f"""<div class="bs-week"><div style="font-weight:800; color:var(--text-primary);">{title}
                         <span style="font-weight:500; color:var(--text-secondary); font-size:.85rem;">
                         · {wk['start'].strftime('%d %b')}–{wk['end'].strftime('%d %b')}</span></div>{body}</div>""")

    export = plan.assign(date=[d.isoformat() for d in plan["date"]])[[
        "date", "beds_needed", "beds_safe", "capacity", "free_beds", "current_patients", "new_patients",
        "expected_returns", "returns_arriving", "nurses_needed", "nurses_on_duty", "status"]].rename(columns={
        "date": "Date", "beds_needed": "Beds needed", "beds_safe": "Beds to plan to be safe",
        "capacity": "Beds available", "free_beds": "Free beds (negative = missing)",
        "current_patients": "Patients already in hospital", "new_patients": "New admissions in a bed",
        "expected_returns": "Beds for patients coming back", "returns_arriving": "Patients coming back that day",
        "nurses_needed": "Nurses needed per shift (estimate)", "nurses_on_duty": "Nurses on duty",
        "status": "Status"}).round(1)
    export["Status"] = export["Status"].map(lambda s: STATUS[s][2])
    st.download_button("⬇️  Download the day-by-day plan (spreadsheet)", export.to_csv(index=False).encode("utf-8"),
                       file_name=f"bed-plan-{sim.today.isoformat()}.csv", mime="text/csv", use_container_width=True)

    fold("Where do these numbers come from?", [
        "<strong>Patients coming back</strong>: for every patient sent home, we use their chance of coming back within "
        "30 days and how long they would likely stay. A patient with a 20% chance who would stay 5 days counts for 1 bed-day.",
        "Patients can come back any day within 30 days of going home, so their beds are spread over that time.",
        "<strong>Patients already in hospital</strong> leave on their planned day. <strong>New admissions</strong> follow "
        f"the usual activity (about {sim.cfg['activity']['planned_admissions_per_day']} a day for the whole hospital, "
        "fewer at weekends).",
        "Bed numbers, nurses on duty and the usual activity come from the planning settings file "
        "(<code>capalit_ml/config/planning.toml</code>). They are starting values: please replace them with your "
        "service's real numbers.",
        "These figures help you plan. They do not replace the judgement of the care team.",
    ], "ℹ️")

    msg = (f"Today {need_today} of {cap} beds are needed. "
           + (f"Beds will be missing on {plural(n_over, 'day')} in the next {period} days, first on "
              f"{day_name(over_alerts[0]['date'])}. " if n_over else f"There are enough beds for the next {period} days. ")
           + f"{plural(n_high, 'patient')} at high risk of coming back {'needs' if n_high == 1 else 'need'} close follow-up.")
    chat_message("bedsense", msg)
    tts_button(msg, AVATARS["bedsense"]["color"])
    render_disclaimer()


# ── Tab 2: Patients to Follow Up ───────────────────────────────────────────

def tab_people():
    g1, g2, g3 = st.columns([1, 1, 1.2])
    with g1:
        p_service = st.selectbox("Service", ["Whole hospital"] + SERVICES, key="bs_p_service",
                                 help="Only show patients of one service.")
    with g2:
        where = st.selectbox("Patients", ["Everyone", "In hospital", "At home"],
                             help="In hospital: still in a bed. At home: sent home in the last 30 days.")
    with g3:
        levels = st.multiselect("Risk of coming back", ["High", "Medium", "Low"], default=["High", "Medium", "Low"],
                                format_func=lambda l: f"{LEVEL[l][1]} {l}",
                                help="Risk that the patient comes back to hospital within 30 days.")
    ps = None if p_service == "Whole hospital" else p_service
    people = P.followup_list(sim, ps)
    if where != "Everyone":
        people = people[people["where"] == where]
    counts = people["level"].value_counts().reindex(["High", "Medium", "Low"], fill_value=0)

    html('<div class="bs-kpis">'
         + kpi("👥", len(people), "Patients to follow", "in hospital, or home for less than 30 days", TEAL,
               "Everyone who could still come back within 30 days.")
         + kpi("▲", counts["High"], "High risk", "follow-up within 7 days + phone call", RED,
               "Most likely to come back: plan close follow-up.")
         + kpi("⚠", counts["Medium"], "Medium risk", "follow-up within 2 weeks", AMBER,
               "Plan an earlier check-up than usual.")
         + kpi("✓", counts["Low"], "Low risk", "usual check-up in 3 to 4 weeks", GREEN,
               "Usual follow-up is enough.")
         + '</div>')

    if people.empty:
        html("""<div class="glass-card" style="text-align:center; padding:2rem;">
                <div style="font-size:2rem;">🔎</div><p style="color:var(--text-secondary);">
                No patients match these filters. Try choosing <strong>Everyone</strong> or another service.</p></div>""")
        return

    d_left, d_right = st.columns(2)
    with d_left:
        chart_title(f"{plural(int(counts['High']), 'patient')} {'needs' if counts['High'] == 1 else 'need'} close follow-up",
                    "Patients by risk of coming back within 30 days.")
        dfig = go.Figure(go.Pie(
            labels=[f"{LEVEL[l][2]} {l} risk" for l in counts.index], values=counts.values, hole=0.62,
            marker=dict(colors=[LEVEL[l][0] for l in counts.index], line=dict(color="white", width=3)),
            sort=False, direction="clockwise", textinfo="value", textfont=dict(size=14, color="white"),
            hovertemplate="%{label}: %{value} patients (%{percent})<extra></extra>"))
        dfig.add_annotation(text=f"<b>{len(people)}</b><br>patients", showarrow=False, font=dict(size=20, color=INK))
        style_fig(dfig, 300)
        dfig.update_layout(legend=dict(orientation="h", y=-0.08, x=0.5, xanchor="center"))
        st.plotly_chart(dfig, use_container_width=True, config=plot_config("patients-by-risk"))
    with d_right:
        beds_by = people.groupby("level")["bed_days"].sum().reindex(["High", "Medium", "Low"], fill_value=0)
        share_high = 100 * beds_by["High"] / max(beds_by.sum(), 1e-9)
        share_pat = 100 * counts["High"] / max(len(people), 1)
        chart_title(f"High-risk patients are {share_pat:.0f}% of patients but {share_high:.0f}% of the beds for returns",
                    "Beds these patients are expected to use if they come back, in bed-days.")
        bfig = go.Figure(go.Bar(
            y=[f"{LEVEL[l][2]} {l} risk" for l in beds_by.index], x=beds_by.values, orientation="h",
            marker_color=[LEVEL[l][0] for l in beds_by.index],
            text=[f"{v:.0f} bed-days" for v in beds_by.values], textposition="auto",
            hovertemplate="%{y}: about %{x:.0f} bed-days<extra></extra>"))
        style_fig(bfig, 300, showlegend=False)
        bfig.update_yaxes(autorange="reversed")
        bfig.update_xaxes(title_text="Bed-days (1 bed for 1 day)")
        st.plotly_chart(bfig, use_container_width=True, config=plot_config("beds-by-risk"))
    how_to_read([
        "Left: how many patients are at low, medium or high risk of coming back within 30 days.",
        "Right: how many bed-days each group is expected to use for returns. 1 bed-day = 1 bed for 1 day.",
        "Following up high-risk patients closely is where it can save the most beds.",
    ])

    shown = people[people["level"].isin(levels)].reset_index(drop=True)
    chart_title("Patients list", "Click a row to open the patient's card below. Click a column title to sort.")
    if shown.empty:
        html("""<div class="glass-card" style="text-align:center; padding:1.5rem;">
                <p style="color:var(--text-secondary); margin:0;">No patients at the chosen risk levels.
                Tick another level in <strong>Risk of coming back</strong> above.</p></div>""")
        return
    table = pd.DataFrame({
        "Patient": shown["pid"],
        "Where": shown["where"],
        "When": shown["when"],
        "Age": shown["age_band"],
        "Service": shown["service"],
        "Risk of coming back": (shown["risk"] * 100).round(0),
        "Level": [f"{LEVEL[l][1]} {l}" for l in shown["level"]],
        "Stay if they come back": shown["stay_text"],
        "What to do": shown["level"].map(SHORT_ADVICE),
    })
    ev = st.dataframe(
        table, use_container_width=True, hide_index=True, height=420, on_select="rerun",
        selection_mode="single-row", key=f"bs_people_{ps}_{where}_{'-'.join(levels)}",
        column_config={
            "Risk of coming back": st.column_config.ProgressColumn(
                "Risk of coming back", help="Chance that the patient comes back within 30 days",
                format="%d%%", min_value=0, max_value=100),
            "Stay if they come back": st.column_config.TextColumn(
                help="How long the patient would likely stay if they come back"),
            "What to do": st.column_config.TextColumn(width="medium", help="Open the patient's card for the full advice"),
        })
    rows = ev.selection.rows if ev and ev.selection else []
    st.download_button("⬇️  Download this list (spreadsheet)", table.to_csv(index=False).encode("utf-8"),
                       file_name=f"patients-to-follow-{sim.today.isoformat()}.csv", mime="text/csv",
                       use_container_width=True)

    row = shown.iloc[rows[0]] if rows else shown.iloc[0]
    e = P.explain(row)
    color, dot, icon, word = LEVEL[row["level"]]
    chart_title(f"Patient card — {row['pid']}",
                "" if rows else "Showing the first patient of the list. Click a row above to see another patient.")
    facts = "".join(f"<li>{f}</li>" for f in e["facts"])
    html(f"""<div class="bs-card" style="--lvl:{color};">
        <div style="display:flex; justify-content:space-between; flex-wrap:wrap; gap:.5rem;">
          <h4>{icon} {e['headline']}</h4>
          <span class="bs-pill" style="background:{rgba(color, .1)}; color:{color};">{round(row['risk'] * 100)}% · {word}</span>
        </div>
        <p>{e['sentence']}</p>
        <p>🛏️ {e['stay']}</p>
        <p style="color:var(--text-secondary); font-size:.86rem;">{row['age_band']} years · {row['gender']} ·
           {row['service']} · {row['when']} · came in as: {e['arrival']} · left for: {e['leaving_to']}</p>
        <div style="margin-top:.5rem; font-weight:700; font-size:.88rem; color:var(--text-primary);">What the file shows</div>
        <ul>{facts}</ul>
        <div class="bs-todo">💡 <strong>What to do:</strong> {e['advice']}.</div>
    </div>""")


# ── Tab 3: Check a Patient ─────────────────────────────────────────────────

DIAG_CODES = {
    "Heart or blood vessels": "428", "Lungs or breathing": "486", "Digestion": "577",
    "Diabetes": "250.02", "Injury": "820", "Bones or joints": "715", "Kidneys or bladder": "599",
    "Cancer": "162", "Other": "780",
}
SPECIALTY = {
    "Internal medicine": "InternalMedicine", "Emergency": "Emergency/Trauma",
    "General practice": "Family/GeneralPractice", "Cardiology": "Cardiology",
    "Surgery": "Surgery-General", "Kidney care": "Nephrology", "Other services": np.nan,
}
DOSE = {"No": "Not taking it", "Steady": "Same dose", "Up": "Dose increased", "Down": "Dose lowered"}


def tab_check():
    html("""<div class="glass-card fade-in" style="margin-bottom:1rem; padding:1.1rem 1.4rem;">
            <div style="font-weight:700; color:var(--text-primary);">🔍 Check one patient before they go home</div>
            <div style="color:var(--text-secondary); font-size:.86rem;">Fill in what you know from the file. You will see the
            risk that they come back within 30 days, how long they would stay, and what to do.</div></div>""")
    with st.form("bs_check"):
        st.markdown("##### 👤 The patient")
        c1, c2, c3 = st.columns(3)
        with c1:
            age = st.selectbox("Age", list(AGE_RANGES.keys()), index=6, format_func=lambda a: f"{AGE_RANGES[a]} years")
        with c2:
            sex = st.selectbox("Sex", ["Female", "Male"])
        with c3:
            race = st.selectbox("Background", ["Prefer not to say", "Caucasian", "African American", "Hispanic",
                                               "Asian", "Other"], help="Optional. Leave 'Prefer not to say' if unknown.")
        st.markdown("##### 🏥 This stay")
        c1, c2, c3 = st.columns(3)
        with c1:
            p_svc = st.selectbox("Service", SERVICES, key="bs_c_svc")
            adm_type = st.selectbox("How they came in", [1, 2, 3, 7],
                                    format_func=lambda c: {3: "Planned"}.get(c, P.label("admission_type_id", c)))
        with c2:
            adm_src = st.selectbox("Sent by", [7, 1, 2, 4, 6], format_func=lambda c: P.label("admission_source_id", c))
            disch = st.selectbox("Going to", [1, 6, 3, 22, 2, 7],
                                 format_func=lambda c: P.label("discharge_disposition_id", c))
        with c3:
            days_in = st.slider("Days in hospital this time", 1, 14, 4)
            n_meds = st.slider("Medicines given", 1, 80, 15)
        c1, c2, c3 = st.columns(3)
        with c1:
            n_lab = st.slider("Lab tests", 1, 130, 44)
        with c2:
            n_proc = st.slider("Procedures (operations, scans…)", 0, 6, 1)
        with c3:
            n_diag = st.slider("Health problems written in the file", 1, 16, 7)
        c1, c2, c3 = st.columns(3)
        families = list(DIAG_CODES)
        with c1:
            d1 = st.selectbox("Main reason for the stay", families)
        with c2:
            d2 = st.selectbox("Second health problem", families, index=3)
        with c3:
            d3 = st.selectbox("Third health problem", families, index=8)
        st.markdown("##### 📅 The past year")
        c1, c2, c3 = st.columns(3)
        with c1:
            n_inp = st.number_input("Hospital stays", 0, 21, 0)
        with c2:
            n_er = st.number_input("Emergency visits", 0, 76, 0)
        with c3:
            n_out = st.number_input("Clinic visits", 0, 42, 0)
        st.markdown("##### 💉 Diabetes")
        c1, c2, c3 = st.columns(3)
        with c1:
            a1c = st.selectbox("Long-term sugar test (HbA1c)", ["Not measured", "Normal", "Above 7", "Above 8"])
            glu = st.selectbox("Sugar level test", ["Not measured", "Normal", "Above 200", "Above 300"])
        with c2:
            insulin = st.selectbox("Insulin", list(DOSE), format_func=DOSE.get)
            metformin = st.selectbox("Metformin", list(DOSE), format_func=DOSE.get)
        with c3:
            changed = st.selectbox("Diabetes medicines changed during the stay?", ["No", "Yes"])
            on_meds = st.selectbox("Takes diabetes medicines?", ["Yes", "No"])
        go_check = st.form_submit_button("🔍  Check this patient", type="primary", use_container_width=True)

    if not go_check:
        return
    row = {c: "No" for c in P.MED_COLS}
    row.update({
        "race": {"Prefer not to say": np.nan, "African American": "AfricanAmerican"}.get(race, race),
        "gender": sex, "age": f"[{AGE_RANGES[age]})", "admission_type_id": adm_type,
        "discharge_disposition_id": disch, "admission_source_id": adm_src, "time_in_hospital": days_in,
        "payer_code": np.nan, "medical_specialty": SPECIALTY[p_svc], "num_lab_procedures": n_lab,
        "num_procedures": n_proc, "num_medications": n_meds, "number_outpatient": n_out,
        "number_emergency": n_er, "number_inpatient": n_inp, "diag_1": DIAG_CODES[d1],
        "diag_2": DIAG_CODES[d2], "diag_3": DIAG_CODES[d3], "number_diagnoses": n_diag,
        "max_glu_serum": {"Not measured": np.nan, "Normal": "Norm", "Above 200": ">200", "Above 300": ">300"}[glu],
        "A1Cresult": {"Not measured": np.nan, "Normal": "Norm", "Above 7": ">7", "Above 8": ">8"}[a1c],
        "insulin": insulin, "metformin": metformin, "change": "Ch" if changed == "Yes" else "No",
        "diabetesMed": "Yes" if (on_meds == "Yes" or insulin != "No" or metformin != "No") else "No",
    })
    s = P.score_stays(pd.DataFrame([row])).iloc[0]
    stays = P.load_stays()
    card = pd.Series({**s.to_dict(), "risk_rank": float((stays["risk"] <= s["risk"]).mean()),
                      "stay_text": P.stay_range(s["stay_low"], s["stay_high"]),
                      "stay_likely": max(1, round(s["stay_likely"])),
                      "number_inpatient": n_inp, "number_emergency": n_er, "number_outpatient": n_out,
                      "num_medications": n_meds, "time_in_hospital": days_in,
                      "admission_type_id": adm_type, "discharge_disposition_id": disch})
    e = P.explain(card)
    color, dot, icon, word = LEVEL[s["level"]]
    thr_med, thr_high = P.RISK_THRESHOLDS["Medium"] * 100, P.RISK_THRESHOLDS["High"] * 100
    g_max = max(50, int(np.ceil(s["risk"] * 10)) * 10 + 10)

    k1, k2 = st.columns([1, 1.4])
    with k1:
        gfig = go.Figure(go.Indicator(
            mode="gauge+number", value=round(s["risk"] * 100),
            number={"suffix": "%", "font": {"size": 40, "color": color}},
            title={"text": "Risk of coming back within 30 days", "font": {"size": 14, "color": MUTED}},
            gauge={"axis": {"range": [0, g_max], "tickcolor": "#94A3B8", "ticksuffix": "%"},
                   "bar": {"color": color, "thickness": 0.3}, "bgcolor": "#F1F5F9", "borderwidth": 0,
                   "steps": [{"range": [0, thr_med], "color": "rgba(16,185,129,0.15)"},
                             {"range": [thr_med, thr_high], "color": "rgba(245,158,11,0.18)"},
                             {"range": [thr_high, g_max], "color": "rgba(239,68,68,0.15)"}]}))
        style_fig(gfig, 260)
        gfig.update_layout(margin=dict(l=40, r=40, t=50, b=10))
        st.plotly_chart(gfig, use_container_width=True, config={"displayModeBar": False})
        html(f"""<div style="text-align:center; margin-top:-.5rem;">
                 <span class="bs-pill" style="background:{rgba(color, .1)}; color:{color}; font-size:.95rem;">{icon} {word}</span>
                 <div style="color:var(--text-secondary); font-size:.78rem; margin-top:.4rem;">
                 🟢 under {thr_med:.0f}% · 🟠 {thr_med:.0f} to {thr_high:.0f}% · 🔴 over {thr_high:.0f}%</div></div>""")
    with k2:
        facts = "".join(f"<li>{f}</li>" for f in e["facts"])
        html(f"""<div class="bs-card" style="--lvl:{color};">
            <h4>{icon} {e['headline']}</h4>
            <p>{e['sentence']}</p>
            <p>🛏️ {e['stay']}</p>
            <p>📊 Counting the chance that they come back, plan about
               <strong>{s['bed_days']:.1f} bed-days</strong> for this patient
               <span title="1 bed-day = 1 bed for 1 day" style="cursor:help; color:var(--text-secondary);">(?)</span>.</p>
            <div style="margin-top:.5rem; font-weight:700; font-size:.88rem; color:var(--text-primary);">What the file shows</div>
            <ul>{facts}</ul>
            <div class="bs-todo">💡 <strong>What to do:</strong> {e['advice']}.</div>
        </div>""")
    chart_title(f"If they come back: about {plural(card['stay_likely'], 'day')}, "
                f"between {card['stay_text'].replace(' to ', ' and ')}")
    sfig = go.Figure()
    sfig.add_trace(go.Scatter(
        x=[s["stay_low"], s["stay_high"]], y=[0, 0], mode="lines", line=dict(color=rgba(color, .35), width=16),
        hoverinfo="skip", showlegend=False))
    sfig.add_trace(go.Scatter(
        x=[s["stay_likely"]], y=[0], mode="markers+text", marker=dict(size=22, color=color, symbol="diamond"),
        text=[f"about {plural(card['stay_likely'], 'day')}"], textposition="top center",
        hovertemplate="Most likely: %{x:.0f} days<extra></extra>", showlegend=False))
    style_fig(sfig, 150)
    sfig.update_xaxes(range=[0, 15], dtick=1, title_text="Days in hospital if they come back", fixedrange=True)
    sfig.update_yaxes(visible=False, range=[-1, 1.5], fixedrange=True)
    st.plotly_chart(sfig, use_container_width=True, config={"displayModeBar": False})
    msg = f"{e['headline']}. {e['sentence']} {e['stay']} {e['advice']}."
    chat_message("bedsense", msg)
    tts_button(msg, AVATARS["bedsense"]["color"])
    render_disclaimer()


tabs = st.tabs(["🛏️ Bed Planning", "👥 Patients to Follow Up", "🔍 Check a Patient"])
for tab, render, name in [(tabs[0], tab_planning, "The bed plan"),
                          (tabs[1], tab_people, "The patients list"),
                          (tabs[2], tab_check, "The patient check")]:
    with tab:
        try:
            render()
        except Exception:
            logging.exception("BedSense: %s failed", name)
            friendly_error(name)
