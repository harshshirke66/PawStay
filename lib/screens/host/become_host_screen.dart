import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:paw_stay/utils/theme.dart';
import 'package:paw_stay/services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

class BecomeHostScreen extends StatefulWidget {
  const BecomeHostScreen({super.key});

  @override
  State<BecomeHostScreen> createState() => _BecomeHostScreenState();
}

class _BecomeHostScreenState extends State<BecomeHostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  String _selectedCategory = 'Quiet Homes';
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Quiet Homes', 'icon': Icons.home_rounded},
    {'label': 'Big Backyards', 'icon': Icons.grass_rounded},
    {'label': 'Apartments', 'icon': Icons.apartment_rounded},
    {'label': 'Pet Lovers', 'icon': Icons.favorite_rounded},
    {'label': 'Luxury', 'icon': Icons.star_rounded},
  ];

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (selected != null) {
      setState(() => _imageFile = selected);
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    try {
      final bytes = await _imageFile!.readAsBytes();
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = 'host_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'hosts/$fileName';

      await Supabase.instance.client.storage
          .from('hosts') // Make sure this bucket exists and is public
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return Supabase.instance.client.storage
          .from('hosts')
          .getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }

  Future<void> _submitHosting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo of your space')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Upload Image
      final imageUrl = await _uploadImage();

      // 2. Trigger AI Review
      final review = await AIService().reviewHostApplication(
        title: _titleController.text,
        location: _locationController.text,
        price: double.parse(_priceController.text),
        bio: _bioController.text,
        category: _selectedCategory,
      );

      if (!mounted) return;

      if (review['accepted'] == true) {
        // 3. Save to Supabase if accepted
        await Supabase.instance.client.from('hosts').insert({
          'user_id': user.id,
          'name': user.userMetadata?['full_name'] ?? 'User',
          'title': _titleController.text,
          'location': _locationController.text,
          'price': double.parse(_priceController.text),
          'bio': _bioController.text,
          'category': _selectedCategory,
          'rating': review['rating'] ?? 5.0,
          'is_verified': true,
          'image_url':
              imageUrl ??
              'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
        });

        _showResultDialog(
          success: true,
          message: 'AI Review Passed!',
          details:
              review['reason'] ??
              'Welcome to PawStay! Your application was accepted by our automatic verification system.',
        );
      } else {
        _showResultDialog(
          success: false,
          message: 'Application Declined',
          details:
              review['reason'] ??
              'Our AI reviewer suggests improving your bio or details for safety and quality standards.',
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

  void _showResultDialog({
    required bool success,
    required String message,
    required String details,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (success ? AppTheme.accent : Colors.redAccent)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: success ? AppTheme.accent : Colors.redAccent,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: Colors.transparent,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: Text(
                    details,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (success) Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: success
                          ? AppTheme.primary
                          : const Color(0xFFF1F5F9),
                      foregroundColor: success
                          ? Colors.white
                          : AppTheme.textSecondary,
                      elevation: 0,
                    ),
                    child: Text(
                      success ? 'Get Started' : 'Try Again',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Become a Host',
          style: TextStyle(
            color: AppTheme.textMain,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: AppTheme.textMain,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI-Powered Hosting\nApplication',
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 34),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your profile will be instantly reviewed by Gemini AI for safety and professional standards.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Photo Upload Section
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.grey.shade100,
                            width: 2,
                          ),
                        ),
                        child: _imageFile == null
                            ? SizedBox(
                                height: 180,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_rounded,
                                      size: 44,
                                      color: AppTheme.primary.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Upload Space Photo',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Image(
                                    image: kIsWeb
                                        ? NetworkImage(_imageFile!.path)
                                        : FileImage(File(_imageFile!.path))
                                              as ImageProvider,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildField(
                    'Your Hosting Title',
                    _titleController,
                    'e.g. Spacious dog garden in Beverly Hills',
                    Icons.title_rounded,
                  ),
                  const SizedBox(height: 28),
                  _buildField(
                    'Location',
                    _locationController,
                    'e.g. Beverly Hills, CA',
                    Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 28),
                  _buildField(
                    'Price per night (₹)',
                    _priceController,
                    'e.g. 1500',
                    Icons.payments_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 28),

                  // Category Selection
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 16),
                    child: Text(
                      'Place Category',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['label'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat['label']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(12),
                            width: 100,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.background,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.grey.shade100,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cat['icon'],
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Flexible(
                                  child: Text(
                                    cat['label'].split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildField(
                    'About your space & experience',
                    _bioController,
                    'Describe your environment and experience with pets...',
                    Icons.info_rounded,
                    maxLines: 5,
                  ),

                  const SizedBox(height: 56),
                  Hero(
                    tag: 'host_submit_button',
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitHosting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          elevation: 8,
                          shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Submit for AI Review',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.4),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 6,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Gemini is reviewing...',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: AppTheme.textMain,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Text(
                            'AI Assessment in progress',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppTheme.textMain,
              letterSpacing: -0.2,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: AppTheme.primary.withValues(alpha: 0.6),
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }
}
