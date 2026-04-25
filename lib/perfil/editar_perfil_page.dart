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
    _nombreContactoCtrl =
        TextEditingController(text: d['nombreContacto'] ?? '');
    _contactoEmergenciaCtrl =
        TextEditingController(text: d['contactoEmergencia']?.toString() ?? '');
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
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _campoTexto('Nombre', _nombreCtrl),
              _campoTexto('Apellido', _apellidoCtrl),
              _campoTexto('Apodo', _apodoCtrl),
              TextFormField(
                controller: _contrasenaCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _edadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Edad'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obligatorio';
                  if (int.tryParse(v) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _sexo.isNotEmpty ? _sexo : null,
                decoration: const InputDecoration(labelText: 'Sexo'),
                items: ['Masculino', 'Femenino']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _sexo = v!),
                validator: (v) => v == null ? 'Selecciona una opción' : null,
              ),
              const SizedBox(height: 12),
              _campoTexto('Contacto emergencia (nombre)', _nombreContactoCtrl,
                  obligatorio: false),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactoEmergenciaCtrl,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: 'Teléfono emergencia'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
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
                      'contactoEmergencia':
                      int.tryParse(_contactoEmergenciaCtrl.text) ?? 0,
                    };
                    Navigator.pop(context, datos);
                  }
                },
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(String label, TextEditingController controller,
      {bool obligatorio = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: obligatorio
            ? (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null
            : null,
      ),
    );
  }
}