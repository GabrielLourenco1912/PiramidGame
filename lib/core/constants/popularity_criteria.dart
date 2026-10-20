class PopularityCriterion {
  const PopularityCriterion({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

class PopularityCriteria {
  const PopularityCriteria._();

  static const criteria = <PopularityCriterion>[
    PopularityCriterion(
      id: 'resenha',
      title: 'Resenha',
      description:
          'Mede o quanto o aluno anima a turma, puxa conversa e contribui para deixar o ambiente mais descontraido.',
    ),
    PopularityCriterion(
      id: 'presenca_vip',
      title: 'Presença VIP',
      description:
          'Avalia o quanto o aluno é lembrado, percebido ou reconhecido pelos colegas no dia a dia da turma.',
    ),
    PopularityCriterion(
      id: 'aura',
      title: 'Aura',
      description:
          'Representa a energia geral do aluno: presença, estilo, jeito de ser e impacto que causa no ambiente.',
    ),
    PopularityCriterion(
      id: 'modo_parceiro',
      title: 'Modo Parceiro',
      description:
          'Mede o quanto o aluno ajuda os colegas, colabora nas atividades e demonstra espírito de parceria.',
    ),
    PopularityCriterion(
      id: 'carisma_natural',
      title: 'Carisma Natural',
      description:
          'Avalia a facilidade do aluno para socializar, conversar e criar boas relações com os colegas.',
    ),
    PopularityCriterion(
      id: 'humor_de_milhoes',
      title: 'Humor de Milhões',
      description:
          'Representa o quanto o aluno contribui com bom humor, brincadeiras saudáveis e momentos divertidos.',
    ),
    PopularityCriterion(
      id: 'energia_de_grupo',
      title: 'Energia de Grupo',
      description:
          'Mede a participação do aluno em trabalhos, eventos, jogos, dinâmicas e atividades coletivas da turma.',
    ),
    PopularityCriterion(
      id: 'criatividade_caotica',
      title: 'Criatividade Caótica',
      description:
          'Avalia a capacidade do aluno de ter ideias diferentes, soluções inesperadas e comentários geniais.',
    ),
    PopularityCriterion(
      id: 'modo_atleta',
      title: 'Modo Atleta',
      description:
          'Representa a aptidão esportiva, a disposição física e o espírito competitivo saudável do aluno.',
    ),
    PopularityCriterion(
      id: 'talento_de_palco',
      title: 'Talento de Palco',
      description:
          'Mede a aptidão artística do aluno, como música, canto, instrumentos, dança, ritmo ou presença em apresentações.',
    ),
    PopularityCriterion(
      id: 'drip_escolar',
      title: 'Drip Escolar',
      description:
          'Avalia o estilo pessoal do aluno, considerando roupas, tênis, cabelo, acessórios e presença visual.',
    ),
    PopularityCriterion(
      id: 'coracao_de_dorama',
      title: 'Coração de Dorama',
      description:
          'Representa o carisma afetivo, a gentileza e uma vibe de protagonista romântico, sem expor relacionamentos reais.',
    ),
    PopularityCriterion(
      id: 'queridinho_dos_professores',
      title: 'Queridinho dos Professores',
      description:
          'Mede a boa relação do aluno com os professores, considerando respeito, participação, educação e responsabilidade.',
    ),
    PopularityCriterion(
      id: 'cerebro_turbo',
      title: 'Cérebro Turbo',
      description:
          'Avalia o desempenho nos estudos, a facilidade para aprender, resolver problemas e se destacar academicamente.',
    ),
    PopularityCriterion(
      id: 'caos_controlado',
      title: 'Caos Controlado',
      description:
          'Mede o quanto o aluno é bagunceiro, zoeiro ou imprevisível, mas dentro dos limites do respeito e da convivência saudável.',
    ),
  ];
}
