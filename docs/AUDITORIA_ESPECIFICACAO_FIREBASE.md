# Auditoria da especificação do PiramidGame

Conferência em 05/10/2026 do [PiramidGame IFPR-Pgua — Especificação com Firebase e Firestore.pdf](</home/gabriel/IdeaProjects/atividade_mobile/PiramidGame IFPR-Pgua — Especificação com Firebase e Firestore.pdf>), de 25 páginas, contra o código desta pasta. Os números de página abaixo são as páginas físicas do arquivo.

**O projeto implementa a maior parte das funcionalidades e da arquitetura exigidas. Não considero comprovado o cumprimento integral:** o bloqueio de autoavaliação depende de vínculo opcional; há uma fragilidade na restauração da sessão; a remoção preserva os dados, enquanto a especificação menciona exclusão definitiva; e os serviços não utilizam Result nos seus próprios retornos, o que é uma ressalva diante da redação literal entre camadas.

A operação real do projeto Firebase também não foi comprovada por testes de login e persistência em dispositivos reais. Essa pendência é distinta de ausência de código: Android e web já possuem configurações locais geradas para `piramidgame`, inclusive cliente OAuth Web no JSON Android.

O [guia de instruções](</home/gabriel/IdeaProjects/atividade_mobile/Instrucoes_Firebase_PiramidGame.pdf>) descreve decisões da adaptação atual. Para avaliar conformidade, a exigência usada aqui é a especificação original. A [explicação do guia][guide] detalha os comandos e configurações.

## Como ler os pareceres

**Implementado** significa que encontrei o comportamento no código; quando há cobertura, indiquei o teste. **Parcial** significa que há um caminho implementado, mas uma condição necessária limita o requisito. **Ressalva de interpretação** indica diferença de redação que pode afetar uma avaliação literal. **Pendente de validação real** significa que o código e a configuração local existem, mas o funcionamento na nuvem ou no aparelho não foi testado nesta análise.

Exigências repetidas nos capítulos 23 e 26 foram agrupadas com suas ocorrências mais detalhadas. Nomes de classes e estruturas introduzidos por “por exemplo”, “poderão existir” ou “estrutura sugerida” são referências de organização, não uma obrigação de criar todos aqueles arquivos com aqueles nomes.

## Verificação executada

| Conferência | Resultado e alcance |
|---|---|
| Extração e leitura dos PDFs | 3 páginas de instruções e 25 páginas de especificação. |
| `flutter analyze --no-pub` | `No issues found!`; análise estática aprovada. |
| `flutter test --no-pub` | 20 testes existentes aprovados: 11 de regras/lógica e 9 de interface. |
| `npm --prefix firebase-tests test` | 12 testes existentes das regras aprovados no emulador oficial Firestore, projeto `demo-piramidgame`. |
| Reprodução adicional de perfil sem vínculo | Teste temporário Flutter confirmou que a conta Alice consegue avaliar um perfil Alice criado por ela com `usuarioUid=null`. |
| Reprodução adicional de sessão | Teste temporário com AuthService simulando conta válida e FirestoreService falhando confirmou que a ViewModel passa a considerar o usuário não autenticado. |
| Reprodução adicional das regras | Emulador confirmou aceitação de voto da conta Alice no perfil sem vínculo e recusa quando o mesmo perfil possui `usuarioUid=alice`. |
| Inspeção de configuração | `firebase_options.dart`, `firebase.json` e JSON Android apontam para `piramidgame`; pacote Android consistente; clientes OAuth Android e Web presentes. |

Os testes Flutter usam [Firestore simulado e um repositório de autenticação de teste][test-environment]. O teste de interface “Google usa o Command” confirma o fluxo da tela, não a troca real de credenciais com o Google. O emulador confirma as regras locais carregadas do arquivo, não qual versão está publicada no projeto remoto.

As reproduções adicionais foram executadas em arquivos temporários em `/tmp`. Elas conferem o comportamento atual e demonstram as ressalvas; não são correções desses comportamentos. Nenhum arquivo do aplicativo ou das regras foi alterado por esta auditoria.

## Tecnologias e arquitetura obrigatórias

| ID | Citação literal e origem no PDF | Onde foi implementado e parecer |
|---|---|---|
| T01 | “utilizar Flutter para o desenvolvimento” — §2, p. 2 | Dependência SDK Flutter em [pubspec.yaml][pubspec], inicialização em [main.dart][main] e telas em `lib/presentation`. **Implementado.** |
| T02 | “utilizar Firebase Authentication para autenticação dos usuários” — §2, p. 2 | [AuthService][auth-service] chama `FirebaseAuth`; [main.dart][main] injeta sua instância. **Implementado; operação real pendente.** |
| T03 | “utilizar Firestore como banco de dados remoto” — §2, p. 2 | [FirestoreService][firestore-service] acessa `usuarios`, `pessoas` e `avaliacoes`. Os modelos e notas são serializados para documentos. **Implementado; persistência real pendente.** |
| T04 | “utilizar SharedPreferences somente para armazenamento local de preferências, cache e informações auxiliares relacionadas à sessão” — §2, p. 2 | [ThemeLocalService][theme-local] grava apenas `piramidgame_theme_mode`. O [teste de preferência][test-theme-storage] verifica a única chave gravada. **Implementado.** A lista do PDF permite esses usos auxiliares; não obriga a implementar todos os exemplos. |
| T05 | “Não será permitido utilizar SharedPreferences, SQLite, Hive ou arquivos JSON como mecanismo principal de persistência dos dados.” — §2, p. 3 | Dados principais são persistidos pelo [FirestoreService][firestore-service]. Não encontrei armazenamento principal por esses mecanismos nem dependências SQLite/Hive/Drift no pubspec. Métodos `toJson` de modelos apenas representam dados para conversão. **Implementado.** |
| T06 | “A senha do usuário não deverá ser armazenada no SharedPreferences.” — §3.3, p. 4 | Senha é enviada ao [Firebase Auth][email-service]; o [serviço local][theme-local] conhece somente tema. O perfil em [Firestore][save-user] não contém senha. **Implementado.** |
| T07 | “utilizar o pacote go_router para navegação entre telas” — §2, p. 2 | [AppRouter][router] declara as rotas, usa `redirect` e é ligado ao [MaterialApp.router][app-widget]. **Implementado.** Fechar um diálogo com Navigator não elimina o uso de go_router na navegação principal. |
| T08 | “utilizar Flutter Signals para gerenciamento de estado e reatividade” — §2, p. 2 | Signals de usuário, listas, avaliações, rankings e tema nas [ViewModels][viewmodels]. Telas usam `SignalWidget`/`SignalStatefulWidget`, como [RankingPage][ranking-page]. **Implementado.** Há também estado local de formulário com `setState`; o estado compartilhado usa Signals. |
| T09 | “utilizar um arquivo próprio de tema para definir a identidade visual da aplicação” — §2, p. 3 | [AppTheme][app-theme] reúne temas claro e escuro; cores e tipografia são separadas em `lib/app/theme`. **Implementado.** |
| T10 | “permitir alternância entre tema claro e escuro em tempo de execução” — §2, p. 3 | [ThemeViewModel][theme-vm], [botão na barra superior][theme-button] e [themeMode da aplicação][app-widget]. [Teste de interface][widget-theme] aprovado. **Implementado.** |
| T11 | “utilizar o padrão MVVM” — §2, p. 3 | Modelos em `domain/models`, ViewModels em `presentation/viewmodels`, telas em `presentation/pages`. [AppDependencies][dependencies] expõe as ViewModels à UI. **Implementado.** |
| T12 | “utilizar o padrão Command para disparar ações da interface” — §2, p. 3 | [Command e Command1][command] controlam execução, resultado e erro. Login, cadastro, Google, logout, CRUD, avaliação, rankings e tema têm commands nas [ViewModels][viewmodels]. **Implementado para as operações da aplicação.** |
| T13 | “utilizar o padrão Result para encapsular retornos de sucesso e erro entre as camadas” — §2, p. 3 | [Result, Success e Failure][result] são usados em contratos de repositories, use cases, facades e commands. [AuthService][auth-service], [FirestoreService][firestore-service] e [ThemeLocalService][theme-local] retornam valores/Futures comuns e lançam exceções, convertidas nos repositories. **Implementado nas camadas superiores, com ressalva de interpretação literal para service → repository.** |
| T14 | “programar respeitando os princípios do SOLID” — §2, p. 3 | Use cases dependem de [contratos abstratos de repositories][repository-contract]; [AppViewModels][viewmodels] recebe dependências por construtor; telas recebem ViewModels. **Estrutura compatível**, com evidências detalhadas abaixo. Não há um teste automático que certifique SOLID para todo o código. |
| T15 | “organizar o projeto segundo os princípios da Arquitetura Limpa” — §2, p. 3 | Domínio com modelos e contratos sem importações diretas de Firebase/Flutter; adaptadores em `data`; interface em `presentation`; montagem em `app`/`main`. [Caso de uso][save-evaluation] depende de interfaces. **Estrutura compatível com a exigência.** |
| T16 | “services → repositories → use cases → facade de use cases → viewmodel” — §4, p. 5; a sequência termina em UI | Exemplo completo: [FirestoreService][firestore-service] → [EvaluationRepositoryImpl][evaluation-repo] → [SaveEvaluationUseCase][save-evaluation] → [EvaluationFacade][evaluation-facade] → [EvaluationViewModel][evaluation-vm] → [EvaluationPage][evaluation-page]. **Implementado.** A chamada parte da UI e percorre essa cadeia no sentido contrário até o recurso externo. |
| T17 | “Os repositories deverão utilizar os services para acessar os recursos necessários.” — §4.2, p. 5 | [StudentRepositoryImpl][student-repo], [EvaluationRepositoryImpl][evaluation-repo], [AuthRepositoryImpl][auth-repo] e [ThemeRepositoryImpl][theme-repo] usam services e não dependem de widgets. **Implementado.** |
| T18 | “A camada de Use Cases será responsável pelas regras de negócio da aplicação.” — §4.3, p. 6 | Validação de credenciais em [auth_use_cases.dart][auth-cases], cadastro em [StudentValidation][student-validation], avaliação em [evaluation_use_cases.dart][save-evaluation] e cálculo em [ranking_use_cases.dart][ranking-cases]. **Implementado**, com verificações defensivas também no serviço e nas regras remotas. |
| T19 | “A facade deverá agrupar os use cases relacionados” — §4.4, p. 6 | [AuthFacade][auth-facade], [StudentUseCasesFacade][student-facade], [EvaluationFacade][evaluation-facade], [RankingFacade][ranking-facade] e [ThemeUseCasesFacade][theme-facade]. **Implementado.** |
| T20 | “A UI deverá se comunicar com a respectiva ViewModel.” — §4.6, p. 8 | Telas usam [AppDependencies][dependencies] para acessar ViewModels. Não encontrei importações de Firebase Auth, Firestore, SharedPreferences, services ou repositories em `lib/presentation`. **Implementado.** `main.dart` importa SDKs para montar dependências; não é uma tela que consulta o banco. |

### Onde estão os casos de uso mencionados no capítulo 4

Os exemplos do PDF estão cobertos desta forma:

| Grupo | Operações presentes | Arquivos |
|---|---|---|
| Conta | Cadastro, login e-mail/senha, Google, restauração, observação da sessão e logout | [auth_use_cases.dart][auth-cases] e [AuthFacade][auth-facade]. |
| Pessoas | Cadastrar, alterar, remover, listar e buscar por ID | `create_student_use_case.dart`, `update_student_use_case.dart`, `delete_student_use_case.dart`, `get_students_use_case.dart`, `get_student_by_id_use_case.dart`, reunidos em [StudentUseCasesFacade][student-facade]. |
| Avaliações | Salvar/criar ou alterar, consultar por pessoa e buscar minhas avaliações | [evaluation_use_cases.dart][save-evaluation] e [EvaluationFacade][evaluation-facade]. |
| Autoavaliação | Comparação de `usuarioUid` com o UID autenticado | Dentro de [SaveEvaluationUseCase][save-evaluation], além das outras proteções. |
| Rankings | Calcular pessoal e global | [ranking_use_cases.dart][ranking-cases] e [RankingFacade][ranking-facade]. |
| Tema | Obter e alterar preferência | [ThemeUseCasesFacade][theme-facade] e use cases correspondentes. |

Não há um `RankingRepository` separado; o cálculo usa os contratos de pessoas e avaliações. O PDF apresenta esse nome como exemplo, e a função necessária existe. Da mesma forma, salvar uma avaliação e alterar a opinião usam o mesmo caso de uso com o mesmo ID, atendendo ao comportamento solicitado.

### Evidências de SOLID

| Princípio | Evidência encontrada |
|---|---|
| Responsabilidade única | Separação entre telas, estado, casos de uso e adaptadores de dados; preferência de tema possui serviço próprio. |
| Aberto/fechado | Casos de uso recebem contratos; outra implementação de armazenamento pode substituir o adapter sem colocar consultas Firebase nas telas. |
| Substituição de Liskov | Repositório de autenticação de teste substitui o contrato na [montagem dos testes][test-environment], mantendo os fluxos de interface. Essa é uma evidência concreta de substituição, não prova formal de todas as implementações. |
| Segregação de interfaces | Contratos próprios para autenticação, pessoas, avaliações e tema; o use case de tema não precisa conhecer operações de pessoas. |
| Inversão de dependência | Regras de negócio dependem dos contratos em `domain/repositories`; implementações Firebase ficam em `data/repositories`. |

A organização explicitada pelo PDF é verificável. Uma convenção adicional de sala de aula que não esteja neste documento não pode ser conferida sem seu material de referência.

## Contas, autenticação e sessão

| ID | Citação literal e origem no PDF | Onde foi implementado e parecer |
|---|---|---|
| A01 | “Ao realizar o cadastro, deverá ser criado um usuário no Firebase Authentication.” — §3.1, p. 3 | [AuthService.register][email-service] chama `createUserWithEmailAndPassword`; [AuthRepositoryImpl][auth-repo] grava também o perfil em `usuarios`. **Implementado; cadastro remoto real pendente.** |
| A02 | “Posteriormente, o usuário poderá acessar novamente a aplicação utilizando essas credenciais.” — §3.1, p. 3 | [AuthService.login][email-service] chama `signInWithEmailAndPassword`, acionado pelo command de login. **Implementado; autenticação remota real pendente.** |
| A03 | “Nesse caso, a autenticação deverá ser integrada ao Firebase Authentication.” — Conta Google, §3.1, p. 3 | [AuthService.loginWithGoogle][google-service] usa popup Firebase na web; no Android obtém ID token Google e chama `signInWithCredential`. JSON possui cliente Web tipo 3. **Implementado; login Google real pendente.** |
| A04 | “Antes de acessar as principais funcionalidades, o usuário deverá estar autenticado.” — §6, p. 8 | [AppRouter.redirect][router] envia anônimos ao login; repositories e [regras][rules] também exigem autenticação. [Teste de rota protegida][widget-route] e teste de acesso anônimo nas regras aprovados. **Implementado.** |
| A05 | “deverá ser exibida a tela de Splash” — §6, p. 9 | Rota inicial `/splash`; [SplashPage][splash] exibe identidade visual e aciona o command após 2 segundos. **Implementado no fluxo de inicialização bem-sucedida do Firebase.** |
| A06 | “o aplicativo deverá verificar o estado da autenticação” — §6, p. 9 | [AuthService][auth-session] usa `authStateChanges`; [AuthViewModel][auth-vm] observa a sessão; [router][router] aguarda inicialização e fim da splash. Usuário válido segue para home; ausente segue para login. **Implementado no fluxo normal; ressalva na falha do perfil, abaixo.** |
| A07 | “o usuário não deverá precisar informar suas credenciais novamente enquanto houver uma autenticação válida.” — §14.3, p. 15 | O serviço restaura a sessão e há [teste de restauração][widget-restore]. Entretanto, [AuthRepositoryImpl._persistSession][auth-profile] exige salvar perfil no Firestore antes de retornar sucesso, e a [ViewModel][auth-apply] remove o usuário em qualquer Failure. **Parcial diante de falha no Firestore; reprodução confirmada.** |
| A08 | “Permitir o encerramento da sessão.” — §14.4, p. 15 | [AuthService.logout][logout-service] encerra Firebase e, quando inicializado, Google; [botão da barra][logout-button] usa command; [AppWidget][session-clear] limpa dados de outras ViewModels na mudança de UID. **Implementado e testado.** |
| A09 | “Erros de autenticação deverão ser tratados adequadamente e informados ao usuário.” — §19, p. 20 | [firebaseErrorMessage][error-map] traduz credencial inválida, e-mail existente, senha fraca, rede, conta desativada e outros; [AuthPage][auth-page] exibe `errorMessage`. **Implementado.** |
| A10 | “desde que esteja autenticado com a mesma conta.” — Acesso em outro dispositivo, §3.2, p. 4 | Dados ligados ao UID são buscados no [FirestoreService][firestore-service], e a [consulta pessoal][personal-query] filtra `avaliadorUid`. Há teste com segunda instância de serviço sobre o mesmo Firestore simulado. **Implementação presente; pendente testar em dois dispositivos reais.** |

## Pessoas, campos e seleção

| ID | Citação literal e origem no PDF | Onde foi implementado e parecer |
|---|---|---|
| P01 | “usuário autenticado e pessoa avaliada.” — §5, p. 8 | Modelos [AppUser][user-model] e [Student][person-model], além de coleções separadas `usuarios` e `pessoas`. **Implementado.** |
| P02 | “Uma pessoa poderá ser cadastrada para receber avaliações sem possuir uma conta de autenticação.” — §5, p. 8 | [createStudent][create-person] grava documento em `pessoas`, sem chamada de criação de conta; `usuarioUid` pode ser null. **Implementado.** |
| P03 | “um usuário autenticado poderá estar relacionado a uma pessoa existente no sistema.” — §5, p. 8 | Campo [usuarioUid][person-model] e associação administrativa descrita em [docs/FIREBASE.md][binding-guide]. O app cria vínculo no cadastro próprio; para um perfil existente, a associação ocorre pelo console. **Implementado como possibilidade administrativa; depende da operação correta.** |
| P04 | “nome”; “curso”; “turma/ano”; “apelido”; “data de nascimento.” — §7, p. 9 | Todos constam de [Student][person-model], [StudentFormPage][person-form] e da [serialização Firestore][person-data]. **Implementado.** |
| P05 | “INFO”; “MEC”; “MAMB”; “PROD”; “TADS”; “TGA.” — §8.1, pp. 9–10 | Lista exata em [CourseConstants][courses], seleção em [CourseSelector][course-selector] e validação no [caso de uso][student-validation] e nas [regras][rules-person-validation]. **Implementado e testado.** |
| P06 | “um ano entre: 1998 e 2026.” — §8.2, p. 10 | Limites em [AppConstants][years], dropdown [YearSelector][year-selector], validação de domínio e nas regras. **Implementado e testado.** O ano final fixo em 2026 corresponde ao texto do PDF. |
| P07 | “Campos com digitação:”; “nome”; “apelido.” — §8.3, p. 10 | [TextFormFields][person-fields] para nome e apelido. **Implementado.** |
| P08 | “A data de nascimento deverá ser selecionada preferencialmente utilizando um componente como DatePicker.” — §8.3, p. 10 | [showDatePicker][birth-picker] para nascimento; seletores próprios para curso e ano. **Implementado.** |
| P09 | “Mostrar as pessoas cadastradas.” — §14.6, p. 16 | [StudentListPage][person-list], cards com dados básicos e consulta somente a pessoas ativas. **Implementado.** Nível Lenda na listagem aparece como informação que “poderá” ser exibida; não é obrigatório em todos os cards. |
| P10 | “Permitir a visualização das informações completas de uma pessoa.” — §14.7, p. 16 | [StudentDetailPage][person-details] exibe nome, apelido, curso, ano e nascimento, além da opinião da conta atual quando existe. **Implementado.** |
| P11 | “Permitir a edição dos dados cadastrais.” — §14.8, p. 16 | Mesma [tela de formulário][person-form] em modo de edição; command/use case/repository/serviço correspondentes. [Serviço][edit-person] e regras exigem criador. **Implementado.** Essa restrição de propriedade é uma regra adotada pelo sistema. |
| P12 | “Permitir a exclusão de uma pessoa conforme as regras definidas pelo sistema.” — §14.9, p. 16 | [removeStudent][remove-service] marca `ativo=false`, retirando das consultas e rankings, preservando documento e avaliações. **Remoção funcional implementada, com ressalva quanto a exclusão definitiva.** |
| P13 | “A remoção deverá solicitar confirmação antes da exclusão definitiva.” — §14.9, p. 16 | [ConfirmDeleteDialog][delete-dialog] é chamado na [listagem][list-delete] e nos [detalhes][detail-delete]. Confirmação existe e informa preservação do histórico. **Confirmação atendida; não há exclusão física.** As [regras][rules-people] negam `delete`. |

## Avaliações e pontuação

| ID | Citação literal e origem no PDF | Onde foi implementado e parecer |
|---|---|---|
| E01 | “O usuário autenticado não poderá avaliar a si próprio.” — §9, p. 10 | [Tela de avaliação][evaluation-self], [caso de uso][save-evaluation], [serviço][save-rating] e [regras][rules-evaluation-validation] comparam `usuarioUid` ao UID da conta. **Parcial: bloqueio forte para perfil vinculado, mas vínculo opcional permite contornar a regra.** |
| E02 | “usuário que realizou a avaliação”; “pessoa avaliada”; “notas atribuídas”; “pontuação total”; “data da avaliação.” — §9, p. 11 | Campos de [Evaluation][evaluation-model] e [gravação no Firestore][save-rating] contêm todos os dados. **Implementado.** |
| E03 | “Cada pessoa será avaliada utilizando 15 critérios.” — §10, p. 11 | Os 15 nomes e descrições constam de [PopularityCriteria][criteria] e são exibidos na [EvaluationPage][evaluation-fields]. Lista exata detalhada abaixo. **Implementado.** |
| E04 | “Cada critério deverá utilizar um sistema de Star Rating, permitindo notas de 1 a 5 estrelas.” — §10, p. 11 | [StarRating][stars] gera 5 opções, com valores `index + 1`. Modelo, serviço e regras recusam valores fora da faixa e critérios incompletos. **Implementado e testado.** |
| E05 | “A soma das notas atribuídas formará o:” e “Nível Lenda” — §11, p. 13 | [PopularityScore.total][score-model] soma as notas; [Evaluation.pontuacaoTotal][evaluation-model] deriva o total; a tela o atualiza durante o preenchimento. **Implementado.** |
| E06 | “15 × 5 = 75 pontos”; “15 × 1 = 15 pontos” — §11, p. 13 | Notas completas e entre 1 e 5 asseguram a faixa; [teste Flutter][test-score] e teste das [regras][rules-test] verificam os dois extremos. **Implementado e testado.** |
| E07 | “avaliação sem usuário autenticado”; “notas inferiores a 1”; “notas superiores a 5”; “criação de avaliações inválidas.” — §16, p. 18 | [SaveEvaluationUseCase][save-evaluation] verifica conta, pessoa e notas; [validEvaluation][rules-evaluation-validation] valida UID, pessoa ativa, mapa, soma e datas. **Implementado e testado**, observada a ressalva separada de autoavaliação. |
| E08 | “Cada usuário deverá possuir apenas uma avaliação ativa para cada pessoa avaliada.” — §16, p. 18 | [Evaluation.id][evaluation-model] é `${avaliadorUid}_${pessoaId}`; [saveEvaluation][save-rating] escreve nesse documento; [regras][rules-evaluation-validation] exigem a mesma composição. [Teste de alteração][test-unique-rating] aprovado. **Implementado.** |
| E09 | “o usuário deverá alterar sua avaliação existente, em vez de criar uma nova avaliação da mesma pessoa.” — §16, p. 18 | [EvaluationPage][evaluation-load] carrega opinião anterior; [gravação][save-rating] mantém ID e `dataAvaliacao`, atualiza notas e `atualizadoEm`. Só o autor atualiza conforme repository e regras. [Teste de interface][widget-rating-edit] aprovado. **Implementado.** |
| E10 | “Essas informações deverão ser armazenadas no Firestore.” — §9, p. 11 | [saveEvaluation][save-rating] grava mapa de notas, total, autoria, pessoa e timestamps em `avaliacoes`. **Implementado; persistência remota real pendente.** |

### Conferência dos 15 critérios, páginas 11 e 12

Cada nome abaixo é uma citação literal da lista do §10. Os mesmos nomes estão em [popularity_criteria.dart][criteria]. Todos são renderizados por um único loop em [evaluation_page.dart][evaluation-fields], evitando telas com listas diferentes.

| Nº | Nome no PDF | Chave implementada no mapa `notas` |
|---|---|---|
| 1 | “Resenha” | `resenha` |
| 2 | “Presença VIP” | `presenca_vip` |
| 3 | “Aura” | `aura` |
| 4 | “Modo Parceiro” | `modo_parceiro` |
| 5 | “Carisma Natural” | `carisma_natural` |
| 6 | “Humor de Milhões” | `humor_de_milhoes` |
| 7 | “Energia de Grupo” | `energia_de_grupo` |
| 8 | “Criatividade Caótica” | `criatividade_caotica` |
| 9 | “Modo Atleta” | `modo_atleta` |
| 10 | “Talento de Palco” | `talento_de_palco` |
| 11 | “Drip Escolar” | `drip_escolar` |
| 12 | “Coração de Dorama” | `coracao_de_dorama` |
| 13 | “Queridinho dos Professores” | `queridinho_dos_professores` |
| 14 | “Cérebro Turbo” | `cerebro_turbo` |
| 15 | “Caos Controlado” | `caos_controlado` |

As descrições preservam o sentido dos critérios. A organização em mapa `notas` e os nomes internos em snake_case são permitidos pela abertura do §15, p. 18: “Os grupos poderão propor outra organização no Firestore”. A presença dos dados e o funcionamento das regras são o que deve ser conferido.

As estrelas começam em 1 para cada critério. Portanto, uma avaliação nova começa em 15 pontos. O PDF exige notas de 1 a 5 e não exige um estado inicial sem nota; esse valor inicial está dentro da especificação.

## Rankings e persistência

| ID | Citação literal e origem no PDF | Onde foi implementado e parecer |
|---|---|---|
| R01 | “Esse ranking deverá considerar exclusivamente as avaliações realizadas pelo usuário atualmente autenticado.” — §12, p. 14 | [CalculatePersonalRankingUseCase][personal-ranking] busca `byUser(user.uid)` e filtra novamente pelo UID; [FirestoreService][personal-query] consulta esse campo. [Teste com Alice e Bob][test-rankings] aprovado. **Implementado.** |
| R02 | “Nesse ranking deverão ser consideradas as avaliações realizadas por todos os usuários do aplicativo.” — §13, p. 14 | [CalculateGlobalRankingUseCase][global-ranking] usa `evaluations.all()`, permitido a autenticados nas regras. Pessoas inativas e autoavaliações identificadas pelo vínculo são excluídas do cálculo. **Implementado, com a ressalva de identidade já descrita.** |
| R03 | “sua pontuação global deverá considerar a média das avaliações recebidas.” — §13, p. 14 | [_calculate][ranking-cases] agrupa por pessoa e avaliador e calcula `total / ratings.length`. **Implementado e testado.** Exemplo conferido: 60 e 75 resultam em 67,5. |
| R04 | “O ranking deverá ser ordenado da maior média para a menor.” — §13, p. 15 | [entries.sort][ranking-sort] compara pontuações em ordem decrescente. A mesma organização ordena o pessoal. Empates usam nome e depois ID, decisão adicional coerente. **Implementado e testado.** |
| R05 | “Também deverá ser possível exibir a quantidade de avaliações recebidas.” — §13, p. 15 | [RankingEntry][ranking-model] contém quantidade; [RankingCard][ranking-count] exibe no global. **Implementado e testado.** |
| R06 | “A diferença entre os dois rankings deverá estar clara na aplicação.” — §25, p. 24 | [RankingPage][ranking-description] tem seletor Pessoal/Global e textos “O campus na sua opinião” e “A opinião de todo o campus”, explicando filtro e média. **Implementado e testado.** |
| R07 | “os dados deverão permanecer disponíveis após o fechamento da aplicação” — §23, p. 23 | Dados principais são gravados no Firestore e relidos pelas camadas; tema local persistido. **Implementação presente; validação em reinício e dois aparelhos reais pendente.** Não há exigência de armazenar o ranking pronto: o app o recalcula a partir das avaliações. |

## Todas as telas obrigatórias

O §17, pp. 18–19, diz: “O aplicativo deverá possuir obrigatoriamente:”. A tabela usa os nomes literais dessa lista. As rotas estão em [app_router.dart][router-routes].

| Tela ou funcionalidade citada | Página do PDF | Implementação e caminho de acesso |
|---|---|---|
| “tela de Splash” | 18 | [SplashPage][splash], rota `/splash`. |
| “tela de Login” | 18 | [AuthPage][auth-page], rota `/login`. |
| “tela ou funcionalidade de Cadastro de usuário” | 18 | [AuthPage][auth-page] com `registration: true`, rota `/register`. |
| “opção de autenticação com Google” | 18 | [Botão Google][google-button] na tela de autenticação. |
| “tela de Sobre o App” | 18 | [AboutPage][about], rota `/about`. |
| “tela para listar pessoas” | 18 | [StudentListPage][person-list], rota `/students`. |
| “tela para cadastrar pessoa” | 19 | [StudentFormPage][person-form], rota `/students/new`. |
| “tela para visualizar detalhes” | 19 | [StudentDetailPage][person-details], rota `/students/:id`. |
| “interface para avaliar pessoa” | 19 | [EvaluationPage][evaluation-page], rota `/students/:id/evaluate`. |
| “tela de Ranking Pessoal” | 19 | [RankingPage][ranking-page], rota `/ranking`. |
| “tela de Ranking Global” | 19 | [RankingPage][ranking-page] com `global: true`, rota `/ranking/global`. |

**Todas essas interfaces estão presentes.** Compartilhar um componente entre as duas rotas de ranking e entre login/cadastro é compatível com a liberdade de organização descrita na p. 19. Há ainda rota de edição `/students/:id/edit` e acesso às seções pelo [AppScaffold][scaffold].

O capítulo 19, p. 20, exige “campo de e-mail”, “campo de senha”, “botão Entrar”, “opção Criar conta” e “opção Entrar com Google”. Todos estão na [AuthPage][auth-page], com máscara de senha, validação, estado de execução e área de erro.

A Splash contém nome, marca e referência ao campus e a frase de apresentação, elementos sugeridos pelo capítulo 18. A verificação da autenticação e seus redirecionamentos constam das linhas A05 e A06.

### Conteúdo obrigatório da tela Sobre

O §20, pp. 20–21, exige uma tela explicando os itens abaixo. Cada linha cita literalmente um item da lista da p. 20.

| Conteúdo citado | Evidência em AboutPage | Parecer |
|---|---|---|
| “objetivo do app” | [Seção “O projeto”][about-project] apresenta a finalidade didática e as avaliações. | Implementado. |
| “contexto do IFPR – Campus Paranaguá” | Cabeçalho e [texto do projeto][about-project] mencionam o campus. | Implementado. |
| “funcionamento dos critérios” | [Seção de pontuação][about-score] explica 15 critérios de convivência, destaque e participação, com estrelas. As descrições individuais aparecem na avaliação. | Implementado. |
| “cálculo do Nível Lenda” | [Mesmo texto][about-score] explica soma e intervalo 15–75. | Implementado. |
| “funcionamento do ranking pessoal” | [Texto do pessoal][about-personal] explica que usa apenas avaliações da conta. | Implementado. |
| “funcionamento do ranking global” | [Texto do global][about-global] explica média, quantidade e ordem. | Implementado. |
| “utilização do Firestore” | [Texto de conta e dados][about-data] explica armazenamento remoto e uso em outro dispositivo. | Implementado. |
| “utilização do Firebase Authentication” | [Texto de conta e dados][about-data] descreve login, sessão e logout. | Implementado. |
| “utilização de tema claro e escuro” | [Texto de tema][about-theme] explica a troca e a persistência local. | Implementado. |

## Ressalvas que impedem afirmar cumprimento integral

### 1. Autoavaliação depende de um vínculo opcional

**Exigência:** “O usuário autenticado não poderá avaliar a si próprio.” — §9, p. 10; repetida no §14.12, p. 16, e no §16, p. 18.

**Código:** [StudentFormPage][self-optional] inicia `_myProfile=false`; no cadastro, [usuarioUid][self-form] recebe o UID somente se a opção estiver marcada. O [caso de uso][save-evaluation] e as [regras][rules-evaluation-validation] comparam exclusivamente esse campo com o avaliador.

**Reprodução:** conta Alice cadastra um perfil Alice sem marcar “Este é meu perfil”. O documento tem `criadoPor=alice`, `usuarioUid=null` e `ativo=true`. Alice envia uma avaliação de 75 pontos. O caso de uso aceita; as regras reais no emulador também aceitam. Ao usar `usuarioUid=alice`, o emulador recusa.

O sistema não identifica a pessoa real pelo nome, e essa comparação nem seria suficiente para provar identidade. A presença do bloqueio por UID está correta, mas o fluxo livre não garante o vínculo. Por isso o requisito incondicional da especificação fica **parcial**. O próprio guia, p. 2, reconhece a dependência da associação.

**Ajuste necessário para garantia mais forte:** definir um vínculo confiável conta–perfil, incluindo o tratamento de identidades ainda não vinculadas e de perfis duplicados. A associação pode ser administrativa, mas precisa fazer parte da política obrigatória de avaliação. Apenas pedir que o usuário marque a opção não elimina o contorno demonstrado.

### 2. Falha no Firestore afeta a validade de sessão na interface

**Exigência:** “enquanto houver uma autenticação válida” — §14.3, p. 15. O §3.3, p. 4, também diz: “a autenticação válida deverá continuar sendo determinada pelo Firebase Authentication.”

**Código:** [AuthRepositoryImpl._persistSession][auth-profile] executa `saveUser` no Firestore antes de devolver Success. Se essa gravação falha, devolve Failure. [AuthViewModel._applySession][auth-apply] faz `user.value=null` ao receber qualquer Failure. O router usa essa ViewModel para decidir se deve abrir login.

**Reprodução:** com o AuthService simulado retornando uma conta Alice válida e `saveUser` falhando, o repositório continua com `currentUser.uid=alice`, mas a ViewModel termina com `isAuthenticated=false`. Isso confirma a diferença no próprio código do repository/ViewModel, sem depender de um login remoto real.

O fluxo normal de restauração está implementado e passa nos testes existentes. A garantia de manter a sessão fica limitada quando o perfil remoto falha. **Ajuste recomendado:** tratar restauração da identidade e sincronização do perfil como resultados distintos, preservando a sessão Auth válida e apresentando o erro de dados separadamente.

### 3. Remover desativa; os dados permanecem

**Exigência:** “A remoção deverá solicitar confirmação antes da exclusão definitiva.” — §14.9, p. 16.

**Código:** a confirmação existe, mas [removeStudent][remove-service] grava `ativo=false`. [firestore.rules][rules-people] contém `allow delete: if false`. Os documentos da pessoa e de suas avaliações continuam armazenados e o histórico permanece legível aos autenticados conforme as regras atuais.

A p. 16 também permite exclusão “conforme as regras definidas pelo sistema”, o que abre espaço para discutir a semântica. Portanto, classifico como **remoção funcional presente, com ressalva de interpretação**, em vez de afirmar que toda remoção lógica é automaticamente inválida.

Se “exclusão definitiva” for avaliada como apagamento físico, o código atual não cumpre essa parte. Seria necessário ajustar o serviço, as permissões e o tratamento dos documentos relacionados. Se a disciplina aceitar desativação permanente no app, a implementação atual deve ser apresentada com essa decisão explícita.

### 4. Result não é o retorno dos services

**Exigência:** “os retornos entre camadas deverão utilizar o padrão Result” — §23, p. 23, além do §2, p. 3.

**Código:** contracts de repositories, use cases, facades e commands retornam Result. Os [services][firestore-service] retornam, por exemplo, `Future<Student>` e `Future<void>`, e lançam exceções. O [repository][student-repo] captura essas exceções e converte em Failure.

Esse uso cria uma fronteira de Result no repository e protege as camadas superiores. A presença do padrão está comprovada. Entretanto, se a exigência abranger literalmente **todas** as fronteiras, service → repository fica fora do padrão. Essa é uma **ressalva de interpretação arquitetural**, não uma ausência geral de Result.

### 5. Funcionamento remoto e plataformas

Não confirmei por operação real: habilitação dos provedores no console, banco `(default)` criado, região, regras/índices efetivamente publicados, domínios autorizados, certificados da instalação e login Google em aparelho/navegador real. Os arquivos locais são consistentes, mas não provam esses estados do servidor.

Também permanece pendente o teste de fechar/reabrir e acessar os mesmos dados em outro dispositivo real. Os testes simulados comprovam o caminho de código e os cálculos; o teste remoto comprovaria a integração instalada.

Android e web estão configurados. iOS ainda não está em `firebase_options.dart` e não possui os campos Google no `Info.plist`; o guia o apresenta como opção. O PDF de especificação exige Flutter, mas não estabelece que todas as plataformas suportadas pelo framework precisam ser entregues.

## Decisões presentes que o PDF permite

O mapa `notas`, o campo `turmaAno` e o ID determinístico são uma organização diferente do exemplo da p. 17, permitida pela p. 18. Há usuário autenticado separado da pessoa avaliada. Rankings são calculados a partir de dados remotos; o PDF não obriga a persistir uma coleção de rankings pronta. As consultas são executadas ao abrir e atualizar telas, e o estado recebido atualiza a interface por Signals.

As pessoas mencionadas na história das pp. 1–2 compõem o contexto do projeto. Não há instrução para pré-cadastrar obrigatoriamente todos esses personagens. Também não é obrigatório criar Storage, Cloud Functions, cache de sessão em SharedPreferences ou um service/repository separado para cada nome sugerido no capítulo 4.

Os pontos com comportamento demonstrado que merecem revisão são a política de vínculo e a separação entre sessão válida e sincronização do perfil. A definição de exclusão e o alcance do Result precisam ser apresentados conforme a interpretação adotada para as exigências. A integração remota precisa de validação prática antes de declarar o aplicativo plenamente conforme.

[guide]: /home/gabriel/IdeaProjects/atividade_mobile/docs/EXPLICACAO_GUIA_FIREBASE.md
[pubspec]: /home/gabriel/IdeaProjects/atividade_mobile/pubspec.yaml:30
[main]: /home/gabriel/IdeaProjects/atividade_mobile/lib/main.dart:18
[auth-service]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/auth_service.dart:7
[email-service]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/auth_service.dart:19
[google-service]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/auth_service.dart:35
[auth-session]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/auth_service.dart:12
[logout-service]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/auth_service.dart:64
[firestore-service]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/firestore_service.dart:8
[save-user]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/firestore_service.dart:17
[theme-local]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/theme_local_service.dart:10
[router]: /home/gabriel/IdeaProjects/atividade_mobile/lib/app/router/app_router.dart:19
[router-routes]: /home/gabriel/IdeaProjects/atividade_mobile/lib/app/router/app_router.dart:33
[app-widget]: /home/gabriel/IdeaProjects/atividade_mobile/lib/app/app_widget.dart:48
[viewmodels]: /home/gabriel/IdeaProjects/atividade_mobile/lib/app/app_viewmodels.dart:26
[ranking-page]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/ranking_page.dart:10
[app-theme]: /home/gabriel/IdeaProjects/atividade_mobile/lib/app/theme/app_theme.dart:6
[theme-vm]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/viewmodels/theme_viewmodel.dart:9
[theme-button]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/widgets/app_scaffold.dart:67
[dependencies]: /home/gabriel/IdeaProjects/atividade_mobile/lib/app/app_dependencies.dart:9
[command]: /home/gabriel/IdeaProjects/atividade_mobile/lib/core/command/command.dart:8
[result]: /home/gabriel/IdeaProjects/atividade_mobile/lib/core/result/result.dart:1
[repository-contract]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/repositories/student_repository.dart:4
[evaluation-repo]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/repositories/evaluation_repository_impl.dart:8
[student-repo]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/repositories/student_repository_impl.dart:8
[auth-repo]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/repositories/auth_repository_impl.dart:8
[theme-repo]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/repositories/theme_repository_impl.dart:6
[save-evaluation]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/use_cases/evaluation_use_cases.dart:13
[evaluation-facade]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/facades/evaluation_facade.dart:5
[evaluation-vm]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/viewmodels/evaluation_viewmodel.dart:7
[evaluation-page]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/evaluation_page.dart:13
[auth-cases]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/use_cases/auth_use_cases.dart:5
[student-validation]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/use_cases/student_validation.dart:8
[ranking-cases]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/use_cases/ranking_use_cases.dart:64
[auth-facade]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/facades/auth_facade.dart:5
[student-facade]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/facades/student_use_cases_facade.dart:9
[ranking-facade]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/facades/ranking_facade.dart:5
[theme-facade]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/facades/theme_use_cases_facade.dart:6
[rules]: /home/gabriel/IdeaProjects/atividade_mobile/firestore.rules:1
[splash]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/splash_page.dart:9
[auth-vm]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/viewmodels/auth_viewmodel.dart:9
[auth-profile]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/repositories/auth_repository_impl.dart:20
[auth-apply]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/viewmodels/auth_viewmodel.dart:69
[logout-button]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/widgets/app_scaffold.dart:50
[session-clear]: /home/gabriel/IdeaProjects/atividade_mobile/lib/app/app_widget.dart:31
[error-map]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/firebase_error_message.dart:4
[auth-page]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/auth_page.dart:32
[personal-query]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/firestore_service.dart:128
[user-model]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/models/app_user.dart:1
[person-model]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/models/student.dart:1
[create-person]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/firestore_service.dart:40
[binding-guide]: /home/gabriel/IdeaProjects/atividade_mobile/docs/FIREBASE.md:67
[person-form]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_form_page.dart:76
[person-data]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/firestore_service.dart:135
[courses]: /home/gabriel/IdeaProjects/atividade_mobile/lib/core/constants/course_constants.dart:4
[course-selector]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/widgets/course_selector.dart:16
[rules-person-validation]: /home/gabriel/IdeaProjects/atividade_mobile/firestore.rules:8
[years]: /home/gabriel/IdeaProjects/atividade_mobile/lib/core/constants/app_constants.dart:9
[year-selector]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/widgets/year_selector.dart:13
[person-fields]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_form_page.dart:157
[birth-picker]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_form_page.dart:199
[person-list]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_list_page.dart:26
[person-details]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_detail_page.dart:126
[edit-person]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/firestore_service.dart:58
[remove-service]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/firestore_service.dart:80
[delete-dialog]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/widgets/confirm_delete_dialog.dart:15
[list-delete]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_list_page.dart:192
[detail-delete]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_detail_page.dart:69
[rules-people]: /home/gabriel/IdeaProjects/atividade_mobile/firestore.rules:98
[evaluation-self]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/evaluation_page.dart:64
[save-rating]: /home/gabriel/IdeaProjects/atividade_mobile/lib/data/services/firestore_service.dart:94
[rules-evaluation-validation]: /home/gabriel/IdeaProjects/atividade_mobile/firestore.rules:69
[evaluation-model]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/models/evaluation.dart:3
[criteria]: /home/gabriel/IdeaProjects/atividade_mobile/lib/core/constants/popularity_criteria.dart:16
[evaluation-fields]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/evaluation_page.dart:151
[stars]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/widgets/star_rating.dart:41
[score-model]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/models/popularity_score.dart:21
[evaluation-load]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/evaluation_page.dart:71
[personal-ranking]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/use_cases/ranking_use_cases.dart:19
[global-ranking]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/use_cases/ranking_use_cases.dart:47
[ranking-sort]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/use_cases/ranking_use_cases.dart:92
[ranking-model]: /home/gabriel/IdeaProjects/atividade_mobile/lib/domain/models/ranking_entry.dart:3
[ranking-count]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/widgets/ranking_card.dart:52
[ranking-description]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/ranking_page.dart:75
[google-button]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/auth_page.dart:169
[about]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/about_page.dart:6
[about-project]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/about_page.dart:24
[about-score]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/about_page.dart:30
[about-personal]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/about_page.dart:35
[about-global]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/about_page.dart:40
[about-data]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/about_page.dart:46
[about-theme]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/about_page.dart:61
[scaffold]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/widgets/app_scaffold.dart:95
[self-optional]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_form_page.dart:29
[self-form]: /home/gabriel/IdeaProjects/atividade_mobile/lib/presentation/pages/student_form_page.dart:97
[test-environment]: /home/gabriel/IdeaProjects/atividade_mobile/test/support/test_environment.dart:17
[test-theme-storage]: /home/gabriel/IdeaProjects/atividade_mobile/test/business_rules_test.dart:311
[test-score]: /home/gabriel/IdeaProjects/atividade_mobile/test/business_rules_test.dart:48
[test-unique-rating]: /home/gabriel/IdeaProjects/atividade_mobile/test/business_rules_test.dart:157
[test-rankings]: /home/gabriel/IdeaProjects/atividade_mobile/test/business_rules_test.dart:184
[widget-theme]: /home/gabriel/IdeaProjects/atividade_mobile/test/widget_test.dart:232
[widget-route]: /home/gabriel/IdeaProjects/atividade_mobile/test/widget_test.dart:113
[widget-restore]: /home/gabriel/IdeaProjects/atividade_mobile/test/widget_test.dart:128
[widget-rating-edit]: /home/gabriel/IdeaProjects/atividade_mobile/test/widget_test.dart:196
[rules-test]: /home/gabriel/IdeaProjects/atividade_mobile/firebase-tests/firestore_rules.test.cjs:54
