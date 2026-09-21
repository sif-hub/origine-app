import 'package:flutter_test/flutter_test.dart';
import 'package:origine/features/genealogy/presentation/widgets/person_relations.dart';
import 'package:origine/shared/models/person_model.dart';

PersonModel p(int id, String nom, [String? born]) =>
    PersonModel(id: id, nom: nom, sexe: 'M', vivant: true, dateNaissance: born);

List<TreeEdge> parentOf(int parent, int child) => [
      TreeEdge(source: parent, target: child, type: 'ENFANT'),
      TreeEdge(source: child, target: parent, type: 'PERE'),
    ];

void main() {
  test('parents, conjoint, enfants et fratrie déduits de l\'arbre', () {
    final tree = FamilyTreeModel(
      nodes: [p(1, 'Pere'), p(2, 'Mere'), p(3, 'Moi', '1980-01-01'), p(4, 'Frere', '1975-05-05'),
              p(5, 'Epouse'), p(6, 'Fils', '2010-01-01')],
      edges: [
        ...parentOf(1, 3), ...parentOf(2, 3), ...parentOf(1, 4), ...parentOf(2, 4),
        const TreeEdge(source: 3, target: 5, type: 'CONJOINT'),
        const TreeEdge(source: 5, target: 3, type: 'CONJOINT'),
        ...parentOf(3, 6), ...parentOf(5, 6),
      ],
    );
    final r = relationsOf(3, tree);
    expect(r.parents.map((x) => x.nom), containsAll(['Pere', 'Mere']));
    expect(r.spouses.map((x) => x.nom), ['Epouse']);
    expect(r.children.map((x) => x.nom), ['Fils']);
    expect(r.siblings.map((x) => x.nom), ['Frere']);
    expect(relationsOf(6, tree).parents.length, 2);
    expect(relationsOf(1, tree).children.map((x) => x.nom), ['Frere', 'Moi']);
  });

  test('personne isolée : aucun lien', () {
    final r = relationsOf(1, FamilyTreeModel(nodes: [p(1, 'Seul')], edges: const []));
    expect(r.isEmpty, isTrue);
  });
}
