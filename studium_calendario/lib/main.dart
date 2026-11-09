import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'calendario/cal_estilo.dart';
import 'calendario/calendario_page.dart';
import 'calendario/calendario_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // A URL do projeto foi deduzida do usuário do pooler em db.php
    // (postgres.<ref>). Confira no painel do Supabase.
    url: 'https://eoujlobvrtsflkbiucno.supabase.co',
    // Painel Supabase > Project Settings > API > "anon public".
    anonKey: 'COLE_AQUI_A_ANON_KEY',
  );

  runApp(const StudiumApp());
}

class StudiumApp extends StatelessWidget {
  const StudiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studium',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: CalCores.roxo),
      ),
      home: CalendarioPage(
        // Troque pelo id do usuário logado (equivalente a $_SESSION['usuario_id']).
        // Com null, o app lista os eventos de todos, igual ao fallback do PHP.
        repo: CalendarioRepository(idUsuario: null),
      ),
    );
  }
}
