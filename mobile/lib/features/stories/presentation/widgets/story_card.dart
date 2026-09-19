// lib/features/stories/presentation/widgets/story_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../shared/models/story_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/stories_repository.dart';
import '../screens/story_comments_sheet.dart';

String storyMediaUrl(String subfolder, String filename) =>
    resolveMediaUrl(subfolder, filename);

class StoryCard extends StatefulWidget {
  final StoryModel story;
  final VoidCallback onLikeToggle;
  final VoidCallback? onDelete;

  const StoryCard({super.key, required this.story, required this.onLikeToggle, this.onDelete});

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _expanded = false;

  Future<void> _toggleListen() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _tts.setLanguage('fr-FR');
    await _tts.speak(widget.story.description);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette histoire ?'),
        content: Text('"${widget.story.titre}" sera définitivement supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.erreur)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete?.call();
  }

  Future<void> _share() async {
    final story = widget.story;
    final excerpt = story.description.length > 200
        ? '${story.description.substring(0, 200)}...'
        : story.description;
    final text = '📖 ${story.titre}\n\n$excerpt\n\n'
        'Partagé depuis ORIGINE 🌿 — Votre histoire commence ici.';

    try {
      final result = await Share.share(text, subject: story.titre);
      if (result.status == ShareResultStatus.unavailable) {
        await _copyToClipboard(text);
      }
    } catch (_) {
      await _copyToClipboard(text);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Histoire copiée dans le presse-papiers !')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final description = story.description;
    final showToggle = description.length > 160 && !_expanded;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  imageUrl: story.author.photoProfil != null
                      ? storyMediaUrl('avatars', story.author.photoProfil!)
                      : null,
                  initials: story.author.nomComplet.isNotEmpty ? story.author.nomComplet[0] : '?',
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              story.author.nomComplet,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          if (story.author.certifie) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppColors.vertClair, size: 15),
                          ],
                        ],
                      ),
                      Text(
                        story.createdAt?.split(' ').first ?? '',
                        style: const TextStyle(fontSize: 11, color: AppColors.gris),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.gris),
                  onSelected: (v) {
                    if (v == 'report') _showReportDialog(context);
                    if (v == 'delete') _confirmDelete(context);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'report', child: Text('Signaler')),
                    if (widget.onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer', style: TextStyle(color: AppColors.erreur)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(story.titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: showToggle ? 4 : null,
              overflow: showToggle ? TextOverflow.ellipsis : null,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            if (description.length > 160)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Voir moins' : 'Voir plus',
                  style: const TextStyle(
                      color: AppColors.vertClair, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            if (story.media.isNotEmpty) ...[
              const SizedBox(height: 10),
              _MediaPreview(media: story.media),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(kStoryCategories[story.categorie] ?? story.categorie,
                      style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.grisClair,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionButton(
                  icon: story.likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: story.likedByMe ? AppColors.erreur : AppColors.gris,
                  label: '${story.likesCount}',
                  onTap: widget.onLikeToggle,
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.gris,
                  label: '${story.commentsCount}',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => StoryCommentsSheet(storyId: story.id),
                  ),
                ),
                _ActionButton(icon: Icons.share_outlined, color: AppColors.gris, label: 'Partager', onTap: _share),
                if (story.autoriserTts)
                  _ActionButton(
                    icon: _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                    color: _isSpeaking ? AppColors.or : AppColors.gris,
                    label: _isSpeaking ? 'Stop' : 'Écouter',
                    onTap: _toggleListen,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Signaler cette histoire'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Raison (optionnel)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text),
            child: const Text('Signaler'),
          ),
        ],
      ),
    ).then((raison) async {
      if (raison == null) return;
      await StoriesRepository().reportStory(widget.story.id, raison: raison.isEmpty ? null : raison);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Signalement envoyé.')));
      }
    });
  }
}

class _MediaPreview extends StatelessWidget {
  final List<StoryMediaModel> media;
  const _MediaPreview({required this.media});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = media[i];
          if (m.type == 'PHOTO') {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: storyMediaUrl('story_media', m.nomFichier),
                width: 220,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 220, color: AppColors.grisClair),
                errorWidget: (_, __, ___) => Container(
                  width: 220,
                  color: AppColors.grisClair,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            );
          }
          final icon = m.type == 'VIDEO' ? Icons.videocam : Icons.audiotrack;
          return Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.grisClair,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(icon, size: 32, color: AppColors.vertForet)),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
