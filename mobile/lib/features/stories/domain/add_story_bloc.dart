// lib/features/stories/domain/add_story_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/stories_repository.dart';
import '../../../shared/models/story_model.dart';

/// Données collectées à travers les étapes du formulaire "Ajouter une
/// histoire", assemblées par l'écran et envoyées au bloc en une fois.
class StoryDraft {
  final String titre;
  final String description;
  final String? dateHistoire;
  final String? region;
  final String? village;
  final String categorie;
  final String? motsCles;
  final String? source;
  final bool autoriserTts;
  final List<DraftStoryMedia> media;

  // Étape 3 — statut de l'auteur (si professionnel, une demande de
  // certification séparée est envoyée après la publication de l'histoire).
  final bool estProfessionnel;
  final String? typeProfessionnel; // GRIOT | GENEALOGISTE | HISTORIEN | AUTRE
  final String? descriptionProfessionnelle;
  final DraftStoryMedia? documentJustificatif;

  const StoryDraft({
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
    this.estProfessionnel = false,
    this.typeProfessionnel,
    this.descriptionProfessionnelle,
    this.documentJustificatif,
  });
}

// ─── EVENTS ───────────────────────────────────
abstract class AddStoryEvent extends Equatable {
  const AddStoryEvent();
  @override
  List<Object?> get props => [];
}

class SubmitStoryRequested extends AddStoryEvent {
  final StoryDraft draft;
  const SubmitStoryRequested(this.draft);
  @override
  List<Object?> get props => [draft];
}

// ─── STATES ───────────────────────────────────
abstract class AddStoryState extends Equatable {
  const AddStoryState();
  @override
  List<Object?> get props => [];
}

class AddStoryInitial extends AddStoryState {}

class AddStorySubmitting extends AddStoryState {}

class AddStorySuccess extends AddStoryState {
  final StoryModel story;
  const AddStorySuccess(this.story);
  @override
  List<Object?> get props => [story];
}

class AddStoryFailure extends AddStoryState {
  final String message;
  const AddStoryFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────
class AddStoryBloc extends Bloc<AddStoryEvent, AddStoryState> {
  final StoriesRepository _repository;

  AddStoryBloc(this._repository) : super(AddStoryInitial()) {
    on<SubmitStoryRequested>(_onSubmit);
  }

  Future<void> _onSubmit(SubmitStoryRequested event, Emitter<AddStoryState> emit) async {
    emit(AddStorySubmitting());
    final draft = event.draft;
    try {
      final story = await _repository.createStory(
        titre: draft.titre,
        description: draft.description,
        dateHistoire: draft.dateHistoire,
        region: draft.region,
        village: draft.village,
        categorie: draft.categorie,
        motsCles: draft.motsCles,
        source: draft.source,
        autoriserTts: draft.autoriserTts,
        media: draft.media,
      );

      if (draft.estProfessionnel &&
          draft.typeProfessionnel != null &&
          draft.documentJustificatif != null) {
        try {
          await _repository.submitCertificationRequest(
            typeProfessionnel: draft.typeProfessionnel!,
            description: draft.descriptionProfessionnelle,
            documentBytes: draft.documentJustificatif!.bytes,
            documentFilename: draft.documentJustificatif!.filename,
          );
        } catch (_) {
          // L'histoire est déjà publiée : ne pas la faire passer pour un échec
          // (l'utilisateur la republierait en double). La demande de
          // certification peut être refusée par le serveur si elle existe déjà.
        }
      }

      emit(AddStorySuccess(story));
    } catch (e) {
      emit(AddStoryFailure(e.toString()));
    }
  }
}
