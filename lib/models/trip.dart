import 'package:flutter/foundation.dart';

enum TripStatus { onTime, delayed, gateChanged, cancelled }

class Trip {
  final String id;
  final String flightNumber;
  final String origin;
  final String destination;
  final TripStatus status;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final int gate;
  final DateTime lastUpdated;

  Trip({
    required this.id,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.status,
    required this.scheduledTime,
    this.actualTime,
    required this.gate,
    required this.lastUpdated,
  });

  /// Get human-readable status string
  String getStatusString() {
    switch (status) {
      case TripStatus.onTime:
        return 'On Time';
      case TripStatus.delayed:
        return 'Delayed';
      case TripStatus.gateChanged:
        return 'Gate Changed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get status color for UI
  Color getStatusColor() {
    switch (status) {
      case TripStatus.onTime:
        return const Color(0xFF4CAF50); // Green
      case TripStatus.delayed:
        return const Color(0xFFFF9800); // Orange
      case TripStatus.gateChanged:
        return const Color(0xFF2196F3); // Blue
      case TripStatus.cancelled:
        return const Color(0xFFF44336); // Red
    }
  }

  /// Convert Trip to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'flightNumber': flightNumber,
    'origin': origin,
    'destination': destination,
    'status': status.toString().split('.').last,
    'scheduledTime': scheduledTime.toIso8601String(),
    'actualTime': actualTime?.toIso8601String(),
    'gate': gate,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  /// Create Trip from JSON
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      flightNumber: json['flightNumber'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      status: _parseStatus(json['status'] as String),
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      actualTime: json['actualTime'] != null
          ? DateTime.parse(json['actualTime'] as String)
          : null,
      gate: json['gate'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Parse status string to enum
  static TripStatus _parseStatus(String status) {
    switch (status) {
      case 'onTime':
        return TripStatus.onTime;
      case 'delayed':
        return TripStatus.delayed;
      case 'gateChanged':
        return TripStatus.gateChanged;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.onTime;
    }
  }

  /// Create a copy with modified fields
  Trip copyWith({
    String? id,
    String? flightNumber,
    String? origin,
    String? destination,
    TripStatus? status,
    DateTime? scheduledTime,
    DateTime? actualTime,
    int? gate,
    DateTime? lastUpdated,
  }) {
    return Trip(
      id: id ?? this.id,
      flightNumber: flightNumber ?? this.flightNumber,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      gate: gate ?? this.gate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() => 'Trip(id: $id, flight: $flightNumber, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          gate == other.gate;

  @override
  int get hashCode => id.hashCode ^ status.hashCode ^ gate.hashCode;
}
