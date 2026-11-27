import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';
import '../../data/providers/repository_providers.dart';
import '../crm/widgets/event_location.dart';
import '../crm/widgets/interaction_bottom_sheet.dart';
import '../crm/widgets/location_navigation_sheet.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  bool _isVisaoMensal = true;
  String _filtroStatus = 'Todos';
  DateTime _mesAtual = DateTime.now();
  DateTime _diaSelecionado = DateUtils.dateOnly(DateTime.now());

  final ScrollController _monthlyVerticalController = ScrollController();
  final ScrollController _weeklyVerticalController = ScrollController();

  @override
  void dispose() {
    _monthlyVerticalController.dispose();
    _weeklyVerticalController.dispose();
    super.dispose();
  }

  DateTime? _resolveInteractionDate(Map<String, dynamic> data) {
    final eventoTs = data['data_evento'] as Timestamp?;
    if (eventoTs != null) return eventoTs.toDate();
    final registroTs = data['data_registro'] as Timestamp?;
    return registroTs?.toDate();
  }

  String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agenda Comercial',
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
        actions: [
          TextButton.icon(
            onPressed: () {
              final hoje = DateTime.now();
              setState(() {
                _mesAtual = DateTime(hoje.year, hoje.month, 1);
                _diaSelecionado = DateUtils.dateOnly(hoje);
              });
            },
            icon: const Icon(Icons.today_outlined, size: 16),
            label: const Text('Hoje', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              height: 34,
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
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(crmRepositoryProvider).watchInteractions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const BrandLoadingView(message: 'Carregando agenda...');
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Não foi possível carregar a agenda.'),
            );
          }

          final docs = snapshot.data ?? [];

          final Map<String, List<Map<String, dynamic>>> eventosPorDia = {};
          for (final data in docs) {
            final status = '${data['status'] ?? 'Em Prospecção'}';
            if (_filtroStatus == 'Agendadas' && status != 'Agendada') {
              continue;
            }
            if (_filtroStatus == 'Prospecção' &&
                status != 'Em Prospecção' &&
                status != 'Aguardando') {
              continue;
            }

            final dt = _resolveInteractionDate(data);
            if (dt == null) continue;
            final chave = _dayKey(dt);
            eventosPorDia.putIfAbsent(chave, () => []).add(data);
          }

          // Ordena dentro de cada dia: agendados com horário primeiro, depois registros
          for (final lista in eventosPorDia.values) {
            lista.sort((a, b) {
              final dtA = _resolveInteractionDate(a) ?? DateTime(2000);
              final dtB = _resolveInteractionDate(b) ?? DateTime(2000);
              return dtA.compareTo(dtB);
            });
          }

          return Column(
            children: [
              // Navegação do Mês + Filtro Rápido
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
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
                          '${_getNombreMes(_mesAtual.month)} ${_mesAtual.year}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: tokens.textPrimary,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
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
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final filtro in const [
                          'Todos',
                          'Agendadas',
                          'Prospecção',
                        ])
                          ChoiceChip(
                            label: Text(
                              filtro,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _filtroStatus == filtro,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) =>
                                setState(() => _filtroStatus = filtro),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isVisaoMensal
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompactMobile = constraints.maxWidth < 720;
                          return SingleChildScrollView(
                            key: const PageStorageKey('agenda_monthly_v'),
                            controller: _monthlyVerticalController,
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                            child: Column(
                              children: [
                                _buildWeekDaysHeader(tokens),
                                const SizedBox(height: 6),
                                _buildGridMensal(
                                  context,
                                  eventosPorDia,
                                  isCompactMobile: isCompactMobile,
                                ),
                                if (isCompactMobile) ...[
                                  const SizedBox(height: 16),
                                  _buildSelectedDayPanel(
                                    context,
                                    _diaSelecionado,
                                    eventosPorDia[_dayKey(_diaSelecionado)] ??
                                        [],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      )
                    : SingleChildScrollView(
                        key: const PageStorageKey('agenda_weekly_v'),
                        controller: _weeklyVerticalController,
                        padding: const EdgeInsets.all(12),
                        child: _buildGridSemanal(context, eventosPorDia),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeekDaysHeader(AppThemeTokens tokens) {
    return Row(
      children: [
        for (final dia in const ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                dia,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dia == 'SÁB' ? tokens.warning : tokens.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

  Widget _buildGridMensal(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> eventosPorDia, {
    required bool isCompactMobile,
  }) {
    final tokens = context.tokens;
    final primeiroDiaDoMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
    final ultimoDiaDoMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);

    final diaInicioSemana =
        primeiroDiaDoMes.weekday == 7 ? 0 : primeiroDiaDoMes.weekday;
    final totalDiasExibicao = diaInicioSemana + ultimoDiaDoMes.day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: isCompactMobile
            ? 56
            : MediaQuery.textScalerOf(context).scale(118),
        crossAxisSpacing: isCompactMobile ? 4 : 6,
        mainAxisSpacing: isCompactMobile ? 4 : 6,
      ),
      itemCount: totalDiasExibicao,
      itemBuilder: (context, index) {
        if (index < diaInicioSemana) {
          return Container(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated2.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        final diaNumero = index - diaInicioSemana + 1;
        final dataDia = DateTime(_mesAtual.year, _mesAtual.month, diaNumero);
        final chaveDia = _dayKey(dataDia);
        final eventosDoDia = eventosPorDia[chaveDia] ?? [];

        final hoje = DateUtils.dateOnly(DateTime.now());
        final isHoje = DateUtils.isSameDay(hoje, dataDia);
        final isSelecionado = DateUtils.isSameDay(_diaSelecionado, dataDia);
        final isSabado = dataDia.weekday == DateTime.saturday;

        return GestureDetector(
          onTap: () {
            setState(() => _diaSelecionado = dataDia);
            if (!isCompactMobile) {
              _exibirDetalhesDoDia(context, dataDia, eventosDoDia);
            }
          },
          child: Container(
            padding: EdgeInsets.all(isCompactMobile ? 4 : 6),
            decoration: BoxDecoration(
              color: isSelecionado && isCompactMobile
                  ? tokens.primary.withValues(alpha: 0.14)
                  : isHoje
                  ? tokens.badgeBackground(tokens.primary)
                  : tokens.surfaceElevated1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelecionado && isCompactMobile
                    ? tokens.primary
                    : isHoje
                    ? tokens.primary
                    : isSabado
                    ? tokens.warning.withValues(alpha: 0.35)
                    : tokens.borderSubtle,
                width: (isHoje || (isSelecionado && isCompactMobile)) ? 1.5 : 1,
              ),
            ),
            child: isCompactMobile
                ? _buildCompactDayCell(
                    tokens,
                    diaNumero: diaNumero,
                    isHoje: isHoje,
                    isSabado: isSabado,
                    eventosDoDia: eventosDoDia,
                  )
                : _buildDesktopDayCell(
                    context,
                    tokens,
                    dataDia: dataDia,
                    diaNumero: diaNumero,
                    isHoje: isHoje,
                    isSabado: isSabado,
                    eventosDoDia: eventosDoDia,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCompactDayCell(
    AppThemeTokens tokens, {
    required int diaNumero,
    required bool isHoje,
    required bool isSabado,
    required List<Map<String, dynamic>> eventosDoDia,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$diaNumero',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: isHoje
                ? tokens.primary
                : isSabado
                ? tokens.warning
                : tokens.textPrimary,
          ),
        ),
        if (eventosDoDia.isNotEmpty)
          Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              for (final ev in eventosDoDia.take(3))
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tokens.statusColor('${ev['status'] ?? 'Em Prospecção'}'),
                    shape: BoxShape.circle,
                  ),
                ),
              if (eventosDoDia.length > 3)
                Text(
                  '+',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tokens.textSecondary,
                  ),
                ),
            ],
          )
        else
          const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildDesktopDayCell(
    BuildContext context,
    AppThemeTokens tokens, {
    required DateTime dataDia,
    required int diaNumero,
    required bool isHoje,
    required bool isSabado,
    required List<Map<String, dynamic>> eventosDoDia,
  }) {
    return Column(
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
                    fontSize: 12,
                    color: isHoje
                        ? tokens.primary
                        : isSabado
                        ? tokens.warning
                        : tokens.textPrimary,
                  ),
                ),
                if (isSabado) ...[
                  const SizedBox(width: 4),
                  Text(
                    '>18:30',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.warning,
                    ),
                  ),
                ],
              ],
            ),
            if (eventosDoDia.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Text(
                  '${eventosDoDia.length}',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: tokens.textSecondary,
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
                _buildCompactPill(context, dataDia, evento),
              if (eventosDoDia.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${eventosDoDia.length - 2} mais',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tokens.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPill(
    BuildContext context,
    DateTime dia,
    Map<String, dynamic> evento,
  ) {
    final tokens = context.tokens;
    final status = '${evento['status'] ?? 'Em Prospecção'}';
    final color = tokens.statusColor(status);
    final dataEvento = (evento['data_evento'] as Timestamp?)?.toDate();
    final prefix = dataEvento != null
        ? '${dataEvento.hour.toString().padLeft(2, '0')}:${dataEvento.minute.toString().padLeft(2, '0')}'
        : status;

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.badgeBackground(color),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$prefix • ${evento['empresa_nome'] ?? 'Cliente'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSelectedDayPanel(
    BuildContext context,
    DateTime dataDia,
    List<Map<String, dynamic>> eventos,
  ) {
    final tokens = context.tokens;
    final podeAgendar = !DateUtils.dateOnly(
      dataDia,
    ).isBefore(DateUtils.dateOnly(DateTime.now()));

    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${dataDia.day.toString().padLeft(2, '0')}/${dataDia.month.toString().padLeft(2, '0')}/${dataDia.year} • ${_getDiaSemanaNome(dataDia.weekday)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: podeAgendar ? () => _abrirAgendamento(dataDia) : null,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Registrar', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (eventos.isEmpty)
            Text(
              'Nenhuma prospecção ou palestra registrada neste dia.',
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            )
          else
            for (final ev in eventos) _buildEventoVisual(context, dataDia, ev),
        ],
      ),
    );
  }

  // Visão Semanal Alternativa
  Widget _buildGridSemanal(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> eventosPorDia,
  ) {
    final tokens = context.tokens;
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
        final eventosDoDia = eventosPorDia[_dayKey(dataDia)] ?? [];

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 10.0),
          padding: const EdgeInsets.all(14),
          onTap: () => _exibirDetalhesDoDia(context, dataDia, eventosDoDia),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${dataDia.day.toString().padLeft(2, '0')}/${dataDia.month.toString().padLeft(2, '0')} - ${_getDiaSemanaNome(dataDia.weekday)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: tokens.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (eventosDoDia.isEmpty)
                Text(
                  'Nenhuma atividade registrada',
                  style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                )
              else
                for (final evento in eventosDoDia)
                  _buildEventoVisual(context, dataDia, evento),
            ],
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
                  label: const Text('Registrar / Agendar neste dia'),
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
                  message: 'Não há atividades ou agendamentos neste dia.',
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: eventos.length,
                    itemBuilder: (context, index) {
                      final ev = eventos[index];
                      final status = '${ev['status'] ?? 'Em Prospecção'}';
                      final statusColor = tokens.statusColor(status);
                      final localizacao = EventLocation.fromMap(
                        ev['localizacao'],
                      );
                      final timestamp = ev['data_evento'] as Timestamp?;
                      final hora = timestamp != null
                          ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                          : status;

                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        backgroundColor: tokens.surfaceElevated2,
                        borderColor: statusColor.withValues(alpha: 0.35),
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
                                  label: '$status${timestamp != null ? ' • $hora' : ''}',
                                  color: statusColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (status == 'Agendada')
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
                                color: tokens.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (ev['valor'] != null && ev['valor'] != '0') ...[
                              const SizedBox(height: 4),
                              Text(
                                'Valor: R\$ ${ev['valor']}',
                                style: TextStyle(
                                  color: tokens.textPrimary,
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
                                style: TextStyle(
                                  color: tokens.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (localizacao != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: tokens.badgeBackground(tokens.primary),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: tokens.primary.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 15,
                                          color: tokens.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            localizacao.displayAddress,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: tokens.textPrimary,
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
    final status = '${evento['status'] ?? 'Em Prospecção'}';
    final statusColor = tokens.statusColor(status);
    final localizacao = EventLocation.fromMap(evento['localizacao']);
    final data = (evento['data_evento'] as Timestamp?)?.toDate();
    final hora = data == null
        ? status
        : '$status • ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: tokens.badgeBackground(statusColor),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _exibirDetalhesDoDia(context, dia, [evento]),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hora,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
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
