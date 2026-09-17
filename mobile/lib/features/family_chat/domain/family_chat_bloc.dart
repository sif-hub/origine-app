// lib/features/family_chat/domain/family_chat_bloc.dart

import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/family_chat_repository.dart';
import '../../../shared/models/family_chat_model.dart';

// ─── EVENTS ───────────────────────────────────
abstract class FamilyChatEvent extends Equatable {
  const FamilyChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadMessages extends FamilyChatEvent {}

/// Déclenché périodiquement par un Timer côté écran pour simuler un
/// rafraîchissement quasi temps réel sans dépendance WebSocket.
class PollMessages extends FamilyChatEvent {}

class SendMessage extends FamilyChatEvent {
  final String? contenu;
  final Uint8List? imageBytes;
  final String? imageFilename;
  const SendMessage({this.contenu, this.imageBytes, this.imageFilename});
  @override
  List<Object?> get props => [contenu, imageBytes, imageFilename];
}

// ─── STATES ───────────────────────────────────
abstract class FamilyChatState extends Equatable {
  const FamilyChatState();
  @override
  List<Object?> get props => [];
}

class FamilyChatLoading extends FamilyChatState {}

class FamilyChatLoaded extends FamilyChatState {
  final List<FamilyMessageModel> messages;
  final bool sending;
  const FamilyChatLoaded(this.messages, {this.sending = false});
  @override
  List<Object?> get props => [messages, sending];
}

class FamilyChatError extends FamilyChatState {
  final String message;
  const FamilyChatError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────
class FamilyChatBloc extends Bloc<FamilyChatEvent, FamilyChatState> {
  final FamilyChatRepository _repository;
  final int groupId;

  FamilyChatBloc(this._repository, this.groupId) : super(FamilyChatLoading()) {
    on<LoadMessages>(_onLoad);
    on<PollMessages>(_onPoll);
    on<SendMessage>(_onSend);
  }

  Future<void> _onLoad(FamilyChatEvent event, Emitter<FamilyChatState> emit) async {
    emit(FamilyChatLoading());
    try {
      final messages = await _repository.getMessages(groupId);
      emit(FamilyChatLoaded(messages));
    } catch (e) {
      emit(FamilyChatError(e.toString()));
    }
  }

  Future<void> _onPoll(FamilyChatEvent event, Emitter<FamilyChatState> emit) async {
    try {
      final messages = await _repository.getMessages(groupId);
      final current = state;
      emit(FamilyChatLoaded(messages, sending: current is FamilyChatLoaded ? current.sending : false));
    } catch (_) {
      // Silencieux : un échec de sondage ne doit pas casser l'écran.
    }
  }

  Future<void> _onSend(SendMessage event, Emitter<FamilyChatState> emit) async {
    final current = state;
    if (current is! FamilyChatLoaded) return;
    emit(FamilyChatLoaded(current.messages, sending: true));
    try {
      final message = await _repository.sendMessage(
        groupId,
        contenu: event.contenu,
        imageBytes: event.imageBytes,
        imageFilename: event.imageFilename,
      );
      emit(FamilyChatLoaded([...current.messages, message]));
    } catch (e) {
      emit(FamilyChatLoaded(current.messages, sending: false));
    }
  }
}
