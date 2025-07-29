import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageActionsProvider =
StateNotifierProvider<MessageActionsNotifier, Map<String, Map<String, bool>>>(
      (ref) => MessageActionsNotifier(),
);

class MessageActionsNotifier
    extends StateNotifier<Map<String, Map<String, bool>>> {
  MessageActionsNotifier() : super({});

  void toggleLike(String messageId) {
    final current = state[messageId] ?? {};
    final liked = !(current['liked'] ?? false);
    state = {
      ...state,
      messageId: {
        ...current,
        'liked': liked,
        'disliked': false,
      }
    };
  }

  void toggleDislike(String messageId) {
    final current = state[messageId] ?? {};
    final disliked = !(current['disliked'] ?? false);
    state = {
      ...state,
      messageId: {
        ...current,
        'disliked': disliked,
        'liked': false,
      }
    };
  }

  void reset(String messageId) {
    state = {
      ...state,
      messageId: {
        'liked': false,
        'disliked': false,
      }
    };
  }
}
