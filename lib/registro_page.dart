// lib/registro_page.dart
import 'package:flutter/material.dart';
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
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 12,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono decorativo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A11CB).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1,
                          size: 56,
                          color: Color(0xFF6A11CB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A11CB),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completa tus datos para comenzar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Campos del formulario
                      _buildInputField(
                        label: 'Nombre',
                        icon: Icons.person_outline,
                        onSaved: (v) => nombre = v!,
                        validator: (v) => v == null || v.isEmpty ? 'Nombre requerido' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Apellido',
                        icon: Icons.person_outline,
                        onSaved: (v) => apellido = v!,
                        validator: (v) => v == null || v.isEmpty ? 'Apellido requerido' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Apodo (cómo te llamaremos)',
                        icon: Icons.tag,
                        onSaved: (v) => apodo = v!,
                        validator: (v) => v == null || v.isEmpty ? 'Apodo requerido' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Contraseña',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        onSaved: (v) => contrasena = v!,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Contraseña requerida';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Edad',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        onSaved: (v) => edad = int.parse(v!),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Edad requerida';
                          if (int.tryParse(v) == null) return 'Número válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Sexo',
                          prefixIcon: const Icon(Icons.people_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        value: sexo.isNotEmpty ? sexo : null,
                        items: ['Masculino', 'Femenino']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => sexo = v!),
                        validator: (v) => v == null ? 'Selecciona una opción' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Contacto de emergencia (nombre)',
                        icon: Icons.contact_phone,
                        required: false,
                        onSaved: (v) => nombreContacto = v ?? '',
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Teléfono de emergencia',
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.number,
                        onSaved: (v) => contactoEmergencia = int.parse(v!),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Teléfono requerido';
                          if (int.tryParse(v) == null) return 'Solo números';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Botón registrar
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A11CB),
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: const Color(0xFF6A11CB).withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              final datos = {
                                'nombre': nombre,
                                'apellido': apellido,
                                'apodo': apodo,
                                'contrasena': contrasena,
                                'edad': edad,
                                'sexo': sexo,
                                'nombreContacto': nombreContacto,
                                'contactoEmergencia': contactoEmergencia,
                              };
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BienvenidaPage(userData: datos),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Ya tienes cuenta?'),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                color: Color(0xFF6A11CB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildInputField({
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6A11CB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: required
          ? (validator ?? (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null)
          : null,
      onSaved: onSaved,
    );
  }
}