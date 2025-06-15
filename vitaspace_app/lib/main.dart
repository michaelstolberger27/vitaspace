import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/spaces_provider.dart';
import 'providers/device_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/sign_up_page.dart';
import 'screens/home_page.dart';
import 'screens/spaces_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpacesProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VitaSpace',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginPage(),
          '/sign_up': (context) => SignUpPage(),
          '/home': (context) => HomePage(),
          '/spaces': (context) => SpacesPage(),
        },
      ),
    );
  }
}
