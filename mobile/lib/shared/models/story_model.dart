// lib/shared/models/story_model.dart

class StoryAuthorModel {
  final int id;
  final String nom;
  final String? prenom;
  final String? photoProfil;
  final bool certifie;
  final String statutAuteur;
  final String? email;

  const StoryAuthorModel({
    required this.id,
    required this.nom,
    this.prenom,
    this.photoProfil,
    this.certifie = false,
    this.statutAuteur = 'UTILISATEUR',
    this.email,
  });

  String get nomComplet => '${prenom ?? ''} $nom'.trim();

  factory StoryAuthorModel.fromJson(Map<String, dynamic> json) => StoryAuthorModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        nom: json['nom'] as String? ?? '',
        prenom: json['prenom'] as String?,
        photoProfil: json['photo_profil'] as String?,
        certifie: (json['certifie'] == 1 || json['certifie'] == true),
        statutAuteur: json['statut_auteur'] as String? ?? 'UTILISATEUR',
        email: json['email'] as String?,
      );
}

class StoryMediaModel {
  final int id;
  final String type; // PHOTO | VIDEO | AUDIO
  final String nomFichier;

  const StoryMediaModel({required this.id, required this.type, required this.nomFichier});

  factory StoryMediaModel.fromJson(Map<String, dynamic> json) => StoryMediaModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        type: json['type'] as String? ?? 'PHOTO',
        nomFichier: json['nom_fichier'] as String? ?? '',
      );
}

class StoryModel {
  final int id;
  final StoryAuthorModel author;
  final String titre;
  final String description;
  final String? dateHistoire;
  final String? region;
  final String? village;
  final String categorie;
  final String? motsCles;
  final String? source;
  final bool autoriserTts;
  final List<StoryMediaModel> media;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final String? createdAt;

  const StoryModel({
    required this.id,
    required this.author,
    required this.titre,
    required this.description,
    this.dateHistoire,
    this.region,
    this.village,
    this.categorie = 'AUTRE',
    this.motsCles,
    this.source,
    this.autoriserTts = true,
    this.media = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
    this.createdAt,
  });

  StoryModel copyWith({int? likesCount, bool? likedByMe, int? commentsCount}) => StoryModel(
        id: id,
        author: author,
        titre: titre,
        description: description,
        dateHistoire: dateHistoire,
        region: region,
        village: village,
        categorie: categorie,
        motsCles: motsCles,
        source: source,
        autoriserTts: autoriserTts,
        media: media,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        likedByMe: likedByMe ?? this.likedByMe,
        createdAt: createdAt,
      );

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        author: StoryAuthorModel.fromJson(json['author'] as Map<String, dynamic>? ?? {}),
        titre: json['titre'] as String? ?? '',
        description: json['description'] as String? ?? '',
        dateHistoire: json['date_histoire'] as String?,
        region: json['region'] as String?,
        village: json['village'] as String?,
        categorie: json['categorie'] as String? ?? 'AUTRE',
        motsCles: json['mots_cles'] as String?,
        source: json['source'] as String?,
        autoriserTts: (json['autoriser_tts'] == null) ? true : (json['autoriser_tts'] == true),
        media: (json['media'] as List? ?? [])
            .map((m) => StoryMediaModel.fromJson(m as Map<String, dynamic>))
            .toList(),
        likesCount: int.tryParse(json['likes_count'].toString()) ?? 0,
        commentsCount: int.tryParse(json['comments_count'].toString()) ?? 0,
        likedByMe: (json['liked_by_me'] == true),
        createdAt: json['created_at'] as String?,
      );
}

class StoryCommentModel {
  final int id;
  final int storyId;
  final String contenu;
  final StoryAuthorModel author;
  final String? createdAt;

  const StoryCommentModel({
    required this.id,
    required this.storyId,
    required this.contenu,
    required this.author,
    this.createdAt,
  });

  factory StoryCommentModel.fromJson(Map<String, dynamic> json) => StoryCommentModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        storyId: int.tryParse(json['story_id'].toString()) ?? 0,
        contenu: json['contenu'] as String? ?? '',
        author: StoryAuthorModel.fromJson(json['author'] as Map<String, dynamic>? ?? {}),
        createdAt: json['created_at'] as String?,
      );
}

class CertificationRequestModel {
  final int id;
  final StoryAuthorModel user;
  final String typeProfessionnel;
  final String? description;
  final String documentFichier;
  final String statut; // EN_ATTENTE | APPROUVEE | REJETEE
  final String? createdAt;

  const CertificationRequestModel({
    required this.id,
    required this.user,
    required this.typeProfessionnel,
    this.description,
    required this.documentFichier,
    this.statut = 'EN_ATTENTE',
    this.createdAt,
  });

  factory CertificationRequestModel.fromJson(Map<String, dynamic> json) => CertificationRequestModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        user: StoryAuthorModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
        typeProfessionnel: json['type_professionnel'] as String? ?? 'AUTRE',
        description: json['description'] as String?,
        documentFichier: json['document_fichier'] as String? ?? '',
        statut: json['statut'] as String? ?? 'EN_ATTENTE',
        createdAt: json['created_at'] as String?,
      );
}

const kCertificationTypeLabels = {
  'GRIOT': 'Griot',
  'GENEALOGISTE': 'Généalogiste',
  'HISTORIEN': 'Historien',
  'AUTRE': 'Autre',
};

const kStoryCategories = {
  'TRADITIONS_COUTUMES': 'Traditions et coutumes',
  'HISTOIRE_PEUPLES': 'Histoire des peuples',
  'PERSONNALITES_FIGURES': 'Personnalités et figures historiques',
  'LIEUX_PATRIMOINE': 'Lieux et patrimoine',
  'RITES_CEREMONIES': 'Rites et cérémonies',
  'CONTES_LEGENDES': 'Contes et légendes',
  'LANGUES_EXPRESSIONS': 'Langues et expressions',
  'ART_MUSIQUE_DANSE': 'Art, musique et danse',
  'VIE_QUOTIDIENNE': 'Vie quotidienne d\'autrefois',
  'AUTRE': 'Autre',
};

const kCameroonRegions = [
  'Adamaoua', 'Centre', 'Est', 'Extrême-Nord', 'Littoral',
  'Nord', 'Nord-Ouest', 'Ouest', 'Sud', 'Sud-Ouest',
];
