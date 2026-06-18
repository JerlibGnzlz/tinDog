class PetModel {
  const PetModel({
    required this.id,
    required this.userId,
    this.name,
    this.age,
    this.color,
    this.breed,
    this.favoriteToy,
    this.photoUrl,
  });

  final String id;
  final String userId;
  final String? name;
  final int? age;
  final String? color;
  final String? breed;
  final String? favoriteToy;
  final String? photoUrl;

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String?,
      age: (json['age'] as num?)?.toInt(),
      color: json['color'] as String?,
      breed: json['breed'] as String?,
      favoriteToy: json['favoriteToy'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
