// TEMPLATE — copy this folder to lib/features/<your_id>/ and rename.
//
// It shows the whole integration in ~60 lines:
//   * call your backend module through the shared ApiClient
//   * show the result
//   * hand the `narrative` to the shared avatar stage (voice + subtitles)
//
// Then register it in lib/features/modules/module_registry.dart:
//   entry: (_) => const TemplateScreen(),  status: ModuleStatus.live,
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/cards.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';

class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  Map<String, dynamic>? _result;
  String? _error;
  bool _loading = false;

  Future<void> _predict() async {
    setState(() => _loading = true);
    try {
      final res = await context
          .read<ApiClient>()
          .postJson('/api/v1/mymodel/predict', {'age_ordinal': 7, 'num_medications': 18});
      setState(() => _result = res);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrative = (_result?['narrative'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(SpeechSegment.fromJson)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('MyModel')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GradientButton(label: 'Predict', loading: _loading, onTap: _predict),
            const SizedBox(height: 20),
            if (_error != null) Text(_error!),
            if (_result != null) Text('Probability: ${_result!['probability']}'),
            if (narrative.isNotEmpty)
              TextButton(
                // Replace AvatarProfile.teemo with your own AvatarProfile.
                onPressed: () => AvatarStageScreen.open(context,
                    avatar: AvatarProfile.teemo, segments: narrative),
                child: const Text('Let the avatar explain'),
              ),
          ],
        ),
      ),
    );
  }
}
