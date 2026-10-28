import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../utils/layout.dart';
import '../widgets/brand_logo.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onOpenOrders,
    required this.onShop,
  });

  final VoidCallback onOpenOrders;
  final VoidCallback onShop;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final OrderService _orderService = OrderService();
  StreamSubscription<AuthState>? _authSubscription;
  bool _signingOut = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _authSubscription = _client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openAuth(AuthMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => AuthScreen(mode: mode),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your guest cart and guest orders stay on this device. '
          'Account orders stay with your account.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _signingOut = true);
    try {
      await _client.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out. Your cart is still here.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _orderService.signedInEmail;
    final signedIn = email != null && email.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = Layout.pagePadding(constraints.maxWidth);
        final contentWidth = constraints.maxWidth - padding * 2;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 26),
              if (signedIn)
                _SignedInCard(
                  email: email,
                  signingOut: _signingOut,
                  onSignOut: _signOut,
                )
              else
                _GuestCard(
                  onSignIn: () => _openAuth(AuthMode.signIn),
                  onCreateAccount: () => _openAuth(AuthMode.signUp),
                ),
              const SizedBox(height: 36),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: contentWidth >= 900 ? 760 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ActionRow(
                      title: 'Your orders',
                      body: signedIn
                          ? 'Account orders and guest orders from this device.'
                          : 'Guest orders placed on this device are saved here.',
                      action: 'View orders',
                      onTap: widget.onOpenOrders,
                    ),
                    _InfoBlock(
                      title: 'Payment',
                      body:
                          'GCash, card, and other options through Xendit. The '
                          'store never receives your card details. An order is '
                          'only marked paid after Xendit confirms it.',
                    ),
                    _InfoBlock(
                      title: 'Delivery',
                      body:
                          'The ELEVATE team arranges delivery after payment '
                          'using the address you enter at checkout. Add notes '
                          'if pickup or sizing needs to be discussed.',
                    ),
                    _InfoBlock(
                      title: 'Orders without an account',
                      body:
                          'Guest orders are tied to this device. Keep the order '
                          'reference if you switch phones or need help from the '
                          'team.',
                    ),
                    const SizedBox(height: 34),
                    const Divider(),
                    const SizedBox(height: 28),
                    const BrandLogo(size: 20),
                    const SizedBox(height: 10),
                    Text(
                      'Pins, shirts, and bookmarks for the ELEVATE community.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payments handled by Xendit.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: widget.onShop,
                      child: const Text('Continue shopping'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Shopping as a guest',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'No account is needed to order. Sign in to keep orders with '
              'your account on every device, or keep using guest checkout.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.6,
                  ),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton(
                onPressed: onSignIn,
                child: const Text('Sign in'),
              ),
              OutlinedButton(
                onPressed: onCreateAccount,
                child: const Text('Create account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.email,
    required this.signingOut,
    required this.onSignOut,
  });

  final String email;
  final bool signingOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Signed in',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This device still keeps its own guest cart. Account orders are '
            'available wherever you sign in.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: signingOut ? null : onSignOut,
            child: signingOut
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.line),
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.55,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          TextButton(
            onPressed: onTap,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.65,
                ),
          ),
        ],
      ),
    );
  }
}
