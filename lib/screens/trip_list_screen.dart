import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../state/trip_provider.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  @override
  void initState() {
    super.initState();
    // Load trips when screen initializes
    Future.microtask(() => context.read<TripProvider>().loadInitialTrips());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Notifier - Trips'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TripProvider>().syncTrips();
            },
          ),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, tripProvider, child) {
          if (tripProvider.isLoading && tripProvider.trips.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tripProvider.error != null && tripProvider.trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(tripProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      tripProvider.clearError();
                      tripProvider.syncTrips();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (tripProvider.trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flight, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No trips found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => tripProvider.syncTrips(),
                    child: const Text('Load Trips'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => tripProvider.syncTrips(),
            child: ListView.builder(
              itemCount: tripProvider.trips.length + 1,
              itemBuilder: (context, index) {
                if (index == tripProvider.trips.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (tripProvider.lastSyncTime != null)
                          Text(
                            'Last synced: ${DateFormat('HH:mm:ss').format(tripProvider.lastSyncTime!)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        if (tripProvider.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final trip = tripProvider.trips[index];
                return _TripCard(trip: trip);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSimulationDialog(context);
        },
        tooltip: 'Simulate Background Update',
        child: const Icon(Icons.cloud_download),
      ),
    );
  }

  void _showSimulationDialog(BuildContext context) {
    final tripProvider = context.read<TripProvider>();
    if (tripProvider.trips.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No trips to update')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _SimulationDialog(
        trips: tripProvider.trips,
        onUpdate: (tripId, status) {
          Navigator.pop(context);
          tripProvider.simulateBackgroundUpdate(tripId, status);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Background update simulated'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: trip.getStatusColor(), width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flight number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trip.flightNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: trip.getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trip.getStatusString(),
                      style: TextStyle(
                        color: trip.getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Route
              Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${trip.origin} → ${trip.destination}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Time and Gate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(trip.scheduledTime),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.door_sliding,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Gate ${trip.gate}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Last updated
              Text(
                'Updated: ${DateFormat('MMM d, HH:mm').format(trip.lastUpdated)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulationDialog extends StatefulWidget {
  final List<Trip> trips;
  final Function(String, TripStatus) onUpdate;

  const _SimulationDialog({required this.trips, required this.onUpdate});

  @override
  State<_SimulationDialog> createState() => _SimulationDialogState();
}

class _SimulationDialogState extends State<_SimulationDialog> {
  late String _selectedTripId;
  late TripStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedTripId = widget.trips.first.id;
    _selectedStatus = TripStatus.delayed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Simulate Background Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select a trip and new status to simulate a background update:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedTripId,
            items: widget.trips.map((trip) {
              return DropdownMenuItem(
                value: trip.id,
                child: Text(trip.flightNumber),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedTripId = value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButton<TripStatus>(
            isExpanded: true,
            value: _selectedStatus,
            items: TripStatus.values.map((status) {
              final trip = widget.trips.firstWhere(
                (t) => t.id == _selectedTripId,
              );
              final statusString = trip
                  .copyWith(status: status)
                  .getStatusString();
              return DropdownMenuItem(value: status, child: Text(statusString));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatus = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onUpdate(_selectedTripId, _selectedStatus);
          },
          child: const Text('Simulate'),
        ),
      ],
    );
  }
}
