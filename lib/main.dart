import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';
import 'api/token_store.dart';
import 'core/router.dart';
import 'state/auth_state.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'widgets/toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: EdgeColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore(prefs);
  late final ApiClient api;
  late final AuthState auth;
  api = ApiClient(
    tokens,
    onUnauthorized: () {
      auth.logout();
    },
  );
  auth = AuthState(api, tokens);
  await auth.bootstrap();
  runApp(VektraApp(api: api, tokens: tokens, auth: auth));
}

class VektraApp extends StatelessWidget {
  const VektraApp({
    super.key,
    required this.api,
    required this.tokens,
    required this.auth,
  });

  final ApiClient api;
  final TokenStore tokens;
  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStore>.value(value: tokens),
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthState>.value(value: auth),
      ],
      child: Builder(builder: (context) {
        final router = buildRouter(context.read<AuthState>());
        return MaterialApp.router(
          title: 'VektraPro',
          theme: AppTheme.build(),
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: ToastMessenger.instance.key,
          routerConfig: router,
        );
      }),
    );
  }
}
