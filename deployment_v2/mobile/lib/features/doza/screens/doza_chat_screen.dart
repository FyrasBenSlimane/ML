import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/patient/active_patient_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/pressable.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/widgets/avatar_face.dart';
import '../data/doza_models.dart';
import 'doza_result_screen.dart';

/// One question Doza asks, with the quick replies the doctor can tap. The LABELS
/// are shown to the doctor; the VALUES are the codes the model expects (never
/// translated).
class _Question {
  const _Question(this.key, this.text, this.options);
  final String key;
  final String text;
  final List<(Object, String)> options;
}

const _script = <_Question>[
  _Question('gender', 'To start, is the patient a man or a woman?',
      [(1, 'Man'), (0, 'Woman')]),
  _Question('age_ordinal', 'What is their age range?', [
    (3, '18–39'), (4, '40–49'), (5, '50–59'), (6, '60–69'), (7, '70–79'), (8, '80 +')
  ]),
  _Question('admission_type_id', 'How were they admitted?',
      [(1, 'Emergency'), (2, 'Urgent'), (3, 'Elective'), (0, 'Not sure')]),
  _Question('admission_source_id', 'Where are they coming from?', [
    (7, 'ER'), (1, 'Physician'), (6, 'Transfer'), (0, 'Other'), ('jnsp', 'Not sure')
  ]),
  _Question('medical_specialty', 'Which department is caring for them?', [
    ('InternalMedicine', 'Internal medicine'), ('Emergency/Trauma', 'ER / Trauma'),
    ('Family/GeneralPractice', 'Family / GP'), ('Cardiology', 'Cardiology'),
    ('Other', 'Other department'), ('Unknown', 'Unknown'),
  ]),
  _Question('diag_1_group', 'What is the main reason for admission?', [
    ('Diabetes', 'Diabetes'), ('Circulatory', 'Heart / vessels'), ('Respiratory', 'Lungs'),
    ('Digestive', 'Digestive'), ('Genitourinary', 'Kidneys'), ('Musculoskeletal', 'Joints'),
    ('Injury', 'Injury'), ('Neoplasms', 'Cancer'), ('Other', 'Other'),
  ]),
  _Question('A1Cresult', 'What is their latest HbA1c?',
      [(1, '< 7 %'), (2, '7–8 %'), (3, '> 8 %'), (0, 'Unknown')]),
  _Question('num_medications', 'How many medications are they on?',
      [(3, '1–5'), (8, '6–10'), (13, '11–15'), (18, '16–20'), (25, '> 20')]),
  _Question('sulfonylurea', 'Is a sulfonylurea prescribed?',
      [(1, 'Yes'), (0, 'No')]),
  _Question('number_inpatient', 'In the past year, how many inpatient stays?',
      [(0, '0'), (1, '1'), (2, '2'), (3, '3+')]),
  _Question('number_emergency', 'And how many ER visits?',
      [(0, '0'), (1, '1'), (2, '2'), (3, '3+')]),
  _Question('number_outpatient', 'Finally, how many outpatient visits?',
      [(0, '0'), (1, '1'), (2, '2'), (3, '3+')]),
];

enum _Kind { bot, user, result, error }

class _Msg {
  _Msg(this.kind, {this.text = '', this.result});
  final _Kind kind;
  final String text;
  final DozaResult? result;
}

/// Doza as a conversational chatbot (same model & API as before) in Ryma's
/// visual charter: blob background, soft bubbles, coral accent, quick replies.
class DozaChatScreen extends StatefulWidget {
  const DozaChatScreen({super.key});

  @override
  State<DozaChatScreen> createState() => _DozaChatScreenState();
}

class _DozaChatScreenState extends State<DozaChatScreen> {
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  final Map<String, Object> _answers = {};

  int _step = -1;         // -1 before the first question
  bool _typing = false;   // Doza "is writing…"
  bool _busy = false;     // a reply is being processed / analysis running
  List<(Object, String)>? _options;  // current quick replies ("retry" when null key)
  bool _retry = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _messages.clear();
    _answers.clear();
    _step = -1;
    _retry = false;
    _options = null;
    setState(() {});
    await _bot('Hello, I\'m Doza 👩‍⚕️');
    await _bot('I\'ll estimate whether your patient\'s insulin dose (already on '
        'insulin) is likely to change. A few quick questions — tap an answer.');
    await _ask();
  }

  /// Append a Doza bubble after a short "writing…" delay.
  Future<void> _bot(String text) async {
    setState(() => _typing = true);
    _scrollToEnd();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(_Msg(_Kind.bot, text: text));
    });
    _scrollToEnd();
  }

  Future<void> _ask() async {
    _step++;
    if (_step >= _script.length) {
      await _analyze();
      return;
    }
    final q = _script[_step];
    await _bot(q.text);
    setState(() => _options = q.options);
    _scrollToEnd();
  }

  void _answer(Object value, String label) {
    if (_busy) return;
    HapticFeedback.selectionClick();
    if (_retry) {
      setState(() {
        _retry = false;
        _options = null;
      });
      _analyze();
      return;
    }
    setState(() {
      _messages.add(_Msg(_Kind.user, text: label));
      _answers[_script[_step].key] = value;
      _options = null;
    });
    _scrollToEnd();
    _ask();
  }

  Future<void> _analyze() async {
    final api = context.read<ApiClient>();  // capture before any await
    final code = context.read<ActivePatientCubit>().state?.code;
    setState(() => _busy = true);
    await _bot('Thanks. Analyzing the patient\'s profile…');
    setState(() => _typing = true);
    _scrollToEnd();
    try {
      final json = await api.postJson('/api/v1/doza/predict', {'answers': _answers},
          headers: code == null ? null : {'X-Patient-Code': code});
      if (!mounted) return;
      final res = DozaResult(json);
      setState(() {
        _typing = false;
        _busy = false;
        _messages.add(_Msg(_Kind.result, result: res));
      });
      HapticFeedback.mediumImpact();
      _scrollToEnd();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _busy = false;
        _messages.add(_Msg(_Kind.error, text: e.message));
        _retry = true;
        _options = [('retry', 'Try again')];
      });
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showChips = _options != null && !_typing;
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.coral, AppColors.pink, AppColors.amber],
        opacity: 0.16,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                  itemCount: _messages.length + (_typing ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length) return const _TypingBubble();
                    final m = _messages[i];
                    return switch (m.kind) {
                      _Kind.user => _UserBubble(text: m.text),
                      _Kind.bot => _BotBubble(child: _BubbleText(m.text)),
                      _Kind.error => _BotBubble(child: _BubbleText(m.text, error: true)),
                      _Kind.result => _BotBubble(child: _ResultCard(result: m.result!)),
                    };
                  },
                ),
              ),
              _QuickReplies(
                visible: showChips,
                options: _options ?? const [],
                onTap: _answer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            const AvatarFace(avatar: AvatarProfile.doza, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Doza',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                  Row(
                    children: [
                      const PulseDot(color: AppColors.green, size: 6),
                      Text(_busy ? 'analyzing…' : 'insulin assistant · online',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Restart',
              onPressed: _busy ? null : _start,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );
}

// --------------------------------------------------------------------- bubbles
class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AvatarFace(avatar: AvatarProfile.doza, size: 34),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                ),
                boxShadow: AppColors.softShadow(),
              ),
              child: child,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }
}

class _BubbleText extends StatelessWidget {
  const _BubbleText(this.text, {this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error) ...[
          const Icon(Icons.cloud_off_rounded, color: AppColors.coral, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(text,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4)),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 48),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: AppColors.coralGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: AppColors.glow(AppColors.coral, strength: 0.22),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.12, curve: Curves.easeOutCubic);
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const _BotBubble(child: _Dots());
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_c.value + i * 0.2) % 1);
            final o = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: o),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- result in chat
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final DozaResult result;

  Color get _zoneColor => switch (result.zone) {
        'High risk' => AppColors.red,
        'Intermediate risk' => AppColors.amber,
        _ => AppColors.green,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_person_rounded, color: AppColors.coral, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text('For the doctor — do not show the patient.',
                  style: TextStyle(
                      color: AppColors.coral.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _zoneColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('${result.pourcentage}%',
                  style: TextStyle(color: _zoneColor, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.zone,
                      style: TextStyle(
                          color: _zoneColor, fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(
                    result.changeProbable
                        ? 'Dose change likely'
                        : 'Dose fairly stable',
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (result.zoneTaux != null) ...[
          const SizedBox(height: 8),
          Text('Actual rate observed in this zone: ${result.zoneTaux}%.',
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, height: 1.35)),
        ],
        const SizedBox(height: 12),
        GradientButton(
          label: 'Details & voice explanation',
          icon: Icons.volume_up_rounded,
          gradient: AppColors.coralGradient,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DozaResultScreen(result: result))),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- quick replies
class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.visible, required this.options, required this.onTap});

  final bool visible;
  final List<(Object, String)> options;
  final void Function(Object value, String label) onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: AppColors.softShadow(),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (value, label) in options)
                    _ReplyChip(label: label, onTap: () => onTap(value, label)),
                ],
              ),
            ),
    );
  }
}

class _ReplyChip extends StatelessWidget {
  const _ReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.coral.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.coral, fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }
}
