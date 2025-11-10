import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screen/login_screen.dart' as login;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AhorraMax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
         primaryColor: const Color(0xFF2ECC71), // Verde AhorraMax
         colorScheme: const ColorScheme.light(
           primary: Color(0xFF2ECC71), // Verde principal
           secondary: Color(0xFF4FA3FF), // Azul IA
           tertiary: Color(0xFF00C853), // Verde brillante CTA
           surface: Colors.white,
           onPrimary: Colors.white,
           onSecondary: Colors.white,
         ),
         useMaterial3: true,
         fontFamily: 'Inter', // Cambiado a Inter según especificación
       ),
       darkTheme: ThemeData.dark(
         useMaterial3: true,
       ).copyWith(
         primaryColor: const Color(0xFF2ECC71),
         colorScheme: const ColorScheme.dark(
           primary: Color(0xFF2ECC71),
           secondary: Color(0xFF4FA3FF),
           tertiary: Color(0xFF00C853),
           surface: const Color(0xFF1E1E1E),
           onSurface: Colors.white,
         ),
         scaffoldBackgroundColor: const Color(0xFF121212),
         cardColor: const Color(0xFF1E1E1E),
       ),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const login.LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(toggleTheme: _toggleTheme),
        '/profile': (context) => ProfileScreen(toggleTheme: _toggleTheme),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        return const login.LoginScreen();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '🔥 Bienvenido a AhorraMax',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
