import 'package:flutter/material.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import 'explore_categories.dart';
import 'widgets/explore_category_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topInset + 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Explorar',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text(
              'Encontrá veterinarias, paseos, refugios y pet shops',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: exploreCategories.length,
              itemBuilder: (context, index) {
                final category = exploreCategories[index];
                return ExploreCategoryCard(
                  category: category,
                  onTap: () => showTindogInfoSnackBar(
                    context,
                    '${category.title}: próximamente en tinDog',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
