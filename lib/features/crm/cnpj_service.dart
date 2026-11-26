import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'contract_document.dart';

class CnpjLookupException implements Exception {
  final String message;

  const CnpjLookupException(this.message);

  @override
  String toString() => message;
}

class CnpjService {
  final http.Client? _client;
  final Duration timeout;

  const CnpjService({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client;

  Future<Map<String, String>> lookup(String input) async {
    if (!ContractDocument.validCnpj(input)) {
      throw const CnpjLookupException('Informe um CNPJ válido para consultar.');
    }
    final cnpj = ContractDocument.normalizeCnpj(input);
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            Uri.https('brasilapi.com.br', '/api/cnpj/v1/$cnpj'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);
      if (response.statusCode == 404) {
        throw const CnpjLookupException(
          'CNPJ não encontrado na base consultada.',
        );
      }
      if (response.statusCode == 400) {
        throw const CnpjLookupException(
          'O serviço não reconheceu este CNPJ. Confira o número.',
        );
      }
      if (response.statusCode == 429) {
        throw const CnpjLookupException(
          'Limite de consultas atingido. Tente novamente mais tarde.',
        );
      }
      if (response.statusCode != 200) {
        throw const CnpjLookupException(
          'Consulta indisponível. Tente novamente mais tarde ou preencha manualmente.',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      String text(String key) {
        final value = decoded[key];
        return value is String ? value.trim() : '';
      }

      if (ContractDocument.normalizeCnpj(text('cnpj')) != cnpj ||
          text('razao_social').isEmpty) {
        throw const FormatException();
      }
      final street = [
        text('descricao_tipo_de_logradouro'),
        text('logradouro'),
      ].where((part) => part.isNotEmpty).join(' ');
      final fields = <String, String>{
        'razao_social': text('razao_social'),
        'nome_fantasia': text('nome_fantasia'),
        'endereco': street,
        'numero': text('numero'),
        'bairro': text('bairro'),
        'cep': text('cep').replaceAll(RegExp(r'[^0-9]'), ''),
        'cidade': text('municipio'),
        'estado': text('uf').toUpperCase(),
        'email': text('email'),
        'fone': text('ddd_telefone_1').isNotEmpty
            ? text('ddd_telefone_1')
            : text('ddd_telefone_2'),
      };
      fields.removeWhere((key, value) => value.isEmpty);
      return fields;
    } on TimeoutException {
      throw const CnpjLookupException(
        'A consulta demorou demais. Tente novamente ou preencha manualmente.',
      );
    } on http.ClientException {
      throw const CnpjLookupException(
        'Não foi possível conectar à consulta. Verifique a internet ou preencha manualmente.',
      );
    } on FormatException {
      throw const CnpjLookupException(
        'O serviço retornou dados inválidos. Preencha manualmente ou tente novamente.',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
