import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/friendly_error.dart';
import '../utils/ids.dart';
import '../utils/layout.dart';
import '../utils/validators.dart';
import '../widgets/brand_logo.dart';
import '../widgets/elevate_background.dart';
import '../widgets/labeled_field.dart';
import '../widgets/product_image.dart';
import 'order_details_screen.dart';
import 'payment_webview_screen.dart';

/// Checkout screen for ELEVATE MERCH.
/// Supports both standard cart checkout and direct "Buy Now" flow.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.onShop,
    this.directItem,
  });

  final CartService cart;
  final VoidCallback onShop;
  final CartItem? directItem;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();
  final ProductService _productService = ProductService();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  late final String _idempotencyKey;
  bool _autovalidate = false;
  bool _submitting = false;
  String? _errorMessage;

  List<CartItem> get _items {
    if (widget.directItem != null) {
      return <CartItem>[widget.directItem!];
    }
    return widget.cart.items;
  }

  double get _subtotal =>
      _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  @override
  void initState() {
    super.initState();
    _idempotencyKey = Ids.idempotencyKey();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _notesController = TextEditingController();

    _loadCustomerDetails();
  }

  Future<void> _loadCustomerDetails() async {
    final saved = await _orderService.loadSavedCustomer();
    if (!mounted) return;

    if (saved != null) {
      if (_nameController.text.isEmpty) _nameController.text = saved.name;
      if (_phoneController.text.isEmpty) _phoneController.text = saved.phone;
      if (_addressController.text.isEmpty) {
        _addressController.text = saved.address;
      }
      if (_emailController.text.isEmpty && (saved.email ?? '').isNotEmpty) {
        _emailController.text = saved.email!;
      }
    }

    final signedInEmail = _orderService.signedInEmail;
    if (_emailController.text.isEmpty &&
        signedInEmail != null &&
        signedInEmail.isNotEmpty) {
      _emailController.text = signedInEmail;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = true);
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final customer = CustomerDetails(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final isSignedIn = _orderService.isSignedIn;
    final guestToken = isSignedIn ? null : Ids.guestAccessCode();

    try {
      // Resolve latest product IDs from database to prevent stale local ID mismatches
      List<CartItem> orderItems = _items;
      try {
        final activeProducts = await _productService.fetchActiveProducts();
        orderItems = _items.map((item) {
          final match = activeProducts.cast<Product?>().firstWhere(
            (p) =>
                p != null &&
                p.name.toLowerCase().trim() == item.name.toLowerCase().trim(),
            orElse: () => activeProducts.cast<Product?>().firstWhere(
              (p) => p != null && p.id == item.productId,
              orElse: () => null,
            ),
          );
          if (match != null) {
            return item.copyWith(productId: match.id, price: match.price);
          }
          return item;
        }).toList();
      } catch (_) {
        // Fall back to original items if pre-resolution fails
      }

      // 1. Create order securely in Supabase backend (prices and stock revalidated)
      final created = await _orderService.createOrder(
        items: orderItems,
        customer: customer,
        idempotencyKey: _idempotencyKey,
        guestToken: guestToken,
      );

      // Save customer profile details locally for subsequent convenience
      await _orderService.saveCustomer(customer);

      // Save guest access token locally if ordering as a guest
      if (guestToken != null) {
        await _orderService.saveGuestAccess(
          GuestOrderAccess(
            reference: created.reference,
            token: guestToken,
            createdAt: DateTime.now(),
            total: created.total,
            summary: _items
                .map((item) => '${item.name} × ${item.quantity}')
                .join(', '),
          ),
        );
      }

      // Clear standard cart if full cart was checked out
      if (widget.directItem == null) {
        widget.cart.clear();
      }

      if (!mounted) return;

      // 2. Initiate payment session on trusted backend
      PaymentResult? payment;
      try {
        payment = await _paymentService.startPayment(
          reference: created.reference,
          guestToken: guestToken,
        );
      } catch (paymentErr) {
        // If the Edge function or secret is pending deployment, the order is still saved.
        // Direct the user to the order details screen with clear guidance.
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailsScreen(
              reference: created.reference,
              guestToken: guestToken,
              onShop: widget.onShop,
              notice: friendlyError(
                paymentErr,
                fallback:
                    'Order created! You can pay now or review order status.',
              ),
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      if (payment.hasCheckout) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PaymentWebViewScreen(
              checkoutUrl: payment!.checkoutUrl!,
              reference: created.reference,
              guestToken: guestToken,
              onShop: widget.onShop,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailsScreen(
              reference: created.reference,
              guestToken: guestToken,
              onShop: widget.onShop,
            ),
          ),
        );
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = friendlyError(
          err,
          fallback: 'Checkout could not be completed. Please try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = Layout.pagePadding(constraints.maxWidth);
            final contentWidth = constraints.maxWidth - padding * 2;
            final wide = contentWidth >= 880;

            final form = _CheckoutForm(
              formKey: _formKey,
              name: _nameController,
              phone: _phoneController,
              email: _emailController,
              address: _addressController,
              notes: _notesController,
              autovalidate: _autovalidate,
              signedInEmail: _orderService.signedInEmail ?? '',
            );

            final summary = _CheckoutSummary(
              items: _items,
              subtotal: _subtotal,
              submitting: _submitting,
              errorMessage: _errorMessage,
              onSubmit: _submit,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Checkout',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 28),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: form),
                        const SizedBox(width: 56),
                        SizedBox(width: 380, child: summary),
                      ],
                    )
                  else ...<Widget>[
                    summary,
                    const SizedBox(height: 36),
                    form,
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.paper,
                              ),
                            )
                          : Text('Pay ${formatPeso(_subtotal)} with Xendit'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.items,
    required this.subtotal,
    required this.submitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final List<CartItem> items;
  final double subtotal;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Order items',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: ProductImage(imageUrl: item.imageUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Qty: ${item.quantity} · ${formatPeso(item.price)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatPeso(item.lineTotal),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            children: <Widget>[
              Text(
                'Subtotal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              const Spacer(),
              Text(
                formatPeso(subtotal),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                'Delivery',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              const Spacer(),
              Text(
                'Arranged after payment',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: <Widget>[
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                formatPeso(subtotal),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                      height: 1.5,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.paper,
                    ),
                  )
                : Text('Pay ${formatPeso(subtotal)} with Xendit'),
          ),
          const SizedBox(height: 12),
          Text(
            'Secure payment via Xendit. GCash, credit/debit card, and Maya accepted.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({
    required this.formKey,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    required this.autovalidate,
    required this.signedInEmail,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController address;
  final TextEditingController notes;
  final bool autovalidate;
  final String signedInEmail;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: autovalidate
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (signedInEmail.isNotEmpty) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tile,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'Ordering as $signedInEmail. This order will be linked to your account.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Contact details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Full name',
            controller: name,
            hint: 'Juan Dela Cruz',
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.name],
            validator: Validators.name,
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Mobile number',
            controller: phone,
            hint: '0917 123 4567',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.telephoneNumber],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ -]')),
            ],
            validator: Validators.phone,
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Email (optional)',
            controller: email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.email],
            validator: Validators.email,
            helper: 'For the order receipt and Xendit payment confirmation.',
          ),
          const SizedBox(height: 30),
          Text(
            'Delivery address',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Delivery address',
            controller: address,
            hint: 'House/Unit number, Street, Barangay, City, Province',
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.newline,
            autofillHints: const <String>[AutofillHints.fullStreetAddress],
            validator: Validators.address,
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Notes (optional)',
            controller: notes,
            hint: 'Size preference, pickup instructions, or special requests',
            textInputAction: TextInputAction.newline,
            validator: Validators.notes,
            maxLines: 2,
            maxLength: 500,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Text(
              'Payment is handled securely by Xendit. ELEVATE MERCH does not store '
              'your payment credentials. Orders are verified and updated upon webhook confirmation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
