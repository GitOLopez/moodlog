import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'moodlog.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        apellido TEXT NOT NULL,
        apodo TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        edad INTEGER NOT NULL,
        sexo TEXT NOT NULL,
        nombreContacto TEXT,
        contactoEmergencia INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        emoji TEXT NOT NULL,
        titulo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        foto_path TEXT,
        notas_json TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pais TEXT NOT NULL,
        numero TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_memories_user_id ON memories(user_id)');
    await db.execute('CREATE INDEX idx_memories_created_at ON memories(created_at)');
  }

  // ---------------- USERS ----------------
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    user['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByApodo(String apodo) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'apodo = ?',
      whereArgs: [apodo],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [user['id']]);
  }

  // ---------------- MEMORIES ----------------
  Future<int> insertMemory(Map<String, dynamic> memory) async {
    final db = await database;
    memory['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('memories', memory);
  }

  Future<List<Map<String, dynamic>>> getMemoriesByUser(int userId) async {
    final db = await database;
    return await db.query(
      'memories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteMemory(int memoryId) async {
    final db = await database;
    return await db.delete('memories', where: 'id = ?', whereArgs: [memoryId]);
  }

  Future<int> updateMemory(Map<String, dynamic> memory) async {
    final db = await database;
    memory['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('memories', memory, where: 'id = ?', whereArgs: [memory['id']]);
  }
}