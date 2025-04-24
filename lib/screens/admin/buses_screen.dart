import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/bus_service.dart';
import '../../services/route_service.dart';
import '../../models/bus.dart';
import '../../models/route.dart';

class BusesScreen extends StatefulWidget {
  const BusesScreen({Key? key}) : super(key: key);

  @override
  State<BusesScreen> createState() => _BusesScreenState();
}

class _BusesScreenState extends State<BusesScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _busNameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _dateController = TextEditingController();
  BusRoute? _selectedRoute;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize the BusService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BusService>().initialize();
      }
    });
  }

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

  Future<void> _selectTime(BuildContext context, bool isArrival) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = 
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isArrival) {
          _arrivalTimeController.text = formattedTime;
        } else {
          _departureTimeController.text = formattedTime;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty 
          ? DateTime.parse(_dateController.text)
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _showAddEditBusDialog([Bus? bus]) {
    if (bus != null) {
      _busNumberController.text = bus.busNumber;
      _busNameController.text = bus.busName;
      _capacityController.text = bus.capacity.toString();
      _typeController.text = bus.type;
      _priceController.text = bus.price.toString();
      _departureTimeController.text = bus.departureTime;
      _arrivalTimeController.text = bus.arrivalTime;
      _dateController.text = bus.travelDate != null 
          ? DateFormat('yyyy-MM-dd').format(bus.travelDate!)
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
      builder: (context) => AlertDialog(
        title: Text(bus == null ? 'Add New Bus' : 'Edit Bus'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                    labelText: 'Price (RWF)',
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
                    return DropdownButtonFormField<BusRoute>(
                      value: _selectedRoute,
                      decoration: const InputDecoration(
                        labelText: 'Select Route',
                        border: OutlineInputBorder(),
                      ),
                      items: routes.map((route) {
                        return DropdownMenuItem<BusRoute>(
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
                TextFormField(
                  controller: _departureTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Departure Time',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectTime(context, false),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _arrivalTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Arrival Time',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectTime(context, true),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Travel Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
            onPressed: _isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;

                    setState(() => _isLoading = true);

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
                        status: 'active',
                        registrationNumber: _busNumberController.text,
                      );

                      if (bus == null) {
                        await busService.createBus(newBus);
                      } else {
                        await busService.updateBus(newBus);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              bus == null
                                  ? 'Bus added successfully'
                                  : 'Bus updated successfully',
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
                : Text(bus == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buses',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
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
                          'All Buses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditBusDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Bus'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<BusService>(
                      builder: (context, busService, child) {
                        if (!busService.isInitialized) {
                          return const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final buses = busService.buses;
                        if (buses.isEmpty) {
                          return const SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(
                                'No buses found',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: buses.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final bus = buses[index];
                                return RepaintBoundary(
                                  child: Material(
                                    type: MaterialType.card,
                                    color: Theme.of(context).cardColor,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        '${bus.busNumber} - ${bus.busName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            'Route: ${bus.fromLocation} to ${bus.toLocation}',
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Capacity: ${bus.capacity} seats • Type: ${bus.type}',
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Price: RWF ${bus.price} • Travel Date: ${DateFormat('yyyy-MM-dd').format(bus.travelDate!)}',
                                          ),
                                        ],
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
                                            onPressed: () => _showDeleteConfirmation(context, bus),
                                          ),
                                        ],
                                      ),
                                    ),
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
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text('Are you sure you want to delete ${bus.busName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<BusService>().deleteBus(bus.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bus deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 