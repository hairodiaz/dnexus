import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/cash_register_service.dart';
import '../../../core/utils/currency_formatter.dart';

/// Diálogo para abrir una nueva caja registradora
class OpenCashRegisterDialog extends StatefulWidget {
  final UserModel user;
  final int businessId;

  const OpenCashRegisterDialog({
    super.key,
    required this.user,
    required this.businessId,
  });

  @override
  State<OpenCashRegisterDialog> createState() => _OpenCashRegisterDialogState();
}

class _OpenCashRegisterDialogState extends State<OpenCashRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _initialAmountController = TextEditingController(text: '5000');
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _initialAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openCashRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final initialAmount = double.parse(_initialAmountController.text.replaceAll(',', ''));
      final notes = _notesController.text.trim();

      final cashRegister = CashRegisterService.openCashRegister(
        businessId: widget.businessId,
        user: widget.user,
        initialAmount: initialAmount,
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        Navigator.of(context).pop(cashRegister);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir caja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setQuickAmount(double amount) {
    _initialAmountController.text = amount.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.lock_open,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Abrir Caja Registradora',
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

              // User info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName ?? widget.user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Cajero(a) - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Initial amount
              const Text(
                'Monto inicial en caja',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _initialAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto inicial *',
                  hintText: '5000',
                  prefixText: 'RD\$ ',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.monetization_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El monto inicial es requerido';
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

              // Quick amount buttons
              const Text(
                'Montos comunes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                children: [
                  _buildQuickAmountChip(1000),
                  _buildQuickAmountChip(3000),
                  _buildQuickAmountChip(5000),
                  _buildQuickAmountChip(10000),
                  _buildQuickAmountChip(15000),
                  _buildQuickAmountChip(20000),
                ],
              ),
              const SizedBox(height: 20),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Observaciones sobre la apertura de caja...',
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
                      onPressed: _isLoading ? null : _openCashRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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
                          : const Text('Abrir Caja'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El monto inicial debe coincidir con el dinero físico en caja',
                        style: TextStyle(
                          color: Colors.orange[700],
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
    );
  }

  Widget _buildQuickAmountChip(double amount) {
    return ActionChip(
      label: Text(CurrencyFormatter.formatNoDecimals(amount)),
      onPressed: () => _setQuickAmount(amount),
      backgroundColor: Colors.grey[100],
      side: BorderSide(color: Colors.grey[300]!),
    );
  }
}