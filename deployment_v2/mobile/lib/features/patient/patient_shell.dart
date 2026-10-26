import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/network/api_client.dart';
import '../../core/patient/patient_alerts_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/pressable.dart';
import '../avatar/avatar_profile.dart';
import '../doza/screens/doza_patient_profile_screen.dart';
import '../home/widgets/sky_scene.dart';
import '../sora/screens/sora_patient_profile_screen.dart';
import '../settings/settings_sheet.dart';

/// The patient's world: a gentle home with the alerts their doctor sent, and a
/// profile with their Patient ID. No model, no result ever reaches this side.
class PatientShell extends StatelessWidget {
  const PatientShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => PatientAlertsCubit(ctx.read<ApiClient>())..load(),
      child: const _PatientShellView(),
    );
  }
}

class _PatientShellView extends StatefulWidget {
  const _PatientShellView();

  @override
  State<_PatientShellView> createState() => _PatientShellViewState();
}

class _PatientShellViewState extends State<_PatientShellView> {
  int _tab = 0;

  void _open(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _tab == 0 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _tab,
          children: const [_PatientHome(), _PatientProfile()],
        ),
        bottomNavigationBar: _PatientNav(index: _tab, onTap: _open),
      ),
    );
  }
}

// --------------------------------------------------------------------------- #
// Home · alerts
// --------------------------------------------------------------------------- #
class _PatientHome extends StatelessWidget {
  const _PatientHome();

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    final cubit = context.read<PatientAlertsCubit>();
    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: cubit.load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _SkyHeader(name: user?.prenom ?? '')),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -34),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                padding: EdgeInsets.fromLTRB(16, 92, 16, 120 + MediaQuery.paddingOf(context).bottom),
                child: const _AlertsSection(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarCard(
          avatar: AvatarProfile.doza,
          module: 'doza',
          title: 'Doza',
          subtitle: 'Your insulin assistant',
          gradient: AppColors.coralGradient,
          haloPrimary: AppColors.coral,
          haloSecondary: AppColors.pink,
          screen: (_) => const DozaPatientProfileScreen(),
        ),
        const SizedBox(height: 14),
        _AvatarCard(
          avatar: AvatarProfile.sora,
          module: 'sora',
          title: 'Sora',
          subtitle: 'Your follow-up after hospital',
          gradient: AppColors.amberGradient,
          haloPrimary: AppColors.amber,
          haloSecondary: const Color(0xFFFB923C),
          screen: (_) => const SoraPatientProfileScreen(),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text('Your medical results stay with your doctor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
        ),
      ],
    );
  }
}

/// Carte d'avatar de l'accueil : ouvre l'écran patient de l'assistant. Quand un
/// message du médecin n'est pas lu, la carte s'illumine et affiche une pastille
/// « nouveau message » ; les messages se consultent dans l'écran de l'avatar.
/// Au retour sur l'accueil, les alertes sont rafraîchies (règle B). Réutilisée
/// pour Doza et Sora : paramétrer plutôt que dupliquer.
class _AvatarCard extends StatefulWidget {
  const _AvatarCard({
    required this.avatar,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.haloPrimary,
    required this.haloSecondary,
    required this.screen,
  });

  final AvatarProfile avatar;
  final String module;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color haloPrimary;
  final Color haloSecondary;
  final WidgetBuilder screen;

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final cubit = context.read<PatientAlertsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: Builder(builder: widget.screen),
        ),
      ),
    );
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final unread = context.select((PatientAlertsCubit c) =>
        c.state.alerts.where((a) => a.module == module && !a.lu).length);
    final hasAlert = unread > 0;

    final card = SoftCard(
      gradient: widget.gradient,
      onTap: _open,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: AppColors.glow(Colors.black, strength: 0.12),
                ),
                child: ClipOval(
                  child: Image.asset(widget.avatar.faceAsset,
                      fit: BoxFit.cover, alignment: Alignment.topCenter),
                ),
              ),
              if (hasAlert)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.haloPrimary, width: 3),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1, end: 1.3, duration: 700.ms, curve: Curves.easeInOut),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 2),
                Text(widget.subtitle,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                if (hasAlert) ...[
                  const SizedBox(height: 8),
                  _NewMessagePill(count: unread),
                ],
              ],
            ),
          ),
          const GlassPanel(
            radius: 14,
            opacity: 0.25,
            padding: EdgeInsets.all(10),
            child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );

    // Halo pulsé autour de la carte lorsqu'un message n'est pas lu.
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: hasAlert
                ? [
                    BoxShadow(
                      color: widget.haloPrimary.withValues(alpha: 0.35 + 0.45 * t),
                      blurRadius: 22 + 30 * t,
                      spreadRadius: 1 + 4 * t,
                    ),
                    BoxShadow(
                      color: widget.haloSecondary.withValues(alpha: 0.22 + 0.30 * t),
                      blurRadius: 32 + 24 * t,
                      spreadRadius: 1 + 2 * t,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: card,
    );
  }
}

/// Pastille translucide « nouveau message » avec une cloche qui s'agite.
class _NewMessagePill extends StatelessWidget {
  const _NewMessagePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 1 ? '$count new messages' : '1 new message';
    return GlassPanel(
      radius: 14,
      opacity: 0.28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 15)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.06, end: 0.06, duration: 420.ms, curve: Curves.easeInOut),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------- #
// Sky header (reuses Ryma's SkyPainter)
// --------------------------------------------------------------------------- #
class _SkyHeader extends StatefulWidget {
  const _SkyHeader({required this.name});

  final String name;

  @override
  State<_SkyHeader> createState() => _SkyHeaderState();
}

class _SkyHeaderState extends State<_SkyHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  String _greeting(double h) {
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final now = DateTime.now();
    final hour = now.hour + now.minute / 60;
    final unread = context.select((PatientAlertsCubit c) => c.state.unread);
    return SizedBox(
      height: (MediaQuery.sizeOf(context).height * 0.34).clamp(260.0, 340.0),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, _) => CustomPaint(painter: SkyPainter(hour: hour, t: _loop.value)),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: top + 12,
            child: Row(
              children: [
                const GlassPanel(
                  radius: 16,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 17),
                      SizedBox(width: 6),
                      Text('My health space',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                ),
                const Spacer(),
                Pressable(
                  onTap: () => showSettingsSheet(context),
                  child: const GlassPanel(
                    radius: 18,
                    padding: EdgeInsets.all(9),
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: top + 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name.isEmpty ? '${_greeting(hour)} 👋' : '${_greeting(hour)}, ${widget.name} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                const SizedBox(height: 6),
                const Text('Take care of yourself',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1)),
                const SizedBox(height: 12),
                GlassPanel(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(unread > 0 ? Icons.mark_email_unread_rounded : Icons.mark_email_read_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        unread > 0
                            ? '$unread new message${unread > 1 ? 's' : ''}'
                            : 'You\'re up to date',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------- #
// Profile
// --------------------------------------------------------------------------- #
class _PatientProfile extends StatelessWidget {
  const _PatientProfile();

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    final top = MediaQuery.paddingOf(context).top;
    final initials = user == null
        ? '?'
        : ((user.prenom.isNotEmpty ? user.prenom[0] : '') +
                (user.nom.isNotEmpty ? user.nom[0] : ''))
            .toUpperCase();
    return BlobBackground(
      colors: const [AppColors.teal, AppColors.sky, AppColors.violet, AppColors.pink],
      opacity: 0.16,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, top + 24, 16, 120 + MediaQuery.paddingOf(context).bottom),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.glow(AppColors.teal, strength: 0.4),
              ),
              child: Text(initials.isEmpty ? '?' : initials,
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(user?.fullName ?? 'Patient',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          Center(
            child: Text(user?.email ?? '',
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          _IdCard(code: user?.code ?? '—'),
          const SizedBox(height: 14),
          SoftCard(
            child: Row(
              children: [
                const IconBadge(Icons.lock_person_rounded, color: AppColors.violet, size: 44),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Your privacy is protected: the analyses stay with your doctor, '
                    'who only passes on their messages to you.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Log out',
            icon: Icons.logout_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFB7185), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  const _IdCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      gradient: AppColors.brandGradient,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Patient ID',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text(code,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: 1.5)),
            ],
          ),
          const Spacer(),
          Pressable(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID copied')),
              );
            },
            child: const GlassPanel(
              radius: 14,
              opacity: 0.25,
              padding: EdgeInsets.all(10),
              child: Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------- #
// Frosted bottom nav (2 tabs, unread badge)
// --------------------------------------------------------------------------- #
class _PatientNav extends StatelessWidget {
  const _PatientNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final unread = context.select((PatientAlertsCubit c) => c.state.unread);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white),
              boxShadow: AppColors.softShadow(),
            ),
            child: Row(
              children: [
                _item(0, Icons.favorite_rounded, 'Home', badge: unread),
                _item(1, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label, {int badge = 0}) {
    final selected = i == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 0, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.teal.withValues(alpha: 0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: selected ? AppColors.tealDeep : AppColors.muted),
                ),
                if (badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                      child: Text('$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.tealDeep : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
