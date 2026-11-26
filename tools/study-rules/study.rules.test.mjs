import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  writeBatch,
  serverTimestamp,
  query,
  where,
} from 'firebase/firestore';

test('Owli Study Module security and integrity', async () => {
  const env = await initializeTestEnvironment({
    projectId: 'demo-owli-rules',

    firestore: {
      host: '127.0.0.1',
      port: 8180,

      rules: readFileSync(
        new URL('../../firestore.rules', import.meta.url),
        'utf8',
      ),
    },
  });

  try {
    await env.clearFirestore();

    const dbA = env
      .authenticatedContext('user_a')
      .firestore();

    const dbB = env
      .authenticatedContext('user_b')
      .firestore();

    const anonymous = env
      .unauthenticatedContext()
      .firestore();

    const deckId = 'deck_test';

    const deck = doc(dbA, 'decks', deckId);

    const card = (db, id) =>
      doc(db, 'decks', deckId, 'cards', id);

    const progress = (db, id) =>
      doc(
        db,
        'progress',
        `user_a~${deckId}~${id}`,
      );

    const cardData = (id) => ({
      deckId,
      front: `Question ${id}`,
      back: `Answer ${id}`,
      sourceNoteId: null,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    const progressData = (id) => ({
      userId: 'user_a',
      deckId,
      cardId: id,
      lastResult: 'gotIt',
      lastReviewedAt: serverTimestamp(),
      nextReviewAt: null,
    });

    // TEST 1: Valid owner can create a deck.

    await assertSucceeds(
      setDoc(deck, {
        ownerId: 'user_a',
        subjectId: 'test-subject',
        title: 'Security Test',
        description: '',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    // TEST 2: Unauthenticated and other users denied.

    await assertFails(
      getDoc(doc(anonymous, 'decks', deckId)),
    );

    await assertFails(
      getDoc(doc(dbB, 'decks', deckId)),
    );

    await assertFails(
      updateDoc(deck, {
        ownerId: 'user_b',
        updatedAt: serverTimestamp(),
      }),
    );

    // TEST 3: Valid flashcards can be created.

    for (let i = 1; i <= 12; i++) {
      const id = `card_${i}`;

      await assertSucceeds(
        setDoc(card(dbA, id), cardData(id)),
      );
    }

    await assertFails(
      getDoc(card(dbB, 'card_1')),
    );

    await assertFails(
      deleteDoc(card(dbB, 'card_1')),
    );

    // TEST 4: Ten-card atomic result saving.

    const session = writeBatch(dbA);

    for (let i = 1; i <= 10; i++) {
      const id = `card_${i}`;

      session.set(
        progress(dbA, id),
        progressData(id),
      );
    }

    await assertSucceeds(session.commit());

    const ownedProgress = query(
      collection(dbA, 'progress'),
      where('userId', '==', 'user_a'),
      where('deckId', '==', deckId),
    );

    let snapshot = await assertSucceeds(
      getDocs(ownedProgress),
    );

    assert.equal(snapshot.size, 10);

    // TEST 5: Progress isolation and invalid writes.

    await assertFails(
      getDoc(progress(dbB, 'card_1')),
    );

    await assertFails(
      updateDoc(progress(dbB, 'card_1'), {
        lastResult: 'stillLearning',
        lastReviewedAt: serverTimestamp(),
      }),
    );

    await assertFails(
      updateDoc(progress(dbA, 'card_1'), {
        lastResult: 'invalid',
        lastReviewedAt: serverTimestamp(),
      }),
    );

    await assertFails(
      setDoc(
        doc(dbA, 'progress', 'wrong-id'),
        progressData('card_1'),
      ),
    );

    await assertFails(
      setDoc(
        progress(dbA, 'missing_card'),
        progressData('missing_card'),
      ),
    );

    // TEST 6: Content changes must invalidate progress.

    await assertFails(
      updateDoc(card(dbA, 'card_1'), {
        front: 'Changed question',
        updatedAt: serverTimestamp(),
      }),
    );

    const edit = writeBatch(dbA);

    edit.delete(progress(dbA, 'card_1'));

    edit.update(card(dbA, 'card_1'), {
      front: 'Changed question',
      updatedAt: serverTimestamp(),
    });

    await assertSucceeds(edit.commit());

    // TEST 7: Updating an unreviewed card works.

    const unreviewedEdit = writeBatch(dbA);

    unreviewedEdit.delete(
      progress(dbA, 'card_12'),
    );

    unreviewedEdit.update(card(dbA, 'card_12'), {
      back: 'Changed answer',
      updatedAt: serverTimestamp(),
    });

    await assertSucceeds(
      unreviewedEdit.commit(),
    );

    // TEST 8: Deletion requires progress cleanup.

    await assertFails(
      deleteDoc(card(dbA, 'card_2')),
    );

    const removal = writeBatch(dbA);

    removal.delete(progress(dbA, 'card_2'));
    removal.delete(card(dbA, 'card_2'));

    await assertSucceeds(removal.commit());

    // TEST 9: Lock deck before cleanup.

    await assertFails(deleteDoc(deck));

    await assertSucceeds(
      updateDoc(deck, {
        deleting: true,
        updatedAt: serverTimestamp(),
      }),
    );

    await assertFails(
      setDoc(
        card(dbA, 'new_card'),
        cardData('new_card'),
      ),
    );

    await assertFails(
      setDoc(
        progress(dbA, 'card_3'),
        progressData('card_3'),
      ),
    );

    // TEST 10: Owner can resume cleanup.

    snapshot = await assertSucceeds(
      getDocs(ownedProgress),
    );

    for (const record of snapshot.docs) {
      await assertSucceeds(deleteDoc(record.ref));
    }

    const cards = await assertSucceeds(
      getDocs(
        collection(dbA, 'decks', deckId, 'cards'),
      ),
    );

    for (const record of cards.docs) {
      await assertSucceeds(deleteDoc(record.ref));
    }

    await assertSucceeds(deleteDoc(deck));

    const remaining = await assertSucceeds(
      getDocs(ownedProgress),
    );

    assert.equal(remaining.size, 0);

    console.log(
      'ALL OWLI SECURITY CHECKS PASSED',
    );
  } finally {
    await env.cleanup();
  }
});