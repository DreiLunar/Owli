import 'package:material_ui/material_ui.dart';

import '../../domain/models/flashcard.dart';

class FlashcardDraft {
  final String front;
  final String back;

  const FlashcardDraft({required this.front, required this.back});
}

class CreateFlashcardScreen extends StatefulWidget {
  final String deckTitle;
  final Flashcard? initialCard;
  final Future<void> Function(FlashcardDraft draft)? onSubmit;

  const CreateFlashcardScreen({
    super.key,
    required this.deckTitle,
    this.initialCard,
    this.onSubmit,
  });

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _frontController;
  late final TextEditingController _backController;

  bool _isSaving = false;
  bool _saveFailed = false;

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  bool get _isEditing => widget.initialCard != null;

  @override
  void initState() {
    super.initState();

    _frontController = TextEditingController(
      text: widget.initialCard?.front ?? '',
    );

    _backController = TextEditingController(
      text: widget.initialCard?.back ?? '',
    );
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  // ASYNCHRONOUS FLASHCARD SAVING
  Future<void> _submitFlashcard() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    final draft = FlashcardDraft(
      front: _frontController.text.trim(),
      back: _backController.text.trim(),
    );

    final callback = widget.onSubmit;

    // Preserve the existing draft-returning behavior.
    if (callback == null) {
      Navigator.of(context).pop(draft);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });

    try {
      await callback(draft);

      if (!mounted) return;

      Navigator.of(context).pop(draft);
    } catch (error) {
      debugPrint('Flashcard save failed: ${error.runtimeType}');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _saveFailed = true;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<FlashcardDraft>(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Flashcard' : 'Add Flashcard'),
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Selected deck information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lavenderColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'EDITING IN' : 'ADDING TO',
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.deckTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Question field
                TextFormField(
                  controller: _frontController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  decoration: _inputDecoration(
                    label: 'Front — Question *',
                    hint: 'Enter your question',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a question.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Answer field
                TextFormField(
                  controller: _backController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 8,
                  decoration: _inputDecoration(
                    label: 'Back — Answer *',
                    hint: 'Enter your answer',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an answer.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Save error state
                if (_saveFailed) ...[
                  const Text(
                    'Unable to confirm the save. '
                    'Your input has been preserved. '
                    'Check your deck before retrying if '
                    'the connection was interrupted.',
                    key: ValueKey('flashcard_save_error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                ],

                // Save or update flashcard
                FilledButton(
                  key: const ValueKey('submit_flashcard_button'),
                  onPressed: _isSaving ? null : _submitFlashcard,
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
                              key: ValueKey('flashcard_saving_state'),
                            ),
                          ],
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Save Flashcard',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The front contains the question. '
                  'The back contains the answer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
