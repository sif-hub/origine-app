// lib/shared/models/family_chat_model.dart

class ChatUserModel {
  final int id;
  final String nom;
  final String? prenom;
  final String? photoProfil;
  final String? email;

  const ChatUserModel({
    required this.id,
    required this.nom,
    this.prenom,
    this.photoProfil,
    this.email,
  });

  String get nomComplet => '${prenom ?? ''} $nom'.trim();

  factory ChatUserModel.fromJson(Map<String, dynamic> json) => ChatUserModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        nom: json['nom'] as String? ?? '',
        prenom: json['prenom'] as String?,
        photoProfil: json['photo_profil'] as String?,
        email: json['email'] as String?,
      );
}

class FamilyMessageModel {
  final int id;
  final int groupId;
  final ChatUserModel sender;
  final String? contenu;
  final String typeMessage; // TEXT | IMAGE
  final String? nomFichier;
  final String? createdAt;

  const FamilyMessageModel({
    required this.id,
    required this.groupId,
    required this.sender,
    this.contenu,
    this.typeMessage = 'TEXT',
    this.nomFichier,
    this.createdAt,
  });

  factory FamilyMessageModel.fromJson(Map<String, dynamic> json) => FamilyMessageModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        groupId: int.tryParse(json['group_id'].toString()) ?? 0,
        sender: ChatUserModel.fromJson(json['sender'] as Map<String, dynamic>? ?? {}),
        contenu: json['contenu'] as String?,
        typeMessage: json['type_message'] as String? ?? 'TEXT',
        nomFichier: json['nom_fichier'] as String?,
        createdAt: json['created_at'] as String?,
      );
}

class FamilyGroupModel {
  final int id;
  final String nom;
  final int createdBy;
  final int membersCount;
  final FamilyMessageModel? lastMessage;
  final String? createdAt;

  const FamilyGroupModel({
    required this.id,
    required this.nom,
    required this.createdBy,
    this.membersCount = 0,
    this.lastMessage,
    this.createdAt,
  });

  factory FamilyGroupModel.fromJson(Map<String, dynamic> json) => FamilyGroupModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        nom: json['nom'] as String? ?? '',
        createdBy: int.tryParse(json['created_by'].toString()) ?? 0,
        membersCount: int.tryParse(json['members_count'].toString()) ?? 0,
        lastMessage: json['last_message'] != null
            ? FamilyMessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
            : null,
        createdAt: json['created_at'] as String?,
      );
}
