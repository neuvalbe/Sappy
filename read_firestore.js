const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sappy-caa9e' });
const db = admin.firestore();
async function run() {
  const doc = await db.collection('metrics').doc('global_counts').get();
  console.log(JSON.stringify(doc.data(), null, 2));
}
run();
