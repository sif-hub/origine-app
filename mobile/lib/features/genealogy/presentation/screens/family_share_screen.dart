// lib/features/genealogy/presentation/screens/family_share_screen.dart
//
// Partage d'un arbre avec un membre choisi : recherche d'un utilisateur,
// choix du droit (lecture / édition), liste et retrait des partages.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/genealogy_repository.dart';

const _permissionLabels = {
  'LECTURE': 'Lecture seule',
  'EDITION': 'Peut modifier',
};

class FamilyShareScreen extends StatefulWidget {
  final FamilyModel family;
  const FamilyShareScreen({super.key, required this.family});

  @override
  State<FamilyShareScreen> createState() => _FamilyShareScreenState();
}

class _FamilyShareScreenState extends State<FamilyShareScreen> {
  final _repository = GenealogyRepository();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<FamilyShareModel>? _shares;
  List<UserModel> _results = [];
  bool _searching = false;
  String? _error;
  String _permission = 'LECTURE';
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShares() async {
    try {
      final shares = await _repository.getShares(widget.family.id);
      if (!mounted) return;
      setState(() { _shares = shares; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      try {
        final users = await _repository.searchUsers(value);
        if (!mounted) return;
        final already = _shares?.map((s) => s.user.id).toSet() ?? {};
        setState(() => _results = users.where((u) => !already.contains(u.id)).toList());
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _share(UserModel user) async {
    setState(() => _busy.add(user.id));
    try {
      await _repository.shareFamily(widget.family.id, user.id, _permission);
      _searchCtrl.clear();
      setState(() => _results = []);
      await _loadShares();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Arbre partagé avec ${user.nomComplet}.'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy.remove(user.id));
    }
  }

  Future<void> _changePermission(FamilyShareModel share, String permission) async {
    if (permission == share.permission) return;
    setState(() => _busy.add(share.user.id));
    try {
      await _repository.shareFamily(widget.family.id, share.user.id, permission);
      await _loadShares();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy.remove(share.user.id));
    }
  }

  Future<void> _remove(FamilyShareModel share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer l\'accès ?'),
        content: Text('${share.user.nomComplet} ne pourra plus voir cet arbre.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer', style: TextStyle(color: AppColors.erreur)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy.add(share.user.id));
    try {
      await _repository.unshareFamily(widget.family.id, share.user.id);
      await _loadShares();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy.remove(share.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partager mon arbre')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Choisir un membre', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Recherchez un utilisateur d\'ORIGINE par nom ou email, puis choisissez ce qu\'il peut faire.',
            style: TextStyle(fontSize: 12, color: AppColors.gris),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Rechercher un membre',
              prefixIcon: const Icon(Icons.search, color: AppColors.gris),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'LECTURE', label: Text('Lecture seule'), icon: Icon(Icons.visibility_outlined)),
              ButtonSegment(value: 'EDITION', label: Text('Peut modifier'), icon: Icon(Icons.edit_outlined)),
            ],
            selected: {_permission},
            onSelectionChanged: (s) => setState(() => _permission = s.first),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: _results
                    .map((u) => ListTile(
                          leading: AppAvatar(initials: u.initiales, radius: 18),
                          title: Text(u.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(u.email),
                          trailing: _busy.contains(u.id)
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.person_add_alt_1, color: AppColors.vertForet),
                          onTap: _busy.contains(u.id) ? null : () => _share(u),
                        ))
                    .toList(),
              ),
            ),
          ] else if (_searchCtrl.text.trim().length >= 2 && !_searching)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Aucun membre trouvé.', style: TextStyle(color: AppColors.gris, fontSize: 13)),
            ),
          const SizedBox(height: 28),
          Text('Partagé avec', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_error != null)
            AppBanner(message: _error!)
          else if (_shares == null)
            const Padding(padding: EdgeInsets.all(16), child: AppLoader())
          else if (_shares!.isEmpty)
            const Text('Cet arbre n\'est encore partagé avec personne.',
                style: TextStyle(color: AppColors.gris, fontSize: 13))
          else
            ..._shares!.map((share) => Card(
                  child: ListTile(
                    leading: AppAvatar(initials: share.user.initiales, radius: 18),
                    title: Text(share.user.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(share.user.email),
                    trailing: _busy.contains(share.user.id)
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'remove') {
                                _remove(share);
                              } else {
                                _changePermission(share, v);
                              }
                            },
                            child: Chip(
                              label: Text(_permissionLabels[share.permission] ?? share.permission,
                                  style: const TextStyle(fontSize: 11)),
                              side: BorderSide.none,
                              backgroundColor: AppColors.or.withValues(alpha: 0.15),
                            ),
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'LECTURE', child: Text('Lecture seule')),
                              const PopupMenuItem(value: 'EDITION', child: Text('Peut modifier')),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('Retirer l\'accès', style: TextStyle(color: AppColors.erreur)),
                              ),
                            ],
                          ),
                  ),
                )),
        ],
      ),
    );
  }
}
