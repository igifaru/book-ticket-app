import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/route.dart' as route_model;
import '../../services/route_service.dart';

class RouteManagementScreen extends StatefulWidget {
  final route_model.Route? route;
  
  const RouteManagementScreen({super.key, this.route});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _viaLocationsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.route != null) {
      _startLocationController.text = widget.route!.startLocation;
      _endLocationController.text = widget.route!.endLocation;
      _viaLocationsController.text = widget.route!.viaLocations;
      _descriptionController.text = widget.route!.description;
      _distanceController.text = widget.route!.distance.toString();
      _durationController.text = widget.route!.estimatedDuration.toString();
      _isActive = widget.route!.isActive;
    }
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    _viaLocationsController.dispose();
    _descriptionController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final routeService = context.read<RouteService>();
      final route = route_model.Route(
        id: widget.route?.id,
        startLocation: _startLocationController.text,
        endLocation: _endLocationController.text,
        viaLocations: _viaLocationsController.text,
        distance: double.parse(_distanceController.text),
        estimatedDuration: int.parse(_durationController.text),
        description: _descriptionController.text,
        isActive: widget.route?.isActive ?? true,
      );

      if (widget.route == null) {
        await routeService.createRoute(route);
      } else {
        await routeService.updateRoute(route);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving route: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route == null ? 'Add Route' : 'Edit Route'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  labelText: 'Via Locations (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
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
                  labelText: 'Estimated Duration (minutes)',
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
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRoute,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(widget.route == null ? 'Add Route' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 