// lib/perfil/editar_perfil_page.dart
import 'package:flutter/material.dart';

class EditarPerfilPage extends StatefulWidget {
  final Map<String, dynamic> datosActuales;
  const EditarPerfilPage({Key? key, required this.datosActuales})
      : super(key: key);

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _apodoCtrl;
  late TextEditingController _contrasenaCtrl;
  late TextEditingController _edadCtrl;
  String _sexo = '';
  late TextEditingController _nombreContactoCtrl;
  late TextEditingController _contactoEmergenciaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.datosActuales;
    _nombreCtrl = TextEditingController(text: d['nombre'] ?? '');
    _apellidoCtrl = TextEditingController(text: d['apellido'] ?? '');
    _apodoCtrl = TextEditingController(text: d['apodo'] ?? '');
    _contrasenaCtrl = TextEditingController(text: d['contrasena'] ?? '');
    _edadCtrl = TextEditingController(text: d['edad']?.toString() ?? '');
    _sexo = d['sexo'] ?? '';
    _nombreContactoCtrl = TextEditingController(text: d['nombreContacto'] ?? '');
    _contactoEmergenciaCtrl = TextEditingController(text: d['contactoEmergencia']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _apodoCtrl.dispose();
    _contrasenaCtrl.dispose();
    _edadCtrl.dispose();
    _nombreContactoCtrl.dispose();
    _contactoEmergenciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A11CB).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 48,
                          color: Color(0xFF6A11CB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Editar información',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A11CB),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Actualiza tus datos personales',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 28),

                      // Campos del formulario
                      _buildInputField(
                        label: 'Nombre',
                        icon: Icons.person_outline,
                        controller: _nombreCtrl,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Apellido',
                        icon: Icons.person_outline,
                        controller: _apellidoCtrl,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Apodo',
                        icon: Icons.tag,
                        controller: _apodoCtrl,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Contraseña',
                        icon: Icons.lock_outline,
                        controller: _contrasenaCtrl,
                        obscureText: true,
                        validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Edad',
                        icon: Icons.cake_outlined,
                        controller: _edadCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo obligatorio';
                          if (int.tryParse(v) == null) return 'Número válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _sexo.isNotEmpty ? _sexo : null,
                        decoration: InputDecoration(
                          labelText: 'Sexo',
                          prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF6A11CB)),
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
                        items: ['Masculino', 'Femenino']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _sexo = v!),
                        validator: (v) => v == null ? 'Selecciona una opción' : null,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Contacto de emergencia (nombre)',
                        icon: Icons.contact_phone,
                        controller: _nombreContactoCtrl,
                        required: false,
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Teléfono de emergencia',
                        icon: Icons.phone_android,
                        controller: _contactoEmergenciaCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 32),

                      // Botón guardar
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
                              final datos = {
                                'nombre': _nombreCtrl.text,
                                'apellido': _apellidoCtrl.text,
                                'apodo': _apodoCtrl.text,
                                'contrasena': _contrasenaCtrl.text,
                                'edad': int.tryParse(_edadCtrl.text) ?? 0,
                                'sexo': _sexo,
                                'nombreContacto': _nombreContactoCtrl.text,
                                'contactoEmergencia': int.tryParse(_contactoEmergenciaCtrl.text) ?? 0,
                              };
                              Navigator.pop(context, datos);
                            }
                          },
                          child: const Text(
                            'Guardar cambios',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
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

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
    );
  }
}