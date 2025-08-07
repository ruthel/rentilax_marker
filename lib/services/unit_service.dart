import '../models/unit_type.dart';
import 'database_service.dart';

class UnitService {
  static final UnitService _instance = UnitService._internal();
  factory UnitService() => _instance;
  UnitService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Cache des unités
  List<ConsumptionUnit>? _cachedUnits;

  /// Récupère toutes les unités disponibles
  Future<List<ConsumptionUnit>> getAllUnits() async {
    if (_cachedUnits != null) {
      return _cachedUnits!;
    }

    try {
      _cachedUnits = await _databaseService.getConsumptionUnits();

      // Si aucune unité n'existe, initialiser avec les unités par défaut
      if (_cachedUnits!.isEmpty) {
        await _initializeDefaultUnits();
        _cachedUnits = await _databaseService.getConsumptionUnits();
      }

      return _cachedUnits!;
    } catch (e) {
      // En cas d'erreur, retourner les unités par défaut
      return ConsumptionUnit.defaultUnits;
    }
  }

  /// Récupère les unités par type
  Future<List<ConsumptionUnit>> getUnitsByType(UnitType type) async {
    final allUnits = await getAllUnits();
    return allUnits.where((unit) => unit.type == type).toList();
  }

  /// Récupère l'unité par défaut pour un type donné
  Future<ConsumptionUnit?> getDefaultUnitForType(UnitType type) async {
    final units = await getUnitsByType(type);
    return units.where((unit) => unit.isDefault).firstOrNull ??
        units.firstOrNull;
  }

  /// Récupère une unité par son ID
  Future<ConsumptionUnit?> getUnitById(int id) async {
    final allUnits = await getAllUnits();
    return allUnits.where((unit) => unit.id == id).firstOrNull;
  }

  /// Ajoute une nouvelle unité
  Future<ConsumptionUnit> addUnit(ConsumptionUnit unit) async {
    final newUnit = await _databaseService.insertConsumptionUnit(unit);
    _invalidateCache();
    return newUnit;
  }

  /// Met à jour une unité existante
  Future<void> updateUnit(ConsumptionUnit unit) async {
    await _databaseService.updateConsumptionUnit(unit);
    _invalidateCache();
  }

  /// Supprime une unité
  Future<void> deleteUnit(int id) async {
    await _databaseService.deleteConsumptionUnit(id);
    _invalidateCache();
  }

  /// Définit une unité comme unité par défaut pour son type
  Future<void> setAsDefault(int unitId) async {
    final unit = await getUnitById(unitId);
    if (unit == null) return;

    // Retirer le statut par défaut des autres unités du même type
    final sameTypeUnits = await getUnitsByType(unit.type);
    for (final otherUnit in sameTypeUnits) {
      if (otherUnit.id != unitId && otherUnit.isDefault) {
        await updateUnit(otherUnit.copyWith(isDefault: false));
      }
    }

    // Définir cette unité comme par défaut
    await updateUnit(unit.copyWith(isDefault: true));
  }

  /// Convertit une valeur d'une unité vers une autre
  double convertValue(
    double value,
    ConsumptionUnit fromUnit,
    ConsumptionUnit toUnit,
  ) {
    if (fromUnit.type != toUnit.type) {
      throw ArgumentError('Cannot convert between different unit types');
    }

    // Convertir vers l'unité de base, puis vers l'unité cible
    final baseValue = value * fromUnit.conversionFactor;
    return baseValue / toUnit.conversionFactor;
  }

  /// Formate une valeur avec son unité
  String formatValue(double value, ConsumptionUnit unit, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)} ${unit.symbol}';
  }

  /// Récupère le symbole d'unité approprié selon le contexte
  String getUnitSymbol(UnitType type, {ConsumptionUnit? specificUnit}) {
    if (specificUnit != null) {
      return specificUnit.symbol;
    }

    switch (type) {
      case UnitType.water:
        return 'm³';
      case UnitType.electricity:
        return 'kWh';
      case UnitType.gas:
        return 'm³';
    }
  }

  /// Initialise les unités par défaut dans la base de données
  Future<void> _initializeDefaultUnits() async {
    for (final unit in ConsumptionUnit.defaultUnits) {
      await _databaseService.insertConsumptionUnit(unit);
    }
  }

  /// Invalide le cache des unités
  void _invalidateCache() {
    _cachedUnits = null;
  }

  /// Récupère les statistiques d'utilisation des unités
  Future<Map<UnitType, int>> getUnitUsageStats() async {
    final stats = <UnitType, int>{};

    for (final type in UnitType.values) {
      final count = await _databaseService.getRelevesCountByUnitType(type);
      stats[type] = count;
    }

    return stats;
  }

  /// Vérifie si une unité peut être supprimée (pas utilisée dans des relevés)
  Future<bool> canDeleteUnit(int unitId) async {
    final usageCount = await _databaseService.getRelevesCountByUnitId(unitId);
    return usageCount == 0;
  }

  /// Récupère les unités les plus utilisées
  Future<List<ConsumptionUnit>> getMostUsedUnits({int limit = 5}) async {
    final allUnits = await getAllUnits();
    final usageCounts = <int, int>{};

    for (final unit in allUnits) {
      if (unit.id != null) {
        usageCounts[unit.id!] =
            await _databaseService.getRelevesCountByUnitId(unit.id!);
      }
    }

    // Trier par utilisation décroissante
    allUnits.sort((a, b) {
      final countA = usageCounts[a.id] ?? 0;
      final countB = usageCounts[b.id] ?? 0;
      return countB.compareTo(countA);
    });

    return allUnits.take(limit).toList();
  }
}
