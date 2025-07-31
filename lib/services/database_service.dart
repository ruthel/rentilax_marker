import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cite.dart';
import '../models/locataire.dart';
import '../models/releve.dart';
import '../models/configuration.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'rentilax_marker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table des cités
    await db.execute('''
      CREATE TABLE cites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        adresse TEXT,
        dateCreation TEXT NOT NULL
      )
    ''');

    // Table des locataires
    await db.execute('''
      CREATE TABLE locataires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        telephone TEXT,
        email TEXT,
        citeId INTEGER NOT NULL,
        numeroLogement TEXT NOT NULL,
        tarifPersonnalise REAL,
        dateEntree TEXT NOT NULL,
        FOREIGN KEY (citeId) REFERENCES cites (id)
      )
    ''');

    // Table des relevés
    await db.execute('''
      CREATE TABLE releves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        locataireId INTEGER NOT NULL,
        ancienIndex REAL NOT NULL,
        nouvelIndex REAL NOT NULL,
        consommation REAL NOT NULL,
        tarif REAL NOT NULL,
        montant REAL NOT NULL,
        dateReleve TEXT NOT NULL,
        commentaire TEXT,
        FOREIGN KEY (locataireId) REFERENCES locataires (id)
      )
    ''');

    // Table de configuration
    await db.execute('''
      CREATE TABLE configuration (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarifBase REAL NOT NULL,
        devise TEXT NOT NULL DEFAULT 'FCFA',
        dateModification TEXT NOT NULL
      )
    ''');

    // Insérer une configuration par défaut
    await db.insert('configuration', {
      'tarifBase': 100.0,
      'devise': 'FCFA',
      'dateModification': DateTime.now().toIso8601String(),
    });
  }

  // CRUD pour les cités
  Future<int> insertCite(Cite cite) async {
    final db = await database;
    return await db.insert('cites', cite.toMap());
  }

  Future<List<Cite>> getCites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cites');
    return List.generate(maps.length, (i) => Cite.fromMap(maps[i]));
  }

  Future<void> updateCite(Cite cite) async {
    final db = await database;
    await db.update('cites', cite.toMap(), where: 'id = ?', whereArgs: [cite.id]);
  }

  Future<void> deleteCite(int id) async {
    final db = await database;
    await db.delete('cites', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD pour les locataires
  Future<int> insertLocataire(Locataire locataire) async {
    final db = await database;
    return await db.insert('locataires', locataire.toMap());
  }

  Future<List<Locataire>> getLocataires() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('locataires');
    return List.generate(maps.length, (i) => Locataire.fromMap(maps[i]));
  }

  Future<List<Locataire>> getLocatairesByCite(int citeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = 
        await db.query('locataires', where: 'citeId = ?', whereArgs: [citeId]);
    return List.generate(maps.length, (i) => Locataire.fromMap(maps[i]));
  }

  Future<void> updateLocataire(Locataire locataire) async {
    final db = await database;
    await db.update('locataires', locataire.toMap(), where: 'id = ?', whereArgs: [locataire.id]);
  }

  Future<void> deleteLocataire(int id) async {
    final db = await database;
    await db.delete('locataires', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD pour les relevés
  Future<int> insertReleve(Releve releve) async {
    final db = await database;
    return await db.insert('releves', releve.toMap());
  }

  Future<List<Releve>> getReleves() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('releves', orderBy: 'dateReleve DESC');
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  Future<List<Releve>> getRelevesByLocataire(int locataireId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = 
        await db.query('releves', where: 'locataireId = ?', whereArgs: [locataireId], orderBy: 'dateReleve DESC');
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  Future<Releve?> getDernierReleve(int locataireId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'releves',
      where: 'locataireId = ?',
      whereArgs: [locataireId],
      orderBy: 'dateReleve DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? Releve.fromMap(maps.first) : null;
  }

  Future<void> updateReleve(Releve releve) async {
    final db = await database;
    await db.update('releves', releve.toMap(), where: 'id = ?', whereArgs: [releve.id]);
  }

  Future<void> deleteReleve(int id) async {
    final db = await database;
    await db.delete('releves', where: 'id = ?', whereArgs: [id]);
  }

  Future<Releve?> getReleveForLocataireAndMonth(int locataireId, int month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'releves',
      where: "locataireId = ? AND strftime('%m', dateReleve) = ? AND strftime('%Y', dateReleve) = ?",
      whereArgs: [locataireId, month.toString().padLeft(2, '0'), year.toString()],
      limit: 1,
    );
    return maps.isNotEmpty ? Releve.fromMap(maps.first) : null;
  }

  Future<List<Releve>> getRelevesForMonth(int month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'releves',
      where: "strftime('%m', dateReleve) = ? AND strftime('%Y', dateReleve) = ?",
      whereArgs: [month.toString().padLeft(2, '0'), year.toString()],
      orderBy: 'dateReleve DESC',
    );
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  // Configuration
  Future<Configuration> getConfiguration() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('configuration', limit: 1);
    if (maps.isNotEmpty) {
      return Configuration.fromMap(maps.first);
    }
    // Si pas de configuration, créer une par défaut
    final config = Configuration(
      tarifBase: 100.0,
      dateModification: DateTime.now(),
    );
    await db.insert('configuration', config.toMap());
    return config;
  }

  Future<void> updateConfiguration(Configuration config) async {
    final db = await database;
    await db.update('configuration', config.toMap(), where: 'id = ?', whereArgs: [config.id]);
  }
}