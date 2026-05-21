// lib/bienvenida_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'estadistica/estadistica_page.dart';
import 'perfil/perfil_page.dart';

class BienvenidaPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BienvenidaPage({Key? key, required this.userData}) : super(key: key);

  @override
  _BienvenidaPageState createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  int _currentIndex = 0;
  // ✅ Se quitó 'final' para permitir reasignaciones
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
      // Pestaña 0: Home
      BienvenidaHomeContent(
        apodo: _userData['apodo'] ?? 'Usuario',
        estados: estados,
        onAgregarEstado: (nuevo) {
          setState(() {
            estados.add(nuevo);
            _buildPages(); // Reconstruye para reflejar el nuevo estado
          });
        },
        onEliminarEstado: (index) {
          setState(() {
            estados.removeAt(index);
            _buildPages();
          });
        },
      ),
      // Pestaña 1: Estadísticas
      EstadisticaPage(estados: estados),
      // Pestaña 2: Perfil
      PerfilPage(
        datosUsuario: _userData,
        onActualizarDatos: (nuevosDatos) {
          setState(() {
            _userData = nuevosDatos;
            _buildPages(); // Refresca el perfil y el apodo en la Home
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: isWide ? BottomNavigationBarType.fixed : BottomNavigationBarType.shifting,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: isWide,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// --- BienvenidaHomeContent sin cambios (se mantiene igual) ---
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
  _BienvenidaHomeContentState createState() => _BienvenidaHomeContentState();
}

class _BienvenidaHomeContentState extends State<BienvenidaHomeContent> {
  void agregarEstado(String emoji, String titulo, String descripcion, {String? foto}) {
    final horaActual = TimeOfDay.now();
    final horaFormateada =
        "${horaActual.hour}:${horaActual.minute.toString().padLeft(2, '0')}";

    final nuevoEstado = {
      'fecha': DateTime.now(),
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
      if (!mounted) {
        timer.cancel();
        return;
      }
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
          title: const Text('Agregar Nota'),
          content: TextField(
            onChanged: (value) => nuevaNota = value,
            decoration: const InputDecoration(hintText: 'Escribe tu nota...'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                setState(() {
                  widget.estados[index]['notas'].add(nuevaNota);
                });
                Navigator.pop(context);
              },
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nuevo Estado de Ánimo',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('¿Cómo te sientes?'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['😊', '😢', '😡', '😐', '😞'].map((emoji) {
                        final isSelected = emojiSeleccionado == emoji;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              emojiSeleccionado = emoji;
                            });
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 1.5 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor:
                              isSelected ? Colors.blue[100] : Colors.grey[200],
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: 28,
                                  color: isSelected ? Colors.blue : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Título (ej. Feliz, Triste, etc.)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => titulo = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '¿Qué hiciste hoy? Describe tu día...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => descripcion = value,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Agregar fotos (Opcional)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text('Subir Foto'),
                      onPressed: () {
                        setModalState(() {
                          fotoSeleccionada = 'foto_demo.png';
                        });
                      },
                    ),
                    if (fotoSeleccionada != null)
                      Text('Foto seleccionada: $fotoSeleccionada',
                          style: const TextStyle(color: Colors.green)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      child: const Text('Guardar'),
                      onPressed: () {
                        if (emojiSeleccionado != null &&
                            titulo.isNotEmpty &&
                            descripcion.isNotEmpty) {
                          agregarEstado(
                              emojiSeleccionado!, titulo, descripcion,
                              foto: fotoSeleccionada);
                          Navigator.pop(context);
                        }
                      },
                    ),
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
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '¡Hola, ${widget.apodo}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: widget.estados.isEmpty
                ? const Center(child: Text('No hay estados registrados aún'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.estados.length,
              itemBuilder: (context, index) {
                final estado = widget.estados[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Text(estado['emoji'],
                            style: const TextStyle(fontSize: 28)),
                        title: Text(
                            '${estado['hora']}  ${estado['titulo']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(estado['descripcion']),
                            if (estado['foto'] != null &&
                                estado['foto'].isNotEmpty)
                              Text('Foto adjunta',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600])),
                            if (estado['notas'].isNotEmpty)
                              ...estado['notas']
                                  .map<Widget>((nota) => Text("- $nota"))
                                  .toList(),
                          ],
                        ),
                        trailing: estado['tiempoRestante'] > 0
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue),
                              onPressed: () {
                                // Editar (por implementar)
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  eliminarEstado(index),
                            ),
                          ],
                        )
                            : IconButton(
                          icon: const Icon(Icons.note_add,
                              color: Colors.green),
                          onPressed: () => agregarNota(index),
                        ),
                      ),
                      if (estado['tiempoRestante'] > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Tiempo restante para eliminar: ${estado['tiempoRestante']} min',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, right: 16.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: mostrarFormularioNuevoEstado,
              ),
            ),
          ),
        ],
      ),
    );
  }
}