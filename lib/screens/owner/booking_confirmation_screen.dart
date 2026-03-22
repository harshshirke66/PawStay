import 'package:flutter/material.dart';
import 'package:paw_stay/models/host.dart';
import 'package:paw_stay/utils/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:paw_stay/screens/owner/add_pet_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Host host;
  final DateTimeRange dateRange;

  const BookingConfirmationScreen({
    super.key,
    required this.host,
    required this.dateRange,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<dynamic> _pets = [];
  dynamic _selectedPet;
  bool _isLoading = false;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _fetchPets();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  Future<void> _fetchPets() async {
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('pets')
          .select()
          .eq('owner_id', user!.id);
      setState(() {
        _pets = data as List<dynamic>;
        if (_pets.isNotEmpty) _selectedPet = _pets[0];
      });
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    }
  }

  void _confirmBooking() {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a pet')));
      return;
    }

    final int nights = widget.dateRange.duration.inDays;
    final double total = widget.host.price * nights;

    final options = {
      'key': 'rzp_test_S2fMyRh9KI4PVG',
      'amount': (total * 100)
          .toInt(), // amount in the smallest currency sub-unit
      'name': 'PawStay Booking',
      'description': 'Booking ${widget.host.name} for $nights nights',
      'prefill': {
        'contact': '9876543210',
        'email': user?.email ?? 'test@test.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error starting Razorpay checkout: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed. ${response.message ?? "Try again."}'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet selected: ${response.walletName}')),
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('bookings').insert({
        'owner_id': user!.id,
        'host_id': widget.host.id,
        'pet_id': _selectedPet['id'],
        'start_date': widget.dateRange.start.toIso8601String(),
        'end_date': widget.dateRange.end.toIso8601String(),
        'total_price': widget.host.price * (widget.dateRange.duration.inDays),
        'status': 'confirmed', // Confirmed directly since it's paid
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.accent,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Booking Confirmed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your stay with ${widget.host.name} is successfully booked.\nPayment ID: ${response.paymentId}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int nights = widget.dateRange.duration.inDays;
    double total = widget.host.price * nights;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Confirm Order',
          style: TextStyle(
            color: AppTheme.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.host.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.host.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.host.location,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppTheme.highlight,
                            ),
                            Text(
                              ' ${widget.host.rating} (124 reviews)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Text(
              'Your trip',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dates',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('MMM d').format(widget.dateRange.start)} – ${DateFormat('MMM d').format(widget.dateRange.end)}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: AppTheme.textMain,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            const Text(
              'Select your pet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 16),

            if (_pets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add a pet profile to continue',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPetScreen(),
                          ),
                        );
                        if (result == true) {
                          _fetchPets();
                        }
                      },
                      child: const Text('Add Now'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<dynamic>(
                initialValue: _selectedPet,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMain,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.pets_rounded, size: 20),
                ),
                items: _pets.map((pet) {
                  return DropdownMenuItem<dynamic>(
                    value: pet,
                    child: Text(pet['name']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPet = val),
              ),

            const SizedBox(height: 48),
            const Text(
              'Price details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 24),

            _buildPriceRow(
              '₹${widget.host.price.toInt()} x $nights nights',
              '₹${total.toInt()}',
            ),
            const SizedBox(height: 12),
            _buildPriceRow('PawStay service fee', '₹0.00', isUnderlined: true),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total (INR)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.textMain,
                  ),
                ),
                Text(
                  '₹${total.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 56),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm and Reserve',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isUnderlined = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textMain,
            decoration: isUnderlined ? TextDecoration.underline : null,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}
