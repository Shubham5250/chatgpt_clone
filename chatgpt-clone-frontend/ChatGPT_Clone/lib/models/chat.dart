import 'package:uuid/uuid.dart';

import '../message_status.dart';
import 'message.dart';
import '../message_status.dart';
import 'message.dart';

import 'package:uuid/uuid.dart';
import 'message.dart';


class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;
  final MessageStatus status;
  static final Uuid _uuid = const Uuid();

  Chat({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.messages,
    this.status = MessageStatus.sent,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Chat copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    MessageStatus? status,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      status: status ?? this.status,
    );
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? json['_id'] ?? const Uuid().v4(), //for fallback
      title: json['title'] ?? 'ChatGPT',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ??
          (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now())
          : DateTime.now(),
      messages: (json['messages'] as List? ?? [])
          .map((msg) => Message.fromJson(msg))
          .toList(),
      status: MessageStatus.values.firstWhere(
            (e) => e.name == (json['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'status': status.name,
    };
  }
}