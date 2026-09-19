import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:origine/features/genealogy/presentation/widgets/family_tree_layout.dart';
import 'package:origine/shared/models/person_model.dart';

PersonModel p(int id, String nom, String sexe, [String? born]) => PersonModel(
      id: id, nom: nom, sexe: sexe, vivant: true, dateNaissance: born);

// Le backend enregistre chaque lien dans les deux sens.
List<TreeEdge> parentOf(int parent, int child, {String type = 'PERE'}) => [
      TreeEdge(source: parent, target: child, type: 'ENFANT'),
      TreeEdge(source: child, target: parent, type: type),
    ];
List<TreeEdge> spouses(int a, int b) => [
      TreeEdge(source: a, target: b, type: 'CONJOINT'),
      TreeEdge(source: b, target: a, type: 'CONJOINT'),
    ];

void main() {
  test('arbre sur 3 générations : niveaux, couples et enfants centrés', () {
    // 1+2 grands-parents ; enfants 3 (Paul), 4 (Anne) ; Paul + 5 (Marie) ;
    // leurs enfants 6, 7, 8 ; Anne + 9 (Luc) ; enfant 10.
    final tree = FamilyTreeModel(
      nodes: [
        p(1, 'GrandPere', 'M', '1930-01-01'), p(2, 'GrandMere', 'F', '1932-01-01'),
        p(3, 'Paul', 'M', '1955-01-01'), p(4, 'Anne', 'F', '1958-01-01'),
        p(5, 'Marie', 'F', '1957-01-01'),
        p(6, 'Enf1', 'M', '1980-01-01'), p(7, 'Enf2', 'F', '1983-01-01'), p(8, 'Enf3', 'M', '1986-01-01'),
        p(9, 'Luc', 'M', '1956-01-01'), p(10, 'Cousin', 'F', '1985-01-01'),
      ],
      edges: [
        ...spouses(1, 2),
        ...parentOf(1, 3), ...parentOf(2, 3, type: 'MERE'),
        ...parentOf(1, 4), ...parentOf(2, 4, type: 'MERE'),
        ...spouses(3, 5),
        ...parentOf(3, 6), ...parentOf(5, 6, type: 'MERE'),
        ...parentOf(3, 7), ...parentOf(5, 7, type: 'MERE'),
        ...parentOf(3, 8), ...parentOf(5, 8, type: 'MERE'),
        ...spouses(4, 9),
        ...parentOf(4, 10, type: 'MERE'), ...parentOf(9, 10),
      ],
    );

    final l = computeTreeLayout(tree);
    expect(l.positions.length, 10);

    double y(int id) => l.positions[id]!.dy;
    double x(int id) => l.positions[id]!.dx;

    // Générations
    expect(y(1), y(2));
    expect(y(3), greaterThan(y(1)));
    expect(y(3), y(4));
    expect(y(5), y(3)); // conjoint sur la même ligne
    expect(y(6), greaterThan(y(3)));
    expect(y(10), y(6));

    // Couples adjacents
    expect((x(1) - x(2)).abs(), kNodeW + kCoupleGap);
    expect((x(3) - x(5)).abs(), kNodeW + kCoupleGap);

    // Aucun chevauchement de cartes
    final rects = l.positions.values.map((o) => Rect.fromLTWH(o.dx, o.dy, kNodeW, kNodeH)).toList();
    for (var i = 0; i < rects.length; i++) {
      for (var j = i + 1; j < rects.length; j++) {
        expect(rects[i].overlaps(rects[j]), isFalse, reason: 'cartes $i et $j se chevauchent');
      }
    }

    // Les trois enfants de Paul/Marie sont centrés sous le couple
    final coupleCenter = (x(3) < x(5) ? x(3) : x(5)) + (kNodeW * 2 + kCoupleGap) / 2;
    final kidsCenter = (x(6) + x(8) + kNodeW) / 2;
    expect((coupleCenter - kidsCenter).abs(), lessThan(1));

    // Ordre des frères et sœurs par date de naissance
    expect(x(6), lessThan(x(7)));
    expect(x(7), lessThan(x(8)));
    // Paul (1955) à gauche d'Anne (1958)
    expect(x(3), lessThan(x(4)));

    expect(l.marriages.length, 3);
    expect(l.connectors.where((c) => !c.secondary).length, 6); // Paul, Anne + 4 petits-enfants
    expect(l.size.width, greaterThan(0));
  });

  test('arbre vide et personne isolée', () {
    expect(computeTreeLayout(const FamilyTreeModel(nodes: [], edges: [])).positions, isEmpty);
    final one = computeTreeLayout(FamilyTreeModel(nodes: [p(1, 'Seul', 'M')], edges: const []));
    expect(one.positions.length, 1);
    expect(one.connectors, isEmpty);
  });

  test('données incohérentes (cycle) ne plantent pas', () {
    final t = FamilyTreeModel(
      nodes: [p(1, 'A', 'M'), p(2, 'B', 'M')],
      edges: [...parentOf(1, 2), ...parentOf(2, 1)],
    );
    expect(() => computeTreeLayout(t), returnsNormally);
  });
}
