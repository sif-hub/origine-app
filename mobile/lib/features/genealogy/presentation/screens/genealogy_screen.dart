// lib/features/genealogy/presentation/screens/genealogy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/genealogy_repository.dart';
import '../../domain/genealogy_bloc.dart';
import 'add_member_wizard_screen.dart';
import 'family_documents_screen.dart';
import 'family_gallery_screen.dart';
import 'family_privacy_screen.dart';

class GenealogyScreen extends StatelessWidget {
  final String? familyId;
  const GenealogyScreen({super.key, this.familyId});

  @override
  Widget build(BuildContext context) {
    final preferredId = familyId != null ? int.tryParse(familyId!) : null;
    return BlocProvider(
      create: (_) => GenealogyBloc(GenealogyRepository())
        ..add(LoadFamilies(preferredFamilyId: preferredId)),
      child: const _GenealogyView(),
    );
  }
}

class _GenealogyView extends StatefulWidget {
  const _GenealogyView();

  @override
  State<_GenealogyView> createState() => _GenealogyViewState();
}

class _GenealogyViewState extends State<_GenealogyView> {
  String _view = 'list'; // list | tree

  void _refresh() => context.read<GenealogyBloc>().add(RefreshTree());

  Future<void> _openWizard(
    BuildContext context, {
    required int familyId,
    required List<PersonModel> existingPersons,
    PersonModel? referencePerson,
    String? relationType,
  }) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddMemberWizardScreen(
        familyId: familyId,
        existingPersons: existingPersons,
        initialReferencePerson: referencePerson,
        initialRelationType: relationType,
      ),
    ));
    if (context.mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arbre Généalogique'),
        actions: [
          IconButton(
            icon: Icon(
              _view == 'list' ? Icons.account_tree_rounded : Icons.list_rounded,
            ),
            tooltip: _view == 'list' ? 'Vue arbre' : 'Vue liste',
            onPressed: () => setState(() => _view = _view == 'list' ? 'tree' : 'list'),
          ),
          BlocBuilder<GenealogyBloc, GenealogyState>(
            builder: (context, state) {
              final familyId = _familyIdOf(state);
              final nodes = _nodesOf(state);
              return IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Ajouter un membre',
                onPressed: familyId == null
                    ? null
                    : () => _openWizard(context, familyId: familyId, existingPersons: nodes),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<GenealogyBloc, GenealogyState>(
        builder: (context, state) {
          if (state is GenealogyLoading || state is GenealogyInitial) {
            return const AppLoader();
          }
          if (state is GenealogyError) {
            return Center(child: AppBanner(message: state.message));
          }

          final families = state is GenealogyLoaded
              ? state.families
              : state is GenealogyEmpty
                  ? state.families
                  : <FamilyModel>[];
          final selectedFamily = state is GenealogyLoaded
              ? state.selectedFamily
              : state is GenealogyEmpty
                  ? state.selectedFamily
                  : null;

          return Column(
            children: [
              if (families.isNotEmpty && selectedFamily != null)
                _buildFamilySelector(context, families, selectedFamily),
              if (selectedFamily != null) _buildQuickAccessBar(context, selectedFamily),
              Expanded(
                child: state is GenealogyEmpty
                    ? _buildEmptyState(context, selectedFamily!, [])
                    : state is GenealogyLoaded
                        ? (_view == 'tree' ? _buildTreeView(state.tree) : _buildListView(context, state))
                        : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  int? _familyIdOf(GenealogyState state) {
    if (state is GenealogyLoaded) return state.selectedFamily.id;
    if (state is GenealogyEmpty) return state.selectedFamily.id;
    return null;
  }

  List<PersonModel> _nodesOf(GenealogyState state) {
    if (state is GenealogyLoaded) return state.tree.nodes;
    return const [];
  }

  Widget _buildFamilySelector(
      BuildContext context, List<FamilyModel> families, FamilyModel selected) {
    return Container(
      color: AppColors.blanc,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.family_restroom, color: AppColors.vertForet, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<FamilyModel>(
              value: selected,
              isExpanded: true,
              underline: const SizedBox(),
              items: families
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.nom, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (f) {
                if (f != null) context.read<GenealogyBloc>().add(SelectFamily(f));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessBar(BuildContext context, FamilyModel family) {
    Widget action(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, color: AppColors.vertForet, size: 20),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gris)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.blanc,
      child: Row(
        children: [
          action(Icons.photo_library_outlined, 'Photos', () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FamilyGalleryScreen(familyId: family.id),
            ));
          }),
          action(Icons.description_outlined, 'Documents', () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FamilyDocumentsScreen(familyId: family.id),
            ));
          }),
          action(Icons.collections_outlined, 'Souvenirs', () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FamilyGalleryScreen(familyId: family.id),
            ));
          }),
          action(Icons.settings_outlined, 'Paramètres', () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FamilyPrivacyScreen(family: family),
            ));
            if (context.mounted) _refresh();
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FamilyModel family, List<PersonModel> nodes) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_outlined, size: 64, color: AppColors.grisClair),
          const SizedBox(height: 16),
          Text('Votre arbre est vide', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Commencez par ajouter une personne.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            child: AppPrimaryButton(
              label: '+ Ajouter un membre',
              onPressed: () => _openWizard(context, familyId: family.id, existingPersons: nodes),
              backgroundColor: AppColors.vertForet,
            ),
          ),
        ],
      ),
    );
  }

  // ── VUE LISTE ──────────────────────────────────────────────────────
  Widget _buildListView(BuildContext context, GenealogyLoaded state) {
    final nodes = state.tree.nodes;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: nodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _PersonTile(
        person: nodes[index],
        onAddRelation: () => _showAddRelationDialog(context, state, nodes[index]),
      ),
    );
  }

  // ── VUE ARBRE (Canvas simplifié) ────────────────────────────────────
  Widget _buildTreeView(FamilyTreeModel tree) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _TreeCanvas(tree: tree, onNodeTap: (person) {
          _showPersonDetails(context, tree, person);
        }),
      ),
    );
  }

  // ── DIALOGS ────────────────────────────────────────────────────────
  void _showAddRelationDialog(BuildContext context, GenealogyLoaded state, PersonModel person) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajouter un lien pour ${person.nomComplet}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ..._relationOptions.entries.map((entry) {
              return ListTile(
                leading: const Icon(Icons.add, color: AppColors.vertClair),
                title: Text(entry.value),
                onTap: () {
                  Navigator.pop(context);
                  _openWizard(
                    context,
                    familyId: state.selectedFamily.id,
                    existingPersons: state.tree.nodes,
                    referencePerson: person,
                    relationType: entry.key,
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  static const _relationOptions = {
    'PERE': 'Père',
    'MERE': 'Mère',
    'ENFANT': 'Enfant',
    'CONJOINT': 'Conjoint(e)',
    'FRERE_SOEUR': 'Frère / Sœur',
  };

  void _showPersonDetails(BuildContext context, FamilyTreeModel tree, PersonModel person) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  initials: person.nomComplet.isNotEmpty ? person.nomComplet[0] : '?',
                  radius: 22,
                  backgroundColor: person.sexe == 'M'
                      ? AppColors.vertForet
                      : person.sexe == 'F'
                          ? AppColors.erreur
                          : AppColors.gris,
                ),
                const SizedBox(width: 12),
                Text(person.nomComplet,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            if (person.dateNaissance != null) Text('Naissance : ${person.dateNaissance}'),
            if (person.dateDeces != null) Text('Décès : ${person.dateDeces}'),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Ajouter un lien familial',
              onPressed: () {
                Navigator.pop(context);
                final state = context.read<GenealogyBloc>().state;
                if (state is GenealogyLoaded) {
                  _showAddRelationDialog(context, state, person);
                }
              },
              backgroundColor: AppColors.vertForet,
            ),
          ],
        ),
      ),
    );
  }
}

// ── TUILE PERSONNE ─────────────────────────────────────────────────────
class _PersonTile extends StatelessWidget {
  final PersonModel person;
  final VoidCallback onAddRelation;

  const _PersonTile({required this.person, required this.onAddRelation});

  @override
  Widget build(BuildContext context) {
    final sexeColor = person.sexe == 'M'
        ? AppColors.vertForet
        : person.sexe == 'F'
            ? AppColors.erreur
            : AppColors.gris;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: AppAvatar(
          initials: person.nomComplet.isNotEmpty ? person.nomComplet[0] : '?',
          radius: 22,
          backgroundColor: sexeColor,
        ),
        title: Text(person.nomComplet,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          person.dateNaissance != null ? person.annees : 'Date inconnue',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: AppColors.or),
          onPressed: onAddRelation,
        ),
      ),
    );
  }
}

// ── CANVAS ARBRE GÉNÉALOGIQUE (flutter canvas simplifié) ───────────────
class _TreeCanvas extends StatelessWidget {
  final FamilyTreeModel tree;
  final void Function(PersonModel) onNodeTap;

  const _TreeCanvas({required this.tree, required this.onNodeTap});

  @override
  Widget build(BuildContext context) {
    if (tree.nodes.isEmpty) return const SizedBox.shrink();

    const nodeW = 130.0;
    const nodeH = 60.0;
    const hSpacing = 30.0;
    const vSpacing = 60.0;

    // Distribution simple : une colonne par génération
    final Map<int, int> levels = {};
    final Map<int, List<int>> nodesByLevel = {};

    for (int i = 0; i < tree.nodes.length; i++) {
      levels[tree.nodes[i].id] = 0;
    }
    for (final edge in tree.edges) {
      if (edge.type == 'ENFANT') {
        final parentLevel = levels[edge.source] ?? 0;
        if ((levels[edge.target] ?? 0) <= parentLevel) {
          levels[edge.target] = parentLevel + 1;
        }
      }
    }
    for (final node in tree.nodes) {
      final lvl = levels[node.id] ?? 0;
      nodesByLevel.putIfAbsent(lvl, () => []).add(node.id);
    }

    final positions = <int, Offset>{};
    for (final entry in nodesByLevel.entries) {
      final lvl = entry.key;
      final ids = entry.value;
      for (int i = 0; i < ids.length; i++) {
        positions[ids[i]] = Offset(
          i * (nodeW + hSpacing),
          lvl * (nodeH + vSpacing),
        );
      }
    }

    final maxX = positions.values.fold(0.0, (m, o) => o.dx > m ? o.dx : m) + nodeW;
    final maxY = positions.values.fold(0.0, (m, o) => o.dy > m ? o.dy : m) + nodeH;

    return SizedBox(
      width: maxX + 20,
      height: maxY + 20,
      child: Stack(
        children: [
          // Traits entre noeuds
          CustomPaint(
            size: Size(maxX + 20, maxY + 20),
            painter: _TreePainter(tree: tree, positions: positions,
                nodeW: nodeW, nodeH: nodeH),
          ),
          // Cartes personnes
          ...tree.nodes.map((node) {
            final pos = positions[node.id];
            if (pos == null) return const SizedBox.shrink();
            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onTap: () => onNodeTap(node),
                child: _NodeCard(person: node, width: nodeW, height: nodeH),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  final FamilyTreeModel tree;
  final Map<int, Offset> positions;
  final double nodeW;
  final double nodeH;

  const _TreePainter({
    required this.tree, required this.positions,
    required this.nodeW, required this.nodeH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.grisClair
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintConjoint = Paint()
      ..color = AppColors.or.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in tree.edges) {
      final from = positions[edge.source];
      final to = positions[edge.target];
      if (from == null || to == null) continue;

      final p = edge.type == 'CONJOINT' ? paintConjoint : paintLine;

      final start = Offset(from.dx + nodeW / 2, from.dy + nodeH / 2);
      final end = Offset(to.dx + nodeW / 2, to.dy + nodeH / 2);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, (start.dy + end.dy) / 2,
            end.dx, (start.dy + end.dy) / 2, end.dx, end.dy);

      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _NodeCard extends StatelessWidget {
  final PersonModel person;
  final double width;
  final double height;

  const _NodeCard({required this.person, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final borderColor = person.sexe == 'M'
        ? AppColors.vertForet
        : person.sexe == 'F'
            ? AppColors.erreur
            : AppColors.gris;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            person.nomComplet,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            person.dateNaissance != null ? person.annees : '?',
            style: const TextStyle(fontSize: 10, color: AppColors.gris),
          ),
        ],
      ),
    );
  }
}
