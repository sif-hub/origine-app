// lib/features/genealogy/presentation/screens/person_detail_screen.dart
//
// Fiche complète d'un membre de l'arbre : informations, liens familiaux,
// modification, ajout d'un lien et suppression.
//
// Résultat renvoyé à l'écran de l'arbre au retour :
//   'refresh' (données modifiées), 'add_relation', 'deleted',
//   'open:<id>[:1]' (ouvrir la fiche d'un proche), ou null.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/genealogy_repository.dart';
import '../widgets/person_relations.dart';
import 'edit_person_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final PersonModel person;
  final FamilyTreeModel tree;
  final bool canEdit;

  const PersonDetailScreen({
    super.key,
    required this.person,
    required this.tree,
    required this.canEdit,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  late PersonModel _person = widget.person;
  bool _changed = false;
  bool _deleting = false;

  Color get _color => _person.sexe == 'M'
      ? AppColors.vertForet
      : _person.sexe == 'F'
          ? AppColors.erreur
          : AppColors.gris;

  static DateTime? _parse(String? iso) =>
      iso == null || iso.length < 10 ? null : DateTime.tryParse(iso.substring(0, 10));

  static String _fr(String? iso) {
    final d = _parse(iso);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String? get _ageLine {
    final born = _parse(_person.dateNaissance);
    if (born == null) return null;
    final end = _parse(_person.dateDeces) ?? DateTime.now();
    var age = end.year - born.year;
    if (end.month < born.month || (end.month == born.month && end.day < born.day)) age--;
    if (age < 0) return null;
    return _person.vivant ? '$age an${age > 1 ? 's' : ''}' : 'Décédé(e) à $age an${age > 1 ? 's' : ''}';
  }

  String get _sexeLabel => _person.sexe == 'M'
      ? 'Masculin'
      : _person.sexe == 'F'
          ? 'Féminin'
          : 'Non précisé';

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<PersonModel>(
      MaterialPageRoute(builder: (_) => EditPersonScreen(person: _person)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _person = updated;
      _changed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations mises à jour.')),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce membre ?'),
        content: Text(
          '${_person.nomComplet} sera retiré(e) de l\'arbre, avec ses liens familiaux, '
          'ses documents et ses souvenirs. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.erreur)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await GenealogyRepository().deletePerson(_person.id);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _openRelative(PersonModel relative) {
    // Retour vers l'arbre, qui rouvre la fiche du proche (et rafraîchit si besoin).
    Navigator.of(context).pop('open:${relative.id}${_changed ? ':1' : ''}');
  }

  Widget _relativeSection(String title, List<PersonModel> people) {
    if (people.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gris)),
          const SizedBox(height: 6),
          ...people.map((r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: AppAvatar(
                  imageUrl: r.photo == null ? null : resolveMediaUrl('person_photos', r.photo!),
                  initials: r.nomComplet.isNotEmpty ? r.nomComplet[0] : '?',
                  radius: 18,
                  backgroundColor: r.sexe == 'M'
                      ? AppColors.vertForet
                      : r.sexe == 'F'
                          ? AppColors.erreur
                          : AppColors.gris,
                ),
                title: Text(r.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: r.dateNaissance != null ? Text(r.annees) : null,
                trailing: const Icon(Icons.chevron_right, color: AppColors.gris),
                onTap: () => _openRelative(r),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _person;
    final rel = relationsOf(p.id, widget.tree);
    final ageLine = _ageLine;

    final infoRows = <InfoRow>[
      InfoRow('Sexe', _sexeLabel),
      if (p.dateNaissance != null) InfoRow('Naissance', _fr(p.dateNaissance)),
      if (!p.vivant) InfoRow('Décès', p.dateDeces != null ? _fr(p.dateDeces) : 'Date inconnue'),
      if (ageLine != null) InfoRow('Âge', ageLine),
      if ((p.lieuNaissance ?? '').isNotEmpty) InfoRow('Lieu de naissance', p.lieuNaissance!),
      if ((p.villageOrigine ?? '').isNotEmpty) InfoRow('Village d\'origine', p.villageOrigine!),
      if ((p.nationalite ?? '').isNotEmpty) InfoRow('Nationalité', p.nationalite!),
      if ((p.profession ?? '').isNotEmpty) InfoRow('Profession', p.profession!),
      if ((p.nomPereTexte ?? '').isNotEmpty) InfoRow('Père', p.nomPereTexte!),
      if ((p.nomMereTexte ?? '').isNotEmpty) InfoRow('Mère', p.nomMereTexte!),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed ? 'refresh' : null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fiche du membre'),
          actions: [
            if (widget.canEdit)
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _edit,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  AppAvatar(
                    imageUrl: p.photo == null ? null : resolveMediaUrl('person_photos', p.photo!),
                    initials: p.nomComplet.isNotEmpty ? p.nomComplet[0] : '?',
                    radius: 52,
                    backgroundColor: _color,
                  ),
                  const SizedBox(height: 12),
                  Text(p.nomComplet,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    p.dateNaissance != null ? p.annees : 'Date de naissance inconnue',
                    style: const TextStyle(fontSize: 13, color: AppColors.gris),
                  ),
                  if (!p.vivant)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Chip(
                        label: Text('Décédé(e)', style: TextStyle(fontSize: 11)),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppInfoCard(title: 'Informations', rows: infoRows),
            if ((p.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(p.notes!, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Liens familiaux', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (rel.isEmpty)
                      const Text('Aucun lien familial pour l\'instant.',
                          style: TextStyle(color: AppColors.gris, fontSize: 13)),
                    _relativeSection('PARENTS', rel.parents),
                    _relativeSection('CONJOINT(E)', rel.spouses),
                    _relativeSection('ENFANTS', rel.children),
                    _relativeSection('FRÈRES ET SŒURS', rel.siblings),
                  ],
                ),
              ),
            ),
            if (widget.canEdit) ...[
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Modifier les informations',
                backgroundColor: AppColors.vertForet,
                onPressed: _edit,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_link),
                label: const Text('Ajouter un lien familial'),
                onPressed: () => Navigator.of(context).pop('add_relation'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: _deleting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.delete_outline, color: AppColors.erreur),
                label: const Text('Supprimer ce membre',
                    style: TextStyle(color: AppColors.erreur, fontWeight: FontWeight.w600)),
                onPressed: _deleting ? null : _delete,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
