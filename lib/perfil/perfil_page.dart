import 'package:flutter/material.dart';
import 'package:moodlog/database/database_helper.dart';
import 'editar_perfil_page.dart';

class PerfilPage extends StatefulWidget {
  final Map<String, dynamic> datosUsuario;
  final Function(Map<String, dynamic>) onActualizarDatos;

  const PerfilPage({
    Key? key,
    required this.datosUsuario,
    required this.onActualizarDatos,
  }) : super(key: key);

  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _alertasActivadas = true; // valor por defecto
  late int _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.datosUsuario['id'];
    _cargarPreferencia();
  }

  Future<void> _cargarPreferencia() async {
    final desactivadas = await DatabaseHelper().obtenerConfiguracion(_userId, 'alertas_desactivadas');
    setState(() {
      _alertasActivadas = desactivadas != '1';
    });
  }

  Future<void> _cambiarAlertas(bool value) async {
    setState(() {
      _alertasActivadas = value;
    });
    final nuevoValor = value ? '0' : '1';
    await DatabaseHelper().guardarConfiguracion(_userId, 'alertas_desactivadas', nuevoValor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _tarjetaInformacion(widget.datosUsuario),
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
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: const Text('Recibir alertas de apoyo emocional'),
                subtitle: const Text('Te recordaremos buscar ayuda si detectamos varios días difíciles'),
                value: _alertasActivadas,
                onChanged: _cambiarAlertas,
                activeColor: Colors.indigo,
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
      MaterialPageRoute(builder: (_) => EditarPerfilPage(datosActuales: widget.datosUsuario)),
    );
    if (nuevosDatos != null) {
      widget.onActualizarDatos(nuevosDatos);
      _cargarPreferencia(); // recarga por si cambió el id (aunque no debería)
    }
  }
}