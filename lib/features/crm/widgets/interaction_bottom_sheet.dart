import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import 'event_location.dart';
import 'location_navigation_sheet.dart';
import 'location_picker_screen.dart';

typedef InteractionBottomSheet = CommercialAppointmentModal;

class CommercialAppointmentModal extends StatefulWidget {
  final String empresaNome;
  final DateTime? dataInicial;
  final Map<String, dynamic>? interacaoInicial;
  final bool permitirVinculo;

  const CommercialAppointmentModal({
    super.key,
    required this.empresaNome,
    this.dataInicial,
    this.interacaoInicial,
    this.permitirVinculo = false,
  });

  @override
  State<CommercialAppointmentModal> createState() =>
      _CommercialAppointmentModalState();
}

class _CommercialAppointmentModalState
    extends State<CommercialAppointmentModal> {
  String _statusSelecionado = 'Em Prospecção';
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  DateTime? _dataEvento;
  TimeOfDay? _horarioEvento;
  bool _isSaving = false;
  int _duracaoMinutos = 60;
  Map<String, dynamic>? _interacaoVinculada;
  EventLocation? _localizacao;

  static const List<Map<String, dynamic>> _statusOptions = [
    {'label': 'Em Prospecção', 'icon': Icons.search},
    {'label': 'Aguardando', 'icon': Icons.hourglass_empty},
    {'label': 'Agendada', 'icon': Icons.check_circle},
    {'label': 'Recusada', 'icon': Icons.cancel},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.empresaNome != 'Nova Prospecção') {
      _empresaController.text = widget.empresaNome;
    }
    _dataEvento = widget.dataInicial;
    if (widget.dataInicial != null) _statusSelecionado = 'Agendada';
    if (widget.interacaoInicial != null) {
      _preencherInteracao(widget.interacaoInicial!);
    }
  }

  void _preencherInteracao(Map<String, dynamic> interacao) {
    _interacaoVinculada = interacao;
    _empresaController.text = '${interacao['empresa_nome'] ?? ''}';
    _notasController.text = '${interacao['notas'] ?? ''}';
    _valorController.text = '${interacao['valor'] ?? '0'}';
    _statusSelecionado = widget.dataInicial != null
        ? 'Agendada'
        : '${interacao['status'] ?? 'Em Prospecção'}';
    final data = (interacao['data_evento'] as Timestamp?)?.toDate();
    _dataEvento = widget.dataInicial ?? data;
    _horarioEvento = data == null ? null : TimeOfDay.fromDateTime(data);
    _duracaoMinutos = (interacao['duracao_minutos'] as num?)?.toInt() ?? 60;
    _localizacao = EventLocation.fromMap(interacao['localizacao']);
  }

  Future<void> _selecionarLocalizacao(String nomeAgendista) async {
    final selecionada = await Navigator.of(context).push<EventLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _localizacao,
          capturedBy: nomeAgendista,
        ),
      ),
    );
    if (selecionada != null && mounted) {
      setState(() => _localizacao = selecionada);
    }
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _notasController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataHora() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _dataEvento != null && !_dataEvento!.isBefore(DateUtils.dateOnly(now))
          ? _dataEvento!
          : now,
      firstDate: DateUtils.dateOnly(now),
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _horarioEvento ?? const TimeOfDay(hour: 19, minute: 0),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _dataEvento = pickedDate;
          _horarioEvento = pickedTime;
        });
      }
    }
  }

  bool _validarRegraSabado() {
    if (_statusSelecionado == 'Agendada') {
      if (_dataEvento == null || _horarioEvento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selecione a data e o horário para agendar o evento.',
            ),
          ),
        );
        return false;
      }

      if (_dataEvento!.weekday == DateTime.saturday) {
        final minutosSelecionados =
            _horarioEvento!.hour * 60 + _horarioEvento!.minute;
        final limiteMinutos = 18 * 60 + 30;

        if (minutosSelecionados < limiteMinutos) {
          final tokens = context.tokens;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: tokens.warning),
                  const SizedBox(width: 8),
                  const Text('Restrição de Sábado', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: Text(
                'Aos sábados, os agendamentos são permitidos exclusivamente após as 18:30.\n\nPor favor, escolha um horário a partir das 18:30 ou altere o dia da palestra.',
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Entendido',
                    style: TextStyle(color: tokens.primary),
                  ),
                ),
              ],
            ),
          );
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentUser = FirebaseAuth.instance.currentUser;
    final nomeAgendista =
        currentUser?.displayName ??
        currentUser?.email?.split('@').first ??
        'Agendista';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Apontamento Comercial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: tokens.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Registrado por: $nomeAgendista',
              style: TextStyle(
                color: tokens.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            if (widget.permitirVinculo)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('interacoes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Não foi possível carregar as negociações do CRM.',
                    );
                  }
                  final documentos = snapshot.data?.docs ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _interacaoVinculada?['doc_id'] as String?,
                      decoration: const InputDecoration(
                        labelText: 'Negociação do CRM',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Novo cliente / negociação'),
                        ),
                        for (final documento in documentos)
                          DropdownMenuItem(
                            value: documento.id,
                            child: Text(
                              '${documento.data()['empresa_nome'] ?? 'Cliente'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (id) {
                              setState(() {
                                if (id == null || id.isEmpty) {
                                  _interacaoVinculada = null;
                                  _empresaController.clear();
                                  _notasController.clear();
                                  _valorController.clear();
                                  _dataEvento = widget.dataInicial;
                                  _horarioEvento = null;
                                  _duracaoMinutos = 60;
                                  _statusSelecionado = 'Agendada';
                                  _localizacao = null;
                                } else {
                                  final documento = documentos.firstWhere(
                                    (doc) => doc.id == id,
                                  );
                                  _preencherInteracao({
                                    ...documento.data(),
                                    'doc_id': documento.id,
                                  });
                                }
                              });
                            },
                    ),
                  );
                },
              ),

            TextField(
              controller: _empresaController,
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa / Cliente',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor Proposto (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Status da Negociação',
              style: TextStyle(
                fontSize: 13,
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.6,
              ),
              itemCount: _statusOptions.length,
              itemBuilder: (context, index) {
                final option = _statusOptions[index];
                final label = option['label'] as String;
                final icon = option['icon'] as IconData;
                final color = tokens.statusColor(label);
                final isSelected = _statusSelecionado == label;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _statusSelecionado = label),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.badgeBackground(color)
                            : tokens.surfaceElevated2,
                        border: Border.all(
                          color: isSelected ? color : tokens.borderSubtle,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected ? color : tokens.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? color : tokens.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            if (_statusSelecionado == 'Agendada') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.badgeBackground(tokens.success),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tokens.success.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data e Horário da Palestra (Obrigatório)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tokens.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selecionarDataHora,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tokens.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dataEvento == null
                                  ? 'Clique para selecionar Data e Hora'
                                  : '${_dataEvento!.day}/${_dataEvento!.month}/${_dataEvento!.year} - ${_horarioEvento?.format(context) ?? 'Selecionar horário'}',
                              style: TextStyle(
                                color: _dataEvento == null
                                    ? tokens.textSecondary
                                    : tokens.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: tokens.success,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '$_duracaoMinutos',
                key: ValueKey('duracao-${_interacaoVinculada?['doc_id']}'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração (minutos)',
                ),
                onChanged: (value) =>
                    _duracaoMinutos = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _notasController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações / Próximos Passos',
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _localizacao != null
                      ? tokens.primary.withValues(alpha: 0.45)
                      : tokens.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: _localizacao != null
                            ? tokens.primary
                            : tokens.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Localização do Evento / Empresa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      if (_localizacao != null)
                        IconButton(
                          tooltip: 'Remover localização',
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: tokens.textSecondary,
                          ),
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _localizacao = null),
                        ),
                    ],
                  ),
                  if (_localizacao == null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Marque no mapa ou capture pelo GPS para o palestrante abrir direto no Waze ou Google Maps.',
                      style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _selecionarLocalizacao(nomeAgendista),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Marcar endereço no mapa (GPS)'),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      _localizacao!.displayAddress,
                      style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GPS: ${_localizacao!.coordinatesLabel}',
                      style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _selecionarLocalizacao(nomeAgendista),
                              icon: const Icon(Icons.edit_location_alt, size: 16),
                              label: const Text('Alterar no mapa'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: tokens.primary,
                                side: BorderSide(
                                  color: tokens.primary.withValues(alpha: 0.4),
                                ),
                              ),
                              onPressed: () => showLocationNavigationSheet(
                                context,
                                location: _localizacao!,
                                title: _empresaController.text.trim().isEmpty
                                    ? widget.empresaNome
                                    : _empresaController.text.trim(),
                              ),
                              icon: const Icon(Icons.directions, size: 16),
                              label: const Text('Ir ao local'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final empresaValida = _empresaController.text.trim();
                        if (empresaValida.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe o nome da empresa.'),
                            ),
                          );
                          return;
                        }

                        if (!_validarRegraSabado()) return;

                        setState(() => _isSaving = true);

                        DateTime? dataFinal;
                        if (_dataEvento != null && _horarioEvento != null) {
                          dataFinal = DateTime(
                            _dataEvento!.year,
                            _dataEvento!.month,
                            _dataEvento!.day,
                            _horarioEvento!.hour,
                            _horarioEvento!.minute,
                          );
                        }

                        final apontamento = {
                          'empresa_nome': empresaValida,
                          'status': _statusSelecionado,
                          'valor': _valorController.text.trim().isEmpty
                              ? '0'
                              : _valorController.text.trim(),
                          'agendista':
                              _interacaoVinculada?['agendista'] ??
                              nomeAgendista,
                          'agendista_uid':
                              _interacaoVinculada?['agendista_uid'] ??
                              currentUser?.uid ??
                              '',
                          'notas': _notasController.text.trim(),
                          'data_evento': dataFinal != null
                              ? Timestamp.fromDate(dataFinal)
                              : null,
                          'duracao_minutos': _duracaoMinutos,
                          'localizacao': _localizacao?.toMap(),
                          if (_interacaoVinculada == null)
                            'data_registro': FieldValue.serverTimestamp(),
                        };

                        try {
                          final colecao = FirebaseFirestore.instance.collection(
                            'interacoes',
                          );
                          if (_statusSelecionado == 'Agendada') {
                            if (_duracaoMinutos <= 0 ||
                                _duracaoMinutos > 1440) {
                              throw StateError(
                                'Informe uma duração entre 1 e 1440 minutos.',
                              );
                            }
                            if (dataFinal!.isBefore(DateTime.now())) {
                              throw StateError('Escolha um horário futuro.');
                            }
                            final fim = dataFinal.add(
                              Duration(minutes: _duracaoMinutos),
                            );
                            final agendadas = await colecao
                                .where('status', isEqualTo: 'Agendada')
                                .get();
                            for (final documento in agendadas.docs) {
                              if (documento.id ==
                                  _interacaoVinculada?['doc_id']) {
                                continue;
                              }
                              final dados = documento.data();
                              final inicioExistente =
                                  (dados['data_evento'] as Timestamp?)
                                      ?.toDate();
                              if (inicioExistente == null) continue;
                              final fimExistente = inicioExistente.add(
                                Duration(
                                  minutes:
                                      (dados['duracao_minutos'] as num?)
                                          ?.toInt() ??
                                      60,
                                ),
                              );
                              if (dataFinal.isBefore(fimExistente) &&
                                  inicioExistente.isBefore(fim)) {
                                throw StateError(
                                  'Horário ocupado por ${dados['empresa_nome'] ?? 'outro compromisso'}. Escolha outro horário.',
                                );
                              }
                            }
                          }
                          final id = _interacaoVinculada?['doc_id'] as String?;
                          if (id == null) {
                            await colecao.add(apontamento);
                          } else {
                            await colecao.doc(id).update(apontamento);
                          }
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao salvar: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Registrar na Árvore',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
