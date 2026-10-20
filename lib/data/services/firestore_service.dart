import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/evaluation.dart';
import '../../domain/models/popularity_score.dart';
import '../../domain/models/student.dart';

class FirestoreService {
  const FirestoreService(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _people =>
      _firestore.collection('pessoas');
  CollectionReference<Map<String, dynamic>> get _evaluations =>
      _firestore.collection('avaliacoes');
  CollectionReference<Map<String, dynamic>> get _userLinks =>
      _firestore.collection('vinculosUsuarios');

  static const _profileAlreadyLinked =
      'Sua conta já está vinculada a uma pessoa.';

  Future<void> saveUser(AppUser user) {
    return _firestore.collection('usuarios').doc(user.uid).set({
      'nome': user.nome,
      'email': user.email,
      'foto': user.foto,
      'provider': user.provider,
    }, SetOptions(merge: true));
  }

  Future<List<Student>> fetchStudents() async {
    final snapshot = await _people.where('ativo', isEqualTo: true).get();
    final people = snapshot.docs.map(_personFromDocument).toList();
    people.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return people;
  }

  Future<Student?> fetchStudentById(String id) async {
    final document = await _people.doc(id).get();
    if (!document.exists) return null;
    final person = _personFromDocument(document);
    return person.ativo ? person : null;
  }

  Future<Student> createStudent(Student person, String uid) async {
    final document = _people.doc();
    final created = person.copyWith(
      id: document.id,
      criadoPor: uid,
      ativo: true,
    );
    if (created.usuarioUid != null && created.usuarioUid != uid) {
      throw StateError('Você só pode vincular o cadastro à sua própria conta.');
    }
    final data = {
      ..._personData(created),
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
    if (created.usuarioUid == null) {
      await document.set(data);
    } else {
      // Inclui perfis inativos e anteriores ao índice de vínculos.
      final existing = await _people
          .where('usuarioUid', isEqualTo: uid)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      if (existing.docs.isNotEmpty) throw StateError(_profileAlreadyLinked);

      final link = _userLinks.doc(uid);
      await _firestore.runTransaction((transaction) async {
        final currentLink = await transaction.get(link);
        if (currentLink.exists) throw StateError(_profileAlreadyLinked);
        // O documento por UID serializa cadastros em aparelhos diferentes.
        transaction.set(link, {'pessoaId': document.id});
        transaction.set(document, data);
      });
    }
    return created;
  }

  Future<Student> updateStudent(Student person, String uid) async {
    return _firestore.runTransaction((transaction) async {
      final document = _people.doc(person.id);
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) throw StateError('Pessoa não encontrada.');
      final current = _personFromDocument(snapshot);
      _ensureOwner(current, uid);
      final updated = current.copyWith(
        nome: person.nome,
        apelido: person.apelido,
        curso: person.curso,
        turmaAno: person.turmaAno,
        dataNascimento: person.dataNascimento,
      );
      transaction.update(document, {
        ..._personData(updated),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      return updated;
    });
  }

  Future<void> removeStudent(String id, String uid) {
    return _firestore.runTransaction((transaction) async {
      final document = _people.doc(id);
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) throw StateError('Pessoa não encontrada.');
      _ensureOwner(_personFromDocument(snapshot), uid);
      // Remoção lógica evita exclusão de avaliações pertencentes a outras contas.
      transaction.update(document, {
        'ativo': false,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Evaluation> saveEvaluation(Evaluation evaluation) async {
    if (!evaluation.notas.isComplete) {
      throw StateError('Avalie os 15 critérios com notas de 1 a 5.');
    }
    final reference = _evaluations.doc(evaluation.id);
    await _firestore.runTransaction((transaction) async {
      final personDocument = await transaction.get(
        _people.doc(evaluation.pessoaId),
      );
      if (!personDocument.exists || personDocument.data()?['ativo'] != true) {
        throw StateError('Pessoa não encontrada.');
      }
      if (personDocument.data()?['usuarioUid'] == evaluation.avaliadorUid) {
        throw StateError('Você não pode avaliar a si próprio.');
      }
      final previous = await transaction.get(reference);
      transaction.set(reference, {
        'avaliadorUid': evaluation.avaliadorUid,
        'pessoaId': evaluation.pessoaId,
        'notas': evaluation.notas.toJson(),
        'pontuacaoTotal': evaluation.pontuacaoTotal,
        'dataAvaliacao':
            previous.data()?['dataAvaliacao'] ?? FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
    return _evaluationFromDocument(await reference.get());
  }

  Future<Evaluation?> fetchEvaluation(String uid, String pessoaId) async {
    final snapshot = await _evaluations.doc('${uid}_$pessoaId').get();
    return snapshot.exists ? _evaluationFromDocument(snapshot) : null;
  }

  Future<List<Evaluation>> fetchEvaluations({String? uid}) async {
    Query<Map<String, dynamic>> query = _evaluations;
    if (uid != null) query = query.where('avaliadorUid', isEqualTo: uid);
    final snapshot = await query.get();
    return snapshot.docs.map(_evaluationFromDocument).toList();
  }

  static Map<String, dynamic> _personData(Student person) => {
    'nome': person.nome.trim(),
    'apelido': person.apelido.trim(),
    'curso': person.curso,
    'turmaAno': person.turmaAno,
    'dataNascimento': Timestamp.fromDate(person.dataNascimento),
    'criadoPor': person.criadoPor,
    'usuarioUid': person.usuarioUid,
    'ativo': person.ativo,
  };

  static Student _personFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return Student(
      id: document.id,
      nome: data['nome'] as String,
      apelido: data['apelido'] as String,
      curso: data['curso'] as String,
      turmaAno: data['turmaAno'] as int,
      dataNascimento: (data['dataNascimento'] as Timestamp).toDate(),
      criadoPor: data['criadoPor'] as String,
      usuarioUid: data['usuarioUid'] as String?,
      ativo: data['ativo'] as bool,
    );
  }

  static Evaluation _evaluationFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    final score = PopularityScore.fromJson(
      Map<String, dynamic>.from(data['notas'] as Map),
    );
    if (!score.isComplete || score.total != data['pontuacaoTotal']) {
      throw const FormatException('Avaliação inválida no Firestore.');
    }
    return Evaluation(
      avaliadorUid: data['avaliadorUid'] as String,
      pessoaId: data['pessoaId'] as String,
      notas: score,
      dataAvaliacao: (data['dataAvaliacao'] as Timestamp).toDate(),
      atualizadoEm: (data['atualizadoEm'] as Timestamp).toDate(),
    );
  }

  static void _ensureOwner(Student person, String uid) {
    if (!person.ativo) throw StateError('Pessoa não encontrada.');
    if (person.criadoPor != uid) {
      throw StateError(
        'Somente quem cadastrou pode editar ou remover esta pessoa.',
      );
    }
  }
}
