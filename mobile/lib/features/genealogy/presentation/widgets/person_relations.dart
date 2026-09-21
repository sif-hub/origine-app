// lib/features/genealogy/presentation/widgets/person_relations.dart
//
// Liens familiaux d'un membre, déduits des arêtes de l'arbre (le backend
// enregistre chaque lien dans les deux sens).

import '../../../../shared/models/person_model.dart';

class PersonRelations {
  final List<PersonModel> parents;
  final List<PersonModel> spouses;
  final List<PersonModel> children;
  final List<PersonModel> siblings;

  const PersonRelations({
    required this.parents,
    required this.spouses,
    required this.children,
    required this.siblings,
  });

  bool get isEmpty => parents.isEmpty && spouses.isEmpty && children.isEmpty && siblings.isEmpty;
}

PersonRelations relationsOf(int personId, FamilyTreeModel tree) {
  final byId = {for (final n in tree.nodes) n.id: n};
  final parentsOf = <int, Set<int>>{};
  final spouses = <int>{};
  final siblings = <int>{};

  for (final e in tree.edges) {
    if (!byId.containsKey(e.source) || !byId.containsKey(e.target) || e.source == e.target) continue;
    switch (e.type) {
      case 'ENFANT':
        parentsOf.putIfAbsent(e.target, () => {}).add(e.source);
        break;
      case 'PERE':
      case 'MERE':
        parentsOf.putIfAbsent(e.source, () => {}).add(e.target);
        break;
      case 'CONJOINT':
        if (e.source == personId) spouses.add(e.target);
        if (e.target == personId) spouses.add(e.source);
        break;
      case 'FRERE_SOEUR':
        if (e.source == personId) siblings.add(e.target);
        if (e.target == personId) siblings.add(e.source);
        break;
    }
  }

  final myParents = parentsOf[personId] ?? <int>{};
  final children = <int>{
    for (final entry in parentsOf.entries)
      if (entry.value.contains(personId)) entry.key,
  };
  // Frères et sœurs : liens explicites + enfants d'un même parent.
  for (final entry in parentsOf.entries) {
    if (entry.key != personId && entry.value.any(myParents.contains)) siblings.add(entry.key);
  }

  List<PersonModel> resolve(Iterable<int> ids) {
    final list = ids.map((id) => byId[id]).whereType<PersonModel>().toList();
    list.sort((a, b) => (a.dateNaissance ?? '9999').compareTo(b.dateNaissance ?? '9999'));
    return list;
  }

  return PersonRelations(
    parents: resolve(myParents),
    spouses: resolve(spouses),
    children: resolve(children),
    siblings: resolve(siblings),
  );
}
