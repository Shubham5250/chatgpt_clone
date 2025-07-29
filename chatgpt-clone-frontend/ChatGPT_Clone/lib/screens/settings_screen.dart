import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../constants/colors.dart';

/// SETTINGS SCREEN - FOR USER INFO, MODEL SELECTION, LOGOUT...
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String selectedModel = 'gpt-4.1-nano';
  final List<String> modelOptions = [
    'gpt-4.1-nano',
    'gpt-4.1-turbo',
    'gpt-4.1-pro',
    'gpt-3.5-turbo',
    'gpt-3.5-lite',
  ];

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.read(authProvider.notifier).getUserProfile();
    final phoneNumber = userProfile['phoneNumber'] ?? '+1 234 567 8900';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        children: [
          // User info
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.userBubbleLight,
              backgroundImage: userProfile['photoURL'] != null
                  ? NetworkImage(userProfile['photoURL'])
                  : null,
              child: userProfile['photoURL'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(
              userProfile['displayName'] ?? 'User',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              userProfile['email'] ?? 'user@example.com',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const Divider(color: Colors.grey),
          // Phone number
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.white),
            title: const Text('Phone Number', style: TextStyle(color: Colors.white)),
            subtitle: Text(phoneNumber, style: const TextStyle(color: Colors.grey)),
          ),
          const Divider(color: Colors.grey),
          // Model selection
          ListTile(
            leading: const Icon(Icons.memory, color: Colors.white),
            title: const Text('Model', style: TextStyle(color: Colors.white)),
            trailing: Text(selectedModel, style: const TextStyle(color: Colors.greenAccent)),
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (context) {
                  String tempSelected = selectedModel;
                  return AlertDialog(
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
                            Navigator.of(context).pop(value);
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
                  );
                },
              );
              if (result != null && result != selectedModel) {
                setState(() {
                  selectedModel = result;
                });
              }
            },
          ),
          const Divider(color: Colors.grey),
          // Logout option
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
} 