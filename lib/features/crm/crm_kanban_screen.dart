import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/interaction_bottom_sheet.dart';

class CrmKanbanScreen extends StatefulWidget {
  const CrmKanbanScreen({Key? key}) : super(key: key);

  @override
  State<CrmKanbanScreen> createState() => _CrmKanbanScreenState();
}

class _CrmKanbanScreenState extends State<CrmKanbanScreen> {
  String _filtroTexto = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de Pesquisa Superior
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _filtroTexto = value.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Filtrar por empresa ou agendista...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _filtroTexto.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filtroTexto = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Kanban Reativo com Filtro
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('interacoes')
                  .orderBy('data_registro', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Agrupamento com filtro dinâmico
                final Map<String, List<Map<String, dynamic>>> colunas = {
                  'Em Prospecção': [],
                  'Aguardando': [],
                  'Agendada': [],
                  'Recusada': [],
                };

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final empresa = (data['empresa_nome'] ?? '')
                      .toString()
                      .toLowerCase();
                  final agendista = (data['agendista'] ?? '')
                      .toString()
                      .toLowerCase();
                  final status = data['status'] ?? 'Em Prospecção';

                  // Aplica o filtro de texto
                  final bateuComFiltro =
                      _filtroTexto.isEmpty ||
                      empresa.contains(_filtroTexto) ||
                      agendista.contains(_filtroTexto);

                  if (bateuComFiltro && colunas.containsKey(status)) {
                    colunas[status]!.add(data);
                  }
                }

                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildKanbanColumn(
                      context,
                      title: 'Em Prospecção',
                      color: Colors.blueGrey,
                      items: colunas['Em Prospecção']!,
                    ),
                    _buildKanbanColumn(
                      context,
                      title: 'Aguardando',
                      color: Colors.amberAccent,
                      items: colunas['Aguardando']!,
                    ),
                    _buildKanbanColumn(
                      context,
                      title: 'Agendada',
                      color: Colors.greenAccent,
                      items: colunas['Agendada']!,
                    ),
                    _buildKanbanColumn(
                      context,
                      title: 'Recusada',
                      color: Colors.redAccent,
                      items: colunas['Recusada']!,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const InteractionBottomSheet(
                empresaNome: 'Nova Prospecção',
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context, {
    required String title,
    required Color color,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    items.length.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum resultado',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['empresa_nome'] ?? 'Empresa Sem Nome',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Agendista: ${item['agendista'] ?? 'Não informado'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                              if (item['notas'] != null &&
                                  (item['notas'] as String).isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item['notas'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
