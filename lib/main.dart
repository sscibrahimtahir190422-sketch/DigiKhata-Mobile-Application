import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zompxfhzgkkyssveglii.supabase.co',
    publishableKey: 'sb_publishable_kUznpuvTNaK3XUV5yoc30A_ECuME83R',
  );

  runApp(const DigiKhataApp());
}
