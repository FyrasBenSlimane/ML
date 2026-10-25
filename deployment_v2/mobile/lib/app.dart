import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/network/server_status_cubit.dart';
import 'core/settings/settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/teemo/bloc/history_cubit.dart';
import 'features/teemo/data/teemo_repository.dart';

/// Wires the shared services every module can use:
///   ApiClient (server address from Settings), TeemoRepository,
///   SettingsCubit, ServerStatusCubit and HistoryCubit.
class ReadmitGuardApp extends StatelessWidget {
  const ReadmitGuardApp({super.key, required this.settings});

  final SettingsCubit settings;

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(() => settings.state.serverUrl);
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: api),
        RepositoryProvider(create: (_) => TeemoRepository(api)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
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
