import 'package:flutter/material.dart';

class UserRole {
  static const owner = 'owner';
  static const manager = 'manager';
  static const sales = 'sales';
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;

  User({required this.id, required this.name, required this.email, required this.role});
}

class Item {
  int id;
  String name;
  String description;
  double price;

  Item({required this.id, required this.name, this.description = '', required this.price});
}

class LinkRequest {
  final int id;
  final int requesterId;
  final String status; 
  final String note;

  LinkRequest({required this.id, required this.requesterId, this.status = 'pending', this.note = ''});
}

class MockSupplierRepository {
  int _userAuto = 1;
  int _itemAuto = 1;
  int _linkAuto = 1;

  final List<User> users = [];
  final List<Item> items = [];
  final List<LinkRequest> linkRequests = [];

  MockSupplierRepository() {
    users.add(User(id: _userAuto++, name: 'Sales Demo', email: 'sales@example.com', role: UserRole.sales));
    users.add(User(id: _userAuto++, name: 'Manager Demo', email: 'manager@example.com', role: UserRole.manager));
    users.add(User(id: _userAuto++, name: 'Owner Demo', email: 'owner@example.com', role: UserRole.owner));
  }

  User? login(String email) => users.firstWhere((u) => u.email == email, orElse: () => null);

  Item addItem(String name, String desc, double price) {
    final it = Item(id: _itemAuto++, name: name, description: desc, price: price);
    items.add(it);
    return it;
  }

  void updateItem(Item item) {
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) items[idx] = item;
  }

  void deleteItem(int id) => items.removeWhere((i) => i.id == id);

  LinkRequest createLinkRequest(int requesterId, {String note = ''}) {
    final lr = LinkRequest(id: _linkAuto++, requesterId: requesterId, status: 'pending', note: note);
    linkRequests.add(lr);
    return lr;
  }

  void setLinkStatus(int linkId, String status) {
    final idx = linkRequests.indexWhere((l) => l.id == linkId);
    if (idx >= 0) linkRequests[idx] = LinkRequest(id: linkRequests[idx].id, requesterId: linkRequests[idx].requesterId, status: status, note: linkRequests[idx].note);
  }
}

class SalesRepVersionApp extends StatelessWidget {
  final MockSupplierRepository repo;
  SalesRepVersionApp({Key? key, required this.repo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
            title: 'Supplier — SalesRep',
            theme: ThemeData(primarySwatch: Colors.blue),
    home: LoginScreen(repo: repo),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final MockSupplierRepository repo;
  const LoginScreen({Key? key, required this.repo}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'sales@example.com'); 

  void _doLogin() {
    final user = widget.repo.login(_emailCtrl.text.trim());
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No user with that email.')));
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DashboardScreen(repo: widget.repo, currentUser: user)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(title: Text('Login (Sales Rep)')),
    body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            children: [
    TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email')),
    SizedBox(height: 12),
    ElevatedButton(onPressed: _doLogin, child: Text('Login')),
    SizedBox(height: 8),
    Text('Note: Signup is handled by the web app; team creation is managed by web devs.'),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final MockSupplierRepository repo;
  final User currentUser;
  const DashboardScreen({Key? key, required this.repo, required this.currentUser}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
    ItemsTab(repo: widget.repo, canModify: _canModifyItems(widget.currentUser)),
    TeamTab(repo: widget.repo, currentUser: widget.currentUser), // read-only list for sales rep
    LinksTab(repo: widget.repo, currentUser: widget.currentUser),
    ProfileTab(user: widget.currentUser),
    ];

    return Scaffold(
            appBar: AppBar(title: Text('Dashboard — ${widget.currentUser.role.toUpperCase()}')),
    body: tabs[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            items: const [
    BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Items'),
    BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Team'),
    BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Link Requests'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  bool _canModifyItems(User u) => u.role == UserRole.owner || u.role == UserRole.manager || u.role == UserRole.sales;
}

class ItemsTab extends StatefulWidget {
  final MockSupplierRepository repo;
  final bool canModify;
  const ItemsTab({Key? key, required this.repo, required this.canModify}) : super(key: key);

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab> {
  void _showAddEdit([Item? item]) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final priceCtrl = TextEditingController(text: item?.price.toString() ?? '0');

    showDialog<void>(context: context, builder: (_) => AlertDialog(
            title: Text(item==null ? 'Add Item' : 'Edit Item'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
    TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name')),
    TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Description')),
    TextField(controller: priceCtrl, decoration: InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
      ]),
    actions: [TextButton(onPressed: ()=>Navigator.of(context).pop(), child: Text('Cancel')),
    ElevatedButton(onPressed: (){
      final p = double.tryParse(priceCtrl.text) ?? 0.0;
      if (item==null) {
        setState(()=>widget.repo.addItem(nameCtrl.text, descCtrl.text, p));
      } else {
        item.name = nameCtrl.text; item.description = descCtrl.text; item.price = p;
        widget.repo.updateItem(item);
        setState((){});
      }
      Navigator.of(context).pop();
    }, child: Text('Save'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
    if (widget.canModify) Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: ()=>_showAddEdit(), icon: Icon(Icons.add), label: Text('Add Item'))),
    Expanded(child: ListView.builder(itemCount: widget.repo.items.length, itemBuilder: (_, i){
      final it = widget.repo.items[i];
      return Card(child: ListTile(
              title: Text(it.name),
              subtitle: Text('${it.description}
              \$${it.price.toStringAsFixed(2)}'),
      isThreeLine: true,
              trailing: widget.canModify ? PopupMenuButton<String>(onSelected: (v){
      if (v=='edit') _showAddEdit(it);
      if (v=='delete') setState(()=>widget.repo.deleteItem(it.id));
            }, itemBuilder: (_)=>[PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]) : null,
          ));
    }))
      ]),
    );
  }
}

class TeamTab extends StatelessWidget {
  final MockSupplierRepository repo;
  final User currentUser;
  const TeamTab({Key? key, required this.repo, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: null, icon: Icon(Icons.person_add), label: Text('Add Member (web)'))),
    Expanded(child: ListView.builder(itemCount: repo.users.length, itemBuilder: (_, i){
      final u = repo.users[i];
      return Card(child: ListTile(title: Text(u.name), subtitle: Text('${u.email} — ${u.role}')));
    }))
      ]),
    );
  }
}

class LinksTab extends StatefulWidget {
  final MockSupplierRepository repo;
  final User currentUser;
  const LinksTab({Key? key, required this.repo, required this.currentUser}) : super(key: key);

  @override
  State<LinksTab> createState() => _LinksTabState();
}

class _LinksTabState extends State<LinksTab> {
  void _createRequest() {
    final noteCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
            title: Text('Create Link Request'),
            content: TextField(controller: noteCtrl, decoration: InputDecoration(labelText: 'Note (optional)')),
    actions: [TextButton(onPressed: ()=>Navigator.of(context).pop(), child: Text('Cancel')),
    ElevatedButton(onPressed: (){
      widget.repo.createLinkRequest(widget.currentUser.id, note: noteCtrl.text.trim());
      setState((){});
      Navigator.of(context).pop();
    }, child: Text('Send'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final canApprove = widget.currentUser.role == UserRole.owner || widget.currentUser.role == UserRole.manager;
    return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: _createRequest, icon: Icon(Icons.send), label: Text('Create Request'))),
    Expanded(child: ListView.builder(itemCount: widget.repo.linkRequests.length, itemBuilder: (_, i){
      final lr = widget.repo.linkRequests[i];
      final requester = widget.repo.users.firstWhere((u)=>u.id==lr.requesterId, orElse: ()=>User(id:0,name:'Unknown',email:'',role:''));
      return Card(child: ListTile(
              title: Text('Request #${lr.id} — ${lr.status.toUpperCase()}'),
              subtitle: Text('From: ${requester.name} (${requester.email})
              Note: ${lr.note}'),
      isThreeLine: true,
              trailing: canApprove && lr.status=='pending' ? Row(mainAxisSize: MainAxisSize.min, children: [TextButton(onPressed: (){ widget.repo.setLinkStatus(lr.id, 'approved'); setState((){}); }, child: Text('Approve')), TextButton(onPressed: (){ widget.repo.setLinkStatus(lr.id, 'rejected'); setState((){}); }, child: Text('Reject'))]) : null,
          ));
    }))
      ]),
    );
  }
}

class ProfileTab extends StatelessWidget {
  final User user;
  const ProfileTab({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Card(margin: EdgeInsets.all(24), child: Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), SizedBox(height:8), Text(user.email), SizedBox(height:8), Text('Role: ${user.role}')]))));
  }
}

