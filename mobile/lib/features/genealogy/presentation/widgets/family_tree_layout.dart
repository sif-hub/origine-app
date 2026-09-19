// lib/features/genealogy/presentation/widgets/family_tree_layout.dart
//
// Calcul de la mise en page d'un arbre généalogique : une ligne par
// génération, couples côte à côte, enfants centrés sous leurs parents.
// Logique pure (sans widget) pour rester testable.

import 'dart:ui';

import '../../../../shared/models/person_model.dart';

const double kNodeW = 132;
const double kNodeH = 66;
const double kCoupleGap = 28;
const double kSiblingGap = 24;
const double kGenerationGap = 90;
const double kMargin = 24;

class TreeConnector {
  /// Point de départ (bas du/des parent(s)).
  final Offset from;

  /// Point d'arrivée (haut de l'enfant).
  final Offset to;

  /// Ordonnée du trait horizontal commun aux frères et sœurs.
  final double busY;

  /// Lien secondaire (second parent hors du couple) : tracé en pointillé.
  final bool secondary;

  const TreeConnector(this.from, this.to, this.busY, {this.secondary = false});
}

class TreeLayout {
  final Map<int, Offset> positions;
  final List<(Offset, Offset)> marriages;
  final List<TreeConnector> connectors;
  final Size size;

  const TreeLayout({
    required this.positions,
    required this.marriages,
    required this.connectors,
    required this.size,
  });
}

class _Unit {
  final List<int> members;
  int level = 0;
  _Unit? parent;
  final List<_Unit> children = [];
  double subtreeW = 0;
  double x = 0;

  _Unit(this.members);

  double get width => members.length * kNodeW + (members.length - 1) * kCoupleGap;
}

TreeLayout computeTreeLayout(FamilyTreeModel tree) {
  final byId = {for (final p in tree.nodes) p.id: p};
  final ids = byId.keys.toList();
  if (ids.isEmpty) {
    return const TreeLayout(positions: {}, marriages: [], connectors: [], size: Size.zero);
  }

  final parentsOf = <int, Set<int>>{for (final id in ids) id: {}};
  final spouseOf = <int, Set<int>>{for (final id in ids) id: {}};
  final siblingPairs = <(int, int)>[];
  final grandParentPairs = <(int, int)>[];

  for (final e in tree.edges) {
    if (!byId.containsKey(e.source) || !byId.containsKey(e.target) || e.source == e.target) continue;
    switch (e.type) {
      case 'ENFANT':
        parentsOf[e.target]!.add(e.source);
        break;
      case 'PERE':
      case 'MERE':
        parentsOf[e.source]!.add(e.target);
        break;
      case 'CONJOINT':
        spouseOf[e.source]!.add(e.target);
        spouseOf[e.target]!.add(e.source);
        break;
      case 'FRERE_SOEUR':
        siblingPairs.add((e.source, e.target));
        break;
      case 'GRAND_PARENT':
        grandParentPairs.add((e.source, e.target));
        break;
    }
  }

  // ── Générations : un enfant est toujours sous ses parents ────────────
  final level = {for (final id in ids) id: 0};
  final maxLevel = ids.length;
  for (var round = 0; round < ids.length + 5; round++) {
    var changed = false;
    void raise(int id, int value) {
      if (value > level[id]! && value <= maxLevel) {
        level[id] = value;
        changed = true;
      }
    }

    parentsOf.forEach((child, parents) {
      for (final p in parents) {
        raise(child, level[p]! + 1);
      }
    });
    spouseOf.forEach((a, spouses) {
      for (final b in spouses) {
        final m = level[a]! > level[b]! ? level[a]! : level[b]!;
        raise(a, m);
        raise(b, m);
      }
    });
    for (final (a, b) in siblingPairs) {
      final m = level[a]! > level[b]! ? level[a]! : level[b]!;
      raise(a, m);
      raise(b, m);
    }
    for (final (person, grand) in grandParentPairs) {
      raise(person, level[grand]! + 2);
    }
    if (!changed) break;
  }

  // ── Unités : un individu seul, ou un groupe de conjoints ─────────────
  int birthOrder(int id) {
    final d = byId[id]!.dateNaissance;
    return d == null ? 1 << 30 : (int.tryParse(d.replaceAll('-', '').padRight(8, '0').substring(0, 8)) ?? 1 << 30);
  }

  final unitOf = <int, _Unit>{};
  final units = <_Unit>[];
  final seen = <int>{};
  for (final id in ids) {
    if (seen.contains(id)) continue;
    final group = <int>[];
    final stack = [id];
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      if (!seen.add(cur)) continue;
      group.add(cur);
      stack.addAll(spouseOf[cur]!);
    }
    // Le membre "de sang" (qui a des parents dans l'arbre) est placé en premier
    // s'il est seul de ce cas, sinon tri par date de naissance.
    group.sort((a, b) {
      final pa = parentsOf[a]!.isNotEmpty ? 0 : 1;
      final pb = parentsOf[b]!.isNotEmpty ? 0 : 1;
      if (group.length == 2 && pa != pb) return pa - pb;
      final c = birthOrder(a).compareTo(birthOrder(b));
      return c != 0 ? c : a.compareTo(b);
    });
    final unit = _Unit(group)..level = group.map((m) => level[m]!).reduce((a, b) => a > b ? a : b);
    units.add(unit);
    for (final m in group) {
      unitOf[m] = unit;
    }
  }

  // ── Rattachement de chaque unité à l'unité de ses parents ────────────
  final anchorMember = <_Unit, int>{};
  for (final u in units) {
    for (final m in u.members) {
      for (final p in parentsOf[m]!) {
        final pu = unitOf[p]!;
        if (identical(pu, u) || pu.level >= u.level) continue;
        if (u.parent == null) {
          u.parent = pu;
          anchorMember[u] = m;
          pu.children.add(u);
        }
      }
      if (u.parent != null) break;
    }
  }
  int unitBirth(_Unit u) => u.members.map(birthOrder).reduce((a, b) => a < b ? a : b);
  for (final u in units) {
    u.children.sort((a, b) => unitBirth(a).compareTo(unitBirth(b)));
  }

  // ── Largeurs puis positions ──────────────────────────────────────────
  double measure(_Unit u) {
    var total = 0.0;
    for (var i = 0; i < u.children.length; i++) {
      total += measure(u.children[i]);
      if (i > 0) total += kSiblingGap;
    }
    u.subtreeW = total > u.width ? total : u.width;
    return u.subtreeW;
  }

  void place(_Unit u, double left) {
    u.x = left + (u.subtreeW - u.width) / 2;
    var childrenW = 0.0;
    for (var i = 0; i < u.children.length; i++) {
      childrenW += u.children[i].subtreeW + (i > 0 ? kSiblingGap : 0);
    }
    var cursor = left + (u.subtreeW - childrenW) / 2;
    for (final c in u.children) {
      place(c, cursor);
      cursor += c.subtreeW + kSiblingGap;
    }
  }

  final roots = units.where((u) => u.parent == null).toList()
    ..sort((a, b) => unitBirth(a).compareTo(unitBirth(b)));
  var cursor = kMargin;
  for (final r in roots) {
    measure(r);
    place(r, cursor);
    cursor += r.subtreeW + kSiblingGap * 2;
  }

  final positions = <int, Offset>{};
  final marriages = <(Offset, Offset)>[];
  var maxX = 0.0;
  var maxLvl = 0;
  for (final u in units) {
    final y = kMargin + u.level * (kNodeH + kGenerationGap);
    for (var i = 0; i < u.members.length; i++) {
      final x = u.x + i * (kNodeW + kCoupleGap);
      positions[u.members[i]] = Offset(x, y);
      if (x + kNodeW > maxX) maxX = x + kNodeW;
      if (i > 0) {
        marriages.add((
          Offset(x - kCoupleGap, y + kNodeH / 2),
          Offset(x, y + kNodeH / 2),
        ));
      }
    }
    if (u.level > maxLvl) maxLvl = u.level;
  }

  // ── Connecteurs parents → enfants ────────────────────────────────────
  final connectors = <TreeConnector>[];
  for (final u in units) {
    final parentUnit = u.parent;
    final childId = anchorMember[u];
    if (parentUnit == null || childId == null) continue;
    final childPos = positions[childId]!;
    final realParents = parentsOf[childId]!.where((p) => identical(unitOf[p], parentUnit)).toList();
    final busY = positions[parentUnit.members.first]!.dy + kNodeH + kGenerationGap / 2;

    Offset from;
    if (realParents.length >= 2) {
      final a = positions[realParents[0]]!;
      final b = positions[realParents[1]]!;
      final left = a.dx < b.dx ? a : b;
      final right = a.dx < b.dx ? b : a;
      from = Offset((left.dx + kNodeW + right.dx) / 2, left.dy + kNodeH / 2);
    } else {
      final p = positions[realParents.first]!;
      from = Offset(p.dx + kNodeW / 2, p.dy + kNodeH);
    }
    connectors.add(TreeConnector(from, Offset(childPos.dx + kNodeW / 2, childPos.dy), busY));
  }

  // Second parent situé dans une autre unité (non conjoint) : lien pointillé.
  for (final id in ids) {
    final unit = unitOf[id]!;
    final main = anchorMember[unit];
    if (main != id) continue;
    for (final p in parentsOf[id]!) {
      final pu = unitOf[p]!;
      if (identical(pu, unit.parent) || pu.level >= unit.level) continue;
      final pp = positions[p]!;
      final cp = positions[id]!;
      connectors.add(TreeConnector(
        Offset(pp.dx + kNodeW / 2, pp.dy + kNodeH),
        Offset(cp.dx + kNodeW / 2, cp.dy),
        pp.dy + kNodeH + kGenerationGap / 2 + 10,
        secondary: true,
      ));
    }
  }

  return TreeLayout(
    positions: positions,
    marriages: marriages,
    connectors: connectors,
    size: Size(
      (maxX > cursor - kSiblingGap * 2 ? maxX : cursor - kSiblingGap * 2) + kMargin,
      kMargin * 2 + (maxLvl + 1) * kNodeH + maxLvl * kGenerationGap,
    ),
  );
}
