import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InteractionBottomSheet extends StatefulWidget {
  final String empresaNome;

  const InteractionBottomSheet({Key? key, required this.empresaNome})
    : super(key: key);

  @override
  State<InteractionBottomSheet> createState() => _InteractionBottomSheetState();
}

class _InteractionBottomSheetState extends State<InteractionBottomSheet> {
  String _statusSelecionado = 'Aguardando';

  final List<Map<String, dynamic>> _statusOptions = [
    {'label': 'Em Prospecção', 'icon': Icons.search, 'color': Colors.blueGrey},
    {
      'label': 'Aguardando',
      'icon': Icons.hourglass_empty,
      'color': Colors.amberAccent,
    },
    {
      'label': 'Agendada',
      'icon': Icons.check_circle,
      'color': Colors.greenAccent,
    },
    {'label': 'Recusada', 'icon': Icons.cancel, 'color': Colors.redAccent},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apontamento: ${widget.empresaNome}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Qual é o status atual da negociação após o contato?',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Grade de Seleção de Status
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _statusOptions.length,
            itemBuilder: (context, index) {
              final option = _statusOptions[index];
              final isSelected = _statusSelecionado == option['label'];

              return GestureDetector(
                onTap: () =>
                    setState(() => _statusSelecionado = option['label']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? option['color'].withOpacity(0.15)
                        : Colors.white.withOpacity(0.02),
                    border: Border.all(
                      color: isSelected ? option['color'] : Colors.white10,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        option['icon'],
                        size: 18,
                        color: isSelected ? option['color'] : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option['label'],
                        style: TextStyle(
                          color: isSelected ? option['color'] : Colors.white54,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Campo de Anotações Críticas (Ex: "Falar com o Marcos da diretoria amanhã")
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Anotações da visita (Ex: Objeções, próximos passos...)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withOpacity(0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botão de Salvar que alimenta o Firebase e o Kanban
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // 1. Instância do Firestore
                final db = FirebaseFirestore.instance;

                // 2. Prepara os dados do apontamento (Micro-nó da Árvore)
                final apontamento = {
                  'empresa_nome': widget.empresaNome,
                  'status': _statusSelecionado,
                  'data_registro': FieldValue.serverTimestamp(), // Pega a hora exata do servidor
                  'agendista':
                      'Eliton', // Futuramente pegaremos o usuário logado
                  'notas': 'Visita realizada com sucesso.', // Aqui você conectaria o Controller do TextField
                };

                try {
                  // 3. Salva na coleção "interacoes" no Firebase
                  await db.collection('interacoes').add(apontamento);

                  // 4. Fecha a gaveta após o sucesso
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Apontamento registrado na Árvore!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Tratamento de erro nível hard
                  print('Erro ao salvar: $e');
                }
              },
              child: const Text(
                'Registrar na Árvore',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
