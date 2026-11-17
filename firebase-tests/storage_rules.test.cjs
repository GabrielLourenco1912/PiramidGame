const fs = require('node:fs');
const path = require('node:path');
const { before, beforeEach, after, test } = require('node:test');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { ref, uploadBytes, getBytes, deleteObject, listAll } = require('firebase/storage');

let environment;
const photoPath = (uid = 'alice') => `usuarios/${uid}/perfil/${'a'.repeat(32)}.png`;
const storage = (uid) => uid
  ? environment.authenticatedContext(uid).storage()
  : environment.unauthenticatedContext().storage();
const png = Uint8Array.from([137, 80, 78, 71, 13, 10, 26, 10]);
const upload = (uid = 'alice', filename = photoPath(), bytes = png, contentType = 'image/png') =>
  uploadBytes(ref(storage(uid), filename), bytes, { contentType });

before(async () => {
  const [host, port] = (process.env.FIREBASE_STORAGE_EMULATOR_HOST || '127.0.0.1:9199').split(':');
  environment = await initializeTestEnvironment({
    projectId: 'demo-piramidgame',
    storage: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, '..', 'storage.rules'), 'utf8') },
  });
});
beforeEach(async () => environment.clearStorage());
after(async () => environment?.cleanup());

test('apenas o proprietário envia e exclui a própria foto', async () => {
  await assertSucceeds(upload());
  await assertFails(upload('bob'));
  await assertFails(deleteObject(ref(storage('bob'), photoPath())));
  await assertSucceeds(deleteObject(ref(storage('alice'), photoPath())));
});

test('usuários autenticados veem a foto para os perfis e rankings', async () => {
  await assertSucceeds(upload());
  await assertSucceeds(getBytes(ref(storage('bob'), photoPath())));
  await assertFails(getBytes(ref(storage(), photoPath())));
  await assertFails(upload(null));
  await assertFails(listAll(ref(storage('alice'), 'usuarios/alice/perfil')));
});

test('rejeita arquivos vazios, grandes, MIME incorreto e caminhos fora do perfil', async () => {
  await assertFails(upload('alice', photoPath(), new Uint8Array()));
  await assertFails(upload('alice', photoPath(), new Uint8Array(5 * 1024 * 1024 + 1)));
  await assertFails(upload('alice', photoPath(), png, 'text/plain'));
  await assertFails(upload('alice', 'usuarios/alice/perfil/foto.png'));
  await assertFails(upload('alice', 'usuarios/alice/outro/arquivo.png'));
  await assertFails(upload('alice', 'arquivo.png'));
});

test('5 MB é o limite aceito e só o proprietário pode atualizar a imagem', async () => {
  await assertSucceeds(upload('alice', photoPath(), new Uint8Array(5 * 1024 * 1024)));
  await assertFails(upload('bob'));
  await assertSucceeds(upload());
});
