import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/models/client_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/invoice_service.dart';
import '../../../shared/services/client_service.dart';
import '../../../shared/services/inventory_service.dart';
import '../../../core/utils/currency_formatter.dart';

/// Página simplificada para crear facturas - Optimizada para facturadores
class CreateInvoiceSimplePage extends StatefulWidget {
  final UserModel user;
  final int businessId;

  const CreateInvoiceSimplePage({
    super.key,
    required this.user,
    required this.businessId,
  });

  @override
  State<CreateInvoiceSimplePage> createState() => _CreateInvoiceSimplePageState();
}

class _CreateInvoiceSimplePageState extends State<CreateInvoiceSimplePage> {
  final _formKey = GlobalKey<FormState>();
  final _clientSearchController = TextEditingController();
  final _productSearchController = TextEditingController();
  
  List<ClientModel> _clients = [];
  List<ProductModel> _products = [];
  List<ClientModel> _filteredClients = [];
  List<ProductModel> _filteredProducts = [];
  
  ClientModel? _selectedClient;
  List<InvoiceItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _clients = ClientService().getAllClients();
      _products = await InventoryService.getProducts(widget.businessId);
      _filteredClients = _clients;
      _filteredProducts = _products;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients.where((client) =>
          client.nombreCompleto.toLowerCase().contains(query.toLowerCase()) ||
          client.cedula.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) =>
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.code.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  void _addProduct(ProductModel product, int quantity) {
    if (quantity <= 0 || quantity > product.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cantidad inválida. Stock disponible: ${product.currentStock}')),
      );
      return;
    }

    setState(() {
      final existingIndex = _items.indexWhere((item) => item.productId == product.id.toString());
      
      if (existingIndex >= 0) {
        // Actualizar cantidad existente
        final newQuantity = _items[existingIndex].quantity + quantity;
        if (newQuantity <= product.currentStock) {
          _items[existingIndex] = _items[existingIndex].copyWith(
            quantity: newQuantity,
            // El subtotal se calcula automáticamente
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cantidad total excede el stock disponible')),
          );
          return;
        }
      } else {
        // Agregar nuevo item
        _items.add(InvoiceItemModel(
          productId: product.id.toString(),
          productName: product.name,
          productCode: product.code,
          quantity: quantity.toDouble(),
          unitPrice: product.salePrice,
          // El subtotal se calcula automáticamente
        ));
      }
    });

    _productSearchController.clear();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _tax => _subtotal * 0.19; // 19% IVA
  double get _total => _subtotal + _tax;

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate() || _selectedClient == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos requeridos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear la factura básica
      var createdInvoice = await InvoiceService.createInvoice(
        businessId: widget.businessId.toString(),
        createdBy: widget.user.username,
        customerId: _selectedClient!.id,
        customerName: _selectedClient!.nombreCompleto,
        customerCedula: _selectedClient!.cedula,
        customerPhone: _selectedClient!.telefono,
        customerEmail: _selectedClient!.email,
      );

      // Agregar items a la factura
      for (final item in _items) {
        createdInvoice = await InvoiceService.addItemToInvoice(
          invoiceId: createdInvoice.id,
          productId: item.productId,
          quantity: item.quantity,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Factura ${createdInvoice.formattedNumber} creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creando factura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Factura',
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
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildClientSection(),
                        const SizedBox(height: 24),
                        _buildProductSection(),
                        const SizedBox(height: 24),
                        _buildItemsList(),
                      ],
                    ),
                  ),
                ),
                _buildSummarySection(),
              ],
            ),
          ),
    );
  }

  Widget _buildClientSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clientSearchController,
            decoration: const InputDecoration(
              labelText: 'Buscar cliente',
              hintText: 'Nombre o documento',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filterClients,
            validator: (value) => _selectedClient == null ? 'Seleccione un cliente' : null,
          ),
          if (_selectedClient == null && _filteredClients.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _filteredClients.length,
                itemBuilder: (context, index) {
                  final client = _filteredClients[index];
                  return ListTile(
                    title: Text(client.nombreCompleto),
                    subtitle: Text('CC: ${client.cedula}'),
                    onTap: () {
                      setState(() {
                        _selectedClient = client;
                        _clientSearchController.text = client.nombreCompleto;
                      });
                    },
                  );
                },
              ),
            ),
          ],
          if (_selectedClient != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedClient!.nombreCompleto,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('CC: ${_selectedClient!.cedula}'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedClient = null;
                        _clientSearchController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text(
                'Agregar Productos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _productSearchController,
            decoration: const InputDecoration(
              labelText: 'Buscar producto',
              hintText: 'Nombre o código',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filterProducts,
          ),
          if (_productSearchController.text.isNotEmpty && _filteredProducts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código: ${product.code}'),
                        Text(
                          'Stock: ${product.currentStock} ${product.unit} - ${CurrencyFormatter.formatNoDecimals(product.salePrice)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: product.currentStock > 0
                        ? IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () => _showQuantityDialog(product),
                          )
                        : const Icon(Icons.block, color: Colors.red),
                    onTap: product.currentStock > 0
                        ? () => _showQuantityDialog(product)
                        : null,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay productos agregados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.list, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Productos Agregados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                title: Text(item.productName),
                subtitle: Text('Código: ${item.productCode}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.quantity.toInt()} × ${CurrencyFormatter.formatNoDecimals(item.unitPrice)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormatter.formatNoDecimals(item.subtotal),
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text(CurrencyFormatter.formatNoDecimals(_subtotal)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA (19%):'),
              Text(CurrencyFormatter.formatNoDecimals(_tax)),
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
                CurrencyFormatter.formatNoDecimals(_total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _items.isNotEmpty && _selectedClient != null && !_isLoading
                  ? _createInvoice
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                  : const Text(
                      'Crear Factura',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(ProductModel product) {
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock disponible: ${product.currentStock} ${product.unit}'),
            Text('Precio: ${CurrencyFormatter.formatNoDecimals(product.salePrice)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (quantity > 0) {
                _addProduct(product, quantity);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _clientSearchController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }
}