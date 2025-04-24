import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus.dart';
import '../models/route.dart' as route_model;
import '../services/bus_service.dart';
import '../services/route_service.dart';
import '../utils/database_helper.dart';
import 'booking_screen.dart';
import 'package:intl/intl.dart';

class BusSearchScreen extends StatefulWidget {
  final route_model.BusRoute? selectedRoute;

  const BusSearchScreen({
    super.key,
    this.selectedRoute,
  });

  @override
  State<BusSearchScreen> createState() => _BusSearchScreenState();
}

class _BusSearchScreenState extends State<BusSearchScreen> {
  late final RouteService _routeService;
  late final BusService _busService;
  
  List<route_model.BusRoute> _routes = [];
  route_model.BusRoute? _selectedRoute;
  DateTime? _selectedDate;
  List<Bus> _buses = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.selectedRoute;
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final databaseHelper = DatabaseHelper();
    _routeService = RouteService(databaseHelper: databaseHelper);
    _busService = BusService(databaseHelper: databaseHelper);
    await _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final routes = await _routeService.getAllRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading routes: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _searchBuses() async {
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final buses = await _busService.searchBuses(
        routeId: _selectedRoute!.id ?? 0,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      );
      setState(() {
        _buses = buses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching buses: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Buses'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<route_model.BusRoute>(
                      value: _selectedRoute,
                      decoration: const InputDecoration(
                        labelText: 'Select Route',
                        border: OutlineInputBorder(),
                      ),
                      items: _routes.map((route) {
                        return DropdownMenuItem<route_model.BusRoute>(
                          value: route,
                          child: Text('${route.startLocation} to ${route.endLocation}'),
                        );
                      }).toList(),
                      onChanged: _isLoading ? null : (route_model.BusRoute? route) {
                        setState(() {
                          _selectedRoute = route;
                          _hasSearched = false;
                          _buses.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _isLoading ? null : () => _selectDate(context),
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: 'Select Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _searchBuses,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Search Buses',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            if (_hasSearched) ...[
              const SizedBox(height: 24),
              if (_buses.isEmpty && !_isLoading)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No buses available for the selected route and date',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else if (_buses.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _buses.length,
                  itemBuilder: (context, index) {
                    final bus = _buses[index];
                    return BusListItem(
                      bus: bus,
                      route: _selectedRoute!,
                      onTap: () => _navigateToBooking(context, bus),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToBooking(BuildContext context, Bus bus) {
    // Convert BusRoute to Route
    final route = route_model.Route(
      id: _selectedRoute!.id,
      startLocation: _selectedRoute!.startLocation,
      endLocation: _selectedRoute!.endLocation,
      viaLocations: '',
      distance: _selectedRoute!.distance,
      estimatedDuration: _selectedRoute!.duration.toInt(),
      description: '${_selectedRoute!.startLocation} to ${_selectedRoute!.endLocation}',
      isActive: true,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          bus: bus,
          route: route,
        ),
      ),
    );
  }
}

class BusListItem extends StatelessWidget {
  final Bus bus;
  final route_model.BusRoute route;
  final VoidCallback onTap;

  const BusListItem({
    super.key,
    required this.bus,
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(bus.busName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route: ${route.startLocation} to ${route.endLocation}'),
            Text('Departure: ${bus.departureTime}'),
            Text('Available Seats: ${bus.availableSeats}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              bus.formattedPrice,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text('per seat'),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
} 