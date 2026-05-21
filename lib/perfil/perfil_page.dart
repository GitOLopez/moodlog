import 'package:flutter/material.dart';
import 'editar_perfil_page.dart';

class PerfilPage extends StatelessWidget {
  final Map<String, dynamic> datosUsuario;
  final Function(Map<String, dynamic>) onActualizarDatos;

  const PerfilPage({
    Key? key,
    required this.datosUsuario,
    required this.onActualizarDatos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _tarjetaInformacion(datosUsuario),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _abrirEdicion(context),
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaInformacion(Map<String, dynamic> datos) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF6A11CB),
              child: Icon(Icons.person, size: 45, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              datos['apodo'] ?? 'Usuario',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _filaInfo('Nombre', datos['nombre']),
            _filaInfo('Apellido', datos['apellido']),
            _filaInfo('Edad', datos['edad']?.toString()),
            _filaInfo('Sexo', datos['sexo']),
            _filaInfo('Contacto emergencia', datos['nombreContacto']),
            _filaInfo('Tel. emergencia', datos['contactoEmergencia']?.toString()),
          ],
        ),
      ),
    );
  }

  Widget _filaInfo(String etiqueta, String? valor) {
    final texto = (valor == null || valor.isEmpty) ? 'No especificado' : valor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              etiqueta,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  void _abrirEdicion(BuildContext context) async {
    final nuevosDatos = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => EditarPerfilPage(datosActuales: datosUsuario)),
    );
    if (nuevosDatos != null) {
      onActualizarDatos(nuevosDatos);
    }
  }
}