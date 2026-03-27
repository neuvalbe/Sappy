// Seed and wipe Firestore to a clean state.
// Uses Application Default Credentials from `firebase login`.
const { initializeApp, cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Try ADC first (works if `gcloud auth` or GOOGLE_APPLICATION_CREDENTIALS is set),
// fall back to project-only init (works for Firestore emulator or permissive rules).
try {
  initializeApp({ credential: applicationDefault(), projectId: 'sappy-caa9e' });
} catch {
  initializeApp({ projectId: 'sappy-caa9e' });
}

const db = getFirestore();

async function run() {
  const docRef = db.collection('metrics').doc('global_counts');

  // Wipe and seed with clean structure
  await docRef.set({
    total_happy: 0,
    total_sad: 0,
    countries: {}
  });

  console.log('✅ Firestore seeded: metrics/global_counts');

  // Verify
  const doc = await docRef.get();
  console.log(JSON.stringify(doc.data(), null, 2));
}

run().then(() => process.exit(0)).catch(e => {
  console.error('❌ Failed:', e.message);
  process.exit(1);
});
