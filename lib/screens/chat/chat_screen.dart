import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../providers/app_state_provider.dart';
import '../../services/chat_service.dart';
import '../../services/realtime_service.dart';
import 'package:intl/intl.dart';

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
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _muted = false;
  List<Map<String, dynamic>> _participants = [];
  StreamSubscription<ChatMessagePayload>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadSettings();
    _realtimeSub = RealtimeService.instance.onChatMessage.listen((payload) {
      if (payload.chatId != widget.chatId || !mounted) return;
      try {
        final msg = ChatMessage.fromJson(payload.message);
        setState(() => _messages = [..._messages, msg]);
        _scrollToBottom(animated: true);
      } catch (_) {}
    });
  }

  Future<void> _loadMessages() async {
    final list = await ChatService.getMessages(widget.chatId);
    if (mounted) {
      setState(() {
        _messages = list;
        _loading = false;
      });
      _scrollToBottom(animated: false);
    }
  }

  Future<void> _loadSettings() async {
    final settings = await ChatService.getChatSettings(widget.chatId);
    if (!mounted || settings.isEmpty) return;
    setState(() {
      _muted = settings['muted'] == true;
      final list = settings['participants'] as List<dynamic>? ?? [];
      _participants = list
          .map((e) => e as Map<String, dynamic>)
          .toList();
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final raw = _controller.text;
    final t = raw.trim();
    if (t.isEmpty) return;
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    if (user == null) return;
    FocusScope.of(context).unfocus();
    _controller.clear();
    final msg = await ChatService.sendMessage(
      chatId: widget.chatId,
      userId: user.id,
      userName: user.name,
      text: t,
    );
    if (mounted) {
      setState(() => _messages = [..._messages, msg]);
      _scrollToBottom(animated: true);
    }
  }

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(position);
    }
  }

  void _showConversationActions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.info),
                title: const Text('Ver detalhes da conversa'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDetailsSheet();
                },
              ),
              if (widget.isGroup)
                ListTile(
                  leading: const Icon(LucideIcons.edit2),
                  title: const Text('Editar nome do grupo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showEditTitleDialog();
                  },
                ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.red),
                title: const Text('Excluir conversa'),
                textColor: Colors.red,
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDeleteConversation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditTitleDialog() async {
    final controller = TextEditingController(text: widget.title);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar nome do grupo'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nome do grupo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Aqui poderíamos chamar um serviço para persistir a alteração.
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir conversa'),
          content: const Text(
            'Tem a certeza que quer excluir esta conversa? Isto não remove mensagens do outro participante.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await ChatService.deleteConversation(widget.chatId);
    if (!mounted) return;
    Navigator.of(context).pop(); // fecha sala
  }

  void _showDetailsSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final title = widget.title;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.racingOrange.withValues(alpha: 0.15),
                      child: Text(
                        title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.racingOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isGroup ? 'Conversa em grupo' : 'Conversa privada',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_participants.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Participantes',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ..._participants.map(
                        (p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: theme.cardColor,
                            child: Text(
                              (p['name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                            ),
                          ),
                          title: Text(p['name'] as String? ?? ''),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Silenciar notificações'),
                  value: _muted,
                  onChanged: (v) async {
                    setState(() {
                      _muted = v;
                    });
                    await ChatService.setChatMuted(widget.chatId, v);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('HH:mm');

    return GestureDetector(
      onTap: () {
        final focus = FocusScope.of(context);
        if (!focus.hasPrimaryFocus && focus.focusedChild != null) {
          focus.unfocus();
        }
      },
      behavior: HitTestBehavior.deferToChild,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.phone),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showConversationActions,
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
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
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
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      m.senderName,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.racingOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Text(
                                  m.text,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateFormat.format(m.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Mensagem',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.4),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 1,
                      maxLines: 5,
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
          ),
        ],
      ),
      ),
    );
  }
}
