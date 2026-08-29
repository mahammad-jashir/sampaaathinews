import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/routes.dart';
import 'themes/app_theme.dart';
import 'providers/providers.dart';
import 'widgets/responsive_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SampathiNewsApp(),
    ),
  );
}

class SampathiNewsApp extends ConsumerWidget {
  const SampathiNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read user setting theme provider
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ಸಂಪಾತಿ ನ್ಯೂಸ್ - Sampathi News',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // Wraps every page in ResponsiveBreakpoints so ResponsiveBreakpoints.of(context)
      // works anywhere in the app (e.g. HomePage's mobile/desktop layout check).
      builder: (context, child) => ResponsiveLayout(child: child ?? const SizedBox()),
    );
  }
}
