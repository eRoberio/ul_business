import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_screen.dart';
import '../crm/crm_kanban_screen.dart';
import '../agenda/agenda_screen.dart';
import '../timeline/time_tree_screen.dart';
import 'user_management_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const CrmKanbanScreen(),
    const AgendaScreen(),
    const TimeTreeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.business_center,
              color: Colors.blueAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'UL Business',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
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
                  icon: const Icon(
                    Icons.group_add_outlined,
                    color: Colors.amberAccent,
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

          // Menu de Perfil com renderização segura de avatar do Google
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            icon: ClipOval(
              child: SizedBox(
                width: 36,
                height: 36,
                child: user?.photoURL != null && user!.photoURL!.isNotEmpty
                    ? Image.network(
                        user.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildInitialsAvatar(user),
                      )
                    : _buildInitialsAvatar(user),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    const Divider(color: Colors.white10),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      'Sair do Sistema',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildInitialsAvatar(User? user) {
    final name = user?.displayName ?? user?.email ?? 'U';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: Theme.of(context).colorScheme.primary,
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

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        NavigationRail(
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) =>
              setState(() => _selectedIndex = index),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Colors.blueAccent),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.view_kanban_outlined),
              selectedIcon: Icon(Icons.view_kanban, color: Colors.blueAccent),
              label: Text('CRM'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(
                Icons.calendar_month,
                color: Colors.blueAccent,
              ),
              label: Text('Agenda'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.account_tree_outlined),
              selectedIcon: Icon(Icons.account_tree, color: Colors.blueAccent),
              label: Text('Árvore'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
        Expanded(child: _pages[_selectedIndex]),
      ],
    );
  }

  Widget _buildMobileLayout() => _pages[_selectedIndex];

  Widget _buildBottomNavBar() {
    return NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
    );
  }
}
