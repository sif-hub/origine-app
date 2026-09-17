// lib/features/family_chat/presentation/screens/family_groups_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/family_chat_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/family_chat_repository.dart';
import '../../domain/family_groups_bloc.dart';
import 'create_group_screen.dart';
import 'family_chat_screen.dart';

class FamilyGroupsScreen extends StatelessWidget {
  const FamilyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FamilyGroupsBloc(FamilyChatRepository())..add(LoadGroups()),
      child: const _FamilyGroupsView(),
    );
  }
}

class _FamilyGroupsView extends StatelessWidget {
  const _FamilyGroupsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma famille')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.vertForet,
        icon: const Icon(Icons.group_add_outlined, color: AppColors.blanc),
        label: const Text('Créer un groupe familial', style: TextStyle(color: AppColors.blanc)),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const CreateGroupScreen(),
          ));
          if (context.mounted) context.read<FamilyGroupsBloc>().add(RefreshGroups());
        },
      ),
      body: BlocBuilder<FamilyGroupsBloc, FamilyGroupsState>(
        builder: (context, state) {
          if (state is FamilyGroupsLoading) return const AppLoader();
          if (state is FamilyGroupsError) return Center(child: AppBanner(message: state.message));
          if (state is FamilyGroupsLoaded) {
            if (state.groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.groups_outlined, size: 64, color: AppColors.grisClair),
                    SizedBox(height: 16),
                    Text('Aucun groupe familial pour le moment.'),
                    SizedBox(height: 4),
                    Text('Créez-en un pour échanger avec vos proches.',
                        style: TextStyle(fontSize: 12, color: AppColors.gris)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _GroupTile(group: state.groups[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final FamilyGroupModel group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final last = group.lastMessage;
    String preview;
    if (last == null) {
      preview = 'Aucun message pour le moment';
    } else if (last.typeMessage == 'IMAGE') {
      preview = '${last.sender.prenom ?? last.sender.nom} : 📷 Photo';
    } else {
      preview = '${last.sender.prenom ?? last.sender.nom} : ${last.contenu ?? ''}';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: AppAvatar(
        initials: group.nom.isNotEmpty ? group.nom[0] : '?',
        radius: 24,
        backgroundColor: AppColors.vertForet,
      ),
      title: Text(group.nom, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)),
      trailing: Text('${group.membersCount} membres',
          style: const TextStyle(fontSize: 11, color: AppColors.gris)),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FamilyChatScreen(group: group),
      )),
    );
  }
}
