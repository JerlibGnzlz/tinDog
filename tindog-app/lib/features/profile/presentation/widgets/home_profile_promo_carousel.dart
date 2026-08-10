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
  void didUpdateWidget(covariant HomeProfilePromoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slides.isEmpty) return;
    if (_index >= widget.slides.length) {
      _index = widget.slides.length - 1;
      if (_controller.hasClients) {
        _controller.jumpToPage(_index);
      }
    }
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
