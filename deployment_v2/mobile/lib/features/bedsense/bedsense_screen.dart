import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/doctor_banner.dart';
import '../avatar/avatar_profile.dart';
import '../teemo/data/teemo_models.dart';
import '../teemo/widgets/form_fields.dart';
import 'data/bedsense_api.dart';
import 'data/bedsense_models.dart';
import 'screens/bed_planning_view.dart';
import 'screens/check_patient_view.dart';
import 'screens/followup_view.dart';
import 'widgets/bs_common.dart';

/// BedSense (Najd): bed planning, patients to follow up and a single-patient
/// check (30-day return risk + length of the return stay). Doctor only; the
/// registry wraps it in PatientGate so a patient is confirmed first.
class BedSenseScreen extends StatefulWidget {
  const BedSenseScreen({super.key});

  @override
  State<BedSenseScreen> createState() => _BedSenseScreenState();
}

enum _Section { planning, followup, check }

class _BedSenseScreenState extends State<BedSenseScreen> {
  late final BedSenseApi _api = BedSenseApi(context.read<ApiClient>());
  final _pages = PageController();
  _Section _section = _Section.planning;
  BsMeta? _meta;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meta = await _api.meta();
      if (!mounted) return;
      setState(() {
        _meta = meta;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _go(_Section s) {
    setState(() => _section = s);
    if (_pages.hasClients) {
      _pages.animateToPage(s.index, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlobBackground(
        colors: const [bsGreen, AppColors.teal, AppColors.sky, AppColors.green],
        opacity: 0.18,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: _loading
                    ? const Center(child: BsLoading('Loading BedSense…'))
                    : _meta == null
                        ? _loadError()
                        : _body(_meta!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 16, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            Hero(
              tag: AvatarProfile.bedsense.heroTag,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: bsGradient,
                  boxShadow: AppColors.glow(bsGreen, strength: 0.25),
                ),
                padding: const EdgeInsets.all(2.5),
                child: ClipOval(
                  child: Image.asset(
                    AvatarProfile.bedsense.faceAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Colors.white,
                      child: Icon(Icons.bed_rounded, color: bsGreen),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BedSense',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  Text('Beds, follow-up and length of stay',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _loadError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SoftCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, color: AppColors.coral, size: 36),
                const SizedBox(height: 12),
                Text(_error ?? 'BedSense could not be loaded.', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _loadMeta,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _body(BsMeta meta) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Column(
              children: [
                const DoctorBanner(),
                const SizedBox(height: 12),
                SegmentedChoice(
                  color: bsGreen,
                  height: 48,
                  options: const [
                    FieldOption(_Section.planning, 'Bed planning'),
                    FieldOption(_Section.followup, 'Follow-up'),
                    FieldOption(_Section.check, 'Check a patient'),
                  ],
                  // Icons only when there is room for them next to the labels.
                  icons: MediaQuery.sizeOf(context).width >= 440
                      ? const [Icons.bed_rounded, Icons.groups_rounded, Icons.person_search_rounded]
                      : null,
                  value: _section,
                  onChanged: (v) => _go(v as _Section),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _section = _Section.values[i]),
              children: [
                BedPlanningView(meta: meta, api: _api),
                FollowupView(meta: meta, api: _api),
                CheckPatientView(meta: meta, api: _api),
              ],
            ),
          ),
        ],
      );
}
