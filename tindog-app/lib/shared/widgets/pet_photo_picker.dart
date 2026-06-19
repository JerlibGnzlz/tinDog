import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'tindog_gradient_progress_bar.dart';
import 'pet_photo_preview.dart';

class PetPhotoPicker extends StatelessWidget {
  const PetPhotoPicker({
    super.key,
    required this.photoUrl,
    this.localFile,
    this.localImageBytes,
    required this.onTap,
    this.isLoading = false,
    this.uploadProgress,
    this.uploadStatus,
  });

  final String? photoUrl;
  final File? localFile;
  final Uint8List? localImageBytes;
  final VoidCallback onTap;
  final bool isLoading;
  final double? uploadProgress;
  final String? uploadStatus;

  bool get _hasPreview =>
      localImageBytes != null ||
      localFile != null ||
      (photoUrl != null && photoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PetPhotoPreview(
            photoUrl: photoUrl,
            localImageBytes: localImageBytes,
            localFile: localFile,
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (uploadStatus != null) ...[
                          Text(
                            uploadStatus!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (uploadProgress != null)
                          TindogGradientProgressBar(
                            value: uploadProgress!,
                            height: 6,
                          )
                        else
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!isLoading)
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
    );
  }
}
