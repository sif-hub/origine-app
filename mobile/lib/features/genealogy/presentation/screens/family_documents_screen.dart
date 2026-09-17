// lib/features/genealogy/presentation/screens/family_documents_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/genealogy_repository.dart';

const _documentLabels = {
  'ACTE_NAISSANCE': 'Acte de naissance',
  'ACTE_MARIAGE': 'Acte de mariage',
  'ACTE_DECES': 'Acte de décès',
  'AUTRE': 'Autre document',
};

class FamilyDocumentsScreen extends StatefulWidget {
  final int familyId;
  const FamilyDocumentsScreen({super.key, required this.familyId});

  @override
  State<FamilyDocumentsScreen> createState() => _FamilyDocumentsScreenState();
}

class _FamilyDocumentsScreenState extends State<FamilyDocumentsScreen> {
  final _repository = GenealogyRepository();
  List<PersonDocumentModel>? _documents;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final documents = await _repository.getFamilyDocuments(widget.familyId);
      if (!mounted) return;
      setState(() => _documents = documents);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents de la famille')),
      body: _error != null
          ? Center(child: AppBanner(message: _error!))
          : _documents == null
              ? const AppLoader()
              : _documents!.isEmpty
                  ? const Center(child: Text('Aucun document pour le moment.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documents!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final doc = _documents![i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.description_outlined,
                                color: AppColors.vertForet),
                            title: Text(_documentLabels[doc.typeDocument] ?? doc.typeDocument),
                            subtitle: Text(doc.createdAt ?? ''),
                          ),
                        );
                      },
                    ),
    );
  }
}
