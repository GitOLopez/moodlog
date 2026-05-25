// lib/bienvenida_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moodlog/database/database_helper.dart';
import 'estadistica/estadistica_page.dart';
import 'perfil/perfil_page.dart';

const int TIEMPO_LIMITE_MINUTOS = 5; // Cambia a 1 para pruebas
const Set<String> emojisNegativos = {'😢', '😡', '😞'};

class BienvenidaPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BienvenidaPage({Key? key, required this.userData}) : super(key: key);

  @override
  _BienvenidaPageState createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  List<Map<String, dynamic>> estados = [];
  late Map<String, dynamic> _userData;
  late int _userId;
  Timer? _refreshTimer;
  late AnimationController _animationController;

  void _actualizarTiempos() {
    final ahora = DateTime.now();
    final limiteSegundos = TIEMPO_LIMITE_MINUTOS * 60;
    bool huboCambio = false;
    for (var estado in estados) {
      final creado = estado['fecha'] as DateTime;
      final segundosPasados = ahora.difference(creado).inSeconds;
      final nuevosSegundos = (limiteSegundos - segundosPasados).clamp(0, limiteSegundos);
      if (estado['segundosRestantes'] != nuevosSegundos) {
        estado['segundosRestantes'] = nuevosSegundos;
        huboCambio = true;
      }
    }
    if (huboCambio) setState(() {});
  }

  void _iniciarTimerRefresco() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (estados.any((e) => (e['segundosRestantes'] as int) > 0)) {
        _actualizarTiempos();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animationController.forward();
    _userData = Map<String, dynamic>.from(widget.userData);
    _userId = _userData['id'];
    _cargarEstadosDesdeBD();
    _iniciarTimerRefresco();
  }

  // ==================== APOYO EMOCIONAL ====================
  Future<int> _contarDiasConEmocionesNegativasEnUltimaSemana() async {
    final hoy = DateTime.now();
    final hace7Dias = hoy.subtract(const Duration(days: 7));
    final registros = await DatabaseHelper().getMemoriesByUserInRange(_userId, hace7Dias, hoy);
    final diasConNegativos = <String>{};
    for (var reg in registros) {
      if (emojisNegativos.contains(reg['emoji'])) {
        final fecha = DateTime.parse(reg['created_at']);
        final diaKey = '${fecha.year}-${fecha.month}-${fecha.day}';
        diasConNegativos.add(diaKey);
      }
    }
    return diasConNegativos.length;
  }

  Future<int> _contarEmocionesNegativasHoy() async {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final finHoy = inicioHoy.add(const Duration(days: 1));
    final registros = await DatabaseHelper().getMemoriesByUserInRange(_userId, inicioHoy, finHoy);
    int count = 0;
    for (var reg in registros) {
      if (emojisNegativos.contains(reg['emoji'])) count++;
    }
    return count;
  }

  Future<void> _verificarYMostrarMensajeAyuda() async {
    final desactivadas = await DatabaseHelper().obtenerConfiguracion(_userId, 'alertas_desactivadas');
    if (desactivadas == '1') return;

    final ultimoMensajeStr = await DatabaseHelper().obtenerConfiguracion(_userId, 'ultimo_mensaje_ayuda');
    DateTime? ultimoMensaje;
    if (ultimoMensajeStr != null) {
      ultimoMensaje = DateTime.tryParse(ultimoMensajeStr);
    }
    if (ultimoMensaje != null && DateTime.now().difference(ultimoMensaje).inDays < 5) return;

    final diasNegativosSemana = await _contarDiasConEmocionesNegativasEnUltimaSemana();
    final negativosHoy = await _contarEmocionesNegativasHoy();

    bool condicionSemana = diasNegativosSemana >= 3;
    bool condicionHoy = negativosHoy >= 2;

    if (condicionSemana || condicionHoy) {
      final mensaje = condicionHoy
          ? 'Hoy has tenido varias emociones difíciles. Recuerda que no estás solo.'
          : 'En los últimos días has registrado emociones difíciles con frecuencia. Recuerda que no estás solo.';
      await _mostrarDialogoAyuda(mensaje);
      await DatabaseHelper().guardarConfiguracion(_userId, 'ultimo_mensaje_ayuda', DateTime.now().toIso8601String().split('T')[0]);
    }
  }

  Future<void> _mostrarDialogoAyuda(String mensaje) async {
    final telefonoContacto = _userData['contactoEmergencia']?.toString() ?? '';
    final nombreContacto = _userData['nombreContacto'] ?? 'Contacto de emergencia';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('💙 ¿Necesitas apoyo?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Recordar más tarde', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              Navigator.pop(context);
              _mostrarRecursosAyuda(telefonoContacto, nombreContacto);
            },
            child: const Text('Sí, necesito ayuda'),
          ),
        ],
      ),
    );
  }

  void _mostrarRecursosAyuda(String telefonoContacto, String nombreContacto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Opciones de ayuda', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.indigo.shade100, child: const Icon(Icons.phone, color: Colors.indigo)),
              title: const Text('Línea #TeEscucho (ISSS)'),
              subtitle: const Text('7071-1302'),
              onTap: () async {
                Navigator.pop(context);
                final Uri telUri = Uri(scheme: 'tel', path: '70711302');
                if (await canLaunchUrl(telUri)) {
                  await launchUrl(telUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se puede realizar la llamada'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
            ),
            if (telefonoContacto.isNotEmpty)
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.person, color: Colors.green)),
                title: Text('Llamar a $nombreContacto'),
                subtitle: Text(telefonoContacto),
                onTap: () async {
                  Navigator.pop(context);
                  final numeroLimpio = telefonoContacto.replaceAll(RegExp(r'[^0-9]'), '');
                  final Uri telUri = Uri(scheme: 'tel', path: numeroLimpio);
                  if (await canLaunchUrl(telUri)) {
                    await launchUrl(telUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se puede realizar la llamada'), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  // ==================== FIN APOYO EMOCIONAL ====================

  Future<void> _cargarEstadosDesdeBD() async {
    final memories = await DatabaseHelper().getMemoriesByUser(_userId);
    setState(() {
      estados = memories.map((mem) => _memoryToEstado(mem)).toList();
      _actualizarTiempos();
    });
    _verificarYMostrarMensajeAyuda();
  }

  Map<String, dynamic> _memoryToEstado(Map<String, dynamic> memory) {
    DateTime created = DateTime.parse(memory['created_at']);
    int segundosPasados = DateTime.now().difference(created).inSeconds;
    int limiteSegundos = TIEMPO_LIMITE_MINUTOS * 60;
    int segundosRestantes = (limiteSegundos - segundosPasados).clamp(0, limiteSegundos);
    List<String> notas = [];
    if (memory['notas_json'] != null && memory['notas_json'].isNotEmpty) {
      try {
        notas = List<String>.from(jsonDecode(memory['notas_json']));
      } catch (e) {}
    }
    return {
      'id': memory['id'],
      'fecha': created,
      'hora': '${created.hour}:${created.minute.toString().padLeft(2, '0')}',
      'emoji': memory['emoji'],
      'titulo': memory['titulo'],
      'descripcion': memory['descripcion'],
      'foto': memory['foto_path'] ?? '',
      'notas': notas,
      'segundosRestantes': segundosRestantes,
    };
  }

  Future<void> agregarEstado(String emoji, String titulo, String descripcion, {String? foto}) async {
    final ahora = DateTime.now();
    final nuevoMemory = {
      'user_id': _userId,
      'emoji': emoji,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto_path': foto ?? '',
      'notas_json': '[]',
    };
    int id = await DatabaseHelper().insertMemory(nuevoMemory);
    final nuevoEstado = {
      'id': id,
      'fecha': ahora,
      'hora': '${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}',
      'emoji': emoji,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto': foto ?? '',
      'notas': <String>[],
      'segundosRestantes': TIEMPO_LIMITE_MINUTOS * 60,
    };
    setState(() => estados.insert(0, nuevoEstado));
    if (emojisNegativos.contains(emoji)) {
      _verificarYMostrarMensajeAyuda();
    }
  }

  Future<void> editarEstado(int index, String emoji, String titulo, String descripcion, {String? foto}) async {
    final estado = estados[index];
    final memoryId = estado['id'];
    final updatedMemory = {
      'id': memoryId,
      'emoji': emoji,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto_path': foto ?? estado['foto'],
      'notas_json': jsonEncode(estado['notas']),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await DatabaseHelper().updateMemory(updatedMemory);
    setState(() {
      estados[index]['emoji'] = emoji;
      estados[index]['titulo'] = titulo;
      estados[index]['descripcion'] = descripcion;
      estados[index]['foto'] = foto ?? estado['foto'];
    });
  }

  Future<void> eliminarEstado(int index) async {
    final estado = estados[index];
    await DatabaseHelper().deleteMemory(estado['id']);
    setState(() => estados.removeAt(index));
  }

  Future<void> agregarNota(int index, String nuevaNota) async {
    setState(() => estados[index]['notas'].add(nuevaNota));
    final memoryId = estados[index]['id'];
    final nuevasNotasJson = jsonEncode(estados[index]['notas']);
    await DatabaseHelper().updateMemory({
      'id': memoryId,
      'notas_json': nuevasNotasJson,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFF), Color(0xFFEFF3FE)],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            BienvenidaHomeContent(
              apodo: _userData['apodo'] ?? 'Usuario',
              estados: estados,
              onAgregarEstado: (emoji, titulo, descripcion, {foto}) =>
                  agregarEstado(emoji, titulo, descripcion, foto: foto),
              onEditarEstado: (index, emoji, titulo, descripcion, {foto}) =>
                  editarEstado(index, emoji, titulo, descripcion, foto: foto),
              onEliminarEstado: eliminarEstado,
              onAgregarNota: agregarNota,
            ),
            EstadisticaPage(userId: _userId),
            PerfilPage(
              datosUsuario: _userData,
              onActualizarDatos: (nuevosDatos) => setState(() => _userData = nuevosDatos),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: isWide ? BottomNavigationBarType.fixed : BottomNavigationBarType.shifting,
            selectedItemColor: Colors.indigo.shade700,
            unselectedItemColor: Colors.grey.shade500,
            showUnselectedLabels: true,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Estadísticas'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
            ],
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

// ======================== BienvenidaHomeContent ========================
class BienvenidaHomeContent extends StatefulWidget {
  final String apodo;
  final List<Map<String, dynamic>> estados;
  final Future<void> Function(String emoji, String titulo, String descripcion, {String? foto}) onAgregarEstado;
  final Future<void> Function(int index, String emoji, String titulo, String descripcion, {String? foto}) onEditarEstado;
  final Future<void> Function(int index) onEliminarEstado;
  final Future<void> Function(int index, String nota) onAgregarNota;

  const BienvenidaHomeContent({
    Key? key,
    required this.apodo,
    required this.estados,
    required this.onAgregarEstado,
    required this.onEditarEstado,
    required this.onEliminarEstado,
    required this.onAgregarNota,
  }) : super(key: key);

  @override
  _BienvenidaHomeContentState createState() => _BienvenidaHomeContentState();
}

class _BienvenidaHomeContentState extends State<BienvenidaHomeContent> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fabController.forward();
  }

  // --- Manejo robusto de imágenes (bytes) ---
  Future<String?> _copiarImagenAPersistente(File imagenOriginal) async {
    try {
      // Leer bytes de la imagen original
      final bytes = await imagenOriginal.readAsBytes();
      if (bytes.isEmpty) {
        print('❌ El archivo original está vacío');
        return null;
      }
      final directorio = await getApplicationDocumentsDirectory();
      final nombreArchivo = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final nuevaRuta = '${directorio.path}/$nombreArchivo';
      final nuevoArchivo = File(nuevaRuta);
      await nuevoArchivo.writeAsBytes(bytes);
      if (await nuevoArchivo.exists()) {
        print('✅ Imagen copiada correctamente a: $nuevaRuta');
        return nuevaRuta;
      } else {
        print('❌ No se pudo crear el archivo de imagen');
        return null;
      }
    } catch (e) {
      print('❌ Error copiando imagen: $e');
      return null;
    }
  }

  Future<Uint8List?> _loadImageBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        print('⚠️ Archivo no existe: $path');
        return null;
      }
    } catch (e) {
      print('❌ Error leyendo imagen: $e');
      return null;
    }
  }

  Widget _buildImageWidget(String? path, {double height = 120}) {
    if (path == null || path.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Uint8List?>(
      future: _loadImageBytes(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(height: height, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              snapshot.data!,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: height,
                color: Colors.grey[200],
                child: const Center(child: Text('Error de imagen', style: TextStyle(color: Colors.grey))),
              ),
            ),
          );
        } else {
          print('⚠️ No se pudieron cargar los bytes de la imagen: $path');
          return Container(
            height: height,
            color: Colors.grey[200],
            child: const Center(child: Text('Imagen no disponible', style: TextStyle(color: Colors.grey))),
          );
        }
      },
    );
  }

  Future<File?> _seleccionarImagen() async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle), child: Icon(Icons.photo_library, color: Colors.indigo.shade700)),
              title: const Text('Galería', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final rutaPersistente = await _copiarImagenAPersistente(File(image.path));
                  if (rutaPersistente != null) {
                    Navigator.pop(context, File(rutaPersistente));
                  } else {
                    Navigator.pop(context, null);
                  }
                } else {
                  Navigator.pop(context, null);
                }
              },
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle), child: Icon(Icons.camera_alt, color: Colors.indigo.shade700)),
              title: const Text('Cámara', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  final rutaPersistente = await _copiarImagenAPersistente(File(image.path));
                  if (rutaPersistente != null) {
                    Navigator.pop(context, File(rutaPersistente));
                  } else {
                    Navigator.pop(context, null);
                  }
                } else {
                  Navigator.pop(context, null);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> estado) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(estado['emoji'], style: const TextStyle(fontSize: 48)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(estado['titulo'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                  child: Text('📅 ${estado['fecha'].day}/${estado['fecha'].month}/${estado['fecha'].year} • ${estado['hora']}', style: TextStyle(color: Colors.grey.shade700)),
                ),
                const SizedBox(height: 20),
                const Text('¿Qué hiciste hoy?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(estado['descripcion'], style: const TextStyle(fontSize: 16, height: 1.4)),
                if (estado['foto'] != null && estado['foto'].isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('📸 Momento capturado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildImageWidget(estado['foto'], height: 200),
                ],
                if (estado['notas'].isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('📝 Notas personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...estado['notas'].map((n) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [const Icon(Icons.circle, size: 6), const SizedBox(width: 8), Expanded(child: Text(n))]))),
                ],
                const SizedBox(height: 16),
                if ((estado['segundosRestantes'] as int) > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [Icon(Icons.timer, color: Colors.amber.shade800), const SizedBox(width: 8), Text('Puedes editar por ${_formatTiempo(estado['segundosRestantes'])}', style: TextStyle(color: Colors.amber.shade800))]),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void mostrarFormularioNuevoEstado() {
    String? emoji;
    String titulo = '';
    String descripcion = '';
    File? imagen;
    String? errorEmoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Text('✨ Nuevo estado de ánimo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 8),
                const Text('¿Cómo te sientes hoy?', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['😊', '😢', '😡', '😐', '😞'].map((e) {
                    final selected = emoji == e;
                    return GestureDetector(
                      onTap: () => setModalState(() { emoji = e; errorEmoji = null; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()..scale(selected ? 1.3 : 1.0),
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? Colors.indigo.shade100 : Colors.grey.shade100),
                          padding: const EdgeInsets.all(12),
                          child: Text(e, style: TextStyle(fontSize: 32, color: selected ? Colors.indigo : Colors.black87)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (errorEmoji != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(errorEmoji!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(labelText: 'Título', prefixIcon: const Icon(Icons.title), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  onChanged: (v) => titulo = v,
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(labelText: '¿Qué hiciste hoy?', prefixIcon: const Icon(Icons.edit_note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  onChanged: (v) => descripcion = v,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(imagen == null ? Icons.add_a_photo : Icons.change_circle),
                  label: Text(imagen == null ? 'Agregar foto' : 'Cambiar foto'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () async {
                    final img = await _seleccionarImagen();
                    if (img != null) setModalState(() => imagen = img);
                  },
                ),
                if (imagen != null) const Padding(padding: EdgeInsets.only(top: 8), child: Text('✓ Foto lista', style: TextStyle(color: Colors.green))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (emoji == null) return setModalState(() => errorEmoji = '⚠️ Elige una emoción');
                    if (titulo.isEmpty || descripcion.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa título y descripción'), behavior: SnackBarBehavior.floating));
                      return;
                    }
                    widget.onAgregarEstado(emoji!, titulo, descripcion, foto: imagen?.path);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: const Text('Guardar registro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void mostrarFormularioEditarEstado(int index) {
    final estado = widget.estados[index];
    String? emoji = estado['emoji'];
    String titulo = estado['titulo'];
    String descripcion = estado['descripcion'];
    File? imagen = estado['foto'] != null && estado['foto'].isNotEmpty ? File(estado['foto']) : null;
    String? errorEmoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Text('✏️ Editar estado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['😊', '😢', '😡', '😐', '😞'].map((e) {
                    final selected = emoji == e;
                    return GestureDetector(
                      onTap: () => setModalState(() { emoji = e; errorEmoji = null; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()..scale(selected ? 1.3 : 1.0),
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? Colors.indigo.shade100 : Colors.grey.shade100),
                          padding: const EdgeInsets.all(12),
                          child: Text(e, style: TextStyle(fontSize: 32, color: selected ? Colors.indigo : Colors.black87)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (errorEmoji != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(errorEmoji!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 24),
                TextField(controller: TextEditingController(text: titulo), decoration: InputDecoration(labelText: 'Título', prefixIcon: const Icon(Icons.title), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), onChanged: (v) => titulo = v),
                const SizedBox(height: 16),
                TextField(controller: TextEditingController(text: descripcion), maxLines: 3, decoration: InputDecoration(labelText: 'Descripción', prefixIcon: const Icon(Icons.edit_note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), onChanged: (v) => descripcion = v),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(imagen == null ? Icons.add_a_photo : Icons.change_circle),
                  label: Text(imagen == null ? 'Agregar foto' : 'Cambiar foto'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () async {
                    final img = await _seleccionarImagen();
                    if (img != null) setModalState(() => imagen = img);
                  },
                ),
                if (imagen != null) const Padding(padding: EdgeInsets.only(top: 8), child: Text('✓ Foto actualizada', style: TextStyle(color: Colors.green))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (emoji == null) return setModalState(() => errorEmoji = 'Selecciona una emoción');
                    if (titulo.isEmpty || descripcion.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa los campos'), behavior: SnackBarBehavior.floating));
                      return;
                    }
                    widget.onEditarEstado(index, emoji!, titulo, descripcion, foto: imagen?.path);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: const Text('Actualizar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void mostrarDialogoNota(int index) {
    final notas = widget.estados[index]['notas'] as List;
    if (notas.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Máximo 5 notas por registro'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
      return;
    }
    String nuevaNota = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('📝 Agregar nota', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: 'Escribe tu reflexión...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          onChanged: (v) => nuevaNota = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              if (nuevaNota.isNotEmpty) widget.onAgregarNota(index, nuevaNota);
              Navigator.pop(context);
            },
            child: const Text('Guardar nota'),
          ),
        ],
      ),
    );
  }

  String _formatTiempo(int segundos) {
    if (segundos <= 0) return '0s';
    int minutos = segundos ~/ 60;
    int segs = segundos % 60;
    return minutos > 0 ? '${minutos}m ${segs}s' : '${segs}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header con saludo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.indigo.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_emotions, color: Colors.indigo, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¡Hola, ${widget.apodo}!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Text('¿Cómo estuvo tu día?', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                    child: const Icon(Icons.mood, color: Colors.indigo),
                  ),
                ],
              ),
            ),
            // Lista de estados
            Expanded(
              child: widget.estados.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No hay registros aún', style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Toca el botón + para añadir tu primer momento', style: TextStyle(color: Colors.grey.shade400)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.estados.length,
                itemBuilder: (context, index) {
                  final estado = widget.estados[index];
                  final restante = estado['segundosRestantes'] as int;
                  final editable = restante > 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shadowColor: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _mostrarDetalle(estado),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                                  child: Center(child: Text(estado['emoji'], style: const TextStyle(fontSize: 32))),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(estado['titulo'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(estado['descripcion'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                if (editable)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(onPressed: () => mostrarFormularioEditarEstado(index), icon: const Icon(Icons.edit, color: Colors.indigo), tooltip: 'Editar'),
                                      IconButton(onPressed: () => widget.onEliminarEstado(index), icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Eliminar'),
                                    ],
                                  )
                                else
                                  IconButton(onPressed: () => mostrarDialogoNota(index), icon: const Icon(Icons.note_add, color: Colors.green), tooltip: 'Agregar nota'),
                              ],
                            ),
                            if (editable) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: restante / (TIEMPO_LIMITE_MINUTOS * 60),
                                backgroundColor: Colors.grey.shade200,
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              const SizedBox(height: 6),
                              Text('⏱️ ${_formatTiempo(restante)} para editar', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                            if (estado['foto'] != null && estado['foto'].isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageWidget(estado['foto'], height: 120),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          onPressed: mostrarFormularioNuevoEstado,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nuevo estado', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }
}