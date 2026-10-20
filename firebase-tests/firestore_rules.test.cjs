const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { before, beforeEach, after, test } = require('node:test');
const {
  initializeTestEnvironment, assertSucceeds, assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, getDoc, updateDoc, deleteDoc, getDocs, collection,
  serverTimestamp, Timestamp, writeBatch, runTransaction,
} = require('firebase/firestore');

const criteria = [
  'resenha', 'presenca_vip', 'aura', 'modo_parceiro', 'carisma_natural',
  'humor_de_milhoes', 'energia_de_grupo', 'criatividade_caotica',
  'modo_atleta', 'talento_de_palco', 'drip_escolar', 'coracao_de_dorama',
  'queridinho_dos_professores', 'cerebro_turbo', 'caos_controlado',
];
let environment;
const db = (uid) => uid
  ? environment.authenticatedContext(uid, { email: uid + '@example.com' }).firestore()
  : environment.unauthenticatedContext().firestore();
const person = (uid = 'alice', usuarioUid = null) => ({
  nome: 'Ana', apelido: 'ana', curso: 'INFO', turmaAno: 2026,
  dataNascimento: Timestamp.fromDate(new Date('2005-04-02T00:00:00Z')),
  criadoPor: uid, usuarioUid, ativo: true,
  criadoEm: serverTimestamp(), atualizadoEm: serverTimestamp(),
});
const rating = (uid = 'alice', pessoaId = 'ana', stars = 4) => ({
  avaliadorUid: uid, pessoaId,
  notas: Object.fromEntries(criteria.map((criterion) => [criterion, stars])),
  pontuacaoTotal: stars * 15,
  dataAvaliacao: serverTimestamp(), atualizadoEm: serverTimestamp(),
});
const seedPerson = async (usuarioUid = null) => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'pessoas/ana'), person('owner', usuarioUid));
  });
};
const createLinkedPerson = (firestore, personId, uid) => {
  const batch = writeBatch(firestore);
  batch.set(doc(firestore, 'pessoas', personId), person(uid, uid));
  batch.set(doc(firestore, 'vinculosUsuarios', uid), { pessoaId: personId });
  return batch.commit();
};

before(async () => {
  const address = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  const [host, port] = address.split(':');
  environment = await initializeTestEnvironment({
    projectId: 'demo-piramidgame',
    firestore: {
      host, port: Number(port),
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});
beforeEach(async () => environment.clearFirestore());
after(async () => environment?.cleanup());

test('acesso sem autenticação é negado em todas as coleções', async () => {
  const anonymous = db();
  for (const name of ['usuarios', 'pessoas', 'vinculosUsuarios', 'avaliacoes']) {
    await assertFails(getDocs(collection(anonymous, name)));
  }
  await assertFails(setDoc(doc(anonymous, 'pessoas/ana'), person()));
});

test('perfil do usuário é privado e só pode ser gravado pelo próprio UID', async () => {
  const user = { nome: 'Alice', email: 'alice@example.com', foto: null, provider: 'password' };
  await assertSucceeds(setDoc(doc(db('alice'), 'usuarios/alice'), user));
  await assertSucceeds(getDoc(doc(db('alice'), 'usuarios/alice')));
  await assertFails(getDoc(doc(db('bob'), 'usuarios/alice')));
  await assertFails(setDoc(doc(db('bob'), 'usuarios/alice'), { ...user, email: 'bob@example.com' }));
  await assertFails(updateDoc(doc(db('alice'), 'usuarios/alice'), { senha: 'proibida' }));
});

test('cadastro de pessoa valida criador, curso, ano, nascimento e vínculo', async () => {
  const alice = db('alice');
  await assertSucceeds(setDoc(doc(alice, 'pessoas/ana'), person()));
  await assertSucceeds(createLinkedPerson(alice, 'self', 'alice'));
  await assertFails(setDoc(doc(alice, 'pessoas/forged-owner'), person('bob')));
  await assertFails(setDoc(doc(alice, 'pessoas/forged-link'), person('alice', 'bob')));
  await assertFails(setDoc(doc(alice, 'pessoas/bad-course'), { ...person(), curso: 'Outro' }));
  await assertFails(setDoc(doc(alice, 'pessoas/bad-year'), { ...person(), turmaAno: 2027 }));
  await assertFails(setDoc(doc(alice, 'pessoas/bad-date'), {
    ...person(), dataNascimento: Timestamp.fromDate(new Date('2100-01-01')),
  }));
});

test('perfil vinculado exige índice recíproco gravado atomicamente', async () => {
  const alice = db('alice');
  await assertFails(setDoc(doc(alice, 'pessoas/self'), person('alice', 'alice')));
  await assertFails(setDoc(doc(alice, 'vinculosUsuarios/alice'), { pessoaId: 'self' }));
  await assertSucceeds(createLinkedPerson(alice, 'self', 'alice'));
  assert.equal((await getDoc(doc(alice, 'vinculosUsuarios/alice'))).data().pessoaId, 'self');
});

test('uma conta não pode vincular duas pessoas, mesmo contornando o app', async () => {
  const alice = db('alice');
  await assertSucceeds(createLinkedPerson(alice, 'self', 'alice'));
  await assertFails(createLinkedPerson(alice, 'duplicate', 'alice'));
  await assertFails(setDoc(doc(alice, 'pessoas/duplicate'), person('alice', 'alice')));
  assert.equal((await getDoc(doc(alice, 'pessoas/duplicate'))).exists(), false);
  assert.equal((await getDocs(collection(alice, 'pessoas'))).size, 1);
});

test('lote com duas pessoas para o mesmo UID é inteiramente rejeitado', async () => {
  const alice = db('alice');
  const batch = writeBatch(alice);
  batch.set(doc(alice, 'pessoas/first'), person('alice', 'alice'));
  batch.set(doc(alice, 'pessoas/second'), person('alice', 'alice'));
  batch.set(doc(alice, 'vinculosUsuarios/alice'), { pessoaId: 'first' });
  await assertFails(batch.commit());
  assert.equal((await getDocs(collection(alice, 'pessoas'))).size, 0);
  assert.equal((await getDoc(doc(alice, 'vinculosUsuarios/alice'))).exists(), false);
});

test('cadastros simultâneos na mesma conta só confirmam uma pessoa', async () => {
  const alice = db('alice');
  const link = doc(alice, 'vinculosUsuarios/alice');
  const create = (id) => runTransaction(alice, async (transaction) => {
    const current = await transaction.get(link);
    if (current.exists()) throw new Error('Conta já vinculada.');
    transaction.set(doc(alice, 'pessoas', id), person('alice', 'alice'));
    transaction.set(link, { pessoaId: id });
  });
  const results = await Promise.allSettled([create('first'), create('second')]);
  assert.equal(results.filter((result) => result.status === 'fulfilled').length, 1);
  assert.equal(results.filter((result) => result.status === 'rejected').length, 1);
  const people = await getDocs(collection(alice, 'pessoas'));
  assert.equal(people.size, 1);
  assert.equal((await getDoc(link)).data().pessoaId, people.docs[0].id);
});

test('criador pode cadastrar terceiros e contas distintas têm vínculos próprios', async () => {
  const alice = db('alice');
  await assertSucceeds(createLinkedPerson(alice, 'alice-profile', 'alice'));
  await assertSucceeds(setDoc(doc(alice, 'pessoas/ana'), person()));
  await assertSucceeds(setDoc(doc(alice, 'pessoas/bruno'), person()));
  await assertSucceeds(createLinkedPerson(db('bob'), 'bob-profile', 'bob'));
  assert.equal((await getDocs(collection(alice, 'pessoas'))).size, 4);
});

test('índice é privado, imutável e só aceita a pessoa que representa a conta', async () => {
  const alice = db('alice');
  await assertSucceeds(createLinkedPerson(alice, 'self', 'alice'));
  await assertFails(getDoc(doc(db(), 'vinculosUsuarios/alice')));
  await assertFails(getDoc(doc(db('bob'), 'vinculosUsuarios/alice')));
  await assertFails(getDocs(collection(alice, 'vinculosUsuarios')));
  await assertFails(setDoc(doc(db('bob'), 'vinculosUsuarios/alice'), { pessoaId: 'self' }));
  await assertFails(setDoc(doc(db('bob'), 'vinculosUsuarios/bob'), { pessoaId: 'self' }));
  await assertFails(updateDoc(doc(alice, 'vinculosUsuarios/alice'), { pessoaId: 'other' }));
  await assertFails(deleteDoc(doc(alice, 'vinculosUsuarios/alice')));
  await assertSucceeds(updateDoc(doc(alice, 'pessoas/self'), {
    nome: 'Alice Lima', atualizadoEm: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(alice, 'pessoas/self'), {
    usuarioUid: null, atualizadoEm: serverTimestamp(),
  }));
});

test('remoção lógica não libera o vínculo para criar outra pessoa', async () => {
  const alice = db('alice');
  await assertSucceeds(createLinkedPerson(alice, 'self', 'alice'));
  await assertSucceeds(updateDoc(doc(alice, 'pessoas/self'), {
    ativo: false, atualizadoEm: serverTimestamp(),
  }));
  await assertFails(createLinkedPerson(alice, 'duplicate', 'alice'));
  assert.equal((await getDoc(doc(alice, 'vinculosUsuarios/alice'))).data().pessoaId, 'self');
});

test('vínculo legado recebe índice sem alterar pessoa ou avaliações existentes', async () => {
  await seedPerson('alice');
  const alice = db('alice');
  await assertSucceeds(setDoc(doc(alice, 'vinculosUsuarios/alice'), { pessoaId: 'ana' }));
  await assertFails(createLinkedPerson(alice, 'duplicate', 'alice'));
  assert.equal((await getDocs(collection(alice, 'pessoas'))).size, 1);
});

test('somente criador edita/remove logicamente e o vínculo é imutável', async () => {
  await assertSucceeds(setDoc(doc(db('alice'), 'pessoas/ana'), person()));
  await assertSucceeds(updateDoc(doc(db('alice'), 'pessoas/ana'), {
    nome: 'Ana Lima', atualizadoEm: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(db('bob'), 'pessoas/ana'), {
    nome: 'Outro', atualizadoEm: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(db('alice'), 'pessoas/ana'), {
    usuarioUid: 'bob', atualizadoEm: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(db('alice'), 'pessoas/ana'), {
    criadoPor: 'bob', atualizadoEm: serverTimestamp(),
  }));
  await assertFails(deleteDoc(doc(db('alice'), 'pessoas/ana')));
  await assertSucceeds(updateDoc(doc(db('alice'), 'pessoas/ana'), {
    ativo: false, atualizadoEm: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(db('alice'), 'pessoas/ana'), {
    ativo: true, atualizadoEm: serverTimestamp(),
  }));
});

test('uma avaliação válida é compartilhada para cálculo do ranking global', async () => {
  await seedPerson();
  await assertSucceeds(setDoc(doc(db('alice'), 'avaliacoes/alice_ana'), rating()));
  await assertSucceeds(getDoc(doc(db('bob'), 'avaliacoes/alice_ana')));
  await assertSucceeds(getDocs(collection(db('bob'), 'avaliacoes')));
});

test('o ID determinístico impede votos duplicados e identidade forjada', async () => {
  await seedPerson();
  await assertSucceeds(setDoc(doc(db('alice'), 'avaliacoes/alice_ana'), rating()));
  await assertFails(setDoc(doc(db('alice'), 'avaliacoes/outro-id'), rating()));
  await assertFails(setDoc(doc(db('bob'), 'avaliacoes/alice_ana'), rating()));
});

test('edição mantém pessoa, usuário e data original; outra conta não altera voto', async () => {
  await seedPerson();
  const reference = doc(db('alice'), 'avaliacoes/alice_ana');
  await assertSucceeds(setDoc(reference, rating()));
  await assertSucceeds(updateDoc(reference, {
    notas: rating('alice', 'ana', 5).notas,
    pontuacaoTotal: 75, atualizadoEm: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(db('bob'), 'avaliacoes/alice_ana'), {
    pontuacaoTotal: 15, atualizadoEm: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    dataAvaliacao: Timestamp.fromDate(new Date('2020-01-01')),
    atualizadoEm: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    pessoaId: 'outra', atualizadoEm: serverTimestamp(),
  }));
});

test('bloqueia autoavaliação também para vínculo definido pelo administrador', async () => {
  await seedPerson('alice');
  await assertFails(setDoc(doc(db('alice'), 'avaliacoes/alice_ana'), rating()));
  await assertSucceeds(setDoc(doc(db('bob'), 'avaliacoes/bob_ana'), rating('bob')));
});

test('valida todos os 15 critérios e rejeita nota zero, seis e fracionária', async () => {
  await seedPerson();
  const reference = doc(db('alice'), 'avaliacoes/alice_ana');
  for (const criterion of criteria) {
    for (const value of [0, 6, 3.5]) {
      const data = rating();
      data.notas[criterion] = value;
      data.pontuacaoTotal = 56 + value;
      await assertFails(setDoc(reference, data));
    }
  }
});

test('rejeita critérios ausentes/extras e total adulterado', async () => {
  await seedPerson();
  const reference = doc(db('alice'), 'avaliacoes/alice_ana');
  const missing = rating();
  delete missing.notas.aura;
  await assertFails(setDoc(reference, missing));
  const extra = rating();
  extra.notas.extra = 1;
  await assertFails(setDoc(reference, extra));
  await assertFails(setDoc(reference, { ...rating(), pontuacaoTotal: 75 }));
  await assertFails(setDoc(reference, { ...rating(), campoExtra: true }));
});

test('limites de 15 e 75 pontos são aceitos', async () => {
  await seedPerson();
  await assertSucceeds(setDoc(doc(db('alice'), 'avaliacoes/alice_ana'), rating('alice', 'ana', 1)));
  await assertSucceeds(setDoc(doc(db('bob'), 'avaliacoes/bob_ana'), rating('bob', 'ana', 5)));
});

test('pessoa inexistente ou removida não recebe avaliação', async () => {
  await assertFails(setDoc(doc(db('alice'), 'avaliacoes/alice_ana'), rating()));
  await seedPerson();
  await environment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'pessoas/ana'), { ativo: false });
  });
  await assertFails(setDoc(doc(db('alice'), 'avaliacoes/alice_ana'), rating()));
});
