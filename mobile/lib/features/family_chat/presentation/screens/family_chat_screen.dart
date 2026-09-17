// lib/features/family_chat/presentation/screens/family_chat_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/models/family_chat_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/domain/auth_bloc.dart';
import '../../data/family_chat_repository.dart';
import '../../domain/family_chat_bloc.dart';

String _familyMediaUrl(String filename) {
  final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
  return '$base/uploads/family_messages/$filename';
}

class FamilyChatScreen extends StatelessWidget {
  final FamilyGroupModel group;
  const FamilyChatScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FamilyChatBloc(FamilyChatRepository(), group.id)..add(LoadMessages()),
      child: _FamilyChatView(group: group),
    );
  }
}

class _FamilyChatView extends StatefulWidget {
  final FamilyGroupModel group;
  const _FamilyChatView({required this.group});

  @override
  State<_FamilyChatView> createState() => _FamilyChatViewState();
}

class _FamilyChatViewState extends State<_FamilyChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      context.read<FamilyChatBloc>().add(PollMessages());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<FamilyChatBloc>().add(SendMessage(contenu: text));
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    context.read<FamilyChatBloc>().add(SendMessage(imageBytes: bytes, imageFilename: file.name));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.nom, style: const TextStyle(fontSize: 16)),
            Text('${widget.group.membersCount} membres',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<FamilyChatBloc, FamilyChatState>(
              listener: (context, state) {
                if (state is FamilyChatLoaded) _scrollToBottom();
              },
              builder: (context, state) {
                if (state is FamilyChatLoading) return const AppLoader();
                if (state is FamilyChatError) return Center(child: AppBanner(message: state.message));
                if (state is FamilyChatLoaded) {
                  if (state.messages.isEmpty) {
                    return const Center(child: Text('Aucun message. Dites bonjour !'));
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length,
                    itemBuilder: (_, i) {
                      final m = state.messages[i];
                      return _MessageBubble(message: m, isMine: m.sender.id == myId);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera_outlined, color: AppColors.vertForet),
                    onPressed: _pickAndSendImage,
                  ),
                  Expanded(
                    child: AppTextField(label: 'Écrivez un message...', controller: _controller),
                  ),
                  const SizedBox(width: 4),
                  BlocBuilder<FamilyChatBloc, FamilyChatState>(
                    builder: (context, state) {
                      final sending = state is FamilyChatLoaded && state.sending;
                      return IconButton(
                        icon: sending
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send, color: AppColors.vertForet),
                        onPressed: sending ? null : _send,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final FamilyMessageModel message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppColors.vertForet : AppColors.blanc;
    final textColor = isMine ? AppColors.blanc : AppColors.noir;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: isMine ? null : Border.all(color: AppColors.grisClair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(message.sender.nomComplet,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.vertForet)),
              ),
            if (message.typeMessage == 'IMAGE' && message.nomFichier != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_familyMediaUrl(message.nomFichier!), width: 200, fit: BoxFit.cover),
              ),
            if (message.contenu != null && message.contenu!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message.contenu!, style: TextStyle(color: textColor, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
