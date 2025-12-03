import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  runApp(WordlistApp(storageService: storageService));
}

class WordlistApp extends StatelessWidget {
  final StorageService storageService;

  const WordlistApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordlist Elicitation Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        useMaterial3: true,
      ),
      home: HomeScreen(storageService: storageService),
      debugShowCheckedModeBanner: false,
    );
  }
}
