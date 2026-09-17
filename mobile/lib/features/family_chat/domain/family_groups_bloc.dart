// lib/features/family_chat/domain/family_groups_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/family_chat_repository.dart';
import '../../../shared/models/family_chat_model.dart';

// ─── EVENTS ───────────────────────────────────
abstract class FamilyGroupsEvent extends Equatable {
  const FamilyGroupsEvent();
  @override
  List<Object?> get props => [];
}

class LoadGroups extends FamilyGroupsEvent {}

class RefreshGroups extends FamilyGroupsEvent {}

// ─── STATES ───────────────────────────────────
abstract class FamilyGroupsState extends Equatable {
  const FamilyGroupsState();
  @override
  List<Object?> get props => [];
}

class FamilyGroupsLoading extends FamilyGroupsState {}

class FamilyGroupsLoaded extends FamilyGroupsState {
  final List<FamilyGroupModel> groups;
  const FamilyGroupsLoaded(this.groups);
  @override
  List<Object?> get props => [groups];
}

class FamilyGroupsError extends FamilyGroupsState {
  final String message;
  const FamilyGroupsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────
class FamilyGroupsBloc extends Bloc<FamilyGroupsEvent, FamilyGroupsState> {
  final FamilyChatRepository _repository;

  FamilyGroupsBloc(this._repository) : super(FamilyGroupsLoading()) {
    on<LoadGroups>(_onLoad);
    on<RefreshGroups>(_onLoad);
  }

  Future<void> _onLoad(FamilyGroupsEvent event, Emitter<FamilyGroupsState> emit) async {
    emit(FamilyGroupsLoading());
    try {
      final groups = await _repository.getMyGroups();
      emit(FamilyGroupsLoaded(groups));
    } catch (e) {
      emit(FamilyGroupsError(e.toString()));
    }
  }
}
