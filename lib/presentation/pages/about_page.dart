import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/ifpr_mark.dart';
import '../widgets/responsive_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => ResponsivePage(
    maxWidth: 760,
    child: ListView(
      padding: ResponsivePage.padding(context),
      children: [
        const Center(child: IfprMark(size: 64)),
        const SizedBox(height: 20),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(AppConstants.campusName, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const _Section(
          'O projeto',
          'Um aplicativo didático em Flutter para registrar a convivência, a resenha '
              'e os destaques do IFPR – Campus Paranaguá. Pessoas podem receber avaliações '
              'mesmo sem possuir uma conta.',
        ),
        const _Section(
          'Como funciona o Nível Lenda',
          'São 15 critérios de convivência, destaque e participação. Cada critério '
              'recebe de 1 a 5 estrelas. A soma forma o Nível Lenda: de 15 a 75 pontos.',
        ),
        const _Section(
          'Ranking pessoal',
          'Considera exclusivamente as avaliações que você fez. Cada usuário possui '
              'uma avaliação por pessoa e pode alterá-la depois.',
        ),
        const _Section(
          'Ranking global',
          'Considera as avaliações de todos os usuários. A pontuação é a média dos '
              'totais recebidos pela pessoa, com a quantidade de avaliações ao lado. '
              'Os rankings exibem primeiro a maior pontuação; empates seguem a ordem alfabética.',
        ),
        const _Section(
          'Conta e dados',
          'Firebase Authentication cuida do login com e-mail e senha ou Google, '
              'mantém a sessão e permite sair da conta. O Firestore armazena usuários, '
              'pessoas e avaliações, permitindo acessar seus dados em outro dispositivo. '
              'Atualize a listagem ou o ranking para buscar as informações mais recentes.',
        ),
        const _Section(
          'Cadastro e autoavaliação',
          'Ao cadastrar seu próprio perfil, marque “Este é meu perfil”. A pessoa será '
              'vinculada à sua conta e a autoavaliação será bloqueada. Um perfil já existente '
              'pode ser vinculado pelo responsável pelo projeto. '
              'Cada conta pode ter apenas um perfil vinculado, inclusive após sua remoção. '
              'Somente quem cadastrou uma pessoa pode editar ou remover seu perfil. '
              'A remoção oculta o perfil dos rankings e preserva o histórico das avaliações.',
        ),
        const _Section(
          'Claro ou escuro',
          'Troque o tema a qualquer momento no botão da barra superior. '
              'Essa preferência fica salva neste aparelho com SharedPreferences.',
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.body);
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body),
      ],
    ),
  );
}
