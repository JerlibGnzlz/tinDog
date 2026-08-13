import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/tindog_nav.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/tindog_back_button.dart';
import '../../../../shared/widgets/tindog_filled_button.dart';
import '../../../../shared/widgets/tindog_loader.dart';
import '../../../../core/widgets/no_stretch_scroll_behavior.dart';

class ProfileSectionScaffold extends StatelessWidget {
  const ProfileSectionScaffold({
    super.key,
    required this.title,
    required this.child,
    this.loading = false,
    this.loadError,
    this.onRetry,
    this.saving = false,
    this.saveSuccess = false,
    this.saveEnabled = true,
    this.onSave,
    this.saveLabel = 'Guardar',
    this.showBack = true,
  });

  final String title;
  final Widget child;
  final bool loading;
  final String? loadError;
  final VoidCallback? onRetry;
  final bool saving;
  final bool saveSuccess;
  final bool saveEnabled;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        tindogPopOrHome(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text(title),
          leading: showBack
              ? TindogBackButton(onPressed: () => tindogPopOrHome(context))
              : null,
          automaticallyImplyLeading: showBack,
          leadingWidth: showBack ? 48 : null,
        ),
        body: loading
            ? const Center(child: TindogLoader(message: 'Cargando…'))
            : loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(loadError!),
                          const SizedBox(height: 16),
                          TindogFilledButton(
                            onPressed: onRetry,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: const NoStretchScrollBehavior(),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              16,
                              24,
                              16 + MediaQuery.viewInsetsOf(context).bottom,
                            ),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: child,
                          ),
                        ),
                      ),
                      if (onSave != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: TindogFilledButton(
                            onPressed: saveEnabled ? onSave : null,
                            loading: saving,
                            success: saveSuccess,
                            child: Text(saveLabel),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
