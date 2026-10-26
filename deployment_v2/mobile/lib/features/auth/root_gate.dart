import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/patient/active_patient_cubit.dart';
import '../patient/patient_shell.dart';
import '../shell/main_shell.dart';
import 'auth_screen.dart';

/// Decides what the signed-in (or signed-out) user sees:
///   * not logged in        -> the login / sign-up screen
///   * doctor               -> the full clinical app (Team, Doza, Sora, Teemo)
///   * patient              -> the gentle patient portal (alerts + profile)
///
/// The professor's rule lives here: a patient account can never reach a model.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      // Dropping a session must forget whichever patient was being evaluated.
      listenWhen: (a, b) => !b.isAuthenticated,
      listener: (ctx, _) => ctx.read<ActivePatientCubit>().clear(),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (!state.isAuthenticated) return const AuthScreen();
          return state.user!.isMedecin ? const MainShell() : const PatientShell();
        },
      ),
    );
  }
}
