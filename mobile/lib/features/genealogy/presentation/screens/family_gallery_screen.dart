// lib/features/genealogy/presentation/screens/family_gallery_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/genealogy_repository.dart';

String _uploadUrl(String subfolder, String filename) {
  final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
  return '$base/uploads/$subfolder/$filename';
}

class FamilyGalleryScreen extends StatefulWidget {
  final int familyId;
  const FamilyGalleryScreen({super.key, required this.familyId});

  @override
  State<FamilyGalleryScreen> createState() => _FamilyGalleryScreenState();
}

class _FamilyGalleryScreenState extends State<FamilyGalleryScreen> {
  final _repository = GenealogyRepository();
  List<PersonMemoryModel>? _memories;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final memories = await _repository.getFamilyMemories(widget.familyId);
      if (!mounted) return;
      setState(() => _memories = memories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Souvenirs de la famille')),
      body: _error != null
          ? Center(child: AppBanner(message: _error!))
          : _memories == null
              ? const AppLoader()
              : _memories!.isEmpty
                  ? const Center(child: Text('Aucun souvenir pour le moment.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _memories!.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (_, i) {
                        final memory = _memories![i];
                        if (memory.type == 'PHOTO') {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: _uploadUrl('person_memories', memory.nomFichier),
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: AppColors.grisClair),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.grisClair,
                                child: const Icon(Icons.broken_image_outlined, color: AppColors.gris),
                              ),
                            ),
                          );
                        }
                        final icon = memory.type == 'VIDEO' ? Icons.videocam : Icons.audiotrack;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.grisClair,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Icon(icon, color: AppColors.vertForet, size: 28)),
                        );
                      },
                    ),
    );
  }
}
