import 'package:flutter/material.dart';

import 'navigation/app_router.dart';
import 'services/api_client.dart';
import 'services/data_store.dart';
import 'theme/app_theme.dart';

class PsyTechApp extends StatefulWidget {
  const PsyTechApp({super.key});

  @override
  State<PsyTechApp> createState() => _PsyTechAppState();
}

class _PsyTechAppState extends State<PsyTechApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Token expiré / entreprise supprimée: retour à la connexion.
    ApiClient.instance.onUnauthorized = () {
      DataStore.instance.reset();
      AppRouter.navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Session expirée. Reconnectez-vous.'),
        ));
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PsyTech Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorKey: AppRouter.navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
