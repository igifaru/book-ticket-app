// lib/screens/admin/admin_buses.dart
import 'package:flutter/material.dart';
import 'package:tickiting/models/bus.dart';
import 'package:tickiting/utils/theme.dart';
import 'package:tickiting/utils/database_helper.dart';

class AdminBuses extends StatefulWidget {
  const AdminBuses({super.key});

  @override
  _AdminBusesState createState() => _AdminBusesState();
}

class _AdminBusesState extends State<AdminBuses> {
  List<Bus> buses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  // Load buses from database
  Future<void> _loadBuses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loadedBuses = await DatabaseHelper().getAllBuses();
      setState(() {
        buses = loadedBuses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading buses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Bus Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Search and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search buses...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    // Show filter options
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bus list
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : buses.isEmpty
                      ? const Center(child: Text('No buses found'))
                      : RefreshIndicator(
                        onRefresh: _loadBuses,
                        child: ListView.builder(
                          itemCount: buses.length,
                          itemBuilder: (context, index) {
                            final bus = buses[index];
                            return _buildBusCard(bus, index);
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditBusDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBusCard(Bus bus, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ID: ${bus.id}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        bus.busType == 'Premium'
                            ? Colors.amber[100]
                            : bus.busType == 'Standard'
                            ? Colors.blue[100]
                            : Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bus.busType,
                    style: TextStyle(
                      color:
                          bus.busType == 'Premium'
                              ? Colors.amber[800]
                              : bus.busType == 'Standard'
                              ? Colors.blue[800]
                              : Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Departure',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        bus.departureTime,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Arrival',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        bus.arrivalTime,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        bus.duration,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price', style: TextStyle(color: Colors.grey)),
                      Text(
                        '${bus.price.toStringAsFixed(0)} RWF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Seats',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${bus.availableSeats}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Features',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        bus.features.join(', '),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showAddEditBusDialog(context, bus: bus, index: index);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmDialog(context, index);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditBusDialog(BuildContext context, {Bus? bus, int? index}) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController(text: bus?.id ?? '');
    final nameController = TextEditingController(text: bus?.name ?? '');
    final departureTimeController = TextEditingController(
      text: bus?.departureTime ?? '',
    );
    final arrivalTimeController = TextEditingController(
      text: bus?.arrivalTime ?? '',
    );
    final durationController = TextEditingController(
      text: bus?.duration ?? '',
    );
    final priceController = TextEditingController(
      text: bus?.price.toString() ?? '',
    );
    final seatsController = TextEditingController(
      text: bus?.availableSeats.toString() ?? '',
    );

    String busType = bus?.busType ?? 'Standard';
    List<String> features = List<String>.from(bus?.features ?? ['AC']);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(bus == null ? 'Add New Bus' : 'Edit Bus'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: 'Bus ID'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter bus ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Bus Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter bus name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: busType,
                      decoration: const InputDecoration(labelText: 'Bus Type'),
                      items:
                          ['Economy', 'Standard', 'Premium']
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          busType = value;
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: departureTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Departure Time',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter departure time';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: arrivalTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Arrival Time',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter arrival time';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: durationController,
                      decoration: const InputDecoration(labelText: 'Duration'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter duration';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (RWF)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: seatsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Available Seats',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter available seats';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Features',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text('AC'),
                      value: features.contains('AC'),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            features.add('AC');
                          } else {
                            features.remove('AC');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('WiFi'),
                      value: features.contains('WiFi'),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            features.add('WiFi');
                          } else {
                            features.remove('WiFi');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('USB Charging'),
                      value: features.contains('USB Charging'),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            features.add('USB Charging');
                          } else {
                            features.remove('USB Charging');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Refreshments'),
                      value: features.contains('Refreshments'),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            features.add('Refreshments');
                          } else {
                            features.remove('Refreshments');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('TV'),
                      value: features.contains('TV'),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            features.add('TV');
                          } else {
                            features.remove('TV');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newBus = Bus(
                      id: idController.text,
                      name: nameController.text,
                      departureTime: departureTimeController.text,
                      arrivalTime: arrivalTimeController.text,
                      duration: durationController.text,
                      price: double.parse(priceController.text),
                      availableSeats: int.parse(seatsController.text),
                      busType: busType,
                      features: features,
                    );

                    try {
                      if (bus == null) {
                        // Add new bus to database
                        await DatabaseHelper().insertBus(newBus);
                      } else {
                        // Update existing bus in database
                        await DatabaseHelper().updateBus(newBus);
                      }

                      // Reload buses from database
                      _loadBuses();

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            bus == null
                                ? 'Bus added successfully'
                                : 'Bus updated successfully',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(bus == null ? 'Add' : 'Update'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int index) {
    final bus = buses[index];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Bus'),
            content: const Text(
              'Are you sure you want to delete this bus? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Delete bus from database
                    await DatabaseHelper().deleteBus(bus.id);

                    // Reload buses from database
                    _loadBuses();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bus deleted successfully'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
