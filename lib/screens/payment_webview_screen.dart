import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../utils/layout.dart';
import '../widgets/brand_logo.dart';
import 'order_details_screen.dart';

/// Hosts the Xendit hosted checkout.
///
/// Web and desktop open the secure page in the browser; Android and iOS use an
/// in-app WebView. Returning from this screen never marks an order paid — the
/// order screen keeps asking the database, which is only updated by a verified
/// Xendit webhook.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.reference,
    required this.onShop,
    this.guestToken,
    this.onFinished,
  });

  final String checkoutUrl;
  final String reference;
  final String? guestToken;
  final VoidCallback onShop;

  /// Used when payment is retried from an order; the caller reloads instead
  /// of being sent to a second order screen.
  final VoidCallback? onFinished;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _opening = false;
  bool _finishing = false;
  bool _browserMode = true;

  @override
  void initState() {
    super.initState();
    _browserMode = kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (!_browserMode) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.paper)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (value) {
              if (mounted) setState(() => _progress = value);
            },
            onNavigationRequest: _onNavigationRequest,
            onWebResourceError: (error) {
              if (error.isForMainFrame == true) {
                setState(() => _progress = 100);
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.checkoutUrl));
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final storefront = AppConfig.storefrontUrl.trim();
    if (storefront.isNotEmpty &&
        request.url.startsWith(storefront.replaceAll(RegExp(r'/+$'), ''))) {
      _finish();
      return NavigationDecision.prevent;
    }

    final uri = Uri.tryParse(request.url);
    final scheme = (uri?.scheme ?? '').toLowerCase();
    if (scheme.isNotEmpty && scheme != 'http' && scheme != 'https') {
      launchUrl(uri!, mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _openExternal() async {
    if (_opening) return;
    setState(() => _opening = true);
    final uri = Uri.tryParse(widget.checkoutUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the secure checkout. Try again.'),
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _opening = false);
  }

  void _finish() {
    if (_finishing) return;
    _finishing = true;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsScreen(
          reference: widget.reference,
          guestToken: widget.guestToken,
          onShop: widget.onShop,
          notice:
              'Xendit confirms payments automatically. It can take a moment to appear here.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const BrandLogo(size: 18),
        actions: <Widget>[
          TextButton(
            onPressed: _finish,
            child: const Text('I have paid'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _browserMode
            ? _BrowserCheckout(
                reference: widget.reference,
                opening: _opening,
                onOpen: _openExternal,
                onDone: _finish,
              )
            : Column(
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        if (_controller != null)
                          WebViewWidget(controller: _controller!),
                        if (_progress < 100)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(
                              value: _progress <= 0 ? null : _progress / 100,
                              minHeight: 2,
                              backgroundColor: AppColors.line,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Order ${widget.reference}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.muted,
                                    ),
                          ),
                        ),
                        FilledButton(
                          onPressed: _finish,
                          child: const Text('I have paid'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BrowserCheckout extends StatelessWidget {
  const _BrowserCheckout({
    required this.reference,
    required this.opening,
    required this.onOpen,
    required this.onDone,
  });

  final String reference;
  final bool opening;
  final VoidCallback onOpen;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: Layout.pagePadding(MediaQuery.sizeOf(context).width),
        vertical: 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                color: AppColors.tile,
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.ink,
                  size: 24,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Pay on Xendit',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'The secure checkout opens in a new tab. Come back here when '
                'you are finished — your order updates when Xendit confirms '
                'the payment.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.65,
                    ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'Order $reference',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: opening ? null : onOpen,
                child: Text(
                  opening ? 'Opening checkout…' : 'Open secure checkout',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onDone,
                child: const Text('I have paid'),
              ),
              const SizedBox(height: 18),
              Text(
                'Keep this page open until Xendit shows a confirmation. '
                'Returning here does not by itself mark the order as paid.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.6,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
