import 'package:flutter/material.dart';
import 'dart:async';

import '../services/real_time_sync_service.dart';

/// Indicateur de synchronisation en temps réel
/// Affiche l'état actuel de la synchronisation dans la barre d'application
class RealTimeSyncIndicator extends StatefulWidget {
  const RealTimeSyncIndicator({super.key});

  @override
  State<RealTimeSyncIndicator> createState() => _RealTimeSyncIndicatorState();
}

class _RealTimeSyncIndicatorState extends State<RealTimeSyncIndicator>
    with TickerProviderStateMixin {
  StreamSubscription<SyncEvent>? _syncEventSubscription;
  RealTimeSyncStatus? _status;
  SyncEvent? _lastEvent;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialiser les animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _loadStatus();
    _subscribeToSyncEvents();
  }

  @override
  void dispose() {
    _syncEventSubscription?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _loadStatus() async {
    final status = await RealTimeSyncService.instance.getStatus();
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  void _subscribeToSyncEvents() {
    _syncEventSubscription = RealTimeSyncService.instance.syncEvents.listen(
      (event) {
        if (mounted) {
          setState(() {
            _lastEvent = event;
          });

          _handleSyncEvent(event);
        }
      },
    );
  }

  void _handleSyncEvent(SyncEvent event) {
    switch (event.type) {
      case SyncEventType.syncStarted:
        _rotationController.repeat();
        break;

      case SyncEventType.syncCompleted:
        _rotationController.stop();
        _rotationController.reset();
        _pulseController.forward().then((_) {
          _pulseController.reverse();
        });
        break;

      case SyncEventType.syncFailed:
      case SyncEventType.error:
        _rotationController.stop();
        _rotationController.reset();
        break;

      case SyncEventType.changesDetected:
        _pulseController.forward().then((_) {
          _pulseController.reverse();
        });
        break;

      default:
        break;
    }

    // Recharger le statut après chaque événement
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null || !_status!.isInitialized) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _showSyncDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSyncIcon(),
            const SizedBox(width: 4),
            _buildSyncText(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncIcon() {
    IconData icon;
    Color color;
    Widget iconWidget;

    if (_status!.isSyncing) {
      icon = Icons.sync;
      color = Colors.blue;
      iconWidget = AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Icon(icon, size: 16, color: color),
          );
        },
      );
    } else if (!_status!.realTimeSyncEnabled) {
      icon = Icons.sync_disabled;
      color = Colors.grey;
      iconWidget = Icon(icon, size: 16, color: color);
    } else if (_lastEvent?.type == SyncEventType.error ||
        _lastEvent?.type == SyncEventType.syncFailed) {
      icon = Icons.sync_problem;
      color = Colors.red;
      iconWidget = Icon(icon, size: 16, color: color);
    } else if (_lastEvent?.type == SyncEventType.changesDetected) {
      icon = Icons.sync_alt;
      color = Colors.orange;
      iconWidget = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Icon(icon, size: 16, color: color),
          );
        },
      );
    } else {
      icon = Icons.cloud_done;
      color = Colors.green;
      iconWidget = Icon(icon, size: 16, color: color);
    }

    return iconWidget;
  }

  Widget _buildSyncText() {
    if (_status!.isSyncing) {
      return Text(
        'Sync...',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (_lastEvent != null) {
      final timeSinceEvent = DateTime.now().difference(_lastEvent!.timestamp);
      if (timeSinceEvent.inMinutes < 1) {
        return Text(
          'Maintenant',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  void _showSyncDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildSyncIcon(),
            const SizedBox(width: 8),
            Text('Synchronisation temps réel'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusInfo(),
              const SizedBox(height: 16),
              _buildRecentEvents(),
              const SizedBox(height: 16),
              _buildDataCounts(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _forceSyncNow();
            },
            child: Text('Synchroniser'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(_status!.statusDescription),
        const SizedBox(height: 8),
        if (_status!.realTimeSyncEnabled) ...[
          Text(
              'Détection de changements: ${_status!.changeDetectionInterval}s'),
          Text(
              'Sync automatique: ${_status!.autoSyncOnChange ? "Activée" : "Désactivée"}'),
        ],
      ],
    );
  }

  Widget _buildRecentEvents() {
    if (_lastEvent == null) {
      return Text('Aucun événement récent');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dernier événement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getEventTypeDescription(_lastEvent!.type),
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                _lastEvent!.message,
                style: TextStyle(fontSize: 12),
              ),
              Text(
                _formatTimestamp(_lastEvent!.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataCounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Données surveillées',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...(_status!.lastKnownCounts.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_getDataTypeLabel(entry.key)),
                Text('${entry.value}'),
              ],
            ),
          ),
        )),
      ],
    );
  }

  String _getEventTypeDescription(SyncEventType type) {
    switch (type) {
      case SyncEventType.serviceStarted:
        return 'Service démarré';
      case SyncEventType.changesDetected:
        return 'Changements détectés';
      case SyncEventType.dataChanged:
        return 'Données modifiées';
      case SyncEventType.syncStarted:
        return 'Synchronisation démarrée';
      case SyncEventType.syncCompleted:
        return 'Synchronisation terminée';
      case SyncEventType.syncFailed:
        return 'Synchronisation échouée';
      case SyncEventType.error:
        return 'Erreur';
      case SyncEventType.configurationChanged:
        return 'Configuration modifiée';
    }
  }

  String _getDataTypeLabel(String dataType) {
    switch (dataType) {
      case 'cites':
        return 'Cités';
      case 'locataires':
        return 'Locataires';
      case 'releves':
        return 'Relevés';
      default:
        return dataType;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Il y a quelques secondes';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} minute(s)';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} heure(s)';
    } else {
      return 'Il y a ${difference.inDays} jour(s)';
    }
  }

  Future<void> _forceSyncNow() async {
    try {
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

      final result = await RealTimeSyncService.instance.forceSyncNow();

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
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
}

/// Version compacte pour les barres d'outils
class CompactRealTimeSyncIndicator extends StatefulWidget {
  const CompactRealTimeSyncIndicator({super.key});

  @override
  State<CompactRealTimeSyncIndicator> createState() =>
      _CompactRealTimeSyncIndicatorState();
}

class _CompactRealTimeSyncIndicatorState
    extends State<CompactRealTimeSyncIndicator>
    with SingleTickerProviderStateMixin {
  StreamSubscription<SyncEvent>? _syncEventSubscription;
  RealTimeSyncStatus? _status;
  SyncEvent? _lastEvent;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _loadStatus();
    _subscribeToSyncEvents();
  }

  @override
  void dispose() {
    _syncEventSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _loadStatus() async {
    final status = await RealTimeSyncService.instance.getStatus();
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  void _subscribeToSyncEvents() {
    _syncEventSubscription = RealTimeSyncService.instance.syncEvents.listen(
      (event) {
        if (mounted) {
          setState(() {
            _lastEvent = event;
          });

          if (event.type == SyncEventType.syncStarted) {
            _animationController.repeat();
          } else {
            _animationController.stop();
            _animationController.reset();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null || !_status!.isInitialized) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;

    if (_status!.isSyncing) {
      icon = Icons.sync;
      color = Colors.blue;
    } else if (!_status!.realTimeSyncEnabled) {
      icon = Icons.sync_disabled;
      color = Colors.grey;
    } else if (_lastEvent?.type == SyncEventType.error) {
      icon = Icons.sync_problem;
      color = Colors.red;
    } else {
      icon = Icons.cloud_done;
      color = Colors.green;
    }

    Widget iconWidget = Icon(icon, size: 20, color: color);

    if (_status!.isSyncing) {
      iconWidget = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animationController.value * 2 * 3.14159,
            child: iconWidget,
          );
        },
      );
    }

    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Synchronisation'),
            content: RealTimeSyncIndicator(),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
        );
      },
      icon: iconWidget,
      tooltip: _status!.statusDescription,
    );
  }
}
