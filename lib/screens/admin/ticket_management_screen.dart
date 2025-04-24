import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TicketManagementScreen extends StatefulWidget {
  const TicketManagementScreen({Key? key}) : super(key: key);

  @override
  State<TicketManagementScreen> createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredTickets = [];
  
  // Mock data - Replace with actual data from your backend
  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TK001',
      'customerName': 'John Doe',
      'source': 'New York',
      'destination': 'Los Angeles',
      'date': DateTime.now().add(const Duration(days: 2)),
      'status': 'Pending',
      'amount': 150.00,
      'seatNo': 'A1',
      'busNo': 'BUS123',
    },
    // Add more mock tickets here
  ];

  @override
  void initState() {
    super.initState();
    _filteredTickets = List.from(_tickets);
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
                  _buildSearchAndFilter(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildTicketsList(),
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
        onPressed: () => _showAddTicketDialog(),
        child: const Icon(Icons.add),
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
                'Ticket Management',
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
                    _buildStatCard('Total Tickets', _filteredTickets.length.toString()),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Pending',
                      _filteredTickets.where((ticket) => ticket['status'] == 'Pending').length.toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Confirmed',
                      _filteredTickets.where((ticket) => ticket['status'] == 'Confirmed').length.toString(),
                      color: Colors.green,
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
              'Ticket Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                _buildStatCard('Total Tickets', _filteredTickets.length.toString()),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Pending',
                  _filteredTickets.where((ticket) => ticket['status'] == 'Pending').length.toString(),
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Confirmed',
                  _filteredTickets.where((ticket) => ticket['status'] == 'Confirmed').length.toString(),
                  color: Colors.green,
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

  Widget _buildSearchAndFilter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 16),
              _buildFilterDropdown(),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _buildSearchField(),
            ),
            const SizedBox(width: 16),
            _buildFilterDropdown(),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search tickets...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A27),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => _filterTickets(),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A27),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          dropdownColor: const Color(0xFF1A1A27),
          style: const TextStyle(color: Colors.white),
          items: ['All', 'Pending', 'Confirmed', 'Cancelled']
              .map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedFilter = newValue;
              });
              _filterTickets();
            }
          },
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    if (_filteredTickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No tickets found',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _filteredTickets.length,
      itemBuilder: (context, index) {
        final ticket = _filteredTickets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1A1A27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Text(
                  '#${ticket['id']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    ticket['customerName'],
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(ticket['status']),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTicketDetail('From', ticket['source']),
                    _buildTicketDetail('To', ticket['destination']),
                    _buildTicketDetail('Date', 
                      DateFormat('MMM dd, yyyy').format(ticket['date'])),
                    _buildTicketDetail('Seat', ticket['seatNo']),
                    _buildTicketDetail('Bus No', ticket['busNo']),
                    _buildTicketDetail('Amount', '\$${ticket['amount']}'),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            'Confirm',
                            Icons.check,
                            Colors.green,
                            () => _updateTicketStatus(index, 'Confirmed'),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            'Cancel',
                            Icons.close,
                            Colors.red,
                            () => _updateTicketStatus(index, 'Cancelled'),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            'Edit',
                            Icons.edit,
                            Colors.blue,
                            () => _editTicket(index),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            'Delete',
                            Icons.delete,
                            Colors.red,
                            () => _deleteTicket(index),
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
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

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

  Widget _buildTicketDetail(String label, String value) {
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

  void _showAddTicketDialog([Map<String, dynamic>? ticket]) {
    final bool isEditing = ticket != null;
    final TextEditingController customerNameController = TextEditingController(text: ticket?['customerName'] ?? '');
    final TextEditingController sourceController = TextEditingController(text: ticket?['source'] ?? '');
    final TextEditingController destinationController = TextEditingController(text: ticket?['destination'] ?? '');
    final TextEditingController amountController = TextEditingController(text: ticket?['amount']?.toString() ?? '');
    final TextEditingController seatNoController = TextEditingController(text: ticket?['seatNo'] ?? '');
    final TextEditingController busNoController = TextEditingController(text: ticket?['busNo'] ?? '');
    
    DateTime selectedDate = ticket?['date'] ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A27),
        title: Text(
          isEditing ? 'Edit Ticket' : 'Add New Ticket',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: customerNameController,
                label: 'Customer Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: sourceController,
                label: 'Source',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: destinationController,
                label: 'Destination',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.teal),
                title: const Text('Date', style: TextStyle(color: Colors.grey)),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(selectedDate),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: Colors.teal[400]!,
                            onPrimary: Colors.white,
                            surface: const Color(0xFF1A1A27),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: amountController,
                label: 'Amount',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: seatNoController,
                label: 'Seat Number',
                icon: Icons.airline_seat_recline_normal,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: busNoController,
                label: 'Bus Number',
                icon: Icons.directions_bus,
              ),
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
              final newTicket = {
                'id': ticket?['id'] ?? 'TK${_tickets.length + 1}'.padLeft(3, '0'),
                'customerName': customerNameController.text,
                'source': sourceController.text,
                'destination': destinationController.text,
                'date': selectedDate,
                'status': ticket?['status'] ?? 'Pending',
                'amount': double.tryParse(amountController.text) ?? 0.0,
                'seatNo': seatNoController.text,
                'busNo': busNoController.text,
              };

              setState(() {
                if (isEditing) {
                  final index = _tickets.indexWhere((t) => t['id'] == ticket['id']);
                  _tickets[index] = newTicket;
                } else {
                  _tickets.add(newTicket);
                }
              });

              Navigator.pop(context);
              // Implement API call to add/update ticket
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
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
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

  void _filterTickets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTickets = _tickets.where((ticket) {
        return ticket['customerName'].toLowerCase().contains(query) ||
               ticket['id'].toLowerCase().contains(query) ||
               ticket['source'].toLowerCase().contains(query) ||
               ticket['destination'].toLowerCase().contains(query) ||
               ticket['busNo'].toLowerCase().contains(query);
      }).toList();

      if (_selectedFilter != 'All') {
        _filteredTickets = _filteredTickets.where((ticket) => 
          ticket['status'] == _selectedFilter).toList();
      }
    });
  }

  void _updateTicketStatus(int index, String status) {
    setState(() {
      _tickets[index]['status'] = status;
    });
    // Implement API call to update status
  }

  void _editTicket(int index) {
    // Implement edit ticket functionality
  }

  void _deleteTicket(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A27),
        title: const Text(
          'Delete Ticket',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this ticket?',
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
                _tickets.removeAt(index);
              });
              Navigator.pop(context);
              // Implement API call to delete ticket
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