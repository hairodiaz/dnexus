import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/services/invoice_service.dart';
import '../../../shared/widgets/cash_register_validator.dart';
import '../../../core/utils/currency_formatter.dart';

/// Página simplificada para cajeros - Procesar pagos de facturas
class CashierSimplePage extends StatefulWidget {
  final UserModel user;
  final int businessId;

  const CashierSimplePage({
    super.key,
    required this.user,
    required this.businessId,
  });

  @override
  State<CashierSimplePage> createState() => _CashierSimplePageState();
}

class _CashierSimplePageState extends State<CashierSimplePage> {
  List<InvoiceModel> _pendingInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingInvoices();
  }

  Future<void> _loadPendingInvoices() async {
    setState(() => _isLoading = true);
    try {
      final allInvoices = InvoiceService.getAllInvoices();
      _pendingInvoices = allInvoices.where((invoice) => 
        invoice.status == InvoiceStatus.created || 
        invoice.status == InvoiceStatus.inCashier
      ).toList();
      _filteredInvoices = _pendingInvoices;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando facturas: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterInvoices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInvoices = _pendingInvoices;
      } else {
        _filteredInvoices = _pendingInvoices.where((invoice) =>
          invoice.number.toLowerCase().contains(query.toLowerCase()) ||
          (invoice.customerName ?? '').toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _processPayment(InvoiceModel invoice, PaymentMethod method, double? receivedAmount) async {
    try {
      // Validar que tenga caja abierta antes de procesar el pago
      final canProcess = await CashRegisterValidator.validateCashRegister(
        context,
        widget.user,
        widget.businessId,
      );
      
      if (!canProcess) {
        return; // Usuario canceló o no abrió caja
      }

      // Si es efectivo y hay vuelto, calcular cambio
      double changeAmount = 0;
      if (method == PaymentMethod.cash && receivedAmount != null) {
        if (receivedAmount < invoice.total) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El monto recibido es insuficiente')),
          );
          return;
        }
        changeAmount = receivedAmount - invoice.total;
      }

      await InvoiceService.processPayment(
        invoiceId: invoice.id,
        paymentMethod: method,
        paidAmount: receivedAmount ?? invoice.total,
        processedBy: widget.user.username,
        userId: widget.user.id,
      );

      // Mostrar información del cambio si aplica
      if (changeAmount > 0) {
        _showChangeDialog(changeAmount);
      }

      // Actualizar la lista
      _loadPendingInvoices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pago procesado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error procesando pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentDialog(InvoiceModel invoice) {
    PaymentMethod selectedMethod = PaymentMethod.cash;
    final receivedController = TextEditingController(
      text: CurrencyFormatter.formatNumberOnlyNoDecimals(invoice.total),
    );
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => LayoutBuilder(
          builder: (context, constraints) {
            // Calcular dimensiones responsivas
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenWidth < 600;
            final isTinyScreen = screenWidth < 400;
            
            // Ajustar ancho del diálogo según el tamaño de pantalla
            double dialogWidth;
            if (isTinyScreen) {
              dialogWidth = screenWidth * 0.95; // 95% en pantallas muy pequeñas
            } else if (isSmallScreen) {
              dialogWidth = screenWidth * 0.85; // 85% en pantallas pequeñas
            } else {
              dialogWidth = 500; // Ancho fijo en pantallas grandes
            }
            
            // Altura máxima del contenido
            final maxContentHeight = screenHeight * 0.7;
            
            return AlertDialog(
              title: Text(
                'Procesar Pago - ${invoice.formattedNumber}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                ),
              ),
              contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: maxContentHeight,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información de la factura
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cliente: ${invoice.customerName ?? 'N/A'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              'Total: ${CurrencyFormatter.formatNoDecimals(invoice.total)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Items: ${invoice.items.length} productos',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Método de pago
                      Text(
                        'Método de Pago:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 15,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      
                      // Radio buttons con diseño compacto
                      ...PaymentMethod.values.map((method) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: RadioListTile<PaymentMethod>(
                          title: Text(
                            method.displayName,
                            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                          ),
                          value: method,
                          groupValue: selectedMethod,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedMethod = value;
                                if (value == PaymentMethod.cash) {
                                  receivedController.text = CurrencyFormatter.formatNumberOnlyNoDecimals(invoice.total);
                                }
                              });
                            }
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      )),
                      
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      
                      // Campo de efectivo (solo si está seleccionado)
                      if (selectedMethod == PaymentMethod.cash) ...[
                        Text(
                          'Dinero Recibido:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 15,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        TextFormField(
                          controller: receivedController,
                          decoration: InputDecoration(
                            labelText: 'Dinero recibido',
                            labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                            prefixText: 'RD\$ ',
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 8 : 16,
                            ),
                          ),
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                          keyboardType: TextInputType.number,
                          autofocus: true,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        if (receivedController.text.isNotEmpty)
                          _buildChangePreview(invoice.total, receivedController.text, isSmallScreen),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final receivedAmount = selectedMethod == PaymentMethod.cash
                        ? double.tryParse(receivedController.text)
                        : invoice.total;
                        
                    Navigator.pop(context);
                    _processPayment(invoice, selectedMethod, receivedAmount);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                  ),
                  child: Text(
                    'Procesar',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.all(isSmallScreen ? 8 : 16),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChangePreview(double total, String receivedText, [bool isSmallScreen = false]) {
    final received = double.tryParse(receivedText) ?? 0;
    final change = received - total;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        color: change >= 0 ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: change >= 0 ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Cambio:',
            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
          ),
          Text(
            change >= 0 ? CurrencyFormatter.formatNoDecimals(change) : 'Insuficiente',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: change >= 0 ? Colors.green[700] : Colors.red[700],
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeDialog(double changeAmount) {
    showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.payments, 
                  color: Colors.green, 
                  size: isSmallScreen ? 20 : 24),
                SizedBox(width: isSmallScreen ? 4 : 8),
                Text(
                  'Cambio',
                  style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.formatNoDecimals(changeAmount),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 16),
                Text(
                  'Entregue este cambio al cliente',
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                ),
                child: Text(
                  'Entendido',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInvoiceDetails(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Factura ${invoice.formattedNumber}'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del cliente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente: ${invoice.customerName ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Fecha: ${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}'),
                    Text('Estado: ${invoice.status.displayName}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Lista de productos
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: invoice.items.length,
                  itemBuilder: (context, index) {
                    final item = invoice.items[index];
                    return ListTile(
                      dense: true,
                      title: Text(item.productName),
                      subtitle: Text('Código: ${item.productCode}'),
                      trailing: Text(
                        '${item.quantity.toInt()} × ${CurrencyFormatter.formatNoDecimals(item.unitPrice)} = ${CurrencyFormatter.formatNoDecimals(item.subtotal)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Totales
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text(CurrencyFormatter.formatNoDecimals(invoice.subtotal)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('IVA:'),
                        Text(CurrencyFormatter.formatNoDecimals(invoice.totalTax)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormatter.formatNoDecimals(invoice.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPaymentDialog(invoice);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Procesar Pago'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Caja - Procesar Pagos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por número de factura o cliente...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: _filterInvoices,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loadPendingInvoices,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // Estadísticas rápidas
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pendientes',
                    _pendingInvoices.length.toString(),
                    Colors.orange,
                    Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total a Cobrar',
                    CurrencyFormatter.formatNoDecimals(_pendingInvoices.fold(0.0, (sum, invoice) => sum + invoice.total)),
                    Colors.green,
                    Icons.monetization_on,
                  ),
                ),
              ],
            ),
          ),

          // Lista de facturas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.green),
                            SizedBox(height: 16),
                            Text(
                              'No hay facturas pendientes de pago',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _filteredInvoices[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: invoice.status == InvoiceStatus.inCashier
                                    ? Colors.orange[300]!
                                    : Colors.blue[300]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                decoration: BoxDecoration(
                                  color: invoice.status == InvoiceStatus.inCashier
                                      ? Colors.orange[100]
                                      : Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  IconData(invoice.status.iconCodePoint, fontFamily: 'MaterialIcons'),
                                  color: Color(invoice.status.colorValue),
                                ),
                              ),
                              title: Text(
                                invoice.formattedNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cliente: ${invoice.customerName ?? 'N/A'}'),
                                  Text(
                                    '${invoice.items.length} productos - ${invoice.status.displayName}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatNoDecimals(invoice.total),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton(
                                    onPressed: () => _showPaymentDialog(invoice),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(80, 32),
                                    ),
                                    child: const Text(
                                      'Cobrar',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showInvoiceDetails(invoice),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}