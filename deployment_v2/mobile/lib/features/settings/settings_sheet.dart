import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/server_status_cubit.dart';
import '../../core/settings/settings_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/cards.dart';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SettingsSheet(),
    );

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final _url = TextEditingController(text: context.read<SettingsCubit>().state.serverUrl);
  late final _name = TextEditingController(text: context.read<SettingsCubit>().state.userName);

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    context.read<SettingsCubit>().setServerUrl(_url.text);
    await context.read<ServerStatusCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final status = context.watch<ServerStatusCubit>().state;
    final (statusText, statusColor) = switch (status.health) {
      ServerHealth.online => ('Connected · modules: ${status.modules.join(', ')}', AppColors.green),
      ServerHealth.offline => (status.message ?? 'Offline', AppColors.coral),
      ServerHealth.checking => ('Checking…', AppColors.amber),
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            const _Label('Your name'),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: context.read<SettingsCubit>().setUserName,
              decoration: const InputDecoration(
                  hintText: 'Shown in the greeting', prefixIcon: Icon(Icons.person_rounded)),
            ),
            const SizedBox(height: 18),
            const _Label('Server address'),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _testConnection(),
              decoration: const InputDecoration(
                  hintText: 'http://192.168.1.20:8000', prefixIcon: Icon(Icons.dns_rounded)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Emulator: http://10.0.2.2:8000 · Phone on Wi-Fi: http://<PC IP>:8000 · Browser: http://localhost:8000',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
                FilledButton.tonalIcon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: const Text('Save & test'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _Label("Teemo's voice"),
            SegmentedButton<VoiceEngine>(
              segments: const [
                ButtonSegment(
                    value: VoiceEngine.neural,
                    icon: Icon(Icons.auto_awesome_rounded),
                    label: Text('Neural (server)')),
                ButtonSegment(
                    value: VoiceEngine.device,
                    icon: Icon(Icons.phone_android_rounded),
                    label: Text('Device (offline)')),
              ],
              selected: {settings.voiceEngine},
              onSelectionChanged: (s) => context.read<SettingsCubit>().setVoiceEngine(s.first),
            ),
            const SizedBox(height: 6),
            const Text(
              'Neural uses a natural female voice from the server (needs internet there). '
              'If it is unavailable Teemo switches to the device voice automatically.',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: settings.subtitles,
              onChanged: context.read<SettingsCubit>().setSubtitles,
              title: const Text('Subtitles', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Word-by-word captions while Teemo speaks'),
            ),
            const SizedBox(height: 10),
            GradientButton(label: 'Done', icon: Icons.check_rounded, onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
      );
}
