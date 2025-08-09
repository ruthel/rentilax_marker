import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/google_drive_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/section_title.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  List<GoogleDriveBackupInfo> _googleDriveBackups = [];
  bool _isLoading = false;
  bool _autoBackupEnabled = false;
  AutoBackupFrequency _backupFrequency = AutoBackupFrequency.daily;

  // Google Drive
  GoogleSignInAccount? _googleAccount;
  bool _isGoogleSignedIn = false;
  bool _googleSyncEnabled = false;
  LastBackupInfo? _lastGoogleBackup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

      // Charger les données Google Drive
      await _loadGoogleDriveData();

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

  Future<void> _loadGoogleDriveData() async {
    try {
      _isGoogleSignedIn = await GoogleDriveService.isSignedIn();
      if (_isGoogleSignedIn) {
        _googleAccount = await GoogleDriveService.getCurrentAccount();
        _googleDriveBackups = await GoogleDriveService.listBackups();
        _lastGoogleBackup = await GoogleDriveService.getLastBackupInfo();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données Google Drive: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Backup & Synchronisation',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.backup), text: 'Backup'),
            Tab(icon: Icon(Icons.cloud), text: 'Google Drive'),
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
                _buildGoogleDriveTab(),
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

  Future<void> _configureAutoBackup() async {
    await _backupService.configureAutoBackup(
      enabled: _autoBackupEnabled,
      frequency: _backupFrequency,
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

  Widget _buildGoogleDriveTab() {
    return RefreshIndicator(
      onRefresh: _loadGoogleDriveData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section de connexion Google
            _buildGoogleConnectionSection(),

            const SizedBox(height: 24),

            // Section de sauvegarde Google Drive
            if (_isGoogleSignedIn) ...[
              _buildGoogleBackupSection(),

              const SizedBox(height: 24),

              // Liste des sauvegardes Google Drive
              _buildGoogleBackupsList(),

              const SizedBox(height: 24),

              // Configuration de synchronisation automatique
              _buildAutoSyncSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleConnectionSection() {
    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Drive',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _isGoogleSignedIn
                          ? 'Connecté en tant que ${_googleAccount?.email ?? "Utilisateur"}'
                          : 'Connectez-vous pour sauvegarder sur Google Drive',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isGoogleSignedIn) ...[
            // Informations du compte connecté
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _googleAccount?.photoUrl != null
                        ? NetworkImage(_googleAccount!.photoUrl!)
                        : null,
                    child: _googleAccount?.photoUrl == null
                        ? Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _googleAccount?.displayName ?? 'Utilisateur Google',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _googleAccount?.email ?? '',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _signOutFromGoogle,
                    icon: Icon(Icons.logout, size: 16),
                    label: Text('Déconnecter'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            if (_lastGoogleBackup != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.backup, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dernière sauvegarde : ${DateFormat('dd/MM/yyyy HH:mm').format(_lastGoogleBackup!.timestamp)}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Bouton de connexion
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signInToGoogle,
                icon: Icon(Icons.login),
                label: Text('Se connecter à Google Drive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoogleBackupSection() {
    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sauvegarde Google Drive',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _backupToGoogleDrive,
                  icon: Icon(Icons.cloud_upload),
                  label: Text('Sauvegarder maintenant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _performGoogleSync,
                  icon: Icon(Icons.sync),
                  label: Text('Synchroniser'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleBackupsList() {
    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sauvegardes disponibles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: _loadGoogleDriveData,
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Actualiser'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_googleDriveBackups.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune sauvegarde trouvée',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez votre première sauvegarde Google Drive',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_googleDriveBackups.asMap().entries.map((entry) {
              final index = entry.key;
              final backup = entry.value;
              return AnimatedListItem(
                index: index,
                child: _buildGoogleDriveBackupItem(backup),
              );
            })),
        ],
      ),
    );
  }

  Widget _buildGoogleDriveBackupItem(GoogleDriveBackupInfo backup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.cloud, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.name,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(backup.createdTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.storage, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      backup.formattedSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Restaurer'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'restore') {
                _restoreFromGoogleDrive(backup);
              } else if (value == 'delete') {
                _deleteGoogleBackup(backup);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSyncSection() {
    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Synchronisation automatique',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Activer la synchronisation automatique'),
            subtitle: Text('Sauvegarde automatique sur Google Drive'),
            value: _googleSyncEnabled,
            onChanged: (value) {
              setState(() => _googleSyncEnabled = value);
              _configureAutoSync();
            },
          ),
          if (_googleSyncEnabled) ...[
            const Divider(),
            ListTile(
              title: Text('Fréquence de synchronisation'),
              subtitle: Text('Quotidienne'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showSyncFrequencyDialog,
            ),
            ListTile(
              title: Text('Synchroniser uniquement en Wi-Fi'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implémenter la configuration Wi-Fi uniquement
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Méthodes Google Drive
  Future<void> _signInToGoogle() async {
    try {
      final account = await GoogleDriveService.signIn();
      if (account != null) {
        await _loadGoogleDriveData();
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connecté à Google Drive avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOutFromGoogle() async {
    try {
      await GoogleDriveService.signOut();
      await _loadGoogleDriveData();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Déconnecté de Google Drive'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _backupToGoogleDrive() async {
    try {
      setState(() => _isLoading = true);

      final result = await GoogleDriveService.backupToGoogleDrive(
        includePaymentHistory: true,
        includeConfiguration: true,
      );

      setState(() => _isLoading = false);

      if (result.success) {
        await _loadGoogleDriveData();
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sauvegarde réussie sur Google Drive'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performGoogleSync() async {
    try {
      setState(() => _isLoading = true);

      final result = await GoogleDriveService.performAutoSync();

      setState(() => _isLoading = false);

      if (result.success) {
        await _loadGoogleDriveData();
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synchronisation réussie'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Info: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromGoogleDrive(GoogleDriveBackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la restauration'),
        content: Text(
          'Êtes-vous sûr de vouloir restaurer cette sauvegarde ?\n\n'
          'Cette action remplacera toutes vos données actuelles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        final result =
            await GoogleDriveService.restoreFromGoogleDrive(backup.id);

        setState(() => _isLoading = false);

        if (result.success) {
          await _loadData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Restauration réussie depuis Google Drive'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la restauration: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteGoogleBackup(GoogleDriveBackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette sauvegarde ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await GoogleDriveService.deleteBackup(backup.id);

        if (success) {
          await _loadGoogleDriveData();
          setState(() {});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sauvegarde supprimée'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la suppression'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _configureAutoSync() async {
    await GoogleDriveService.configureAutoSync(
      enabled: _googleSyncEnabled,
      intervalHours: 24, // Quotidien par défaut
      wifiOnly: true,
    );
  }

  void _showSyncFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fréquence de synchronisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: Text('Toutes les heures'),
              value: 1,
              groupValue: 24,
              onChanged: (value) {
                Navigator.pop(context);
                // TODO: Configurer la fréquence
              },
            ),
            RadioListTile<int>(
              title: Text('Quotidienne'),
              value: 24,
              groupValue: 24,
              onChanged: (value) {
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: Text('Hebdomadaire'),
              value: 168,
              groupValue: 24,
              onChanged: (value) {
                Navigator.pop(context);
                // TODO: Configurer la fréquence
              },
            ),
          ],
        ),
      ),
    );
  }
}
