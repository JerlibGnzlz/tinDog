import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/tindog_form_sheet_scaffold.dart';
import '../discover_filters.dart';

Future<DiscoverFilters?> showDiscoverFiltersSheet({
  required BuildContext context,
  required DiscoverFilters current,
}) {
  return showModalBottomSheet<DiscoverFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _DiscoverFiltersSheet(initial: current),
  );
}

class _DiscoverFiltersSheet extends StatefulWidget {
  const _DiscoverFiltersSheet({required this.initial});

  final DiscoverFilters initial;

  @override
  State<_DiscoverFiltersSheet> createState() => _DiscoverFiltersSheetState();
}

class _DiscoverFiltersSheetState extends State<_DiscoverFiltersSheet> {
  late final TextEditingController _breedController;
  late RangeValues _age;
  late double _maxKm;

  @override
  void initState() {
    super.initState();
    _breedController =
        TextEditingController(text: widget.initial.breed?.trim() ?? '');
    _age = RangeValues(
      (widget.initial.minAge ?? 0).toDouble(),
      (widget.initial.maxAge ?? 20).toDouble(),
    );
    _maxKm = widget.initial.maxKm.toDouble().clamp(5, 100);
  }

  @override
  void dispose() {
    _breedController.dispose();
    super.dispose();
  }

  bool get _fullAgeRange =>
      _age.start.round() <= 0 && _age.end.round() >= 20;

  void _clear() {
    Navigator.pop(
      context,
      widget.initial.copyWith(
        clearBreed: true,
        clearMinAge: true,
        clearMaxAge: true,
        maxKm: 50,
      ),
    );
  }

  void _apply() {
    final breed = _breedController.text.trim();
    // 0–20 = sin filtro de edad (si no, Prisma excluía pets con age null).
    Navigator.pop(
      context,
      widget.initial.copyWith(
        breed: breed.isEmpty ? null : breed,
        clearBreed: breed.isEmpty,
        minAge: _fullAgeRange ? null : _age.start.round(),
        maxAge: _fullAgeRange ? null : _age.end.round(),
        clearMinAge: _fullAgeRange,
        clearMaxAge: _fullAgeRange,
        maxKm: _maxKm.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final breedNow = _breedController.text.trim();

    return TindogFormSheetScaffold(
      maxHeightFactor: 0.92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Text(
            'Filtros',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Raza',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _breedController,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: const InputDecoration(
              hintText: 'Ej: Labrador, Mestizo…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final breed in kSuggestedBreeds.take(10))
                ActionChip(
                  label: Text(breed),
                  backgroundColor: breedNow.toLowerCase() == breed.toLowerCase()
                      ? AppColors.primary.withValues(alpha: 0.22)
                      : AppColors.surface,
                  side: BorderSide(
                    color: breedNow.toLowerCase() == breed.toLowerCase()
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _breedController.text = breed;
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _fullAgeRange
                ? 'Edad: todas'
                : 'Edad: ${_age.start.round()} – ${_age.end.round()} años',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          RangeSlider(
            values: _age,
            min: 0,
            max: 20,
            divisions: 20,
            activeColor: AppColors.primaryDark,
            labels: RangeLabels(
              '${_age.start.round()}',
              '${_age.end.round()}',
            ),
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 8),
          Text(
            'Distancia (Cerca): ${_maxKm.round()} km',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Slider(
            value: _maxKm,
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: AppColors.primaryDark,
            label: '${_maxKm.round()} km',
            onChanged: (v) => setState(() => _maxKm = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _apply,
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
