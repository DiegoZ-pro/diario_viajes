import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: 'https://choratrufzpkprgfbylb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNob3JhdHJ1Znpwa3ByZ2ZieWxiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5MDc5ODAsImV4cCI6MjA5MDQ4Mzk4MH0.r59vTI1sHLz0pR9QWCLy-QQWoN58_mLjeKcNsZgG3GY',
  );

  runApp(
    // providerScope es el contenedor raíz de riverpod
    const ProviderScope(child: TravelDiaryApp()),
  );
}

// atajo para acceder a supabase en cualquier lugar
final supabase = Supabase.instance.client;
