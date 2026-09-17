// lib/features/ai/presentation/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<Map<String, String>> _apiHistory = [];

  final List<String> _suggestions = [
    'Qu\'est-ce que l\'arbre généalogique ?',
    'Comment fonctionne ORIGINE AI ?',
    'Expliquez la tradition du dot',
    'Que signifie le nom Mbarga ?',
    'Comment ajouter mon père dans l\'arbre ?',
  ];

  @override
  void initState() {
    super.initState();
    _addMessage(
      role: 'assistant',
      content: 'Bonjour ! Je suis ORIGINE AI 🌿\n\n'
          'Je peux vous aider à :\n'
          '• Explorer votre arbre généalogique\n'
          '• Comprendre les traditions camerounaises\n'
          '• Rechercher vos ancêtres\n'
          '• Expliquer les significations de noms\n\n'
          'Posez-moi une question pour commencer !',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage({required String role, required String content}) {
    setState(() {
      _messages.add(_ChatMessage(role: role, content: content));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;
    _controller.clear();

    _addMessage(role: 'user', content: text.trim());
    setState(() => _isTyping = true);

    try {
      final response = await apiClient.post('/ai/chat', data: {
        'message': text.trim(),
        'historique': _apiHistory,
      });

      final reponse = response.data['data']['reponse'] as String;

      _apiHistory.add({'role': 'user', 'content': text.trim()});
      _apiHistory.add({'role': 'assistant', 'content': reponse});

      // Garde au max 20 échanges en mémoire
      if (_apiHistory.length > 20) {
        _apiHistory.removeRange(0, 2);
      }

      _addMessage(role: 'assistant', content: reponse);
    } on DioException catch (e) {
      _addMessage(
        role: 'assistant',
        content: '⚠️ Désolé, une erreur est survenue : ${ApiClient.extractError(e)}',
      );
    } finally {
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('ORIGINE AI', style: TextStyle(fontSize: 16)),
            Text(
              'Assistant généalogique et culturel',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Effacer la conversation',
            onPressed: () {
              setState(() {
                _messages.clear();
                _apiHistory.clear();
              });
              _addMessage(
                role: 'assistant',
                content: 'Conversation effacée. Comment puis-je vous aider ? 🌿',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: _messages.isEmpty
                ? const _EmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (_isTyping && index == _messages.length) {
                        return const _TypingIndicator();
                      }
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Suggestions (affichées uniquement au premier message)
          if (_messages.length == 1)
            _buildSuggestions(),

          // Barre de saisie
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 42,
      color: AppColors.blanc,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => GestureDetector(
          onTap: () => _sendMessage(_suggestions[index]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.vertForet.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _suggestions[index],
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.vertForet,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.blanc,
        border: Border(top: BorderSide(color: AppColors.grisClair)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _isTyping ? null : _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Écrivez un message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.grisClair),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.grisClair),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.vertClair, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _isTyping
                  ? null
                  : () => _sendMessage(_controller.text),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _isTyping
                      ? AppColors.grisClair
                      : AppColors.vertForet,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isTyping
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.gris),
                      )
                    : const Icon(Icons.send_rounded,
                        color: AppColors.blanc, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BULLE DE MESSAGE ──────────────────────────────────────────────────
class _ChatMessage {
  final String role;
  final String content;
  final DateTime time;

  _ChatMessage({
    required this.role,
    required this.content,
  }) : time = DateTime.now();
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.vertForet,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('AI',
                    style: TextStyle(
                        color: AppColors.blanc,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.vertForet : AppColors.blanc,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.grisClair),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? AppColors.blanc : AppColors.noir,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${message.time.hour.toString().padLeft(2, '0')}:'
                  '${message.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.gris),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── INDICATEUR DE FRAPPE ──────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );

    _anims = List.generate(
      3,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controllers[i],
          curve: Interval(i * 0.2, 1.0, curve: Curves.easeInOut),
        ),
      ),
    );

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.vertForet,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('AI',
                  style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.blanc,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.grisClair),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _anims[i],
                  builder: (_, __) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7 + _anims[i].value * 4,
                    decoration: BoxDecoration(
                      color: AppColors.vertForet
                          .withOpacity(0.4 + _anims[i].value * 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ÉTAT VIDE ─────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.vertForet.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.vertForet, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'ORIGINE AI',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.vertForet),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre assistant généalogique\net culturel camerounais',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gris, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
