import 'package:appiombi/app.dart';
import 'package:appiombi/config/app_config.dart';
import 'package:appiombi/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Appiombi app widget builds', (tester) async {
    final config = AppConfig(
      supabaseUrl: 'your_supabase_project_url',
      supabaseAnonKey: 'your_supabase_anon_key',
    );
    final supabaseService = SupabaseService(config);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          supabaseServiceProvider.overrideWithValue(supabaseService),
        ],
        child: const App(),
      ),
    );
    await tester.pump();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Appiombi'), findsOneWidget);
  });
}
