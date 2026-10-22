import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeTreeScreen extends StatelessWidget {
  const TimeTreeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Árvore Cronológica de Vendas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Histórico de Interações (TimeTree)', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('interacoes').orderBy('data_registro', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum nó registrado na árvore ainda.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final empresa = data['empresa_nome'] ?? 'Empresa Sem Nome';
              final status = data['status'] ?? 'Em Prospecção';
              final agendista = data['agendista'] ?? 'Agendista';
              final notas = data['notas'] ?? '';
              
              final timestamp = data['data_registro'] as Timestamp?;
              final dataFormatada = timestamp != null
                  ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                  : 'Recente';

              IconData icon;
              Color color;

              switch (status) {
                case 'Agendada':
                  icon = Icons.check_circle;
                  color = Colors.greenAccent;
                  break;
                case 'Aguardando':
                  icon = Icons.hourglass_top;
                  color = Colors.amberAccent;
                  break;
                case 'Recusada':
                  icon = Icons.cancel;
                  color = Colors.redAccent;
                  break;
                default:
                  icon = Icons.search;
                  color = Colors.blueGrey;
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(width: 2, height: 16, color: index == 0 ? Colors.transparent : Colors.white24),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color)),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        Expanded(child: Container(width: 2, color: index == docs.length - 1 ? Colors.transparent : Colors.white24)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Card(
                          color: Theme.of(context).colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(empresa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(dataFormatada, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Agendista: $agendista', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                                if (notas.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(notas, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}