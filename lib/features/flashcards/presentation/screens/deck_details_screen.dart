import 'package:material_ui/material_ui.dart';

import '../../data/mock/mock_study_store.dart';
import '../../data/repositories/mock_study_repository.dart';
import '../../domain/models/deck.dart';
import '../../domain/models/flashcard.dart';
import '../../domain/models/study_progress.dart';
import '../../domain/repositories/study_repository.dart';
import '../../domain/services/study_session_controller.dart';

import 'create_deck_screen.dart';
import 'create_flashcard_screen.dart';
import 'study_session_screen.dart';

class DeckDetailsScreen extends StatefulWidget {
  final Deck deck;
  final MockStudyStore? store;
  final StudyRepository? repository;

  // Compatibility with previous tests.
  const DeckDetailsScreen({
    super.key,
    required this.deck,
    required MockStudyStore this.store,
  }) : repository = null;

  const DeckDetailsScreen.withRepository({
    super.key,
    required this.deck,
    required StudyRepository this.repository,
  }) : store = null;

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen> {
  late final StudyRepository _repository;
  late Deck deck;

  List<Flashcard> flashcards = const [];
  List<StudyProgress> _progress = const [];

  bool _loading = false;
  bool _busy = false;
  bool _loadFailed = false;

  bool get _disabled => _loading || _busy || _loadFailed;

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  // Matches the current Firebase transaction limit.
  static const _sessionLimit = 10;

  @override
  void initState() {
    super.initState();

    deck = widget.deck;

    _repository =
        widget.repository ?? MockStudyRepository(store: widget.store!);

    _reload();
  }

  // ==================================================
  // LOAD DECK, CARDS AND PROGRESS
  // ==================================================

  Future<void> _reload() async {
    if (!mounted || _loading) return;

    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      final decks = await _repository.fetchDecks();

      final latestDeck = decks.singleWhere((item) => item.id == deck.id);

      final cards = await _repository.fetchFlashcards(deckId: deck.id);

      final progress = await _repository.fetchProgress(deckId: deck.id);

      if (!mounted) return;

      final cardIds = cards.map((card) => card.id).toSet();

      setState(() {
        deck = latestDeck;
        flashcards = List.unmodifiable(cards);

        _progress = List.unmodifiable(
          progress.where((item) => cardIds.contains(item.cardId)),
        );
      });
    } catch (error) {
      debugPrint('Deck loading failed: ${error.runtimeType}');

      if (!mounted) return;

      setState(() {
        _loadFailed = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==================================================
  // ACTION MANAGEMENT
  // ==================================================

  void _notify(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (!mounted || _disabled) return;

    setState(() {
      _busy = true;
    });

    try {
      await action();
    } catch (error) {
      debugPrint('Deck action failed: ${error.runtimeType}');

      if (!mounted) return;

      _notify(
        'Unable to confirm the operation. '
        'Please check your connection.',
      );

      // Reconcile the UI with the database.
      await _reload();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result == true;
  }

  // ==================================================
  // DECK CRUD
  // ==================================================

  Future<void> _editDeck() => _runAction(() async {
    final draft = await Navigator.of(context).push<DeckDraft>(
      MaterialPageRoute(
        builder: (_) => CreateDeckScreen(
          initialDeck: deck,
          onSubmit: (draft) => _repository.updateDeck(
            deckId: deck.id,
            title: draft.title,
            description: draft.description,
          ),
        ),
      ),
    );

    if (!mounted || draft == null) return;

    _notify('Deck updated successfully!');
    await _reload();
  });

  Future<void> _deleteDeck() => _runAction(() async {
    final confirmed = await _confirm(
      'Delete deck?',
      'This will delete "${deck.title}" and its '
          '${flashcards.length} flashcards. '
          'This action cannot be undone.',
    );

    if (!mounted || !confirmed) return;

    await _repository.deleteDeck(deck.id);

    if (!mounted) return;

    Navigator.of(context).pop();
  });

  // ==================================================
  // FLASHCARD CRUD
  // ==================================================

  Future<void> _addFlashcard() => _openFlashcardEditor();

  Future<void> _editFlashcard(Flashcard card) =>
      _openFlashcardEditor(card: card);

  Future<void> _openFlashcardEditor({Flashcard? card}) => _runAction(() async {
    final draft = await Navigator.of(context).push<FlashcardDraft>(
      MaterialPageRoute(
        builder: (_) => CreateFlashcardScreen(
          deckTitle: deck.title,
          initialCard: card,
          onSubmit: (draft) async {
            if (card == null) {
              await _repository.createFlashcard(
                deckId: deck.id,
                front: draft.front,
                back: draft.back,
              );
            } else {
              await _repository.updateFlashcard(
                deckId: deck.id,
                cardId: card.id,
                front: draft.front,
                back: draft.back,
              );
            }
          },
        ),
      ),
    );

    if (!mounted || draft == null) return;

    _notify(
      card == null
          ? 'Flashcard added successfully!'
          : 'Flashcard updated successfully!',
    );

    await _reload();
  });

  Future<void> _deleteFlashcard(Flashcard card) => _runAction(() async {
    final confirmed = await _confirm(
      'Delete flashcard?',
      'Delete "${card.front}"? '
          'This action cannot be undone.',
    );

    if (!mounted || !confirmed) return;

    await _repository.deleteFlashcard(deckId: deck.id, cardId: card.id);

    if (!mounted) return;

    _notify('Flashcard deleted successfully!');
    await _reload();
  });

  // ==================================================
  // STUDY SESSION SELECTION
  // ==================================================

  Future<void> _startStudy() => _runAction(() async {
    await _openStudySession(flashcards);
  });

  Future<void> _reviewStillLearning() => _runAction(() async {
    final cards = await _repository.fetchCardsNeedingReview(deckId: deck.id);

    if (!mounted) return;

    if (cards.isEmpty) {
      _notify('No cards currently need review.');
      await _reload();
      return;
    }

    await _openStudySession(cards);
  });

  Future<List<Flashcard>?> _selectBatch(List<Flashcard> cards) async {
    if (cards.length <= _sessionLimit) {
      return cards;
    }

    final batchCount = (cards.length / _sessionLimit).ceil();

    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose a study batch'),
        children: [
          for (var i = 0; i < batchCount; i++)
            SimpleDialogOption(
              key: ValueKey('study_batch_$i'),
              onPressed: () => Navigator.pop(dialogContext, i),
              child: Text(
                'Batch ${i + 1}: Cards '
                '${i * _sessionLimit + 1}–'
                '${cards.skip(i * _sessionLimit).take(_sessionLimit).length + i * _sessionLimit}',
              ),
            ),
        ],
      ),
    );

    if (selected == null) return null;

    return cards.skip(selected * _sessionLimit).take(_sessionLimit).toList();
  }

  Future<void> _openStudySession(List<Flashcard> cards) async {
    if (cards.isEmpty || !mounted) return;

    final selected = await _selectBatch(cards);

    if (!mounted || selected == null || selected.isEmpty) {
      return;
    }

    final deckId = deck.id;

    final session = StudySessionController(deckId: deckId, cards: selected);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StudySessionScreen(
          deckTitle: deck.title,
          session: session,
          onSessionCompleted: (results) async {
            // Detect content changes before saving.
            final currentCards = await _repository.fetchFlashcards(
              deckId: deckId,
            );

            final currentById = {
              for (final card in currentCards) card.id: card,
            };

            for (final original in selected) {
              final current = currentById[original.id];

              if (current == null ||
                  current.front != original.front ||
                  current.back != original.back) {
                throw StateError(
                  'Flashcard content changed '
                  'during this study session.',
                );
              }
            }

            await _repository.saveSessionResults(
              deckId: deckId,
              results: results,
            );
          },
        ),
      ),
    );

    if (!mounted) return;

    await _reload();
  }

  // ==================================================
  // PROGRESS CALCULATIONS
  // ==================================================

  int get _gotIt =>
      _progress.where((item) => item.lastResult == StudyResult.gotIt).length;

  int get _stillLearning => _progress
      .where((item) => item.lastResult == StudyResult.stillLearning)
      .length;

  int get _notReviewed => flashcards.length - _progress.length;

  // ==================================================
  // SCREEN
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: AppBar(
          title: const Text('Deck Details'),
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,

          actions: [
            IconButton(
              tooltip: 'Refresh deck',
              onPressed: _loading || _busy ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),

            IconButton(
              tooltip: 'Edit deck',
              onPressed: _disabled ? null : _editDeck,
              icon: const Icon(Icons.edit_outlined),
            ),

            IconButton(
              tooltip: 'Delete deck',
              onPressed: _disabled ? null : _deleteDeck,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('add_flashcard_button'),
          onPressed: _disabled ? null : _addFlashcard,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Flashcard'),
        ),

        body: SafeArea(
          child: Column(
            children: [
              if (_busy && !_loading) const LinearProgressIndicator(),

              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        key: ValueKey('details_loading_state'),
        child: CircularProgressIndicator(),
      );
    }

    if (_loadFailed) {
      return Center(
        key: const ValueKey('details_error_state'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),

              const SizedBox(height: 16),

              const Text(
                'Unable to load this deck.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              FilledButton(
                key: const ValueKey('retry_details_button'),
                onPressed: _busy ? null : _reload,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (!_busy) await _reload();
      },

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

        children: [
          _buildDeckSummary(),

          const SizedBox(height: 24),

          _buildLearningProgress(),

          const SizedBox(height: 24),

          FilledButton.icon(
            key: const ValueKey('start_study_button'),
            onPressed: _disabled || flashcards.isEmpty ? null : _startStudy,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Study'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            key: const ValueKey('review_still_learning_button'),
            onPressed: _disabled || _stillLearning == 0
                ? null
                : _reviewStillLearning,
            icon: const Icon(Icons.refresh),
            label: Text('Review Still Learning ($_stillLearning)'),
          ),

          if (flashcards.length > _sessionLimit)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Choose study batches of up to 10 cards.',
                textAlign: TextAlign.center,
              ),
            ),

          if (flashcards.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Add at least one flashcard to start studying.',
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          const Text(
            'Flashcards',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          if (flashcards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No flashcards yet')),
            )
          else
            ...flashcards.map(_buildFlashcard),
        ],
      ),
    );
  }

  Widget _buildDeckSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: lavenderColor,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.style_outlined, color: primaryColor, size: 36),

          const SizedBox(height: 16),

          Text(
            deck.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          if (deck.description.isNotEmpty) Text(deck.description),

          const SizedBox(height: 16),

          Text('${flashcards.length} flashcards'),
        ],
      ),
    );
  }

  Widget _buildLearningProgress() {
    final fraction = flashcards.isEmpty ? 0.0 : _gotIt / flashcards.length;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Learning Progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${(fraction * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text('Based on your latest flashcard ratings.'),

            const SizedBox(height: 16),

            LinearProgressIndicator(value: fraction, minHeight: 8),

            const SizedBox(height: 20),

            _buildProgressRow('Got It', _gotIt, const Color(0xFF15803D)),

            const SizedBox(height: 12),

            _buildProgressRow(
              'Still Learning',
              _stillLearning,
              const Color(0xFFB45309),
            ),

            const SizedBox(height: 12),

            _buildProgressRow('Not Reviewed', _notReviewed, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          '$count',
          key: ValueKey('progress_$label'),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFlashcard(Flashcard card) {
    return Card(
      key: ValueKey(card.id),
      color: Colors.white,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('QUESTION')),

                IconButton(
                  tooltip: 'Edit flashcard',
                  onPressed: _disabled ? null : () => _editFlashcard(card),
                  icon: const Icon(Icons.edit_outlined, color: primaryColor),
                ),

                IconButton(
                  tooltip: 'Delete flashcard',
                  onPressed: _disabled ? null : () => _deleteFlashcard(card),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),

            Text(
              card.front,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const Divider(height: 24),

            const Text('ANSWER'),

            const SizedBox(height: 8),

            Text(card.back),
          ],
        ),
      ),
    );
  }
}
