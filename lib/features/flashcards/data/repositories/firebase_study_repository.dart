import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../decks/data/deck_repository.dart';
import '../../domain/repositories/study_repository.dart';

class FirebaseStudyRepository extends DeckRepository
    implements StudyRepository {
  @override
  final String userId;

  FirebaseStudyRepository._({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required this.userId,
  }) : super(auth: auth, firestore: firestore, scopedUserId: userId);

  factory FirebaseStudyRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) {
    final resolvedAuth = auth ?? FirebaseAuth.instance;

    final resolvedFirestore = firestore ?? FirebaseFirestore.instance;

    final user = resolvedAuth.currentUser;

    if (user == null) {
      throw StateError('Authentication required.');
    }

    return FirebaseStudyRepository._(
      auth: resolvedAuth,
      firestore: resolvedFirestore,
      userId: user.uid,
    );
  }
}
