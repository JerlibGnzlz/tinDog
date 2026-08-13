import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/feedback/app_haptics.dart';
import '../../../../core/network/session_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/argentina_provinces.dart';
import '../../data/device_location.dart';
import '../../data/georef_client.dart';
import '../../data/profile_repository.dart';
import '../profile_providers.dart';
import '../widgets/private_gps_map_preview.dart';
import '../widgets/profile_section_scaffold.dart';

class ProfileLocationScreen extends ConsumerStatefulWidget {
  const ProfileLocationScreen({super.key});

  @override
  ConsumerState<ProfileLocationScreen> createState() =>
      _ProfileLocationScreenState();
}

class _ProfileLocationScreenState extends ConsumerState<ProfileLocationScreen> {
  final _localityController = TextEditingController();
  final _focusNode = FocusNode();

  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  bool _saveSuccess = false;
  bool _gpsBusy = false;
  bool _hasGps = false;
  bool _searching = false;
  double? _gpsLat;
  double? _gpsLng;

  ArgentinaProvince? _province;
  ArgentinaLocality? _selected;
  List<ArgentinaLocality> _options = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _localityController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _localityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).getMyProfile();
      final saved = profile.location?.trim() ?? '';
      _hydrateFromSaved(saved);
      if (mounted) {
        setState(() {
          _loading = false;
          _hasGps = profile.hasGps;
          _gpsLat = profile.latitude;
          _gpsLng = profile.longitude;
        });
      }
      if (_province != null) {
        await _refreshOptions(query: _selected?.name ?? '');
      }
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = readableError(e);
        });
      }
    }
  }

  void _hydrateFromSaved(String saved) {
    if (saved.isEmpty) return;
    final parts = saved.split(',');
    final name = parts.first.trim();
    final region = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
    final province = provinceByShortOrName(region);
    if (province != null) {
      _province = province;
      _selected = ArgentinaLocality(name: name, province: province);
      _localityController.text = name;
      return;
    }
    // Texto viejo sin provincia clara.
    _localityController.text = saved;
  }

  void _onProvinceChanged(ArgentinaProvince? next) {
    setState(() {
      _province = next;
      _selected = null;
      _localityController.clear();
      _options = const [];
    });
    if (next != null) {
      unawaited(_refreshOptions());
    }
  }

  void _onLocalityTyped(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      unawaited(_refreshOptions(query: value));
    });
    if (_selected != null &&
        value.trim().toLowerCase() != _selected!.name.toLowerCase()) {
      setState(() => _selected = null);
    }
  }

  Future<void> _refreshOptions({String query = ''}) async {
    final province = _province;
    if (province == null) return;
    setState(() => _searching = true);
    try {
      final results = await ref.read(georefClientProvider).searchLocalities(
            province: province,
            query: query,
          );
      if (!mounted || _province?.id != province.id) return;
      setState(() {
        _options = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _options = const [];
        _searching = false;
      });
      showTindogErrorSnackBar(
        context,
        'No se pudieron cargar localidades. Revisá la conexión.',
      );
    }
  }

  void _selectLocality(ArgentinaLocality locality) {
    setState(() {
      _selected = locality;
      _province = locality.province;
      _localityController.text = locality.name;
      _localityController.selection = TextSelection.collapsed(
        offset: locality.name.length,
      );
    });
    _focusNode.unfocus();
  }

  Future<void> _useGps() async {
    setState(() => _gpsBusy = true);
    try {
      final coords = await DeviceLocation.getCurrent();
      ArgentinaLocality? resolved;
      String? resolveError;
      try {
        resolved = await ref.read(georefClientProvider).resolveFromGps(
              latitude: coords.latitude,
              longitude: coords.longitude,
            );
      } catch (e) {
        resolveError = 'No se pudo sugerir el barrio; el GPS sí se guardó.';
      }

      // Un solo setState: mapa + provincia/barrio alineados al GPS.
      if (!mounted) return;
      setState(() {
        _gpsLat = coords.latitude;
        _gpsLng = coords.longitude;
        _hasGps = true;
        if (resolved != null) {
          _province = resolved.province;
          _selected = resolved;
          _localityController.text = resolved.name;
          _localityController.selection = TextSelection.collapsed(
            offset: resolved.name.length,
          );
          _options = [resolved];
        }
      });
      _focusNode.unfocus();

      final locationText = resolved?.label ??
          (_selected?.label ?? _localityController.text.trim());

      await ref.read(profileRepositoryProvider).updateMyProfile(
            latitude: coords.latitude,
            longitude: coords.longitude,
            location: locationText.isEmpty ? null : locationText,
          );
      ref.invalidate(myProfileProvider);
      if (!mounted) return;

      setState(() => _gpsBusy = false);
      AppHaptics.success();
      if (resolved != null) {
        showTindogSuccessSnackBar(
          context,
          'GPS y barrio actualizados · ${resolved.label}',
        );
      } else {
        showTindogInfoSnackBar(
          context,
          resolveError ??
              'GPS guardado. Elegí el barrio a mano si hace falta.',
        );
      }

      // Refresca sugerencias de la provincia detectada.
      if (_province != null) {
        unawaited(_refreshOptions(query: resolved?.name ?? ''));
      }
    } on DeviceLocationException catch (e) {
      if (!mounted) return;
      setState(() => _gpsBusy = false);
      showTindogErrorSnackBar(context, e.message);
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        setState(() => _gpsBusy = false);
        showTindogErrorSnackBar(context, readableError(e));
      }
    }
  }

  Future<void> _save() async {
    final province = _province;
    final selected = _selected;
    final typed = _localityController.text.trim();

    String? location;
    if (selected != null) {
      location = selected.label;
    } else if (province != null && typed.isNotEmpty) {
      location = '$typed, ${province.shortName}';
    } else if (typed.isNotEmpty) {
      location = typed;
    }

    if ((location == null || location.isEmpty) && !_hasGps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elegí provincia y localidad, o usá GPS'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _saveSuccess = false;
    });
    try {
      await ref.read(profileRepositoryProvider).updateMyProfile(
            location: location,
          );
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveSuccess = true;
      });
      AppHaptics.success();
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      showTindogSuccessSnackBar(
        context,
        location != null
            ? 'Etiqueta guardada: $location (el mapa solo cambia con Actualizar GPS)'
            : 'Ubicación guardada',
      );
      context.pop();
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        showTindogErrorSnackBar(context, readableError(e));
        setState(() {
          _saving = false;
          _saveSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _gpsBusy;

    return ProfileSectionScaffold(
      title: 'Ubicación',
      loading: _loading,
      loadError: _loadError,
      onRetry: _loadData,
      saving: busy,
      saveSuccess: _saveSuccess,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Provincia y localidad de Argentina (datos oficiales). '
            'El GPS calcula distancia para Cerca y puede completar el lugar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ArgentinaProvince>(
            // ignore: deprecated_member_use
            value: _province,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Provincia',
              prefixIcon: Icon(Icons.map_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final p in kArgentinaProvinces)
                DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.shortName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy ? null : _onProvinceChanged,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _localityController,
            focusNode: _focusNode,
            enabled: !busy && _province != null,
            textCapitalization: TextCapitalization.words,
            onChanged: _onLocalityTyped,
            decoration: InputDecoration(
              labelText: _province?.isCaba == true ? 'Barrio' : 'Localidad',
              hintText: _province == null
                  ? 'Primero elegí provincia'
                  : (_province!.capital != null
                      ? 'Ej. ${_province!.capital}'
                      : 'Ej. Palermo'),
              prefixIcon: const Icon(Icons.place_outlined),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_localityController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          onPressed: () {
                            _localityController.clear();
                            setState(() {
                              _selected = null;
                              _options = const [];
                            });
                            unawaited(_refreshOptions());
                          },
                          icon: const Icon(Icons.clear_rounded),
                        )),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_province != null) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: _options.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _searching
                              ? 'Buscando…'
                              : 'Escribí para buscar en ${_province!.shortName}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _options.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _options[index];
                          final selected =
                              _selected?.name.toLowerCase() ==
                              item.name.toLowerCase();
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            leading: Icon(
                              item.isCapital
                                  ? Icons.star_rounded
                                  : Icons.location_on_outlined,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              item.isCapital
                                  ? 'Capital · ${item.province.shortName}'
                                  : item.province.shortName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () => _selectLocality(item),
                          );
                        },
                      ),
              ),
            ),
          ],
          if (_selected != null) ...[
            const SizedBox(height: 8),
            Text(
              'Etiqueta pública: «Vive en ${_selected!.name}» '
              '(no mueve el mapa; el mapa es tu GPS).',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            if (_gpsMismatchHint != null) ...[
              const SizedBox(height: 8),
              Text(
                _gpsMismatchHint!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: busy ? null : _useGps,
            icon: _gpsBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _hasGps ? 'Actualizar ubicación GPS' : 'Usar mi ubicación GPS',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (_hasGps) ...[
            const SizedBox(height: 10),
            Text(
              'GPS activo: el modo Cerca usará tu posición (sin dirección exacta).',
              style: TextStyle(
                color: AppColors.primaryDark.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_gpsLat != null && _gpsLng != null) ...[
              const SizedBox(height: 12),
              PrivateGpsMapPreview(
                key: ValueKey('gps-$_gpsLat-$_gpsLng'),
                latitude: _gpsLat!,
                longitude: _gpsLng!,
                publicBarrio: _selected?.name,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String? get _gpsMismatchHint {
    final lat = _gpsLat;
    final lng = _gpsLng;
    final place = _selected;
    if (lat == null || lng == null || place == null) return null;
    final pLat = place.latitude;
    final pLng = place.longitude;
    if (pLat == null || pLng == null) return null;
    final km = const Distance().as(
      LengthUnit.Kilometer,
      LatLng(lat, lng),
      LatLng(pLat, pLng),
    );
    if (km < 8) return null;
    return 'Tu GPS está a ~${km.round()} km de ${place.name}. '
        'El mapa sigue tu GPS; el barrio es solo la etiqueta pública.';
  }
}
