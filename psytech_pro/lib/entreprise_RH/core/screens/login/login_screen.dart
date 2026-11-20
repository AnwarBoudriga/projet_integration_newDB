import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import 'widgets/login_brand_panel.dart';
import 'widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showBrandPanel = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (showBrandPanel)
                const Expanded(flex: 4, child: LoginBrandPanel()),
              Expanded(
                flex: 6,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: const LoginForm(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
