// lib/features/genealogy/presentation/screens/member_verification_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../domain/add_member_bloc.dart';

const _visibiliteLabels = {
  'PRIVE': 'Privé',
  'PARTAGE': 'Partagé',
  'PUBLIC': 'Public',
};

class MemberVerificationScreen extends StatelessWidget {
  final PersonModel person;
  final MemberDraft draft;

  const MemberVerificationScreen({super.key, required this.person, required this.draft});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.vertForet,
                    child: Icon(Icons.check, color: AppColors.blanc, size: 34),
                  ),
                  const SizedBox(height: 12),
                  Text('Membre ajouté avec succès !',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${person.nomComplet} a été ajouté(e) à votre arbre.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppInfoCard(
              title: person.nomComplet,
              rows: [
                if (draft.relationType != 'AUCUN') InfoRow('Relation', draft.relationType),
                if (person.dateNaissance != null) InfoRow('Né(e) le', person.dateNaissance!),
                if (person.villageOrigine != null) InfoRow('Origine', person.villageOrigine!),
                InfoRow('Visibilité', _visibiliteLabels[person.visibilite] ?? person.visibilite),
                InfoRow('Peut voir', person.peutVoir ? 'Oui' : 'Non'),
                InfoRow('Peut modifier', person.peutModifier ? 'Oui' : 'Non'),
                InfoRow('Peut ajouter des documents', person.peutAjouterDocuments ? 'Oui' : 'Non'),
                InfoRow('Peut ajouter des souvenirs', person.peutAjouterSouvenirs ? 'Oui' : 'Non'),
                InfoRow('Peut commenter', person.peutCommenter ? 'Oui' : 'Non'),
              ],
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Voir dans mon arbre',
              backgroundColor: AppColors.vertForet,
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Ajouter un autre membre',
              backgroundColor: AppColors.or,
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
