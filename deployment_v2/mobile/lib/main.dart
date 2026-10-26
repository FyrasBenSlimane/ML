import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/auth/auth_cubit.dart';
import 'core/network/api_client.dart';
import 'core/settings/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final settings = await SettingsCubit.create();
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(() => settings.state.serverUrl);
  final auth = AuthCubit.restore(api, prefs);
  runApp(ReadmitGuardApp(settings: settings, api: api, auth: auth));
}
