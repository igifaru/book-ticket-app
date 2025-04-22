import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/route.dart' as route_model;
import '../../models/bus.dart';
import '../../services/bus_service.dart';
import '../../services/route_service.dart';

class AddBusScreen extends StatefulWidget {
  const AddBusScreen({super.key});

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _busNameController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _totalSeatsController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _typeController = TextEditingController();
  final _travelDateController = TextEditingController();
  List<route_model.Route> _routes = [];
  route_model.Route? _selectedRoute;
  bool _isLoading = false;
  DateTime? _selectedTravelDate;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final routeService = Provider.of<RouteService>(context, listen: false);
      final routes = await routeService.getAllRoutes();
      setState(() {
        _routes = routes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load routes: $e')));
      }
    }
  }

  Future<void> _selectTime(
    BuildContext context, {
    bool isArrival = false,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isArrival) {
          _arrivalTimeController.text =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        } else {
          _departureTimeController.text =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTravelDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedTravelDate = picked;
        _travelDateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _addBus() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a route')));
      return;
    }
    if (_selectedTravelDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a travel date')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bus = Bus(
        busNumber: _busNumberController.text,
        capacity: int.parse(_capacityController.text),
        type: _typeController.text,
        busName: _busNameController.text,
        routeId: _selectedRoute!.id!,
        departureTime: _departureTimeController.text,
        arrivalTime: _arrivalTimeController.text,
        totalSeats: int.parse(_capacityController.text),
        availableSeats: int.parse(_capacityController.text),
        price: double.parse(_priceController.text),
        fromLocation: _selectedRoute!.startLocation,
        toLocation: _selectedRoute!.endLocation,
        status: 'active',
        createdAt: DateTime.now(),
        travelDate: _selectedTravelDate!,
      );

      final busService = Provider.of<BusService>(context, listen: false);
      await busService.createBus(bus);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bus added successfully')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add bus: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _busNameController.dispose();
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    _totalSeatsController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _typeController.dispose();
    _travelDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Bus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _busNumberController,
                decoration: const InputDecoration(
                  labelText: 'Bus Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bus number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _busNameController,
                decoration: const InputDecoration(
                  labelText: 'Bus Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bus name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<route_model.Route>(
                decoration: const InputDecoration(
                  labelText: 'Route',
                  border: OutlineInputBorder(),
                ),
                value: _selectedRoute,
                items:
                    _routes.map((route) {
                      return DropdownMenuItem<route_model.Route>(
                        value: route,
                        child: Text(
                          '${route.startLocation} to ${route.endLocation}',
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoute = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a route';
                  }
                  return null;
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
                onTap: () => _selectTime(context, isArrival: false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select departure time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _arrivalTimeController,
                decoration: const InputDecoration(
                  labelText: 'Arrival Time',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectTime(context, isArrival: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select arrival time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalSeatsController,
                decoration: const InputDecoration(
                  labelText: 'Total Seats',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total seats';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number of seats';
                  }
                  return null;
                },
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _travelDateController,
                decoration: const InputDecoration(
                  labelText: 'Travel Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select travel date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addBus,
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Add Bus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
