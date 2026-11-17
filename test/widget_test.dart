import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digikhata/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Provide in-memory preferences for widget tests.
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'https://zompxfhzgkkyssveglii.supabase.co',
      publishableKey: 'sb_publishable_kUznpuvTNaK3XUV5yoc30A_ECuME83R',
    );
  });

  testWidgets('DigiKhata app starts', (tester) async {
    await tester.pumpWidget(const DigiKhataApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
