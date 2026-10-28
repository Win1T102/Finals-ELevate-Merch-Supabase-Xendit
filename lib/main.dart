import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/root_shell.dart';
import 'services/cart_service.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'widgets/brand_logo.dart';

bool _supabaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _StartingApp());
  await _bootstrap();
}

Future<void> _bootstrap() async {
  try {
    if (!_supabaseReady) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
      _supabaseReady = true;
    }
    final cart = CartService();
    await cart.load();
    runApp(ElevateMerchApp(cart: cart));
  } catch (error) {
    runApp(
      _StartupErrorApp(
        message: friendlyError(
          error,
          fallback: 'The store could not start. Check your connection and try again.',
        ),
        onRetry: () {
          runApp(const _StartingApp());
          _bootstrap();
        },
      ),
    );
  }
}

class ElevateMerchApp extends StatelessWidget {
  const ElevateMerchApp({super.key, required this.cart});

  final CartService cart;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: RootShell(cart: cart),
    );
  }
}

class _StartingApp extends StatelessWidget {
  const _StartingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BrandLogo(size: 24),
                    const SizedBox(height: 34),
                    Text(
                      'The store could not start.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    const SizedBox(height: 26),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
