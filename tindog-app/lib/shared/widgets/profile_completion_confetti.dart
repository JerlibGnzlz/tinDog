import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'paw_particle_path.dart';

class ProfileCompletionConfetti extends StatefulWidget {
  const ProfileCompletionConfetti({
    super.key,
    required this.play,
    required this.child,
  });

  final bool play;
  final Widget child;

  @override
  State<ProfileCompletionConfetti> createState() =>
      _ProfileCompletionConfettiState();
}

class _ProfileCompletionConfettiState extends State<ProfileCompletionConfetti> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
    _maybePlay();
  }

  @override
  void didUpdateWidget(ProfileCompletionConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay();
  }

  void _maybePlay() {
    if (widget.play) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.play();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 18,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.15,
            minimumSize: const Size(18, 18),
            maximumSize: const Size(28, 28),
            createParticlePath: createPawParticlePath,
            colors: const [
              AppColors.primary,
              AppColors.primaryDark,
              AppColors.accent,
              AppColors.textPrimary,
            ],
          ),
        ),
      ],
    );
  }
}
