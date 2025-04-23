import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await context.read<AuthService>().getAllUsers();
      setState(() {
        _users = users.where((user) => user.role != 'admin').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _blockUser(User user) async {
    try {
      await context.read<AuthService>().updateUserStatus(user.id!, 'blocked');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked successfully')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user: $e')),
      );
    }
  }

  Future<void> _unblockUser(User user) async {
    try {
      await context.read<AuthService>().updateUserStatus(user.id!, 'active');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unblocked successfully')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unblock user: $e')),
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    try {
      await context.read<AuthService>().deleteUser(user.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  void _showUserDetails(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Email', user.email, Icons.email),
              const Divider(),
              _buildDetailRow('Phone', user.phone, Icons.phone),
              const Divider(),
              _buildDetailRow('Username', user.username, Icons.person_outline),
              const Divider(),
              _buildDetailRow(
                'Status',
                user.status ?? 'active',
                Icons.info_outline,
                valueColor: user.status == 'blocked' ? Colors.red : Colors.green,
              ),
              const Divider(),
              _buildDetailRow(
                'Member Since',
                _formatDate(user.createdAt),
                Icons.calendar_today,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (user.status != 'blocked')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _blockUser(user);
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Block User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _unblockUser(user);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Unblock User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(user);
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
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

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _users.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: const Icon(Icons.person_outline),
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: user.status == 'blocked'
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.status ?? 'active',
                                style: TextStyle(
                                  color: user.status == 'blocked'
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),
                            onTap: () => _showUserDetails(user),
                          ),
                        );
                      },
                    ),
    );
  }
} 