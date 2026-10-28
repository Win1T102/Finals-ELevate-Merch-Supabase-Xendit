import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../utils/layout.dart';
import '../utils/validators.dart';
import '../widgets/brand_logo.dart';
import '../widgets/elevate_background.dart';
import '../widgets/labeled_field.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.mode = AuthMode.signIn});

  final AuthMode mode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late AuthMode _mode = widget.mode;
  bool _busy = false;
  String? _error;
  String? _info;

  SupabaseClient get _auth => Supabase.instance.client;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _info = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    final email = _email.text.trim();
    final password = _password.text;

    try {
      if (_mode == AuthMode.signUp) {
        final response = await _auth.auth.signUp(
          email: email,
          password: password,
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            _info = 'Check your email to confirm the account, then sign in.';
            _mode = AuthMode.signIn;
          });
        } else {
          Navigator.of(context).pop(true);
        }
      } else {
        await _auth.auth.signInWithPassword(email: email, password: password);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyError(error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first, then request a reset.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() {
        _info = 'If that email has an account, a reset link is on its way.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switchMode() {
    setState(() {
      _mode = _mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
      _error = null;
      _info = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final signingIn = _mode == AuthMode.signIn;

    return ElevateBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          titleSpacing: 0,
          title: const BrandLogo(size: 18),
        ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Layout.pagePadding(MediaQuery.sizeOf(context).width),
            vertical: 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      signingIn ? 'Sign in' : 'Create an account',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      signingIn
                          ? 'Keep your orders with your account on every '
                              'device. Guest checkout is always available.'
                          : 'An account keeps your orders together. It is not '
                              'needed to buy anything.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 30),
                    LabeledField(
                      label: 'Email',
                      controller: _email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      validator: Validators.requiredEmail,
                    ),
                    const SizedBox(height: 18),
                    LabeledField(
                      label: 'Password',
                      controller: _password,
                      hint: signingIn ? 'Your password' : 'At least 8 characters',
                      textInputAction: TextInputAction.done,
                      autofillHints: signingIn
                          ? const <String>[AutofillHints.password]
                          : const <String>[AutofillHints.newPassword],
                      validator: Validators.password,
                      obscureText: true,
                    ),
                    if (signingIn)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSurface,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          _error!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.danger,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                    if (_info != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          _info!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.success,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.paper,
                              ),
                            )
                          : Text(signingIn ? 'Sign in' : 'Create account'),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : _switchMode,
                        child: Text(
                          signingIn
                              ? 'New here? Create an account'
                              : 'Already have an account? Sign in',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your guest cart stays on this device either way. '
                      'Signing out does not remove it.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            height: 1.55,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
