import 'package:material_ui/material_ui.dart';

import '../../data/repositories/mock_study_repository.dart';
import '../../domain/models/deck.dart';
import '../../domain/repositories/study_repository.dart';

import 'create_deck_screen.dart';
import 'deck_details_screen.dart';

class DeckLibraryScreen extends StatefulWidget {
  final StudyRepository? repository;
  final String? subjectId;
  final Widget Function(BuildContext, Deck)? detailsBuilder;

  // Backward-compatible mock preview.
  const DeckLibraryScreen({super.key})
    : repository = null,
      subjectId = null,
      detailsBuilder = null;

  // Explicit repository injection.
  const DeckLibraryScreen.withRepository({
    super.key,
    required StudyRepository this.repository,
    required String this.subjectId,
    this.detailsBuilder,
  });

  @override
  State<DeckLibraryScreen> createState() => _DeckLibraryScreenState();
}

class _DeckLibraryScreenState extends State<DeckLibraryScreen> {
  late final StudyRepository _repository;
  late final String _subjectId;
  late final Widget Function(BuildContext, Deck) _detailsBuilder;

  final _searchController = TextEditingController();

  List<Deck> _decks = const [];
  Map<String, int> _cardCounts = const {};

  String _searchQuery = '';

  bool _isLoading = false;
  bool _isNavigating = false;
  bool _hasError = false;

  bool get _isBusy => _isLoading || _isNavigating;

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  int get _totalCardCount =>
      _cardCounts.values.fold(0, (total, count) => total + count);

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? MockStudyRepository();
    _subjectId = widget.subjectId ?? 'mock-subject';
    _detailsBuilder =
        widget.detailsBuilder ??
        (_, deck) => DeckDetailsScreen.withRepository(
          deck: deck,
          repository: _repository,
        );

    _loadDecks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================================================
  // ASYNCHRONOUS LIBRARY LOADING
  // ==================================================

  Future<void> _loadDecks() async {
    if (!mounted || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final decks = await _repository.fetchDecks();

      if (!mounted) {
        return;
      }

      final entries = await Future.wait(
        decks.map((deck) async {
          final cards = await _repository.fetchFlashcards(deckId: deck.id);

          return MapEntry(deck.id, cards.length);
        }),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _decks = List<Deck>.unmodifiable(decks);

        _cardCounts = Map<String, int>.unmodifiable(
          Map<String, int>.fromEntries(entries),
        );

        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Deck library load failed: '
        '${error.runtimeType}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ==================================================
  // CREATE DECK
  // ==================================================

  Future<void> _createDeck() async {
    if (_isBusy || _hasError) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      final draft = await Navigator.of(context).push<DeckDraft>(
        MaterialPageRoute(
          builder: (_) => CreateDeckScreen(
            onSubmit: (draft) async {
              await _repository.createDeck(
                subjectId: _subjectId,
                title: draft.title,
                description: draft.description,
              );
            },
          ),
        ),
      );

      if (!mounted || draft == null) {
        return;
      }

      _searchController.clear();

      setState(() {
        _searchQuery = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck created successfully!')),
      );

      // Reload only after confirmed creation.
      await _loadDecks();
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  // ==================================================
  // OPEN DECK DETAILS
  // ==================================================

  Future<void> _openDeck(Deck deck) async {
    if (_isBusy || _hasError) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (context) => _detailsBuilder(context, deck)),
      );

      if (!mounted) {
        return;
      }

      // Refresh after any changes in Deck Details.
      await _loadDecks();
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  // ==================================================
  // SCREEN
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Study',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            key: const ValueKey('refresh_library_button'),
            tooltip: 'Refresh library',
            onPressed: _isBusy ? null : _loadDecks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('create_deck_button'),

        onPressed: _isBusy || _hasError ? null : _createDeck,

        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Deck'),
      ),

      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        key: ValueKey('library_loading_state'),
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    final query = _searchQuery.trim().toLowerCase();

    final filteredDecks = _decks.where((deck) {
      return deck.title.toLowerCase().contains(query) ||
          deck.description.toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadDecks,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

        children: [
          const Text('Build your knowledge, one card at a time.'),

          const SizedBox(height: 24),

          _buildLibrarySummary(),

          const SizedBox(height: 24),

          TextField(
            key: const ValueKey('deck_search_field'),
            controller: _searchController,

            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },

            decoration: InputDecoration(
              hintText: 'Search your decks...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              const Text(
                'My Decks',

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              Text('${filteredDecks.length} decks'),
            ],
          ),

          const SizedBox(height: 16),

          if (filteredDecks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),

              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),

                  const SizedBox(height: 12),

                  Text(
                    _decks.isEmpty ? 'No decks yet' : 'No decks found',

                    key: const ValueKey('library_empty_state'),
                  ),

                  if (_decks.isEmpty)
                    const Text('Create your first study deck.'),
                ],
              ),
            )
          else
            ...filteredDecks.map(_buildDeckCard),
        ],
      ),
    );
  }

  // ==================================================
  // LIBRARY SUMMARY
  // ==================================================

  Widget _buildLibrarySummary() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: lavenderColor,
        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'YOUR LIBRARY',

            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          Text(
            '${_decks.length} Decks',

            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C1D95),
            ),
          ),

          Text(
            '$_totalCardCount flashcards to explore',

            style: const TextStyle(color: primaryColor),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // DECK CARD
  // ==================================================

  Widget _buildDeckCard(Deck deck) {
    final cardCount = _cardCounts[deck.id] ?? 0;

    return Card(
      key: ValueKey('library_deck_${deck.id}'),

      color: Colors.white,

      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        onTap: _isBusy ? null : () => _openDeck(deck),

        leading: Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: lavenderColor,

            borderRadius: BorderRadius.circular(14),
          ),

          child: const Icon(Icons.style_outlined, color: primaryColor),
        ),

        title: Text(
          deck.title,

          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            if (deck.description.isNotEmpty) Text(deck.description),

            const SizedBox(height: 6),

            Text(
              '$cardCount cards',

              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  // ==================================================
  // ERROR STATE
  // ==================================================

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('library_error_state'),

      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),

            const SizedBox(height: 16),

            const Text(
              'Unable to load your decks',

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            FilledButton(
              key: const ValueKey('retry_library_button'),

              onPressed: _isBusy ? null : _loadDecks,

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
