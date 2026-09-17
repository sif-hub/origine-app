// lib/features/family_chat/presentation/screens/create_group_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/family_chat_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/family_chat_repository.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _repository = FamilyChatRepository();
  final _nomCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  List<ChatUserModel> _searchResults = [];
  final Map<int, ChatUserModel> _selectedMembers = {};
  bool _searching = false;
  bool _creating = false;
  String? _error;

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results = await _repository.searchUsers(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _create() async {
    final nom = _nomCtrl.text.trim();
    if (nom.isEmpty) {
      setState(() => _error = 'Le nom du groupe est obligatoire.');
      return;
    }
    setState(() { _creating = true; _error = null; });
    try {
      await _repository.createGroup(nom, memberIds: _selectedMembers.keys.toList());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un groupe familial')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              AppBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            AppTextField(label: 'Nom du groupe *', controller: _nomCtrl, hint: 'Ex : Famille Eyenga'),
            const SizedBox(height: 20),
            const Text('Ajouter des membres', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            AppTextField(
              label: 'Rechercher par nom ou email',
              controller: _searchCtrl,
              onChanged: (v) => _search(v),
            ),
            const SizedBox(height: 12),
            if (_selectedMembers.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedMembers.values
                    .map((u) => Chip(
                          label: Text(u.nomComplet, style: const TextStyle(fontSize: 11)),
                          onDeleted: () => setState(() => _selectedMembers.remove(u.id)),
                          backgroundColor: AppColors.vertForet.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 8),
            if (_searching) const AppLoader(),
            if (!_searching && _searchResults.isNotEmpty)
              ..._searchResults.map((u) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AppAvatar(
                      initials: u.nomComplet.isNotEmpty ? u.nomComplet[0] : '?',
                      radius: 18,
                    ),
                    title: Text(u.nomComplet, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(u.email ?? '', style: const TextStyle(fontSize: 11)),
                    trailing: Icon(
                      _selectedMembers.containsKey(u.id)
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: AppColors.vertForet,
                    ),
                    onTap: () => setState(() {
                      if (_selectedMembers.containsKey(u.id)) {
                        _selectedMembers.remove(u.id);
                      } else {
                        _selectedMembers[u.id] = u;
                      }
                    }),
                  )),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Créer le groupe',
              isLoading: _creating,
              onPressed: _create,
              backgroundColor: AppColors.vertForet,
            ),
          ],
        ),
      ),
    );
  }
}
