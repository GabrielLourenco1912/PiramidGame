/// Pessoa avaliada. Seu cadastro não cria uma conta de autenticação.
class Student {
  const Student({
    required this.id,
    required this.nome,
    required this.curso,
    required this.turmaAno,
    required this.apelido,
    required this.dataNascimento,
    this.criadoPor = '',
    this.usuarioUid,
    this.ativo = true,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      nome: json['nome'] as String,
      curso: json['curso'] as String,
      turmaAno: (json['turmaAno'] as num).toInt(),
      apelido: json['apelido'] as String,
      dataNascimento: DateTime.parse(json['dataNascimento'] as String),
      criadoPor: json['criadoPor'] as String? ?? '',
      usuarioUid: json['usuarioUid'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  final String id;
  final String nome;
  final String curso;
  final int turmaAno;
  final String apelido;
  final DateTime dataNascimento;
  final String criadoPor;

  /// Vínculo opcional e único com a conta desta pessoa, inclusive se inativa.
  /// Também é usado para impedir a autoavaliação.
  final String? usuarioUid;
  final bool ativo;

  Student copyWith({
    String? id,
    String? nome,
    String? curso,
    int? turmaAno,
    String? apelido,
    DateTime? dataNascimento,
    String? criadoPor,
    bool? ativo,
  }) {
    return Student(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      curso: curso ?? this.curso,
      turmaAno: turmaAno ?? this.turmaAno,
      apelido: apelido ?? this.apelido,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      criadoPor: criadoPor ?? this.criadoPor,
      usuarioUid: usuarioUid,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'curso': curso,
      'turmaAno': turmaAno,
      'apelido': apelido,
      'dataNascimento': dataNascimento.toIso8601String(),
      'criadoPor': criadoPor,
      'usuarioUid': usuarioUid,
      'ativo': ativo,
    };
  }
}
