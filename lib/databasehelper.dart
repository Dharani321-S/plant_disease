import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // This is the 'instance' getter your error message is looking for
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('plant_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, 
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE settings (id INTEGER PRIMARY KEY, pin TEXT)');
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT,
        diseaseName TEXT,
        treatment TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE garden (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT, 
        imagePath TEXT, 
        disease TEXT
      )
    ''');
  }

  // --- History Methods ---
  Future<int> insertHistory(String imagePath, String diseaseName, String treatment) async {
    final db = await instance.database;
    return await db.insert('history', {
      'imagePath': imagePath,
      'diseaseName': diseaseName,
      'treatment': treatment,
    });
  }

  Future<List<Map<String, dynamic>>> queryAllHistory() async {
    final db = await instance.database;
    return await db.query('history', orderBy: 'id DESC');
  }

  // --- Garden Methods ---
  Future<int> addToGarden(String name, String imagePath, String disease) async {
    final db = await instance.database;
    return await db.insert('garden', {'name': name, 'imagePath': imagePath, 'disease': disease});
  }

  Future<List<Map<String, dynamic>>> fetchGarden() async {
    final db = await instance.database;
    return await db.query('garden', orderBy: 'id DESC');
  }

  // This fixes the 'deleteFromGarden' error in your garden_page.dart
  Future<int> deleteFromGarden(int id) async {
    final db = await instance.database;
    return await db.delete('garden', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteHistory(int id) async {
    final db = await instance.database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}