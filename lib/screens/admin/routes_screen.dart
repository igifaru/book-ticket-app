import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/route_service.dart';
import '../../models/route.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _showAddEditRouteDialog([BusRoute? route]) {
    if (route != null) {
      _startLocationController.text = route.fromLocation;
      _endLocationController.text = route.toLocation;
      _distanceController.text = route.distance.toString();
      _durationController.text = route.duration.toString();
    } else {
      _startLocationController.clear();
      _endLocationController.clear();
      _distanceController.clear();
      _durationController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route == null ? 'Add New Route' : 'Edit Route'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _startLocationController,
                decoration: const InputDecoration(
                  labelText: 'Start Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _endLocationController,
                decoration: const InputDecoration(
                  labelText: 'End Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance (km)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
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
            onPressed: _isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;

                    setState(() => _isLoading = true);

                    try {
                      final routeService = context.read<RouteService>();
                      if (route == null) {
                        final newRoute = BusRoute(
                          fromLocation: _startLocationController.text,
                          toLocation: _endLocationController.text,
                          distance: double.parse(_distanceController.text),
                          duration: double.parse(_durationController.text),
                          price: 0.0, // Default price
                        );
                        await routeService.addRoute(newRoute);
                      } else {
                        final updatedRoute = BusRoute(
                          id: route.id,
                          fromLocation: _startLocationController.text,
                          toLocation: _endLocationController.text,
                          distance: double.parse(_distanceController.text),
                          duration: double.parse(_durationController.text),
                          price: route.price,
                          createdAt: route.createdAt,
                          updatedAt: DateTime.now(),
                        );
                        await routeService.updateRoute(updatedRoute);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              route == null
                                  ? 'Route added successfully'
                                  : 'Route updated successfully',
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
                : Text(route == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Routes',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditRouteDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Route'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<RouteService>(
            builder: (context, routeService, child) {
              return FutureBuilder<List<BusRoute>>(
                future: routeService.getAllRoutes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final routes = snapshot.data ?? [];
                  if (routes.isEmpty) {
                    return const Center(child: Text('No routes found'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            '${route.fromLocation} to ${route.toLocation}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Distance: ${route.distance}km • Duration: ${route.duration} minutes',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showAddEditRouteDialog(route),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Route'),
                                      content: const Text(
                                        'Are you sure you want to delete this route?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            try {
                                              await routeService
                                                  .deleteRoute(route.id!);
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Route deleted successfully',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content:
                                                      Text('Error: ${e.toString()}'),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
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
        ],
      ),
    );
  }
} 