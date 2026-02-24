import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../providers/app_state_provider.dart';
import '../../services/chat_service.dart';

/// Tipo de conversa (abas).
enum ChatTab {
  community,
  groups,
  privateChat,
}

/// Tela de chat: Comunidade, Grupos ou Particular.
/// Se [initialConversation] for passado, abre essa conversa diretamente.
class ChatScreen extends StatefulWidget {
  final ChatConversation? initialConversation;

  const ChatScreen({super.key, this.initialConversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.initialConversation;
    if (conv != null) {
      return _ChatRoomScreen(
        chatId: conv.id,
        title: conv.title,
        isGroup: conv.isGroup,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mensagens'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Comunidade'),
            Tab(text: 'Grupos'),
            Tab(text: 'Particular'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChatListFromService(
            type: ChatListType.community,
            emptyMessage: 'Nenhuma conversa da comunidade.',
          ),
          _ChatListFromService(
            type: ChatListType.groups,
            emptyMessage: 'Nenhum grupo ainda.',
          ),
          _ChatListFromService(
            type: ChatListType.privateChat,
            emptyMessage: 'Nenhuma conversa particular.',
          ),
        ],
      ),
    );
  }
}

class _ChatListFromService extends StatefulWidget {
  final ChatListType type;
  final String emptyMessage;

  const _ChatListFromService({
    required this.type,
    required this.emptyMessage,
  });

  @override
  State<_ChatListFromService> createState() => _ChatListFromServiceState();
}

class _ChatListFromServiceState extends State<_ChatListFromService> {
  List<ChatConversation> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ChatService.getConversations(widget.type);
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _ChatList(
      items: _items,
      emptyMessage: widget.emptyMessage,
    );
  }
}

class _ChatList extends StatelessWidget {
  final List<ChatConversation> items;
  final String emptyMessage;

  const _ChatList({
    required this.items,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 64,
              color: theme.iconTheme.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.racingOrange.withValues(alpha: 0.2),
            child: Icon(
              item.isGroup ? LucideIcons.users : LucideIcons.user,
              color: AppColors.racingOrange,
            ),
          ),
          title: Text(item.title),
          subtitle: Text(
            item.lastMessagePreview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => _openChatRoom(context, item),
        );
      },
    );
  }

  void _openChatRoom(BuildContext context, ChatConversation item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatRoomScreen(
          chatId: item.id,
          title: item.title,
          isGroup: item.isGroup,
        ),
      ),
    );
  }
}

/// Tela de uma conversa: mensagens do ChatService + envio.
class _ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final bool isGroup;

  const _ChatRoomScreen({
    required this.chatId,
    required this.title,
    required this.isGroup,
  });

  @override
  State<_ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<_ChatRoomScreen> {
  final _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final list = await ChatService.getMessages(widget.chatId);
    if (mounted) {
      setState(() {
        _messages = list;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    if (user == null) return;
    _controller.clear();
    final msg = await ChatService.sendMessage(
      chatId: widget.chatId,
      userId: user.id,
      userName: user.name,
      text: t,
    );
    if (mounted) setState(() => _messages = [..._messages, msg]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.phone),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: m.isFromMe
                                ? AppColors.racingOrange.withValues(alpha: 0.2)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: m.isFromMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (widget.isGroup && !m.isFromMe)
                                Text(
                                  m.senderName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.racingOrange,
                                  ),
                                ),
                              Text(m.text),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            color: theme.scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Mensagem',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: 1,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(LucideIcons.send, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.racingOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
