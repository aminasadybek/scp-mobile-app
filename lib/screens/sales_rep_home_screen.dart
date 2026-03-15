import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'complaints_sales_screen.dart';
import 'chat_screen.dart';
import 'order_history_screen.dart';
import 'edit_catalog_screen.dart';

class SalesRepHomeScreen extends StatelessWidget {
  const SalesRepHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    if (user == null || user.role != 'sales_rep') {
      // Если не sales_rep, показываем ошибку
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('Access restricted to Sales Representatives only.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaterChains Sales Reps'),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),
        backgroundColor: const Color(0xFF6B8E23),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name.substring(0, 1),
                style: const TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome,',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Text(
              'Sales Representative!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF6B8E23)),
                title: const Text('Chats with Consumers'),
                subtitle: const Text('Handle consumer communication'),
                onTap: () {
                  if (user.role == 'sales_rep') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  }
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.report_problem, color: Color(0xFF6B8E23)),
                title: const Text('Complaints'),
                subtitle: const Text('Resolve first-line complaints'),
                onTap: () {
                  if (user.role == 'sales_rep') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComplaintsSalesScreen()),
                    );
                  }
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.list_alt, color: Color(0xFF6B8E23)),
                title: const Text('Order Management'),
                subtitle: const Text('View and process orders'),
                onTap: () {
                  if (user.role == 'sales_rep') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  }
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF6B8E23)),
                title: const Text('Edit the catalog'),
                subtitle: const Text('Add, remove, update, or edit products'),
                onTap: () {
                  if (user.role == 'sales_rep') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditCatalogScreen()),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Escalate unresolved issues to Manager',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
