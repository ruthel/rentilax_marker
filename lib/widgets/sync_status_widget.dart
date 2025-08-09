import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sync_scheduler_service.dart';
import '../services/google_drive_service.dart';

/// Widget d'affichage du statut de synchronisation
class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  AutoSyncStatus? _syncStatus;
  LastBackupInfo? _lastBackup;
  SyncStatus? _detailedSyncStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() => _isLoading = true);

    try {
      final status = await SyncSchedulerService.getAutoSyncStatus();
      final backup = await GoogleDriveService.getLastBackupInfo();
      final syncStatus = await GoogleDriveService.getSyncStatus();

      setState(() {
        _syncStatus = status;
        _lastBackup = backup;
        _detailedSyncStatus = syncStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Synchronisation Google Drive',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            // Statut de connexion Google Drive
            _buildStatusRow(
              'Statut',
              _detailedSyncStatus?.statusMessage ?? 'Chargement...',
              Icons.info,
            ),

            if (_detailedSyncStatus?.isSignedIn == true) ...[
              // Informations sur les changements
              if (_detailedSyncStatus!.hasLocalChanges)
                _buildStatusRow(
                  'Changements locaux',
                  'Non synchronisés',
                  Icons.edit,
                  color: Colors.orange,
                ),
              if (_detailedSyncStatus!.hasRemoteChanges)
                _buildStatusRow(
                  'Changements distants',
                  'Disponibles',
                  Icons.cloud_download,
                  color: Colors.blue,
                ),

              // Informations sur les sauvegardes
              if (_detailedSyncStatus!.remoteBackupCount > 0)
                _buildStatusRow(
                  'Sauvegardes distantes',
                  '${_detailedSyncStatus!.remoteBackupCount}',
                  Icons.backup,
                ),
            ],

            if (_syncStatus?.enabled == true) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Configuration automatique',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                'Fréquence',
                _syncStatus!.intervalDescription,
                Icons.schedule,
              ),
              if (_syncStatus!.nextSyncTime != null)
                _buildStatusRow(
                  'Prochaine sync',
                  _syncStatus!.nextSyncDescription ?? 'Inconnue',
                  Icons.access_time,
                ),
              if (_syncStatus!.wifiOnly)
                _buildStatusRow(
                  'Connexion',
                  'Wi-Fi uniquement',
                  Icons.wifi,
                ),
            ] else if (_detailedSyncStatus?.isSignedIn == true) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Synchronisation automatique désactivée',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_lastBackup != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Dernière sauvegarde',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd/MM/yyyy à HH:mm').format(_lastBackup!.timestamp),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _forceSyncNow,
                    icon: Icon(Icons.sync, size: 16),
                    label: Text('Synchroniser'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadSyncStatus,
                  icon: Icon(Icons.refresh, size: 20),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon,
      {Color? color}) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: effectiveColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (_detailedSyncStatus?.isSignedIn != true) return Icons.cloud_off;
    if (_syncStatus?.isRunning == true) return Icons.sync;
    if (_detailedSyncStatus?.needsSync == true) return Icons.sync_problem;
    return Icons.cloud_done;
  }

  Color _getStatusColor() {
    if (_detailedSyncStatus?.isSignedIn != true) return Colors.grey;
    if (_syncStatus?.isRunning == true) return Colors.blue;
    if (_detailedSyncStatus?.needsSync == true) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStatusBadge() {
    if (_syncStatus?.isRunning == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Actif',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_detailedSyncStatus?.needsSync == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Sync requise',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _forceSyncNow() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Synchronisation en cours...'),
            ],
          ),
        ),
      );

      // Utiliser la synchronisation bidirectionnelle avancée
      final result = await GoogleDriveService.performBidirectionalSync();

      // Fermer le dialogue de chargement
      if (mounted) {
        Navigator.pop(context);
      }

      // Actualiser le statut
      await _loadSyncStatus();

      // Afficher le résultat détaillé
      if (mounted) {
        _showSyncResult(result);
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSyncResult(SyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text('Résultat de la synchronisation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            if (result.syncDetails != null) ...[
              const SizedBox(height: 16),
              Text(
                'Détails:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(result.syncDetails!.summary),
              if (result.syncDetails!.hasErrors) ...[
                const SizedBox(height: 8),
                Text(
                  'Erreurs:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                ...result.syncDetails!.errors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      '• $error',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

/// Widget compact pour afficher le statut dans une barre d'outils
class CompactSyncStatusWidget extends StatefulWidget {
  const CompactSyncStatusWidget({super.key});

  @override
  State<CompactSyncStatusWidget> createState() =>
      _CompactSyncStatusWidgetState();
}

class _CompactSyncStatusWidgetState extends State<CompactSyncStatusWidget> {
  AutoSyncStatus? _syncStatus;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final status = await SyncSchedulerService.getAutoSyncStatus();
      setState(() => _syncStatus = status);
    } catch (e) {
      // Ignorer les erreurs pour le widget compact
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_syncStatus == null) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String tooltip;

    if (_syncStatus!.enabled) {
      if (_syncStatus!.isRunning) {
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        tooltip = 'Synchronisation active';
      } else {
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
        tooltip = 'Synchronisation configurée';
      }
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.cloud_off;
      tooltip = 'Synchronisation désactivée';
    }

    return IconButton(
      onPressed: () => _showSyncDialog(context),
      icon: Icon(statusIcon, color: statusColor),
      tooltip: tooltip,
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Statut de synchronisation'),
        content: SyncStatusWidget(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
