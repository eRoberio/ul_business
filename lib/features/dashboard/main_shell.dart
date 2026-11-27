import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';
import '../../core/theme/theme_provider.dart';
import 'dashboard_screen.dart';
import '../crm/crm_kanban_screen.dart';
import '../agenda/agenda_screen.dart';
import '../timeline/time_tree_screen.dart';
import 'user_management_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();

  final List<Widget> _pages = const [
    DashboardScreen(),
    CrmKanbanScreen(),
    AgendaScreen(),
    TimeTreeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final user = FirebaseAuth.instance.currentUser;
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const ULBusinessLogo(
              size: 34,
              borderRadius: 9,
            ),
            const SizedBox(width: 12),
            Text(
              'UL Business',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: tokens.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: tokens.isDark ? 'Mudar para Light Mode' : 'Mudar para Dark Mode',
            child: IconButton(
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .toggleLightDark(Theme.of(context).brightness);
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    RotationTransition(turns: anim, child: child),
                child: Icon(
                  tokens.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  key: ValueKey(tokens.isDark),
                  color: tokens.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),

          // Stream para verificar se o usuário é Orador e exibir atalho de gestão de equipe
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final isOrador = userData?['role'] == 'orador';

              if (isOrador) {
                return IconButton(
                  icon: Icon(
                    Icons.group_add_outlined,
                    color: tokens.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Gestão da Equipe',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(width: 4),

          // Menu de Perfil com renderização segura de avatar do Google
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            tooltip: 'Conta',
            icon: ClipOval(
              child: SizedBox(
                width: 34,
                height: 34,
                child: user?.photoURL != null && user!.photoURL!.isNotEmpty
                    ? Image.network(
                        user.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildInitialsAvatar(user, tokens),
                      )
                    : _buildInitialsAvatar(user, tokens),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: tokens.borderSubtle),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: tokens.danger),
                    const SizedBox(width: 8),
                    Text(
                      'Sair do Sistema',
                      style: TextStyle(
                        color: tokens.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: PageStorage(
        bucket: _pageStorageBucket,
        child: isDesktop ? _buildDesktopLayout(tokens) : _buildMobileLayout(),
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(tokens),
    );
  }

  Widget _buildInitialsAvatar(User? user, AppThemeTokens tokens) {
    final name = user?.displayName ?? user?.email ?? 'U';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: tokens.primary,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(AppThemeTokens tokens) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) =>
              setState(() => _selectedIndex = index),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.view_kanban_outlined),
              selectedIcon: Icon(Icons.view_kanban),
              label: Text('CRM'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: Text('Agenda'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.account_tree_outlined),
              selectedIcon: Icon(Icons.account_tree),
              label: Text('Árvore'),
            ),
          ],
        ),
        VerticalDivider(thickness: 1, width: 1, color: tokens.borderSubtle),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() => IndexedStack(
    index: _selectedIndex,
    children: _pages,
  );

  Widget _buildBottomNavBar(AppThemeTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.borderSubtle, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Resumo',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_kanban_outlined),
            selectedIcon: Icon(Icons.view_kanban),
            label: 'Funil',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Árvore',
          ),
        ],
      ),
    );
  }
}
