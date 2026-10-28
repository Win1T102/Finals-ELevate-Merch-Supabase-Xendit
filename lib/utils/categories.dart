/// Display names and ordering for the catalogue's categories.
///
/// The database migration normalises common spellings already, so this is
/// mostly about presenting consistent labels and a deliberate browse order.
class ProductCategories {
  const ProductCategories._();

  static const String all = 'All';

  static const List<String> _order = <String>[
    'Pins',
    'T-shirts',
    'Long sleeves',
    'Lanyards',
    'Bookmarks',
  ];

  static const Map<String, String> _aliases = <String, String>{
    'pin': 'Pins',
    'pins': 'Pins',
    'shirt': 'T-shirts',
    'shirts': 'T-shirts',
    'tshirt': 'T-shirts',
    'tshirts': 'T-shirts',
    't-shirt': 'T-shirts',
    't-shirts': 'T-shirts',
    'tee': 'T-shirts',
    'tees': 'T-shirts',
    'long sleeve': 'Long sleeves',
    'long sleeves': 'Long sleeves',
    'long-sleeve': 'Long sleeves',
    'long-sleeves': 'Long sleeves',
    'longsleeve': 'Long sleeves',
    'longsleeves': 'Long sleeves',
    'lanyard': 'Lanyards',
    'lanyards': 'Lanyards',
    'bookmark': 'Bookmarks',
    'bookmarks': 'Bookmarks',
    'bible bookmark': 'Bookmarks',
    'bible bookmarks': 'Bookmarks',
  };

  /// A clean label for a category as stored in the database.
  static String label(String? raw) {
    final display = displayLabel(raw);
    return display ?? 'The collection';
  }

  /// The label to show for a category, or null when none is set.
  static String? displayLabel(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    final key = text.toLowerCase();
    final canonical = _aliases[key];
    if (canonical != null) return canonical;
    // Title-case unknown categories without destroying acronyms.
    return text
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Known categories first, then anything custom, alphabetically.
  static int compare(String? a, String? b) {
    final left = label(a);
    final right = label(b);
    final leftIndex = _order.indexOf(left);
    final rightIndex = _order.indexOf(right);
    if (leftIndex == -1 && rightIndex == -1) return left.compareTo(right);
    if (leftIndex == -1) return 1;
    if (rightIndex == -1) return -1;
    return leftIndex.compareTo(rightIndex);
  }

  /// Categories in browse order, empty ones removed, `All` first.
  static List<String> filters(Iterable<String?> rawCategories) {
    final seen = <String>{};
    final values = <String>[];
    for (final raw in rawCategories) {
      final resolved = label(raw);
      if (resolved == 'The collection') continue;
      if (seen.add(resolved)) values.add(resolved);
    }
    values.sort((a, b) => compare(a, b));
    if (values.length < 2) return const <String>[];
    return <String>[all, ...values];
  }
}
