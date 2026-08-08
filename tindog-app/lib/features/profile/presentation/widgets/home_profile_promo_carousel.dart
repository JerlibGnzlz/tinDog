import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HomePromoSlide {
  const HomePromoSlide({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onCta,
    this.icon = Icons.videocam_rounded,
  });

  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onCta;
  final IconData icon;
}

/// Card promo inferior (carousel) estilo hub Tinder, paleta TinDog.
class HomeProfilePromoCarousel extends StatefulWidget {
  const HomeProfilePromoCarousel({super.key, required this.slides});

  final List<HomePromoSlide> slides;

  @override
  State<HomeProfilePromoCarousel> createState() =>
      _HomeProfilePromoCarouselState();
}

class _HomeProfilePromoCarouselState extends State<HomeProfilePromoCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF0E8D6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            children: [
              SizedBox(
                height: 118,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final slide = widget.slides[i];
                    return Column(
                      children: [
                        Icon(
                          slide.icon,
                          color: AppColors.primaryDark,
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.slides.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 8 : 6,
                    height: active ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? AppColors.primaryDark
                          : AppColors.border,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: widget.slides[_index].onCta,
                  child: Text(
                    widget.slides[_index].cta.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
