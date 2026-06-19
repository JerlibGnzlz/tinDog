import 'package:flutter/material.dart';
import '../widgets/profile_section_scaffold.dart';

class ProfileVideosScreen extends StatelessWidget {
  const ProfileVideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSectionScaffold(
      title: 'Videos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.videocam_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Próximamente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Podrás subir clips de tu mascota en una próxima actualización.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
