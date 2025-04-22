import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus.dart';
import '../models/route.dart' as route_model;
import '../services/bus_service.dart';
import '../services/route_service.dart';
import 'booking_screen.dart';
import 'package:intl/intl.dart';

class BusSearchScreen extends StatefulWidget {
  final route_model.Route? selectedRoute;

  const BusSearchScreen({
    super.key,
    this.selectedRoute,
  });

  @override
  State<BusSearchScreen> createState() => _BusSearchScreenState();
}

class _BusSearchScreenState extends State<BusSearchScreen> {
  route_model.Route? _selectedRoute;
  DateTime? _selectedDate;
  List<Bus> _buses = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.selectedRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoutes();
    });
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final routeService = context.read<RouteService>();
      await routeService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading routes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchBuses() async {
    if (_selectedRoute == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route and date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final busService = context.read<BusService>();
      final searchDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      debugPrint('Searching buses for route: ${_selectedRoute!.id}, date: $searchDate');
      
      final buses = await busService.searchBuses(
        routeId: _selectedRoute!.id!,
        date: searchDate,
      );
      
      debugPrint('Search completed. Found ${buses.length} buses');
      
      if (mounted) {
        setState(() {
          _buses = buses;
          if (buses.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No buses available for the selected route and date. Please try a different date or route.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error during bus search: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching buses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeService = context.watch<RouteService>();
    final routes = routeService.routes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Buses'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (routeService.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (routes.isEmpty)
              const Center(
                child: Text('No routes available. Please try again later.'),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Route and Date',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<route_model.Route>(
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
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                            selectableDayPredicate: (DateTime date) {
                              return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
                            },
                          );
                          if (date != null && mounted) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Travel Date',
                            border: const OutlineInputBorder(),
                            errorText: _hasSearched && _selectedDate == null ? 'Please select a date' : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
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
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
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
                      return Card(
                        child: ListTile(
                          title: Text(bus.busName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Route: ${_selectedRoute!.startLocation} to ${_selectedRoute!.endLocation}'),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingScreen(
                                  bus: bus,
                                  route: _selectedRoute!,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
} 