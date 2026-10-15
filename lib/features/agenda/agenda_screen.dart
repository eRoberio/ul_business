import 'package:flutter/material.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agenda Sincronizada',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Visão Mestra • Outubro 2026',
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
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar Agora',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filtros',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor Horizontal de Dias (Semana)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildDateSelector(context, day: '12', weekday: 'Seg', isSelected: false),
                _buildDateSelector(context, day: '13', weekday: 'Ter', isSelected: false),
                _buildDateSelector(context, day: '14', weekday: 'Qua', isSelected: false),
                _buildDateSelector(context, day: '15', weekday: 'Qui', isSelected: true), // Dia atual selecionado
                _buildDateSelector(context, day: '16', weekday: 'Sex', isSelected: false),
                _buildDateSelector(context, day: '17', weekday: 'Sáb', isSelected: false),
              ],
            ),
          ),
          
          // Timeline do Dia Selecionado
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Evento Confirmado
                _buildEventCard(
                  context,
                  time: '09:00\n11:30',
                  title: 'O Profissional da Atualidade',
                  company: 'Instituto Vida & Consultores (IVCA)',
                  agent: 'Fechado por: Eliton',
                  status: 'Confirmado',
                  statusColor: Colors.greenAccent,
                ),
                
                // Intervalo / Bloqueio
                _buildBlockCard(
                  context,
                  time: '12:00\n14:00',
                  title: 'Deslocamento / Almoço',
                  icon: Icons.directions_car_outlined,
                ),

                // Evento Pendente (Pré-reserva)
                _buildEventCard(
                  context,
                  time: '15:00\n17:00',
                  title: 'Mapeamento Comportamental',
                  company: 'TechCorp Solutions',
                  agent: 'Pré-reserva: Marcos',
                  status: 'Aguardando Assinatura',
                  statusColor: Colors.amberAccent,
                ),

                // Espaço Livre
                _buildFreeSlotCard(
                  context,
                  time: '18:00\n21:00',
                ),
              ],
            ),
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

  // Widget: Seletor de Data
  Widget _buildDateSelector(BuildContext context, {required String day, required String weekday, required bool isSelected}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      margin: const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? colorScheme.primary : Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(weekday, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white54)),
          const SizedBox(height: 4),
          Text(day, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white)),
        ],
      ),
    );
  }

  // Widget: Cartão de Evento (Palestra/Treinamento)
  Widget _buildEventCard(
    BuildContext context, {
    required String time,
    required String title,
    required String company,
    required String agent,
    required String status,
    required Color statusColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna de Horário
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(time, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white54, height: 1.5)),
            ),
          ),
          const SizedBox(width: 8),
          // Linha lateral de status
          Container(width: 4, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          // Cartão de Conteúdo
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              color: Theme.of(context).colorScheme.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 14, color: Colors.white54),
                        const SizedBox(width: 6),
                        Expanded(child: Text(company, style: const TextStyle(fontSize: 13, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(agent, style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Cartão de Bloqueio (Viagem/Descanso)
  Widget _buildBlockCard(BuildContext context, {required String time, required String title, required IconData icon}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(time, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white38, height: 1.5)),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.white38),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Slot Livre para Agendamento
  Widget _buildFreeSlotCard(BuildContext context, {required String time}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(time, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white38, height: 1.5)),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 4, decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10, style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text('+ Horário Disponível', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}