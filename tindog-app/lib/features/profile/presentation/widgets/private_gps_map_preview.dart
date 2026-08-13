import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';

/// Mapa privado: solo el dueño ve su pin GPS (no se muestra a otros).
///
/// El pin sigue al GPS real; se recentra al actualizar coordenadas.
class PrivateGpsMapPreview extends StatefulWidget {
  const PrivateGpsMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.publicBarrio,
  });

  final double latitude;
  final double longitude;
  final String? publicBarrio;

  @override
  State<PrivateGpsMapPreview> createState() => _PrivateGpsMapPreviewState();
}

class _PrivateGpsMapPreviewState extends State<PrivateGpsMapPreview> {
  final _mapController = MapController();

  @override
  void didUpdateWidget(covariant PrivateGpsMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(
          LatLng(widget.latitude, widget.longitude),
          _mapController.camera.zoom,
        );
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(widget.latitude, widget.longitude);
    final barrio = widget.publicBarrio?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tu posición GPS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tindog.tindog_app',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primaryDark,
                        size: 44,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                barrio != null && barrio.isNotEmpty
                    ? 'Este mapa es tu GPS real (solo vos). '
                        'Los demás verán «Vive en $barrio», no el pin exacto.'
                    : 'Solo vos ves este mapa. Los demás solo ven el barrio '
                        'y una distancia aproximada.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
