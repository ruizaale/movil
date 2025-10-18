import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'home.dart'; // Asegúrate de tener tu archivo home.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arbol Red Login',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String passwordStrength = ""; // ✅ Nivel de seguridad
  Color strengthColor = Colors.grey; // ✅ Color visual

  // ---- FUNCIÓN DE EVALUACIÓN DE CONTRASEÑA ----
  void checkPasswordStrength(String password) {
    String strength;
    Color color;

    if (password.isEmpty) {
      strength = "";
      color = Colors.grey;
    } else if (password.length < 6) {
      strength = "Débil";
      color = Colors.red;
    } else if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#\$&*~.,%]'))) {
      strength = "Segura";
      color = Colors.green;
    } else if (password.length >= 8) {
      strength = "Media";
      color = Colors.orange;
    } else {
      strength = "Débil";
      color = Colors.red;
    }

    setState(() {
      passwordStrength = strength;
      strengthColor = color;
    });
  }

  // ---- FUNCIÓN DE ENVÍO (YA FUNCIONA) ----
  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    final usersRef = firestore.collection('users');

    try {
      if (isLogin) {
        final query = await usersRef
            .where('email', isEqualTo: email)
            .where('password', isEqualTo: password)
            .get();

        if (!mounted) return;

        if (query.docs.isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario o contraseña incorrectos')),
          );
        }
      } else {
        final query = await usersRef.where('email', isEqualTo: email).get();

        if (!mounted) return;

        if (query.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El correo ya está registrado')),
          );
          return;
        }

        await usersRef.add({
          'email': email,
          'password': password,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado exitosamente')),
        );

        setState(() {
          isLogin = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Imagen del logo
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.transparent,
                  backgroundImage: const AssetImage('assets/logo.jpeg'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Arbol Red',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // Password con validación de seguridad
                TextField(
                  controller: passwordController,
                  onChanged: checkPasswordStrength,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),

                // Indicador de fuerza
                const SizedBox(height: 8),
                if (passwordStrength.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Seguridad: ",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        passwordStrength,
                        style: TextStyle(
                          color: strengthColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                // Recomendación
                const SizedBox(height: 6),
                Text(
                  "Usa letras mayúsculas, números y caracteres especiales (!@#\$&*)",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 30),

                // Botón
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLogin ? 'Iniciar sesión' : 'Registrarse',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Botón para cambiar entre login / registro
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin
                        ? '¿No tienes cuenta? Regístrate'
                        : '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
