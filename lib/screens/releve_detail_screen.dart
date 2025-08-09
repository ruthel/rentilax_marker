import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/payment_history.dart';
import '../services/database_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';
import '../utils/app_spacing.dart';
import '../l10n/l10n_extensions.dart';
import 'payment_management_screen.dart';

class ReleveDetailScreen extends StatefulWidget {
  final int releveId;
  const ReleveDetailScreen({super.key, required this.releveId});

  @override
  State<ReleveDetailScreen> createState() => _ReleveDetailScreenState();
}

class _ReleveDetailScreenState extends State<ReleveDetailScreen> {
  final DatabaseService _db = DatabaseService();
  Releve? _releve;
  Locataire? _locataire;
  List<PaymentHistory> _paymentHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final releve = await _db.getReleveById(widget.releveId);
    Locataire? locataire;
    List<PaymentHistory> paymentHistory = [];

    if (releve != null) {
      locataire = await _db.getLocataireById(releve.locataireId);
      paymentHistory = await _db.getPaymentHistory(releve.id!);
    }

    if (mounted) {
      setState(() {
        _releve = releve;
        _locataire = locataire;
        _paymentHistory = paymentHistory;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return const Scaffold(
        appBar: ModernAppBar(title: 'Détails du relevé'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_releve == null) {
      return Scaffold(
        appBar: const ModernAppBar(title: 'Détails du relevé'),
        body: Center(
          child: Text(l10n.noRelevesFound),
        ),
      );
    }

    final releve = _releve!;
    final locataire = _locataire;

    return Scaffold(
      appBar: ModernAppBar(
        title: l10n.readingDetails,
        actions: [
          if (releve.remainingAmount > 0)
            IconButton(
              icon: const Icon(Icons.payment_rounded),
              tooltip: 'Gérer les paiements',
              onPressed: () => _navigateToPaymentManagement(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte locataire
              ModernCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locataire != null
                                ? '${locataire.prenom} ${locataire.nom}'
                                : l10n.tenant,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(releve.dateReleve),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Carte indices et conso
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.consumption,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            context,
                            label: l10n.oldIndex,
                            value: releve.ancienIndex.toStringAsFixed(2),
                          ),
                        ),
                        Expanded(
                          child: _buildMetric(
                            context,
                            label: l10n.newIndex,
                            value: releve.nouvelIndex.toStringAsFixed(2),
                          ),
                        ),
                        Expanded(
                          child: _buildMetric(
                            context,
                            label: l10n.consumption,
                            value: releve.consommation.toStringAsFixed(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Carte tarification
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appliedRate,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            context,
                            label: l10n.appliedRate,
                            value:
                                '${releve.tarif.toStringAsFixed(2)} ${l10n.currency}',
                          ),
                        ),
                        Expanded(
                          child: _buildMetric(
                            context,
                            label: l10n.totalAmount,
                            value: releve.montant.toStringAsFixed(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Carte statut de paiement
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.paymentStatus,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            context,
                            label: l10n.status,
                            value: releve.isPaid
                                ? l10n.paid
                                : releve.isPartiallyPaid
                                    ? '${l10n.paid} (partial)'
                                    : l10n.unpaid,
                          ),
                        ),
                        Expanded(
                          child: _buildMetric(
                            context,
                            label: l10n.paymentDate,
                            value: releve.paymentDate != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(releve.paymentDate!)
                                : '-',
                          ),
                        ),
                      ],
                    ),
                    if (releve.paidAmount > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetric(
                              context,
                              label: 'Montant payé',
                              value:
                                  '${releve.paidAmount.toStringAsFixed(2)} ${l10n.currency}',
                            ),
                          ),
                          Expanded(
                            child: _buildMetric(
                              context,
                              label: 'Montant restant',
                              value:
                                  '${releve.remainingAmount.toStringAsFixed(2)} ${l10n.currency}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentProgress(releve),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Historique des paiements
              if (_paymentHistory.isNotEmpty) _buildPaymentHistorySection(),

              if (releve.commentaire != null &&
                  releve.commentaire!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.comment,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        releve.commentaire!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context,
      {required String label, required String value}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentProgress(Releve releve) {
    final theme = Theme.of(context);
    final progress = releve.paymentProgress;
    final progressColor = progress >= 100 ? Colors.green : Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression du paiement',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${progress.toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: theme.colorScheme.surfaceContainer,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 FCFA',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${releve.montant.toStringAsFixed(0)} FCFA',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentHistorySection() {
    final theme = Theme.of(context);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Historique des paiements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_paymentHistory.length}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._paymentHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final payment = entry.value;
            final isLast = index == _paymentHistory.length - 1;

            return Column(
              children: [
                _buildPaymentHistoryItem(payment),
                if (!isLast) const Divider(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(PaymentHistory payment) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${payment.amount.toStringAsFixed(2)} FCFA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _getPaymentMethodIcon(payment.paymentMethod),
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    payment.paymentMethod,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          payment.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'espèces':
        return Icons.payments_rounded;
      case 'virement bancaire':
        return Icons.account_balance_rounded;
      case 'mobile money':
        return Icons.phone_android_rounded;
      case 'chèque':
        return Icons.receipt_long_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  void _navigateToPaymentManagement() async {
    if (_releve == null || _locataire == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentManagementScreen(
          releve: _releve!,
          locataire: _locataire!,
        ),
      ),
    );

    // Recharger les données si un paiement a été effectué
    if (result == true) {
      _load();
    }
  }
}
