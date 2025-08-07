import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cite.dart';
import '../models/locataire.dart';
import '../models/releve.dart';
import '../models/configuration.dart';
import '../models/payment_history.dart';
import '../models/unit_type.dart';

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
      version: 5, // Incrémenter la version de la base de données
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        moisReleve TEXT NOT NULL,
        commentaire TEXT,
        isPaid INTEGER NOT NULL DEFAULT 0,
        paymentDate TEXT,
        paidAmount REAL NOT NULL DEFAULT 0.0,
        unitId INTEGER,
        unitType TEXT NOT NULL DEFAULT 'water',
        FOREIGN KEY (locataireId) REFERENCES locataires (id),
        FOREIGN KEY (unitId) REFERENCES consumption_units (id)
      )
    ''');

    // Table de configuration
    await db.execute('''
      CREATE TABLE configuration (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarifBase REAL NOT NULL,
        devise TEXT NOT NULL DEFAULT 'FCFA',
        default_unit_id INTEGER,
        default_unit_type TEXT NOT NULL DEFAULT 'water',
        dateModification TEXT NOT NULL
      )
    ''');

    // Table des unités de consommation
    await db.execute('''
      CREATE TABLE consumption_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        full_name TEXT NOT NULL,
        type TEXT NOT NULL,
        conversion_factor REAL NOT NULL DEFAULT 1.0,
        is_default INTEGER NOT NULL DEFAULT 0,
        date_creation INTEGER NOT NULL
      )
    ''');

    // Insérer une configuration par défaut
    await db.insert('configuration', {
      'tarifBase': 100.0,
      'devise': 'FCFA',
      'default_unit_type': 'water',
      'dateModification': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajouter la colonne moisReleve à la table releves
      await db.execute('ALTER TABLE releves ADD COLUMN moisReleve TEXT');

      // Mettre à jour les relevés existants pour que moisReleve = dateReleve
      await db.execute(
          'UPDATE releves SET moisReleve = dateReleve WHERE moisReleve IS NULL');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE releves ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE releves ADD COLUMN paymentDate TEXT');
    }
    if (oldVersion < 4) {
      await _createNewTables(db);
    }
    if (oldVersion < 5) {
      // Ajouter les colonnes pour les unités
      await db.execute('ALTER TABLE releves ADD COLUMN unitId INTEGER');
      await db.execute(
          'ALTER TABLE releves ADD COLUMN unitType TEXT NOT NULL DEFAULT "water"');
      await db.execute(
          'ALTER TABLE configuration ADD COLUMN default_unit_id INTEGER');
      await db.execute(
          'ALTER TABLE configuration ADD COLUMN default_unit_type TEXT NOT NULL DEFAULT "water"');

      // Créer la table des unités de consommation
      await db.execute('''
        CREATE TABLE consumption_units (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          symbol TEXT NOT NULL,
          full_name TEXT NOT NULL,
          type TEXT NOT NULL,
          conversion_factor REAL NOT NULL DEFAULT 1.0,
          is_default INTEGER NOT NULL DEFAULT 0,
          date_creation INTEGER NOT NULL
        )
      ''');
    }
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
    await db
        .update('cites', cite.toMap(), where: 'id = ?', whereArgs: [cite.id]);
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
    await db.update('locataires', locataire.toMap(),
        where: 'id = ?', whereArgs: [locataire.id]);
  }

  Future<void> deleteLocataire(int id) async {
    final db = await database;
    await db.delete('locataires', where: 'id = ?', whereArgs: [id]);
  }

  Future<Locataire?> getLocataireByNumeroLogementAndCite(
      String numeroLogement, int citeId,
      {int? excludeId}) async {
    final db = await database;
    String whereClause = 'numeroLogement = ? AND citeId = ?';
    List<dynamic> whereArgs = [numeroLogement, citeId];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'locataires',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    return maps.isNotEmpty ? Locataire.fromMap(maps.first) : null;
  }

  // CRUD pour les relevés
  Future<int> insertReleve(Releve releve) async {
    final db = await database;
    return await db.insert('releves', releve.toMap());
  }

  Future<List<Releve>> getReleves() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('releves', orderBy: 'dateReleve DESC');
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  Future<List<Releve>> getRelevesByLocataire(int locataireId,
      {int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('releves',
        where: 'locataireId = ?',
        whereArgs: [locataireId],
        orderBy: 'dateReleve DESC',
        limit: limit);
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
    await db.update('releves', releve.toMap(),
        where: 'id = ?', whereArgs: [releve.id]);
  }

  Future<void> deleteReleve(int id) async {
    final db = await database;
    await db.delete('releves', where: 'id = ?', whereArgs: [id]);
  }

  Future<Releve?> getReleveForLocataireAndMonth(
      int locataireId, int month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'releves',
      where:
          "locataireId = ? AND strftime('%m', moisReleve) = ? AND strftime('%Y', moisReleve) = ?",
      whereArgs: [
        locataireId,
        month.toString().padLeft(2, '0'),
        year.toString()
      ],
      limit: 1,
    );
    return maps.isNotEmpty ? Releve.fromMap(maps.first) : null;
  }

  Future<List<Releve>> getRelevesForMonth(int month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'releves',
      where:
          "strftime('%m', moisReleve) = ? AND strftime('%Y', moisReleve) = ?",
      whereArgs: [month.toString().padLeft(2, '0'), year.toString()],
      orderBy: 'dateReleve DESC',
    );
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  Future<void> updatePaymentStatus(
      int releveId, bool isPaid, DateTime? paymentDate) async {
    final db = await database;
    await db.update(
      'releves',
      {
        'isPaid': isPaid ? 1 : 0,
        'paymentDate': paymentDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [releveId],
    );
  }

  // Configuration
  Future<Configuration> getConfiguration() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('configuration', limit: 1);
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
    await db.update('configuration', config.toMap(),
        where: 'id = ?', whereArgs: [config.id]);
  }

  // Nouvelles méthodes pour les fonctionnalités avancées

  // Méthodes pour l'historique des paiements
  Future<int> insertPaymentHistory(PaymentHistory payment) async {
    final db = await database;
    return await db.insert('payment_history', payment.toMap());
  }

  Future<List<PaymentHistory>> getPaymentHistory(int releveId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_history',
      where: 'releve_id = ?',
      whereArgs: [releveId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) => PaymentHistory.fromMap(maps[i]));
  }

  // Méthodes pour les relevés en retard
  Future<List<Releve>> getOverdueReleves() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final List<Map<String, dynamic>> maps = await db.query(
      'releves',
      where: 'isPaid = 0 AND moisReleve < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
      orderBy: 'moisReleve ASC',
    );
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  // Méthodes pour les analyses
  Future<List<Releve>> getRelevesInPeriod(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'releves',
      where: 'dateReleve >= ? AND dateReleve <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'dateReleve DESC',
    );
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  Future<Releve?> getReleveById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'releves',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Releve.fromMap(maps.first) : null;
  }

  Future<Locataire?> getLocataireById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locataires',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Locataire.fromMap(maps.first) : null;
  }

  Future<Cite?> getCiteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cites',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Cite.fromMap(maps.first) : null;
  }

  // Méthodes pour les paiements partiels
  Future<void> updatePaymentAmount(int releveId, double paidAmount,
      bool isFullyPaid, DateTime? paymentDate) async {
    final db = await database;
    await db.update(
      'releves',
      {
        'paidAmount': paidAmount,
        'isPaid': isFullyPaid ? 1 : 0,
        'paymentDate': paymentDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [releveId],
    );
  }

  // Méthodes pour les notifications
  Future<int> insertNotification({
    required int locataireId,
    required String type,
    required String message,
    required DateTime sentAt,
  }) async {
    final db = await database;
    return await db.insert('notifications', {
      'locataire_id': locataireId,
      'type': type,
      'message': message,
      'sent_at': sentAt.toIso8601String(),
    });
  }

  // Méthode pour créer les nouvelles tables lors de la mise à jour
  Future<void> _createNewTables(Database db) async {
    // Table pour l'historique des paiements
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        releve_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (releve_id) REFERENCES releves (id)
      )
    ''');

    // Table pour les notifications
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        locataire_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        sent_at TEXT NOT NULL,
        FOREIGN KEY (locataire_id) REFERENCES locataires (id)
      )
    ''');

    // Ajouter la colonne paidAmount à la table releves si elle n'existe pas
    try {
      await db
          .execute('ALTER TABLE releves ADD COLUMN paidAmount REAL DEFAULT 0');
    } catch (e) {
      // La colonne existe déjà
    }
  }

  // CRUD pour les unités de consommation
  Future<ConsumptionUnit> insertConsumptionUnit(ConsumptionUnit unit) async {
    final db = await database;
    final id = await db.insert('consumption_units', unit.toMap());
    return unit.copyWith(id: id);
  }

  Future<List<ConsumptionUnit>> getConsumptionUnits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumption_units',
      orderBy: 'type, name',
    );
    return List.generate(maps.length, (i) => ConsumptionUnit.fromMap(maps[i]));
  }

  Future<List<ConsumptionUnit>> getConsumptionUnitsByType(UnitType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumption_units',
      where: 'type = ?',
      whereArgs: [type.id],
      orderBy: 'name',
    );
    return List.generate(maps.length, (i) => ConsumptionUnit.fromMap(maps[i]));
  }

  Future<ConsumptionUnit?> getConsumptionUnitById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumption_units',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? ConsumptionUnit.fromMap(maps.first) : null;
  }

  Future<void> updateConsumptionUnit(ConsumptionUnit unit) async {
    final db = await database;
    await db.update(
      'consumption_units',
      unit.toMap(),
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  Future<void> deleteConsumptionUnit(int id) async {
    final db = await database;
    await db.delete('consumption_units', where: 'id = ?', whereArgs: [id]);
  }

  Future<ConsumptionUnit?> getDefaultUnitForType(UnitType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumption_units',
      where: 'type = ? AND is_default = 1',
      whereArgs: [type.id],
      limit: 1,
    );
    return maps.isNotEmpty ? ConsumptionUnit.fromMap(maps.first) : null;
  }

  // Méthodes pour les statistiques d'utilisation des unités
  Future<int> getRelevesCountByUnitType(UnitType type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM releves WHERE unitType = ?',
      [type.id],
    );
    return result.first['count'] as int;
  }

  Future<int> getRelevesCountByUnitId(int unitId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM releves WHERE unitId = ?',
      [unitId],
    );
    return result.first['count'] as int;
  }

  // Méthodes pour la recherche d'unités
  Future<List<ConsumptionUnit>> searchConsumptionUnits(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumption_units',
      where: 'name LIKE ? OR symbol LIKE ? OR full_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'type, name',
    );
    return List.generate(maps.length, (i) => ConsumptionUnit.fromMap(maps[i]));
  }
}
