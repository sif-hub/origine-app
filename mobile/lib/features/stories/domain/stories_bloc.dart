// lib/features/stories/domain/stories_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/stories_repository.dart';
import '../../../shared/models/story_model.dart';

// ─── EVENTS ───────────────────────────────────
abstract class StoriesEvent extends Equatable {
  const StoriesEvent();
  @override
  List<Object?> get props => [];
}

class LoadFeed extends StoriesEvent {}

class RefreshFeed extends StoriesEvent {}

class ToggleLike extends StoriesEvent {
  final int storyId;
  const ToggleLike(this.storyId);
  @override
  List<Object?> get props => [storyId];
}

// ─── STATES ───────────────────────────────────
abstract class StoriesState extends Equatable {
  const StoriesState();
  @override
  List<Object?> get props => [];
}

class StoriesLoading extends StoriesState {}

class StoriesLoaded extends StoriesState {
  final List<StoryModel> stories;
  const StoriesLoaded(this.stories);
  @override
  List<Object?> get props => [stories];
}

class StoriesError extends StoriesState {
  final String message;
  const StoriesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────
class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  final StoriesRepository _repository;

  StoriesBloc(this._repository) : super(StoriesLoading()) {
    on<LoadFeed>(_onLoad);
    on<RefreshFeed>(_onLoad);
    on<ToggleLike>(_onToggleLike);
  }

  Future<void> _onLoad(StoriesEvent event, Emitter<StoriesState> emit) async {
    emit(StoriesLoading());
    try {
      final stories = await _repository.getFeed();
      emit(StoriesLoaded(stories));
    } catch (e) {
      emit(StoriesError(e.toString()));
    }
  }

  Future<void> _onToggleLike(ToggleLike event, Emitter<StoriesState> emit) async {
    final current = state;
    if (current is! StoriesLoaded) return;
    try {
      final liked = await _repository.toggleLike(event.storyId);
      final updated = current.stories.map((s) {
        if (s.id != event.storyId) return s;
        return s.copyWith(
          likedByMe: liked,
          likesCount: liked ? s.likesCount + 1 : s.likesCount - 1,
        );
      }).toList();
      emit(StoriesLoaded(updated));
    } catch (_) {
      // Silencieux : on laisse l'état inchangé si le like échoue en réseau.
    }
  }
}
