import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatgpt_clone/providers/chat_provider.dart';


/// APPEARS BELOW EACH LATEST AI RESPONSE MESSAGE - IN CHAT SCREEN
class MessageActionBar extends ConsumerStatefulWidget {
  final String messageContent;
  final VoidCallback? onCopy;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSpeaker;
  final VoidCallback? onRegenerate;
  final VoidCallback? onShare;
  final bool isLiked;
  final bool isDisliked;

  const MessageActionBar({
    super.key,
    required this.messageContent,
    this.onCopy,
    this.onLike,
    this.onDislike,
    this.onSpeaker,
    this.onRegenerate,
    this.onShare,
    this.isLiked = false,
    this.isDisliked = false,
  });

  @override
  ConsumerState<MessageActionBar> createState() => _MessageActionBarState();
}

class _MessageActionBarState extends ConsumerState<MessageActionBar> {
  bool _showActions = false;  String? selectedModel;



  @override
  void initState() {
    super.initState();
    // Show actions after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showActions = true;
        });
      }
    });
    selectedModel = ref.read(selectedModelProvider);

  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.messageContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
    widget.onCopy?.call();
  }


  void _showRegenerateMenu(BuildContext context, Offset offset, WidgetRef ref) async {
    final selectedModel = ref.read(selectedModelProvider);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx + 1, offset.dy + 1),
      color: Colors.grey[900],
      items: [
        PopupMenuItem<String>(
          value: 'regenerate',
          child: Row(
            children: [
              const Icon(Icons.refresh, color: Colors.white),
              const SizedBox(width: 10),
              const Text('Regenerate Response', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_model',
          child: Row(
            children: [
              const Icon(Icons.memory, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Text('Change Model (${selectedModel})', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );

    // regenerates response
    if (selected == 'regenerate') {
      widget.onRegenerate?.call();
    } else if (selected == 'change_model') {
      // provided model options - Passed as parameter in API service sendMessage()
      String tempSelected = selectedModel ?? 'gpt-4.1-nano';
      final modelOptions = [
        'gpt-4.1-nano',
        'gpt-4.1-turbo',
        'gpt-4.1-pro',
        'gpt-3.5-turbo',
        'gpt-3.5-lite',
      ];

      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Select Model', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: modelOptions.map((model) {
                  return RadioListTile<String>(
                    value: model,
                    groupValue: tempSelected,
                    onChanged: (value) {
                      setState(() {
                        tempSelected = value!;
                      });
                    },
                    title: Text(model, style: const TextStyle(color: Colors.white)),
                    activeColor: Colors.greenAccent,
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(tempSelected),
                  child: const Text('OK', style: TextStyle(color: Colors.greenAccent)),
                ),
              ],
            ),
          );
        },
      );

      if (result != null) {
        ref.read(selectedModelProvider.notifier).state = result;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showActions) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildActionButton(
            icon: 'assets/copy.svg',
            onTap: _copyToClipboard,
            tooltip: 'Copy',
          ),
          _buildActionButton(
            icon: widget.isLiked ? 'assets/like_filled.svg' : 'assets/like.svg',
            onTap: widget.onLike,
            tooltip: 'Like',
            isActive: widget.isLiked,
          ),
          _buildActionButton(
            icon: 'assets/dislike.svg',
            onTap: widget.onDislike,
            tooltip: 'Dislike',
            isActive: widget.isDisliked,
            show: !widget.isLiked,
          ),
          _buildActionButton(
            icon: 'assets/speaker.svg',
            onTap: widget.onSpeaker,
            tooltip: 'Read aloud',
          ),
          _buildActionButton(
            icon: 'assets/regenerate.svg',
            onTap: () async {
              final RenderBox button = context.findRenderObject() as RenderBox;
              final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
              final offset = button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay);
              _showRegenerateMenu(context, offset, ref);
            },
            tooltip: 'Regenerate',
          ),
          _buildActionButton(
            icon: 'assets/share.svg',
            onTap: widget.onShare,
            tooltip: 'Share',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool isActive = false,
    bool show = true,
  }) {
    if (!show) {
      return const SizedBox.shrink(); //hide dislike , when hit like button
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(right: 4),
          child: SvgPicture.asset(
            icon,
            color: isActive ? Colors.green : Colors.white,
            width: 18,
            height: 18,
          ),
        ),
      ),
    );
  }
} 