import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Torre de Controle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Visão Global do Orador',
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
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Roberio+Moreira&background=2563EB&color=fff'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo Financeiro (KPIs)
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                _buildKpiCard(
                  context,
                  title: 'Faturamento Mensal',
                  value: 'R\$ 35.500',
                  trend: '+12% vs mês anterior',
                  icon: Icons.attach_money,
                  color: Colors.greenAccent,
                ),
                _buildKpiCard(
                  context,
                  title: 'Palestras Fechadas',
                  value: '08',
                  trend: 'Outubro de 2026',
                  icon: Icons.mic_external_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildKpiCard(
                  context,
                  title: 'Taxa de Conversão',
                  value: '68%',
                  trend: 'Funil de Agendistas',
                  icon: Icons.data_usage,
                  color: Colors.amberAccent,
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Top Temas e Aprovações Pendentes
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gráfico Simulado de Temas mais vendidos
                Expanded(
                  flex: 2,
                  child: _buildSectionContainer(
                    context,
                    title: 'Temas de Maior Tração',
                    child: Column(
                      children: [
                        _buildBarChartRow(context, label: 'O Profissional da Atualidade', percentage: 0.85, value: '12 agendas', color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        _buildBarChartRow(context, label: 'Mapeamento Comportamental', percentage: 0.60, value: '8 agendas', color: Colors.blueGrey),
                        const SizedBox(height: 16),
                        _buildBarChartRow(context, label: 'Liderança e Inteligência', percentage: 0.40, value: '5 agendas', color: Colors.blueGrey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Lista de Aprovações Pendentes
                Expanded(
                  flex: 1,
                  child: _buildSectionContainer(
                    context,
                    title: 'Aprovações Pendentes',
                    child: Column(
                      children: [
                        _buildApprovalItem(
                          context,
                          agendista: 'Eliton',
                          empresa: 'Instituto Vida (IVCA)',
                          data: '12 Nov 2026',
                        ),
                        const Divider(color: Colors.white10),
                        _buildApprovalItem(
                          context,
                          agendista: 'Marcos',
                          empresa: 'TechCorp Solutions',
                          data: 'A definir',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Construtor dos Cards de KPI
  Widget _buildKpiCard(BuildContext context, {required String title, required String value, required String trend, required IconData icon, required Color color}) {
    return Container(
      width: 260, // Largura fixa para manter o design no Wrap
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
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(trend, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }

  // Container para envelopar seções com título
  Widget _buildSectionContainer(BuildContext context, {required String title, required Widget child}) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  // Construtor da Barra de Progresso Simples (DataViz)
  Widget _buildBarChartRow(BuildContext context, {required String label, required double percentage, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Construtor do Item de Aprovação Pendente
  Widget _buildApprovalItem(BuildContext context, {required String agendista, required String empresa, required String data}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(empresa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Por: $agendista • Data: $data', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
            tooltip: 'Aprovar Contrato',
            onPressed: () {},
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          )
        ],
      ),
    );
  }
}