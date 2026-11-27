import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ul_business/features/crm/contract_screen.dart';

import '../../core/feedback/feedback_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';
import '../../data/providers/repository_providers.dart';
import 'widgets/event_location.dart';
import 'widgets/interaction_bottom_sheet.dart';
import 'widgets/location_navigation_sheet.dart';

class CrmKanbanScreen extends ConsumerStatefulWidget {
  const CrmKanbanScreen({super.key});

  @override
  ConsumerState<CrmKanbanScreen> createState() => _CrmKanbanScreenState();
}

class _CrmKanbanScreenState extends ConsumerState<CrmKanbanScreen> {
  String _filtroTexto = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  final List<String> _todasColunas = const [
    'Em Prospecção',
    'Aguardando',
    'Agendada',
    'Recusada',
    'Acompanhamento',
    'Finalizado',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRM',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: tokens.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _filtroTexto = value.toLowerCase().trim()),
                  decoration: InputDecoration(
                    hintText: 'Filtrar por empresa ou agendista...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _filtroTexto.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filtroTexto = '');
                            },
                          )
                        : null,
                  ),
                ),
              ],
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
                  return const BrandLoadingView(message: 'Carregando funil CRM...');
                }

                final docs = snapshot.data?.docs ?? [];

                final Map<String, List<Map<String, dynamic>>> colunas = {
                  for (final col in _todasColunas) col: [],
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

                return Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    key: const PageStorageKey('crm_kanban_horizontal'),
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _todasColunas.length,
                    itemBuilder: (context, index) {
                      final title = _todasColunas[index];
                      return KanbanColumn(
                        title: title,
                        color: tokens.statusColor(title),
                        items: colunas[title]!,
                        todasColunas: _todasColunas,
                        onOpenInteracao: _abrirInteracao,
                        onMoveStatus: _moverStatus,
                        onRemoveTag: _mostrarDialogoRemoverTag,
                        onDeleteCard: _excluirCard,
                      );
                    },
                  ),
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
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            constraints: const BoxConstraints(maxWidth: 640),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: const CommercialAppointmentModal(
                empresaNome: 'Nova Prospecção',
              ),
            ),
          );
        },
        backgroundColor: tokens.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _moverStatus(
    Map<String, dynamic> item,
    String novoStatus,
  ) async {
    final docId = item['doc_id'];
    if (docId == null) return;
    if (novoStatus == 'Agendada') {
      _abrirInteracao({...item, 'status': novoStatus});
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Agendista';

    try {
      await ref.read(crmRepositoryProvider).moveStatus(
        item: item,
        newStatus: novoStatus,
        newStatusFullName: _getNomeCompletoStatus(novoStatus),
        actorUid: user?.uid ?? '',
        actorName: actorName,
      );
      ref.read(feedbackProvider.notifier).showSuccess(
        'Card movido para "$novoStatus".',
      );
    } catch (e) {
      ref.read(feedbackProvider.notifier).showError(
        'Não foi possível mover o card: $e',
      );
    }
  }

  Future<void> _excluirCard(Map<String, dynamic> item) async {
    final docId = item['doc_id'] as String?;
    if (docId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    final actorName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Agendista';
    try {
      await ref.read(crmRepositoryProvider).deleteInteraction(
        docId: docId,
        empresaNome: '${item['empresa_nome'] ?? 'Cliente'}',
        actorUid: user?.uid ?? '',
        actorName: actorName,
      );
      ref.read(feedbackProvider.notifier).showSuccess('Card removido do CRM.');
    } catch (e) {
      ref.read(feedbackProvider.notifier).showError(
        'Sem permissão ou erro ao excluir: $e',
      );
    }
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
        child: CommercialAppointmentModal(
          empresaNome: '${interacao['empresa_nome'] ?? 'Cliente'}',
          interacaoInicial: interacao,
        ),
      ),
    );
  }

  String _getNomeCompletoStatus(String statusAbreviado) {
    switch (statusAbreviado) {
      case 'Acompanhamento':
        return 'Palestra Realizada & Acompanhamento';
      default:
        return statusAbreviado;
    }
  }

  void _mostrarDialogoRemoverTag(
    BuildContext context,
    Map<String, dynamic> item,
    dynamic docId,
    String tagParaRemover,
  ) {
    final tokens = context.tokens;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Tag'),
        content: Text(
          'Tem certeza que deseja remover a tag "${tagParaRemover.split('_').first}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (docId != null) {
                final tags = List<String>.from(item['tags'] ?? []);
                tags.removeWhere((tag) => tag == tagParaRemover);

                await FirebaseFirestore.instance
                    .collection('interacoes')
                    .doc(docId)
                    .update({'tags': tags});
              }
            },
            child: Text('Remover', style: TextStyle(color: tokens.danger)),
          ),
        ],
      ),
    );
  }
}

class KanbanColumn extends StatefulWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;
  final List<String> todasColunas;
  final void Function(Map<String, dynamic> interacao) onOpenInteracao;
  final Future<void> Function(Map<String, dynamic> item, String novoStatus)
  onMoveStatus;
  final void Function(
    BuildContext context,
    Map<String, dynamic> item,
    dynamic docId,
    String tagParaRemover,
  )
  onRemoveTag;
  final Future<void> Function(Map<String, dynamic> item) onDeleteCard;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.color,
    required this.items,
    required this.todasColunas,
    required this.onOpenInteracao,
    required this.onMoveStatus,
    required this.onRemoveTag,
    required this.onDeleteCard,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final columnBg = tokens.isDark
        ? tokens.surfaceElevated1
        : tokens.surfaceElevated2;

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) =>
          details.data['status'] != widget.title,
      onAcceptWithDetails: (details) =>
          widget.onMoveStatus(details.data, widget.title),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
          decoration: BoxDecoration(
            color: isHovered ? widget.color.withValues(alpha: 0.08) : columnBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? widget.color : tokens.borderSubtle,
              width: isHovered ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.isDark
                            ? tokens.surfaceElevated2
                            : tokens.surfaceElevated1,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.items.length.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.borderSubtle),

              Expanded(
                child: widget.items.isEmpty
                    ? Center(
                        child: Text(
                          'Arraste um cartão aqui',
                          style: TextStyle(
                            color: tokens.textSecondary.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.builder(
                        key: PageStorageKey('kanban_col_${widget.title}'),
                        controller: _verticalController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(10.0),
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          return Draggable<Map<String, dynamic>>(
                            data: item,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: 280,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: tokens.surfaceElevated1,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: tokens.primary,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  item['empresa_nome'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: DealCard(
                                item: item,
                                currentColumnTitle: widget.title,
                                todasColunas: widget.todasColunas,
                                onTap: () => widget.onOpenInteracao(item),
                                onMoveStatus: (novo) =>
                                    widget.onMoveStatus(item, novo),
                                onDeleteCard: () => widget.onDeleteCard(item),
                                onRemoveTag: (tag) => widget.onRemoveTag(
                                  context,
                                  item,
                                  item['doc_id'],
                                  tag,
                                ),
                              ),
                            ),
                            child: DealCard(
                              item: item,
                              currentColumnTitle: widget.title,
                              todasColunas: widget.todasColunas,
                              onTap: () => widget.onOpenInteracao(item),
                              onMoveStatus: (novo) =>
                                  widget.onMoveStatus(item, novo),
                              onDeleteCard: () => widget.onDeleteCard(item),
                              onRemoveTag: (tag) => widget.onRemoveTag(
                                context,
                                item,
                                item['doc_id'],
                                tag,
                              ),
                            ),
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
}

class DealCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String currentColumnTitle;
  final List<String> todasColunas;
  final VoidCallback onTap;
  final ValueChanged<String> onMoveStatus;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onDeleteCard;

  const DealCard({
    super.key,
    required this.item,
    required this.currentColumnTitle,
    required this.todasColunas,
    required this.onTap,
    required this.onMoveStatus,
    required this.onRemoveTag,
    required this.onDeleteCard,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final docId = item['doc_id'];
    final rawValor = '${item['valor'] ?? '0'}'
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    final valorNum = double.tryParse(rawValor) ?? 0.0;
    final localizacao = EventLocation.fromMap(item['localizacao']);
    final timestamp = item['data_evento'] as Timestamp?;
    final dataEventoStr = timestamp != null
        ? '${timestamp.toDate().day.toString().padLeft(2, '0')}/${timestamp.toDate().month.toString().padLeft(2, '0')} • ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')} (${item['duracao_minutos'] ?? 60}m)'
        : null;

    // Agrupa tags por status para evitar poluição visual com tags duplicadas
    final rawTags = (item['tags'] as List<dynamic>?) ?? const [];
    final Map<String, ({String rawTag, int count})> groupedTags = {};
    for (final tag in rawTags) {
      final tagStr = tag.toString();
      final statusName = tagStr.split('_').first;
      final existing = groupedTags[statusName];
      groupedTags[statusName] = (
        rawTag: tagStr,
        count: (existing?.count ?? 0) + 1,
      );
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(14.0),
      backgroundColor: tokens.isDark
          ? tokens.surfaceElevated2
          : tokens.surfaceElevated1,
      borderRadius: 10,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['empresa_nome'] ?? 'Empresa Sem Nome',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: tokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: tokens.textSecondary,
                ),
                onSelected: onMoveStatus,
                itemBuilder: (context) => [
                  ...todasColunas
                      .where((col) => col != currentColumnTitle)
                      .map((colunaDestino) {
                        return PopupMenuItem<String>(
                          value: colunaDestino,
                          child: Text(
                            'Mover para $colunaDestino',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    onTap: () {
                      if (docId != null) {
                        onDeleteCard();
                      }
                    },
                    child: Text(
                      'Excluir',
                      style: TextStyle(color: tokens.danger, fontSize: 12),
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
              color: tokens.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (dataEventoStr != null) ...[
            const SizedBox(height: 8),
            StatusBadge(
              label: dataEventoStr,
              color: tokens.success,
              icon: Icons.event_outlined,
            ),
          ],
          if (valorNum > 0) ...[
            const SizedBox(height: 8),
            Text(
              formatBrlCurrency(valorNum),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ],
          if ('${item['notas'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${item['notas']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
          ],
          if (localizacao != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 13, color: tokens.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    localizacao.displayAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: tokens.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LocationActionButtons(
              location: localizacao,
              empresaNome: '${item['empresa_nome'] ?? 'Empresa'}',
              compact: true,
            ),
          ],
          if (groupedTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: groupedTags.entries.take(3).map((entry) {
                final label = entry.value.count > 1
                    ? '${entry.key} ×${entry.value.count}'
                    : entry.key;
                return StatusBadge(
                  label: label,
                  color: tokens.statusColor(entry.key),
                  onLongPress: () => onRemoveTag(entry.value.rawTag),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: tokens.borderSubtle),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContractScreen(interacao: item),
                  ),
                );
              },
              icon: Icon(Icons.draw_outlined, size: 15, color: tokens.primary),
              label: Text(
                'Gerar Contrato',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tokens.borderSubtle),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
