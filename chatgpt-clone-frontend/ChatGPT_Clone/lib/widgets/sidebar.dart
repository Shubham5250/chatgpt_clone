import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/colors.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';

class Sidebar extends ConsumerStatefulWidget {
  final String userId;
  final Function(String) onChatSelected;
  final VoidCallback openDrawer;
  final VoidCallback onCreateNewChat;

  const Sidebar({
    super.key,
    required this.userId,
    required this.onChatSelected,
    required this.openDrawer,
    required this.onCreateNewChat,
  });

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatProvider);
    final chatNotifier = ref.watch(chatProvider.notifier);
    final filteredChats = _searchQuery.isEmpty
        ? chats
        : chats.where((chat) => chat.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Container(
      width: 280,
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: SvgPicture.asset(
                                  'assets/search.svg',
                                  color: Colors.white,
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            hintText: 'Search',
                            hintStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: AppColors.userBubbleLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: SizedBox(
                          width: 20,
                          height: 20,
                          child: SvgPicture.asset(
                            'assets/edit.svg',
                            color: Colors.white,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        onPressed: widget.onCreateNewChat,
                        tooltip: 'New Chat',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.onCreateNewChat,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/edit.svg',
                          color: Colors.white,
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'New Chat',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                // Library, GPTs, Chats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: SvgPicture.asset('assets/image.svg', color: Colors.white, width: 20, height: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Library', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: SvgPicture.asset('assets/menu_sidebar.svg', color: Colors.white, width: 20, height: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('GPTs', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: SvgPicture.asset('assets/chat.svg', color: Colors.white, width: 20, height: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Chats', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chat history list
                if (chatNotifier.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading chats...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filteredChats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No chats found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    onRefresh: () async {
                      await ref.read(chatProvider.notifier).refreshChats();
                    },
                    child: Column(
                      children: filteredChats.map((chat) => ListTile(
                        title: Text(
                          chat.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => widget.onChatSelected(chat.id),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
          // User profile section
          Consumer(
            builder: (context, ref, child) {
              final userProfile = ref.read(authProvider.notifier).getUserProfile();
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.userBubbleLight,
                        backgroundImage: userProfile['photoURL'] != null 
                            ? NetworkImage(userProfile['photoURL'])
                            : null,
                        child: userProfile['photoURL'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile['displayName'] ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userProfile['email'] ?? 'user@example.com',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}