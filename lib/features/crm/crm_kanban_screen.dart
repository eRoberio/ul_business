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

  final List<String> _todasColunas = [
    'Em Prospecção',
    'Aguardando',
    'Agendada',
    'Recusada',
  ];

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

                final Map<String, List<Map<String, dynamic>>> colunas = {
                  'Em Prospecção': [],
                  'Aguardando': [],
                  'Agendada': [],
                  'Recusada': [],
                };

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['doc_id'] = doc.id;

                  final empresa = (data['empresa_nome'] ?? '')
                      .toString()
                      .toLowerCase();
                  final agendista = (data['agendista'] ?? '')
                      .toString()
                      .toLowerCase();
                  final status = data['status'] ?? 'Em Prospecção';

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
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => details.data['status'] != title,
      onAcceptWithDetails: (details) async {
        final docId = details.data['doc_id'];
        if (docId != null) {
          if (title == 'Agendada') {
            _abrirInteracao({...details.data, 'status': title});
            return;
          }
          await FirebaseFirestore.instance
              .collection('interacoes')
              .doc(docId)
              .update({'status': title});
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          width: 290,
          margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
          decoration: BoxDecoration(
            color: isHovered
                ? color.withOpacity(0.15)
                : Theme.of(context).colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? color : Colors.white10,
              width: isHovered ? 2.0 : 1.0,
            ),
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
                          'Arraste um cartão aqui',
                          style: TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Draggable<Map<String, dynamic>>(
                            data: item,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: 270,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blueAccent),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  item['empresa_nome'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildCardContent(context, item, title),
                            ),
                            child: _buildCardContent(context, item, title),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirInteracao(Map<String, dynamic> interacao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: InteractionBottomSheet(
          empresaNome: '${interacao['empresa_nome'] ?? 'Cliente'}',
          interacaoInicial: interacao,
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    Map<String, dynamic> item,
    String currentColumnTitle,
  ) {
    final docId = item['doc_id'];
    final valor = item['valor'] ?? '0';
    final timestamp = item['data_evento'] as Timestamp?;
    final dataEventoStr = timestamp != null
        ? '${timestamp.toDate().day}/${timestamp.toDate().month} às ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => _abrirInteracao(item),
        borderRadius: BorderRadius.circular(8),
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
                      item['empresa_nome'] ?? 'Empresa Sem Nome',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opções',
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.white54,
                    ),
                    onSelected: (novoStatus) async {
                      if (docId != null) {
                        if (novoStatus == 'Agendada') {
                          _abrirInteracao({...item, 'status': novoStatus});
                          return;
                        }
                        await FirebaseFirestore.instance
                            .collection('interacoes')
                            .doc(docId)
                            .update({'status': novoStatus});
                      }
                    },
                    itemBuilder: (context) => [
                      ..._todasColunas
                          .where((col) => col != currentColumnTitle)
                          .map((colunaDestino) {
                            return PopupMenuItem<String>(
                              value: colunaDestino,
                              child: Text(
                                'Mover para $colunaDestino',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          })
                          .toList(),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        onTap: () async {
                          if (docId != null) {
                            await FirebaseFirestore.instance
                                .collection('interacoes')
                                .doc(docId)
                                .delete();
                          }
                        },
                        child: const Text(
                          'Excluir',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item['agendista'] ?? 'Agendista',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (dataEventoStr != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.event,
                      size: 12,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$dataEventoStr (${item['duracao_minutos'] ?? 60} min)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (valor != '0' && valor.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'R\$ $valor',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ],
              if ('${item['notas'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${item['notas']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
