/// Application configuration.
///
/// Only public client configuration belongs here. Supabase anon keys are
/// public by design; the Xendit secret key, Supabase service-role key, and
/// webhook callback token must never be added to this file.
class AppConfig {
  const AppConfig._();

  static const String appName = 'ELEVATE MERCH';
  static const String storeTagline =
      'Pins, shirts, long sleeves, lanyards, and Bible bookmarks.';

  static const String supabaseUrl = 'https://yqevxsnqvdtdgodbhrkv.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxZXZ4c25xdmR0ZGdvZGJocmt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI2NDQyNjgsImV4cCI6MjEwODIyMDI2OH0.SOjbQmKqsdVxGAPVYSbQBPJslCTMcNHksCBoAJ6dcG0';

  /// Supabase Edge Function names. The Xendit secret stays on the server.
  static const String createPaymentFunction = 'create-payment';

  /// Optional https storefront URL used by Xendit as the return URL.
  /// Set the same value as the STOREFRONT_URL function secret.
  static const String storefrontUrl = '';
}

