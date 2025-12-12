import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/services/invoice_service.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final _invoiceService = InvoiceService();
  
  List<InvoiceModel> _pendingInvoices = [];
  InvoiceModel? _selectedInvoice;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  
  final _cashAmountController = TextEditingController();
  final _cardAmountController = TextEditingController();
  final _bankAmountController = TextEditingController();
  
  bool _isLoading = false;
  double _changeAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPendingInvoices();
  }

  Future<void> _loadPendingInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allInvoices = _invoiceService.getAllInvoices();
      _pendingInvoices = allInvoices.where(
        (invoice) => invoice.status == InvoiceStatus.inCashier,
      ).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando facturas: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectInvoice(InvoiceModel invoice) {
    setState(() {
      _selectedInvoice = invoice;
      _resetPaymentForm();
    });
  }

  void _resetPaymentForm() {
    _cashAmountController.clear();
    _cardAmountController.clear();
    _bankAmountController.clear();
    _selectedPaymentMethod = PaymentMethod.cash;
    _changeAmount = 0.0;
  }

  void _calculateChange() {
    if (_selectedInvoice == null) return;

    double totalPaid = 0.0;
    
    switch (_selectedPaymentMethod) {
      case PaymentMethod.cash:
        totalPaid = double.tryParse(_cashAmountController.text) ?? 0.0;
        break;
      case PaymentMethod.card:
        totalPaid = _selectedInvoice!.total; // Cards pay exact amount
        break;
      case PaymentMethod.bankTransfer:
        totalPaid = _selectedInvoice!.total; // Bank transfers pay exact amount
        break;
      case PaymentMethod.mixed:
        totalPaid = (double.tryParse(_cashAmountController.text) ?? 0.0) +
                   (double.tryParse(_cardAmountController.text) ?? 0.0) +
                   (double.tryParse(_bankAmountController.text) ?? 0.0);
        break;
    }

    setState(() {
      _changeAmount = totalPaid - _selectedInvoice!.total;
    });
  }

  Future<void> _processPayment() async {
    if (_selectedInvoice == null) return;

    double totalPaid = 0.0;
    
    switch (_selectedPaymentMethod) {
      case PaymentMethod.cash:
        totalPaid = double.tryParse(_cashAmountController.text) ?? 0.0;
        break;
      case PaymentMethod.card:
        totalPaid = _selectedInvoice!.total;
        break;
      case PaymentMethod.bankTransfer:
        totalPaid = _selectedInvoice!.total;
        break;
      case PaymentMethod.mixed:
        totalPaid = (double.tryParse(_cashAmountController.text) ?? 0.0) +
                   (double.tryParse(_cardAmountController.text) ?? 0.0) +
                   (double.tryParse(_bankAmountController.text) ?? 0.0);
        break;
    }

    if (totalPaid < _selectedInvoice!.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto pagado es insuficiente')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _invoiceService.processPayment(
        _selectedInvoice!.id,
        _selectedPaymentMethod,
        totalPaid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago procesado exitosamente')),
        );
        
        // Show change dialog if there's change
        if (_changeAmount > 0) {
          _showChangeDialog();
        } else {
          _completeTransaction();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error procesando pago: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showChangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cambio a Devolver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              '\$${_changeAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: _completeTransaction,
            child: const Text('Cambio Entregado'),
          ),
        ],
      ),
    );
  }

  void _completeTransaction() {
    Navigator.of(context).pop(); // Close change dialog if open
    setState(() {
      _selectedInvoice = null;
      _resetPaymentForm();
    });
    _loadPendingInvoices(); // Refresh the list
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Pago',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PaymentMethod>(
          initialValue: _selectedPaymentMethod,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: PaymentMethod.values.map((method) {
            return DropdownMenuItem(
              value: method,
              child: Text(_getPaymentMethodName(method)),
            );
          }).toList(),
          onChanged: (method) {
            setState(() {
              _selectedPaymentMethod = method!;
              _resetPaymentForm();
            });
          },
        ),
      ],
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.bankTransfer:
        return 'Transferencia';
      case PaymentMethod.mixed:
        return 'Mixto';
    }
  }

  Widget _buildPaymentInputs() {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.cash:
        return Column(
          children: [
            TextField(
              controller: _cashAmountController,
              decoration: const InputDecoration(
                labelText: 'Monto Recibido',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (_) => _calculateChange(),
            ),
            if (_changeAmount != 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _changeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  border: Border.all(
                    color: _changeAmount >= 0 ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _changeAmount >= 0 ? 'Cambio:' : 'Faltante:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _changeAmount >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '\$${_changeAmount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _changeAmount >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case PaymentMethod.card:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.credit_card, size: 48, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                'Monto: \$${_selectedInvoice!.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('Confirme el pago con tarjeta'),
            ],
          ),
        );

      case PaymentMethod.bankTransfer:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            border: Border.all(color: Colors.purple),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.account_balance, size: 48, color: Colors.purple),
              const SizedBox(height: 8),
              Text(
                'Monto: \$${_selectedInvoice!.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('Confirme la transferencia bancaria'),
            ],
          ),
        );

      case PaymentMethod.mixed:
        return Column(
          children: [
            TextField(
              controller: _cashAmountController,
              decoration: const InputDecoration(
                labelText: 'Efectivo',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (_) => _calculateChange(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cardAmountController,
              decoration: const InputDecoration(
                labelText: 'Tarjeta',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (_) => _calculateChange(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bankAmountController,
              decoration: const InputDecoration(
                labelText: 'Transferencia',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (_) => _calculateChange(),
            ),
            if (_changeAmount != 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _changeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  border: Border.all(
                    color: _changeAmount >= 0 ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _changeAmount >= 0 ? 'Cambio:' : 'Faltante:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _changeAmount >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '\$${_changeAmount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _changeAmount >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja - Procesar Pagos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPendingInvoices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Pending invoices list
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long),
                              const SizedBox(width: 8),
                              Text(
                                'Facturas Pendientes (${_pendingInvoices.length})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _pendingInvoices.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No hay facturas pendientes',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _pendingInvoices.length,
                                  itemBuilder: (context, index) {
                                    final invoice = _pendingInvoices[index];
                                    final isSelected = _selectedInvoice?.id == invoice.id;
                                    
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.teal.shade50 : null,
                                        border: Border.all(
                                          color: isSelected ? Colors.teal : Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          invoice.number,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Cliente: ${invoice.clientName}'),
                                            Text('Total: \$${invoice.total.toStringAsFixed(2)}'),
                                            Text('Items: ${invoice.items.length}'),
                                          ],
                                        ),
                                        trailing: isSelected
                                            ? const Icon(Icons.check_circle, color: Colors.teal)
                                            : null,
                                        onTap: () => _selectInvoice(invoice),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Payment processing panel
                Expanded(
                  flex: 1,
                  child: _selectedInvoice == null
                      ? const Center(
                          child: Text(
                            'Seleccione una factura para procesar',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Invoice details
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedInvoice!.number,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Cliente: ${_selectedInvoice!.clientName}'),
                                      Text('Fecha: ${_selectedInvoice!.formattedDate}'),
                                      const Divider(),
                                      Text(
                                        'Total: \$${_selectedInvoice!.total.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Payment method selection
                              _buildPaymentMethodSelector(),
                              
                              const SizedBox(height: 16),
                              
                              // Payment inputs
                              _buildPaymentInputs(),
                              
                              const Spacer(),
                              
                              // Process payment button
                              ElevatedButton(
                                onPressed: _isLoading || (_selectedPaymentMethod == PaymentMethod.cash && _changeAmount < 0)
                                    ? null
                                    : _processPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Procesar Pago',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _cashAmountController.dispose();
    _cardAmountController.dispose();
    _bankAmountController.dispose();
    super.dispose();
  }
}