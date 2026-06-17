class PetModel {
  const PetModel({
    required this.id,
    required this.userId,
    this.name,
    this.photoUrl,
  });

  final String id;
  final String userId;
  final String? name;
  final String? photoUrl;

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
