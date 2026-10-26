import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/pressable.dart';
import '../settings/settings_sheet.dart';

/// Login / sign-up, in the app's own style (blob backdrop, soft card, gradient
/// button). A doctor account needs the establishment code; a patient does not.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false;
  bool _medecin = false;
  bool _busy = false;
  String? _error;

  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _email, _password, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthCubit>();
    try {
      if (_register) {
        await auth.register(
          prenom: _prenom.text.trim(),
          nom: _nom.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _medecin ? 'medecin' : 'patient',
          code: _medecin ? _code.text.trim() : null,
        );
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
      // On success the RootGate rebuilds to the right home automatically.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlobBackground(
        baseColor: const Color(0xFFF0FDFA),
        colors: const [AppColors.teal, AppColors.sky, AppColors.violet, AppColors.pink],
        opacity: 0.3,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Pressable(
                    onTap: () => showSettingsSheet(context),
                    child: const GlassPanel(
                      radius: 18,
                      padding: EdgeInsets.all(9),
                      child: Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _header(),
                const SizedBox(height: 22),
                SoftCard(
                  radius: 30,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_register ? 'Create an account' : 'Welcome back',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        _register
                            ? 'Join the ReadmitGuard portal.'
                            : 'Sign in to continue.',
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 18),
                      if (_register) ...[
                        _roleToggle(),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _field(_prenom, 'First name', Icons.badge_rounded)),
                            const SizedBox(width: 12),
                            Expanded(child: _field(_nom, 'Last name', Icons.badge_outlined)),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      _field(_email, 'Email', Icons.alternate_email_rounded,
                          keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _field(_password, 'Password', Icons.lock_rounded, obscure: true),
                      if (_register && _medecin) ...[
                        const SizedBox(height: 12),
                        _field(_code, 'Establishment code', Icons.verified_user_rounded),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _errorBox(_error!),
                      ],
                      const SizedBox(height: 20),
                      GradientButton(
                        label: _register ? 'Create my account' : 'Sign in',
                        icon: Icons.arrow_forward_rounded,
                        loading: _busy,
                        onTap: _busy ? null : _submit,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),
                const SizedBox(height: 18),
                Center(
                  child: Pressable(
                    onTap: () => setState(() {
                      _register = !_register;
                      _error = null;
                    }),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                        children: [
                          TextSpan(text: _register ? 'Already have an account?  ' : 'New here?  '),
                          TextSpan(
                            text: _register ? 'Sign in' : 'Create an account',
                            style: const TextStyle(color: AppColors.tealDeep, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppColors.glow(AppColors.teal, strength: 0.45),
          ),
          child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 46),
        ).animate().scale(begin: const Offset(0.4, 0.4), duration: 700.ms, curve: Curves.elasticOut),
        const SizedBox(height: 14),
        const Text('ReadmitGuard',
            style: TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
        const Text('Care that watches over you',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _roleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _roleTab('Patient', Icons.favorite_rounded, !_medecin, () => setState(() => _medecin = false)),
          _roleTab('Doctor', Icons.medical_services_rounded, _medecin,
              () => setState(() => _medecin = true)),
        ],
      ),
    );
  }

  Widget _roleTab(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected ? AppColors.softShadow() : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? AppColors.tealDeep : AppColors.muted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.tealDeep : AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
