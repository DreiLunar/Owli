import 'package:material_ui/material_ui.dart';

import '../../domain/models/deck.dart';

class DeckDraft {
  final String title;
  final String description;

  const DeckDraft({required this.title, required this.description});
}

class CreateDeckScreen extends StatefulWidget {
  final Deck? initialDeck;

  final Future<void> Function(DeckDraft draft)? onSubmit;

  const CreateDeckScreen({super.key, this.initialDeck, this.onSubmit});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;
  bool _saveFailed = false;

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  bool get _isEditing => widget.initialDeck != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.initialDeck?.title ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.initialDeck?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ==================================================
  // ASYNCHRONOUS DECK SAVING
  // ==================================================

  Future<void> _submitDeck() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    final draft = DeckDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    final callback = widget.onSubmit;

    // Preserve the existing draft-returning behavior.
    if (callback == null) {
      Navigator.pop(context, draft);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });

    try {
      await callback(draft);

      if (!mounted) {
        return;
      }

      // Close only after the repository confirms saving.
      Navigator.pop(context, draft);
    } catch (error) {
      debugPrint('Deck save failed: ${error.runtimeType}');

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveFailed = true;
      });
    }
  }

  // ==================================================
  // INPUT DECORATION
  // ==================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8E2F3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8E2F3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  // ==================================================
  // SCREEN
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return PopScope<DeckDraft>(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: AppBar(
          title: Text(
            _isEditing ? 'Edit Deck' : 'Create Deck',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
        ),

        body: SafeArea(
          child: Form(
            key: _formKey,

            child: ListView(
              padding: const EdgeInsets.all(24),

              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,

                    decoration: BoxDecoration(
                      color: lavenderColor,
                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: const Icon(
                      Icons.style_outlined,
                      size: 40,
                      color: primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _isEditing
                      ? 'Update your deck'
                      : 'Start learning something new',

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Organize your flashcards into a deck.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 32),

                // ======================================
                // DECK TITLE
                // ======================================
                TextFormField(
                  controller: _titleController,

                  enabled: !_isSaving,

                  textCapitalization: TextCapitalization.sentences,

                  textInputAction: TextInputAction.next,

                  maxLength: 80,

                  decoration: _inputDecoration(
                    label: 'Deck title *',
                    hint: 'e.g. Automata Theory',
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a deck title.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ======================================
                // OPTIONAL DESCRIPTION
                // ======================================
                TextFormField(
                  controller: _descriptionController,

                  enabled: !_isSaving,

                  textCapitalization: TextCapitalization.sentences,

                  minLines: 3,
                  maxLines: 5,
                  maxLength: 200,

                  decoration: _inputDecoration(
                    label: 'Description (optional)',
                    hint: 'What is this deck about?',
                  ),
                ),

                const SizedBox(height: 24),

                // ======================================
                // SAVE ERROR STATE
                // ======================================
                if (_saveFailed) ...[
                  const Text(
                    'Unable to confirm deck creation. '
                    'Your input has been preserved. '
                    'If the connection was interrupted, '
                    'check your library before trying again.',

                    key: ValueKey('deck_save_error'),

                    textAlign: TextAlign.center,

                    style: TextStyle(color: Colors.red),
                  ),

                  const SizedBox(height: 16),
                ],

                // ======================================
                // CREATE OR SAVE DECK
                // ======================================
                FilledButton(
                  key: const ValueKey('submit_deck_button'),

                  onPressed: _isSaving ? null : _submitDeck,

                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,

                    minimumSize: const Size.fromHeight(54),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(width: 12),

                            Text(
                              'Saving...',
                              key: ValueKey('deck_saving_state'),
                            ),
                          ],
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Deck',

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                Text(
                  _isEditing
                      ? 'Your existing flashcards will be preserved.'
                      : 'You can add flashcards after creating your deck.',

                  textAlign: TextAlign.center,

                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
