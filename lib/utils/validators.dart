/// Form validation shared by checkout and account screens.
class Validators {
  const Validators._();

  static final RegExp _phone = RegExp(r'^\+?[0-9][0-9 -]{6,19}$');
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) {
    final text = (value ?? '').trim();
    if (text.length < 2) return 'Enter your full name.';
    if (text.length > 120) return 'Keep the name under 120 characters.';
    return null;
  }

  static String? phone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter a contact number.';
    if (!_phone.hasMatch(text)) {
      return 'Use a number such as 0917 123 4567.';
    }
    return null;
  }

  static String? address(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your delivery address.';
    if (text.length < 10) return 'Add a little more detail so delivery is clear.';
    if (text.length > 500) return 'Keep the address under 500 characters.';
    return null;
  }

  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (text.length > 254 || !_email.hasMatch(text)) {
      return 'Enter a valid email address, or leave it blank.';
    }
    return null;
  }

  static String? notes(String? value) {
    final text = (value ?? '').trim();
    if (text.length > 500) return 'Keep notes under 500 characters.';
    return null;
  }

  static String? requiredEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(text)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.length < 8) return 'Use at least 8 characters.';
    return null;
  }
}
