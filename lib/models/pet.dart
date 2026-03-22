class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final String weight;
  final String age;
  final String imageUrl;
  final String notes;

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.weight,
    required this.age,
    required this.imageUrl,
    this.notes = '',
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      ownerId: map['owner_id'],
      name: map['name'],
      breed: map['breed'],
      weight: map['weight'],
      age: map['age'],
      imageUrl:
          map['image_url'] ??
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&q=80&w=1000',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'name': name,
      'breed': breed,
      'weight': weight,
      'age': age,
      'image_url': imageUrl,
      'notes': notes,
    };
  }
}
