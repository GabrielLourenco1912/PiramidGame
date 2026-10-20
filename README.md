# PiramidGame IFPR-Pgua

Aplicativo Flutter adaptado à especificação “PiramidGame IFPR-Pgua — Especificação com Firebase e Firestore.pdf”, na raiz do projeto.

Possui cadastro/login com e-mail e senha ou Google, restauração da sessão, logout, cadastro de pessoas separado das avaliações, 15 critérios com estrelas, edição de opinião, ranking pessoal e ranking global por média. A navegação usa go_router; o estado usa Flutter Signals; as operações usam Command e Result.

## Configuração

Siga [Instrucoes_Firebase_PiramidGame.pdf](Instrucoes_Firebase_PiramidGame.pdf) ou [o guia em texto](docs/FIREBASE.md).

```bash
flutter pub get
firebase login
flutterfire configure --project=SEU_PROJECT_ID --platforms=android,web
firebase deploy --only firestore --project SEU_PROJECT_ID
flutter run
```

O arquivo `lib/firebase_options.dart` entregue é um ponto de configuração explícito: o FlutterFire deve substituí-lo com as opções do seu projeto. Até essa configuração, o aplicativo exibe uma tela de orientação. O login Google no Android também precisa dos certificados SHA e de `google-services.json` atualizado. As instruções completas estão no PDF.

Android e web são os alvos principais. O Android usa `com.example.atividade_mobile` e, com o SDK Flutter atual, exige API 24 ou superior. Para iOS, configure o Firebase e o Google no Xcode; o Bundle ID é `com.example.atividadeMobile` e o mínimo é iOS 15. Os plugins Firebase não oferecem suporte oficial a Linux.

## Dados e regras

- `usuarios/{uid}`: perfil da conta, acessível apenas por seu proprietário.
- `pessoas/{id}`: dados cadastrais; `criadoPor` define quem pode editar/remover e `usuarioUid` identifica a conta representada.
- `vinculosUsuarios/{uid}`: índice imutável com `pessoaId`, que garante um único perfil vinculado por conta.
- `avaliacoes/{uid}_{pessoaId}`: uma avaliação por usuário/pessoa, com mapa de 15 notas, soma e datas do servidor.

Ao cadastrar seu perfil, marque “Este é meu perfil”. Cada conta pode estar vinculada a no máximo uma pessoa, inclusive após a remoção lógica. O cadastro e seu vínculo são gravados na mesma transação e validados pelas regras do Firestore. `criadoPor` permite que uma conta cadastre várias outras pessoas sem assumir a identidade delas.

Para associar uma pessoa existente, o responsável pelo Firebase deve conferir a identidade e manter `usuarioUid` e `vinculosUsuarios/{uid}.pessoaId` consistentes. Projetos com dados antigos podem [zerar os cadastros ou regularizar os vínculos antes de publicar as novas regras](docs/VINCULO_USUARIO_PESSOA.md). Sem vínculo, não é possível identificar a autoavaliação.

A remoção é lógica (`ativo=false`): retira o perfil das listas e rankings e mantém o histórico. Pessoas sem avaliações não entram nos rankings. Empates seguem a ordem alfabética. Os dados são buscados ao abrir as telas e ao atualizar. O ranking global é calculado no cliente, adequado ao escopo didático; consultas a todas as avaliações podem precisar de agregação no servidor se o volume crescer.

SharedPreferences guarda somente o tema. Firebase Authentication controla a sessão; o Firestore guarda os dados principais. SQLite/Drift foram removidos. Dados de instalações da versão anterior não são migrados automaticamente para a nuvem.

## Arquitetura

`services → repositories → use cases → facades → viewmodels → UI`

`lib/data` contém os adaptadores de Firebase e SharedPreferences; `lib/domain` contém os modelos, contratos e regras; `lib/presentation` contém ViewModels e telas. A UI acessa somente as ViewModels. O tema fica em `lib/app/theme`.

## Verificação local

```bash
flutter analyze
flutter test
npm --prefix firebase-tests ci
npm --prefix firebase-tests test
```

Os testes Flutter usam Firestore simulado para verificar regras de negócio e fluxos de interface. Os testes em `firebase-tests` usam o emulador oficial para validar `firestore.rules`, incluindo propriedade, vínculo, unicidade, notas, soma e remoção. O projeto de teste `demo-piramidgame` não acessa o Firebase real. O emulador precisa de Node e Java compatíveis com o Firebase CLI.

Para regenerar o PDF:

```bash
python3 -m pip install reportlab
python3 scripts/gerar_guia_firebase.py
```
