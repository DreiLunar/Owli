    import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeckRepository {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> createDeck({
    required String subjectId,
    required String title,
    String description = '',
  }) async {
    await _db.collection('decks').add({
      'ownerId': _uid,
      'subjectId': subjectId,
      'title': title.trim(),
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyDecks() {
    return _db
        .collection('decks')
        .where('ownerId', isEqualTo: _uid)
        .snapshots();
  }

  Future<void> deleteDeck(String deckId) async {
    final deckRef = _db.collection('decks').doc(deckId);

    final cards = await deckRef.collection('cards').get();
    final progress = await _db
        .collection('progress')
        .where('userId', isEqualTo: _uid)
        .where('deckId', isEqualTo: deckId)
        .get();

    final refs = [
      ...cards.docs.map((d) => d.reference),
      ...progress.docs.map((d) => d.reference),
    ];

    for (var i = 0; i < refs.length; i += 400) {
      final batch = _db.batch();
      for (final ref in refs.skip(i).take(400)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    await deckRef.delete();
  }
}