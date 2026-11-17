# Foto de perfil: configuração e uso

A funcionalidade usa o mesmo projeto Firebase já configurado, `piramidgame`. A imagem fica no **Cloud Storage for Firebase** e sua URL fica no Firestore. Não é necessário criar outro projeto ou salvar imagens em base64 no banco.

## Passos manuais no Firebase

1. Abra [Storage do projeto piramidgame](https://console.firebase.google.com/project/piramidgame/storage). Se ainda não estiver habilitado, clique em **Começar/Get started** para criar o bucket padrão. Escolha a região e inicie com acesso restrito.
2. Se solicitado, vincule uma conta de faturamento e habilite o **plano Blaze**. Atualmente o Cloud Storage exige esse plano, mesmo que o uso fique dentro das franquias gratuitas. Veja a [documentação oficial](https://firebase.google.com/docs/storage/flutter/start).
3. Confira o nome do bucket na aba **Arquivos/Files**. O app já está configurado para `piramidgame.firebasestorage.app`. Se o console mostrar outro nome, atualize `storageBucket` nas configurações Android e web de `lib/firebase_options.dart` ou execute `flutterfire configure --project=piramidgame --platforms=android,web`.
4. Em **Storage → Regras**, publique o conteúdo de [`storage.rules`](../storage.rules). Em **Firestore Database → Regras**, publique o conteúdo completo de [`firestore.rules`](../firestore.rules). As duas regras são necessárias: a pessoa agora pode ter o campo opcional `foto`.

Como alternativa ao passo 4, publique os arquivos locais pela CLI, na raiz do projeto:

```bash
firebase deploy --only firestore:rules,storage --project piramidgame
```

Não é necessário criar pastas, documentos, índices ou Cloud Functions manualmente. O aplicativo cria os arquivos e atualiza os documentos. Depois da configuração, encerre o app e execute `flutter run` novamente para incluir os novos plugins nativos; hot reload não os instala.

## Uso no celular

Na tela **Início**, toque no avatar com o ícone de câmera. A mesma opção aparece no perfil da pessoa vinculada à sua conta por **Este é meu perfil**.

- **Tirar foto** abre a câmera nativa e solicita sua autorização.
- **Escolher da galeria** abre o seletor nativo. O app recebe somente a foto escolhida; não solicita acesso amplo ao armazenamento.
- **Remover foto** volta a exibir as iniciais do nome.

Cancelar a câmera/galeria mantém a foto anterior. Se a permissão for negada, o app explica como autorizá-la nas configurações do celular. A foto também pode ser alterada antes de cadastrar a pessoa vinculada; esse cadastro herda a foto da conta.

Android declara `CAMERA`, solicitada pelo `image_picker` em tempo de execução. Não usa `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES` ou permissão de microfone. No iOS, as descrições de uso da câmera e da biblioteca estão em `ios/Runner/Info.plist`. O seletor usa `requestFullMetadata: false`, evitando acesso a metadados desnecessários; selecionar uma foto no seletor do sistema concede acesso àquela foto. A [documentação do plugin](https://pub.dev/packages/image_picker) descreve as diferenças entre plataformas.

O Firebase deste repositório continua configurado para Android e web. Para executar no iOS, inclua essa plataforma na configuração FlutterFire e configure o login Google no Xcode, como descrito em [FIREBASE.md](FIREBASE.md). Na web, câmera e seleção dependem das capacidades do navegador.

## Persistência e arquitetura

O fluxo segue `services → repository → use cases → AuthFacade → AuthViewModel → UI`, com `Command`, `Result` e Signals. A UI não acessa Firebase ou `image_picker` diretamente.

- Storage: `usuarios/{uid}/perfil/{versaoAleatoria}.png`.
- Firestore: `usuarios/{uid}.foto` guarda a URL da conta. `pessoas/{id}.foto` recebe a mesma URL se `usuarioUid` corresponder à conta; isso permite exibir a imagem nas listas e rankings sem abrir a leitura dos demais dados privados em `usuarios`.
- O cadastro de pessoa e a edição dos seus demais dados continuam seguindo as regras de criador já existentes. Somente a conta representada pode trocar a foto da pessoa, inclusive quando o cadastro foi feito por outro usuário.
- A leitura pelo SDK do Storage exige autenticação e a escrita/exclusão exige o UID proprietário. URLs geradas por `getDownloadURL` contêm tokens de acesso: quem possuir o link poderá abrir a imagem.
- A imagem é validada e reencodada como PNG, sem metadados EXIF, mantendo a proporção e limitando o maior lado a 768 pixels. Arquivos de entrada acima de 20 MiB são rejeitados; o arquivo enviado tem limite de 5 MiB, também validado nas regras.
- Cada troca usa um nome novo para evitar cache da foto antiga. O upload termina antes da transação que atualiza a conta e a pessoa. Se a gravação falhar, a foto anterior permanece e o app tenta remover o arquivo novo. Depois de uma troca/remoção confirmada, tenta excluir a versão antiga; uma falha nessa limpeza pode deixar um arquivo sem referência no bucket.
- O Firestore é a fonte da foto escolhida: restaurar a sessão ou entrar novamente com Google preserva a personalização e a remoção.
- Se o Android encerrar o app durante a câmera/galeria, a seleção é recuperada na próxima abertura autenticada. SharedPreferences guarda temporariamente apenas o UID que iniciou a seleção, além da preferência de tema. O arquivo e sua URL não são persistidos ali; uma seleção iniciada por outra conta é descartada.

## Verificação

```bash
flutter analyze
flutter test
npm --prefix firebase-tests test
```

Os testes usam Firestore simulado e emuladores locais do Firestore e Storage com o projeto `demo-piramidgame`; não alteram o projeto real. Cobrem persistência, remoção, login Google, cancelamento, permissões negadas, falhas de upload/gravação, recuperação da seleção, processamento da imagem e isolamento por usuário nas regras.

No dispositivo, confira a primeira autorização da câmera, a recusa e nova tentativa, seleção na galeria, cancelamento, remoção, reinício do app e a foto do perfil vinculado vista por outra conta. O diálogo real de permissão e a câmera física exigem essa validação em Android/iOS.
