# 🎨 Guia Visual do CRM com Novo Sistema de Tags

## 📊 Layout da Tela Principal

```
╔════════════════════════════════════════════════════════════════════════════════╗
║ UL Business                                                      👤  Profile   ║
║                                                                                 ║
║ Dashboard | CRM | Agenda | Árvore                                              ║
╠════════════════════════════════════════════════════════════════════════════════╣
║                                                                                 ║
║  🔍 Filtrar por empresa ou agendista...                                        ║
║                                                                                 ║
║ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
║ │● Em Prosp. 2 │ │● Aguardando 0│ │● Agendada 2  │ │● Recusada 0  │ │● Palestra  0 │ │● Finalizado 1│
║ ├──────────────┤ ├──────────────┤ ├──────────────┤ ├──────────────┤ ├──────────────┤ ├──────────────┤
║ │              │ │              │ │              │ │              │ │              │ │              │
║ │ Arraste um   │ │ Arraste um   │ │ ┌──────────┐ │ │              │ │              │ │ ┌──────────┐│
║ │ cartão aqui  │ │ cartão aqui  │ │ │ Empresa1 │ │ │              │ │              │ │ │ Empresa5 ││
║ │              │ │              │ │ ├──────────┤ │ │              │ │              │ │ ├──────────┤│
║ │              │ │              │ │ │ Roberto  │ │ │              │ │              │ │ │ João     ││
║ │              │ │              │ │ ├──────────┤ │ │              │ │              │ │ ├──────────┤│
║ │              │ │              │ │ │ 📅 20/11 │ │ │              │ │              │ │ │ 📅 15/11 ││
║ │              │ │              │ │ │ 15:00    │ │ │              │ │              │ │ │ 10:00    ││
║ │              │ │              │ │ │ (90 min) │ │ │              │ │              │ │ │ (60 min) ││
║ │              │ │              │ │ ├──────────┤ │ │              │ │              │ │ ├──────────┤│
║ │              │ │              │ │ │ R$ 1500  │ │ │              │ │              │ │ │ R$ 2000  ││
║ │              │ │              │ │ ├──────────┤ │ │              │ │              │ │ ├──────────┤│
║ │              │ │              │ │ │[Tags]  ⋮ │ │ │              │ │              │ │ │[Tags]  ⋮ ││
║ │              │ │              │ │ │          │ │ │              │ │              │ │ │          ││
║ │              │ │              │ │ ├─────────-│ │ │              │ │              │ │ ├──────────┤│
║ │              │ │              │ │ │Gerar     │ │ │              │ │              │ │ │Gerar     ││
║ │              │ │              │ │ │Contrato  │ │ │              │ │              │ │ │Contrato  ││
║ │              │ │              │ │ └──────────┘ │ │              │ │              │ │ └──────────┘│
║ │              │ │              │ │              │ │              │ │              │ │              │
║ │              │ │              │ │ ┌──────────┐ │ │              │ │              │ │              │
║ │              │ │              │ │ │ Empresa2 │ │ │              │ │              │ │              │
║ │              │ │              │ │ ├──────────┤ │ │              │ │              │ │              │
║ │              │ │              │ │ │ Maria    │ │ │              │ │              │ │              │
║ │              │ │              │ │ ├──────────┤ │ │              │ │              │ │              │
║ │              │ │              │ │ │[Tags]  ⋮ │ │ │              │ │              │ │              │
║ │              │ │              │ │ └──────────┘ │ │              │ │              │ │              │
║ │              │ │              │ │              │ │              │ │              │ │              │
║ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
║
║                                                                              ⊕ (Novo Card)
╚════════════════════════════════════════════════════════════════════════════════╝
```

## 🏷️ Detalhe do Card com Tags

### Antes (Sem Tags)
```
┌─────────────────────────────┐
│ Empresa Name           ⋯    │
├─────────────────────────────┤
│ Agendista Name              │
│ 📅 20/11 às 15:00 (90 min)  │
│ R$ 1500                     │
│ Notas sobre a empresa...    │
│                             │
│ ┌───────────────────────┐   │
│ │  Gerar Contrato       │   │
│ └───────────────────────┘   │
└─────────────────────────────┘
```

### Depois (Com Tags)
```
┌──────────────────────────────────┐
│ Empresa Name                  ⋯  │
├──────────────────────────────────┤
│ Agendista Name                   │
│ 📅 20/11 às 15:00 (90 min)      │
│ R$ 1500                          │
│ Notas sobre a empresa...         │
│                                  │
│ [Em Prospecção] [Agendada] [🔚]  │
│    ↑ Long Press para remover     │
│                                  │
│ ┌──────────────────────────────┐ │
│ │   Gerar Contrato             │ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

## 🏷️ Cores e Significado das Tags

| Tag | Cor | Significa |
|-----|-----|-----------|
| Em Prospecção | 🔵 Azul Cinzento | Empresa ainda em prospecção |
| Aguardando | 🟡 Âmbar | Aguardando resposta |
| Agendada | 🟢 Verde | Palestra/Reunião agendada |
| Recusada | 🔴 Vermelho | Empresa recusou proposta |
| Palestra Realizada & Acompanhamento | 🟣 Roxo | ✨ **NOVO** - Em acompanhamento |
| Finalizado | 🔵 Teal/Azul Claro | ✨ **NOVO** - Processo finalizado |

## 🎯 Fluxo Completo de um Card

### Exemplo: Empresa ABC

```
INÍCIO
  ↓
1. Novo Card criado em "Em Prospecção"
   Tags: []
  ↓
2. Movido para "Aguardando" (Drag & Drop)
   Tags: ["Em Prospecção_17000001"]
  ↓
3. Movido para "Agendada" via Menu
   Tags: ["Em Prospecção_17000001", "Aguardando_17000002"]
  ↓
4. Palestra realizada, movido para "Palestra Realizada & Acompanhamento"
   Tags: ["Em Prospecção_17000001", "Aguardando_17000002", "Agendada_17000003"]
  ↓
5. Acompanhamento concluído, movido para "Finalizado"
   Tags: [
      "Em Prospecção_17000001",
      "Aguardando_17000002",
      "Agendada_17000003",
      "Palestra Realizada & Acompanhamento_17000004"
   ]
  ↓
FIM (Admin pode remover tags conforme necessário)
```

## 📱 Interações do Usuário

### ✋ Movimentação 1: Drag & Drop
```
Usuário arrasta card para coluna "Palestra Realizada & Acompanhamento"
        ↓
Firestore atualiza: status = "Palestra Realizada & Acompanhamento"
        ↓
Nova tag adicionada: "Palestra Realizada & Acompanhamento_<timestamp>"
        ↓
Card é atualizado na tela com nova tag visível
```

### ✋ Movimentação 2: Menu de Contexto
```
Usuário clica em ⋯ (três pontinhos)
        ↓
Menu aparece com opções: "Mover para..."
        ↓
Usuário seleciona "Mover para Finalizado"
        ↓
Firestore atualiza: status = "Finalizado"
        ↓
Nova tag adicionada: "Finalizado_<timestamp>"
        ↓
Card é atualizado na tela com nova tag visível
```

### ✋ Remoção de Tag
```
Usuário mantém pressionado (Long Press) sobre tag [Em Prospecção]
        ↓
Diálogo de confirmação aparece:
"Tem certeza que deseja remover a tag 'Em Prospecção'?"
        ↓
Usuário clica "Remover"
        ↓
Firestore atualiza: tags = [...sem "Em Prospecção_17000001"...]
        ↓
Card é atualizado e tag desaparece
```

## 🎯 Casos de Uso Práticos

### Caso 1: Rastrear Empresas em Acompanhamento
```
Manager quer saber quais empresas estão em acompanhamento após a palestra
  ↓
Clica na coluna "Palestra Realizada & Acompanhamento"
  ↓
Vê todos os cards que tiveram a tag "Palestra Realizada & Acompanhamento"
  ↓
Pode analisar notas e histórico de movimentação pelas tags
```

### Caso 2: Revisar Histórico de Movimentação
```
Admin quer entender por onde passou um determinado card
  ↓
Abre o card
  ↓
Vê as tags: [Em Prospecção] [Aguardando] [Agendada] [Recusada] [Agendada] [Finalizado]
  ↓
Percebe que a empresa foi recusada mas depois teve segunda chance (Agendada novamente)
```

### Caso 3: Remover Movimentação Errada
```
Admin moveu card para coluna errada por acidente
  ↓
Clica long press na tag incorreta
  ↓
Clica "Remover"
  ↓
Tag desaparece, mas o status atual permanece correto
```

## 📊 Relatório Visual (Exemplo)

```
Empresa: ABC Corp
Agendista: Roberto Almeida
Valor: R$ 2.500

HISTÓRICO DE MOVIMENTAÇÃO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 10/11 → [Em Prospecção]
   └─ Novo contato prospectado

📅 12/11 → [Aguardando]
   └─ Aguardando confirmação do interesse

📅 15/11 → [Agendada]
   └─ Palestra agendada para 20/11

📅 20/11 → [Agendada] (mantido)
   └─ Palestra realizada com sucesso

📅 20/11 → [Palestra Realizada & Acompanhamento] ✨ NOVO
   └─ Iniciando período de acompanhamento

📅 25/11 → [Finalizado] ✨ NOVO
   └─ Processo finalizado com contrato assinado

Tags Presentes:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Em Prospecção] [Aguardando] [Agendada] [Palestra R...] [Finalizado]
```

---

**Esta é a visão completa do novo sistema de CRM com Tags!** ✨
