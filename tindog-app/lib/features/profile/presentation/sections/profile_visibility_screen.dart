import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Transparencia: qué ven otros dueños de tu perfil.
class ProfileVisibilityScreen extends StatelessWidget {
  const ProfileVisibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Qué ven los demás',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'tinDog conecta dueños reales para playdates. '
            'Esto es lo que otras personas pueden ver de vos:',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          const _VisSection(
            title: 'Sí se ve',
            icon: Icons.visibility_outlined,
            items: [
              'Nombre y foto de tu mascota',
              'Raza, edad y clips/fotos que subas',
              'Tu nombre, foto de perfil y bio («Sobre vos»)',
              'Barrio / zona (sin dirección exacta)',
              'Distancia aproximada si activaste GPS',
              'Si entraste con Google: sello «Verificado con Google»',
              'Señal «Activo» si usaste la app hace poco',
            ],
          ),
          const SizedBox(height: 16),
          const _VisSection(
            title: 'No se ve',
            icon: Icons.visibility_off_outlined,
            items: [
              'Tu email',
              'Tu contraseña',
              'Dirección exacta ni GPS preciso',
              'Teléfono (aún no pedimos uno)',
              'Chats privados con otras personas',
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.push('/profile/personal'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar datos personales'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisSection extends StatelessWidget {
  const _VisSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryDark, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: AppColors.primaryDark)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
