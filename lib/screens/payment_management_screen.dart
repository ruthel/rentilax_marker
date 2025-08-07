import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/payment_history.dart';
import '../services/payment_service.dart';
import '../services/database_service.dart';

class PaymentManagementScreen extends StatefulWidget {
  final Releve releve;
  final Locataire locataire;

  const PaymentManagementScreen({
    super.key,
    required this.releve,
    required this.locataire,
  });

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<PaymentHistory> _paymentHistory = [];
  bool _isLoading = true;

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedPaymentMethod = 'Espèces';

  final List<String> _paymentMethods = [
    'Espèces',
    'Virement bancaire',
    'Mobile Money',
    'Chèque',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await PaymentService.getPaymentHistory(widget.releve.id!);
      setState(() {
        _paymentHistory = history;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Paiements'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaymentSummaryCard(),
                  const SizedBox(height: 16),
                  _buildPaymentProgressCard(),
                  const SizedBox(height: 16),
                  if (widget.releve.remainingAmount > 0) ...[
                    _buildNewPaymentCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildPaymentHistoryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  widget.locataire.nomComplet,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
                'Période',
                DateFormat('MMMM yyyy', 'fr_FR')
                    .format(widget.releve.moisReleve)),
            _buildSummaryRow('Consommation',
                '${widget.releve.consommation.toStringAsFixed(2)} unités'),
            _buildSummaryRow('Montant total',
                '${widget.releve.montant.toStringAsFixed(2)} FCFA'),
            _buildSummaryRow('Montant payé',
                '${widget.releve.paidAmount.toStringAsFixed(2)} FCFA'),
            _buildSummaryRow(
              'Montant restant',
              '${widget.releve.remainingAmount.toStringAsFixed(2)} FCFA',
              isHighlighted: widget.releve.remainingAmount > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProgressCard() {
    final progress = widget.releve.paymentProgress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Progression du Paiement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progress >= 100 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 100 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 FCFA',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${widget.releve.montant.toStringAsFixed(0)} FCFA',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPaymentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Nouveau Paiement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Montant (FCFA)',
                border: const OutlineInputBorder(),
                helperText:
                    'Maximum: ${widget.releve.remainingAmount.toStringAsFixed(2)} FCFA',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Mode de paiement',
                border: OutlineInputBorder(),
              ),
              items: _paymentMethods
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPaymentMethod = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processPayment,
                icon: const Icon(Icons.add),
                label: const Text('Enregistrer le Paiement'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Historique des Paiements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_paymentHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucun paiement enregistré',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._paymentHistory.map((payment) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        child: const Icon(Icons.check, color: Colors.green),
                      ),
                      title: Text('${payment.amount.toStringAsFixed(2)} FCFA'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mode: ${payment.paymentMethod}'),
                          Text(
                              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate)}'),
                          if (payment.notes != null &&
                              payment.notes!.isNotEmpty)
                            Text('Note: ${payment.notes}'),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }

    if (amount > widget.releve.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le montant dépasse le montant restant')),
      );
      return;
    }

    try {
      final success = await PaymentService.makePartialPayment(
        releveId: widget.releve.id!,
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (success) {
        _amountController.clear();
        _notesController.clear();
        await _loadPaymentHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paiement enregistré avec succès')),
          );

          // Retourner à l'écran précédent si le paiement est complet
          if (amount >= widget.releve.remainingAmount) {
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Erreur lors de l\'enregistrement du paiement')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
