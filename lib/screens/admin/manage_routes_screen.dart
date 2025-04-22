import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/route_service.dart';
import '../../models/route.dart' as route_model;

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _viaLocationsController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  route_model.Route? _editingRoute;

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    _viaLocationsController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddRouteDialog() {
    _editingRoute = null;
    _startLocationController.clear();
    _endLocationController.clear();
    _viaLocationsController.clear();
    _distanceController.clear();
    _durationController.clear();
    _descriptionController.clear();
    _showRouteDialog();
  }

  void _showEditRouteDialog(route_model.Route route) {
    _editingRoute = route;
    _startLocationController.text = route.startLocation;
    _endLocationController.text = route.endLocation;
    _viaLocationsController.text = route.viaLocations;
    _distanceController.text = route.distance.toString();
    _durationController.text = route.estimatedDuration.toString();
    _descriptionController.text = route.description;
    _showRouteDialog();
  }

  void _showRouteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingRoute == null ? 'Add Route' : 'Edit Route'),
        content: SingleChildScrollView(
          child: Form(
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter start location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endLocationController,
                  decoration: const InputDecoration(
                    labelText: 'End Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter end location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _viaLocationsController,
                  decoration: const InputDecoration(
                    labelText: 'Via Locations (optional)',
                    border: OutlineInputBorder(),
                  ),
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter distance';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: _isLoading ? null : _saveRoute,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(_editingRoute == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final route = route_model.Route(
        id: _editingRoute?.id,
        startLocation: _startLocationController.text,
        endLocation: _endLocationController.text,
        viaLocations: _viaLocationsController.text,
        distance: double.parse(_distanceController.text),
        estimatedDuration: int.parse(_durationController.text),
        description: _descriptionController.text,
        isActive: _editingRoute?.isActive ?? true,
      );

      if (_editingRoute == null) {
        await context.read<RouteService>().createRoute(route);
      } else {
        await context.read<RouteService>().updateRoute(route);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingRoute == null
                  ? 'Route added successfully'
                  : 'Route updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRoute(route_model.Route route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text(
          'Are you sure you want to delete the route from ${route.startLocation} to ${route.endLocation}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<RouteService>().deleteRoute(route.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting route: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
      ),
      body: Consumer<RouteService>(
        builder: (context, routeService, child) {
          if (routeService.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final routes = routeService.routes;
          if (routes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No routes available'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddRouteDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Route'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                child: ListTile(
                  title: Text('${route.startLocation} to ${route.endLocation}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (route.viaLocations.isNotEmpty)
                        Text('Via: ${route.viaLocations}'),
                      Text(
                        'Distance: ${route.distance}km • Duration: ${route.estimatedDuration}min',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: route.isActive,
                        onChanged: (value) async {
                          final updatedRoute = route.copyWith(isActive: value);
                          await context
                              .read<RouteService>()
                              .updateRoute(updatedRoute);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditRouteDialog(route),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () => _deleteRoute(route),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRouteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 