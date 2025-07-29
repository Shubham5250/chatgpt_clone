import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Make sure this file exists
import 'package:chatgpt_clone/providers/chat_provider.dart';
import 'package:chatgpt_clone/providers/auth_provider.dart';
import 'package:chatgpt_clone/widgets/sidebar.dart';
import 'package:chatgpt_clone/screens/main_screen.dart';
import 'package:chatgpt_clone/screens/login_screen.dart';
import 'models/chat.dart';
import 'screens/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {

    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize Firebase. Please restart the app.'),
        ),
      ),
    ));
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final authState = ref.watch(authProvider.notifier).state;
    return MaterialApp(
      title: 'ChatGPT Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF181818),

      ),
      home: user != null
          ? MainScreen(userId: user.uid)
          : const LoginScreen(),
    );
  }
}