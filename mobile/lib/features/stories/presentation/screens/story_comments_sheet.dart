// lib/features/stories/presentation/screens/story_comments_sheet.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/story_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/stories_repository.dart';

class StoryCommentsSheet extends StatefulWidget {
  final int storyId;
  const StoryCommentsSheet({super.key, required this.storyId});

  @override
  State<StoryCommentsSheet> createState() => _StoryCommentsSheetState();
}

class _StoryCommentsSheetState extends State<StoryCommentsSheet> {
  final _repository = StoriesRepository();
  final _controller = TextEditingController();
  List<StoryCommentModel>? _comments;
  String? _error;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final comments = await _repository.getComments(widget.storyId);
      if (!mounted) return;
      setState(() => _comments = comments);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      final comment = await _repository.addComment(widget.storyId, text);
      if (!mounted) return;
      setState(() {
        _comments = [...?_comments, comment];
        _controller.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppColors.grisClair, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Commentaires', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            Expanded(
              child: _error != null
                  ? Center(child: AppBanner(message: _error!))
                  : _comments == null
                      ? const AppLoader()
                      : _comments!.isEmpty
                          ? const Center(child: Text('Aucun commentaire pour le moment.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _comments!.length,
                              itemBuilder: (_, i) {
                                final c = _comments![i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppAvatar(
                                        initials: c.author.nomComplet.isNotEmpty
                                            ? c.author.nomComplet[0]
                                            : '?',
                                        radius: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.author.nomComplet,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600, fontSize: 12)),
                                            const SizedBox(height: 2),
                                            Text(c.contenu, style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(label: 'Écrire un commentaire...', controller: _controller),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _posting
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, color: AppColors.vertForet),
                      onPressed: _posting ? null : _post,
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
