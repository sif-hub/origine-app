// lib/shared/models/person_model.dart

import 'package:equatable/equatable.dart';

class PersonModel extends Equatable {
  final int id;
  final int? familyId;
  final String nom;
  final String? prenom;
  final String sexe;
  final String? dateNaissance;
  final String? dateDeces;
  final bool vivant;
  final String? photo;
  final String? notes;
  final String? lieuNaissance;
  final String? villageOrigine;
  final String? nationalite;
  final String? profession;
  final String? nomPereTexte;
  final String? nomMereTexte;
  final String visibilite;
  final bool peutVoir;
  final bool peutModifier;
  final bool peutAjouterDocuments;
  final bool peutAjouterSouvenirs;
  final bool peutCommenter;

  const PersonModel({
    required this.id,
    this.familyId,
    required this.nom,
    this.prenom,
    required this.sexe,
    this.dateNaissance,
    this.dateDeces,
    required this.vivant,
    this.photo,
    this.notes,
    this.lieuNaissance,
    this.villageOrigine,
    this.nationalite,
    this.profession,
    this.nomPereTexte,
    this.nomMereTexte,
    this.visibilite = 'PRIVE',
    this.peutVoir = true,
    this.peutModifier = false,
    this.peutAjouterDocuments = false,
    this.peutAjouterSouvenirs = true,
    this.peutCommenter = true,
  });

  String get nomComplet => '${prenom ?? ''} $nom'.trim();

  String get annees {
    final n = dateNaissance?.substring(0, 4) ?? '?';
    if (dateDeces != null) return '$n - ${dateDeces!.substring(0, 4)}';
    return n;
  }

  factory PersonModel.fromJson(Map<String, dynamic> json) => PersonModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        familyId: json['family_id'] != null
            ? int.tryParse(json['family_id'].toString())
            : null,
        nom: json['nom'] as String? ?? '',
        prenom: json['prenom'] as String?,
        sexe: json['sexe'] as String? ?? 'INCONNU',
        dateNaissance: json['date_naissance'] as String?,
        dateDeces: json['date_deces'] as String?,
        vivant: (json['vivant'] == 1 || json['vivant'] == true),
        photo: json['photo'] as String?,
        notes: json['notes'] as String?,
        lieuNaissance: json['lieu_naissance'] as String?,
        villageOrigine: json['village_origine'] as String?,
        nationalite: json['nationalite'] as String?,
        profession: json['profession'] as String?,
        nomPereTexte: json['nom_pere_texte'] as String?,
        nomMereTexte: json['nom_mere_texte'] as String?,
        visibilite: json['visibilite'] as String? ?? 'PRIVE',
        peutVoir: (json['peut_voir'] == null) ? true : (json['peut_voir'] == 1 || json['peut_voir'] == true),
        peutModifier: (json['peut_modifier'] == 1 || json['peut_modifier'] == true),
        peutAjouterDocuments:
            (json['peut_ajouter_documents'] == 1 || json['peut_ajouter_documents'] == true),
        peutAjouterSouvenirs: (json['peut_ajouter_souvenirs'] == null)
            ? true
            : (json['peut_ajouter_souvenirs'] == 1 || json['peut_ajouter_souvenirs'] == true),
        peutCommenter: (json['peut_commenter'] == null)
            ? true
            : (json['peut_commenter'] == 1 || json['peut_commenter'] == true),
      );

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prenom': prenom,
        'sexe': sexe,
        'date_naissance': dateNaissance,
        'date_deces': dateDeces,
        'family_id': familyId,
        'notes': notes,
        'photo': photo,
        'lieu_naissance': lieuNaissance,
        'village_origine': villageOrigine,
        'nationalite': nationalite,
        'profession': profession,
        'nom_pere_texte': nomPereTexte,
        'nom_mere_texte': nomMereTexte,
      }..removeWhere((key, value) => value == null);

  PersonModel copyWith({
    int? id,
    int? familyId,
    String? nom,
    String? prenom,
    String? sexe,
    String? dateNaissance,
    String? dateDeces,
    bool? vivant,
    String? photo,
    String? notes,
    String? lieuNaissance,
    String? villageOrigine,
    String? nationalite,
    String? profession,
    String? nomPereTexte,
    String? nomMereTexte,
    String? visibilite,
    bool? peutVoir,
    bool? peutModifier,
    bool? peutAjouterDocuments,
    bool? peutAjouterSouvenirs,
    bool? peutCommenter,
  }) {
    return PersonModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      sexe: sexe ?? this.sexe,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      dateDeces: dateDeces ?? this.dateDeces,
      vivant: vivant ?? this.vivant,
      photo: photo ?? this.photo,
      notes: notes ?? this.notes,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      villageOrigine: villageOrigine ?? this.villageOrigine,
      nationalite: nationalite ?? this.nationalite,
      profession: profession ?? this.profession,
      nomPereTexte: nomPereTexte ?? this.nomPereTexte,
      nomMereTexte: nomMereTexte ?? this.nomMereTexte,
      visibilite: visibilite ?? this.visibilite,
      peutVoir: peutVoir ?? this.peutVoir,
      peutModifier: peutModifier ?? this.peutModifier,
      peutAjouterDocuments: peutAjouterDocuments ?? this.peutAjouterDocuments,
      peutAjouterSouvenirs: peutAjouterSouvenirs ?? this.peutAjouterSouvenirs,
      peutCommenter: peutCommenter ?? this.peutCommenter,
    );
  }

  @override
  List<Object?> get props => [id, nom, prenom, sexe];
}

class RelationshipModel {
  final String typeRelation;
  final PersonModel person;

  const RelationshipModel({
    required this.typeRelation,
    required this.person,
  });

  factory RelationshipModel.fromJson(Map<String, dynamic> json) =>
      RelationshipModel(
        typeRelation: json['type_relation'] as String? ?? '',
        person: PersonModel.fromJson(json),
      );
}

class FamilyTreeModel {
  final List<PersonModel> nodes;
  final List<TreeEdge> edges;

  const FamilyTreeModel({required this.nodes, required this.edges});

  factory FamilyTreeModel.fromJson(Map<String, dynamic> json) => FamilyTreeModel(
        nodes: (json['nodes'] as List? ?? [])
            .map((n) => PersonModel.fromJson(n as Map<String, dynamic>))
            .toList(),
        edges: (json['edges'] as List? ?? [])
            .map((e) => TreeEdge.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TreeEdge {
  final int source;
  final int target;
  final String type;

  const TreeEdge({
    required this.source,
    required this.target,
    required this.type,
  });

  factory TreeEdge.fromJson(Map<String, dynamic> json) => TreeEdge(
        source: int.tryParse(json['source'].toString()) ?? 0,
        target: int.tryParse(json['target'].toString()) ?? 0,
        type: json['type'] as String? ?? '',
      );
}

class FamilyModel {
  final int id;
  final String nom;
  final String visibilite;
  final String? description;
  final bool shared;
  final String? permission;
  final String? ownerNom;

  const FamilyModel({
    required this.id,
    required this.nom,
    required this.visibilite,
    this.description,
    this.shared = false,
    this.permission,
    this.ownerNom,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) => FamilyModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        nom: json['nom'] as String? ?? '',
        visibilite: json['visibilite'] as String? ?? 'PRIVE',
        description: json['description'] as String?,
        shared: json['shared'] == true,
        permission: json['permission'] as String?,
        ownerNom: json['owner_nom'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'visibilite': visibilite,
        'description': description,
      }..removeWhere((key, value) => value == null);

  FamilyModel copyWith({int? id, String? nom, String? visibilite, String? description}) =>
      FamilyModel(
        id: id ?? this.id,
        nom: nom ?? this.nom,
        visibilite: visibilite ?? this.visibilite,
        description: description ?? this.description,
        shared: shared,
        permission: permission,
        ownerNom: ownerNom,
      );
}

class PersonDocumentModel {
  final int id;
  final int personId;
  final String typeDocument;
  final String nomFichier;
  final String? createdAt;

  const PersonDocumentModel({
    required this.id,
    required this.personId,
    required this.typeDocument,
    required this.nomFichier,
    this.createdAt,
  });

  factory PersonDocumentModel.fromJson(Map<String, dynamic> json) => PersonDocumentModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        personId: int.tryParse(json['person_id'].toString()) ?? 0,
        typeDocument: json['type_document'] as String? ?? 'AUTRE',
        nomFichier: json['nom_fichier'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );
}

class PersonMemoryModel {
  final int id;
  final int personId;
  final String type;
  final String nomFichier;
  final String? createdAt;

  const PersonMemoryModel({
    required this.id,
    required this.personId,
    required this.type,
    required this.nomFichier,
    this.createdAt,
  });

  factory PersonMemoryModel.fromJson(Map<String, dynamic> json) => PersonMemoryModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        personId: int.tryParse(json['person_id'].toString()) ?? 0,
        type: json['type'] as String? ?? 'PHOTO',
        nomFichier: json['nom_fichier'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );
}
