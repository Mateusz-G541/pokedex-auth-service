// Generates RSA keypair for JWT if missing, no OpenSSL required
const fs = require('fs');
const path = require('path');
const { generateKeyPairSync } = require('crypto');

const keysDir = path.resolve(__dirname, '..', 'keys');
const privPath = path.join(keysDir, 'private.pem');
const pubPath = path.join(keysDir, 'public.pem');

try {
  if (!fs.existsSync(keysDir)) fs.mkdirSync(keysDir, { recursive: true });

  const needPriv = !fs.existsSync(privPath);
  const needPub = !fs.existsSync(pubPath);

  if (needPriv || needPub) {
    const { publicKey, privateKey } = generateKeyPairSync('rsa', {
      modulusLength: 2048,
      publicKeyEncoding: { type: 'spki', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    });

    fs.writeFileSync(privPath, privateKey, { encoding: 'utf8', mode: 0o600 });
    fs.writeFileSync(pubPath, publicKey, { encoding: 'utf8', mode: 0o644 });

    console.log('[gen-keys] RSA keys generated at', keysDir);
  } else {
    console.log('[gen-keys] Keys already exist, skipping');
  }
} catch (err) {
  console.error('[gen-keys] Failed to generate keys:', err);
  process.exit(1);
}
