// lib/config/supabase_config.dart
// Supabase connection. Set SUPABASE_URL and SUPABASE_ANON_KEY (env or --dart-define) for production.

/// Set via --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=... when building for web.
/// Or assign in code after creating project at https://supabase.com
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
