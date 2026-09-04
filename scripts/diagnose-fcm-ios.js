# Diagnóstico FCM → APNs (iOS)
#
# 1) No Firebase Console → Project settings → Service accounts → Generate new private key
#    Salve o JSON em: ./secrets/giro-certo-firebase-adminsdk.json  (não commitar)
# 2) npm i firebase-admin  (na pasta da API ou aqui)
# 3) node scripts/diagnose-fcm-ios.js <FCM_TOKEN>
#
# Imprime o erro real da Apple/FCM (InvalidProviderToken, BadEnvironmentKeyInToken, etc.)

const path = require('path');
const fs = require('fs');

async function main() {
  const token = process.argv[2];
  if (!token) {
    console.error('Uso: node scripts/diagnose-fcm-ios.js <FCM_TOKEN>');
    process.exit(1);
  }

  const credPath = path.resolve(
    __dirname,
    '../secrets/giro-certo-firebase-adminsdk.json'
  );
  if (!fs.existsSync(credPath)) {
    console.error(
      'Coloque o service account em secrets/giro-certo-firebase-adminsdk.json'
    );
    process.exit(1);
  }

  const admin = require('firebase-admin');
  const serviceAccount = require(credPath);
  if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  }

  console.log('Project:', serviceAccount.project_id);
  console.log('Enviando para token:'FAKESECRET_g2h3i4j5k6l7m8n9o0p1'...');

  try {
    const id = await admin.messaging().send({
      token,
      notification: {
        title: 'Diagnóstico Giro Certo',
        body: 'Se você leu isto, APNs/FCM estão ok.',
      },
      apns: {
        headers: { 'apns-priority': '10', 'apns-push-type': 'alert' },
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
    console.log('✅ Enviado com sucesso. messageId =', id);
  } catch (e) {
    console.error('❌ Falha FCM/APNs:');
    console.error('  code   :', e.code);
    console.error('  message:', e.message);
    if (e.errorInfo) console.error('  info   :', e.errorInfo);
  }
}

main();
