import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../utils/friendly_error.dart';
import '../utils/layout.dart';
import '../widgets/brand_logo.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../widgets/product_modal.dart';
import '../widgets/skeleton_grid.dart';

/// The shop dashboard: an editorial opening, then the catalogue.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.cart,
    required this.onOpenCart,
  });

  final CartService cart;
  final VoidCallback onOpenCart;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _collectionKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = const <Product>[];
  Object? _error;
  bool _loading = true;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final products = await _productService.fetchActiveProducts();
      products.sort((a, b) {
        final byCategory = ProductCategories.compare(a.category, b.category);
        if (byCategory != 0) return byCategory;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
        if (_selectedCategory != null &&
            !products.any((product) =>
                ProductCategories.label(product.category) == _selectedCategory)) {
          _selectedCategory = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _scrollToCollection() {
    final target = _collectionKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _openProduct(Product product) {
    showProductModal(
      context: context,
      product: product,
      cart: widget.cart,
      onOpenCart: widget.onOpenCart,
    );
  }

  void _addToCart(Product product) {
    final added = widget.cart.add(product);
    final existing = widget.cart.itemFor(product.id);
    final message = added
        ? '${product.name} added to your cart.'
        : existing != null
            ? 'That is the most of this piece you can order at once.'
            : 'This piece is not available right now.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: added
              ? SnackBarAction(
                  label: 'View cart',
                  onPressed: widget.onOpenCart,
                )
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = Layout.pagePadding(constraints.maxWidth);
        final contentWidth = constraints.maxWidth - padding * 2;
        final wideHero = contentWidth >= 860;
        final columns = contentWidth >= 1050
            ? 4
            : contentWidth >= 740
                ? 3
                : contentWidth >= 430
                    ? 2
                    : 1;
        final gap = columns == 4 ? 24.0 : 20.0;
        final tileWidth = (contentWidth - gap * (columns - 1)) / columns;

        final featured = _featuredProduct();

        return RefreshIndicator(
          onRefresh: _load,
          color: AppColors.elevateRed,
          backgroundColor: AppColors.tile,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, wideHero ? 30 : 12, padding, 0),
                sliver: SliverToBoxAdapter(
                  child: _Hero(
                    featured: featured,
                    wide: wideHero,
                    onShop: _scrollToCollection,
                    onFeaturedTap:
                        featured == null ? null : () => _openProduct(featured),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  wideHero ? 76 : 52,
                  padding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CollectionHeader(
                    key: _collectionKey,
                    count: _products.length,
                    selectedCategory: _selectedCategory,
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    onSearchChanged: (query) =>
                        setState(() => _searchQuery = query),
                    onClearSearch: _clearSearch,
                    categories: ProductCategories.filters(
                      _products.map((product) => product.category),
                    ),
                    onSelect: (category) =>
                        setState(() => _selectedCategory = category),
                    onRefresh: _loading ? null : _load,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, 28, padding, 0),
                sliver: SliverToBoxAdapter(
                  child: _CatalogueBody(
                    loading: _loading,
                    error: _error,
                    products: _filteredProducts,
                    columns: columns,
                    tileWidth: tileWidth,
                    gap: gap,
                    searchQuery: _searchQuery,
                    onClearSearch: _clearSearch,
                    onRetry: _load,
                    onOpen: _openProduct,
                    onAdd: _addToCart,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  _products.isEmpty ? 24 : 84,
                  padding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _OrderingNotes(wide: contentWidth >= 760),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, 56, padding, 0),
                sliver: SliverToBoxAdapter(child: _Footer()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
            ],
          ),
        );
      },
    );
  }

  Product? _featuredProduct() {
    if (_products.isEmpty) return null;
    for (final product in _products) {
      if (product.imageUrl.isNotEmpty && product.isAvailable) return product;
    }
    return _products.first;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  List<Product> get _filteredProducts {
    var list = _products;
    if (_selectedCategory != null) {
      list = list
          .where((product) =>
              ProductCategories.label(product.category) == _selectedCategory)
          .toList(growable: false);
    }
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list.where((product) {
        final nameMatches = product.name.toLowerCase().contains(query);
        final descMatches =
            product.description?.toLowerCase().contains(query) ?? false;
        final catMatches =
            product.category?.toLowerCase().contains(query) ?? false;
        return nameMatches || descMatches || catMatches;
      }).toList(growable: false);
    }
    return list;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.featured,
    required this.wide,
    required this.onShop,
    this.onFeaturedTap,
  });

  final Product? featured;
  final bool wide;
  final VoidCallback onShop;
  final VoidCallback? onFeaturedTap;

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'A small collection, made to be worn.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
        ),
        SizedBox(height: wide ? 20 : 14),
        Text(
          'Carry the\nmessage.',
          style: (wide
                  ? Theme.of(context).textTheme.displayLarge
                  : Theme.of(context).textTheme.displayMedium)
              ?.copyWith(fontSize: wide ? 68 : 46),
        ),
        SizedBox(height: wide ? 24 : 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Text(
            'Pins, shirts, and bookmarks for the ELEVATE community. '
            'Simple pieces for everyday wear, and for the days you need '
            'the reminder most.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                  height: 1.6,
                ),
          ),
        ),
        SizedBox(height: wide ? 32 : 24),
        FilledButton(
          onPressed: onShop,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.elevateRed,
            foregroundColor: AppColors.paper,
          ),
          child: const Text('Shop the collection'),
        ),
        const SizedBox(height: 12),
        Text(
          'Guest checkout. No account needed.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ],
    );

    final art = _FeaturedArt(product: featured, onTap: onFeaturedTap, wide: wide);

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          copy,
          const SizedBox(height: 36),
          art,
        ],
      );
    }

    return SizedBox(
      height: 474,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(flex: 11, child: Padding(
            padding: const EdgeInsets.only(right: 48),
            child: copy,
          )),
          Expanded(flex: 9, child: art),
        ],
      ),
    );
  }
}

class _FeaturedArt extends StatelessWidget {
  const _FeaturedArt({
    required this.product,
    required this.wide,
    this.onTap,
  });

  final Product? product;
  final bool wide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = product;

    if (item == null) {
      final panel = InkWell(
        onTap: onTap,
        child: Container(
          color: AppColors.ink,
          padding: const EdgeInsets.all(28),
          child: const Align(
            alignment: Alignment.bottomLeft,
            child: BrandMark(
              size: 46,
              color: AppColors.paper,
              showTagline: true,
            ),
          ),
        ),
      );
      return wide ? panel : SizedBox(height: 320, child: panel);
    }

    Widget image = InkWell(
      onTap: onTap,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.elevateRed.withValues(alpha: 0.22),
                blurRadius: 40,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ProductImage(
            imageUrl: item.imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
    image = wide
        ? Expanded(child: image)
        : AspectRatio(aspectRatio: 1.08, child: image);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        image,
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ProductCategories.displayLabel(item.category) ??
                        'ELEVATE',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              item.hasPrice ? formatPeso(item.price) : 'Price pending',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    super.key,
    required this.count,
    required this.categories,
    required this.selectedCategory,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSelect,
    required this.onRefresh,
  });

  final int count;
  final List<String> categories;
  final String? selectedCategory;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onSelect;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Text(
                'The collection',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (count > 0)
              Text(
                '$count ${count == 1 ? 'piece' : 'pieces'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Refresh collection',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search merchandise (pins, shirts, bookmarks...)',
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.muted),
                    onPressed: onClearSearch,
                    tooltip: 'Clear search',
                  )
                : null,
            filled: true,
            fillColor: AppColors.tile,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (categories.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Wrap(
            spacing: 22,
            runSpacing: 8,
            children: <Widget>[
              _FilterTab(
                label: ProductCategories.all,
                selected: selectedCategory == null,
                onTap: () => onSelect(null),
              ),
              ...categories.skip(1).map(
                    (category) => _FilterTab(
                      label: category,
                      selected: selectedCategory == category,
                      onTap: () => onSelect(category),
                    ),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.ink : AppColors.muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 2,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(
                color: AppColors.elevateRed,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogueBody extends StatelessWidget {
  const _CatalogueBody({
    required this.loading,
    required this.error,
    required this.products,
    required this.columns,
    required this.tileWidth,
    required this.gap,
    required this.searchQuery,
    required this.onClearSearch,
    required this.onRetry,
    required this.onOpen,
    required this.onAdd,
  });

  final bool loading;
  final Object? error;
  final List<Product> products;
  final int columns;
  final double tileWidth;
  final double gap;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final VoidCallback onRetry;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    if (loading && products.isEmpty) {
      return SkeletonProductGrid(count: columns * 2, columns: columns);
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'The collection could not load.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              friendlyError(
                error!,
                fallback: 'Check your connection and try again.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      if (searchQuery.trim().isNotEmpty) {
        return EmptyState(
          title: 'No matching pieces',
          message:
              'No items matched "$searchQuery". Try checking for typos or clear your search to browse all pieces.',
          actionLabel: 'Clear search',
          onAction: onClearSearch,
          icon: Icons.search_off_outlined,
          compact: true,
        );
      }
      return EmptyState(
        title: 'The collection is being prepared',
        message:
            'New pieces are on the way. Refresh to look again, or check back soon.',
        actionLabel: 'Refresh',
        onAction: onRetry,
        icon: Icons.inventory_2_outlined,
        compact: true,
      );
    }

    return Wrap(
      spacing: gap,
      runSpacing: 36,
      children: products
          .map(
            (product) => SizedBox(
              width: tileWidth,
              child: ProductCard(
                product: product,
                onTap: () => onOpen(product),
                onAdd: () => onAdd(product),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _OrderingNotes extends StatelessWidget {
  const _OrderingNotes({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    const notes = <(String, String)>[
      (
        'Choose your pieces',
        'Add merch to the cart. No account needed, and your cart stays on this device.'
      ),
      (
        'Pay securely',
        'GCash, card, and other options through Xendit. The store never sees your payment details.'
      ),
      (
        'We arrange delivery',
        'The team confirms stock and delivery after payment. Add notes at checkout if you need to.'
      ),
    ];

    return Container(
      padding: const EdgeInsets.only(top: 34),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ordering, briefly',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Prices and stock are checked again when your order is placed, '
              'so the total you confirm is the total you pay.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 40,
            runSpacing: 26,
            children: notes
                .map(
                  (note) => SizedBox(
                    width: wide ? 240 : 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          note.$1,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          note.$2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                                height: 1.6,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: <Widget>[
          const BrandLogo(size: 18),
          Text(
            'Made for the ELEVATE community.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          Text(
            'Payments handled by Xendit.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
        ],
      ),
    );
  }
}
