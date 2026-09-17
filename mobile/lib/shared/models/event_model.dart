// lib/shared/models/event_model.dart

class FamilyEventModel {
  final int id;
  final String nom;
  final String typeEvenement;
  final DateTime dateEvenement;
  final String? heure;
  final String? description;
  final String? personneConcernee;
  final String? createdAt;

  const FamilyEventModel({
    required this.id,
    required this.nom,
    this.typeEvenement = 'AUTRE',
    required this.dateEvenement,
    this.heure,
    this.description,
    this.personneConcernee,
    this.createdAt,
  });

  factory FamilyEventModel.fromJson(Map<String, dynamic> json) => FamilyEventModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        nom: json['nom'] as String? ?? '',
        typeEvenement: json['type_evenement'] as String? ?? 'AUTRE',
        dateEvenement: DateTime.parse(json['date_evenement'] as String),
        heure: json['heure'] as String?,
        description: json['description'] as String?,
        personneConcernee: json['personne_concernee'] as String?,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'type_evenement': typeEvenement,
        'date_evenement': dateEvenement.toIso8601String().split('T').first,
        if (heure != null) 'heure': heure,
        if (description != null) 'description': description,
        if (personneConcernee != null) 'personne_concernee': personneConcernee,
      };
}

const kEventTypeLabels = {
  'ANNIVERSAIRE': '🎂 Anniversaire',
  'ANNIVERSAIRE_DECES': '🕊️ Anniversaire de décès',
  'MARIAGE': '💍 Mariage',
  'NAISSANCE': '👶 Naissance',
  'BAPTEME': '⛪ Baptême',
  'CEREMONIE': '🎓 Cérémonie',
  'REUNION': '🎉 Réunion familiale',
  'AUTRE': '📌 Autre événement',
};
