import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/section_title.dart';

class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final BackupService _backupService = BackupService();
  final ExportService _exportService = ExportService();
  final ImportService _importService = ImportService();

  List<BackupInfo> _backups = [];
  List<ExportInfo> _exports = [];
  bool _isLoading = false;
  bool _autoBackupEnabled = false;
  AutoBackupFrequency _backupFrequency = AutoBackupFrequency.daily;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final backups = await _backupService.getAvailableBackups();
      final exports = await _exportService.getAvailableExports();

      setState(() {
        _backups = backups;
        _exports = exports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Backup & Synchronisation',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.backup), text: 'Backup'),
            Tab(icon: Icon(Icons.file_download), text: 'Export'),
            Tab(icon: Icon(Icons.file_upload), text: 'Import'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBackupTab(),
                _buildExportTab(),
                _buildImportTab(),
              ],
            ),
    );
  }

  Widget _buildBackupTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Actions rapides
            SectionTitle(text: 'Actions Rapides'),
            const SizedBox(height: 24),

            // Paramètres de backup automatique
            SectionTitle(text: 'Backup Automatique'),
            const SizedBox(height: 24),

            // Liste des backups
            SectionTitle(text: 'Backups Disponibles'),
            _buildBackupsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions Rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.backup,
                    label: 'Backup Complet',
                    color: Colors.blue,
                    onPressed: _createFullBackup,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.update,
                    label: 'Backup Incrémental',
                    color: Colors.green,
                    onPressed: _createIncrementalBackup,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.restore,
                    label: 'Restaurer',
                    color: Colors.orange,
                    onPressed: _showRestoreDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.cloud_sync,
                    label: 'Sync Cloud',
                    color: Colors.purple,
                    onPressed: _syncToCloud,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildAutoBackupSettings() {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Automatique',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activer le backup automatique'),
              subtitle: const Text(
                  'Sauvegarde automatique selon la fréquence choisie'),
              value: _autoBackupEnabled,
              onChanged: (value) {
                setState(() => _autoBackupEnabled = value);
                _configureAutoBackup();
              },
            ),
            if (_autoBackupEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Fréquence'),
                subtitle: Text(_getFrequencyText(_backupFrequency)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showFrequencyDialog,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupsList() {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backups Disponibles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_backups.length} backup(s)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_backups.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.backup, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun backup disponible',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_backups.length, (index) {
                final backup = _backups[index];
                return AnimatedListItem(
                  index: index,
                  child: _buildBackupItem(backup),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(BackupInfo backup) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backup.isIncremental
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
          child: Icon(
            backup.isIncremental ? Icons.update : Icons.backup,
            color: backup.isIncremental ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          backup.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd/MM/yyyy à HH:mm').format(backup.createdAt)),
            Text(
              '${backup.formattedSize} • ${backup.isEncrypted ? 'Chiffré' : 'Non chiffré'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleBackupAction(value, backup),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, size: 20),
                  SizedBox(width: 8),
                  Text('Restaurer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('Partager'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Types d'export
            SectionTitle(text: 'Types d\'Export'),
            const SizedBox(height: 24),

            // Exports récents
            SectionTitle(text: 'Exports Récents'),
            _buildExportsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTypes() {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Types d\'Export',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Rapports PDF
            _buildExportSection(
              title: 'Rapports PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              items: [
                _buildExportItem('Rapport Mensuel', Icons.calendar_month,
                    () => _exportMonthlyReport()),
                _buildExportItem('Rapport Annuel', Icons.calendar_today,
                    () => _exportAnnualReport()),
                _buildExportItem('Rapport Personnalisé', Icons.tune,
                    () => _exportCustomReport()),
              ],
            ),

            const SizedBox(height: 20),

            // Données Excel/CSV
            _buildExportSection(
              title: 'Données Excel/CSV',
              icon: Icons.table_chart,
              color: Colors.green,
              items: [
                _buildExportItem('Tous les Relevés', Icons.receipt,
                    () => _exportAllReleves()),
                _buildExportItem('Tous les Locataires', Icons.people,
                    () => _exportAllLocataires()),
                _buildExportItem('Données Financières', Icons.attach_money,
                    () => _exportFinancialData()),
                _buildExportItem('Analyse Consommation', Icons.analytics,
                    () => _exportConsumptionAnalysis()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildExportItem(String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildExportsList() {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exports Récents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_exports.length} export(s)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_exports.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.file_download, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun export disponible',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_exports.length, (index) {
                final export = _exports[index];
                return AnimatedListItem(
                  index: index,
                  child: _buildExportItem2(export),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildExportItem2(ExportInfo export) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _getFormatColor(export.format).withValues(alpha: 0.1),
          child: Icon(
            _getFormatIcon(export.format),
            color: _getFormatColor(export.format),
          ),
        ),
        title: Text(
          export.fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd/MM/yyyy à HH:mm').format(export.createdAt)),
            Text(
              export.formattedSize,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleExportAction(value, export),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('Partager'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnhancedCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import de Données',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Importez des données depuis des fichiers CSV, Excel ou JSON.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startImport,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Sélectionner un Fichier'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Formats supportés:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Chip(
                        label: Text('CSV'),
                        avatar: Icon(Icons.table_chart, size: 16),
                      ),
                      SizedBox(width: 8),
                      Chip(
                        label: Text('Excel'),
                        avatar: Icon(Icons.grid_on, size: 16),
                      ),
                      SizedBox(width: 8),
                      Chip(
                        label: Text('JSON'),
                        avatar: Icon(Icons.code, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions des backups

  Future<void> _createFullBackup() async {
    setState(() => _isLoading = true);

    try {
      final result = await _backupService.createFullBackup();

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup créé avec succès: ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createIncrementalBackup() async {
    setState(() => _isLoading = true);

    try {
      final result = await _backupService.createIncrementalBackup();

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result.message ?? 'Backup incrémental créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer un Backup'),
        content: const Text(
          'Sélectionnez un backup à restaurer. Cette opération remplacera toutes les données actuelles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la sélection et restauration
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncToCloud() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Synchronisation cloud en cours de développement...'),
      ),
    );
  }

  Future<void> _configureAutoBackup() async {
    await _backupService.configureAutoBackup(
      enabled: _autoBackupEnabled,
      frequency: _backupFrequency,
    );
  }

  void _showFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fréquence de Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AutoBackupFrequency.values.map((frequency) {
            return RadioListTile<AutoBackupFrequency>(
              title: Text(_getFrequencyText(frequency)),
              value: frequency,
              groupValue: _backupFrequency,
              onChanged: (value) {
                setState(() => _backupFrequency = value!);
                Navigator.pop(context);
                _configureAutoBackup();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleBackupAction(String action, BackupInfo backup) {
    switch (action) {
      case 'restore':
        _restoreBackup(backup);
        break;
      case 'share':
        _shareBackup(backup);
        break;
      case 'delete':
        _deleteBackup(backup);
        break;
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la Restauration'),
        content: Text(
          'Êtes-vous sûr de vouloir restaurer le backup "${backup.name}" ?\n\n'
          'Cette opération remplacera toutes les données actuelles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        final result = await _backupService.restoreBackup(backup.filePath);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Backup restauré avec succès (${result.itemsRestored} éléments)'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareBackup(BackupInfo backup) {
    // TODO: Implémenter le partage de backup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Partage de backup en cours de développement...')),
    );
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le Backup'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${backup.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _backupService.deleteBackup(backup.name);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Actions des exports

  Future<void> _exportMonthlyReport() async {
    final now = DateTime.now();
    setState(() => _isLoading = true);

    try {
      final result = await _exportService.exportMonthlyReportToPDF(
        month: now.month,
        year: now.year,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport exporté: ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAnnualReport() async {
    final now = DateTime.now();
    setState(() => _isLoading = true);

    try {
      final result =
          await _exportService.exportAnnualReportToPDF(year: now.year);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport annuel exporté: ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _exportCustomReport() {
    // TODO: Implémenter l'export de rapport personnalisé
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Rapport personnalisé en cours de développement...')),
    );
  }

  Future<void> _exportAllReleves() async {
    setState(() => _isLoading = true);

    try {
      final result = await _exportService.exportToExcel(
        type: ExcelExportType.allReleves,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relevés exportés: ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAllLocataires() async {
    setState(() => _isLoading = true);

    try {
      final result = await _exportService.exportToExcel(
        type: ExcelExportType.allLocataires,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Locataires exportés: ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportFinancialData() async {
    setState(() => _isLoading = true);

    try {
      final result = await _exportService.exportToExcel(
        type: ExcelExportType.financialData,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Données financières exportées: ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportConsumptionAnalysis() async {
    setState(() => _isLoading = true);

    try {
      final result = await _exportService.exportToExcel(
        type: ExcelExportType.consumptionAnalysis,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Analyse de consommation exportée: ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleExportAction(String action, ExportInfo export) {
    switch (action) {
      case 'share':
        _shareExport(export);
        break;
      case 'delete':
        _deleteExport(export);
        break;
    }
  }

  Future<void> _shareExport(ExportInfo export) async {
    try {
      await _exportService.shareExportedFile(export.filePath, export.fileName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteExport(ExportInfo export) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'Export'),
        content:
            Text('Êtes-vous sûr de vouloir supprimer "${export.fileName}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _exportService.deleteExport(export.filePath);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Actions d'import

  Future<void> _startImport() async {
    try {
      final analysisResult = await _importService.analyzeFile();

      if (analysisResult.success) {
        // TODO: Naviguer vers l'écran de configuration d'import
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier analysé: ${analysisResult.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${analysisResult.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthodes utilitaires

  String _getFrequencyText(AutoBackupFrequency frequency) {
    switch (frequency) {
      case AutoBackupFrequency.daily:
        return 'Quotidien';
      case AutoBackupFrequency.weekly:
        return 'Hebdomadaire';
      case AutoBackupFrequency.monthly:
        return 'Mensuel';
    }
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.excel:
        return Icons.table_chart;
      case ExportFormat.csv:
        return Icons.grid_on;
    }
  }

  Color _getFormatColor(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return Colors.red;
      case ExportFormat.excel:
        return Colors.green;
      case ExportFormat.csv:
        return Colors.blue;
    }
  }
}
