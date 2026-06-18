import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/pet_photo_preview.dart';
import '../../../shared/widgets/tindog_filled_button.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../auth/presentation/auth_provider.dart';
import 'profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(myPetProvider);

    ref.listen(myPetProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) => handleSessionExpired(ref, context, error),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('tinDog'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar perfil',
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authSessionProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: petAsync.when(
        loading: () => const Center(child: TindogLoader(message: 'Cargando…')),
        error: (error, _) => _HomeBody(
          onEdit: () => context.go('/profile'),
          errorMessage: readableError(error),
        ),
        data: (pet) => _HomeBody(
          petName: pet.name,
          photoUrl: pet.photoUrl,
          onEdit: () => context.go('/profile'),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.onEdit,
    this.petName,
    this.photoUrl,
    this.errorMessage,
  });

  final VoidCallback onEdit;
  final String? petName;
  final String? photoUrl;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasPetProfile = petName != null && petName!.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                if (photoUrl != null && photoUrl!.isNotEmpty)
                  PetPhotoPreview(photoUrl: photoUrl, maxHeight: 340)
                else
                  const AppLogo(size: 96),
                const SizedBox(height: 20),
                Text(
                  hasPetProfile ? '¡Hola, ${petName!}!' : 'Bienvenido a tinDog',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (errorMessage != null) ...[
                  Text(
                    errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  hasPetProfile
                      ? 'Tu perfil está listo. Pronto podrás empezar a hacer match.'
                      : 'Completa el perfil de tu mascota para continuar.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: TindogFilledButton(
            onPressed: onEdit,
            child: Text(hasPetProfile ? 'Editar perfil' : 'Completar perfil'),
          ),
        ),
      ],
    );
  }
}
