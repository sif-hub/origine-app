// lib/features/stories/presentation/screens/admin_certifications_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/models/story_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/stories_repository.dart';

String _documentUrl(String filename) {
  final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
  return '$base/uploads/certification_documents/$filename';
}

class AdminCertificationsScreen extends StatefulWidget {
  const AdminCertificationsScreen({super.key});

  @override
  State<AdminCertificationsScreen> createState() => _AdminCertificationsScreenState();
}

class _AdminCertificationsScreenState extends State<AdminCertificationsScreen> {
  final _repository = StoriesRepository();
  List<CertificationRequestModel>? _requests;
  String? _error;
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _error = null; _requests = null; });
    try {
      final requests = await _repository.getCertificationRequests(statut: 'EN_ATTENTE');
      if (!mounted) return;
      setState(() => _requests = requests);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _review(CertificationRequestModel request, String statut) async {
    setState(() => _processing.add(request.id));
    try {
      await _repository.reviewCertificationRequest(request.id, statut);
      if (!mounted) return;
      setState(() => _requests!.removeWhere((r) => r.id == request.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(statut == 'APPROUVEE'
            ? '${request.user.nomComplet} est maintenant certifié(e).'
            : 'Demande rejetée.'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _processing.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certifications à valider')),
      body: _error != null
          ? Center(child: AppBanner(message: _error!))
          : _requests == null
              ? const AppLoader()
              : _requests!.isEmpty
                  ? const Center(child: Text('Aucune demande en attente.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = _requests![i];
                        final processing = _processing.contains(r.id);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AppAvatar(
                                      initials: r.user.nomComplet.isNotEmpty ? r.user.nomComplet[0] : '?',
                                      radius: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r.user.nomComplet,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                          if (r.user.email != null)
                                            Text(r.user.email!,
                                                style: const TextStyle(fontSize: 11, color: AppColors.gris)),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(kCertificationTypeLabels[r.typeProfessionnel] ?? r.typeProfessionnel,
                                          style: const TextStyle(fontSize: 11)),
                                      backgroundColor: AppColors.or.withOpacity(0.15),
                                      side: BorderSide.none,
                                    ),
                                  ],
                                ),
                                if (r.description != null && r.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(r.description!, style: const TextStyle(fontSize: 13)),
                                ],
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: InteractiveViewer(
                                        child: Image.network(_documentUrl(r.documentFichier)),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.description_outlined, size: 16, color: AppColors.vertForet),
                                      SizedBox(width: 6),
                                      Text('Voir le document justificatif',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.vertForet,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: processing ? null : () => _review(r, 'REJETEE'),
                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.erreur),
                                        child: const Text('Rejeter'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: AppPrimaryButton(
                                        label: 'Approuver',
                                        isLoading: processing,
                                        backgroundColor: AppColors.vertForet,
                                        onPressed: () => _review(r, 'APPROUVEE'),
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
