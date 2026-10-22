import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestão da Equipe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Controle de Acessos e Permissões',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum usuário cadastrado no sistema.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final docId = users[index].id;
              final nome = user['nome'] ?? 'Sem Nome';
              final email = user['email'] ?? '';
              final role = user['role'] ?? 'pendente';
              final fotoUrl = user['fotoUrl'];

              final isPendente = role == 'pendente';

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                color: isPendente
                    ? Colors.amber.withOpacity(0.08)
                    : Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPendente
                        ? Colors.amberAccent.withOpacity(0.5)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading: CircleAvatar(
                    backgroundImage: fotoUrl != null
                        ? NetworkImage(fotoUrl)
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: fotoUrl == null
                        ? Text(nome.isNotEmpty ? nome[0].toUpperCase() : 'U')
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _buildRoleBadge(role),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.manage_accounts,
                      color: Colors.white70,
                    ),
                    onSelected: (novaRole) async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(docId)
                          .update({'role': novaRole});
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'agendista',
                        child: Text('Promover a Agendista'),
                      ),
                      const PopupMenuItem(
                        value: 'orador',
                        child: Text('Promover a Orador (Admin)'),
                      ),
                      const PopupMenuItem(
                        value: 'pendente',
                        child: Text('Manter Pendente'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label;

    switch (role) {
      case 'orador':
        color = Colors.blueAccent;
        label = 'ORADOR';
        break;
      case 'agendista':
        color = Colors.greenAccent;
        label = 'AGENDISTA';
        break;
      default:
        color = Colors.amberAccent;
        label = 'PENDENTE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
