import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/sidebar.dart';
import '../widgets/message_action_bar.dart';
import '../widgets/image_selection_bottom_sheet.dart';
import 'package:uuid/uuid.dart';
import '../message_status.dart';
import '../models/message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';


/// SCREEN WHERE USER INTERACTS WITH AI MODEL
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final Chat chat;
  final VoidCallback onMenuPressed;
  final TextEditingController _messageController = TextEditingController();

  ChatScreen({
    super.key,
    required this.chat,
    required this.chatId,
    required this.onMenuPressed,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with SingleTickerProviderStateMixin {
  double sidebarWidth = 280;
  bool isSidebarOpen = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset _gestureStart = Offset.zero;
  late ScrollController _scrollController;
  bool _isLoadingMessages = false;
  bool _isGeneratingResponse = false;

  late String selectedChatId;

  @override
  void initState() {
    super.initState();

    final chats = ref.read(chatProvider);
    if (chats.isNotEmpty) {
      selectedChatId = chats.first.id;
    } else {
      selectedChatId = '';
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(begin: 0, end: sidebarWidth).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _scrollController = ScrollController();

    widget._messageController.addListener(() {
      setState(() {});
    });
  }

  // SIDEBAR - OPEN ANIMATION
  void openSidebar() {
    setState(() => isSidebarOpen = true);
    _controller.forward();
  }

  // SIDEBAR - CLOSE ANIMATION
  void closeSidebar() {
    setState(() => isSidebarOpen = false);
    _controller.reverse();
  }

  void handleChatSelected(String chatId) async {
    setState(() {
      selectedChatId = chatId;
      isSidebarOpen = false;
      _isLoadingMessages = true;
    });
    _controller.reverse();
    
    // Load messages for the selected chat
    try {
      await ref.read(chatProvider.notifier).loadMessages(chatId);
    } catch (e) {
      print('Error loading messages: $e');
    } finally {
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> startNewChat() async {
    // IT DOES NOT create a chat until first message is sent
    setState(() {
      selectedChatId = '';
      isSidebarOpen = false;
    });
    widget._messageController.clear();
    _controller.reverse();
  }

  /// DRAG FROM CHAT-SCREEN TO OPEN SIDEBAR
  void handleDragUpdate(DragUpdateDetails details) {
    double delta = details.primaryDelta ?? 0;
    double value = _controller.value + delta / sidebarWidth;
    _controller.value = value.clamp(0.0, 1.0);
  }

  void handleDragEnd(DragEndDetails details) {
    if (_controller.value > 0.3) {
      openSidebar();
    } else {
      closeSidebar();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget._messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Sidebar
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-sidebarWidth + _animation.value, 0),
                child: Sidebar(
                  userId: 'test_user_123',
                  onChatSelected: handleChatSelected,
                  openDrawer: openSidebar,
                  onCreateNewChat: startNewChat,
                ),
              );
            },
          ),

          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value, 0),
                child: GestureDetector(
                  onHorizontalDragStart: (details) {
                    _gestureStart = details.globalPosition;
                  },
                  onHorizontalDragUpdate: (details) {
                    // Swiping right to open
                    if (!isSidebarOpen && details.delta.dx > 0) {
                      handleDragUpdate(details);
                    }
                    if (isSidebarOpen && details.delta.dx < 0) {
                      handleDragUpdate(details);
                    }
                  },
                  onHorizontalDragEnd: handleDragEnd,
                  child: Stack(
                    children: [
                      AbsorbPointer(
                        absorbing: isSidebarOpen,
                        child: _buildChatScaffold(context),
                      ),
                      if (isSidebarOpen)
                        Container(
                          color: Colors.white.withOpacity(0.24),
                          width: double.infinity,
                          height: double.infinity,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Tap to close overlay
          if (isSidebarOpen)
            Positioned(
              left: sidebarWidth,
              top: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: closeSidebar,
                child: Container(
                  color: Colors.white.withOpacity(0.24),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatScaffold(BuildContext context) {
    final chats = ref.watch(chatProvider);
    final currentChat = chats.firstWhere(
      (c) => c.id == selectedChatId,
      orElse: () => widget.chat,
    );

    // AUTOMATICALLY  Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentChat.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: SvgPicture.asset('assets/menu.svg', color: Colors.white, width: 24, height: 24),
          onPressed: openSidebar,
        ),
        titleSpacing: 0,
        title: currentChat.messages.isNotEmpty
            ? Row(
                children: [
                  const SizedBox(width: 4),
                  const Text(
                    'ChatGPT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: SvgPicture.asset('assets/edit.svg', color: Colors.white, width: 22, height: 22),
                    onPressed: () => startNewChat(),
                    tooltip: 'New Chat',
                  ),
                  IconButton(
                    icon: SvgPicture.asset('assets/dots.svg', color: Colors.white, width: 22, height: 22),
                    onPressed: () {},
                    tooltip: 'More',
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.getPlusBg,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/star.svg',
                              color: AppColors.getPlusText,
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Get Plus',
                              style: TextStyle(
                                color: AppColors.getPlusText,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    child: Image.asset(
                      'assets/temp_chat.png',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMessages
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading messages...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : currentChat.messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 16),
                            Text(
                              'What can I help with?',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.w800
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: currentChat.messages.length,
                    itemBuilder: (context, index) {
                      final message = currentChat.messages[index];
                      final isUser = message.role == 'user';
                      

                      // MESSAGE SENDING INDICATION
                      if (index == currentChat.messages.length - 1 &&
                          isUser && 
                          message.status == MessageStatus.sending) {
                        return Column(
                          children: [
                            // User message
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.userBubbleLight,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  message.content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // AI loading indicator
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'AI is thinking...',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      if (isUser) {
                        // USER MESSAGE BUBBLE
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: Material(
                              color: AppColors.userBubbleLight,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {

                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (message.imageUrl != null)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              message.imageUrl!,
                                              width: 200,
                                              height: 200,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 200,
                                                  height: 200,
                                                  color: Colors.grey[800],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      Text(
                                        message.content,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        // AI message
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.imageUrl != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        message.imageUrl!,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 200,
                                            height: 200,
                                            color: Colors.grey[800],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      // Ripple effect on tap
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        message.content,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Action Bar added here for AI Response
                                if (index == currentChat.messages.lastIndexWhere((m) => m.role != 'user'))
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final messageActions = ref.watch(messageActionsProvider.notifier);
                                      final isLiked = ref.watch(messageActionsProvider)[message.id]?['liked'] ?? false;
                                      final isDisliked = ref.watch(messageActionsProvider)[message.id]?['disliked'] ?? false;
                                      
                                      return MessageActionBar(
                                        messageContent: message.content,
                                        onCopy: () {

                                        },
                                        onLike: () {
                                          messageActions.toggleLike(message.id);
                                        },
                                        onDislike: () {
                                          messageActions.toggleDislike(message.id);
                                        },
                                        onSpeaker: () {

                                        },
                                        onRegenerate: () async {
                                          // Regenerates the response
                                          final userMessages = currentChat.messages.where((m) => m.role == 'user').toList();
                                          if (userMessages.isNotEmpty) {
                                            final userMessage = userMessages.last;
                                            setState(() {
                                              _isGeneratingResponse = true;
                                            });
                                            try {
                                              await ref.read(chatProvider.notifier).sendMessage(
                                                conversationId: currentChat.id,
                                                message: userMessage.content,
                                              );
                                            } catch (e) {

                                            } finally {
                                              setState(() {
                                                _isGeneratingResponse = false;
                                              });
                                            }
                                          }
                                        },
                                        onShare: () {
                                         // can use social_share lib - To share particular chat / message to others.
                                        },
                                        isLiked: isLiked,
                                        isDisliked: isDisliked,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),

          /// Select Images/Files, Send Text MSG, Buttons..
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [

                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => ImageSelectionBottomSheet(
                        onCameraTap: () async {
                          Navigator.of(context).pop();
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
                          if (pickedFile != null) {
                            await _handleImageSend(pickedFile.path);
                          }
                        },
                        onPhotosTap: () async {
                          Navigator.of(context).pop();
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
                          if (pickedFile != null) {
                            await _handleImageSend(pickedFile.path);
                          }
                        },
                        onFilesTap: () async {
                          Navigator.of(context).pop();
                          final result = await FilePicker.platform.pickFiles(type: FileType.image);
                          if (result != null && result.files.single.path != null) {
                            await _handleImageSend(result.files.single.path!);
                          }
                        },
                      ),
                    );
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.userBubbleLight,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Center(
                      child: SvgPicture.asset('assets/image.svg', color: AppColors.hint, width: 24, height: 24),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: widget._messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask anything',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintStyle: TextStyle(color: AppColors.hint),
                        filled: true,
                        fillColor: AppColors.userBubbleLight,
                        suffixIcon: Builder(
                          builder: (context) {
                            if (_isGeneratingResponse) {
                              return Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: SvgPicture.asset('assets/stop.svg', color: Colors.black, width: 20, height: 20),
                                  color: Colors.black,
                                  onPressed: () {
                                    setState(() {
                                      _isGeneratingResponse = false;
                                    });
                                  },
                                ),
                              );
                            }
                            // else if (widget._messageController.text.trim().isNotEmpty) {
                            //   return Container(
                            //     width: 36,
                            //     height: 36,
                            //     margin: const EdgeInsets.only(right: 4),
                            //     decoration: const BoxDecoration(
                            //       color: Colors.white,
                            //       shape: BoxShape.circle,
                            //     ),
                            //     child: IconButton(
                            //       icon: SvgPicture.asset('assets/send.svg', color: Colors.black, width: 20, height: 20),
                            //       color: Colors.black,
                            //       onPressed: () => _sendMessage(ref),
                            //     ),
                            //   );
                            // }
                            else {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: SvgPicture.asset('assets/mic.svg', color: AppColors.hint, width: 22, height: 22),
                                    color: Colors.white,
                                    onPressed: () {},
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: SvgPicture.asset('assets/send.svg', color: Colors.black, width: 20, height: 20),
                                      color: Colors.black,
                                      onPressed: () => _sendMessage(ref),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(ref),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // when hit send button
  void _sendMessage(WidgetRef ref) async {
    final messageContent = widget._messageController.text.trim();
    if (messageContent.isEmpty) return;

    setState(() {
      _isGeneratingResponse = true;
    });

    String? chatIdToUse = selectedChatId.isNotEmpty ? selectedChatId : null;
    if (chatIdToUse == null) {
      await ref.read(chatProvider.notifier).createNewChat();
      final chats = ref.read(chatProvider);
      if (chats.isNotEmpty) {
        setState(() {
          chatIdToUse = chats.first.id;
          selectedChatId = chatIdToUse!;
        });
      }
    }


    if (chatIdToUse != null && chatIdToUse!.isNotEmpty) {
      try {
        await ref.read(chatProvider.notifier).sendMessage(
          conversationId: chatIdToUse!,
          message: messageContent,
        );
        widget._messageController.clear();
      } catch (e) {
        // Handle error
        print('Error sending message: $e');
      } finally {
        setState(() {
          _isGeneratingResponse = false;
        });
      }
    } else {
      setState(() {
        _isGeneratingResponse = false;
      });
    }
  }

  // when image is to be sent
  Future<void> _handleImageSend(String filePath) async {
    String? uploadedImageUrl;
    try {
      setState(() {
        _isGeneratingResponse = true;
      });
      final apiService = ref.read(apiServiceProvider);
      final userId = ref.read(chatProvider.notifier).userId;
      uploadedImageUrl = await apiService.uploadImage(filePath);

      // 1. Optimistic UI: Add image message
      final chats = ref.read(chatProvider);
      if (chats.isNotEmpty) {
        final currentChat = chats.firstWhere((c) => c.id == selectedChatId, orElse: () => chats.first);
        currentChat.messages.add(
          Message(
            content: "",
            imageUrl: uploadedImageUrl,
            role: "user",
            status: MessageStatus.sent,
          ),
        );

        currentChat.messages.add(
          Message(
            content: "Use different model to get the contextual responses for images/files.",
            imageUrl: null,
            role: "assistant",
            status: MessageStatus.sent,
          ),
        );
        setState(() {});
      }

      String? chatIdToUse = selectedChatId.isNotEmpty ? selectedChatId : null;
      if (chatIdToUse == null) {
        await ref.read(chatProvider.notifier).createNewChat();
        final chats = ref.read(chatProvider);
        if (chats.isNotEmpty) {
          setState(() {
            chatIdToUse = chats.first.id;
            selectedChatId = chatIdToUse!;
          });
        }
      }
      if (chatIdToUse != null && chatIdToUse!.isNotEmpty) {
        await ref.read(chatProvider.notifier).sendMessage(
          conversationId: chatIdToUse!,
          message: '',
          imagePath: uploadedImageUrl,
        );
      }
    } catch (e) {
      // Optionally show error
    } finally {
      setState(() {
        _isGeneratingResponse = false;
      });
    }
  }
  // Future<void> _handleImageSend(String filePath) async {
  //   try {
  //     setState(() => _isGeneratingResponse = true);
  //
  //     // 1. Upload image first
  //     final uploadedImageUrl = await ref.read(apiServiceProvider).uploadImage(File(filePath));
  //
  //     // 2. Send message with image URL
  //     await ref.read(chatProvider.notifier).sendMessage(
  //       conversationId: selectedChatId,
  //       message: '', // Empty message for image-only
  //       imagePath: uploadedImageUrl,
  //     );
  //
  //   } catch (e) {
  //     // Show error to user
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to send image: ${e.toString()}')),
  //     );
  //   } finally {
  //     setState(() => _isGeneratingResponse = false);
  //   }
  // }
}