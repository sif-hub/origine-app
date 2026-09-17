// lib/features/genealogy/domain/genealogy_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/genealogy_repository.dart';
import '../../../shared/models/person_model.dart';

// ─── EVENTS ───────────────────────────────────
abstract class GenealogyEvent extends Equatable {
  const GenealogyEvent();
  @override
  List<Object?> get props => [];
}

class LoadFamilies extends GenealogyEvent {
  final int? preferredFamilyId;
  const LoadFamilies({this.preferredFamilyId});
  @override
  List<Object?> get props => [preferredFamilyId];
}

class SelectFamily extends GenealogyEvent {
  final FamilyModel family;
  const SelectFamily(this.family);
  @override
  List<Object?> get props => [family];
}

class RefreshTree extends GenealogyEvent {}

// ─── STATES ───────────────────────────────────
abstract class GenealogyState extends Equatable {
  const GenealogyState();
  @override
  List<Object?> get props => [];
}

class GenealogyInitial extends GenealogyState {}

class GenealogyLoading extends GenealogyState {}

class GenealogyLoaded extends GenealogyState {
  final List<FamilyModel> families;
  final FamilyModel selectedFamily;
  final FamilyTreeModel tree;

  const GenealogyLoaded({
    required this.families,
    required this.selectedFamily,
    required this.tree,
  });

  GenealogyLoaded copyWith({
    List<FamilyModel>? families,
    FamilyModel? selectedFamily,
    FamilyTreeModel? tree,
  }) =>
      GenealogyLoaded(
        families: families ?? this.families,
        selectedFamily: selectedFamily ?? this.selectedFamily,
        tree: tree ?? this.tree,
      );

  @override
  List<Object?> get props => [families, selectedFamily, tree];
}

class GenealogyEmpty extends GenealogyState {
  final List<FamilyModel> families;
  final FamilyModel selectedFamily;
  const GenealogyEmpty({required this.families, required this.selectedFamily});
  @override
  List<Object?> get props => [families, selectedFamily];
}

class GenealogyError extends GenealogyState {
  final String message;
  const GenealogyError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────
class GenealogyBloc extends Bloc<GenealogyEvent, GenealogyState> {
  final GenealogyRepository _repository;

  GenealogyBloc(this._repository) : super(GenealogyInitial()) {
    on<LoadFamilies>(_onLoadFamilies);
    on<SelectFamily>(_onSelectFamily);
    on<RefreshTree>(_onRefreshTree);
  }

  Future<void> _onLoadFamilies(LoadFamilies event, Emitter<GenealogyState> emit) async {
    emit(GenealogyLoading());
    try {
      var families = await _repository.getFamilies();
      if (families.isEmpty) {
        final family = await _repository.createFamily('Ma famille');
        families = [family];
      }
      final selected = event.preferredFamilyId == null
          ? families.first
          : families.firstWhere(
              (f) => f.id == event.preferredFamilyId,
              orElse: () => families.first,
            );
      await _loadTreeFor(families, selected, emit);
    } catch (e) {
      emit(GenealogyError(e.toString()));
    }
  }

  Future<void> _onSelectFamily(SelectFamily event, Emitter<GenealogyState> emit) async {
    final current = state;
    final families = current is GenealogyLoaded
        ? current.families
        : current is GenealogyEmpty
            ? current.families
            : <FamilyModel>[event.family];
    emit(GenealogyLoading());
    try {
      await _loadTreeFor(families, event.family, emit);
    } catch (e) {
      emit(GenealogyError(e.toString()));
    }
  }

  Future<void> _onRefreshTree(RefreshTree event, Emitter<GenealogyState> emit) async {
    final current = state;
    FamilyModel? selected;
    List<FamilyModel> families = [];
    if (current is GenealogyLoaded) {
      selected = current.selectedFamily;
      families = current.families;
    } else if (current is GenealogyEmpty) {
      selected = current.selectedFamily;
      families = current.families;
    }
    if (selected == null) return;
    try {
      await _loadTreeFor(families, selected, emit);
    } catch (e) {
      emit(GenealogyError(e.toString()));
    }
  }

  Future<void> _loadTreeFor(
      List<FamilyModel> families, FamilyModel selected, Emitter<GenealogyState> emit) async {
    final tree = await _repository.getTree(selected.id);
    if (tree.nodes.isEmpty) {
      emit(GenealogyEmpty(families: families, selectedFamily: selected));
    } else {
      emit(GenealogyLoaded(families: families, selectedFamily: selected, tree: tree));
    }
  }
}
