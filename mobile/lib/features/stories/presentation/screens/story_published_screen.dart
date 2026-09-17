// lib/features/stories/presentation/screens/story_published_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/models/story_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import 'add_story_wizard_screen.dart';

class StoryPublishedScreen extends StatelessWidget {
  final StoryModel story;

  const StoryPublishedScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publication')),
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
                  Text('Histoire publiée !', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Votre histoire a été publiée avec succès et est maintenant visible sur le fil d\'actualité d\'ORIGINE.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppInfoCard(
              title: story.titre,
              rows: [
                InfoRow('Catégorie', kStoryCategories[story.categorie] ?? story.categorie),
                if (story.region != null) InfoRow('Région', story.region!),
                InfoRow('Médias', '${story.media.length} fichier(s)'),
              ],
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Retour à l\'accueil',
              backgroundColor: AppColors.vertForet,
              onPressed: () => context.go(AppConstants.routeHome),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Ajouter une autre histoire',
              backgroundColor: AppColors.or,
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const AddStoryWizardScreen(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
