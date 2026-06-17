import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('tinDog'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authSessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenido a tinDog'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Editar perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

final myProfileProvider = FutureProvider<ProfileModel>((ref) {
  return ref.watch(profileRepositoryProvider).getMyProfile();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _fillFields(ProfileModel profile) {
    if (_initialized) return;
    _nameController.text = profile.name ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateMyProfile(
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            location: _locationController.text.trim(),
          );
      ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (profile) {
          _fillFields(profile);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
