import 'package:flutter/material.dart';
import 'package:moodlog/database/database_helper.dart';
import 'bienvenida_page.dart';

class RegistroPage extends StatefulWidget {
  @override
  _RegistroPageState createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();

  String nombre = '';
  String apellido = '';
  String apodo = '';
  String contrasena = '';
  int edad = 0;
  String sexo = '';
  String nombreContacto = '';
  int contactoEmergencia = 0;

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
                      const Icon(Icons.person_add, size: 70, color: Color(0xFF6A11CB)),
                      const Text('Crear cuenta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
                      const SizedBox(height: 24),
                      _campo('Nombre', (v) => nombre = v!),
                      _campo('Apellido', (v) => apellido = v!),
                      _campo('Apodo (cómo te llamaremos)', (v) => apodo = v!),
                      const SizedBox(height: 8),
                      TextFormField(
                        obscureText: true,
                        decoration: _decoracion('Contraseña', Icons.lock),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo obligatorio';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                        onSaved: (v) => contrasena = v!,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: _decoracion('Edad', Icons.cake),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo obligatorio';
                          if (int.tryParse(v) == null) return 'Número inválido';
                          return null;
                        },
                        onSaved: (v) => edad = int.parse(v!),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: _decoracion('Sexo', Icons.people),
                        value: sexo.isNotEmpty ? sexo : null,
                        items: ['Masculino', 'Femenino'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => sexo = v!),
                        validator: (v) => v == null ? 'Selecciona una opción' : null,
                      ),
                      const SizedBox(height: 8),
                      _campo('Contacto de emergencia (nombre)', (v) => nombreContacto = v!, obligatorio: false),
                      const SizedBox(height: 8),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: _decoracion('Teléfono de emergencia', Icons.phone),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo obligatorio';
                          if (int.tryParse(v) == null) return 'Solo números';
                          return null;
                        },
                        onSaved: (v) => contactoEmergencia = int.parse(v!),
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
                              final nuevoUsuario = {
                                'nombre': nombre,
                                'apellido': apellido,
                                'apodo': apodo,
                                'contrasena': contrasena,
                                'edad': edad,
                                'sexo': sexo,
                                'nombreContacto': nombreContacto,
                                'contactoEmergencia': contactoEmergencia,
                              };
                              int id = await DatabaseHelper().insertUser(nuevoUsuario);
                              nuevoUsuario['id'] = id;
                              if (!mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => BienvenidaPage(userData: nuevoUsuario)),
                              );
                            }
                          },
                          child: const Text('Registrarse', style: TextStyle(fontSize: 16)),
                        ),
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

  Widget _campo(String label, Function(String?) onSaved, {bool obligatorio = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        decoration: _decoracion(label, Icons.text_fields),
        validator: obligatorio ? (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null : null,
        onSaved: onSaved,
      ),
    );
  }

  InputDecoration _decoracion(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}