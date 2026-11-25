import 'package:material_ui/material_ui.dart';

import '../../domain/services/study_session_controller.dart';

class StudySessionScreen extends StatefulWidget {
  final String deckTitle;
  final StudySessionController session;

  const StudySessionScreen({
    super.key,
    required this.deckTitle,
    required this.session,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  static const primaryColor = Color(0xFF7C3AED);
  static const backgroundColor = Color(0xFFFAF8FF);
  static const lavenderColor = Color(0xFFEDE9FE);

  StudySessionController get session => widget.session;

  // SWITCH BETWEEN QUESTION AND ANSWER
  void _toggleAnswer() {
    if (session.isCompleted) {
      return;
    }

    setState(() {
      session.toggleAnswer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = session.currentCard;
    final isAnswerVisible = session.isAnswerVisible;

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text('Study Mode'),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Selected deck
            Text(
              widget.deckTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // Session progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.isCompleted
                      ? 'Session complete'
                      : 'Card ${session.currentCardNumber} '
                            'of ${session.totalCards}',
                ),

                Text(
                  '${session.completionPercentage.toStringAsFixed(0)}%'
                  ' completed',
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: session.progress,
              minHeight: 8,
              backgroundColor: lavenderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),

            const SizedBox(height: 32),

            // Current flashcard
            if (card != null) ...[
              Material(
                color: isAnswerVisible
                    ? const Color(0xFFDDD6FE)
                    : lavenderColor,

                borderRadius: BorderRadius.circular(24),

                child: InkWell(
                  key: const ValueKey('study_flashcard'),

                  borderRadius: BorderRadius.circular(24),

                  onTap: _toggleAnswer,

                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 280),

                    child: Padding(
                      padding: const EdgeInsets.all(24),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text(
                            isAnswerVisible ? 'ANSWER' : 'QUESTION',
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            isAnswerVisible ? card.back : card.front,

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4C1D95),
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Icon(Icons.refresh, color: primaryColor),

                          const SizedBox(height: 8),

                          Text(
                            isAnswerVisible
                                ? 'Tap to hide answer'
                                : 'Tap to reveal answer',

                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Alternative way to flip the card
              FilledButton(
                key: const ValueKey('toggle_answer_button'),

                onPressed: _toggleAnswer,

                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                child: Text(isAnswerVisible ? 'Hide Answer' : 'Show Answer'),
              ),
            ] else
              const Center(child: Text('Session completed!')),

            const SizedBox(height: 32),

            // Session statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatistic(
                    label: 'Reviewed',
                    value: '${session.reviewedCards}/${session.totalCards}',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildStatistic(
                    label: 'Remaining',
                    value: '${session.remainingCards}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFE8E2F3)),
      ),

      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
