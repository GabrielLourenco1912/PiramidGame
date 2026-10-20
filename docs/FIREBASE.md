# PiramidGame — configuração do Firebase

Guia simples para conectar esta adaptação ao seu projeto. Faça os passos na ordem. O aplicativo usa Firebase Authentication e Cloud Firestore. As contas, pessoas e avaliações são criadas pelo próprio app.

## 1. Criar o projeto e habilitar os serviços

Acesse https://console.firebase.google.com e crie um projeto, ou escolha um projeto existente. Anote o ID do projeto (não apenas o nome).

Em Authentication > Sign-in method, habilite E-mail/senha e Google. No provedor Google, escolha o e-mail de suporte e salve.

Em Firestore Database, clique em Criar banco de dados. Use o banco padrão, identificado como (default), na edição Standard. Escolha a região e inicie em modo de produção. Você publicará as regras do projeto no passo 4.

Não é necessário criar coleções manualmente, habilitar Storage ou configurar Cloud Functions. Os rankings são calculados pelo aplicativo a partir das avaliações do Firestore.

## 2. Conectar o projeto Flutter

No terminal, dentro da raiz deste projeto, execute:

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutter pub get
flutterfire configure --project=SEU_PROJECT_ID --platforms=android,web
```

Substitua SEU_PROJECT_ID pelo ID anotado. Se flutterfire não for encontrado no Linux/macOS, adicione o diretório $HOME/.pub-cache/bin ao PATH do seu terminal.

No Android, use o pacote com.example.atividade_mobile. O comando registra os aplicativos selecionados, gera lib/firebase_options.dart e configura os arquivos de plataforma. Aceite substituir o arquivo firebase_options.dart de orientação que acompanha o projeto.

Verifique se android/app/google-services.json existe e pertence ao mesmo projeto. O Gradle já aplica o plugin Google Services quando esse arquivo está presente. Não preencha chaves fictícias: use os arquivos gerados para o seu projeto.

<!-- pagebreak -->

## 3. Ajustar o login Google

Android: obtenha os certificados da instalação de desenvolvimento:

```bash
cd android
./gradlew signingReport
cd ..
```

No console Firebase, abra Configurações do projeto > Geral > Seus apps > app Android. Cadastre as impressões SHA-1 e SHA-256 exibidas para a variante debug.

Depois de habilitar Google e cadastrar os certificados, baixe novamente google-services.json e coloque em android/app/google-services.json. O arquivo deve conter um cliente OAuth do tipo Web (client_type: 3), utilizado pelo login Google no Android.

Se a instalação usar outra chave de assinatura, cadastre também os certificados dessa chave. Caso apareça “serverClientId must be provided”, confira o cliente Web no JSON. O app também aceita o ID desse cliente com --dart-define=GOOGLE_SERVER_CLIENT_ID=SEU_CLIENT_ID_WEB.

Web: em Authentication > Settings > Authorized domains, inclua localhost para desenvolvimento e o domínio usado quando publicar. O login Google da versão web usa o popup do Firebase. Permita o popup no navegador.

## 4. Publicar as regras do Firestore

Se o banco já contém pessoas com usuarioUid preenchido, zere os cadastros antigos ou regularize os vínculos antes deste passo, conforme docs/VINCULO_USUARIO_PESSOA.md. As novas regras exigem um índice exclusivo por UID; publicar sem preparar os dados antigos impede a edição desses perfis e deixa seus vínculos sem a reserva de unicidade.

Na raiz do projeto, execute:

```bash
firebase deploy --only firestore --project SEU_PROJECT_ID
```

Esse comando publica firestore.rules e firestore.indexes.json usando firebase.json. Como alternativa, copie todo o conteúdo de firestore.rules para Firestore Database > Rules e clique em Publish.

As regras exigem login, impedem vínculos duplicados por conta, votos duplicados e autoavaliação de perfis vinculados e validam os 15 critérios, as notas inteiras de 1 a 5 e a soma. Só o criador pode editar ou remover uma pessoa. Cada usuário altera apenas suas próprias avaliações.

A remoção usa ativo=false: o perfil sai das listas e rankings e seu histórico permanece no Firestore. As consultas atuais usam índices simples, criados automaticamente; não há índice composto adicional para cadastrar.

## 5. Vincular uma pessoa à conta certa

Ao cadastrar seu próprio perfil no app, marque “Este é meu perfil”. Isso grava seu UID no campo usuarioUid e cria vinculosUsuarios/{uid}, contendo pessoaId com o ID da pessoa, na mesma transação. Cada conta pode ter no máximo uma pessoa vinculada. A remoção lógica mantém esse vínculo reservado.

Para um perfil já existente, o responsável pelo Firebase deve copiar o UID em Authentication > Users e conferir se já há alguma pessoa com esse usuarioUid, inclusive inativa. Confirme a identidade, grave o UID como string no documento correto em pessoas e crie vinculosUsuarios/{uid} com o campo pessoaId apontando para esse documento. Não substitua um índice que já aponta para outra pessoa. Consulte docs/VINCULO_USUARIO_PESSOA.md para o procedimento com dados antigos. Quem não possui conta mantém usuarioUid como null.

O vínculo fica imutável pelo aplicativo. Vincule os perfis dos usuários antes que avaliem: sem a associação, o sistema não tem como reconhecer que uma conta representa aquela pessoa.

<!-- pagebreak -->

## 6. Executar e conferir

Na raiz do projeto:

```bash
flutter run
# Para testar no navegador:
flutter run -d chrome
```

Crie uma conta, cadastre duas pessoas e avalie uma delas. Confira as coleções:

- usuarios/{uid}: nome, e-mail, foto e provedor; leitura restrita à própria conta.
- pessoas/{id}: perfil, criadoPor, usuarioUid, ativo e datas de controle.
- vinculosUsuarios/{uid}: pessoaId; índice exclusivo e imutável, acessível apenas pela própria conta.
- avaliacoes/{uid}_{pessoaId}: avaliador, pessoa, mapa notas, total e datas; usuários autenticados leem as avaliações para calcular o ranking global.

Teste também: fechar e reabrir o app; sair da conta; entrar com Google; editar a avaliação; alternar o tema. O tema é a única informação salva em SharedPreferences.

Com duas contas avaliando a mesma pessoa, o ranking pessoal deve mostrar só a opinião da conta atual. O global deve mostrar a média dos totais e a quantidade de avaliações. Editar uma opinião deve manter um único documento para o mesmo usuário e pessoa.

Um perfil vinculado à conta atual deve bloquear a avaliação tanto na tela quanto no Firestore. Teste em outro aparelho ou navegador com a mesma conta para conferir a persistência remota.

Tente cadastrar outro perfil marcando “Este é meu perfil”: o app deve informar que sua conta já está vinculada a uma pessoa. Isso também deve ser bloqueado após remover logicamente o primeiro perfil. Cadastrar outras pessoas sem essa opção continua permitido.

## Se algo não funcionar

- Tela “Configure a conexão”: execute flutterfire configure e reinicie o app.
- “Acesso negado”: publique firestore.rules no mesmo projeto configurado no Flutter.
- Falha no Google Android: confira pacote, certificados SHA e o JSON atualizado.
- “unauthorized-domain” na web: adicione o domínio em Authorized domains.
- Lista ou ranking antigo: use a atualização da tela para buscar os dados mais recentes.

## iOS, se for utilizar

Em um Mac, execute flutterfire configure incluindo ios nas plataformas. O Bundle ID atual é com.example.atividadeMobile e o projeto já exige iOS 15.

Para o Google, configure GIDClientID em ios/Runner/Info.plist com o CLIENT_ID do arquivo de configuração fornecido pelo Firebase. Em CFBundleURLTypes, adicione a URL scheme indicada por REVERSED_CLIENT_ID. Siga a documentação oficial abaixo para esses campos e a associação do app no Xcode.

## Referências oficiais

- Configuração Flutter: https://firebase.google.com/docs/flutter/setup
- Autenticação e Google: https://firebase.google.com/docs/auth/flutter/federated-auth
- Google no Android: https://pub.dev/packages/google_sign_in_android
- Google no iOS: https://pub.dev/packages/google_sign_in_ios
