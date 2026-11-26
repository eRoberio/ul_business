import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ContractDocument {
  static const version = '1.0';

  static const lectures = [
    'Gestão em qualidade de vida no trabalho',
    'Gente, gestores e empreendedores - O profissional do futuro',
    'Alta performance, relacionamento e gestão de tempo',
  ];

  static const themes = [
    'Gerenciamento inteligente - Estresse positivo e negativo e sua influência na saúde, no comportamento e na atitude',
    'Automotivação e estresse',
    'O perfil do funcionário de sucesso',
    'Inteligências emocionais nas relações interpessoais',
    'Atividade física: sinônimo de segurança',
    'Saúde: alcoolismo e tabagismo - Impacto no trabalho',
  ];

  static const clauses = [
    'A contratante disponibilizará os participantes informados na agenda e assegurará a presença do gestor de RH ou de responsável pela empresa durante a palestra.',
    'Ao final da palestra poderá ser apresentado material didático para aquisição livre e facultativa pelos funcionários. A compra não é condição de participação.',
    'Qualquer desconto em folha relativo a materiais dependerá de autorização individual, prévia e específica do funcionário e da observância da legislação aplicável. Este termo não autoriza descontos nem substitui essa autorização. Valores, parcelas e repasses deverão constar de instrumento próprio.',
    'Os valores devidos pela empresa são exclusivamente os discriminados neste termo. Quando o total for zero, a palestra não terá custo para a contratante. Forma e prazo de pagamento, infraestrutura e condições de cancelamento ou remarcação seguem as condições acordadas abaixo.',
    'Os dados deste documento serão utilizados para formalização, execução e registro da contratação. A contratante confirma que o signatário possui poderes para representá-la. A guarda e o compartilhamento deverão ser restritos às partes e aos responsáveis autorizados.',
    'A autorização opcional de uso do nome e logotipo da empresa não abrange imagem ou voz de funcionários. A divulgação de pessoas identificáveis dependerá de autorização própria e da observância da legislação aplicável.',
  ];

  static const imageConsent =
      'Autorizo, de forma opcional, o uso do nome e logotipo da empresa pelo Instituto Vida em registros desta palestra no site e nas redes sociais institucionais. Esta autorização não inclui imagem ou voz dos participantes e pode ser revogada para usos futuros mediante solicitação ao Instituto.';

  static const acceptance =
      'Confirmo meus poderes de representação, a conferência dos dados, valores e agenda, e declaro que li e aceito as condições deste termo.';

  static const fields = <String, String>{
    'emitente_cnpj': 'CNPJ do Instituto Vida',
    'razao_social': 'Razão social',
    'nome_fantasia': 'Nome fantasia',
    'cnpj': 'CNPJ da contratante',
    'inscricao_estadual': 'Inscrição estadual / isento',
    'email': 'E-mail',
    'fone': 'Telefone',
    'contato': 'Contato (nome)',
    'departamento': 'Departamento',
    'endereco': 'Endereço',
    'numero': 'Número',
    'bairro': 'Bairro',
    'cep': 'CEP',
    'cidade': 'Cidade',
    'estado': 'UF',
    'personalizada': 'Palestra personalizada',
    'valor_palestra': 'Valor da palestra',
    'valor_viagem': 'Despesas de viagem',
    'valor_cadastro': 'Despesas cadastrais',
    'efetivos': 'Funcionários efetivos',
    'terceirizados': 'Terceirizados',
    'participantes': 'Participantes previstos',
    'palestrante': 'Palestrante',
    'fone_palestrante': 'Telefone do palestrante',
    'consultor': 'Consultor / agendista',
    'condicoes': 'Pagamento, infraestrutura e cancelamento / remarcação',
    'signatario': 'Nome completo do signatário',
    'cargo': 'Cargo / função do signatário',
  };

  static int? cents(String input) {
    var value = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (value.isEmpty) return 0;
    if (value.contains(',')) {
      if (!RegExp(r'^\d{1,3}(\.\d{3})*,\d{1,2}$|^\d+,\d{1,2}$')
          .hasMatch(value)) {
        return null;
      }
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return null;
    }
    final parts = value.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null || whole > 99999999) return null;
    final decimal = parts.length == 1
        ? 0
        : int.parse(parts.last.padRight(2, '0'));
    return whole * 100 + decimal;
  }

  static String money(int cents) =>
      'R\$ ${(cents ~/ 100).toString()},${(cents % 100).toString().padLeft(2, '0')}';

  static String normalizeCnpj(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'[./\-\s]'), '');

  static bool validCnpj(String value) {
    final digits = normalizeCnpj(value);
    if (!RegExp(r'^[0-9A-Z]{12}[0-9]{2}$').hasMatch(digits) ||
        digits.split('').toSet().length == 1) {
      return false;
    }
    for (final length in [12, 13]) {
      var sum = 0;
      var weight = length - 7;
      for (var index = 0; index < length; index++) {
        sum += (digits.codeUnitAt(index) - 48) * weight;
        weight = weight == 2 ? 9 : weight - 1;
      }
      final remainder = sum % 11;
      if (int.parse(digits[length]) != (remainder < 2 ? 0 : 11 - remainder)) {
        return false;
      }
    }
    return true;
  }

  static String dateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static Future<Uint8List> generate({
    required String id,
    required Map<String, String> data,
    required List<String> selectedThemes,
    required DateTime event,
    required int duration,
    required DateTime signedAt,
    required bool allowImage,
    required Uint8List signature,
  }) async {
    final document = pw.Document();
    final total = [
      'valor_palestra',
      'valor_viagem',
      'valor_cadastro',
    ].fold<int>(0, (total, key) => total + (cents(data[key] ?? '') ?? 0));
    pw.Widget heading(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
    pw.Widget field(String key) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        '${fields[key]}: ${data[key]?.isNotEmpty == true ? data[key] : "Não informado"}',
      ),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.base().copyWith(
          defaultTextStyle: const pw.TextStyle(fontSize: 10),
        ),
        footer: (context) => pw.Text(
          'Termo $id | v$version | ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
        build: (context) => [
          pw.Text(
            'INSTITUTO VIDA & CONSULTORES ASSOCIADOS',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Gestão empresarial, união, liderança e benefícios'),
          field('emitente_cnpj'),
          pw.Text(
            'Rua João Marques Oliveira, 819 - Lauro de Freitas / BA - CEP 42700-000',
          ),
          heading('TERMO MÚTUO DE RESPONSABILIDADE'),
          pw.Text('Identificador: $id'),
          heading('CADASTRO DA EMPRESA CONTRATANTE'),
          for (final key in fields.keys.skip(1).take(14)) field(key),
          heading('PALESTRA E TEMAS'),
          for (final theme in selectedThemes) pw.Text('- $theme'),
          if (data['personalizada']?.isNotEmpty == true) field('personalizada'),
          heading('PACOTE E VALORES'),
          for (final key in [
            'valor_palestra',
            'valor_viagem',
            'valor_cadastro',
          ])
            pw.Text('${fields[key]}: ${money(cents(data[key] ?? '') ?? 0)}'),
          pw.Text(
            'TOTAL: ${money(total)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          heading('AGENDA'),
          pw.Text(
            'Data e hora local: ${dateTime(event)} | Duração: $duration minutos',
          ),
          for (final key in [
            'efetivos',
            'terceirizados',
            'participantes',
            'palestrante',
            'fone_palestrante',
            'consultor',
          ])
            field(key),
          pw.Text(
            'Total de funcionários: ${(int.tryParse(data['efetivos'] ?? '') ?? 0) + (int.tryParse(data['terceirizados'] ?? '') ?? 0)}',
          ),
          heading('CONDIÇÕES E RESPONSABILIDADES'),
          for (var index = 0; index < clauses.length; index++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text('${index + 1}. ${clauses[index]}'),
            ),
          field('condicoes'),
          heading('AUTORIZAÇÃO OPCIONAL'),
          pw.Text(
            'Uso do nome e logotipo: ${allowImage ? "AUTORIZADO" : "NÃO AUTORIZADO"}',
          ),
          pw.Text(imageConsent),
          heading('ACEITE E ASSINATURA'),
          pw.Text(acceptance),
          field('signatario'),
          field('cargo'),
          pw.Text(
            'Registro de aceite (UTC): ${signedAt.toUtc().toIso8601String()}',
          ),
          pw.Image(
            pw.MemoryImage(signature),
            height: 85,
            width: 260,
            fit: pw.BoxFit.contain,
          ),
          pw.Text(
            'Assinatura eletrônica manuscrita do representante da contratante.',
          ),
        ],
      ),
    );
    return document.save();
  }
}
