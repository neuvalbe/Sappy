const admin = require('firebase-admin');

// Assume the default credential works if we use project sappy-caa9e
admin.initializeApp({
  projectId: 'sappy-caa9e'
});

const db = admin.firestore();

async function run() {
  const docRef = db.collection('metrics').doc('global_counts');
  
  // Reset global counts
  await docRef.set({
    total_happy: 0,
    total_sad: 0,
    countries: {}
  });

  // Delete all user vote documents (chunked to respect 500-op batch limit)
  const usersSnap = await db.collection('users').get();
  const docs = usersSnap.docs;

  for (let i = 0; i < docs.length; i += 500) {
    const chunk = docs.slice(i, i + 500);
    const batch = db.batch();
    chunk.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  }

  console.log(`Database reset. Deleted ${docs.length} user doc(s).`);
}

run().catch(console.error);
