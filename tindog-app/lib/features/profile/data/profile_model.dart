class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.userId,
    this.name,
    this.bio,
    this.avatarUrl,
    this.location,
  });

  final String id;
  final String userId;
  final String? name;
  final String? bio;
  final String? avatarUrl;
  final String? location;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (location != null) 'location': location,
    };
  }
}
