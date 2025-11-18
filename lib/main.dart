import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screen/login_screen.dart' as login;
import 'services/user_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase inicializado correctamente");
  } catch (e) {
    print("❌ Error inicializando Firebase: $e");
    // Continuar sin Firebase para evitar crash
  }

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
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _setLightTheme() {
    setState(() {
      _themeMode = ThemeMode.light;
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
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        primaryColor: const Color(0xFF2ECC71),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2ECC71),
          secondary: Color(0xFF4FA3FF),
          tertiary: Color(0xFF00C853),
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dialogBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
      ),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const login.LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(toggleTheme: _toggleTheme, setLightTheme: _setLightTheme),
        '/profile': (context) => ProfileScreen(toggleTheme: _toggleTheme),
      },
      onUnknownRoute: (settings) {
        // Fallback para rutas no encontradas
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('Página no encontrada'),
            ),
          ),
        );
      },
    );
  }
}

/// ✅ CREA AUTOMÁTICAMENTE TODO EL PERFIL Y DATOS INICIALES DEL USUARIO
Future<void> cargarDatosUsuario() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final docRef =
      FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
  final doc = await docRef.get();

  if (!doc.exists) {
    // Crea el documento del usuario
    await docRef.set({
      "nombre": "Nuevo Usuario",
      "email": user.email,
      "idioma": "es",
      "temaColor": "verde",
      "notificacionesActivas": true,
      "balanceActual": 0,
      "metaPrincipal": 0,
      "fechaRegistro": DateTime.now(),
    });

    // ✅ Crear subcolecciones automáticas
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('gastos')
        .add({
      "categoria": "Inicial",
      "monto": 0,
      "descripcion": "Primer gasto vacío",
      "fecha": DateTime.now(),
      "ahorradoConIA": false,
    });

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('ahorros')
        .add({
      "monto": 0,
      "meta": 100,
      "progreso": 0,
      "fechaInicio": DateTime.now(),
      "fechaMeta": DateTime.now().add(const Duration(days: 30)),
    });

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('notificaciones')
        .add({
      "titulo": "¡Bienvenido a AhorraMax!",
      "mensaje":
          "Empieza a registrar tus gastos y descubre descuentos cerca de ti",
      "fecha": DateTime.now(),
      "leido": false,
    });

    print("Usuario y colecciones creadas correctamente.");
  } else {
    print("Usuario ya tiene datos guardados.");
  }

  // También llamar al servicio para crear perfil automático
  final userService = UserDataService();
  await userService.crearPerfilAutomatico();
}

/// Manejador de autenticación
class AuthWrapper extends StatelessWidget {
  final VoidCallback? setLightTheme;

  const AuthWrapper({super.key, this.setLightTheme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Llama a la creación automática de datos
          cargarDatosUsuario();
          return DashboardScreen(setLightTheme: setLightTheme);
        }

        return const login.LoginScreen();
      },
    );
  }
}

/// Página de inicio temporal
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Bienvenido a AhorraMax',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

