// lib/features/home/presentation/screens/home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/home_navigation.dart';
import '../../../auth/domain/auth_bloc.dart';
import '../../../genealogy/presentation/screens/genealogy_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../ai/presentation/screens/ai_screen.dart';
import '../../../../shared/models/user_model.dart';
import '../../../stories/data/stories_repository.dart';
import '../../../stories/domain/stories_bloc.dart';
import '../../../stories/presentation/screens/add_story_wizard_screen.dart';
import '../../../stories/presentation/widgets/story_card.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../family_chat/presentation/screens/family_groups_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    homeTabRequest.addListener(_onTabRequest);
  }

  @override
  void dispose() {
    homeTabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final tab = homeTabRequest.value;
    if (tab == null) return;
    homeTabRequest.value = null;
    if (mounted) setState(() => _currentIndex = tab);
  }

  final List<Widget> _pages = const [
    _DashboardTab(),
    GenealogyScreen(),
    AiScreen(),
    FamilyGroupsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_outlined),
            activeIcon: Icon(Icons.account_tree_rounded),
            label: 'Arbre',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'ORIGINE AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Famille',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ─── TAB DASHBOARD ────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StoriesBloc(StoriesRepository())..add(LoadFeed()),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.or,
            foregroundColor: AppColors.noir,
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AddStoryWizardScreen(),
              ));
              if (context.mounted) context.read<StoriesBloc>().add(RefreshFeed());
            },
            child: const Icon(Icons.add),
          ),
          body: CustomScrollView(
            slivers: [
              // AppBar déroulant avec dégradé vert
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.vertForet,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.vertForet, AppColors.surfaceSombre],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Bonjour, ${user?.prenom ?? ''}  👋',
                              style: const TextStyle(
                                color: AppColors.orClair,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'ORIGINE',
                              style: TextStyle(
                                color: AppColors.blanc,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const Text(
                              'Vos racines, votre histoire',
                              style: TextStyle(
                                color: AppColors.blanc,
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.blanc),
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle(context, 'Accès rapide'),
                    const SizedBox(height: 16),
                    _buildQuickAccess(context),
                    const SizedBox(height: 28),
                    _buildSectionTitle(context, 'ORIGINE AI'),
                    const SizedBox(height: 12),
                    _buildAiCard(context),
                    const SizedBox(height: 28),
                    _buildSectionTitle(context, 'Découvrez les histoires que raconte le Cameroun'),
                    const SizedBox(height: 12),
                    const _StorySearchBar(),
                    const SizedBox(height: 12),
                    _buildStoriesFeed(context),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      _QuickItem(
        icon: Icons.account_tree_rounded,
        label: 'Arbre\ngénéalogique',
        color: AppColors.vertForet,
        onTap: () => context.go(AppConstants.routeGenealogy),
      ),
      _QuickItem(
        icon: Icons.auto_awesome,
        label: 'ORIGINE\nAI',
        color: AppColors.or,
        onTap: () => context.go(AppConstants.routeAI),
      ),
      _QuickItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chatbot\nIA',
        color: AppColors.vertClair,
        onTap: () => context.go(AppConstants.routeAIChat),
      ),
      _QuickItem(
        icon: Icons.person_rounded,
        label: 'Mon\nProfil',
        color: AppColors.gris,
        onTap: () => context.go(AppConstants.routeProfile),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: items.map((item) => _QuickAccessTile(item: item)).toList(),
    );
  }

  Widget _buildAiCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppConstants.routeAIChat),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.vertForet, AppColors.vertClair],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORIGINE AI 🌿',
                    style: TextStyle(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Posez une question sur votre arbre, vos ancêtres ou la culture camerounaise.',
                    style: TextStyle(
                      color: AppColors.blanc.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.or,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Démarrer une conversation',
                      style: TextStyle(
                        color: AppColors.noir,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.auto_awesome, color: AppColors.or, size: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesFeed(BuildContext context) {
    return BlocBuilder<StoriesBloc, StoriesState>(
      builder: (context, state) {
        if (state is StoriesLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppLoader(),
          );
        }
        if (state is StoriesError) {
          return AppBanner(message: state.message);
        }
        if (state is StoriesLoaded) {
          if (state.stories.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aucune histoire trouvée.')),
            );
          }
          final authState = context.read<AuthBloc>().state;
          final me = authState is AuthAuthenticated ? authState.user : null;
          return Column(
            children: state.stories
                .map((story) => StoryCard(
                      key: ValueKey(story.id),
                      story: story,
                      onLikeToggle: () => context.read<StoriesBloc>().add(ToggleLike(story.id)),
                      onDelete: me != null && (me.role == 'ADMIN' || me.id == story.author.id)
                          ? () => context.read<StoriesBloc>().add(DeleteStory(story.id))
                          : null,
                    ))
                .toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Souhaitez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.erreur),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
              context.go(AppConstants.routeLogin);
            },
            child: const Text('Déconnecter', style: TextStyle(color: AppColors.blanc)),
          ),
        ],
      ),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickAccessTile extends StatelessWidget {
  final _QuickItem item;
  const _QuickAccessTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}


class _StorySearchBar extends StatefulWidget {
  const _StorySearchBar();

  @override
  State<_StorySearchBar> createState() => _StorySearchBarState();
}

class _StorySearchBarState extends State<_StorySearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) context.read<StoriesBloc>().add(SearchFeed(value));
    });
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: (v) => context.read<StoriesBloc>().add(SearchFeed(v)),
      decoration: InputDecoration(
        hintText: 'Rechercher une histoire (titre, région, auteur...)',
        prefixIcon: const Icon(Icons.search, color: AppColors.gris),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  context.read<StoriesBloc>().add(const SearchFeed(''));
                  setState(() {});
                },
              ),
      ),
    );
  }
}
