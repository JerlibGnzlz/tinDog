import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'tindog_network_image.dart';

class PetPhotoPicker extends StatelessWidget {
  const PetPhotoPicker({
    super.key,
    required this.photoUrl,
    this.localFile,
    this.localImageBytes,
    required this.onTap,
    this.isLoading = false,
  });

  final String? photoUrl;
  final File? localFile;
  final Uint8List? localImageBytes;
  final VoidCallback onTap;
  final bool isLoading;

  bool get _hasPreview =>
      localImageBytes != null ||
      localFile != null ||
      (photoUrl != null && photoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: SizedBox(
        width: double.infinity,
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (localImageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.memory(localImageBytes!, fit: BoxFit.cover),
              )
            else if (localFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(localFile!, fit: BoxFit.cover),
              )
            else
              TindogNetworkImage(
                imageUrl: photoUrl,
                borderRadius: 24,
                fit: BoxFit.cover,
              ),
            if (isLoading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(
                  _hasPreview ? Icons.edit : Icons.add_a_photo,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
