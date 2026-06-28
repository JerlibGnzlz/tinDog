class PetMediaModel {
  const PetMediaModel({
    required this.id,
    required this.petId,
    required this.type,
    required this.url,
    required this.publicId,
    required this.sortOrder,
    required this.isPrimary,
    this.durationSec,
  });

  final String id;
  final String petId;
  final String type;
  final String url;
  final String publicId;
  final int sortOrder;
  final bool isPrimary;
  final int? durationSec;

  bool get isVideo => type == 'video';

  factory PetMediaModel.fromJson(Map<String, dynamic> json) {
    return PetMediaModel(
      id: json['id'] as String,
      petId: json['petId'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      publicId: json['publicId'] as String,
      sortOrder: json['sortOrder'] as int,
      isPrimary: json['isPrimary'] as bool,
      durationSec: json['durationSec'] as int?,
    );
  }
}

const maxPetPhotos = 6;
const maxPetVideos = 2;
const maxVideoDurationSec = 30;
