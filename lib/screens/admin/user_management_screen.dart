import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredUsers = [];

  // Mock data - Replace with actual data from your backend
  final List<Map<String, dynamic>> _users = [
    {
      'id': 'U001',
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'phone': '+1 234 567 8900',
      'status': 'Active',
      'joinDate': DateTime.now().subtract(const Duration(days: 30)),
      'bookings': 5,
      'totalSpent': 750.00,
    },
    // Add more mock users here
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filteredUsers = List.from(_users);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchAndTabs(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildUsersList(),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal[400],
        onPressed: () => _showAddUserDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatCard('Total Users', _filteredUsers.length.toString()),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Active',
                      _filteredUsers.where((user) => user['status'] == 'Active').length.toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Inactive',
                      _filteredUsers.where((user) => user['status'] == 'Inactive').length.toString(),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'User Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                _buildStatCard('Total Users', _filteredUsers.length.toString()),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Active',
                  _filteredUsers.where((user) => user['status'] == 'Active').length.toString(),
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Inactive',
                  _filteredUsers.where((user) => user['status'] == 'Inactive').length.toString(),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A27),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color ?? Colors.teal, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color ?? Colors.teal,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndTabs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A27),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => _filterUsers(),
            ),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(
                tabBarTheme: const TabBarTheme(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.teal,
                tabs: const [
                  Tab(text: 'All Users'),
                  Tab(text: 'Active'),
                  Tab(text: 'Inactive'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersList() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUsersListView(_filteredUsers),
        _buildUsersListView(_filteredUsers.where((user) => user['status'] == 'Active').toList()),
        _buildUsersListView(_filteredUsers.where((user) => user['status'] == 'Inactive').toList()),
      ],
    );
  }

  Widget _buildUsersListView(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1A1A27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal[400],
                  child: Text(
                    user['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user['email'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(user['status']),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserDetail('Phone', user['phone']),
                    _buildUserDetail('Join Date', 
                      DateFormat('MMM dd, yyyy').format(user['joinDate'])),
                    _buildUserDetail('Total Bookings', user['bookings'].toString()),
                    _buildUserDetail('Total Spent', '\$${user['totalSpent']}'),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            user['status'] == 'Active' ? 'Deactivate' : 'Activate',
                            user['status'] == 'Active' ? Icons.block : Icons.check_circle,
                            user['status'] == 'Active' ? Colors.red : Colors.green,
                            () => _toggleUserStatus(index),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            'Edit',
                            Icons.edit,
                            Colors.blue,
                            () => _editUser(index),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            'Delete',
                            Icons.delete,
                            Colors.red,
                            () => _deleteUser(index),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final color = status == 'Active' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String tooltip,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user['name'].toLowerCase().contains(query) ||
               user['email'].toLowerCase().contains(query) ||
               user['phone'].toLowerCase().contains(query) ||
               user['id'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddUserDialog([Map<String, dynamic>? user]) {
    final bool isEditing = user != null;
    final TextEditingController nameController = TextEditingController(text: user?['name'] ?? '');
    final TextEditingController emailController = TextEditingController(text: user?['email'] ?? '');
    final TextEditingController phoneController = TextEditingController(text: user?['phone'] ?? '');
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A27),
        title: Text(
          isEditing ? 'Edit User' : 'Add New User',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: phoneController,
                label: 'Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              if (!isEditing) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newUser = {
                'id': user?['id'] ?? 'U${_users.length + 1}'.padLeft(3, '0'),
                'name': nameController.text,
                'email': emailController.text,
                'phone': phoneController.text,
                'status': user?['status'] ?? 'Active',
                'joinDate': user?['joinDate'] ?? DateTime.now(),
                'bookings': user?['bookings'] ?? 0,
                'totalSpent': user?['totalSpent'] ?? 0.0,
              };

              setState(() {
                if (isEditing) {
                  final index = _users.indexWhere((u) => u['id'] == user['id']);
                  _users[index] = newUser;
                } else {
                  _users.add(newUser);
                }
              });

              Navigator.pop(context);
              // Implement API call to add/update user
            },
            child: Text(
              isEditing ? 'Update' : 'Add',
              style: TextStyle(color: Colors.teal[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.teal),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: BorderSide(color: Colors.teal[400]!),
      ),
    );
  }

  void _toggleUserStatus(int index) {
    setState(() {
      _users[index]['status'] = _users[index]['status'] == 'Active' ? 'Inactive' : 'Active';
    });
    // Implement API call to update status
  }

  void _editUser(int index) {
    // Implement edit user functionality
  }

  void _deleteUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A27),
        title: const Text(
          'Delete User',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _users.removeAt(index);
              });
              Navigator.pop(context);
              // Implement API call to delete user
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 