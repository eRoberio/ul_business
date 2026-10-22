import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InteractionBottomSheet extends StatefulWidget {
  final String empresaNome;
  final DateTime? dataInicial;
  final Map<String, dynamic>? interacaoInicial;
  final bool permitirVinculo;

  const InteractionBottomSheet({
    super.key,
    required this.empresaNome,
    this.dataInicial,
    this.interacaoInicial,
    this.permitirVinculo = false,
  });

  @override
  State<InteractionBottomSheet> createState() => _InteractionBottomSheetState();
}

class _InteractionBottomSheetState extends State<InteractionBottomSheet> {
  String _statusSelecionado = 'Em Prospecção';
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  DateTime? _dataEvento;
  TimeOfDay? _horarioEvento;
  bool _isSaving = false;
  int _duracaoMinutos = 60;
  Map<String, dynamic>? _interacaoVinculada;

  final List<Map<String, dynamic>> _statusOptions = [
    {'label': 'Em Prospecção', 'icon': Icons.search, 'color': Colors.blueGrey},
    {
      'label': 'Aguardando',
      'icon': Icons.hourglass_empty,
      'color': Colors.amberAccent,
    },
    {
      'label': 'Agendada',
      'icon': Icons.check_circle,
      'color': Colors.greenAccent,
    },
    {'label': 'Recusada', 'icon': Icons.cancel, 'color': Colors.redAccent},
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
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _notasController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // Seletor de Data e Hora
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

  // Validação da Regra do Sábado
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

      // Sábado = DateTime.saturday (6)
      if (_dataEvento!.weekday == DateTime.saturday) {
        final minutosSelecionados =
            _horarioEvento!.hour * 60 + _horarioEvento!.minute;
        final limiteMinutos = 18 * 60 + 30; // 18:30 = 1110 minutos

        if (minutosSelecionados < limiteMinutos) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text('Restrição de Sábado', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: const Text(
                'Aos sábados, os agendamentos são permitidos exclusivamente após as 18:30.\n\nPor favor, escolha um horário a partir das 18:30 ou altere o dia da palestra.',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(color: Colors.blueAccent),
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final nomeAgendista =
        currentUser?.displayName ??
        currentUser?.email?.split('@').first ??
        'Agendista';

    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apontamento Comercial',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Registrado por: $nomeAgendista',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
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
              decoration: InputDecoration(
                labelText: 'Nome da Empresa / Cliente',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor Proposto (R\$)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Status da Negociação:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
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
                final isSelected = _statusSelecionado == option['label'];

                return GestureDetector(
                  onTap: () =>
                      setState(() => _statusSelecionado = option['label']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? option['color'].withOpacity(0.15)
                          : Colors.white.withOpacity(0.02),
                      border: Border.all(
                        color: isSelected ? option['color'] : Colors.white10,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'],
                          size: 16,
                          color: isSelected ? option['color'] : Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option['label'],
                          style: TextStyle(
                            color: isSelected
                                ? option['color']
                                : Colors.white54,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Seleção de Data/Hora (Aparece em destaque se for "Agendada")
            if (_statusSelecionado == 'Agendada') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data e Horário da Palestra (Obrigatório):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selecionarDataHora,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
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
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.greenAccent,
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
              decoration: InputDecoration(
                labelText: 'Observações / Próximos Passos',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                                  _interacaoVinculada?['doc_id'])
                                continue;
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
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao salvar: $e')),
                            );
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text(
                        'Registrar na Árvore',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
