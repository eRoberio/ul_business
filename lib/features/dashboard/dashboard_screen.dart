import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('interacoes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Processamento e cálculo de métricas reais
          int palestrasFechadas = 0;
          int totalInteracoes = docs.length;
          double faturamentoTotal = 0.0;
          List<Map<String, dynamic>> aprovacoesPendentes = [];
          Map<String, int> contagemTemas = {};

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

              // Contagem para ranking de temas
              contagemTemas[tema] = (contagemTemas[tema] ?? 0) + 1;
            } else if (status == 'Aguardando') {
              aprovacoesPendentes.add(data);
            }
          }

          // Cálculo da taxa de conversão real
          int taxaConversao = totalInteracoes > 0
              ? ((palestrasFechadas / totalInteracoes) * 100).round()
              : 0;

          // Ordenação dos temas mais vendidos
          final temasOrdenados = contagemTemas.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Torre de Controle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                Text(
                  'Visão Geral do Desempenho Comercial',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
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
                        _buildKpiCard(
                          context,
                          width: isWide
                              ? (constraints.maxWidth - 32) / 3
                              : constraints.maxWidth,
                          title: 'Faturamento Estimado',
                          value: 'R\$ ${faturamentoTotal.toStringAsFixed(0)}',
                          trend: palestrasFechadas > 0
                              ? '$palestrasFechadas contratos fechados'
                              : 'Nenhum contrato fechado',
                          icon: Icons.attach_money,
                          color: Colors.greenAccent,
                        ),
                        _buildKpiCard(
                          context,
                          width: isWide
                              ? (constraints.maxWidth - 32) / 3
                              : constraints.maxWidth,
                          title: 'Palestras Confirmadas',
                          value: palestrasFechadas.toString().padLeft(2, '0'),
                          trend: 'Status: Agendada',
                          icon: Icons.event_available,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _buildKpiCard(
                          context,
                          width: isWide
                              ? (constraints.maxWidth - 32) / 3
                              : constraints.maxWidth,
                          title: 'Taxa de Conversão',
                          value: '$taxaConversao%',
                          trend: '$totalInteracoes abordagens registradas',
                          icon: Icons.pie_chart_outline,
                          color: Colors.amberAccent,
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
                          child: _buildSectionContainer(
                            context,
                            title: 'Temas de Maior Tração',
                            child: temasOrdenados.isEmpty
                                ? _buildEmptyState(
                                    icon: Icons.bar_chart_rounded,
                                    message: 'Nenhum tema com agendamento confirmado ainda.',
                                  )
                                : Column(
                                    children: temasOrdenados.take(4).map((
                                      entry,
                                    ) {
                                      final maxVal = temasOrdenados.first.value;
                                      final percentage = entry.value / maxVal;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16.0,
                                        ),
                                        child: _buildBarChartRow(
                                          context,
                                          label: entry.key,
                                          percentage: percentage,
                                          value:
                                              '${entry.value} ${entry.value == 1 ? 'agenda' : 'agendas'}',
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      );
                                    }).toList(),
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
                          child: _buildSectionContainer(
                            context,
                            title: 'Aprovações Pendentes',
                            child: aprovacoesPendentes.isEmpty
                                ? _buildEmptyState(
                                    icon: Icons.check_circle_outline,
                                    message: 'Não há propostas aguardando aprovação no momento.',
                                  )
                                : Column(
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

  Widget _buildKpiCard(
    BuildContext context, {
    required double width,
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trend,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      width: double.infinity,
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartRow(
    BuildContext context, {
    required String label,
    required double percentage,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage.clamp(0.05, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApprovalItem(
    BuildContext context, {
    required String agendista,
    required String empresa,
    required String notas,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Por: $agendista',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (notas.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notas,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.hourglass_top_rounded,
            color: Colors.amberAccent,
            size: 20,
          ),
        ],
      ),
    );
  }
}
