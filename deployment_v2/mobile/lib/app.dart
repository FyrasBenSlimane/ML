import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/auth_cubit.dart';
import 'core/network/api_client.dart';
import 'core/network/server_status_cubit.dart';
import 'core/patient/active_patient_cubit.dart';
import 'core/settings/settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/teemo/bloc/history_cubit.dart';
import 'features/teemo/data/teemo_repository.dart';

/// Wires the shared services every module can use:
///   ApiClient (server address from Settings), TeemoRepository, AuthCubit,
///   ActivePatientCubit, SettingsCubit, ServerStatusCubit and HistoryCubit.
class ReadmitGuardApp extends StatelessWidget {
  const ReadmitGuardApp({
    super.key,
    required this.settings,
    required this.api,
    required this.auth,
  });

  final SettingsCubit settings;
  final ApiClient api;
  final AuthCubit auth;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: api),
        RepositoryProvider(create: (_) => TeemoRepository(api)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider.value(value: auth),
          BlocProvider(create: (_) => ActivePatientCubit()),
          BlocProvider(create: (_) => ServerStatusCubit(api)),
          BlocProvider(create: (_) => HistoryCubit()),
        ],
        child: MaterialApp(
          title: 'ReadmitGuard',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
