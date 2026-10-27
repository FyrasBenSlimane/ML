import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cards.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';
import '../../teemo/data/teemo_models.dart';
import '../../teemo/widgets/form_fields.dart';
import '../data/bedsense_api.dart';
import '../data/bedsense_models.dart';
import '../widgets/bed_load_chart.dart';
import '../widgets/bs_common.dart';

/// "Bed planning": beds needed vs beds available over the coming days.
class BedPlanningView extends StatefulWidget {
  const BedPlanningView({super.key, required this.meta, required this.api});

  final BsMeta meta;
  final BedSenseApi api;

  @override
  State<BedPlanningView> createState() => _BedPlanningViewState();
}

class _BedPlanningViewState extends State<BedPlanningView> with AutomaticKeepAliveClientMixin {
  String? _service;
  int _horizon = 14;
  BsPlan? _plan;
  String? _error;
  bool _loading = true;
  int? _day;
  int _request = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await widget.api.plan(service: _service, horizon: _horizon);
      if (!mounted || id != _request) return;
      final firstOver = plan.days.indexWhere((d) => d.status == 'over');
      setState(() {
        _plan = plan;
        _day = firstOver >= 0 ? firstOver : 0;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _request) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final plan = _plan;
    return RefreshIndicator(
      color: bsGreen,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 36 + MediaQuery.paddingOf(context).bottom),
        children: [
          FieldCard(
            icon: Icons.apartment_rounded,
            color: bsGreen,
            title: 'Which service?',
            subtitle: 'A service gets its share of the hospital beds',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServicePicker(
                  services: widget.meta.services,
                  value: _service,
                  onChanged: (s) {
                    setState(() => _service = s);
                    _load();
                  },
                ),
                const SizedBox(height: 14),
                SegmentedChoice(
                  color: bsGreen,
                  options: const [
                    FieldOption(7, 'Next 7 days'),
                    FieldOption(14, 'Next 2 weeks'),
                    FieldOption(28, 'Next 4 weeks'),
                  ],
                  value: _horizon,
                  onChanged: (v) {
                    setState(() => _horizon = v as int);
                    _load();
                  },
                ),
              ],
            ),
          ),
          if (_loading && plan == null)
            const BsLoading('Building the bed plan…')
          else if (_error != null && plan == null)
            BsErrorCard(message: _error!, onRetry: _load)
          else if (plan != null)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _loading ? 0.45 : 1,
              child: _content(plan),
            ),
        ],
      ),
    );
  }

  Widget _content(BsPlan plan) {
    final cap = plan.capacity;
    final need = plan.bedsNeededToday;
    final free = plan.freeBedsToday;
    final todayStatus = plan.days.isEmpty ? 'ok' : plan.days.first.status;
    final day = (_day != null && _day! < plan.days.length) ? plan.days[_day!] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[BsErrorCard(message: _error!, onRetry: _load), const SizedBox(height: 12)],
        _outlook(plan),
        const SizedBox(height: 14),
        KpiGrid(tiles: [
          KpiTile(
            icon: Icons.bed_rounded,
            value: '$need',
            label: 'Beds needed today',
            hint: cap > 0 ? '${(100 * need / cap).round()}% of $cap beds' : '',
            color: need > cap ? AppColors.red : statusColor(todayStatus),
          ),
          KpiTile(
            icon: free > 0 ? Icons.check_circle_rounded : Icons.block_rounded,
            value: '${free < 0 ? -free : free}',
            label: free < 0 ? 'Beds missing today' : 'Free beds today',
            hint: free < 0 ? 'more patients than beds' : 'ready for new patients',
            color: free > 0.1 * cap ? AppColors.green : (free > 0 ? AppColors.amber : AppColors.red),
          ),
          KpiTile(
            icon: Icons.priority_high_rounded,
            value: '${plan.highRiskPatients}',
            label: 'High-risk patients',
            hint: 'likely to come back, follow up closely',
            color: plan.highRiskPatients > 0 ? AppColors.red : AppColors.green,
          ),
          KpiTile(
            icon: Icons.event_busy_rounded,
            value: '${plan.criticalDays}',
            label: 'Days with beds missing',
            hint: '+ ${plural(plan.tightDays, 'tight day')} · next ${plural(plan.horizon, 'day')}',
            color: plan.criticalDays > 0
                ? AppColors.red
                : (plan.tightDays > 0 ? AppColors.amber : AppColors.green),
          ),
        ]),
        const SectionHeader('Beds needed each day', icon: Icons.bar_chart_rounded),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BedLoadChart(
                days: plan.days,
                selected: _day,
                onSelect: (i) => setState(() => _day = i),
              ),
              const SizedBox(height: 12),
              BsNote('Each bar is the beds needed that day: patients already here, new admissions and '
                  'patients expected to come back. The grey cap is a safe plan '
                  '(${plan.safeBandText.isEmpty ? 'it covers 9 cases out of 10' : plan.safeBandText.toLowerCase()}). '
                  'The dashed line is the beds available. Tap a day to see the details.'),
            ],
          ),
        ),
        if (day != null) ...[const SizedBox(height: 12), _dayCard(day)],
        if (plan.alerts.isNotEmpty) ...[
          SectionHeader('Days that need attention (${plan.alerts.length})', icon: Icons.notifications_active_rounded),
          for (final a in plan.alerts) _alertCard(a),
          const BsNote('These are suggestions to discuss with the team, not orders.'),
        ],
        if (plan.weeks.isNotEmpty) ...[
          const SectionHeader('Week by week', icon: Icons.date_range_rounded),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (var i = 0; i < plan.weeks.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _weekRow(plan.weeks[i]),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (plan.narrative.isNotEmpty)
          GradientButton(
            label: 'Hear the bed plan',
            icon: Icons.volume_up_rounded,
            gradient: bsGradient,
            onTap: () => AvatarStageScreen.open(context,
                avatar: AvatarProfile.bedsense, segments: plan.narrative, title: 'BedSense · bed plan'),
          ),
        const SizedBox(height: 12),
        BsNote(
          [widget.meta.placeholderNote, plan.disclaimer].where((s) => s.isNotEmpty).join('\n'),
          center: true,
        ),
      ].animate(interval: 50.ms).fadeIn(duration: 320.ms).slideY(begin: 0.05),
    );
  }

  Widget _outlook(BsPlan plan) {
    final over = plan.alerts.where((a) => a.severity == 'over').toList();
    final (Color color, IconData icon, String title, String text) = over.isNotEmpty
        ? (
            AppColors.red,
            Icons.block_rounded,
            over.first.title,
            '${over.first.action}${plan.alerts.length > 1 ? ' ${plural(plan.alerts.length - 1, 'other day')} also need attention.' : ''}',
          )
        : plan.alerts.isNotEmpty
            ? (
                AppColors.amber,
                Icons.warning_amber_rounded,
                'Beds will be tight on ${plural(plan.alerts.length, 'day')}',
                'Beds should be enough, but with little room to spare. ${plan.alerts.first.action}',
              )
            : (
                AppColors.green,
                Icons.check_circle_rounded,
                'Enough beds every day for the next ${plural(plan.horizon, 'day')}',
                'No action needed. The plan updates every day.',
              );
    return SoftCard(
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.35)),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15.5)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: AppColors.ink, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(BsDay d) {
    final color = statusColor(d.status);
    final gap = (d.capacity - d.needed).round();
    final word = switch (d.status) {
      'over' => 'Beds missing',
      'tight' => 'Tight',
      _ => 'Enough beds',
    };
    Widget cell(String value, String label, [Color? c]) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(color: c ?? AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5, height: 1.3)),
          ],
        );
    final cells = [
      cell('${d.needed.round()} / ${d.capacity.round()}', 'beds needed / beds available'),
      cell('${gap.abs()}', gap < 0 ? 'beds missing' : 'beds free', color),
      cell('${d.current.round()}', 'patients already in hospital'),
      cell('${d.newPatients.round()}', 'new admissions in a bed'),
      cell('${d.returns.round()}', 'beds for patients coming back'),
      cell('${d.nursesNeeded} / ${d.nursesOnDuty}', 'nurses needed / on duty per shift (estimate)'),
    ];
    return SoftCard(
      border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_rounded, color: AppColors.inkSoft, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(shortDay(d.date),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
              ),
              Pill(word.toUpperCase(), color: color),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < cells.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cells[i]),
                  const SizedBox(width: 12),
                  Expanded(child: i + 1 < cells.length ? cells[i + 1] : const SizedBox()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _alertCard(BsAlert a) {
    final color = statusColor(a.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(a.severity == 'over' ? Icons.block_rounded : Icons.warning_amber_rounded,
                color: color, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(a.action, style: const TextStyle(color: AppColors.inkSoft, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekRow(BsWeek w) {
    final color = w.margin < 0
        ? AppColors.red
        : (w.margin < 0.1 * w.capacity ? AppColors.amber : AppColors.green);
    final dates = (w.start != null && w.end != null) ? '${dayMonth(w.start!)} – ${dayMonth(w.end!)}' : '';
    final fill = w.capacity > 0 ? (w.peakBeds / w.capacity).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: w.label,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                  TextSpan(text: '  $dates', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ])),
              ),
              Pill(w.margin < 0 ? '${-w.margin} MISSING' : '${w.margin} SPARE', color: color),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.line,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Busiest day: ${w.peakBeds} of ${w.capacity} beds'
            '${w.criticalDays > 0 ? ' · ${plural(w.criticalDays, 'day')} with beds missing' : ''}'
            '${w.tightDays > 0 ? ' · ${plural(w.tightDays, 'tight day')}' : ''}',
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
