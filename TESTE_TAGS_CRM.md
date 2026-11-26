# 🧪 Teste das Funcionalidades - Sistema de Tags CRM

## ✅ Checklist de Testes

### 1. Teste de Novo Status
- [ ] Coluna "Palestra Realizada & Acompanhamento" aparece entre "Recusada" e "Finalizado"
- [ ] Coluna "Finalizado" aparece no final
- [ ] Ambas as colunas têm cores distintas (Roxo e Teal)
- [ ] Contador de items funciona em ambas as colunas
- [ ] Mensagem "Arraste um cartão aqui" aparece quando vazio

### 2. Teste de Tags Automáticas - Drag & Drop
- [ ] Criar novo card (vai para "Em Prospecção")
- [ ] Arrastar para "Aguardando"
  - [ ] Status muda para "Aguardando"
  - [ ] Tag "Aguardando" aparece no card
- [ ] Arrastar para "Agendada"
  - [ ] Status muda para "Agendada"
  - [ ] Agora mostra tags: [Aguardando] [Agendada]
- [ ] Arrastar para "Palestra Realizada & Acompanhamento"
  - [ ] Status muda corretamente
  - [ ] Nova tag aparece
- [ ] Arrastar para "Finalizado"
  - [ ] Status muda para "Finalizado"
  - [ ] Tag adiciona-se ao histórico

### 3. Teste de Tags Automáticas - Menu
- [ ] Clitar em ⋯ (três pontinhos) no card
- [ ] Menu aparece com opções "Mover para..."
- [ ] Selecionar "Mover para Recusada"
  - [ ] Status muda para "Recusada"
  - [ ] Tag "Recusada" é adicionada
- [ ] Via menu, mover para "Palestra Realizada & Acompanhamento"
  - [ ] Status muda
  - [ ] Tag adiciona-se
- [ ] Via menu, mover para "Finalizado"
  - [ ] Status muda
  - [ ] Tag adiciona-se

### 4. Teste de Cores de Tags
- [ ] Tag [Em Prospecção] aparece em Azul Cinzento
- [ ] Tag [Aguardando] aparece em Âmbar
- [ ] Tag [Agendada] aparece em Verde
- [ ] Tag [Recusada] aparece em Vermelho
- [ ] Tag [Palestra Realizada & Acompanhamento] aparece em Roxo
- [ ] Tag [Finalizado] aparece em Teal
- [ ] Todas as tags têm ícone X (close) para indicar interatividade

### 5. Teste de Remoção de Tags
- [ ] Long press (manter pressionado) em uma tag
- [ ] Diálogo de confirmação aparece:
  - [ ] Título: "Remover Tag"
  - [ ] Texto com nome da tag
  - [ ] Botão "Cancelar"
  - [ ] Botão "Remover"
- [ ] Clicar "Cancelar"
  - [ ] Diálogo fecha
  - [ ] Tag permanece no card
- [ ] Clicar "Remover"
  - [ ] Diálogo fecha
  - [ ] Tag desaparece do card
  - [ ] Firestore é atualizado sem a tag

### 6. Teste de Persistência
- [ ] Criar card e adicionar tags via movimentação
- [ ] Fechar e reabrir o app
- [ ] [ ] Card aparece com as mesmas tags
- [ ] Recarregar a página (web)
- [ ] Tags persistem

### 7. Teste de Duplicatas de Tags
- [ ] Mover card de "Aguardando" para "Agendada"
  - [ ] Tag "Agendada" aparece
- [ ] Mover imediatamente de volta para "Aguardando"
- [ ] Mover novamente para "Agendada" (rapidamente)
  - [ ] [ ] Deve haver apenas UMA tag "Agendada" (não duplicata)

### 8. Teste de Status Especial "Agendada"
- [ ] Mover card via Drag & Drop para "Agendada"
  - [ ] Deve abrir modal/bottomsheet de agendamento
  - [ ] Tag não é adicionada nesse momento
- [ ] Mover via Menu para "Agendada"
  - [ ] Deve abrir modal/bottomsheet de agendamento
  - [ ] Tag não é adicionada até confirmação

### 9. Teste de Filtro
- [ ] Criar cards com empresas diferentes
- [ ] Usar filtro "Filtrar por empresa ou agendista..."
- [ ] Cards com tags aparecem/desaparecem conforme filtro

### 10. Teste de Menu (Excluir)
- [ ] Abrir menu do card com ⋯
- [ ] Selecionar "Excluir"
  - [ ] Card é removido
  - [ ] Tags do banco de dados são removidas
  - [ ] Nenhum erro no console

## 🔧 Dados de Teste Recomendados

### Card 1: Fluxo Completo
```json
{
  "empresa_nome": "Empresa Teste ABC",
  "agendista": "João Silva",
  "valor": "1500",
  "duracao_minutos": "90",
  "data_evento": "2024-11-20T15:00:00",
  "notas": "Prospect com potencial alto",
  "status": "Finalizado",
  "tags": [
    "Em Prospecção_1700000001",
    "Aguardando_1700000002",
    "Agendada_1700000003",
    "Palestra Realizada & Acompanhamento_1700000004",
    "Finalizado_1700000005"
  ]
}
```

### Card 2: Recusado
```json
{
  "empresa_nome": "Empresa Teste XYZ",
  "agendista": "Maria Santos",
  "valor": "2000",
  "duracao_minutos": "60",
  "data_evento": "2024-11-18T14:00:00",
  "notas": "Recusou proposta",
  "status": "Recusada",
  "tags": [
    "Em Prospecção_1700000010",
    "Aguardando_1700000011",
    "Recusada_1700000012"
  ]
}
```

### Card 3: Em Acompanhamento
```json
{
  "empresa_nome": "Empresa Teste DEF",
  "agendista": "Roberto Costa",
  "valor": "2500",
  "duracao_minutos": "120",
  "data_evento": "2024-11-25T10:00:00",
  "notas": "Aguardando retorno após palestra",
  "status": "Palestra Realizada & Acompanhamento",
  "tags": [
    "Em Prospecção_1700000020",
    "Aguardando_1700000021",
    "Agendada_1700000022",
    "Palestra Realizada & Acompanhamento_1700000023"
  ]
}
```

## 📱 Instruções de Teste Manual

### Teste 1: Flow Básico
```
1. Abra o app CRM
2. Clique em + para criar novo card
3. Preencha dados (empresa, agendista, valor)
4. Card aparecerá em "Em Prospecção"
5. Arraste para "Aguardando"
6. Veja tag [Aguardando] aparecer
7. Clique menu ⋯ e mova para "Finalizado"
8. Veja tag [Finalizado] adicionar-se
```

### Teste 2: Tags em Acompanhamento
```
1. Crie novo card
2. Mova para "Palestra Realizada & Acompanhamento" via menu
3. Veja tag roxa [Palestra Realizada & Acompanhamento]
4. Mova para "Finalizado" via drag & drop
5. Veja ambas tags: [Palestra Realizada & Acompanhamento] [Finalizado]
```

### Teste 3: Remover Tag
```
1. Com card com múltiplas tags
2. Mantenha pressionado em [Recusada]
3. Diálogo aparece
4. Clique "Remover"
5. Tag desaparece, status continua igual
6. Recarregue a página
7. Tag não está mais lá
```

## 🐛 Erros Conhecidos (a Verificar)

- [ ] Verificar se tags não duplicam com movimento rápido
- [ ] Verificar se "Agendada" via drag & drop abre modal corretamente
- [ ] Verificar se menu está atualizado com novos status
- [ ] Verificar cores em diferentes temas (claro/escuro)
- [ ] Verificar se tags não quebram em nomes longos de status

## 📊 Métricas a Monitorar

1. **Tempo de resposta ao mover card**: < 2 segundos
2. **Número de tags por card**: Sem limite (tecnicamente)
3. **Performance com 100+ cards**: Deve ser fluida
4. **Sincronização Firestore**: < 1 segundo

## 🎓 Documentação para Usuários Finais

### Como Usar Tags

**Automaticamente Criadas:**
- Cada vez que você move um card, uma tag é criada
- Você não precisa fazer nada - é automático!

**Como Ver Tags:**
- Abra um card
- Role para baixo
- Veja as tags coloridas que mostram por onde o card passou

**Como Remover Tag:**
- Encontre a tag que deseja remover
- Mantenha pressionado por 1-2 segundos
- Clique "Remover" no diálogo
- Pronto! A tag saiu do histórico

### Status Importantes

**Novo: Palestra Realizada & Acompanhamento**
- Use quando a palestra foi realizada e você está acompanhando a empresa
- Cor: Roxo
- Ajuda a rastrear quais empresas estão sendo acompanhadas

**Novo: Finalizado**
- Use quando o processo está completo
- Contrato assinado, parceria estabelecida ou descartada definitivamente
- Cor: Teal
- Arquivo final de todos os deals

---

**Última Atualização**: 23 de Novembro de 2024
**Versão**: 1.0
**Status**: Pronto para Teste
