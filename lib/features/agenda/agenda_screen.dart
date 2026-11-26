import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';
import '../crm/widgets/event_location.dart';
import '../crm/widgets/interaction_bottom_sheet.dart';
import '../crm/widgets/location_navigation_sheet.dart';

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
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agenda de Palestras',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: tokens.textPrimary,
              ),
            ),
            Text(
              '${_getNombreMes(_mesAtual.month)} de ${_mesAtual.year}',
              style: TextStyle(
                fontSize: 12,
                color: tokens.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: tokens.surfaceElevated2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle),
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
            return const BrandLoadingView(message: 'Carregando agenda...');
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
                      icon: Icon(
                        Icons.chevron_left,
                        color: tokens.textSecondary,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: tokens.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: tokens.textSecondary,
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
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? tokens.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : tokens.textSecondary,
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
    final tokens = context.tokens;
    final primeiroDiaDoMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
    final ultimoDiaDoMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);

    final diaInicioSemana = primeiroDiaDoMes.weekday == 7
        ? 0
        : primeiroDiaDoMes.weekday;
    final totalDiasExibicao = diaInicioSemana + ultimoDiaDoMes.day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: MediaQuery.textScalerOf(context).scale(300),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalDiasExibicao,
      itemBuilder: (context, index) {
        if (index < diaInicioSemana) {
          return Container(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated2.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tokens.borderSubtle.withValues(alpha: 0.5),
              ),
            ),
          );
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHoje
                  ? tokens.badgeBackground(tokens.primary)
                  : tokens.surfaceElevated1,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHoje
                    ? tokens.primary
                    : isSabado
                    ? tokens.warning.withValues(alpha: 0.4)
                    : tokens.borderSubtle,
                width: isHoje ? 1.5 : 1.0,
              ),
              boxShadow: tokens.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$diaNumero',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isHoje
                                ? tokens.primary
                                : isSabado
                                ? tokens.warning
                                : tokens.textPrimary,
                          ),
                        ),
                        if (isSabado) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.badgeBackground(tokens.warning),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '>18:30',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: tokens.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (eventosDoDia.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.badgeBackground(tokens.success),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${eventosDoDia.length}',
                          style: TextStyle(
                            fontSize: 10,
                            color: tokens.success,
                            fontWeight: FontWeight.w700,
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
      backgroundColor: context.tokens.surfaceElevated1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final tokens = context.tokens;

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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: tokens.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: tokens.borderSubtle),
              const SizedBox(height: 12),
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
                const EmptyStateBox(
                  icon: Icons.event_available_outlined,
                  message: 'Não há compromissos agendados para este dia.',
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: eventos.length,
                    itemBuilder: (context, index) {
                      final ev = eventos[index];
                      final localizacao = EventLocation.fromMap(
                        ev['localizacao'],
                      );
                      final timestamp = ev['data_evento'] as Timestamp?;
                      final hora = timestamp != null
                          ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                          : 'A definir';

                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        backgroundColor: tokens.surfaceElevated2,
                        borderColor: tokens.success.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ev['empresa_nome'] ?? 'Cliente',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  label: hora,
                                  color: tokens.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Duração: ${ev['duracao_minutos'] ?? 60} minutos',
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.textSecondary,
                              ),
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
                            if (localizacao != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.lightBlueAccent
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.lightBlueAccent
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 15,
                                          color: Colors.lightBlueAccent,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            localizacao.displayAddress,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LocationActionButtons(
                                      location: localizacao,
                                      empresaNome:
                                          '${ev['empresa_nome'] ?? 'Cliente'}',
                                    ),
                                  ],
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
    final tokens = context.tokens;
    final localizacao = EventLocation.fromMap(evento['localizacao']);
    final data = (evento['data_evento'] as Timestamp?)?.toDate();
    final hora = data == null
        ? 'A definir'
        : '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: tokens.badgeBackground(tokens.success),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _exibirDetalhesDoDia(context, dia, [evento]),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hora,
                  style: TextStyle(
                    fontSize: 11,
                    color: tokens.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${evento['empresa_nome'] ?? 'Cliente'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  'Agendista: ${evento['agendista'] ?? 'Não informado'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                ),
                if (evento['valor'] != null && '${evento['valor']}' != '0')
                  Text(
                    'R\$ ${evento['valor']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: tokens.textPrimary),
                  ),
                if ('${evento['notas'] ?? ''}'.isNotEmpty)
                  Text(
                    '${evento['notas']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                  ),
                if (localizacao != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 11,
                        color: tokens.primary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          localizacao.displayAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: tokens.primary,
                          ),
                        ),
                      ),
                    ],
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
