// lib/bienvenida_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'estadistica/estadistica_page.dart';
import 'perfil/perfil_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bienestar App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
        fontFamily: 'Poppins',
      ),
      home: const BienvenidaPage(userData: {'apodo': 'Usuario'}),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BienvenidaPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BienvenidaPage({Key? key, required this.userData}) : super(key: key);
  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  List<Map<String, dynamic>> estados = [];
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
    _buildPages();
  }

  void _buildPages() {
    _pages = [
      BienvenidaHomeContent(
        apodo: _userData['apodo'] ?? 'Usuario',
        estados: estados,
        onAgregarEstado: (nuevo) {
          setState(() {
            estados.add(nuevo);
            _buildPages();
          });
        },
        onEliminarEstado: (index) {
          setState(() {
            estados.removeAt(index);
            _buildPages();
          });
        },
      ),
      EstadisticaPage(estados: estados),
      PerfilPage(
        datosUsuario: _userData,
        onActualizarDatos: (nuevosDatos) {
          setState(() {
            _userData = nuevosDatos;
            _buildPages();
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: isWide ? BottomNavigationBarType.fixed : BottomNavigationBarType.shifting,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: isWide,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}


// Página Home
class BienvenidaHomeContent extends StatefulWidget {
  final String apodo;
  final List<Map<String, dynamic>> estados;
  final Function(Map<String, dynamic>) onAgregarEstado;
  final Function(int) onEliminarEstado;

  const BienvenidaHomeContent({
    Key? key,
    required this.apodo,
    required this.estados,
    required this.onAgregarEstado,
    required this.onEliminarEstado,
  }) : super(key: key);

  @override
  State<BienvenidaHomeContent> createState() => _BienvenidaHomeContentState();
}

class _BienvenidaHomeContentState extends State<BienvenidaHomeContent> {
  void agregarEstado(String emoji, String titulo, String descripcion, {String? foto}) {
    final ahora = DateTime.now();
    final horaFormateada = "${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}";
    final nuevoEstado = {
      'fecha': ahora,
      'hora': horaFormateada,
      'emoji': emoji,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto': foto ?? '',
      'notas': <String>[],
      'tiempoRestante': 5,
      'timer': null,
    };
    final timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      final index = widget.estados.indexOf(nuevoEstado);
      if (index != -1) {
        setState(() {
          if (widget.estados[index]['tiempoRestante'] > 0) {
            widget.estados[index]['tiempoRestante']--;
          } else {
            timer.cancel();
          }
        });
      }
    });
    nuevoEstado['timer'] = timer;
    widget.onAgregarEstado(nuevoEstado);
  }

  void eliminarEstado(int index) {
    final estado = widget.estados[index];
    final t = estado['timer'];
    if (t is Timer) t.cancel();
    widget.onEliminarEstado(index);
  }

  void agregarNota(int index) {
    showDialog(
      context: context,
      builder: (context) {
        String nuevaNota = '';
        return AlertDialog(
          title: const Text('Agregar Nota', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Escribe tu reflexión...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) => nuevaNota = value,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() { widget.estados[index]['notas'].add(nuevaNota); });
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void mostrarFormularioNuevoEstado() {
    String? emojiSeleccionado;
    String titulo = '';
    String descripcion = '';
    String? fotoSeleccionada;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nuevo Estado de Ánimo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 12),
                    const Text('¿Cómo te sientes?', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['😊', '😢', '😡', '😐', '😞'].map((emoji) {
                        final isSelected = emojiSeleccionado == emoji;
                        return GestureDetector(
                          onTap: () => setModalState(() => emojiSeleccionado = emoji),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.identity()..scale(isSelected ? 1.3 : 1.0),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.grey.shade200,
                              child: Text(emoji, style: TextStyle(fontSize: 34, color: isSelected ? Colors.indigo : Colors.black87)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ej. Feliz, Motivado, ...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.title),
                      ),
                      onChanged: (v) => titulo = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '¿Qué hiciste hoy?',
                        hintText: 'Describe tu día...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.edit_note),
                      ),
                      onChanged: (v) => descripcion = v,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Agregar imagen (opcional)', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Seleccionar foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => setModalState(() => fotoSeleccionada = 'foto_demo.png'),
                    ),
                    if (fotoSeleccionada != null) ...[
                      const SizedBox(height: 8),
                      Text('✓ Foto seleccionada', style: TextStyle(color: Colors.green.shade700)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        if (emojiSeleccionado != null && titulo.isNotEmpty && descripcion.isNotEmpty) {
                          agregarEstado(emojiSeleccionado!, titulo, descripcion, foto: fotoSeleccionada);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Completa los campos obligatorios')),
                          );
                        }
                      },
                      child: const Text('Guardar registro', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    for (var e in widget.estados) {
      final t = e['timer'];
      if (t is Timer) t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                const Icon(Icons.emoji_emotions, size: 32, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Hola, ${widget.apodo}!',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.estados.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No hay estados registrados aún', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Toca el botón + para agregar tu día', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.estados.length,
              itemBuilder: (context, index) {
                final estado = widget.estados[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(estado['emoji'], style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${estado['hora']}  •  ${estado['titulo']}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(estado['descripcion'], style: TextStyle(color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                              if (estado['tiempoRestante'] > 0)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {},
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => eliminarEstado(index),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.note_add, color: Colors.green),
                                  onPressed: () => agregarNota(index),
                                  tooltip: 'Añadir nota',
                                ),
                            ],
                          ),
                          if (estado['foto'] != null && estado['foto'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(image: NetworkImage('https://picsum.photos/200/150'), fit: BoxFit.cover),
                                ),
                                height: 120,
                                width: double.infinity,
                              ),
                            ),
                          if (estado['notas'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Notas:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...estado['notas'].map<Widget>((n) => Padding(
                                    padding: const EdgeInsets.only(left: 8, top: 4),
                                    child: Row(
                                      children: [const Icon(Icons.circle, size: 6), const SizedBox(width: 8), Expanded(child: Text(n))],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          if (estado['tiempoRestante'] > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(
                                value: estado['tiempoRestante'] / 5,
                                backgroundColor: Colors.grey.shade200,
                                color: Colors.indigo,
                              ),
                            ),
                          if (estado['tiempoRestante'] > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Bloqueo de Eliminación en ${estado['tiempoRestante']} min',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, right: 16),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                elevation: 6,
                backgroundColor: Colors.indigo,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: mostrarFormularioNuevoEstado,
                tooltip: 'Agregar estado',
              ),
            ),
          ),
        ],
      ),
    );
  }
}