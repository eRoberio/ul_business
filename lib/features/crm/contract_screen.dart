import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';

import 'cnpj_service.dart';
import 'contract_document.dart';

class ContractScreen extends StatefulWidget {
  final Map<String, dynamic> interacao;
  final CnpjService cnpjService;

  const ContractScreen({
    super.key,
    required this.interacao,
    this.cnpjService = const CnpjService(),
  });

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _selectedThemes = <String>{};
  final _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _accepted = false;
  bool _allowImage = false;
  bool _busy = false;
  bool _lookingUp = false;
  String? _lookupError;
  Timer? _cnpjDebounce;
  late bool _signed;
  String? _contractId;
  Uint8List? _savedPdf;

  static const _moneyFields = [
    'valor_palestra',
    'valor_viagem',
    'valor_cadastro',
  ];
  static const _countFields = ['efetivos', 'terceirizados', 'participantes'];
  static const _states = {
    'AC': 'Acre',
    'AL': 'Alagoas',
    'AP': 'Amapá',
    'AM': 'Amazonas',
    'BA': 'Bahia',
    'CE': 'Ceará',
    'DF': 'Distrito Federal',
    'ES': 'Espírito Santo',
    'GO': 'Goiás',
    'MA': 'Maranhão',
    'MT': 'Mato Grosso',
    'MS': 'Mato Grosso do Sul',
    'MG': 'Minas Gerais',
    'PA': 'Pará',
    'PB': 'Paraíba',
    'PR': 'Paraná',
    'PE': 'Pernambuco',
    'PI': 'Piauí',
    'RJ': 'Rio de Janeiro',
    'RN': 'Rio Grande do Norte',
    'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia',
    'RR': 'Roraima',
    'SC': 'Santa Catarina',
    'SP': 'São Paulo',
    'SE': 'Sergipe',
    'TO': 'Tocantins',
  };
  static const _requiredFields = {
    'emitente_cnpj',
    'razao_social',
    'cnpj',
    'email',
    'fone',
    'contato',
    'endereco',
    'numero',
    'bairro',
    'cep',
    'cidade',
    'estado',
    'efetivos',
    'terceirizados',
    'participantes',
    'palestrante',
    'consultor',
    'condicoes',
    'signatario',
    'cargo',
  };

  DateTime? get _event =>
      (widget.interacao['data_evento'] as Timestamp?)?.toDate();
  int get _duration =>
      (widget.interacao['duracao_minutos'] as num?)?.toInt() ?? 60;
  int get _total => _moneyFields.fold(
    0,
    (total, key) =>
        total + (ContractDocument.cents(_controllers[key]!.text) ?? 0),
  );

  @override
  void initState() {
    super.initState();
    _signed = widget.interacao['contrato_assinado'] == true;
    _contractId = widget.interacao['contrato_id'] as String?;
    for (final key in ContractDocument.fields.keys) {
      _controllers[key] = TextEditingController();
    }
    _controllers['razao_social']!.text =
        '${widget.interacao['empresa_nome'] ?? ''}';
    _controllers['valor_palestra']!.text =
        '${widget.interacao['valor'] ?? '0'}';
    _controllers['valor_viagem']!.text = '0';
    _controllers['valor_cadastro']!.text = '0';
    _controllers['terceirizados']!.text = '0';
    _controllers['consultor']!.text = '${widget.interacao['agendista'] ?? ''}';
    for (final controller in _controllers.values) {
      controller.addListener(_onDataChanged);
    }
  }

  void _invalidateAgreement() {
    _accepted = false;
    if (_signatureController.isNotEmpty) _signatureController.clear();
  }

  void _onDataChanged() => setState(_invalidateAgreement);

  @override
  void dispose() {
    _cnpjDebounce?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _signatureController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _onCnpjInput(String value) {
    _cnpjDebounce?.cancel();
    setState(() => _lookupError = null);
    if (ContractDocument.validCnpj(value)) {
      _cnpjDebounce = Timer(const Duration(milliseconds: 600), _lookupCompany);
    }
  }

  Future<void> _lookupCompany() async {
    _cnpjDebounce?.cancel();
    if (_lookingUp || _busy || _signed) return;
    final input = _controllers['cnpj']!.text;
    if (!ContractDocument.validCnpj(input)) {
      setState(() => _lookupError = 'Informe um CNPJ válido para consultar.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _lookingUp = true;
      _lookupError = null;
    });
    try {
      final fields = await widget.cnpjService.lookup(input);
      if (!mounted) return;
      if (ContractDocument.normalizeCnpj(_controllers['cnpj']!.text) !=
          ContractDocument.normalizeCnpj(input))
        return;
      for (final entry in fields.entries) {
        _controllers[entry.key]!.text = entry.value;
      }
      _message(
        'Dados cadastrais recebidos da BrasilAPI. Confira antes de assinar.',
      );
    } on CnpjLookupException catch (error) {
      if (mounted) setState(() => _lookupError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _lookupError = 'Não foi possível consultar. Tente novamente ou preencha manualmente.',
        );
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  bool _validate({required bool signing}) {
    if (_lookingUp) return false;
    if (!_formKey.currentState!.validate()) {
      _message('Revise os campos obrigatórios e os valores informados.');
      return false;
    }
    if (_selectedThemes.isEmpty &&
        _controllers['personalizada']!.text.trim().isEmpty) {
      _message('Selecione uma palestra ou informe a palestra personalizada.');
      return false;
    }
    final event = _event;
    if (event == null ||
        !event.isAfter(DateTime.now()) ||
        _duration <= 0 ||
        _duration > 1440) {
      _message('Defina uma agenda futura válida no CRM antes de assinar.');
      return false;
    }
    final employees =
        int.parse(_controllers['efetivos']!.text.trim()) +
        int.parse(_controllers['terceirizados']!.text.trim());
    if (int.parse(_controllers['participantes']!.text.trim()) > employees) {
      _message(
        'Participantes previstos não podem superar o total de funcionários.',
      );
      return false;
    }
    if (_signatureController.isEmpty) {
      _message('A assinatura do representante da contratante é obrigatória.');
      return false;
    }
    if (signing && !_accepted) {
      _message(
        'O representante precisa aceitar as condições antes de assinar.',
      );
      return false;
    }
    return true;
  }

  Map<String, String> _data() => _controllers.map(
    (key, controller) => MapEntry(key, controller.text.trim()),
  );

  Future<void> _preview() async {
    if (!_validate(signing: false)) return;
    setState(() => _busy = true);
    try {
      final signature = await _signatureController.toPngBytes();
      if (signature == null)
        throw StateError('Não foi possível capturar a assinatura.');
      final bytes = await ContractDocument.generate(
        id: 'RASCUNHO - NÃO FORMALIZADO',
        data: _data(),
        selectedThemes: _selectedThemes.toList(),
        event: _event!,
        duration: _duration,
        signedAt: DateTime.now().toUtc(),
        allowImage: _allowImage,
        signature: signature,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Revisão do termo')),
            body: PdfPreview(
              build: (_) async => bytes,
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowPrinting: false,
              allowSharing: false,
              canDebug: false,
            ),
          ),
        ),
      );
    } catch (error) {
      _message('Não foi possível revisar o PDF: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_validate(signing: true)) return;
    final interactionId = widget.interacao['doc_id'] as String?;
    if (interactionId == null || interactionId.isEmpty) {
      _message('Salve a interação no CRM antes de formalizar o contrato.');
      return;
    }
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Entre novamente na sua conta.');
      final signature = await _signatureController.toPngBytes();
      if (signature == null || signature.isEmpty) {
        throw StateError('Não foi possível capturar a assinatura.');
      }
      final firestore = FirebaseFirestore.instance;
      final interaction = firestore.collection('interacoes').doc(interactionId);
      final contract = interaction.collection('contratos').doc();
      final data = _data();
      final selectedThemes = _selectedThemes.toList();
      final signedAt = DateTime.now().toUtc();
      final bytes = await ContractDocument.generate(
        id: contract.id,
        data: data,
        selectedThemes: selectedThemes,
        event: _event!,
        duration: _duration,
        signedAt: signedAt,
        allowImage: _allowImage,
        signature: signature,
      );
      if (bytes.length + signature.length > 850000) {
        throw StateError(
          'Documento muito grande. Limpe e refaça a assinatura.',
        );
      }
      await firestore.runTransaction((transaction) async {
        final latest = await transaction.get(interaction);
        final current = latest.data();
        if (current == null) throw StateError('A interação não existe mais.');
        if (current['contrato_assinado'] == true) {
          throw StateError(
            'Esta interação já possui um contrato assinado. Reabra a tela para acessar a cópia.',
          );
        }
        final latestEvent = (current['data_evento'] as Timestamp?)?.toDate();
        final latestDuration =
            (current['duracao_minutos'] as num?)?.toInt() ?? 60;
        if (latestEvent != _event || latestDuration != _duration) {
          throw StateError(
            'A agenda mudou. Reabra o contrato para conferir os dados.',
          );
        }
        transaction.set(contract, {
          'versao': ContractDocument.version,
          'dados': data,
          'temas': selectedThemes,
          'clausulas': ContractDocument.clauses,
          'texto_aceite': ContractDocument.acceptance,
          'aceite': true,
          'autorizacao_imagem': _allowImage,
          'texto_autorizacao_imagem': ContractDocument.imageConsent,
          'assinatura_png': Blob(signature),
          'pdf': Blob(bytes),
          'total_centavos': _total,
          'data_evento': Timestamp.fromDate(_event!),
          'duracao_minutos': _duration,
          'aceito_em_dispositivo': Timestamp.fromDate(signedAt),
          'registrado_em': FieldValue.serverTimestamp(),
          'registrado_por_uid': user.uid,
        });
        transaction.update(interaction, {
          'contrato_id': contract.id,
          'contrato_assinado': true,
          'contrato_razao_social': data['razao_social'],
          'contrato_cnpj': data['cnpj'],
          'contrato_tema': [
            ...selectedThemes,
            if (data['personalizada']!.isNotEmpty) data['personalizada']!,
          ].join('; '),
          'contrato_total_centavos': _total,
          'contrato_assinado_em': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) return;
      setState(() {
        _signed = true;
        _contractId = contract.id;
        _savedPdf = bytes;
      });
      _message(
        'Contrato assinado e salvo. A cópia está disponível para compartilhar.',
      );
    } catch (error) {
      _message('Contrato não salvo: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final id = _contractId;
      final interactionId = widget.interacao['doc_id'] as String?;
      if (id == null || interactionId == null) {
        throw StateError(
          'Contrato legado sem PDF arquivado. Solicite a regularização do registro.',
        );
      }
      var bytes = _savedPdf;
      if (bytes == null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('interacoes')
            .doc(interactionId)
            .collection('contratos')
            .doc(id)
            .get();
        bytes = (snapshot.data()?['pdf'] as Blob?)?.bytes;
      }
      if (bytes == null)
        throw StateError('A cópia do contrato não foi encontrada.');
      _savedPdf = bytes;
      final shared = await Printing.sharePdf(
        bytes: bytes,
        filename: 'termo_$id.pdf',
      );
      if (!shared)
        _message('Compartilhamento não concluído. A cópia continua salva.');
    } catch (error) {
      _message('Não foi possível compartilhar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateField(String key, String? input) {
    final value = input?.trim() ?? '';
    if (_requiredFields.contains(key) && value.isEmpty)
      return 'Campo obrigatório';
    if (value.isEmpty) return null;
    if ((key == 'cnpj' || key == 'emitente_cnpj') &&
        !ContractDocument.validCnpj(value)) {
      return 'Informe um CNPJ válido';
    }
    if (key == 'email' &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Informe um e-mail válido';
    }
    if (key == 'fone' || key == 'fone_palestrante') {
      final length = value.replaceAll(RegExp(r'\D'), '').length;
      if (length < 10 || length > 13) return 'Informe DDD e telefone';
    }
    if (key == 'cep' && !RegExp(r'^\d{5}-?\d{3}$').hasMatch(value))
      return 'CEP inválido';
    if (key == 'estado' && !_states.containsKey(value.toUpperCase()))
      return 'UF inválida';
    if (_moneyFields.contains(key) && ContractDocument.cents(value) == null) {
      return 'Valor inválido. Ex.: 1500,00';
    }
    if (_countFields.contains(key)) {
      final count = int.tryParse(value);
      if (!RegExp(r'^\d+$').hasMatch(value) ||
          count == null ||
          count > 1000000 ||
          (key == 'participantes' && count == 0)) {
        return 'Quantidade inválida';
      }
    }
    return null;
  }

  Widget _field(String key, {double? width}) {
    if (key == 'estado') {
      final state = _controllers[key]!.text.toUpperCase();
      return SizedBox(
        width: width,
        child: DropdownButtonFormField<String>(
          key: ValueKey('estado_$state'),
          initialValue: _states.containsKey(state) ? state : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Estado / UF *',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final entry in _states.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text('${entry.key} - ${entry.value}'),
              ),
          ],
          onChanged: _lookingUp
              ? null
              : (value) => _controllers[key]!.text = value ?? '',
          validator: (value) => _validateField(key, value),
        ),
      );
    }
    final money = _moneyFields.contains(key);
    final count = _countFields.contains(key);
    return SizedBox(
      width: width,
      child: TextFormField(
        key: ValueKey('contract_$key'),
        controller: _controllers[key],
        readOnly: _lookingUp,
        onChanged: key == 'cnpj' ? _onCnpjInput : null,
        onFieldSubmitted: key == 'cnpj' ? (_) => _lookupCompany() : null,
        maxLength: key == 'condicoes' ? 2000 : 160,
        minLines: key == 'condicoes' ? 3 : 1,
        maxLines: key == 'condicoes' ? 6 : 1,
        keyboardType: money
            ? const TextInputType.numberWithOptions(decimal: true)
            : count
            ? TextInputType.number
            : key == 'email'
            ? TextInputType.emailAddress
            : key.startsWith('fone')
            ? TextInputType.phone
            : TextInputType.text,
        textCapitalization: key == 'estado'
            ? TextCapitalization.characters
            : TextCapitalization.none,
        decoration: InputDecoration(
          labelText:
              '${ContractDocument.fields[key]}${_requiredFields.contains(key) ? " *" : ""}',
          prefixText: money ? 'R\$ ' : null,
          border: const OutlineInputBorder(),
          counterText: '',
          errorText: key == 'cnpj' ? _lookupError : null,
          suffixIcon: key != 'cnpj'
              ? null
              : _lookingUp
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Consultar CNPJ na BrasilAPI',
                  onPressed: _busy ? null : _lookupCompany,
                  icon: const Icon(Icons.search),
                ),
        ),
        validator: (value) => _validateField(key, value),
      ),
    );
  }

  Widget _fields(List<String> keys) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 620
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [for (final key in keys) _field(key, width: width)],
      );
    },
  );

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 16),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Widget _options(List<String> options) => Column(
    children: [
      for (final option in options)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(option),
          value: _selectedThemes.contains(option),
          onChanged: (selected) => setState(() {
            _invalidateAgreement();
            if (selected == true) {
              _selectedThemes.add(option);
            } else {
              _selectedThemes.remove(option);
            }
          }),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Termo de responsabilidade',
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: SafeArea(child: _signed ? _signedView() : _form()),
    ),
  );

  Widget _signedView() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Contrato assinado',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.interacao['empresa_nome'] ?? ''}',
            textAlign: TextAlign.center,
          ),
          if (_contractId != null)
            SelectableText(
              'Registro: $_contractId',
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: const Icon(Icons.ios_share),
            label: Text(
              _busy ? 'Abrindo documento...' : 'Compartilhar PDF assinado',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _form() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: AbsorbPointer(
          absorbing: _busy,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'INSTITUTO VIDA',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Text('& Consultores Associados'),
                const Text('Gestão empresarial, união, liderança e benefícios'),
                _heading('Identificação do Instituto'),
                _field('emitente_cnpj'),
                _heading('Cadastro da empresa contratante'),
                _fields([
                  'razao_social',
                  'nome_fantasia',
                  'cnpj',
                  'inscricao_estadual',
                  'email',
                  'fone',
                  'contato',
                  'departamento',
                  'endereco',
                  'numero',
                  'bairro',
                  'cep',
                  'cidade',
                  'estado',
                ]),
                _heading('Palestra'),
                _options(ContractDocument.lectures),
                _heading('Temas gerais e adaptáveis'),
                _options(ContractDocument.themes),
                const SizedBox(height: 16),
                _field('personalizada'),
                _heading('Pacote e valores'),
                _fields(_moneyFields),
                const SizedBox(height: 16),
                Text(
                  'Total: ${ContractDocument.money(_total)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _heading('Agenda'),
                Text(
                  _event == null
                      ? 'Agenda pendente'
                      : 'Data e hora: ${ContractDocument.dateTime(_event!)}',
                ),
                Text('Duração: $_duration minutos'),
                const SizedBox(height: 16),
                _fields([
                  'efetivos',
                  'terceirizados',
                  'participantes',
                  'palestrante',
                  'fone_palestrante',
                  'consultor',
                ]),
                _heading('Condições e responsabilidades'),
                for (
                  var index = 0;
                  index < ContractDocument.clauses.length;
                  index++
                )
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${index + 1}. ${ContractDocument.clauses[index]}',
                    ),
                  ),
                _field('condicoes'),
                _heading('Autorização opcional'),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _allowImage,
                  title: const Text(ContractDocument.imageConsent),
                  onChanged: (value) => setState(() {
                    _invalidateAgreement();
                    _allowImage = value ?? false;
                  }),
                ),
                _heading('Representante da contratante'),
                _fields(['signatario', 'cargo']),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _accepted,
                  title: const Text(ContractDocument.acceptance),
                  onChanged: (value) =>
                      setState(() => _accepted = value ?? false),
                ),
                _heading('Assinatura da contratante'),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Signature(
                    controller: _signatureController,
                    height: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _signatureController.clear,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar assinatura'),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _preview,
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Revisar PDF'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.draw),
                  label: Text(
                    _busy ? 'Processando...' : 'Confirmar assinatura e salvar',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
