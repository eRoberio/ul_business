import 'package:flutter/material.dart';

class TimeTreeScreen extends StatelessWidget {
  const TimeTreeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TechCorp Solutions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Árvore Evolutiva de Treinamento',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          _buildNode(
            context,
            isFirst: true,
            title: 'O Profissional da Atualidade',
            date: '15 de Outubro de 2025',
            status: 'Concluído',
            impact: 'Clima Org. +15%',
            icon: Icons.check_circle,
            color: Colors.greenAccent,
          ),
          _buildNode(
            context,
            title: 'Liderança e Inteligência Emocional',
            date: '10 de Março de 2026',
            status: 'Concluído',
            impact: 'Engajamento Alto',
            icon: Icons.check_circle,
            color: Colors.greenAccent,
          ),
          _buildNode(
            context,
            title: 'Mapeamento Comportamental',
            date: 'Agendado: 20 de Nov de 2026',
            status: 'Confirmado',
            icon: Icons.event_available,
            color: Colors.amberAccent,
          ),
          _buildNode(
            context,
            isLast: true,
            title: 'Inovação e Produtividade',
            date: 'Sugestão de Próximo Passo',
            status: 'Prospecção',
            icon: Icons.lightbulb_outline,
            color: Theme.of(context).colorScheme.primary,
            isDashed: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_chart, color: Colors.white),
        label: const Text('Nova Proposta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Construtor do Nó (Folha da Árvore)
  Widget _buildNode(
    BuildContext context, {
    required String title,
    required String date,
    required String status,
    required IconData icon,
    required Color color,
    String? impact,
    bool isFirst = false,
    bool isLast = false,
    bool isDashed = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna da Linha e Ícone
          Column(
            children: [
              // Linha superior
              Container(
                width: 2,
                height: 20,
                color: isFirst ? Colors.transparent : Colors.white24,
              ),
              // Ícone central
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              // Linha inferior
              Expanded(
                child: isDashed
                    ? _DashedLine(color: color.withOpacity(0.5))
                    : Container(
                        width: 2,
                        color: isLast ? Colors.transparent : Colors.white24,
                      ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Coluna do Cartão de Conteúdo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (impact != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              impact,
                              style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para desenhar a linha tracejada (Sugerindo o futuro)
class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxHeight = constraints.constrainHeight();
        const dashHeight = 4.0;
        const dashSpace = 4.0;
        final dashCount = (boxHeight / (dashHeight + dashSpace)).floor();
        return Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: 2,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}