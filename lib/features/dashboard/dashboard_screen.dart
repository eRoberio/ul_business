import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('interacoes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const BrandLoadingView(message: 'Carregando indicadores...');
          }

          final docs = snapshot.data?.docs ?? [];

          int palestrasFechadas = 0;
          int totalInteracoes = docs.length;
          double faturamentoTotal = 0.0;
          final List<Map<String, dynamic>> aprovacoesPendentes = [];
          final Map<String, int> contagemTemas = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            final tema = data['tema'] ?? 'Treinamento Corporativo';
            final valorStr =
                data['valor']
                    ?.toString()
                    .replaceAll('R\$', '')
                    .replaceAll('.', '')
                    .replaceAll(',', '.')
                    .trim() ??
                '0';
            final valor = double.tryParse(valorStr) ?? 0.0;

            if (status == 'Agendada') {
              palestrasFechadas++;
              faturamentoTotal += valor;
              contagemTemas[tema] = (contagemTemas[tema] ?? 0) + 1;
            } else if (status == 'Aguardando') {
              aprovacoesPendentes.add(data);
            }
          }

          final taxaConversao = totalInteracoes > 0
              ? ((palestrasFechadas / totalInteracoes) * 100).round()
              : 0;

          final temasOrdenados = contagemTemas.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Torre de Controle',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: tokens.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Visão Geral do Desempenho Comercial',
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Cards de KPIs com dados reais
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    return Wrap(
                      spacing: 16.0,
                      runSpacing: 16.0,
                      children: [
                        KpiCard(
                          width: isWide
                              ? (constraints.maxWidth - 32) / 3
                              : constraints.maxWidth,
                          title: 'Faturamento Estimado',
                          value: formatBrlCurrency(faturamentoTotal),
                          trend: palestrasFechadas > 0
                              ? '+$palestrasFechadas contratos fechados'
                              : 'Nenhum contrato fechado',
                          icon: Icons.attach_money,
                          color: tokens.success,
                        ),
                        KpiCard(
                          width: isWide
                              ? (constraints.maxWidth - 32) / 3
                              : constraints.maxWidth,
                          title: 'Palestras Confirmadas',
                          value: palestrasFechadas.toString().padLeft(2, '0'),
                          trend: 'Status: Agendada',
                          icon: Icons.event_available,
                          color: tokens.primary,
                        ),
                        KpiCard(
                          width: isWide
                              ? (constraints.maxWidth - 32) / 3
                              : constraints.maxWidth,
                          title: 'Taxa de Conversão',
                          value: '$taxaConversao%',
                          trend: '$totalInteracoes abordagens registradas',
                          icon: Icons.pie_chart_outline,
                          color: tokens.warning,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Seções de Temas e Aprovações
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    return Flex(
                      direction: isDesktop ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Temas de Maior Tração
                        Expanded(
                          flex: isDesktop ? 2 : 0,
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Temas de Maior Tração',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (temasOrdenados.isEmpty)
                                  const EmptyStateBox(
                                    icon: Icons.bar_chart_rounded,
                                    message:
                                        'Nenhum tema com agendamento confirmado ainda.',
                                  )
                                else
                                  Column(
                                    children: temasOrdenados.take(4).map((
                                      entry,
                                    ) {
                                      final totalAgendamentos =
                                          palestrasFechadas > 0
                                          ? palestrasFechadas
                                          : 1;
                                      final maxVal = temasOrdenados.first.value;
                                      final barFraction = entry.value / maxVal;
                                      final sharePercent =
                                          ((entry.value / totalAgendamentos) *
                                                  100)
                                              .round();
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16.0,
                                        ),
                                        child: _buildBarChartRow(
                                          context,
                                          label: entry.key,
                                          barFraction: barFraction,
                                          sharePercent: sharePercent,
                                          value:
                                              '${entry.value} ${entry.value == 1 ? 'agenda' : 'agendas'}',
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        if (isDesktop)
                          const SizedBox(width: 16)
                        else
                          const SizedBox(height: 16),

                        // Aprovações Pendentes
                        Expanded(
                          flex: isDesktop ? 1 : 0,
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aprovações Pendentes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (aprovacoesPendentes.isEmpty)
                                  const EmptyStateBox(
                                    icon: Icons.check_circle_outline_rounded,
                                    title: 'Tudo em dia',
                                    message:
                                        'Não há propostas aguardando aprovação no momento.',
                                  )
                                else
                                  Column(
                                    children: aprovacoesPendentes.map((item) {
                                      return _buildApprovalItem(
                                        context,
                                        agendista:
                                            item['agendista'] ?? 'Agendista',
                                        empresa:
                                            item['empresa_nome'] ?? 'Empresa',
                                        notas: item['notas'] ?? '',
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChartRow(
    BuildContext context, {
    required String label,
    required double barFraction,
    required int sharePercent,
    required String value,
  }) {
    final tokens = context.tokens;

    return Tooltip(
      message: '$label: $value ($sharePercent% das palestras confirmadas)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value • $sharePercent%',
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: tokens.borderSubtle, width: 0.5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: barFraction.clamp(0.05, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tokens.primary,
                        tokens.followUp,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(
    BuildContext context, {
    required String agendista,
    required String empresa,
    required String notas,
  }) {
    final tokens = context.tokens;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empresa,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: tokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Por: $agendista',
                  style: TextStyle(
                    color: tokens.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (notas.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notas,
                    style: TextStyle(color: tokens.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tokens.badgeBackground(tokens.warning),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              color: tokens.warning,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
