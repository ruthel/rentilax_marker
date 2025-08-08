import '../models/unit_tarif.dart';
import '../models/unit_type.dart';
import 'database_service.dart';

class TarifService {
  static final TarifService _instance = TarifService._internal();
  factory TarifService() => _instance;
  TarifService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Cache des tarifs
  Map<int, UnitTarif>? _cachedTarifs;

  /// Récupère tous les tarifs actifs
  Future<List<UnitTarif>> getAllTarifs() async {
    if (_cachedTarifs != null) {
      return _cachedTarifs!.values.toList();
    }

    try {
      final tarifs = await _databaseService.getUnitTarifs();
      _cachedTarifs = {for (var tarif in tarifs) tarif.unitId: tarif};
      return tarifs;
    } catch (e) {
      return [];
    }
  }

  /// Récupère le tarif actif pour une unité spécifique
  Future<UnitTarif?> getTarifForUnit(int unitId) async {
    if (_cachedTarifs != null && _cachedTarifs!.containsKey(unitId)) {
      return _cachedTarifs![unitId];
    }

    try {
      final tarif = await _databaseService.getUnitTarifByUnitId(unitId);
      if (tarif != null) {
        _cachedTarifs ??= {};
        _cachedTarifs![unitId] = tarif;
      }
      return tarif;
    } catch (e) {
      return null;
    }
  }

  /// Récupère le tarif effectif pour une unité (spécifique ou par défaut)
  Future<double> getEffectiveTarifForUnit(int unitId) async {
    final specificTarif = await getTarifForUnit(unitId);
    if (specificTarif != null) {
      return specificTarif.tarif;
    }
    
    // Retourner le tarif de base de la configuration
    final config = await _databaseService.getConfiguration();
    return config.tarifBase;
  }

  /// Ajoute un nouveau tarif pour une unité
  Future<UnitTarif> addTarif(UnitTarif tarif) async {
    // Désactiver l'ancien tarif s'il existe
    final existingTarif = await getTarifForUnit(tarif.unitId);
    if (existingTarif != null) {
      await _databaseService.deactivateUnitTarif(existingTarif.id!);
    }

    final newTarif = await _databaseService.insertUnitTarif(tarif);
    _invalidateCache();
    return newTarif;
  }

  /// Met à jour un tarif existant
  Future<void> updateTarif(UnitTarif tarif) async {
    await _databaseService.updateUnitTarif(tarif);
    _invalidateCache();
  }

  /// Supprime un tarif
  Future<void> deleteTarif(int tarifId) async {
    await _databaseService.deleteUnitTarif(tarifId);
    _invalidateCache();
  }

  /// Désactive un tarif (le rend inactif)
  Future<void> deactivateTarif(int tarifId) async {
    await _databaseService.deactivateUnitTarif(tarifId);
    _invalidateCache();
  }

  /// Récupère l'historique des tarifs pour une unité
  Future<List<UnitTarif>> getTarifHistoryForUnit(int unitId) async {
    try {
      return await _databaseService.getUnitTarifsByUnitId(unitId);
    } catch (e) {
      return [];
    }
  }

  /// Récupère les tarifs par type d'unité
  Future<Map<UnitType, List<UnitTarif>>> getTarifsByType() async {
    final allTarifs = await getAllTarifs();
    final tarifsByType = <UnitType, List<UnitTarif>>{};

    for (final tarif in allTarifs) {
      // Récupérer l'unité pour déterminer son type
      final unit = await _databaseService.getConsumptionUnitById(tarif.unitId);
      if (unit != null) {
        tarifsByType.putIfAbsent(unit.type, () => []).add(tarif);
      }
    }

    return tarifsByType;
  }

  /// Formate un tarif avec sa devise
  String formatTarif(double tarif, String devise) {
    return '${tarif.toStringAsFixed(2)} $devise';
  }

  /// Vérifie si une unité a un tarif personnalisé
  Future<bool> hasCustomTarif(int unitId) async {
    final tarif = await getTarifForUnit(unitId);
    return tarif != null;
  }

  /// Invalide le cache des tarifs
  void _invalidateCache() {
    _cachedTarifs = null;
  }

  /// Récupère les statistiques des tarifs
  Future<Map<String, dynamic>> getTarifStats() async {
    final allTarifs = await getAllTarifs();
    final config = await _databaseService.getConfiguration();
    
    if (allTarifs.isEmpty) {
      return {
        'totalUnitsWithCustomTarifs': 0,
        'averageTarif': config.tarifBase,
        'minTarif': config.tarifBase,
        'maxTarif': config.tarifBase,
        'defaultTarif': config.tarifBase,
      };
    }

    final tarifs = allTarifs.map((t) => t.tarif).toList();
    final total = tarifs.fold(0.0, (sum, tarif) => sum + tarif);
    final average = total / tarifs.length;
    final minTarif = tarifs.reduce((a, b) => a < b ? a : b);
    final maxTarif = tarifs.reduce((a, b) => a > b ? a : b);

    return {
      'totalUnitsWithCustomTarifs': allTarifs.length,
      'averageTarif': average,
      'minTarif': minTarif,
      'maxTarif': maxTarif,
      'defaultTarif': config.tarifBase,
    };
  }
}
