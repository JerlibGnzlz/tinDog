class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.userId,
    this.name,
    this.bio,
    this.avatarUrl,
    this.location,
    this.latitude,
    this.longitude,
    this.email,
    this.googleLinked = false,
  });

  final String id;
  final String userId;
  final String? name;
  final String? bio;
  final String? avatarUrl;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? email;
  final bool googleLinked;

  bool get hasGps =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      email: json['email'] as String?,
      googleLinked: json['googleLinked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
