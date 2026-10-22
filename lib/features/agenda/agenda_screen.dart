import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../crm/widgets/interaction_bottom_sheet.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool _isVisaoMensal = true;
  DateTime _mesAtual = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agenda de Palestras',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${_getNombreMes(_mesAtual.month)} de ${_mesAtual.year}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            // Alternador Mês / Semana
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton(
                    label: 'Mês',
                    isSelected: _isVisaoMensal,
                    onTap: () => setState(() => _isVisaoMensal = true),
                  ),
                  _buildToggleButton(
                    label: 'Semana',
                    isSelected: !_isVisaoMensal,
                    onTap: () => setState(() => _isVisaoMensal = false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('interacoes')
            .where('status', isEqualTo: 'Agendada')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Não foi possível carregar a agenda.'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Mapeia os eventos agrupados pela chave da data 'YYYY-MM-DD'
          final Map<String, List<Map<String, dynamic>>> eventosPorDia = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            data['doc_id'] = doc.id;
            final timestamp = data['data_evento'] as Timestamp?;

            if (timestamp != null) {
              final dt = timestamp.toDate();
              final chave =
                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

              if (!eventosPorDia.containsKey(chave)) {
                eventosPorDia[chave] = [];
              }
              eventosPorDia[chave]!.add(data);
            }
          }

          return Column(
            children: [
              // Barra de Navegação de Mês/Ano
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _mesAtual = DateTime(
                            _mesAtual.year,
                            _mesAtual.month - 1,
                            1,
                          );
                        });
                      },
                    ),
                    Text(
                      '${_getNombreMes(_mesAtual.month)} de ${_mesAtual.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _mesAtual = DateTime(
                            _mesAtual.year,
                            _mesAtual.month + 1,
                            1,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isVisaoMensal
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final largura = constraints.maxWidth < 1260
                              ? 1260.0
                              : constraints.maxWidth;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: largura,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        for (final dia in [
                                          'DOM',
                                          'SEG',
                                          'TER',
                                          'QUA',
                                          'QUI',
                                          'SEX',
                                          'SÁB',
                                        ])
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                dia,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    _buildGridMensal(context, eventosPorDia),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: _buildGridSemanal(context, eventosPorDia),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Construtor do botão do alternador
  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  // Grade Mensal Responsiva
  Widget _buildGridMensal(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> eventosPorDia,
  ) {
    final primeiroDiaDoMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
    final ultimoDiaDoMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);

    // Ajusta offset para a semana começar no Domingo (weekday: 7 vira 0)
    final diaInicioSemana = primeiroDiaDoMes.weekday == 7
        ? 0
        : primeiroDiaDoMes.weekday;
    final totalDiasExibicao = diaInicioSemana + ultimoDiaDoMes.day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Evita conflito com o SingleChildScrollView
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: MediaQuery.textScalerOf(context).scale(300),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: totalDiasExibicao,
      itemBuilder: (context, index) {
        if (index < diaInicioSemana) {
          return Container(); // Células vazias no início do mês
        }

        final diaNumero = index - diaInicioSemana + 1;
        final dataDia = DateTime(_mesAtual.year, _mesAtual.month, diaNumero);
        final chaveDia =
            '${dataDia.year}-${dataDia.month.toString().padLeft(2, '0')}-${dataDia.day.toString().padLeft(2, '0')}';
        final eventosDoDia = eventosPorDia[chaveDia] ?? [];

        final isHoje =
            DateTime.now().year == dataDia.year &&
            DateTime.now().month == dataDia.month &&
            DateTime.now().day == dataDia.day;

        final isSabado = dataDia.weekday == DateTime.saturday;

        return GestureDetector(
          onTap: () => _exibirDetalhesDoDia(context, dataDia, eventosDoDia),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isHoje
                  ? Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHoje
                    ? Theme.of(context).colorScheme.primary
                    : isSabado
                    ? Colors.amberAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$diaNumero',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isHoje
                            ? Theme.of(context).colorScheme.primary
                            : isSabado
                            ? Colors.amberAccent
                            : Colors.white70,
                      ),
                    ),
                    if (eventosDoDia.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${eventosDoDia.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final evento in eventosDoDia.take(2))
                        _buildEventoVisual(context, dataDia, evento),
                      if (eventosDoDia.length > 2)
                        TextButton(
                          onPressed: () => _exibirDetalhesDoDia(
                            context,
                            dataDia,
                            eventosDoDia,
                          ),
                          child: Text('+${eventosDoDia.length - 2} eventos'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Visão Semanal Alternativa
  Widget _buildGridSemanal(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> eventosPorDia,
  ) {
    final inicioSemana = DateTime(
      _mesAtual.year,
      _mesAtual.month,
      _mesAtual.day - _mesAtual.weekday % 7,
    );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      itemBuilder: (context, index) {
        final dataDia = inicioSemana.add(Duration(days: index));
        final chaveDia =
            '${dataDia.year}-${dataDia.month.toString().padLeft(2, '0')}-${dataDia.day.toString().padLeft(2, '0')}';
        final eventosDoDia = eventosPorDia[chaveDia] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            onTap: () => _exibirDetalhesDoDia(context, dataDia, eventosDoDia),
            title: Text(
              '${dataDia.day}/${dataDia.month} -${_getDiaSemanaNome(dataDia.weekday)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (eventosDoDia.isEmpty)
                  const Text('Nenhuma palestra agendada')
                else
                  for (final evento in eventosDoDia)
                    _buildEventoVisual(context, dataDia, evento),
              ],
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white38,
            ),
          ),
        );
      },
    );
  }

  void _abrirAgendamento(DateTime dia, {Map<String, dynamic>? interacao}) {
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
          empresaNome: '${interacao?['empresa_nome'] ?? 'Nova Prospecção'}',
          dataInicial: interacao == null ? dia : null,
          interacaoInicial: interacao,
          permitirVinculo: interacao == null,
        ),
      ),
    );
  }

  // Modal com os detalhes completos do dia
  void _exibirDetalhesDoDia(
    BuildContext context,
    DateTime dataDia,
    List<Map<String, dynamic>> eventos,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: 640,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Agenda de ${dataDia.day} de ${_getNombreMes(dataDia.month)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agendar neste dia'),
                  onPressed:
                      DateUtils.dateOnly(dataDia)
                          .isBefore(DateUtils.dateOnly(DateTime.now()))
                      ? null
                      : () {
                          Navigator.pop(context);
                          _abrirAgendamento(dataDia);
                        },
                ),
              ),
              const SizedBox(height: 12),

              if (eventos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Não há compromissos agendados para este dia.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: eventos.length,
                    itemBuilder: (context, index) {
                      final ev = eventos[index];
                      final timestamp = ev['data_evento'] as Timestamp?;
                      final hora = timestamp != null
                          ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                          : 'A definir';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ev['empresa_nome'] ?? 'Cliente',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hora,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Duração: ${ev['duracao_minutos'] ?? 60} minutos',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Agendista: ${ev['agendista'] ?? 'Não informado'}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                            if (ev['valor'] != null && ev['valor'] != '0') ...[
                              const SizedBox(height: 4),
                              Text(
                                'Valor: R\$ ${ev['valor']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            if (ev['notas'] != null &&
                                (ev['notas'] as String).isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Observações: ${ev['notas']}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (ev['doc_id'] != null)
                              TextButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Abrir negociação do CRM'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _abrirAgendamento(dataDia, interacao: ev);
                                },
                              ),
                          ],
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

  Widget _buildEventoVisual(
    BuildContext context,
    DateTime dia,
    Map<String, dynamic> evento,
  ) {
    final data = (evento['data_evento'] as Timestamp?)?.toDate();
    final hora = data == null
        ? 'A definir'
        : '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Colors.greenAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _exibirDetalhesDoDia(context, dia, [evento]),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${evento['empresa_nome'] ?? 'Cliente'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Agendista: ${evento['agendista'] ?? 'Não informado'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                if (evento['valor'] != null && '${evento['valor']}' != '0')
                  Text(
                    'R\$ ${evento['valor']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                if ('${evento['notas'] ?? ''}'.isNotEmpty)
                  Text(
                    '${evento['notas']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNombreMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return meses[mes - 1];
  }

  String _getDiaSemanaNome(int dia) {
    const dias = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    return dias[dia - 1];
  }
}
