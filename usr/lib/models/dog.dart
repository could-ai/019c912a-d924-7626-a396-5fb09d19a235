class Dog {
  final String id;
  final String name;
  final String breed;
  final int age;
  final String imageUrl;
  final String bio;
  final double distance; // in miles
  final String ownerName;

  const Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.imageUrl,
    required this.bio,
    required this.distance,
    required this.ownerName,
  });
}
