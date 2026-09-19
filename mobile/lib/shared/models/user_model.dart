// lib/shared/models/user_model.dart

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String sexe;
  final String? dateNaissance;
  final String role;
  final String? photoProfil;
  final String? biographie;
  final String? villageOrigine;
  final String? region;
  final String? departement;
  final String? langue;
  final String? profession;
  final int emailVerifie;
  final String statut;
  final String statutAuteur;
  final bool certifie;

  const UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.sexe,
    this.dateNaissance,
    required this.role,
    this.photoProfil,
    this.biographie,
    this.villageOrigine,
    this.region,
    this.departement,
    this.langue,
    this.profession,
    required this.emailVerifie,
    required this.statut,
    this.statutAuteur = 'UTILISATEUR',
    this.certifie = false,
  });

  String get nomComplet => '$prenom $nom'.trim();

  /// Initiales sûres même si le prénom ou le nom est vide.
  String get initiales {
    final letters = [prenom, nom]
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim()[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        nom: json['nom'] as String? ?? '',
        prenom: json['prenom'] as String? ?? '',
        email: json['email'] as String? ?? '',
        telephone: json['telephone'] as String?,
        sexe: json['sexe'] as String? ?? 'M',
        dateNaissance: json['date_naissance'] as String?,
        role: json['role'] as String? ?? 'UTILISATEUR',
        photoProfil: json['photo_profil'] as String?,
        biographie: json['biographie'] as String?,
        villageOrigine: json['village_origine'] as String?,
        region: json['region'] as String?,
        departement: json['departement'] as String?,
        langue: json['langue'] as String?,
        profession: json['profession'] as String?,
        emailVerifie: int.tryParse(json['email_verifie'].toString()) ?? 0,
        statut: json['statut'] as String? ?? 'ACTIF',
        statutAuteur: json['statut_auteur'] as String? ?? 'UTILISATEUR',
        certifie: (json['certifie'] == 1 || json['certifie'] == true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'sexe': sexe,
        'date_naissance': dateNaissance,
        'role': role,
        'photo_profil': photoProfil,
        'biographie': biographie,
        'village_origine': villageOrigine,
        'region': region,
        'profession': profession,
        'email_verifie': emailVerifie,
        'statut': statut,
      };

  UserModel copyWith({
    String? nom,
    String? prenom,
    String? telephone,
    String? biographie,
    String? villageOrigine,
    String? region,
    String? profession,
    String? photoProfil,
  }) =>
      UserModel(
        id: id,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        email: email,
        telephone: telephone ?? this.telephone,
        sexe: sexe,
        dateNaissance: dateNaissance,
        role: role,
        photoProfil: photoProfil ?? this.photoProfil,
        biographie: biographie ?? this.biographie,
        villageOrigine: villageOrigine ?? this.villageOrigine,
        region: region ?? this.region,
        departement: departement,
        langue: langue,
        profession: profession ?? this.profession,
        emailVerifie: emailVerifie,
        statut: statut,
      );

  @override
  List<Object?> get props => [id, email, nom, prenom];
}
