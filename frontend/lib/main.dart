import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/scanner/screens/scanner_screen.dart';
import 'features/challenges/screens/challenges_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() {
  runApp(const ProviderScope(child: DropInApp()));
}

class DropInApp extends ConsumerStatefulWidget {
  const DropInApp({super.key});

  @override
  ConsumerState<DropInApp> createState() => _DropInAppState();
}

class _DropInAppState extends ConsumerState<DropInApp> {
  // Notifier transmis à go_router pour déclencher une réévaluation du redirect
  final _authListenable = ValueNotifier<bool>(false);
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
    // Vérifie le token JWT stocké après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  void dispose() {
    _authListenable.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Synchronise le ValueNotifier avec Riverpod pour rafraîchir go_router
    ref.listen(authProvider, (_, next) {
      _authListenable.value = next.isAuthenticated;
    });

    return MaterialApp.router(
      title: 'Drop\'In',
      theme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: _authListenable,

      // Redirige automatiquement selon l'état d'authentification
      redirect: (context, state) {
        final isAuth = _authListenable.value;
        final onAuthScreen = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isAuth && !onAuthScreen) return '/login';
        if (isAuth && onAuthScreen) return '/home';
        return null;
      },

      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

        // Shell partagé — ajoute la BottomNavigationBar sur les écrans protégés
        ShellRoute(
          builder: (context, state, child) => _AppShell(
            // On transmet le chemin depuis l'état go_router pour éviter
            // les ambiguïtés de contexte dans le ShellRoute
            location: state.uri.path,
            child: child,
          ),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const MapScreen()),
            GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
            GoRoute(path: '/challenges', builder: (_, __) => const ChallengesScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    );
  }
}

// ── Shell avec BottomNavigationBar ────────────

class _AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const _AppShell({required this.child, required this.location});

  static const _routes = ['/home', '/scanner', '/challenges', '/profile'];

  int _currentIndex() =>
      _routes.indexWhere((r) => location.startsWith(r)).clamp(0, 3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(),
        onTap: (i) => context.go(_routes[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Carte'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Défis'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
