import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:moodlog/database/database_helper.dart';
import 'estadistica/estadistica_page.dart';
import 'perfil/perfil_page.dart';

const int TIEMPO_LIMITE_MINUTOS = 1; // Cambia a 5 para producción

class BienvenidaPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BienvenidaPage({Key? key, required this.userData}) : super(key: key);

  @override
  _BienvenidaPageState createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> estados = [];
  late Map<String, dynamic> _userData;
  late int _userId;
  Timer? _refreshTimer;

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
    _userData = Map<String, dynamic>.from(widget.userData);
    _userId = _userData['id'];
    _cargarEstadosDesdeBD();
    _iniciarTimerRefresco();
  }

  Future<void> _cargarEstadosDesdeBD() async {
    final memories = await DatabaseHelper().getMemoriesByUser(_userId);
    setState(() {
      estados = memories.map((mem) => _memoryToEstado(mem)).toList();
      _actualizarTiempos();
    });
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
      body: IndexedStack(
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: isWide ? BottomNavigationBarType.fixed : BottomNavigationBarType.shifting,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: isWide,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// ================== Widget de la lista de estados ==================
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

class _BienvenidaHomeContentState extends State<BienvenidaHomeContent> {
  final ImagePicker _picker = ImagePicker();

  Future<File?> _seleccionarImagen() async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(context, image != null ? File(image.path) : null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                Navigator.pop(context, image != null ? File(image.path) : null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> estado) {
    final segundosRestantes = estado['segundosRestantes'] as int;
    final puedeEditar = segundosRestantes > 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(estado['emoji'], style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Expanded(child: Text(estado['titulo'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📅 ${estado['fecha'].day}/${estado['fecha'].month}/${estado['fecha'].year} - ${estado['hora']}'),
              const SizedBox(height: 12),
              Text(estado['descripcion'], style: const TextStyle(fontSize: 16)),
              if (estado['foto'] != null && estado['foto'].isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('📷 Foto:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(estado['foto']),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Imagen no disponible', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      frameBuilder: (_, child, frame, __) {
                        if (frame == null) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }
                        return child;
                      },
                    ),
                  ),
                ),
              ],
              if (estado['notas'].isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('📝 Notas:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...estado['notas'].map((nota) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• $nota'),
                )),
              ],
              if (puedeEditar) ...[
                const SizedBox(height: 12),
                Text('⏱️ Tiempo restante: ${_formatTiempo(segundosRestantes)}', style: const TextStyle(color: Colors.blue)),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nuevo Estado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Selecciona una emoción:'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['😊', '😢', '😡', '😐', '😞'].map((e) {
                    final selected = emoji == e;
                    return GestureDetector(
                      onTap: () => setModalState(() { emoji = e; errorEmoji = null; }),
                      child: AnimatedScale(
                        scale: selected ? 1.5 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: selected ? Colors.blue[100] : Colors.grey[200],
                          child: Text(e, style: TextStyle(fontSize: 28, color: selected ? Colors.blue : Colors.black)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (errorEmoji != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorEmoji!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                TextField(decoration: const InputDecoration(labelText: 'Título'), onChanged: (v) => titulo = v),
                const SizedBox(height: 12),
                TextField(decoration: const InputDecoration(labelText: 'Descripción'), onChanged: (v) => descripcion = v),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: Icon(imagen == null ? Icons.add_photo_alternate : Icons.change_circle),
                  label: Text(imagen == null ? 'Agregar foto' : 'Cambiar foto'),
                  onPressed: () async {
                    final img = await _seleccionarImagen();
                    if (img != null) setModalState(() => imagen = img);
                  },
                ),
                if (imagen != null) const Text('✓ Foto seleccionada', style: TextStyle(color: Colors.green)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if (emoji == null) {
                      setModalState(() => errorEmoji = '⚠️ Selecciona una emoción');
                      return;
                    }
                    if (titulo.isEmpty || descripcion.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa título y descripción')));
                      return;
                    }
                    widget.onAgregarEstado(emoji!, titulo, descripcion, foto: imagen?.path);
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Editar Estado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Selecciona una emoción:'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['😊', '😢', '😡', '😐', '😞'].map((e) {
                    final selected = emoji == e;
                    return GestureDetector(
                      onTap: () => setModalState(() { emoji = e; errorEmoji = null; }),
                      child: AnimatedScale(
                        scale: selected ? 1.5 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: selected ? Colors.blue[100] : Colors.grey[200],
                          child: Text(e, style: TextStyle(fontSize: 28, color: selected ? Colors.blue : Colors.black)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (errorEmoji != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorEmoji!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: titulo),
                  decoration: const InputDecoration(labelText: 'Título'),
                  onChanged: (v) => titulo = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: descripcion),
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  onChanged: (v) => descripcion = v,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: Icon(imagen == null ? Icons.add_photo_alternate : Icons.change_circle),
                  label: Text(imagen == null ? 'Agregar foto' : 'Cambiar foto'),
                  onPressed: () async {
                    final img = await _seleccionarImagen();
                    if (img != null) setModalState(() => imagen = img);
                  },
                ),
                if (imagen != null) const Text('✓ Foto seleccionada', style: TextStyle(color: Colors.green)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if (emoji == null) {
                      setModalState(() => errorEmoji = '⚠️ Selecciona una emoción');
                      return;
                    }
                    if (titulo.isEmpty || descripcion.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa título y descripción')));
                      return;
                    }
                    widget.onEditarEstado(index, emoji!, titulo, descripcion, foto: imagen?.path);
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar Cambios'),
                ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Máximo 5 notas por registro'), backgroundColor: Colors.orange));
      return;
    }
    String nuevaNota = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Nota'),
        content: TextField(onChanged: (v) => nuevaNota = v, decoration: const InputDecoration(hintText: 'Escribe tu nota...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nuevaNota.isNotEmpty) widget.onAgregarNota(index, nuevaNota);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String _formatTiempo(int segundos) {
    if (segundos <= 0) return '0 seg';
    int minutos = segundos ~/ 60;
    int segs = segundos % 60;
    return minutos > 0 ? '$minutos min ${segs.toString().padLeft(2, '0')} seg' : '$segs seg';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('¡Hola, ${widget.apodo}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: widget.estados.isEmpty
                ? const Center(child: Text('No hay estados registrados aún'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.estados.length,
              itemBuilder: (context, index) {
                final estado = widget.estados[index];
                final restante = estado['segundosRestantes'] as int;
                final editable = restante > 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => _mostrarDetalle(estado),
                        leading: Text(estado['emoji'], style: const TextStyle(fontSize: 28)),
                        title: Text('${estado['hora']}  ${estado['titulo']}'),
                        subtitle: Text(estado['descripcion']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (editable) IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => mostrarFormularioEditarEstado(index)),
                            if (editable) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => widget.onEliminarEstado(index)),
                            if (!editable) IconButton(icon: const Icon(Icons.note_add, color: Colors.green), onPressed: () => mostrarDialogoNota(index)),
                          ],
                        ),
                      ),
                      if (editable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Tiempo restante: ${_formatTiempo(restante)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 16),
            child: Align(alignment: Alignment.bottomRight, child: FloatingActionButton(child: const Icon(Icons.add), onPressed: mostrarFormularioNuevoEstado)),
          ),
        ],
      ),
    );
  }
}