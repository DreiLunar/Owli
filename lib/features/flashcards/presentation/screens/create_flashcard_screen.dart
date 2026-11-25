import 'package:material_ui/material_ui.dart';

class FlashcardDraft {
  final String front;
  final String back;

  const FlashcardDraft({required this.front, required this.back});
}

class CreateFlashcardScreen extends StatefulWidget {
  final String deckTitle;

  const CreateFlashcardScreen({super.key, required this.deckTitle});

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();

  final _frontController = TextEditingController();
  final _backController = TextEditingController();

  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _submitFlashcard() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = FlashcardDraft(
      front: _frontController.text.trim(),
      back: _backController.text.trim(),
    );

    Navigator.of(context).pop(draft);
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
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text('Add Flashcard'),
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
                    const Text(
                      'ADDING TO',
                      style: TextStyle(
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

              FilledButton(
                onPressed: _submitFlashcard,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Flashcard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    );
  }
}
