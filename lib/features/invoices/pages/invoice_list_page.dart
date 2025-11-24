import 'package:flutter/material.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/invoice_service.dart';

class InvoiceListPage extends StatefulWidget {
  final UserModel user;
  final int businessId;
  
  const InvoiceListPage({
    super.key,
    required this.user,
    required this.businessId,
  });

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  InvoiceStatus? _selectedStatus;
  
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      InvoiceService.initialize();
      _invoices = await InvoiceService.getAllInvoices();
      _filteredInvoices = _invoices;
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

  void _filterInvoices() {
    setState(() {
      _filteredInvoices = _invoices.where((invoice) {
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            invoice.formattedNumber.toLowerCase().contains(searchQuery) ||
            (invoice.customerName?.toLowerCase().contains(searchQuery) ?? false);
        
        final matchesStatus = _selectedStatus == null || invoice.status == _selectedStatus;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Color _getStatusColor(InvoiceStatus status) {
    return Color(status.colorValue);
  }

  String _getStatusText(InvoiceStatus status) {
    return status.displayName;
  }

  void _showInvoiceDetails(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Factura ${invoice.formattedNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (invoice.customerName != null) Text('Cliente: ${invoice.customerName}'),
              Text('Fecha: ${invoice.formattedDate}'),
              Text('Estado: ${_getStatusText(invoice.status)}'),
              Text('Creado por: ${invoice.createdBy}'),
              const Divider(),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...invoice.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${item.productName} x${item.quantity} - ${item.unitPrice.toStringAsFixed(0)}',
                ),
              )),
              const Divider(),
              Text('Subtotal: ${invoice.formattedSubtotal}'),
              if (invoice.totalTax > 0) Text('IVA: ${invoice.formattedTotalTax}'),
              if (invoice.totalDiscount > 0) Text('Descuento: ${invoice.formattedTotalDiscount}'),
              Text(
                'Total: ${invoice.formattedTotal}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<InvoiceStatus?>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Filtrar por Estado',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<InvoiceStatus?>(
          value: null,
          child: Text('Todos los estados'),
        ),
        ...InvoiceStatus.values.map((status) {
          return DropdownMenuItem<InvoiceStatus?>(
            value: status,
            child: Text(_getStatusText(status)),
          );
        }),
      ],
      onChanged: (status) {
        setState(() {
          _selectedStatus = status;
        });
        _filterInvoices();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadInvoices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por número o cliente...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => _filterInvoices(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildStatusFilter(),
                ),
              ],
            ),
          ),
          
          // Invoice list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron facturas',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _filteredInvoices[index];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(invoice.status),
                                child: Text(
                                  invoice.items.length.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              title: Text(
                                invoice.formattedNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (invoice.customerName != null) 
                                    Text('Cliente: ${invoice.customerName}'),
                                  Text('Fecha: ${invoice.formattedDate}'),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(invoice.status).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(invoice.status),
                                          style: TextStyle(
                                            color: _getStatusColor(invoice.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    invoice.formattedTotal,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}