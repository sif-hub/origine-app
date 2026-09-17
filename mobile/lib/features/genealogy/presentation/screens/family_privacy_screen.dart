// lib/features/genealogy/presentation/screens/family_privacy_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/genealogy_repository.dart';

class FamilyPrivacyScreen extends StatefulWidget {
  final FamilyModel family;
  const FamilyPrivacyScreen({super.key, required this.family});

  @override
  State<FamilyPrivacyScreen> createState() => _FamilyPrivacyScreenState();
}

class _FamilyPrivacyScreenState extends State<FamilyPrivacyScreen> {
  final _repository = GenealogyRepository();
  late String _visibilite = widget.family.visibilite;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated =
          await _repository.updateFamily(widget.family.id, {'visibilite': _visibilite});
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité de l\'arbre')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Confidentialité de l\'arbre',
              subtitle: 'Choisissez le niveau de confidentialité de votre arbre généalogique.',
            ),
            const SizedBox(height: 20),
            _Option(
              icon: Icons.lock_outline,
              title: 'Privé',
              description: 'Votre arbre reste accessible uniquement à vous. Aucun autre utilisateur ne peut le voir.',
              value: 'PRIVE',
              groupValue: _visibilite,
              onChanged: (v) => setState(() => _visibilite = v),
            ),
            _Option(
              icon: Icons.groups_outlined,
              title: 'Partagé',
              description:
                  'Vous pouvez inviter des membres de votre famille à consulter ou à collaborer sur votre arbre.',
              value: 'PARTAGE',
              groupValue: _visibilite,
              onChanged: (v) => setState(() => _visibilite = v),
            ),
            _Option(
              icon: Icons.public,
              title: 'Public',
              description:
                  'Votre arbre peut être consulté par tous les utilisateurs d\'ORIGINE dans le cadre d\'une recherche généalogique.',
              value: 'PUBLIC',
              groupValue: _visibilite,
              onChanged: (v) => setState(() => _visibilite = v),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Enregistrer',
              isLoading: _saving,
              backgroundColor: AppColors.vertForet,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _Option({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Card(
      color: selected ? AppColors.vertForet.withOpacity(0.06) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.vertForet : AppColors.grisClair),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: (v) => onChanged(v!),
        activeColor: AppColors.vertForet,
        secondary: Icon(icon, color: AppColors.vertForet),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
