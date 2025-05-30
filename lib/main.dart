  import 'package:flutter/material.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'firebase_options.dart';
  import 'screens/giris_ekrani.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(MyApp());
    } catch (e) {
      print("Firebase başlatma hatası: $e");
    }
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Epilepsi Takip',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        home: GirisEkrani(),
      );
    }
  }