// lib/features/auth/presentation/screens/register_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _sexe = 'M';
  bool _obscurePassword = true;
  double _passwordStrength = 0;
  Uint8List? _photoBytes;
  String? _photoFilename;

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoFilename = file.name;
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  double _evaluerForce(String password) {
    double score = 0;
    if (password.length >= 8) score += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) score += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) score += 0.25;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score += 0.25;
    return score;
  }

  Color get _forceColor {
    if (_passwordStrength < 0.5) return AppColors.erreur;
    if (_passwordStrength < 0.75) return AppColors.alerte;
    return AppColors.succes;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthRegisterRequested(
          {
            'nom': _nomCtrl.text.trim(),
            'prenom': _prenomCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'telephone': _telCtrl.text.trim(),
            'sexe': _sexe,
            'mot_de_passe': _passwordCtrl.text,
          },
          photoBytes: _photoBytes,
          photoFilename: _photoFilename,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppConstants.routeLogin),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegisterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.succes,
                duration: const Duration(seconds: 4),
              ),
            );
            context.go(AppConstants.routeLogin);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rejoignez ORIGINE 🌿',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Commencez à reconstruire votre histoire familiale.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.grisClair,
                            backgroundImage:
                                _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                            child: _photoBytes == null
                                ? const Icon(Icons.person_outline,
                                    size: 40, color: AppColors.gris)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.or,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16, color: AppColors.noir),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Photo de profil (facultatif)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (state is AuthError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppBanner(message: state.message),
                    ),

                  // Nom + Prénom côte à côte
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Nom',
                          controller: _nomCtrl,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Prénom',
                          controller: _prenomCtrl,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Adresse email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gris),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Téléphone (+237...)',
                    controller: _telCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.gris),
                  ),
                  const SizedBox(height: 14),

                  // Sélecteur de sexe
                  const Text('Sexe', style: TextStyle(fontSize: 13, color: AppColors.gris, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['M', 'F'].map((s) {
                      final labels = {'M': 'Masculin', 'F': 'Féminin'};
                      final selected = _sexe == s;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _sexe = s),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.vertForet : AppColors.blanc,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? AppColors.vertForet : AppColors.grisClair,
                              ),
                            ),
                            child: Text(
                              labels[s]!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? AppColors.blanc : AppColors.gris,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Mot de passe',
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.gris),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.gris,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    onChanged: (v) =>
                        setState(() => _passwordStrength = _evaluerForce(v)),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'Minimum 8 caractères';
                      }
                      if (!v.contains(RegExp(r'[A-Z]')) || !v.contains(RegExp(r'[0-9]'))) {
                        return '1 majuscule et 1 chiffre minimum';
                      }
                      return null;
                    },
                  ),

                  // Barre de force du mot de passe
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: AppColors.grisClair,
                      color: _forceColor,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _passwordStrength < 0.5
                        ? 'Mot de passe faible'
                        : _passwordStrength < 0.75
                            ? 'Mot de passe moyen'
                            : 'Mot de passe fort',
                    style: TextStyle(fontSize: 11, color: _forceColor),
                  ),
                  const SizedBox(height: 28),

                  AppPrimaryButton(
                    label: "S'inscrire",
                    onPressed: _submit,
                    isLoading: state is AuthLoading,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Vous avez déjà un compte ? ',
                          style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go(AppConstants.routeLogin),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            color: AppColors.vertClair,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
