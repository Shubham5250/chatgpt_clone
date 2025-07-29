import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import '../widgets/sidebar.dart';
import '../models/chat.dart';
import 'settings_screen.dart';


/// APPEARS AFTER USER IS LOGGED-IN
/// CONTAINS SIDE BAR AND CHAT-SCREEN
class MainScreen extends ConsumerStatefulWidget {
  final String userId;
  const MainScreen({super.key, required this.userId});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showSidebar = false;
  String? _currentChatId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chats = ref.read(chatProvider);
      if (chats.isNotEmpty) {
        setState(() => _currentChatId = chats.first.id);
      }
    });
  }

  Future<void> _handleNewChat() async {
    await ref.read(chatProvider.notifier).createNewChat();
    final newChatId = ref.read(chatProvider).first.id;
    setState(() {
      _currentChatId = newChatId;
      _showSidebar = false;
    });
  }

  Future<void> _handleChatSelected(String chatId) async {
    await ref.read(chatProvider.notifier).loadMessages(chatId);
    setState(() {
      _currentChatId = chatId;
      _showSidebar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatProvider);
    Chat? currentChat;
    if (_currentChatId != null) {
      final match = chats.where((chat) => chat.id == _currentChatId);
      currentChat = match.isNotEmpty ? match.first : null;
    } else {
      currentChat = null;
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Sidebar(
        userId: widget.userId,
        onChatSelected: _handleChatSelected,
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onCreateNewChat: _handleNewChat,
      ),
      body: Row(
        children: [
          if (_showSidebar)
            SizedBox(
              width: 280,
              child: Sidebar(
                userId: widget.userId,
                onChatSelected: _handleChatSelected,
                openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                onCreateNewChat: _handleNewChat,
              ),
            ),
          Expanded(
            child: ChatScreen(
              chatId: currentChat?.id ?? '',
              chat: currentChat ?? Chat(
                id: '',
                title: 'New Chat',
                messages: [],
              ),
              onMenuPressed: () {
                if (MediaQuery.of(context).size.width < 600) {
                  setState(() => _showSidebar = !_showSidebar);
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}