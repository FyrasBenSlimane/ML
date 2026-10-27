import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cards.dart';
import '../../teemo/widgets/form_fields.dart';
import '../data/bedsense_api.dart';
import '../data/bedsense_models.dart';
import '../widgets/bs_common.dart';

/// "Follow-up": patients in hospital now or sent home in the last 30 days,
/// highest chance of coming back first.
class FollowupView extends StatefulWidget {
  const FollowupView({super.key, required this.meta, required this.api});

  final BsMeta meta;
  final BedSenseApi api;

  @override
  State<FollowupView> createState() => _FollowupViewState();
}

class _FollowupViewState extends State<FollowupView> with AutomaticKeepAliveClientMixin {
  static const _pageSize = 20;

  String? _service;
  int _top = _pageSize;
  BsFollowup? _data;
  String? _error;
  bool _loading = true;
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
      final data = await widget.api.followup(service: _service, top: _top);
      if (!mounted || id != _request) return;
      setState(() {
        _data = data;
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
    final data = _data;
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
            subtitle: 'Patients in hospital now or sent home in the last 30 days',
            child: ServicePicker(
              services: widget.meta.services,
              value: _service,
              onChanged: (s) {
                setState(() {
                  _service = s;
                  _top = _pageSize;
                });
                _load();
              },
            ),
          ),
          if (_loading && data == null)
            const BsLoading('Finding the patients to follow up…')
          else if (_error != null && data == null)
            BsErrorCard(message: _error!, onRetry: _load)
          else if (data != null)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _loading ? 0.45 : 1,
              child: _content(data),
            ),
        ],
      ),
    );
  }

  Widget _content(BsFollowup data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[BsErrorCard(message: _error!, onRetry: _load), const SizedBox(height: 12)],
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (level, label, hint)) in const [
                ('high', 'High risk', 'visit within 7 days'),
                ('medium', 'Medium risk', 'visit within 2 weeks'),
                ('low', 'Low risk', 'usual check-up'),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _CountTile(
                    count: data.countFor(level),
                    label: label,
                    hint: hint,
                    color: levelColor(level),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        BsNote('${plural(data.total, 'patient')} could come back to hospital. '
            'The list shows the ${plural(data.shown, 'patient')} most likely to come back first. '
            'Tap a patient to see why.'),
        const SectionHeader('Patients to follow up', icon: Icons.groups_rounded),
        if (data.patients.isEmpty)
          const SoftCard(
            child: Text('Nobody to follow up in this service right now.',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
        for (final p in data.patients) _PatientCard(patient: p),
        if (data.shown < data.total) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() => _top = (_top + _pageSize).clamp(_pageSize, 200));
                      _load();
                    },
              icon: const Icon(Icons.expand_more_rounded, color: bsGreenDeep),
              label: const Text('Show more patients',
                  style: TextStyle(color: bsGreenDeep, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        BsNote(data.disclaimer, center: true),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.count, required this.label, required this.hint, required this.color});

  final int count;
  final String label;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.all(12),
        radius: 22,
        border: Border.all(color: color.withValues(alpha: 0.25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count',
                style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 13)),
            Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.3)),
          ],
        ),
      );
}

class _PatientCard extends StatefulWidget {
  const _PatientCard({required this.patient});

  final BsPatient patient;

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final color = levelColor(p.level);
    final athome = p.where.toLowerCase().contains('home');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        radius: 22,
        onTap: () => setState(() => _open = !_open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('${p.percent}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient ${p.pid}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(
                        [p.ageBand, p.gender, p.service, p.mainReason].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.expand_more_rounded, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Pill('${p.level.toUpperCase()} RISK', color: color),
                Pill(p.when.toUpperCase(),
                    color: athome ? AppColors.blue : AppColors.violet,
                    icon: athome ? Icons.home_rounded : Icons.local_hospital_rounded),
                Pill('STAY ~${plural(p.stayLikely, 'DAY')}', color: bsGreenDeep, icon: Icons.hotel_rounded),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(p.advice,
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.35)),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 22),
                        Text(p.sentence, style: const TextStyle(color: AppColors.ink, height: 1.45)),
                        const SizedBox(height: 6),
                        Text(p.staySentence, style: const TextStyle(color: AppColors.ink, height: 1.45)),
                        const SizedBox(height: 10),
                        for (final f in p.facts)
                          BsBullet(f.isEmpty ? f : f[0].toUpperCase() + f.substring(1), color: color),
                        if (p.arrival.isNotEmpty) BsBullet('Came in: ${p.arrival}', color: color),
                        if (p.leavingTo.isNotEmpty) BsBullet('Going to: ${p.leavingTo}', color: color),
                        BsBullet('About ${p.bedDays.toStringAsFixed(1)} bed days to plan if they come back',
                            color: color),
                      ].animate(interval: 30.ms).fadeIn(duration: 220.ms),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
