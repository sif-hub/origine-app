// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../stories/presentation/screens/admin_certifications_screen.dart';
import '../../data/admin_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.or,
          labelColor: AppColors.blanc,
          unselectedLabelColor: AppColors.blanc,
          tabs: const [
            Tab(text: 'Statistiques'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Signalements'),
            Tab(text: 'Certifications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StatsTab(),
          _UsersTab(),
          _ReportedStoriesTab(),
          AdminCertificationsScreen(embedded: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATISTIQUES
// ─────────────────────────────────────────────
class _StatsTab extends StatefulWidget {
  const _StatsTab();

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  final _repository = AdminRepository();
  AdminStats? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _error = null; _stats = null; });
    try {
      final stats = await _repository.getStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: AppBanner(message: _error!));
    if (_stats == null) return const AppLoader();
    final s = _stats!;
    final items = [
      ('Utilisateurs', s.utilisateurs, Icons.people_outline),
      ('Familles', s.familles, Icons.diversity_3_outlined),
      ('Histoires', s.histoires, Icons.menu_book_outlined),
      ('Groupes familiaux', s.groupesFamiliaux, Icons.forum_outlined),
      ('Messages', s.messages, Icons.chat_bubble_outline),
      ('Certifications en attente', s.certificationsEnAttente, Icons.verified_outlined),
      ('Histoires signalées', s.histoiresSignalees, Icons.flag_outlined),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        children: items.map((it) => _StatCard(label: it.$1, value: it.$2, icon: it.$3)).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grisClair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.vertForet),
          Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gris)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UTILISATEURS
// ─────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _repository = AdminRepository();
  final _searchCtrl = TextEditingController();
  List<UserModel>? _users;
  String? _error;
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _error = null; _users = null; });
    try {
      final users = await _repository.listUsers(q: _searchCtrl.text.trim());
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleStatus(UserModel user) async {
    final newStatus = user.statut == 'ACTIF' ? 'SUSPENDU' : 'ACTIF';
    setState(() => _processing.add(user.id));
    try {
      await _repository.setUserStatus(user.id, newStatus);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus == 'SUSPENDU'
            ? '${user.nomComplet} a été suspendu(e).'
            : '${user.nomComplet} a été réactivé(e).'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _processing.remove(user.id));
    }
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce compte ?'),
        content: Text('${user.nomComplet} (${user.email}) sera définitivement supprimé(e), ainsi que ses données. Cette action est irréversible.'),
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

    setState(() => _processing.add(user.id));
    try {
      await _repository.deleteUser(user.id);
      if (!mounted) return;
      setState(() => _users!.removeWhere((u) => u.id == user.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user.nomComplet} a été supprimé(e).')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _processing.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              labelText: 'Rechercher (nom, prénom, email)',
              prefixIcon: const Icon(Icons.search, color: AppColors.gris),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _load,
              ),
            ),
          ),
        ),
        Expanded(
          child: _error != null
              ? Center(child: AppBanner(message: _error!))
              : _users == null
                  ? const AppLoader()
                  : _users!.isEmpty
                      ? const Center(child: Text('Aucun utilisateur trouvé.'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _users!.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final user = _users![i];
                              final processing = _processing.contains(user.id);
                              final suspended = user.statut == 'SUSPENDU';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: AppAvatar(
                                  initials: user.nomComplet.isNotEmpty ? user.nomComplet[0] : '?',
                                  radius: 20,
                                ),
                                title: Text(user.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${user.email}\n${user.role}${suspended ? " · Suspendu" : ""}'),
                                isThreeLine: true,
                                trailing: processing
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'toggle') _toggleStatus(user);
                                          if (action == 'delete') _confirmDelete(user);
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'toggle',
                                            child: Text(suspended ? 'Réactiver' : 'Suspendre'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Supprimer', style: TextStyle(color: AppColors.erreur)),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HISTOIRES SIGNALÉES
// ─────────────────────────────────────────────
class _ReportedStoriesTab extends StatefulWidget {
  const _ReportedStoriesTab();

  @override
  State<_ReportedStoriesTab> createState() => _ReportedStoriesTabState();
}

class _ReportedStoriesTabState extends State<_ReportedStoriesTab> {
  final _repository = AdminRepository();
  List<ReportedStoryModel>? _items;
  String? _error;
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _error = null; _items = null; });
    try {
      final items = await _repository.getReportedStories();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _dismiss(ReportedStoryModel story) async {
    setState(() => _processing.add(story.id));
    try {
      await _repository.dismissReports(story.id);
      if (!mounted) return;
      setState(() => _items!.removeWhere((s) => s.id == story.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _processing.remove(story.id));
    }
  }

  Future<void> _remove(ReportedStoryModel story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette histoire ?'),
        content: Text('"${story.titre}" sera définitivement supprimée.'),
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

    setState(() => _processing.add(story.id));
    try {
      await _repository.deleteReportedStory(story.id);
      if (!mounted) return;
      setState(() => _items!.removeWhere((s) => s.id == story.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _processing.remove(story.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: AppBanner(message: _error!));
    if (_items == null) return const AppLoader();
    if (_items!.isEmpty) return const Center(child: Text('Aucune histoire signalée.'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final story = _items![i];
          final processing = _processing.contains(story.id);
          final authorNom = '${story.author['prenom'] ?? ''} ${story.author['nom'] ?? ''}'.trim();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Par $authorNom', style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                  const SizedBox(height: 8),
                  Text(
                    story.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text('${story.reports.length} signalement(s) :',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ...story.reports.map((r) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${r['raison'] ?? "Sans raison précisée"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.gris),
                        ),
                      )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: processing ? null : () => _dismiss(story),
                          child: const Text('Ignorer les signalements'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Supprimer',
                          isLoading: processing,
                          backgroundColor: AppColors.erreur,
                          onPressed: () => _remove(story),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
