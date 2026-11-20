import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/psytech_logo.dart';
import '../../../navigation/app_router.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String? error;
    try {
      await _authService.loginWithCompanyKey(_keyController.text);
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Connexion impossible. Réessayez.';
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(error),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PsyTechLogo(),
          const SizedBox(height: 28),
          Text(
            'Connexion entreprise',
            style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez votre clé entreprise pour accéder au module Entreprise (RH).',
            style: GoogleFonts.inter(
                fontSize: 13, height: 1.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          CustomTextField(
            label: 'Clé entreprise',
            hint: 'ENT-XXXXXXXX',
            controller: _keyController,
            onSubmitted: (_) => _submit(),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'La clé entreprise est obligatoire.'
                : null,
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Se connecter',
            trailingIcon: Icons.arrow_forward,
            expand: true,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
