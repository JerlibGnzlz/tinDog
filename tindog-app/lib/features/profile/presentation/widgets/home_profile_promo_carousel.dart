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

/// Una promo clara a la vez (PageView), sin stack de cards tipo dashboard.
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

    final slide = widget.slides[_index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 96,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final item = widget.slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: AppColors.primaryDark,
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
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
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (widget.slides.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: active
                            ? AppColors.primaryDark
                            : AppColors.border,
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: slide.onCta,
                  child: Text(
                    slide.cta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
