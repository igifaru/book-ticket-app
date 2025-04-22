import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/route_service.dart';
import '../services/bus_service.dart';
import '../models/route.dart' as route_model;
import '../models/bus.dart';
import 'bus_details_screen.dart';

class SearchBookTicketsScreen extends StatefulWidget {
  const SearchBookTicketsScreen({super.key});

  @override
  State<SearchBookTicketsScreen> createState() => _SearchBookTicketsScreenState();
}

class _SearchBookTicketsScreenState extends State<SearchBookTicketsScreen> {
  route_model.Route? selectedRoute;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  List<Bus>? searchResults;
  String? error;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _searchBuses() async {
    if (selectedRoute == null) {
      setState(() {
        error = 'Please select a route';
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final buses = await context.read<BusService>().searchBuses(
            routeId: selectedRoute!.id!,
            date: selectedDate,
          );
      setState(() {
        searchResults = buses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to search buses: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Book Tickets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Route Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<RouteService>(
                      builder: (context, routeService, child) {
                        if (routeService.loading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return DropdownButtonFormField<route_model.Route>(
                          value: selectedRoute,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Select a route',
                          ),
                          items: routeService.routes.map((route) {
                            return DropdownMenuItem(
                              value: route,
                              child: Text(
                                '${route.startLocation} to ${route.endLocation}',
                              ),
                            );
                          }).toList(),
                          onChanged: (route) {
                            setState(() {
                              selectedRoute = route;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontSize: 16),
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
            const SizedBox(height: 24),
            // Search Button
            ElevatedButton(
              onPressed: isLoading ? null : _searchBuses,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Search Buses',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            // Search Results
            if (searchResults != null) ...[
              const Text(
                'Available Buses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: searchResults!.isEmpty
                    ? const Center(
                        child: Text('No buses available for selected route and date'),
                      )
                    : ListView.builder(
                        itemCount: searchResults!.length,
                        itemBuilder: (context, index) {
                          final bus = searchResults![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(bus.busName),
                              subtitle: Text(
                                'Departure: ${bus.departureTime}\nAvailable Seats: ${bus.availableSeats}',
                              ),
                              trailing: Text(
                                '₹${bus.price}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BusDetailsScreen(
                                      bus: bus,
                                      selectedDate: selectedDate,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 