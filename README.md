
A refatoração e evolução do UL Business foram implementadas utilizando 100% recursos gratuitos (Plano Firebase Spark Free + pacotes gratuitos do pub.dev, sem Cloud Functions ou servidores externos). A verificação estática do workspace (problems) não encontrou erros de compilação ou lint.

1. Estrutura de Pastas Clean Architecture + Pacotes Gratuitos (pub.dev)
Pacotes adicionados em pubspec.yaml
Além dos pacotes já existentes (flutter_riverpod, firebase_core, cloud_firestore, firebase_auth, shared_preferences), foram adicionados:

firebase_app_check: ^0.5.2 — proteção antifraude gratuita no Spark Plan (Play Integrity no Android, App Attest/DeviceCheck no iOS e reCAPTCHA v3 na Web).
connectivity_plus: ^7.3.1 — detecção de conectividade em tempo real para Web, Android e iOS.
Estrutura criada (domain/, data/, core/, features/)
Domain (domain/):
Entidades e validadores puros: app_user.dart, audit_log.dart, login_lockout_state.dart, schedule_validator.dart.
Interfaces abstratas de repositório: auth_repository.dart, crm_repository.dart, audit_log_repository.dart, login_security_repository.dart.
Data (data/):
Implementações Firebase/Local: firebase_auth_repository.dart, firestore_crm_repository.dart, firestore_audit_log_repository.dart, local_login_security_repository.dart.
Injeção via Riverpod: repository_providers.dart.
Core (core/):
App Check & Firestore Offline: app_check_config.dart
Conectividade & Banner Offline: connectivity_service.dart
Persistência de Rascunhos: draft_storage_service.dart
Mensagens Fixas Globais: feedback_service.dart e global_feedback_banner.dart
Faixa Institucional ULB & Parceiros: InstitutionalPartnersStrip em design_system_widgets.dart.
2. AuthGuard / Login com Bloqueio de 5 Tentativas (5 min) e Password View
AuthGuard: migrado para ConsumerStatefulWidget usando authUidStreamProvider e currentUserProfileProvider, garantindo persistência de sessão (Persistence.LOCAL na Web via ensureSessionPersistence()).
LoginScreen:
Password View: botão de olho (Icons.visibility_outlined / Icons.visibility_off_outlined) alternando obscureText.
Brute-Force Protection: após 5 falhas de login, bloqueia o acesso por 5 minutos persistindo o timestamp em SharedPreferences via LocalLoginSecurityRepository (impedindo burla ao recarregar a página), exibe contador regressivo (mm:ss) e grava evento login_blocked em audit_logs.
Identidade Institucional: exibe InstitutionalPartnersStrip da União Leste Brasileira (ULB) no rodapé.
RegisterScreen:
Password View nos campos de senha e confirmação.
Auto-Save de Rascunho para nome e e-mail (restaurado automaticamente ao reabrir e limpo ao concluir o cadastro).
3. Auto-Save de Rascunho + Firestore Offline + Mensagens Fixas + Scroll/UX
Firestore Offline Persistence + App Check: inicializados em main.dart via FirebaseFreeTierConfig.configure (Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)).
Nota para Web em produção: compile com --dart-define=RECAPTCHA_SITE_KEY=SUA_CHAVE_RECAPTCHA_V3 para ativar o App Check Web.
Indicador de Conectividade: OfflineStatusBanner exibido no topo da aplicação quando offline (Modo Offline (Sincronização pendente)).
Auto-Save no Apontamento Comercial: CommercialAppointmentModal salva e restaura automaticamente empresa, valor, notas, status, data/hora, duração e localização via draftStorageProvider, limpando o rascunho após envio bem-sucedido e validando sábado > 18:30 e conflitos de agenda antes de gravar.
Mensagens Fixas Globais: GlobalFeedbackOverlay + feedbackProvider exibem alertas padronizados compatíveis com Dark/Light Mode (Sucesso verde, Aviso âmbar, Erro vermelho), substituindo SnackBars genéricos em Login, Cadastro, CRM, Contratos e Apontamento Comercial.
Scroll & Preservação de Estado:
MainShell usa PageStorage + IndexedStack.
CrmKanbanScreen, AgendaScreen, DashboardScreen e TimeTreeScreen usam ScrollControllers dedicados e PageStorageKeys.
Auditoria na Árvore Cronológica: TimeTreeScreen agora conta com alternância entre Negociações e Auditoria (audit_logs), registrando bloqueios de login, criação/edição/movimentação/exclusão de cards no CRM, agendamentos e geração de contratos (contract_screen.dart).
4. Regras do firestore.rules com Proteção Antifraude e Logs
Criado firestore.rules e referenciado em firebase.json:
Exige usuário autenticado e ativo (role != 'pendente').
Bloqueia edição/exclusão de cards de outros agendistas (resource.data.agendista_uid == request.auth.uid || isOrador()).
Valida campos obrigatórios, duração (1..1440) e timestamp futuro para status Agendada.
Torna contratos e audit_logs imutáveis (allow update, delete: if false;).
Testes Adicionados
Foram criados testes unitários para bloqueio de login (5 tentativas / 5 min), regra de sábado (> 18:30), conflitos de agenda, rascunhos locais e FeedbackNotifier em security_and_draft_test.dart. Para executá-los localmente: