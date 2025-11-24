import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/cash_register_model.dart';
import '../../../shared/services/cash_register_service.dart';
import '../../../core/utils/currency_formatter.dart';

/// Diálogo para cerrar una caja registradora
class CloseCashRegisterDialog extends StatefulWidget {
  final CashRegisterModel cashRegister;

  const CloseCashRegisterDialog({
    super.key,
    required this.cashRegister,
  });

  @override
  State<CloseCashRegisterDialog> createState() => _CloseCashRegisterDialogState();
}

class _CloseCashRegisterDialogState extends State<CloseCashRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _finalAmountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  double? _difference;

  @override
  void initState() {
    super.initState();
    // Actualizar estadísticas antes de mostrar el diálogo
    final updatedRegister = CashRegisterService.updateCashRegisterStats(widget.cashRegister.id);
    _finalAmountController.text = updatedRegister.calculatedExpectedAmount.toInt().toString();
    _calculateDifference();
  }

  @override
  void dispose() {
    _finalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateDifference() {
    final finalAmountText = _finalAmountController.text.replaceAll(',', '');
    final finalAmount = double.tryParse(finalAmountText);
    
    if (finalAmount != null) {
      final updatedRegister = CashRegisterService.getCashRegisterById(widget.cashRegister.id)!;
      final expectedAmount = updatedRegister.calculatedExpectedAmount;
      setState(() {
        _difference = finalAmount - expectedAmount;
      });
    } else {
      setState(() {
        _difference = null;
      });
    }
  }

  Future<void> _closeCashRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final finalAmount = double.parse(_finalAmountController.text.replaceAll(',', ''));
      final notes = _notesController.text.trim();

      final closedRegister = CashRegisterService.closeCashRegister(
        cashRegisterId: widget.cashRegister.id,
        finalAmount: finalAmount,
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        Navigator.of(context).pop(closedRegister);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar caja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getDifferenceColor() {
    if (_difference == null) return Colors.grey;
    if (_difference! > 0) return Colors.green;
    if (_difference! < 0) return Colors.red;
    return Colors.blue;
  }

  String _getDifferenceText() {
    if (_difference == null) return '--';
    if (_difference! > 0) {
      return '+${CurrencyFormatter.formatNoDecimals(_difference!.abs())} (Sobrante)';
    }
    if (_difference! < 0) {
      return '-${CurrencyFormatter.formatNoDecimals(_difference!.abs())} (Faltante)';
    }
    return 'Exacto';
  }

  IconData _getDifferenceIcon() {
    if (_difference == null) return Icons.help_outline;
    if (_difference! > 0) return Icons.trending_up;
    if (_difference! < 0) return Icons.trending_down;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final updatedRegister = CashRegisterService.getCashRegisterById(widget.cashRegister.id)!;
    final workDuration = DateTime.now().difference(updatedRegister.openedAt);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Cerrar Caja Registradora',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen de la jornada',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'Tiempo abierta',
                              '${workDuration.inHours}h ${workDuration.inMinutes.remainder(60)}m',
                              Icons.access_time,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'Transacciones',
                              updatedRegister.transactionCount.toString(),
                              Icons.receipt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'Monto inicial',
                              CurrencyFormatter.formatNoDecimals(updatedRegister.initialAmount),
                              Icons.account_balance_wallet,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'Ventas totales',
                              CurrencyFormatter.formatNoDecimals(updatedRegister.totalSales),
                              Icons.monetization_on,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Expected amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calculate,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monto esperado en caja',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatNoDecimals(updatedRegister.calculatedExpectedAmount),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Final amount input
                const Text(
                  'Conteo físico de dinero en caja',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _finalAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (value) => _calculateDifference(),
                  decoration: const InputDecoration(
                    labelText: 'Monto final *',
                    hintText: 'Cantidad física contada',
                    prefixText: 'RD\$ ',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.monetization_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El monto final es requerido';
                    }
                    final amount = double.tryParse(value.replaceAll(',', ''));
                    if (amount == null) {
                      return 'Ingrese un monto válido';
                    }
                    if (amount < 0) {
                      return 'El monto no puede ser negativo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Difference indicator
                if (_difference != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getDifferenceColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getDifferenceColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getDifferenceIcon(),
                          color: _getDifferenceColor(),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diferencia',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getDifferenceText(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getDifferenceColor(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas del cierre (opcional)',
                    hintText: 'Observaciones sobre diferencias, incidentes, etc...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _closeCashRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Cerrar Caja'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Warning note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: Colors.red[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Una vez cerrada, no podrás modificar esta caja registradora',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}