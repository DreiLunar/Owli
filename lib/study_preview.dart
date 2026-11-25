import 'package:material_ui/material_ui.dart';

import 'features/flashcards/presentation/screens/deck_library_screen.dart';

void main() {
  runApp(const StudyPreviewApp());
}

class StudyPreviewApp extends StatelessWidget {
  const StudyPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owli Study Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
      ),
      home: const DeckLibraryScreen(),
    );
  }
}
