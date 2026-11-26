// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:signature/signature.dart';

import 'package:ul_business/features/crm/cnpj_service.dart';
import 'package:ul_business/features/crm/contract_document.dart';
import 'package:ul_business/features/crm/contract_screen.dart';
import 'package:ul_business/features/timeline/time_tree_screen.dart';

void main() {
  test(
    'CNPJ lookup maps company data without inventing missing contacts',
    () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://brasilapi.com.br/api/cnpj/v1/11222333000181',
        );
        return http.Response(
          jsonEncode({
            'cnpj': '11222333000181',
            'razao_social': 'Empresa Educação',
            'nome_fantasia': 'Vida',
            'descricao_tipo_de_logradouro': 'RUA',
            'logradouro': 'DAS FLORES',
            'numero': '12',
            'bairro': 'CENTRO',
            'municipio': 'SALVADOR',
            'uf': 'BA',
            'cep': '40000-000',
            'email': null,
            'ddd_telefone_1': '',
            'ddd_telefone_2': '7133334444',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final data = await CnpjService(client: client)
          .lookup('11.222.333/0001-81');
      expect(data['razao_social'], 'Empresa Educação');
      expect(data['endereco'], 'RUA DAS FLORES');
      expect(data['cep'], '40000000');
      expect(data['estado'], 'BA');
      expect(data['fone'], '7133334444');
      expect(data.containsKey('email'), isFalse);
    },
  );

  test(
    'CNPJ lookup rejects invalid numbers without making a request',
    () async {
      final client = MockClient(
        (_) async => throw StateError('Unexpected HTTP request'),
      );
      addTearDown(client.close);
      await expectLater(
        CnpjService(client: client).lookup('123'),
        throwsA(isA<CnpjLookupException>()),
      );
    },
  );

  test('CNPJ lookup handles errors and mismatched company responses', () async {
    for (final status in [400, 404, 429, 503]) {
      final client = MockClient((_) async => http.Response('{}', status));
      try {
        await expectLater(
          CnpjService(client: client).lookup('11222333000181'),
          throwsA(isA<CnpjLookupException>()),
        );
      } finally {
        client.close();
      }
    }
    final client = MockClient(
      (_) async => http.Response(
        '{"cnpj":"99999999999999","razao_social":"Outra"}',
        200,
      ),
    );
    addTearDown(client.close);
    await expectLater(
      CnpjService(client: client).lookup('11222333000181'),
      throwsA(isA<CnpjLookupException>()),
    );
  });

  for (final size in [const Size(320, 740), const Size(1280, 900)]) {
    testWidgets('CNPJ auto-fill updates company and state at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(
          jsonEncode({
            'cnpj': '11222333000181',
            'razao_social': 'Empresa consultada',
            'nome_fantasia': 'Vida',
            'municipio': 'SALVADOR',
            'uf': 'BA',
            'logradouro': 'DAS FLORES',
            'numero': '12',
            'cep': '40000000',
          }),
          200,
        );
      });
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ContractScreen(
            interacao: const {'empresa_nome': 'Nome inicial'},
            cnpjService: CnpjService(client: client),
          ),
        ),
      );
      final cnpj = find.byKey(const ValueKey('contract_cnpj'));
      await tester.ensureVisible(cnpj);
      await tester.enterText(cnpj, '11.222.333/0001-81');
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.text('Empresa consultada'), findsOneWidget);
      expect(find.text('SALVADOR'), findsOneWidget);
      final state = find.byType(DropdownButtonFormField<String>);
      expect(
        tester.widget<DropdownButtonFormField<String>>(state).initialValue,
        'BA',
      );
      await tester.ensureVisible(state);
      await tester.tap(state);
      await tester.pumpAndSettle();
      await tester.tap(find.text('AC - Acre').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<DropdownButtonFormField<String>>(state).initialValue,
        'AC',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('CNPJ lookup failure preserves manual entry and allows retry', (
    tester,
  ) async {
    final client = MockClient((_) async => http.Response('{}', 503));
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ContractScreen(
          interacao: const {'empresa_nome': 'Empresa manual'},
          cnpjService: CnpjService(client: client),
        ),
      ),
    );
    final cnpj = find.byKey(const ValueKey('contract_cnpj'));
    await tester.ensureVisible(cnpj);
    await tester.enterText(cnpj, '11.222.333/0001-81');
    await tester.tap(find.byTooltip('Consultar CNPJ na BrasilAPI'));
    await tester.pumpAndSettle();
    expect(find.text('Empresa manual'), findsOneWidget);
    expect(find.textContaining('Consulta indisponível.'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(cnpj).controller!.text,
      '11.222.333/0001-81',
    );
    final company = find.byKey(const ValueKey('contract_razao_social'));
    await tester.ensureVisible(company);
    await tester.enterText(company, 'Correção manual');
    await tester.pumpAndSettle();
    expect(find.text('Correção manual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Contract amounts use integer cents and reject invalid values', () {
    for (final entry in {
      '': 0,
      '0': 0,
      '0,01': 1,
      '12.5': 1250,
      '1500,50': 150050,
      '1.500,50': 150050,
      'R\$ 25,90': 2590,
    }.entries) {
      expect(ContractDocument.cents(entry.key), entry.value);
    }
    for (final value in ['-1', 'abc', '1,234', '1.2.3', '1.50,00', 'NaN']) {
      expect(ContractDocument.cents(value), isNull);
    }
    expect(ContractDocument.money(150050), 'R\$ 1500,50');
  });

  test('CNPJ validation checks both verification digits', () {
    expect(ContractDocument.validCnpj('11.222.333/0001-81'), isTrue);
    expect(ContractDocument.validCnpj('11222333000181'), isTrue);
    expect(ContractDocument.validCnpj('12.ABC.345/01DE-35'), isTrue);
    for (final value in ['', '00000000000000', '11.222.333/0001-82']) {
      expect(ContractDocument.validCnpj(value), isFalse);
    }
  });

  test(
    'Contract generates a paginated PDF with long conditions and signature',
    () async {
      final bytes = await ContractDocument.generate(
        id: 'teste-contrato',
        data: {
          for (final key in ContractDocument.fields.keys) key: 'Teste',
          'razao_social': 'Empresa de Educação e Saúde',
          'valor_palestra': '1500,50',
          'valor_viagem': '100,00',
          'valor_cadastro': '0',
          'condicoes': List.filled(
            20,
            'Pagamento à vista. Remarcação mediante acordo prévio.',
          ).join(' '),
        },
        selectedThemes: [
          ...ContractDocument.lectures,
          ...ContractDocument.themes,
        ],
        event: DateTime(2030, 5, 20, 10),
        duration: 60,
        signedAt: DateTime.utc(2030, 5, 1, 12),
        allowImage: false,
        signature: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
        ),
      );
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    },
  );

  for (final size in [const Size(320, 740), const Size(1280, 900)]) {
    testWidgets('Contract lays out and calculates totals at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: ContractScreen(
            interacao: {
              'empresa_nome': 'Empresa Teste',
              'valor': '1500,50',
              'agendista': 'Consultora',
              'data_evento': Timestamp.fromDate(DateTime(2030, 5, 20, 10)),
            },
          ),
        ),
      );
      expect(find.text('Empresa Teste'), findsOneWidget);
      expect(find.text('Total: R\$ 1500,50'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final travel = find.ancestor(
        of: find.text('Despesas de viagem'),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(travel);
      await tester.enterText(travel, '100,25');
      await tester.pumpAndSettle();
      expect(find.text('Total: R\$ 1600,75'), findsOneWidget);

      final acceptance = find.widgetWithText(
        CheckboxListTile,
        ContractDocument.acceptance,
      );
      final imageConsent = find.widgetWithText(
        CheckboxListTile,
        ContractDocument.imageConsent,
      );
      await tester.ensureVisible(acceptance);
      await tester.tap(acceptance);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(acceptance).value, isTrue);
      expect(tester.widget<CheckboxListTile>(imageConsent).value, isFalse);

      final signature = tester.widget<Signature>(find.byType(Signature));
      signature.controller.addPoint(
        Point(const Offset(10, 10), PointType.move, 1),
      );
      signature.controller.addPoint(
        Point(const Offset(80, 40), PointType.move, 1),
      );
      expect(signature.controller.isNotEmpty, isTrue);
      await tester.ensureVisible(travel);
      await tester.enterText(travel, '200,00');
      await tester.pumpAndSettle();
      expect(signature.controller.isEmpty, isTrue);
      expect(tester.widget<CheckboxListTile>(acceptance).value, isFalse);

      final save = find.text('Confirmar assinatura e salvar');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Campo obrigatório'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Signed contracts expose their saved copy instead of an editable form',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ContractScreen(
            interacao: {
              'empresa_nome': 'Empresa Teste',
              'contrato_assinado': true,
              'contrato_id': 'termo-123',
            },
          ),
        ),
      );
      expect(find.text('Contrato assinado'), findsOneWidget);
      expect(find.text('Compartilhar PDF assinado'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('Timeline lays out without exceptions at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: TimeTreeScreen()));
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Prospecção'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prospecção'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
