import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'dart:io';


/// FILE THAT HANDLES ALL API CALLS USES - DIO PACKAGE (HTTP CLIENT LIB)
class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: dotenv.get('API_BASE_URL'),
    headers: {'Content-Type': 'application/json'},
  ));


  // Get all conversations for a user
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      final response = await _dio.get('/api/conversations/$userId');
      return (response.data['conversations'] as List)
          .map((json) => Chat.fromJson(json))
          .toList();
    } on DioException catch (e) {
      print('getUserChats error: ${e.message}');
      return [];
    }
  }

  // Get messages for a specific conversation
  Future<List<Message>> getChatMessages(String conversationId) async {
    try {
      final response = await _dio.get('/api/conversations/$conversationId/messages');
      return (response.data['conversation']['messages'] as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } on DioException catch (e) {
      print('getChatMessages error: ${e.message}');
      return [];
    }
  }

  // Send message to AI and get response
  Future<Map<String, dynamic>> sendMessage({
    required String userId,
    required String message,
    String? conversationId,
    String? imagePath,
    String model = 'gpt-4.1-nano',
  }) async {
    try {
      Map<String, dynamic> requestData = {
        'userId': userId,
        'message': message,
        'model': model,
      };


      if (conversationId != null) {
        requestData['conversationId'] = conversationId;
      }


      // if (imagePath != null) {
      //   requestData['image'] = await MultipartFile.fromFile(imagePath);
      // }
      if (imagePath != null) {
        requestData['imageUrl'] = imagePath;
      }

      final response = await _dio.post('/api/chat', data: requestData);

      return {
        'conversationId': response.data['conversationId'],
        'title': response.data['title'] ?? _generateTitleFromMessage(message),
        'userMessage': {
          'content': message,
          'role': 'user',
          'timestamp': DateTime.now().toIso8601String(),
          'imageUrl': imagePath,
        },
        'aiMessage': {
          'content': response.data['reply'],
          'role': 'assistant',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'updatedAt': DateTime.now().toIso8601String(),
      };
    } on DioException catch (e) {
      print('ApiService DioException: ${e.message}');
      print('ApiService DioException response: ${e.response?.data}');
      throw Exception('Failed to send message: ${e.message}');
    }
  }


  // Future<void> updateChatTitle(String conversationId, String newTitle) async {
  //   try {
  //     await _dio.put('/api/conversations/$conversationId/title', data: {
  //       'title': newTitle,
  //     });
  //   } on DioException catch (e) {
  //     print('updateChatTitle error: ${e.message}');
  //     throw Exception('Failed to update chat title: ${e.message}');
  //   }
  // }


  Future<void> deleteChat(String conversationId) async {
    try {
      await _dio.delete('/api/conversations/$conversationId');
    } on DioException catch (e) {
      print('deleteChat error: ${e.message}');
      throw Exception('Failed to delete chat: ${e.message}');
    }
  }

  String _generateTitleFromMessage(String message) {
    String cleanMessage = message.trim();
    if (cleanMessage.length > 50) {
      cleanMessage = cleanMessage.substring(0, 50) + '...';
    }
    return cleanMessage;
  }


Future<Chat> createNewChat(String userId) async {
  try {
    final response = await _dio.post('/api/conversations', data: {
      'userId': userId,
    });
    return Chat(
      id: response.data['conversationId'],
      title: response.data['title'] ?? 'New Chat',
      messages: [],
    );
  } on DioException catch (e) {
    print('createNewChat error: ${e.message}');
    return Chat(
      id: const Uuid().v4(), // fallback
      title: 'New Chat',
      messages: [],
    );
  }
}

// HANDLES IMAGE UPLOAD
  Future<String> uploadImage(dynamic imageSource) async {
    try {
      late MultipartFile multipartFile;

      if (imageSource is File) {

        multipartFile = await MultipartFile.fromFile(imageSource.path);
      } else if (imageSource is String) {

        final file = File(imageSource);
        if (!await file.exists()) {
          throw Exception('File not found at path: $imageSource');
        }
        multipartFile = await MultipartFile.fromFile(imageSource);
      } else {
        throw ArgumentError('imageSource must be either a File or String path');
      }

      final formData = FormData.fromMap({
        'image': multipartFile,
      });

      final response = await _dio.post(
        '/api/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data == null || response.data['url'] == null) {
        throw Exception('Invalid response format from server');
      }

      return response.data['url'] as String;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ?? e.message;
      print('Image upload failed. Status: ${e.response?.statusCode}, Error: $errorMessage');
      throw Exception('Image upload failed: $errorMessage');
    } catch (e) {
      print('Unexpected error during image upload: $e');
      throw Exception('Image upload failed: ${e.toString()}');
    }
  }
  // Future<String?> uploadImage(File imageFile) async {
  //   try {
  //     final formData = FormData.fromMap({
  //       'image': await MultipartFile.fromFile(
  //         imageFile.path,
  //         filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
  //       ),
  //     });
  //
  //     final response = await _dio.post(
  //       '/api/upload',
  //       data: formData,
  //       options: Options(
  //         contentType: 'multipart/form-data',
  //       ),
  //     );
  //
  //     return response.data['url'] as String;
  //   } catch (e) {
  //     print('Image upload error: $e');
  //     return null;
  //   }
  // }
}
