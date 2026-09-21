// lib/features/genealogy/domain/add_member_bloc.dart

import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/direct_upload.dart';
import '../data/genealogy_repository.dart';
import '../../../shared/models/person_model.dart';

class DraftDocument {
  final String typeDocument; // ACTE_NAISSANCE | ACTE_MARIAGE | ACTE_DECES | AUTRE
  final Uint8List bytes;
  final String filename;
  const DraftDocument({required this.typeDocument, required this.bytes, required this.filename});
}

class DraftMemory {
  final String type; // PHOTO | VIDEO | AUDIO
  final Uint8List bytes;
  final String filename;
  const DraftMemory({required this.type, required this.bytes, required this.filename});
}

/// Toutes les données collectées à travers les 5 étapes du formulaire
/// "Ajouter un membre", assemblées par l'écran (StatefulWidget) et
/// envoyées au bloc en une seule fois à la soumission finale.
class MemberDraft {
  // Contexte / lien avec l'arbre existant
  final int familyId;
  final int? anchorPersonId; // personne à partir de laquelle le lien est créé
  final String relationType; // PERE | MERE | CONJOINT | ENFANT | FRERE_SOEUR | AUCUN

  // Étape 1 — Informations
  final String nom;
  final String? prenom;
  final String sexe; // M | F
  final String? dateNaissance;
  final bool vivant;
  final String? lieuNaissance;
  final String? villageOrigine;
  final String? nationalite;
  final String? profession;
  final Uint8List? photoBytes;
  final String? photoFilename;

  // Étape 2 — Relations
  final String? nomPereTexte;
  final String? nomMereTexte;
  final String? notes;

  // Étape 3 — Documents
  final List<DraftDocument> documents;

  // Étape 4 — Souvenirs
  final List<DraftMemory> memories;

  // Étape 5 — Confidentialité
  final String visibilite;
  final bool peutVoir;
  final bool peutModifier;
  final bool peutAjouterDocuments;
  final bool peutAjouterSouvenirs;
  final bool peutCommenter;

  const MemberDraft({
    required this.familyId,
    this.anchorPersonId,
    this.relationType = 'AUCUN',
    required this.nom,
    this.prenom,
    this.sexe = 'M',
    this.dateNaissance,
    this.vivant = true,
    this.lieuNaissance,
    this.villageOrigine,
    this.nationalite,
    this.profession,
    this.photoBytes,
    this.photoFilename,
    this.nomPereTexte,
    this.nomMereTexte,
    this.notes,
    this.documents = const [],
    this.memories = const [],
    this.visibilite = 'PRIVE',
    this.peutVoir = true,
    this.peutModifier = false,
    this.peutAjouterDocuments = false,
    this.peutAjouterSouvenirs = true,
    this.peutCommenter = true,
  });

  Map<String, dynamic> toPersonPayload() => {
        'nom': nom,
        'prenom': prenom,
        'sexe': sexe,
        'date_naissance': dateNaissance,
        'family_id': familyId,
        'notes': notes,
        'lieu_naissance': lieuNaissance,
        'village_origine': villageOrigine,
        'nationalite': nationalite,
        'profession': profession,
        'nom_pere_texte': nomPereTexte,
        'nom_mere_texte': nomMereTexte,
      }..removeWhere((key, value) => value == null);

  Map<String, dynamic> toPrivacyPayload() => {
        'visibilite': visibilite,
        'peut_voir': peutVoir,
        'peut_modifier': peutModifier,
        'peut_ajouter_documents': peutAjouterDocuments,
        'peut_ajouter_souvenirs': peutAjouterSouvenirs,
        'peut_commenter': peutCommenter,
      };
}

// ─── EVENTS ───────────────────────────────────
abstract class AddMemberEvent extends Equatable {
  const AddMemberEvent();
  @override
  List<Object?> get props => [];
}

class SubmitMemberRequested extends AddMemberEvent {
  final MemberDraft draft;
  const SubmitMemberRequested(this.draft);
  @override
  List<Object?> get props => [draft];
}

class ResetAddMember extends AddMemberEvent {}

// ─── STATES ───────────────────────────────────
abstract class AddMemberState extends Equatable {
  const AddMemberState();
  @override
  List<Object?> get props => [];
}

class AddMemberInitial extends AddMemberState {}

class AddMemberSubmitting extends AddMemberState {}

class AddMemberSuccess extends AddMemberState {
  final PersonModel person;
  final MemberDraft draft;
  const AddMemberSuccess(this.person, this.draft);
  @override
  List<Object?> get props => [person, draft];
}

class AddMemberFailure extends AddMemberState {
  final String message;
  const AddMemberFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────
class AddMemberBloc extends Bloc<AddMemberEvent, AddMemberState> {
  final GenealogyRepository _repository;

  AddMemberBloc(this._repository) : super(AddMemberInitial()) {
    on<SubmitMemberRequested>(_onSubmit);
    on<ResetAddMember>((event, emit) => emit(AddMemberInitial()));
  }

  Future<void> _onSubmit(SubmitMemberRequested event, Emitter<AddMemberState> emit) async {
    emit(AddMemberSubmitting());
    final draft = event.draft;
    try {
      // Photo : envoi direct à Cloudinary si disponible, sinon via le backend
      // une fois le membre créé (dev local).
      String? photoUrl;
      if (draft.photoBytes != null) {
        photoUrl = await uploadDirect(draft.photoBytes!, draft.photoFilename ?? 'photo.jpg', 'person_photos');
      }

      var person = await _createPerson(draft, photoUrl: photoUrl);

      if (draft.photoBytes != null && photoUrl == null) {
        person = await _repository.uploadPersonPhoto(
            person.id, draft.photoBytes!, draft.photoFilename ?? 'photo.jpg');
      }

      for (final doc in draft.documents) {
        await _repository.uploadPersonDocument(
          personId: person.id,
          typeDocument: doc.typeDocument,
          bytes: doc.bytes,
          filename: doc.filename,
        );
      }

      for (final memory in draft.memories) {
        final url = await uploadDirect(memory.bytes, memory.filename, 'person_memories');
        await _repository.uploadPersonMemory(
          personId: person.id,
          type: memory.type,
          bytes: memory.bytes,
          filename: memory.filename,
          url: url,
        );
      }

      final updated = await _repository.updatePersonPrivacy(person.id, draft.toPrivacyPayload());

      emit(AddMemberSuccess(updated, draft));
    } catch (e) {
      emit(AddMemberFailure(e.toString()));
    }
  }

  Future<PersonModel> _createPerson(MemberDraft draft, {String? photoUrl}) async {
    final payload = draft.toPersonPayload();
    if (photoUrl != null) payload['photo'] = photoUrl;

    if (draft.anchorPersonId == null) {
      return _repository.createPerson(payload);
    }

    switch (draft.relationType) {
      case 'PERE':
      case 'MERE':
        return _repository.addParent(draft.anchorPersonId!, payload);
      case 'ENFANT':
        return _repository.addChild(draft.anchorPersonId!, payload);
      case 'CONJOINT':
        return _repository.addSpouse(draft.anchorPersonId!, payload);
      case 'FRERE_SOEUR':
        final sibling = await _repository.createPerson(payload);
        await _repository.linkPersons(draft.anchorPersonId!, sibling.id, 'FRERE_SOEUR');
        return sibling;
      default:
        return _repository.createPerson(payload);
    }
  }
}
