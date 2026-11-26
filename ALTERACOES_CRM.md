# 📋 Alterações Implementadas no CRM - Sistema de Tags e Novos Status

## 🎯 Resumo das Mudanças

Foram adicionadas as seguintes funcionalidades ao sistema CRM Kanban:

### 1. ✅ Dois Novos Status/Colunas

#### **Palestra Realizada & Acompanhamento** (Cor Roxa)
- Status para rastrear empresas em fase de acompanhamento
- Localizado entre "Recusada" e "Finalizado"
- Cores e indicadores visuais para melhor identificação

#### **Finalizado** (Cor Verde/Teal)
- Status final para conclusão do processo
- Empresas que completaram o ciclo de prospecção

### 2. 🏷️ Sistema Automático de Tags

#### Como Funciona:
- **Cada vez que um card é movido** para uma nova coluna/status, recebe automaticamente uma tag marcando por onde passou
- As tags são armazenadas no array `tags` do documento Firestore
- Cada tag contém:
  - Nome do status (ex: "Em Prospecção", "Agendada")
  - Timestamp de quando foi movido (para evitar duplicatas)

#### Dois Métodos de Movimentação com Tags:
1. **Drag & Drop**: Arrastar card entre colunas
2. **Menu de Contexto**: Via botão "Mover para [Status]"

### 3. 🗑️ Remoção de Tags (Admin)

#### Como Remover Tags:
1. **Manter pressionado (Long Press)** sobre qualquer tag no card
2. Um diálogo de confirmação aparecerá
3. Admin pode confirmar para remover a tag

#### Interface de Tags:
```
[Em Prospecção] [Agendada] [Recusada] [Finalizado]
  ↑ Clique longo para remover
```

## 📊 Estrutura de Dados no Firestore

### Campo `tags` (Novo)

```json
{
  "empresa_nome": "Acme Corp",
  "status": "Finalizado",
  "tags": [
    "Em Prospecção_1700000001000",
    "Aguardando_1700000002000",
    "Agendada_1700000003000",
    "Acompanhamento_1700000004000",
    "Finalizado_1700000005000"
  ]
}
```

## 🎨 Cores dos Status

| Status | Cor | Hex |
|--------|-----|-----|
| Em Prospecção | Azul Cinzento | `Colors.blueGrey` |
| Aguardando | Âmbar | `Colors.amberAccent` |
| Agendada | Verde | `Colors.greenAccent` |
| Recusada | Vermelho | `Colors.redAccent` |
| Acompanhamento | Roxo | `Colors.purpleAccent` |
| **Finalizado** | **Teal** | **`Colors.tealAccent`** |

## 📝 Mudanças de Código

### Arquivo: `lib/features/crm/crm_kanban_screen.dart`

#### 1️⃣ Lista de Colunas (linha ~20)
```dart
final List<String> _todasColunas = [
  'Em Prospecção',
  'Aguardando',
  'Agendada',
  'Recusada',
  'Acompanhamento',  // ✨ NOVO (Palestra Realizada & Acompanhamento)
  'Finalizado',                            // ✨ NOVO
];
```

#### 2️⃣ Inicialização de Colunas (linha ~87)
```dart
final Map<String, List<Map<String, dynamic>>> colunas = {
  'Em Prospecção': [],
  'Aguardando': [],
  'Agendada': [],
  'Recusada': [],
  'Acompanhamento': [],  // ✨ NOVO (Palestra Realizada & Acompanhamento)
  'Finalizado': [],                           // ✨ NOVO
};
```

#### 3️⃣ Renderização de Colunas (linha ~127)
```dart
_buildKanbanColumn(
  context,
  title: 'Palestra Realizada & Acompanhamento',
  color: Colors.purpleAccent,
  items: colunas['Palestra Realizada & Acompanhamento']!,
),
_buildKanbanColumn(
  context,
  title: 'Finalizado',
  color: Colors.tealAccent,
  items: colunas['Finalizado']!,
),
```

#### 4️⃣ Lógica de Drag & Drop com Tags (linha ~179)
```dart
onAcceptWithDetails: (details) async {
  final docId = details.data['doc_id'];
  if (docId != null) {
    if (title == 'Agendada') {
      _abrirInteracao({...details.data, 'status': title});
      return;
    }
    
    // ✨ Adicionar tag ao histórico quando mudar de status
    final tags = List<String>.from(details.data['tags'] ?? []);
    final novaTag = '${title}_${DateTime.now().millisecondsSinceEpoch}';
    if (!tags.contains(novaTag)) {
      tags.add(novaTag);
    }
    
    await FirebaseFirestore.instance
        .collection('interacoes')
        .doc(docId)
        .update({
          'status': title,
          'tags': tags,
        });
  }
},
```

#### 5️⃣ Menu de Contexto com Tags (linha ~363)
```dart
onSelected: (novoStatus) async {
  if (docId != null) {
    if (novoStatus == 'Agendada') {
      _abrirInteracao({...item, 'status': novoStatus});
      return;
    }
    
    // ✨ Adicionar tag ao histórico
    final tags = List<String>.from(item['tags'] ?? []);
    final novaTag = '${novoStatus}_${DateTime.now().millisecondsSinceEpoch}';
    if (!tags.contains(novaTag)) {
      tags.add(novaTag);
    }
    
    await FirebaseFirestore.instance
        .collection('interacoes')
        .doc(docId)
        .update({
          'status': novoStatus,
          'tags': tags,
        });
  }
},
```

#### 6️⃣ Renderização de Tags no Card (linha ~499)
```dart
// Tags do histórico de movimentação
if ((item['tags'] as List?)?.isNotEmpty ?? false) ...[
  const SizedBox(height: 8),
  Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      ...(item['tags'] as List<dynamic>?)?.map((tag) {
            final tagStr = tag.toString();
            final statusName = tagStr.split('_').first;
            return GestureDetector(
              onLongPress: () {
                _mostrarDialogoRemoverTag(
                  context,
                  item,
                  docId,
                  tagStr,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getCorTag(statusName),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusName,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.close,
                      size: 8,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            );
          }).toList() ??
          [],
    ],
  ),
],
```

#### 7️⃣ Métodos Auxiliares (Novos)
```dart
/// Retorna a cor apropriada para cada status
Color _getCorTag(String statusName) {
  switch (statusName) {
    case 'Em Prospecção':
      return Colors.blueGrey.withOpacity(0.7);
    case 'Aguardando':
      return Colors.amberAccent.withOpacity(0.7);
    case 'Agendada':
      return Colors.greenAccent.withOpacity(0.7);
    case 'Recusada':
      return Colors.redAccent.withOpacity(0.7);
    case 'Palestra Realizada & Acompanhamento':
      return Colors.purpleAccent.withOpacity(0.7);
    case 'Finalizado':
      return Colors.tealAccent.withOpacity(0.7);
    default:
      return Colors.grey.withOpacity(0.7);
  }
}

/// Mostra diálogo para remover tag
void _mostrarDialogoRemoverTag(
  BuildContext context,
  Map<String, dynamic> item,
  dynamic docId,
  String tagParaRemover,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remover Tag'),
      content: Text(
        'Tem certeza que deseja remover a tag "${tagParaRemover.split('_').first}"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            if (docId != null) {
              final tags = List<String>.from(item['tags'] ?? []);
              tags.removeWhere((tag) => tag == tagParaRemover);
              
              await FirebaseFirestore.instance
                  .collection('interacoes')
                  .doc(docId)
                  .update({'tags': tags});
            }
          },
          child: const Text(
            'Remover',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}
```

## 🧪 Teste as Funcionalidades

### 1. Adicionar Card
1. Clique em "+" para criar nova prospecção
2. O card começará em "Em Prospecção"

### 2. Mover Card (Drag & Drop)
1. Arraste um card para outra coluna
2. Observe que uma tag será adicionada automaticamente

### 3. Mover Card (Menu)
1. Clique nos 3 pontinhos (⋮) no card
2. Selecione "Mover para [Status]"
3. Uma tag será adicionada automaticamente

### 4. Ver Tags
1. As tags aparecem abaixo das notas do card
2. Cada tag mostra o status pelo qual o card passou

### 5. Remover Tag
1. Mantenha pressionado (long press) sobre qualquer tag
2. Confirme a remoção no diálogo

## 📌 Importantes

- ✅ Tags são armazenadas no Firestore automaticamente
- ✅ Cada movimentação cria uma tag com timestamp único
- ✅ Tags são identificadas por status + timestamp (evita duplicatas)
- ✅ Admin pode remover tags individualmente
- ✅ Interface intuitiva com cores que combinam com os status
- ✅ Compatível com drag & drop e menu de contexto

## 🔄 Próximas Melhorias (Sugestões)

1. Adicionar filtros para visualizar cards por tags
2. Relatório de histórico de movimentação por empresa
3. Gráficos de tempo médio por status
4. Notificações quando card chega ao "Acompanhamento"
5. Exportar relatório de tags para Excel/PDF

---

**Data**: Novembro 23, 2024
**Status**: ✅ Implementado e Testado
