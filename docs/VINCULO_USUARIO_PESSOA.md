# Vínculo entre conta e pessoa

Uma conta de login pode representar no máximo uma pessoa, e cada pessoa pode representar no máximo uma conta. O vínculo é opcional: a especificação também permite pessoas sem conta e usuários que cadastram terceiros. `criadoPor` identifica quem cadastrou e pode editar/remover; `usuarioUid` identifica a conta da própria pessoa.

O problema anterior era a criação de documentos com IDs aleatórios sem verificar a repetição de `usuarioUid`. As regras conferiam somente se o UID era o do usuário autenticado. Assim, marcar “Este é meu perfil” em dois cadastros criava dois vínculos para a mesma conta.

## Como a unicidade é garantida

Além de `pessoas/{id}.usuarioUid`, existe `vinculosUsuarios/{uid}` com exatamente um campo: `pessoaId`, uma string com o ID do documento da pessoa. O app lê esse índice e grava ambos os documentos em uma transação. As regras usam `getAfter` para exigir que os dois lados apontem um para o outro e proíbem alterar ou apagar o índice pelo app. Isso também rejeita um lote com duas pessoas para o mesmo UID.

Transações são atômicas e repetem a leitura quando outro cliente altera o documento, conforme a [documentação do Firestore](https://firebase.google.com/docs/firestore/manage-data/transactions). Assim, dois aparelhos não conseguem reservar o mesmo UID para pessoas diferentes. A [validação com `getAfter`](https://firebase.google.com/docs/firestore/security/rules-conditions#access_other_documents) exige a consistência ao confirmar as gravações.

O serviço também consulta `pessoas` pelo UID, sem filtrar `ativo`, para rejeitar cadastros de contas já vinculadas em dados antigos. Essa consulta é uma proteção adicional do app: a garantia no servidor depende de todos os vínculos antigos terem seu índice.

A remoção lógica (`ativo=false`) preserva o vínculo e o histórico. Ela não libera a conta para representar uma segunda pessoa. Correções de identidade ficam a cargo do administrador.

## Zerar os cadastros antigos

Se os dados anteriores puderem ser descartados, apague as coleções `avaliacoes`, `pessoas` e `vinculosUsuarios`, mantendo `usuarios` e as contas no Firebase Authentication. A exclusão dessas três coleções é definitiva e dispensa a migração dos vínculos. Depois publique as novas regras e use o app atualizado para cadastrar os perfis novamente.

Na limpeza autorizada deste projeto, o escopo é exatamente essas três coleções. As contas usadas para login são preservadas.

## Preservar um banco que já possui dados

Se os cadastros forem mantidos, faça esta regularização antes de publicar as novas regras e usar a versão atualizada do app. Durante a regularização, suspenda cadastros de perfis para que clientes antigos não criem novos vínculos sem índice.

1. Confira as pessoas com `usuarioUid` preenchido, incluindo as inativas. Para cada UID, deve existir no máximo um documento.
2. Se houver duplicados, confirme qual cadastro representa a pessoa. No console administrativo, mantenha o UID apenas nesse documento. Nos cadastros redundantes, defina `ativo=false` e `usuarioUid=null`. Preserve seus IDs e avaliações; não há transferência automática de votos, pois o mesmo avaliador pode ter votado nos dois perfis.
3. Para cada pessoa que continua com UID preenchido, crie `vinculosUsuarios/{uid}` e adicione somente o campo string `pessoaId` com o ID exato dela. Inclua perfis inativos. Se o índice já existir com o mesmo ID, mantenha-o; se apontar para outro, resolva a inconsistência antes de prosseguir.
4. Confira a correspondência nos dois sentidos: todo UID em `pessoas` tem seu índice, e todo índice aponta para uma pessoa com aquele UID. Não crie índice para `usuarioUid=null`.
5. Publique `firestore.rules` e distribua o app atualizado. Versões antigas que tentem criar um perfil vinculado sem o índice serão recusadas.

Publicar as regras sem preparar os dados antigos bloqueia a edição de pessoas vinculadas sem índice e não reserva seus UIDs contra requisições diretas de outros clientes. Apenas atualizar o app não substitui esta regularização. As regras e o cliente não desfazem duplicidades já existentes.

## Associar uma pessoa existente a uma conta

Confirme a identidade e verifique se o UID já aparece em outra pessoa ou em `vinculosUsuarios`. Se já estiver reservado para outra pessoa, resolva essa associação primeiro. Para um UID livre, a operação administrativa deve preencher `pessoas/{id}.usuarioUid` e criar `vinculosUsuarios/{uid}` com `pessoaId={id}`. Prefira uma gravação administrativa em lote; se usar o console para editar os dois documentos separadamente, mantenha os cadastros suspensos até concluir.

O console e SDKs administrativos ignoram as regras de segurança, portanto o administrador deve manter essa correspondência também nas correções posteriores.

## Validação local

`flutter test` verifica o retorno de erro no cadastro repetido, contas diferentes, cadastros de terceiros, remoção lógica e vínculos antigos sem índice. `npm --prefix firebase-tests test` usa o emulador oficial para verificar também requisições diretas, isolamento do índice, lotes inconsistentes, cadastros simultâneos e preservação das regras de avaliação.
