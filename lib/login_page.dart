import 'package:flutter/material.dart';
import 'package:moodlog/database/database_helper.dart';
import 'registro_page.dart';
import 'bienvenida_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String usuario = '';
  String contrasena = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mood, size: 80, color: Color(0xFF6A11CB)),
                      const Text('MoodLog', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
                      const SizedBox(height: 24),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Usuario (apodo)', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                        onSaved: (value) => usuario = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                        onSaved: (value) => contrasena = value!,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              final user = await DatabaseHelper().getUserByApodo(usuario);
                              if (user != null && user['contrasena'] == contrasena) {
                                if (!mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => BienvenidaPage(userData: user)),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Usuario o contraseña incorrectos'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          child: const Text('Iniciar sesión', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegistroPage())),
                        child: const Text('¿No tienes cuenta? Regístrate'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}