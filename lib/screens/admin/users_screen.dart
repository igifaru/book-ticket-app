import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'package:intl/intl.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _searchQuery;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditUserDialog([User? user]) {
    final bool isEditing = user != null;
    
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _usernameController.text = user.username;
    } else {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _usernameController.clear();
      _passwordController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit User' : 'Add New User'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (value!.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;

                    setState(() => _isLoading = true);

                    try {
                      final authService = context.read<AuthService>();
                      
                      if (isEditing) {
                        final updatedUser = User(
                          id: user!.id,
                          name: _nameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          password: user.password,
                          role: user.role,
                          username: _usernameController.text,
                          createdAt: user.createdAt,
                          status: user.status,
                        );
                        await authService.updateUserStatus(user.id!, user.status ?? 'active');
                      } else {
                        await authService.registerUser(
                          name: _nameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          username: _usernameController.text,
                          password: _passwordController.text,
                        );
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'User updated successfully'
                                  : 'User added successfully',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user.email, Icons.email),
            const SizedBox(height: 8),
            _buildDetailRow('Phone', user.phone, Icons.phone),
            const SizedBox(height: 8),
            _buildDetailRow('Username', user.username, Icons.person),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Status',
              user.status ?? 'active',
              Icons.info,
              valueColor: user.status == 'blocked' ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Member Since',
              DateFormat('MMM d, yyyy').format(user.createdAt),
              Icons.calendar_today,
            ),
          ],
        ),
        actions: [
          if (user.status != 'blocked')
            TextButton.icon(
              onPressed: () async {
                try {
                  await context.read<AuthService>().updateUserStatus(user.id!, 'blocked');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              icon: const Icon(Icons.block, color: Colors.red),
              label: const Text('Block', style: TextStyle(color: Colors.red)),
            )
          else
            TextButton.icon(
              onPressed: () async {
                try {
                  await context.read<AuthService>().updateUserStatus(user.id!, 'active');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User unblocked successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: const Text('Unblock', style: TextStyle(color: Colors.green)),
            ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditUserDialog(user);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(user);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<AuthService>().deleteUser(user.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditUserDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.isNotEmpty ? value : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      return FutureBuilder<List<User>>(
                        future: authService.getAllUsers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }

                          var users = snapshot.data ?? [];
                          
                          // Filter out admin users and apply search
                          users = users.where((user) => user.role != 'admin').toList();
                          if (_searchQuery != null) {
                            final query = _searchQuery!.toLowerCase();
                            users = users.where((user) {
                              return user.name.toLowerCase().contains(query) ||
                                     user.email.toLowerCase().contains(query) ||
                                     user.phone.toLowerCase().contains(query) ||
                                     user.username.toLowerCase().contains(query);
                            }).toList();
                          }

                          if (users.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No users found'),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text(
                                      user.name[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
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
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 