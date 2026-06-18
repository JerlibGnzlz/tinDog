import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_email_choice_screen.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/profile/presentation/profile_hub_screen.dart';
import '../../features/profile/presentation/profile_section_screens.dart';
import '../../features/profile/presentation/profile_screens.dart';

const _authRoutes = {
  '/welcome',
  '/auth/email',
  '/login',
  '/register',
};

/// Evita recrear [GoRouter] en cada cambio de sesión (causa doble navegación).
final _routerRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refreshListenable,
    redirect: (context, state) => _resolveRedirect(ref, state),
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/auth/email',
        builder: (_, _) => const AuthEmailChoiceScreen(),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const ProfileHubScreen(),
        routes: [
          GoRoute(
            path: 'personal',
            builder: (_, _) => const ProfilePersonalScreen(),
          ),
          GoRoute(
            path: 'pet',
            builder: (_, _) => const ProfilePetScreen(),
          ),
          GoRoute(
            path: 'photos',
            builder: (_, _) => const ProfilePhotosScreen(),
          ),
          GoRoute(
            path: 'videos',
            builder: (_, _) => const ProfileVideosScreen(),
          ),
          GoRoute(
            path: 'location',
            builder: (_, _) => const ProfileLocationScreen(),
          ),
        ],
      ),
    ],
  );
});

String? _resolveRedirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authSessionProvider);
  final isLoading = authState.isLoading;
  final isLoggedIn = authState.value ?? false;
  final location = state.matchedLocation;
  final isAuthRoute = _authRoutes.contains(location);

  if (isLoading) return null;

  if (!isLoggedIn && !isAuthRoute) return '/welcome';

  if (isLoggedIn && isAuthRoute) {
    // Registro → onboarding de perfil. Login/resto → home.
    if (location == '/register') return '/profile';
    return '/home';
  }

  return null;
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _ref.listen(authSessionProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
