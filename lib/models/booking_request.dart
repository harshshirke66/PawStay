// lib/models/booking_request.dart

class BookingRequest {
  final String id;
  final String petName;
  final String petBreed;
  final String ownerName;
  final String dateRange;
  final double totalPrice;
  final int nights;
  final String status; // Pending, Approved, etc.

  BookingRequest({
    required this.id,
    required this.petName,
    required this.petBreed,
    required this.ownerName,
    required this.dateRange,
    required this.totalPrice,
    required this.nights,
    this.status = 'Pending',
  });
}
