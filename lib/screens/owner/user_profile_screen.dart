import 'package:flutter/material.dart';
import 'package:paw_stay/utils/theme.dart';
import 'package:paw_stay/screens/host/become_host_screen.dart';
import 'package:paw_stay/screens/host/host_dashboard_screen.dart';
import 'package:paw_stay/screens/owner/add_pet_screen.dart';
import 'package:paw_stay/screens/owner/personal_details_screen.dart';
import 'package:paw_stay/screens/owner/payment_methods_screen.dart';
import 'package:paw_stay/screens/owner/security_privacy_screen.dart';
import 'package:paw_stay/screens/owner/support_center_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? user = Supabase.instance.client.auth.currentUser;
  List<dynamic> _pets = [];
  bool _isLoadingPets = false;
  bool _isHost = false;
  bool _isLoadingHostStatus = true;

  @override
  void initState() {
    super.initState();
    _fetchPets();
    _checkHostStatus();
  }

  Future<void> _checkHostStatus() async {
    if (user == null) {
      if (mounted) setState(() => _isLoadingHostStatus = false);
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('hosts')
          .select('id')
          .eq('user_id', user!.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isHost = res != null;
          _isLoadingHostStatus = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHostStatus = false);
    }
  }

  Future<void> _fetchPets() async {
    if (user == null) return;
    setState(() => _isLoadingPets = true);
    try {
      final data = await Supabase.instance.client
          .from('pets')
          .select()
          .eq('owner_id', user!.id);
      setState(() => _pets = data as List<dynamic>);
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    } finally {
      setState(() => _isLoadingPets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 34),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 24,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF5F5F7)),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'user_avatar',
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(
                            user?.userMetadata?['avatar_url'] ??
                                'https://api.dicebear.com/7.x/avataaars/png?seed=${user?.id ?? "guest"}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.userMetadata?['full_name'] ?? 'User Guest',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              user?.email ?? 'guest@pawstay.com',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Hosting CTA
              _isLoadingHostStatus
                  ? const Center(child: CircularProgressIndicator())
                  : InkWell(
                      onTap: () async {
                        if (_isHost) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HostDashboardScreen(),
                            ),
                          );
                        } else {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BecomeHostScreen(),
                            ),
                          );
                          if (result == true) {
                            _checkHostStatus(); // Reload if successfully applied
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.accent, Color(0xFF5D3FD3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isHost
                                        ? 'Switch to Host View'
                                        : 'Host your home',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isHost
                                        ? 'Manage your stays and earnings'
                                        : 'Earn by hosting furry friends',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppTheme.accent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

              const SizedBox(height: 40),

              // My Pets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Family',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddPetScreen()),
                      );
                      if (result == true) _fetchPets();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add Pet',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoadingPets)
                const Center(child: CircularProgressIndicator())
              else if (_pets.isEmpty)
                _buildEmptyState()
              else
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pets.length,
                    itemBuilder: (context, index) {
                      final pet = _pets[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF5F5F7),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: AppTheme.background,
                                backgroundImage: NetworkImage(
                                  pet['image_url'] ??
                                      'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&q=80&w=1000',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pet['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 48),
              const Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 24),
              _buildSettingItem(
                Icons.person_outline_rounded,
                'Personal Details',
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PersonalDetailsScreen(),
                    ),
                  );
                  setState(() {
                    user = Supabase.instance.client.auth.currentUser;
                  });
                },
              ),
              _buildSettingItem(
                Icons.payment_rounded,
                'Payment Methods',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodsScreen(),
                  ),
                ),
              ),
              _buildSettingItem(
                Icons.security_rounded,
                'Security & Privacy',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SecurityPrivacyScreen(),
                  ),
                ),
              ),
              _buildSettingItem(
                Icons.help_outline_rounded,
                'Support Center',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupportCenterScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (!context.mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No family added yet',
            style: TextStyle(
              color: AppTheme.textMain,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your pets to book a stay',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF5F5F7), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.textMain, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
