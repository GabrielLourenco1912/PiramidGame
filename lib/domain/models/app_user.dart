class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.nome = '',
    this.foto,
    this.provider = 'password',
  });

  final String uid;
  final String email;
  final String nome;
  final String? foto;
  final String provider;

  AppUser withPhoto(String? photo) => AppUser(
    uid: uid,
    email: email,
    nome: nome,
    foto: photo,
    provider: provider,
  );
}

class AuthCredentials {
  const AuthCredentials({required this.email, required this.password});

  final String email;
  final String password;
}
