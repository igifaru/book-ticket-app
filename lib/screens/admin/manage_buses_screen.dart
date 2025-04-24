import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bus.dart';
import '../../services/bus_service.dart';
import '../../utils/validators.dart';
import '../../models/route.dart' as route_model;
import '../../services/route_service.dart';
import 'package:intl/intl.dart';

class ManageBusesScreen extends StatefulWidget {
  const ManageBusesScreen({Key? key}) : super(key: key);

  @override
  _ManageBusesScreenState createState() => _ManageBusesScreenState();
}

class _ManageBusesScreenState extends State<ManageBusesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _busNameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _dateController = TextEditingController();
  route_model.Route? _selectedRoute;

  @override
  void dispose() {
    _busNumberController.dispose();
    _busNameController.dispose();
    _capacityController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Allow selecting any future date
        return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isArrival) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        final formattedTime = 
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isArrival) {
          _arrivalTimeController.text = formattedTime;
        } else {
          _departureTimeController.text = formattedTime;
        }
      });
    }
  }

  void _showAddEditBusDialog([Bus? bus]) {
    final formKey = GlobalKey<FormState>();
    bool isProcessing = false;
    
    if (bus != null) {
      _busNumberController.text = bus.busNumber;
      _busNameController.text = bus.busName;
      _capacityController.text = bus.capacity.toString();
      _typeController.text = bus.type;
      _priceController.text = bus.price.toString();
      _departureTimeController.text = bus.departureTime;
      _arrivalTimeController.text = bus.arrivalTime;
      _dateController.text = bus.travelDate != null 
          ? DateFormat('yyyy-MM-dd').format(bus.travelDate)
          : '';
      
      // Find the route for this bus
      try {
        final routes = context.read<RouteService>().routes;
        _selectedRoute = routes.firstWhere((r) => r.id == bus.routeId);
      } catch (e) {
        debugPrint('Could not find route for bus: $e');
        _selectedRoute = null;
      }
    } else {
      _busNumberController.clear();
      _busNameController.clear();
      _capacityController.clear();
      _typeController.clear();
      _priceController.clear();
      _departureTimeController.clear();
      _arrivalTimeController.clear();
      _dateController.clear();
      _selectedRoute = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(bus == null ? 'Add New Bus' : 'Edit Bus'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _busNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Bus Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _busNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bus Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final number = int.tryParse(value!);
                      if (number == null || number <= 0) return 'Invalid capacity';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Bus Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final number = double.tryParse(value!);
                      if (number == null || number <= 0) return 'Invalid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<RouteService>(
                    builder: (context, routeService, child) {
                      final routes = routeService.routes;
                      return DropdownButtonFormField<route_model.Route>(
                        value: _selectedRoute,
                        decoration: const InputDecoration(
                          labelText: 'Select Route',
                          border: OutlineInputBorder(),
                        ),
                        items: routes.map((route) {
                          return DropdownMenuItem<route_model.Route>(
                            value: route,
                            child: Text('${route.startLocation} to ${route.endLocation}'),
                          );
                        }).toList(),
                        onChanged: (route) {
                          setState(() {
                            _selectedRoute = route;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a route' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateController.text.isNotEmpty 
                            ? DateTime.parse(_dateController.text)
                            : DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        selectableDayPredicate: (DateTime date) {
                          return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
                        },
                      );
                      if (date != null) {
                        setState(() {
                          _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Travel Date',
                        border: const OutlineInputBorder(),
                        errorText: _dateController.text.isEmpty ? 'Travel date is required' : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_dateController.text.isEmpty 
                            ? 'Select Date' 
                            : _dateController.text),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _departureTimeController.text = 
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Departure Time',
                        border: const OutlineInputBorder(),
                        errorText: _departureTimeController.text.isEmpty ? 'Required' : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_departureTimeController.text.isEmpty 
                            ? 'Select Time' 
                            : _departureTimeController.text),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _arrivalTimeController.text = 
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Arrival Time',
                        border: const OutlineInputBorder(),
                        errorText: _arrivalTimeController.text.isEmpty ? 'Required' : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_arrivalTimeController.text.isEmpty 
                            ? 'Select Time' 
                            : _arrivalTimeController.text),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
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
              onPressed: isProcessing ? null : () async {
                if (!formKey.currentState!.validate() || 
                    _dateController.text.isEmpty ||
                    _departureTimeController.text.isEmpty ||
                    _arrivalTimeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                setState(() => isProcessing = true);

                try {
                  final busService = context.read<BusService>();
                  final newBus = Bus(
                    id: bus?.id,
                    busNumber: _busNumberController.text,
                    busName: _busNameController.text,
                    capacity: int.parse(_capacityController.text),
                    type: _typeController.text,
                    routeId: _selectedRoute!.id!,
                    departureTime: _departureTimeController.text,
                    arrivalTime: _arrivalTimeController.text,
                    totalSeats: int.parse(_capacityController.text),
                    availableSeats: int.parse(_capacityController.text),
                    price: double.parse(_priceController.text),
                    fromLocation: _selectedRoute!.startLocation,
                    toLocation: _selectedRoute!.endLocation,
                    travelDate: DateTime.parse(_dateController.text),
                  );

                  if (bus == null) {
                    await busService.createBus(newBus);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bus added successfully')),
                      );
                    }
                  } else {
                    await busService.updateBus(newBus);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bus updated successfully')),
                      );
                    }
                  }
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                } finally {
                  if (mounted) {
                    setState(() => isProcessing = false);
                  }
                }
              },
              child: Text(bus == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Buses'),
      ),
      body: Consumer<BusService>(
        builder: (context, busService, child) {
          return FutureBuilder<List<Bus>>(
            future: busService.getAllBuses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final buses = snapshot.data ?? [];

              if (buses.isEmpty) {
                return const Center(child: Text('No buses available'));
              }

              return ListView.builder(
                itemCount: buses.length,
                itemBuilder: (context, index) {
                  final bus = buses[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text('Bus Number: ${bus.busNumber}'),
                      subtitle: Text(
                        'Type: ${bus.type}\nCapacity: ${bus.capacity} seats',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showAddEditBusDialog(bus),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Bus'),
                                  content: const Text(
                                    'Are you sure you want to delete this bus?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        try {
                                          await busService.deleteBus(bus.id!);
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Bus deleted successfully'),
                                            ),
                                          );
                                        } catch (e) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: ${e.toString()}'),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBusDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
} 