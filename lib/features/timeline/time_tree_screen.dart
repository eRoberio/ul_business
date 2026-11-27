import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';
import '../../domain/entities/audit_log.dart';
import '../crm/widgets/event_location.dart';
import '../crm/widgets/location_navigation_sheet.dart';

class TimeTreeScreen extends StatefulWidget {
  const TimeTreeScreen({super.key});

  @override
  State<TimeTreeScreen> createState() => _TimeTreeScreenState();
}

class _TimeTreeScreenState extends State<TimeTreeScreen> {
  bool _showAuditLogs = false;
  final ScrollController _interactionsScrollController = ScrollController();
  final ScrollController _auditScrollController = ScrollController();

  @override
  void dispose() {
    _interactionsScrollController.dispose();
    _auditScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Árvore Cronológica de Vendas',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: tokens.textPrimary,
              ),
            ),
            Text(
              _showAuditLogs
                  ? 'Logs Imutáveis de Auditoria (audit_logs)'
                  : 'Histórico de Interações (TimeTree)',
              style: TextStyle(
                fontSize: 12,
                color: tokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Negociações', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Auditoria', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_showAuditLogs},
              onSelectionChanged: (selection) {
                setState(() => _showAuditLogs = selection.first);
              },
            ),
          ),
        ],
      ),
      body: _showAuditLogs
          ? _buildAuditLogsList(context)
          : _buildInteractionsList(context),
    );
  }

  Widget _buildAuditLogsList(BuildContext context) {
    final tokens = context.tokens;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandLoadingView(message: 'Carregando logs de auditoria...');
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: EmptyStateBox(
              icon: Icons.security_outlined,
              title: 'Nenhum evento de auditoria',
              message:
                  'Ações críticas (bloqueios de login, movimentações no CRM, agendamentos e contratos) serão registradas aqui.',
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey('timeline_audit_scroll'),
          controller: _auditScrollController,
          padding: const EdgeInsets.all(20.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final action = AuditActionType.fromCode('${data['action'] ?? ''}');
            final actorName = '${data['actor_name'] ?? 'Sistema'}';
            final targetName = '${data['target_name'] ?? ''}';
            final details = '${data['details'] ?? ''}';
            final ts = data['timestamp'] as Timestamp?;
            final dt = ts?.toDate();
            final dataFormatada = dt != null
                ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                : 'Recente';

            final Color color;
            final IconData icon;
            switch (action) {
              case AuditActionType.loginBlocked:
                color = tokens.danger;
                icon = Icons.gpp_bad_outlined;
              case AuditActionType.contractGenerated:
                color = tokens.success;
                icon = Icons.verified_outlined;
              case AuditActionType.eventScheduled:
                color = tokens.success;
                icon = Icons.event_available_outlined;
              case AuditActionType.cardDeleted:
                color = tokens.danger;
                icon = Icons.delete_outline;
              case AuditActionType.cardMoved:
                color = tokens.warning;
                icon = Icons.swap_horiz_rounded;
              case AuditActionType.cardCreated:
              case AuditActionType.cardUpdated:
                color = tokens.primary;
                icon = Icons.edit_note_rounded;
            }

            return CustomCard(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tokens.badgeBackground(color),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                action.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              dataFormatada,
                              style: TextStyle(
                                fontSize: 11,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (targetName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            targetName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.primary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          details,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Responsável: $actorName',
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInteractionsList(BuildContext context) {
    final tokens = context.tokens;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interacoes')
          .orderBy('data_registro', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandLoadingView(message: 'Carregando histórico...');
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: EmptyStateBox(
              icon: Icons.account_tree_outlined,
              title: 'Nenhum registro na árvore',
              message:
                  'As prospecções e agendamentos aparecerão aqui em ordem cronológica.',
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey('timeline_interactions_scroll'),
          controller: _interactionsScrollController,
          padding: const EdgeInsets.all(20.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final empresa = data['empresa_nome'] ?? 'Empresa Sem Nome';
              final status = data['status'] ?? 'Em Prospecção';
              final agendista = data['agendista'] ?? 'Agendista';
              final notas = data['notas'] ?? '';
              final localizacao = EventLocation.fromMap(data['localizacao']);

              final timestamp = data['data_registro'] as Timestamp?;
              final dataFormatada = timestamp != null
                  ? '${timestamp.toDate().day.toString().padLeft(2, '0')}/${timestamp.toDate().month.toString().padLeft(2, '0')}/${timestamp.toDate().year}'
                  : 'Recente';

              final color = tokens.statusColor(status);
              final IconData icon;
              switch (status) {
                case 'Agendada':
                  icon = Icons.check_circle_outline;
                  break;
                case 'Aguardando':
                  icon = Icons.hourglass_top_rounded;
                  break;
                case 'Recusada':
                  icon = Icons.cancel_outlined;
                  break;
                case 'Acompanhamento':
                  icon = Icons.trending_up_rounded;
                  break;
                case 'Finalizado':
                  icon = Icons.verified_outlined;
                  break;
                default:
                  icon = Icons.search;
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 2,
                            height: 18,
                            color: index == 0
                                ? Colors.transparent
                                : tokens.borderSubtle,
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: tokens.badgeBackground(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(icon, color: color, size: 15),
                          ),
                          Expanded(
                            child: Container(
                              width: 2,
                              color: index == docs.length - 1
                                  ? Colors.transparent
                                  : tokens.borderSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomCard(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    empresa,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tokens.surfaceElevated2,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: tokens.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    dataFormatada,
                                    style: TextStyle(
                                      color: tokens.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatusBadge(label: status, color: color),
                                Text(
                                  'Agendista: $agendista',
                                  style: TextStyle(
                                    color: tokens.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (notas.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                notas,
                                style: TextStyle(
                                  color: tokens.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (localizacao != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: tokens.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      localizacao.displayAddress,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: tokens.primary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LocationActionButtons(
                                location: localizacao,
                                empresaNome: '$empresa',
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
  }
}