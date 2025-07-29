import 'package:uuid/uuid.dart';
import '../message_status.dart';

class Message {
  final String id;
  final String content;
  final String role;
  final DateTime timestamp;
  final MessageStatus status;
  final String? imageUrl;
  static final Uuid _uuid = const Uuid();
  final bool isUploading;

  Message({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.imageUrl,
    this.isUploading = false,
  }) :
        id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'],
      content: json['content'] ?? '',
      role: json['role'] ?? 'user',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      status: MessageStatus.values.firstWhere(
            (e) => e.name == (json['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      imageUrl: json['imageUrl'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'imageUrl': imageUrl,
    };
  }

  Message copyWith({
    String? id,
    String? content,
    String? role,
    DateTime? timestamp,
    MessageStatus? status,
    String? imageUrl,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}