// lib/screens/available_buses_screen.dart
import 'package:flutter/material.dart';
import 'package:tickiting/models/bus.dart';
import 'package:tickiting/screens/payment_screen.dart';
import 'package:tickiting/utils/theme.dart';
import 'package:tickiting/utils/database_helper.dart';

class AvailableBusesScreen extends StatefulWidget {
  final String from;
  final String to;
  final DateTime date;
  final int passengers;

  const AvailableBusesScreen({
    Key? key,
    required this.from,
    required this.to,
    required this.date,
    required this.passengers,
  }) : super(key: key);

  @override
  _AvailableBusesScreenState createState() => _AvailableBusesScreenState();
}

class _AvailableBusesScreenState extends State<AvailableBusesScreen> {
  List<Bus> availableBuses = [];
  bool _isLoading = true;
  String _sortBy = 'Departure Time';

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load buses from database
      List<Bus> allBuses = await DatabaseHelper().getAllBuses();

      // In a real app, you might filter buses based on route, date, etc.
      // For now, we'll just use all buses
      setState(() {
        availableBuses = allBuses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading buses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey[200],
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, Bus bus) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Bus name and type
            Row(
              children: [
                Text(
                  bus.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bus.busType == 'Premium'
                        ? Colors.amber[100]
                        : bus.busType == 'Standard'
                            ? Colors.blue[100]
                            : Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bus.busType,
                    style: TextStyle(
                      color: bus.busType == 'Premium'
                          ? Colors.amber[800]
                          : bus.busType == 'Standard'
                              ? Colors.blue[800]
                              : Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Time and duration
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.departureTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.from,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        bus.duration,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 2,
                            color: Colors.grey[300],
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bus.arrivalTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.to,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Features
            Wrap(
              spacing: 8,
              children: bus.features
                  .map(
                    (feature) => Chip(
                      label: Text(feature),
                      backgroundColor: Colors.grey[200],
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 15),
            // Price and book button
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price per person',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${bus.price} RWF',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${bus.availableSeats} seats left',
                  style: TextStyle(
                    color: bus.availableSeats < 5 ? Colors.red : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          bus: bus,
                          from: widget.from,
                          to: widget.to,
                          date: widget.date,
                          passengers: widget.passengers,
                        ),
                      ),
                    );
                  },
                  child: const Text('Book Now'),
                ),
              ],
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
        title: const Text('Available Buses'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Trip details summary
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.from} to ${widget.to}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${widget.date.day}/${widget.date.month}/${widget.date.year} • ${widget.passengers} ${widget.passengers > 1 ? 'Passengers' : 'Passenger'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Modify'),
                ),
              ],
            ),
          ),
          // Filter options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Sort by:'),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Departure Time',
                          _sortBy == 'Departure Time',
                        ),
                        _buildFilterChip('Price', _sortBy == 'Price'),
                        _buildFilterChip('Duration', _sortBy == 'Duration'),
                        _buildFilterChip(
                          'Available Seats',
                          _sortBy == 'Available Seats',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bus list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : availableBuses.isEmpty
                    ? const Center(
                        child: Text('No buses available for this route'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBuses,
                        child: ListView.builder(
                          itemCount: availableBuses.length,
                          itemBuilder: (context, index) {
                            final bus = availableBuses[index];
                            return _buildBusCard(context, bus);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}