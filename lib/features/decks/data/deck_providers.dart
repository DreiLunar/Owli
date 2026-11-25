import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'deck_repository.dart';

final deckRepositoryProvider = Provider((ref) => DeckRepository());