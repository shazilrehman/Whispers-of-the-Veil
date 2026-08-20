import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/whispers_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait and hide system UI for immersive experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [],
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF050510),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const WhispersApp());
}

class WhispersApp extends StatelessWidget {
  const WhispersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whispers of the Veil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF050510),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<WhispersGame>(
        game: WhispersGame(),
        loadingBuilder: (_) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9B6DFF),
          ),
        ),
        errorBuilder: (context, error) => Center(
          child: Text(
            'Something went wrong:\n$error',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
