import 'package:flutter/material.dart';

class CrmKanbanScreen extends StatelessWidget {
  const CrmKanbanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pipeline de Vendas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Workspace do Agendista',
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
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      // ListView horizontal para as colunas do Kanban
      body: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildKanbanColumn(
            context,
            title: 'Prospecção',
            count: 2,
            color: Colors.blueGrey,
            cards: [
              _buildDealCard(
                context,
                empresa: 'TechCorp Indústria',
                tema: 'Mapeamento Comportamental',
                valor: 'R\$ 8.500',
                data: 'A definir',
                urgencia: Colors.orangeAccent,
              ),
              _buildDealCard(
                context,
                empresa: 'Logística Alfa',
                tema: 'Gestão de Tempo',
                valor: 'R\$ 5.000',
                data: 'A definir',
                urgencia: Colors.blueGrey,
              ),
            ],
          ),
          _buildKanbanColumn(
            context,
            title: 'Proposta Enviada',
            count: 1,
            color: Colors.amber,
            cards: [
              _buildDealCard(
                context,
                empresa: 'Instituto Vida & Consultores Associados',
                tema: 'O Profissional da Atualidade',
                valor: 'R\$ 12.000',
                data: '12 de Nov',
                urgencia: Colors.redAccent, // Alta prioridade de fechamento
              ),
            ],
          ),
          _buildKanbanColumn(
            context,
            title: 'Contrato Fechado',
            count: 1,
            color: Colors.green,
            cards: [
              _buildDealCard(
                context,
                empresa: 'Grupo Varejo Sul',
                tema: 'Liderança de Alta Performance',
                valor: 'R\$ 15.000',
                data: '20 de Out',
                urgencia: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Construtor da Coluna do Kanban
  Widget _buildKanbanColumn(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required List<Widget> cards,
  }) {
    return Container(
      width: 300, // Largura fixa para cada coluna no mobile/web
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da Coluna
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Lista de Cartões (Negócios)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: cards,
            ),
          ),
        ],
      ),
    );
  }

  // Construtor do Cartão de Negociação (Deal)
  Widget _buildDealCard(
    BuildContext context, {
    required String empresa,
    required String tema,
    required String valor,
    required String data,
    required Color urgencia,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    empresa,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.circle, color: urgencia, size: 10),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tema: $tema',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    valor,
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).colorScheme.primary
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      data,
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}