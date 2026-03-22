import 'package:flutter/material.dart';
import 'package:paw_stay/models/host.dart';
import 'package:paw_stay/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:paw_stay/screens/owner/booking_confirmation_screen.dart';
import 'package:paw_stay/services/wishlist_service.dart';
import 'package:paw_stay/screens/owner/chat_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';

class HostDetailScreen extends StatefulWidget {
  final Host host;

  const HostDetailScreen({super.key, required this.host});

  @override
  State<HostDetailScreen> createState() => _HostDetailScreenState();
}

class _HostDetailScreenState extends State<HostDetailScreen> {
  DateTimeRange? _selectedDateRange;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Hero Image with Glass Buttons
          SliverAppBar(
            expandedHeight: 480,
            pinned: true,
            stretch: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'host_image_${widget.host.id}',
                    child: Image.network(
                      widget.host.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black45,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    _buildGlassButton(
                      icon: Icons.share_rounded,
                      onTap: () {
                        Share.share(
                          'Check out this amazing pet stay: ${widget.host.title} in ${widget.host.location}! Download PawStay to book.',
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    ListenableBuilder(
                      listenable: WishlistService(),
                      builder: (context, child) {
                        final isWishlisted = WishlistService().isWishlisted(
                          widget.host.id,
                        );
                        return _buildGlassButton(
                          icon: isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isWishlisted
                              ? Colors.redAccent
                              : AppTheme.textMain,
                          onTap: () {
                            WishlistService().toggleWishlist(widget.host.id);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Verification Badge
                if (widget.host.isVerified)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: AppTheme.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI Verified Stay',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Text(
                  widget.host.title,
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 28, height: 1.2),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: AppTheme.highlight,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Row(
                        children: [
                          Text(
                            '${widget.host.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '·',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '124 reviews · ${widget.host.location}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 32),

                // Host Info Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.2,
                        ),
                        backgroundImage: NetworkImage(
                          'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.host.name}',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stay with ${widget.host.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Professional Host · Verified Identity',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.host.userId != null &&
                              widget.host.userId!.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  otherUserId: widget.host.userId!,
                                  otherUserName: widget.host.name,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Host contact information is unavailable.',
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.host.bio.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'About this stay',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.host.bio,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppTheme.textMain,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Animated Features
                _buildModernFeature(
                  Icons.verified_user_rounded,
                  'Verified Experience',
                  'Identity and pet-sitting credentials verified by our AI system.',
                  AppTheme.accent,
                ),
                const SizedBox(height: 32),
                _buildModernFeature(
                  Icons.pets_rounded,
                  'Pet First Aid',
                  'Equipped with medical kits and trained for minor pet emergencies.',
                  AppTheme.primary,
                ),
                const SizedBox(height: 32),
                _buildModernFeature(
                  Icons.home_work_rounded,
                  'Private & Secure',
                  'Fenced secure area ensures your pet stays safe during play.',
                  AppTheme.secondary,
                ),

                const SizedBox(height: 48),
                const Text(
                  'About the space',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.host.bio.isEmpty
                      ? 'I am a passionate pet lover with a large home and a beautiful backyard perfect for dogs to roam. Your pets will be treated as family here. I provide daily walks, play sessions, and plenty of cuddles!'
                      : widget.host.bio,
                  style: const TextStyle(
                    height: 1.7,
                    color: AppTheme.textMain,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 140),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppTheme.textMain,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(text: '₹${widget.host.price.toInt()}'),
                            const TextSpan(
                              text: ' / night',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => _selectDateRange(context),
                      child: Text(
                        _selectedDateRange == null
                            ? 'Choose dates'
                            : '${DateFormat('MMM d').format(_selectedDateRange!.start)} – ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: ElevatedButton(
                  onPressed: _selectedDateRange == null
                      ? () => _selectDateRange(context)
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingConfirmationScreen(
                                host: widget.host,
                                dateRange: _selectedDateRange!,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 64),
                    backgroundColor: _selectedDateRange == null
                        ? AppTheme.textMain
                        : AppTheme.primary,
                  ),
                  child: FittedBox(
                    child: Text(
                      _selectedDateRange == null ? 'Select Dates' : 'Book Now',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppTheme.textMain,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFeature(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 26, color: color),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
