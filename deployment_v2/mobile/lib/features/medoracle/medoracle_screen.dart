import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../core/patient/active_patient_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/doctor_banner.dart';

const _profileOptions = <String, List<String>>{
  'race': [
    'Caucasian',
    'AfricanAmerican',
    'Asian',
    'Hispanic',
    'Other',
    'Unknown',
  ],
  'gender': ['Female', 'Male'],
  'age_band': ['<40', '40-59', '60-79', '80+'],
};

const _labels = <String, String>{
  'number_diagnoses': 'Diagnoses',
  'number_inpatient': 'Prior inpatient stays',
  'number_emergency': 'ER visits',
  'number_outpatient': 'Outpatient visits',
  'admission_type_id': 'Admission type',
  'admission_source_id': 'Admission source',
  'diag_1_group': 'Primary diagnosis',
  'diag_2_group': 'Secondary diagnosis',
  'diag_3_group': 'Tertiary diagnosis',
  'A1Cresult': 'HbA1c result',
  'max_glu_serum': 'Max glucose',
  'race': 'Demographic group',
  'gender': 'Gender',
  'age_band': 'Age band',
};

const _profileLabels = <String, Map<String, String>>{
  'race': {
    'Caucasian': 'Caucasian',
    'AfricanAmerican': 'African American',
    'Asian': 'Asian',
    'Hispanic': 'Hispanic',
    'Other': 'Other',
    'Unknown': 'Unknown',
  },
  'gender': {'Female': 'Female', 'Male': 'Male'},
  'age_band': {
    '<40': 'Under 40',
    '40-59': '40–59',
    '60-79': '60–79',
    '80+': '80+',
  },
};

class MedOracleScreen extends StatefulWidget {
  const MedOracleScreen({super.key});

  @override
  State<MedOracleScreen> createState() => _MedOracleScreenState();
}

class _MedOracleScreenState extends State<MedOracleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberControllers = <String, TextEditingController>{};
  Map<String, dynamic>? _meta;
  Map<String, dynamic> _severity = {};
  final _profiles = <String, Map<String, String>>{
    'patient_a': {'race': 'Caucasian', 'gender': 'Female', 'age_band': '60-79'},
    'patient_b': {
      'race': 'AfricanAmerican',
      'gender': 'Female',
      'age_band': '60-79',
    },
  };
  Map<String, dynamic>? _result;
  String? _error;
  bool _loadingMeta = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    for (final controller in _numberControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final response = await context.read<ApiClient>().getJson(
        '/api/v1/medoracle/meta',
      );
      final fields = Map<String, dynamic>.from(response['fields'] as Map);
      final initialSeverity = <String, dynamic>{};
      for (final entry in fields.entries) {
        final field = Map<String, dynamic>.from(entry.value as Map);
        initialSeverity[entry.key] = field['default'];
        if (field['type'] == 'number') {
          _numberControllers[entry.key] = TextEditingController(
            text: '${field['default']}',
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _meta = response;
        _severity = initialSeverity;
        _loadingMeta = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loadingMeta = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final patient = context.read<ActivePatientCubit>().state;
    if (patient == null) {
      setState(() => _error = 'Confirm the patient to analyze first.');
      return;
    }

    final severity = Map<String, dynamic>.from(_severity);
    for (final entry in _numberControllers.entries) {
      severity[entry.key] = int.parse(entry.value.text);
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await context.read<ApiClient>().postJson(
        '/api/v1/medoracle/predict',
        {
          'severity': severity,
          'patient_a': _profiles['patient_a'],
          'patient_b': _profiles['patient_b'],
        },
        headers: {'X-Patient-Code': patient.code},
      );
      if (!mounted) return;
      setState(() {
        _result = response;
        _submitting = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlobBackground(
        colors: const [
          AppColors.violet,
          AppColors.indigo,
          AppColors.sky,
          AppColors.pink,
        ],
        child: SafeArea(
          child: _loadingMeta
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.violet),
                )
              : _meta == null
              ? _loadError()
              : _content(),
        ),
      ),
    );
  }

  Widget _loadError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SoftCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.coral,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'The MedOracle model could not be loaded.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _loadingMeta = true;
                  _error = null;
                });
                _loadMeta();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content() {
    final patient = context.watch<ActivePatientCubit>().state;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Row(
            children: [
              const IconBadge(
                Icons.analytics_rounded,
                color: AppColors.violet,
                size: 54,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MedOracle',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Text(
                      'Care equity comparison analysis',
                      style: TextStyle(color: AppColors.inkSoft, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const DoctorBanner(),
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    patient == null
                        ? 'No patient confirmed'
                        : 'Assessment linked to file ${patient.code}'
                              '${patient.fullName.isEmpty ? '' : ' · ${patient.fullName}'}',
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const SectionHeader(
            'Shared clinical context',
            icon: Icons.local_hospital_rounded,
          ),
          SoftCard(
            child: Column(
              children: [
                for (final entry in _severity.entries)
                  _severityField(entry.key, entry.value),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The clinical variables are kept identical for both profiles. '
            'Only the selected demographic attributes vary.',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          _profileCard('patient_a', 'Reference profile', AppColors.teal),
          const SizedBox(height: 12),
          _profileCard('patient_b', 'Profile to compare', AppColors.violet),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _errorCard(_error!),
          ],
          const SizedBox(height: 18),
          GradientButton(
            label: _submitting ? 'Analyzing…' : 'Compare the profiles',
            icon: Icons.compare_arrows_rounded,
            gradient: AppColors.violetGradient,
            loading: _submitting,
            onTap: _submitting || patient == null ? null : _submit,
          ),
          const SizedBox(height: 12),
          const Text(
            'Retrospective group comparison based on US hospital data from 1999 to 2008. '
            'This result is neither an individual prediction nor a clinical recommendation; '
            'an association does not prove causation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
          if (_result != null) ...[const SizedBox(height: 24), _results()],
        ],
      ),
    );
  }

  Widget _severityField(String key, dynamic value) {
    final field = Map<String, dynamic>.from(
      (_meta!['fields'] as Map<String, dynamic>)[key] as Map,
    );
    final label = _labels[key] ?? key;
    if (field['type'] == 'number') {
      final limit = key == 'number_diagnoses'
          ? 16
          : (key == 'number_inpatient' ? 20 : 40);
      final min = key == 'number_diagnoses' ? 1 : 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _numberControllers[key],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          validator: (text) {
            final parsed = int.tryParse(text ?? '');
            if (parsed == null || parsed < min || parsed > limit) {
              return 'Enter a value from $min to $limit.';
            }
            return null;
          },
        ),
      );
    }
    final options = (field['options'] as List<dynamic>).toList();
    if (!options.contains(value)) options.insert(0, value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<dynamic>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem<dynamic>(
                value: option,
                child: Text(
                  _optionLabel(key, option),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) setState(() => _severity[key] = next);
        },
      ),
    );
  }

  Widget _profileCard(String key, String title, Color color) {
    final profile = _profiles[key]!;
    return SoftCard(
      border: Border.all(color: color.withValues(alpha: 0.18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(Icons.person_outline_rounded, color: color, size: 40),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final field in _profileOptions.keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                initialValue: profile[field],
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _labels[field],
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: _profileOptions[field]!
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_optionLabel(field, option)),
                      ),
                    )
                    .toList(),
                onChanged: (next) {
                  if (next != null) setState(() => profile[field] = next);
                },
              ),
            ),
        ],
      ),
    );
  }

  String _optionLabel(String field, dynamic value) {
    final profileLabel = _profileLabels[field]?[value.toString()];
    if (profileLabel != null) return profileLabel;
    if (field == 'A1Cresult') {
      return switch (value) {
        'Not_Tested' => 'Not measured',
        'Norm' => 'Normal',
        '>7' => 'Above 7%',
        '>8' => 'Above 8%',
        _ => '$value',
      };
    }
    if (field == 'max_glu_serum') {
      return switch (value) {
        'Not_Tested' => 'Not measured',
        'Norm' => 'Normal',
        '>200' => 'Above 200',
        '>300' => 'Above 300',
        _ => '$value',
      };
    }
    if (field == 'diag_1_group' ||
        field == 'diag_2_group' ||
        field == 'diag_3_group') {
      return switch (value) {
        'Circulatory' => 'Circulatory',
        'Respiratory' => 'Respiratory',
        'Digestive' => 'Digestive',
        'Diabetes' => 'Diabetes',
        'Injury' => 'Injury',
        'Musculoskeletal' => 'Musculoskeletal',
        'Genitourinary' => 'Genitourinary',
        'Neoplasms' => 'Neoplasms',
        'External' => 'External causes',
        _ => 'Other',
      };
    }
    if (field == 'admission_type_id') return 'Type $value';
    if (field == 'admission_source_id') return 'Source $value';
    return '$value';
  }

  Widget _errorCard(String message) => SoftCard(
    color: const Color(0xFFFFF1F2),
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.ink)),
        ),
      ],
    ),
  );

  Widget _results() {
    final comparisons = Map<String, dynamic>.from(
      _result!['comparisons'] as Map,
    );
    final model = Map<String, dynamic>.from(_result!['model'] as Map);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DoctorBanner(),
        const SectionHeader(
          'Comparative results',
          icon: Icons.insights_rounded,
        ),
        for (final entry in comparisons.entries) ...[
          _comparisonCard(Map<String, dynamic>.from(entry.value as Map)),
          const SizedBox(height: 12),
        ],
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About the model',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${model['method']}\n${_result!['disclaimer']}',
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonCard(Map<String, dynamic> comparison) {
    final parts = (comparison['parts'] as List<dynamic>)
        .map((part) => Map<String, dynamic>.from(part as Map))
        .toList();
    final difference = (comparison['difference'] as num).toDouble();
    final isNeutral = difference.abs() < 0.005;
    final color = isNeutral
        ? AppColors.teal
        : (difference > 0 ? AppColors.violet : AppColors.blue);
    final rangeLow = comparison['expected_range_low'];
    final rangeHigh = comparison['expected_range_high'];
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comparison['label'] as String,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Pill(
                comparison['detectable'] == true
                    ? 'DETECTABLE GAP'
                    : 'INCONCLUSIVE',
                color: comparison['detectable'] == true
                    ? AppColors.violet
                    : AppColors.teal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${difference > 0 ? '+' : ''}${difference.toStringAsFixed(2)} '
            '${comparison['unit']}',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Adjusted difference (profile B − profile A); 95% CI: '
            '${comparison['ci_low']} to ${comparison['ci_high']} ${comparison['unit']}.',
            style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            'Estimated average context: ${comparison['expected']} ${comparison['unit']} '
            '(indicative range: $rangeLow–$rangeHigh).',
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (parts.isNotEmpty) ...[
            const Divider(height: 24),
            for (final part in parts)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _labels[part['variable']] ?? '${part['variable']}',
                      ),
                    ),
                    Text(
                      '${(part['difference'] as num) > 0 ? '+' : ''}${part['difference']}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
