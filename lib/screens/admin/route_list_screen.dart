import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/route.dart' as route_model;
import '../../services/route_service.dart';
import 'route_management_screen.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  List<route_model.Route> _routes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final routeService = context.read<RouteService>();
      _routes = await routeService.getAllRoutes();
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

  Future<void> _deleteRoute(route_model.Route route) async {
    try {
      final routeService = context.read<RouteService>();
      await routeService.deleteRoute(route.id!);
      await _loadRoutes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting route: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${route.startLocation} to ${route.endLocation}'),
                    subtitle: Text(route.viaLocations),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _navigateToRouteManagement(route),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Route'),
                                content: Text(
                                    'Are you sure you want to delete this route?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await _deleteRoute(route);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToRouteManagement(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _navigateToRouteManagement([route_model.Route? route]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteManagementScreen(route: route),
      ),
    );
    await _loadRoutes();
  }
}