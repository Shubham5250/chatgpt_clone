import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../message_status.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'dart:io';


final selectedModelProvider = StateProvider<String>((ref) => 'gpt-4.1-nano');


class ChatNotifier extends StateNotifier<List<Chat>> {
  final ApiService _apiService;
  final Ref ref;

  final String userId;
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;


  ChatNotifier(this.ref, this._apiService, this.userId) : super([]) {
  // initially loads all chats for user
    _loadChats();
  }

  // for selected model
  String get selectedModel => ref.read(selectedModelProvider);
  ApiService get apiService => _apiService;

  bool get isLoading => _isLoading;

  Future<void> _loadChats() async {
    try {
      _isLoading = true;
      state = await _apiService.getUserChats(userId);
    } catch (e) {
      print('Error loading chats from API: $e');
      state = [];
    } finally {
      _isLoading = false;
    }
  }

  // registers new chat -
  Future<void> createNewChat() async {
    try {
      final newChat = await _apiService.createNewChat(userId);
      state = [newChat, ...state];
    } catch (e) {
      throw Exception('Failed to create new chat: $e');
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String message,
    String? imagePath,
  }) async {
    Message? optimisticMessage;

    try {
      bool addOptimistic = message.trim().isNotEmpty && (imagePath == null);
      if (addOptimistic) {
        optimisticMessage = Message(
          id: _uuid.v4(),
          content: message,
          role: 'user',
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          imageUrl: imagePath,
        );

        state = [
          ...state.map((chat) => chat.id == conversationId
              ? chat.copyWith(
            messages: [...chat.messages, optimisticMessage!],
            updatedAt: DateTime.now(),
          )
              : chat),
        ];
      }

      String? finalImageUrl;
      if (imagePath != null && !imagePath.startsWith('http')) {
        try {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            finalImageUrl = await _apiService.uploadImage(imageFile);
          }
        } catch (e) {
          print('Image upload error: $e');
        }
      }

      final selectedModel = ref.read(selectedModelProvider);
      final response = await _apiService.sendMessage(
        userId: userId,
        message: message,
        conversationId: conversationId.isEmpty ? null : conversationId,
        imagePath: finalImageUrl ?? imagePath,
        model: selectedModel,
      );

      final serverMessage = Message.fromJson(response['userMessage']);
      final aiMessage = Message.fromJson(response['aiMessage']);
      final String? info = response['infoMessage'];

      final chat = state.firstWhere((c) => c.id == response['conversationId']);
      final alreadyHasImage = serverMessage.imageUrl != null &&
          chat.messages.any((m) => m.imageUrl == serverMessage.imageUrl);

      final List<Message> newMessages = [];

      if (!alreadyHasImage) {
        newMessages.add(serverMessage);
      }

      if (info != null && info.trim().isNotEmpty) {
        newMessages.add(
          Message(
            id: _uuid.v4(),
            content: info,
            role: 'system',
            timestamp: DateTime.now(),
          ),
        );
      }
      newMessages.add(aiMessage);

      state = [
        ...state.map((chat) {
          if (chat.id == response['conversationId']) {
            return chat.copyWith(
              id: response['conversationId'],
              title: response['title'],
              messages: [
                ...chat.messages.where(
                        (m) => optimisticMessage == null || m.id != optimisticMessage.id),
                ...newMessages,
              ],
              updatedAt: DateTime.parse(response['updatedAt']),
            );
          }
          return chat;
        }),
      ];
    } catch (e) {
      state = [
        ...state.map((chat) => chat.id == conversationId
            ? chat.copyWith(
          messages: chat.messages
              .where((m) => optimisticMessage == null || m.id != optimisticMessage.id)
              .toList(),
        )
            : chat),
      ];
      rethrow;
    }
  }


  Future<void> addTemporaryShimmerMessage({required String chatId, required Message message}) async {
    state = [
      for (final chat in state)
        if (chat.id == chatId)
          chat.copyWith(messages: [...chat.messages, message])
        else
          chat,
    ];
  }

  Future<void> replaceMessage({
    required String chatId,
    required String oldMessageId,
    required Message newMessage,
  }) async {
    state = [
      for (final chat in state)
        if (chat.id == chatId)
          chat.copyWith(
            messages: [
              for (final msg in chat.messages)
                if (msg.id == oldMessageId) newMessage else msg
            ],
          )
        else
          chat,
    ];
  }

  Future<void> addMessage({required String chatId, required Message message}) async {
    state = [
      for (final chat in state)
        if (chat.id == chatId)
          chat.copyWith(messages: [...chat.messages, message])
        else
          chat,
    ];
  }



  Future<void> loadMessages(String conversationId) async {
    try {
      final messages = await _apiService.getChatMessages(conversationId);
      state = state.map((chat) {
        return chat.id == conversationId
            ? chat.copyWith(messages: messages)
            : chat;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }


  Future<void> refreshChats() async {
    await _loadChats();
  }

  Future<void> deleteChat(String conversationId) async {
    try {
      await _apiService.deleteChat(conversationId);
      state = state.where((chat) => chat.id != conversationId).toList();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }
}


final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final chatProvider = StateNotifierProvider<ChatNotifier, List<Chat>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState?.uid ?? 'test_user_123'; // Fallback for testing
  return ChatNotifier(ref, apiService, userId);
});