// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/domain/auth_bloc.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../core/api/api_client.dart';
import 'package:dio/dio.dart';
import '../../../stories/presentation/screens/admin_certifications_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../../core/push/push_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _villageCtrl;
  late TextEditingController _regionCtrl;
  late TextEditingController _professionCtrl;
  late TextEditingController _bioCtrl;

  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  bool _enablingNotifications = false;
  bool _uploadingPhoto = false;
  String? _photoOverride;

  String? _photoUrl(UserModel? user) {
    final fileName = _photoOverride ?? user?.photoProfil;
    if (fileName == null) return null;
    final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/uploads/avatars/$fileName';
  }

  Future<void> _changePhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final response = await apiClient.post('/profile/avatar', data: formData);
      final newPhoto = response.data['data']['profile']['photo_profil'] as String?;
      if (!mounted) return;
      setState(() => _photoOverride = newPhoto);
      context.read<AuthBloc>().add(AuthCheckRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour.')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _enableNotifications() async {
    setState(() => _enablingNotifications = true);
    final ok = await PushService.initIfSupported();
    if (!mounted) return;
    setState(() => _enablingNotifications = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Notifications activées ! Vous serez averti des nouveaux messages familiaux.'
          : 'Impossible d\'activer les notifications (permission refusée ou navigateur non compatible).'),
    ));
  }

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController();
    _prenomCtrl = TextEditingController();
    _telCtrl = TextEditingController();
    _villageCtrl = TextEditingController();
    _regionCtrl = TextEditingController();
    _professionCtrl = TextEditingController();
    _bioCtrl = TextEditingController();

    final user = _getUser();
    if (user != null) _fillFields(user);
  }

  UserModel? _getUser() {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticated ? state.user : null;
  }

  void _fillFields(UserModel user) {
    _nomCtrl.text = user.nom;
    _prenomCtrl.text = user.prenom;
    _telCtrl.text = user.telephone ?? '';
    _villageCtrl.text = user.villageOrigine ?? '';
    _regionCtrl.text = user.region ?? '';
    _professionCtrl.text = user.profession ?? '';
    _bioCtrl.text = user.biographie ?? '';
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _telCtrl.dispose();
    _villageCtrl.dispose(); _regionCtrl.dispose();
    _professionCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _errorMessage = null; _successMessage = null; });
    try {
      await apiClient.put('/profile', data: {
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'telephone': _telCtrl.text.trim(),
        'village_origine': _villageCtrl.text.trim(),
        'region': _regionCtrl.text.trim(),
        'profession': _professionCtrl.text.trim(),
        'biographie': _bioCtrl.text.trim(),
      });
      setState(() => _successMessage = 'Profil mis à jour avec succès.');
    } on DioException catch (e) {
      setState(() => _errorMessage = ApiClient.extractError(e));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthBloc>();
    final user = _getUser();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête vert avec avatar
            Container(
              width: double.infinity,
              color: AppColors.vertForet,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadingPhoto ? null : _changePhoto,
                    child: Stack(
                      children: [
                        AppAvatar(
                          imageUrl: _photoUrl(user),
                          initials: user != null
                              ? '${user.prenom[0]}${user.nom[0]}'
                              : '?',
                          radius: 38,
                        ),
                        if (_uploadingPhoto)
                          const Positioned.fill(
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.black38,
                              child: SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blanc),
                              ),
                            ),
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
                            child: const Icon(Icons.camera_alt, size: 14, color: AppColors.noir),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.nomComplet ?? '',
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.or.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role ?? 'UTILISATEUR',
                      style: const TextStyle(color: AppColors.orClair, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      AppBanner(message: _errorMessage!),
                      const SizedBox(height: 12),
                    ],
                    if (_successMessage != null) ...[
                      AppBanner(message: _successMessage!, isError: false),
                      const SizedBox(height: 12),
                    ],

                    Text('Informations personnelles',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: AppTextField(label: 'Nom', controller: _nomCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'Prénom', controller: _prenomCtrl)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Téléphone', controller: _telCtrl, keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),

                    Text('Origines', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: AppTextField(label: "Village d'origine", controller: _villageCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'Région', controller: _regionCtrl)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Profession', controller: _professionCtrl),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Biographie', controller: _bioCtrl, maxLines: 4),
                    const SizedBox(height: 24),

                    AppPrimaryButton(
                      label: 'Enregistrer les modifications',
                      onPressed: _save,
                      isLoading: _isSaving,
                      backgroundColor: AppColors.vertForet,
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Calendrier familial'),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CalendarScreen(),
                      )),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      icon: _enablingNotifications
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.notifications_active_outlined),
                      label: const Text('Activer les notifications'),
                      onPressed: _enablingNotifications ? null : _enableNotifications,
                    ),
                    const SizedBox(height: 16),

                    if (user?.role == 'ADMIN') ...[
                      AppPrimaryButton(
                        label: 'Certifications à valider',
                        backgroundColor: AppColors.or,
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const AdminCertificationsScreen(),
                        )),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Déconnexion
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.erreur),
                        foregroundColor: AppColors.erreur,
                      ),
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        context.go(AppConstants.routeLogin);
                      },
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
