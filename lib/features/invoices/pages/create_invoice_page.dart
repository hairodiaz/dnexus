import 'package:flutter/material.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/client_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/invoice_service.dart';
import '../../../shared/services/inventory_service.dart';
import '../../../shared/services/client_service.dart';

class CreateInvoicePage extends StatefulWidget {
  final UserModel user;
  final int businessId;
  
  const CreateInvoicePage({
    super.key,
    required this.user,
    required this.businessId,
  });

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  InvoiceModel? _currentInvoice;
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<ClientModel> _clients = [];
  ClientModel? _selectedClient;
  
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _products = await InventoryService.getProducts(widget.businessId);
      _filteredProducts = _products;
      _clients = ClientService().getAllClients();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewInvoice() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un cliente')),
      );
      return;
    }

    try {
      final invoice = await InvoiceService.createInvoice(
        businessId: widget.businessId.toString(),
        createdBy: widget.user.id.toString(),
        customerId: _selectedClient!.id,
        customerName: _selectedClient!.nombreCompleto,
        customerCedula: _selectedClient!.cedula,
        customerPhone: _selectedClient!.telefono,
        customerEmail: _selectedClient!.email,
      );

      setState(() {
        _currentInvoice = invoice;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creando factura: $e')),
        );
      }
    }
  }

  Future<void> _addProduct(ProductModel product) async {
    if (_currentInvoice == null) {
      await _createNewInvoice();
      if (_currentInvoice == null) return;
    }

    if (product.currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto sin stock')),
      );
      return;
    }

    try {
      final updatedInvoice = await InvoiceService.addItemToInvoice(
        invoiceId: _currentInvoice!.id,
        productId: product.id.toString(),
        quantity: 1.0,
        unit: product.unit,
      );
      
      setState(() {
        _currentInvoice = updatedInvoice;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error agregando producto: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(InvoiceItemModel item) async {
    if (_currentInvoice == null) return;

    try {
      final updatedInvoice = await InvoiceService.removeItemFromInvoice(
        invoiceId: _currentInvoice!.id,
        productId: item.productId,
        unit: item.unit,
      );
      
      setState(() {
        _currentInvoice = updatedInvoice;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando item: $e')),
        );
      }
    }
  }

  Future<void> _updateItemQuantity(InvoiceItemModel item, double quantity) async {
    if (_currentInvoice == null) return;

    if (quantity <= 0) {
      _removeItem(item);
      return;
    }

    try {
      final updatedInvoice = await InvoiceService.updateItemQuantity(
        invoiceId: _currentInvoice!.id,
        productId: item.productId,
        newQuantity: quantity,
        unit: item.unit,
      );
      
      setState(() {
        _currentInvoice = updatedInvoice;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando cantidad: $e')),
        );
      }
    }
  }

  Future<void> _sendToCashier() async {
    if (_currentInvoice == null || _currentInvoice!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue productos a la factura')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await InvoiceService.sendToCashier(_currentInvoice!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura enviada a caja exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enviando a caja: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
               product.code.toLowerCase().contains(query.toLowerCase()) ||
               product.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Factura'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_currentInvoice != null)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveInvoice,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          if (_currentInvoice != null)
            TextButton.icon(
              onPressed: _isLoading ? null : _sendToCashier,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('Enviar a Caja', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Product selection panel
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Client selection
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cliente',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<ClientModel>(
                                initialValue: _selectedClient,
                                decoration: const InputDecoration(
                                  hintText: 'Seleccionar cliente',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: _clients.map((client) {
                                  return DropdownMenuItem(
                                    value: client,
                                    child: Text('${client.name} - ${client.document}'),
                                  );
                                }).toList(),
                                onChanged: (client) {
                                  setState(() {
                                    _selectedClient = client;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Product search
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Buscar productos...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _filterProducts,
                          ),
                        ),
                        
                        // Product list
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: product.stock > 0 ? Colors.green : Colors.red,
                                  child: Text(
                                    product.stock.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                title: Text(product.name),
                                subtitle: Text(
                                  '${product.category} - \$${product.salePrice.toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  onPressed: product.stock > 0 ? () => _addProduct(product) : null,
                                  icon: const Icon(Icons.add_shopping_cart),
                                ),
                                onTap: product.stock > 0 ? () => _addProduct(product) : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Invoice details panel
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Invoice header
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentInvoice?.number ?? 'Nueva Factura',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_selectedClient != null) ...[
                              const SizedBox(height: 8),
                              Text('Cliente: ${_selectedClient!.name}'),
                              Text('Documento: ${_selectedClient!.document}'),
                            ],
                          ],
                        ),
                      ),
                      
                      // Invoice items
                      Expanded(
                        child: _currentInvoice == null || _currentInvoice!.items.isEmpty
                            ? const Center(
                                child: Text(
                                  'Agregue productos a la factura',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _currentInvoice!.items.length,
                                itemBuilder: (context, index) {
                                  final item = _currentInvoice!.items[index];
                                  return ListTile(
                                    title: Text(item.productName),
                                    subtitle: Text(
                                      '\$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _updateItemQuantity(item, item.quantity - 1),
                                          icon: const Icon(Icons.remove),
                                        ),
                                        Text(item.quantity.toString()),
                                        IconButton(
                                          onPressed: () => _updateItemQuantity(item, item.quantity + 1),
                                          icon: const Icon(Icons.add),
                                        ),
                                        IconButton(
                                          onPressed: () => _removeItem(item),
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      // Invoice totals
                      if (_currentInvoice != null)
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border(top: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:'),
                                  Text('\$${_currentInvoice!.subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('IVA:'),
                                  Text('\$${_currentInvoice!.tax.toStringAsFixed(2)}'),
                                ],
                              ),
                              if (_currentInvoice!.discount > 0)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Descuento:'),
                                    Text('-\$${_currentInvoice!.discount.toStringAsFixed(2)}'),
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
                                    '\$${_currentInvoice!.total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }
}