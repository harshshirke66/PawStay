class Host {
  final String id;
  final String name;
  final String title;
  final String location;
  final String distance;
  final double rating;
  final double price;
  final String imageUrl;
  final String dateRange;
  final String? userId;
  final bool isVerified;
  final String bio;
  final String category;

  Host({
    required this.id,
    required this.name,
    required this.title,
    required this.location,
    required this.distance,
    required this.rating,
    required this.price,
    required this.imageUrl,
    required this.dateRange,
    required this.isVerified,
    required this.bio,
    required this.category,
    this.userId,
  });

  factory Host.fromMap(Map<String, dynamic> map) {
    return Host(
      id: map['id'] ?? '',
      userId: map['user_id'],
      name: map['name'] ?? 'Unknown Host',
      title: map['title'] ?? 'Pet Home',
      location: map['location'] ?? 'Location not specified',
      distance: '0.5 miles away',
      rating: (map['rating'] ?? 5.0).toDouble(),
      price: (map['price'] ?? 0.0).toDouble(),
      isVerified: map['is_verified'] ?? false,
      bio: map['bio'] ?? '',
      category: map['category'] ?? 'Quiet Homes',
      imageUrl:
          map['image_url'] ??
          'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?auto=format&fit=crop&q=80&w=1000',
      dateRange: 'Available now',
    );
  }
}
