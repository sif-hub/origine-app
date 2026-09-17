// lib/features/ai/presentation/screens/ai_screen.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/widgets/app_widgets.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final _traditionCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _clanCtrl = TextEditingController();

  bool _isSearching = false;
  bool _isAsking = false;
  String? _searchResult;
  String? _assistantResult;
  List<dynamic> _searchPersons = [];

  final List<String> _exemples = [
    'Trouve les descendants de mon grand-père',
    'Familles liées au village de Bafoussam',
    'Personnages historiques de la région du Centre',
    'Descendants des Bamiléké',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _traditionCtrl.dispose();
    _nomCtrl.dispose();
    _clanCtrl.dispose();
    super.dispose();
  }

  // ── RECHERCHE NATURELLE ──────────────────────────────────────────────
  Future<void> _search() async {
    final requete = _searchCtrl.text.trim();
    if (requete.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _searchPersons = [];
    });

    try {
      final response = await apiClient.post('/ai/search', data: {'requete': requete});
      final data = response.data['data'];
      final intention = data['interpretation']?['intention'] ?? 'PERSONNE';
      final resultats = data['resultats'] as List? ?? [];

      setState(() {
        _searchPersons = resultats;
        _searchResult = 'Intention détectée : $intention — ${resultats.length} résultat(s)';
      });
    } on DioException catch (e) {
      setState(() => _searchResult = 'Erreur : ${ApiClient.extractError(e)}');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // ── ASSISTANT CULTUREL ────────────────────────────────────────────────
  Future<void> _askCulture(String endpoint, Map<String, dynamic> body) async {
    setState(() { _isAsking = true; _assistantResult = null; });
    try {
      final response = await apiClient.post(endpoint, data: body);
      final data = response.data['data'] as Map<String, dynamic>;
      setState(() => _assistantResult =
          (data['explication'] ?? data['resume'] ?? 'Aucune réponse') as String);
    } on DioException catch (e) {
      setState(() => _assistantResult = 'Erreur : ${ApiClient.extractError(e)}');
    } finally {
      setState(() => _isAsking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORIGINE AI'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppConstants.routeAIChat),
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.orClair, size: 18),
            label: const Text('Chat', style: TextStyle(color: AppColors.orClair)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.or,
          labelColor: AppColors.orClair,
          unselectedLabelColor: AppColors.blanc.withOpacity(0.6),
          tabs: const [
            Tab(text: '🔍 Recherche'),
            Tab(text: '🏛️ Traditions'),
            Tab(text: '🔤 Noms & Clans'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRechercheTab(),
          _buildTraditionsTab(),
          _buildNomsTab(),
        ],
      ),
    );
  }

  // ── TAB : RECHERCHE NATURELLE ─────────────────────────────────────────
  Widget _buildRechercheTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte héro
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.vertForet, AppColors.vertClair],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.or, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Recherche intelligente',
                      style: TextStyle(
                        color: AppColors.blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Posez une question en langage naturel. L\'IA comprend et cherche pour vous.',
                  style: TextStyle(
                    color: AppColors.blanc.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Barre de recherche
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Ex : Trouve les descendants de...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.gris),
                    filled: true,
                    fillColor: AppColors.blanc,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grisClair),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grisClair),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.or, width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _isSearching ? null : _search,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.or,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.noir,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: AppColors.noir, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Exemples de requêtes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _exemples.map((ex) => GestureDetector(
              onTap: () {
                _searchCtrl.text = ex;
                _search();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blanc,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.grisClair),
                ),
                child: Text(
                  ex,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.vertForet,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // Résultats
          if (_searchResult != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.vertForet.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.vertForet.withOpacity(0.2)),
              ),
              child: Text(
                _searchResult!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.vertForet,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_searchPersons.isNotEmpty)
              ...(_searchPersons.map((p) => _buildPersonResult(p)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonResult(dynamic p) {
    final nom = '${p['prenom'] ?? ''} ${p['nom'] ?? ''}'.trim();
    final date = p['date_naissance'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grisClair),
      ),
      child: Row(
        children: [
          AppAvatar(
            initials: nom.isNotEmpty ? nom[0] : '?',
            radius: 18,
            backgroundColor: AppColors.vertForet,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (date != null)
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.gris)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gris),
        ],
      ),
    );
  }

  // ── TAB : TRADITIONS ─────────────────────────────────────────────────
  Widget _buildTraditionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssistantHeader(
            icon: '🏛️',
            title: 'Assistant Culturel',
            desc: 'Explorez les traditions et coutumes du Cameroun.',
          ),
          const SizedBox(height: 20),
          Text('Nom de la tradition',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Ex : Ngondo, Nguon, Dot...',
                  controller: _traditionCtrl,
                ),
              ),
              const SizedBox(width: 10),
              _AskButton(
                isLoading: _isAsking,
                onPressed: () => _askCulture(
                  '/ai/culture/tradition',
                  {'nom': _traditionCtrl.text.trim()},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isAsking && _tabController.index == 1)
            const AppLoader()
          else if (_assistantResult != null && _tabController.index == 1)
            _buildResultCard(_assistantResult!),
          const SizedBox(height: 24),
          _buildTraditionsGrid(),
        ],
      ),
    );
  }

  Widget _buildTraditionsGrid() {
    final traditions = [
      {'label': 'Ngondo', 'emoji': '🌊'},
      {'label': 'Nguon', 'emoji': '👑'},
      {'label': 'Dot', 'emoji': '💍'},
      {'label': 'Lela', 'emoji': '🛡️'},
      {'label': 'Ekang', 'emoji': '🌿'},
      {'label': 'Esani', 'emoji': '🎭'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Traditions populaires',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.4,
          children: traditions.map((t) => GestureDetector(
            onTap: () {
              _traditionCtrl.text = t['label']!;
              _tabController.animateTo(1);
              _askCulture('/ai/culture/tradition', {'nom': t['label']});
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blanc,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.grisClair),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t['emoji']!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    t['label']!,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ── TAB : NOMS & CLANS ───────────────────────────────────────────────
  Widget _buildNomsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssistantHeader(
            icon: '🔤',
            title: 'Signification des noms',
            desc: 'Découvrez l\'origine et la signification des noms camerounais.',
          ),
          const SizedBox(height: 20),

          // Noms
          Text('Signification d\'un nom',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Ex : Mbarga, Atangana, Ngo...',
                  controller: _nomCtrl,
                ),
              ),
              const SizedBox(width: 10),
              _AskButton(
                isLoading: _isAsking,
                onPressed: () => _askCulture(
                  '/ai/culture/name-meaning',
                  {'nom': _nomCtrl.text.trim()},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Clans
          Text('Signification d\'un clan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Ex : Beti, Bassa, Fulbe...',
                  controller: _clanCtrl,
                ),
              ),
              const SizedBox(width: 10),
              _AskButton(
                isLoading: _isAsking,
                onPressed: () => _askCulture(
                  '/ai/culture/clan',
                  {'nom': _clanCtrl.text.trim()},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isAsking && _tabController.index == 2)
            const AppLoader()
          else if (_assistantResult != null && _tabController.index == 2)
            _buildResultCard(_assistantResult!),

          const SizedBox(height: 24),
          _buildNomsPopulaires(),
        ],
      ),
    );
  }

  Widget _buildNomsPopulaires() {
    final noms = [
      'Mbarga', 'Atangana', 'Ngo', 'Biya', 'Ndongo',
      'Tchouaffé', 'Essomba', 'Djoumessi',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Noms populaires',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: noms.map((nom) => GestureDetector(
            onTap: () {
              _nomCtrl.text = nom;
              _tabController.animateTo(2);
              _askCulture('/ai/culture/name-meaning', {'nom': nom});
            },
            child: Chip(
              label: Text(nom,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              backgroundColor: AppColors.vertForet.withOpacity(0.08),
              side: const BorderSide(color: AppColors.vertForet, width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ── HELPERS UI ────────────────────────────────────────────────────────
  Widget _buildAssistantHeader({
    required String icon,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.vertForet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(desc,
                  style: const TextStyle(fontSize: 11, color: AppColors.gris)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grisClair),
        boxShadow: [
          BoxShadow(
            color: AppColors.vertForet.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.or, size: 16),
              const SizedBox(width: 6),
              Text('ORIGINE AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gris,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.noir),
          ),
        ],
      ),
    );
  }
}

class _AskButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _AskButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.vertForet,
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.blanc),
              )
            : const Icon(Icons.search, color: AppColors.blanc, size: 20),
      ),
    );
  }
}
