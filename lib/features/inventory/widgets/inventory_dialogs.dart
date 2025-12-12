import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/inventory_service.dart';
import '../../../shared/widgets/permission_widgets.dart';

/// Diálogo para editar producto existente
class EditProductDialog extends StatefulWidget {
  final ProductModel product;
  final UserModel user;
  final List<String> categories;
  final VoidCallback onProductUpdated;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.user,
    required this.categories,
    required this.onProductUpdated,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _minStockController;
  late final TextEditingController _maxStockController;
  late final TextEditingController _supplierController;
  late final TextEditingController _locationController;
  
  late String _selectedCategory;
  late String _selectedUnit;
  bool _isLoading = false;

  final List<String> _units = [
    'Unidades',
    'Litros',
    'Kilogramos',
    'Metros',
    'Cajas',
    'Paquetes',
  ];

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.product.code);
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _purchasePriceController = TextEditingController(text: widget.product.purchasePrice.toString());
    _salePriceController = TextEditingController(text: widget.product.salePrice.toString());
    _minStockController = TextEditingController(text: widget.product.minStock.toString());
    _maxStockController = TextEditingController(text: widget.product.maxStock.toString());
    _supplierController = TextEditingController(text: widget.product.supplier ?? '');
    _locationController = TextEditingController(text: widget.product.location ?? '');
    
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _supplierController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Editar Producto',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Información básica
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: 'Código *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa el código';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa el nombre';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Categoría *',
                                border: OutlineInputBorder(),
                              ),
                              items: widget.categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? _selectedCategory;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unidad *',
                                border: OutlineInputBorder(),
                              ),
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value ?? _selectedUnit;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Precios
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _purchasePriceController,
                              decoration: const InputDecoration(
                                labelText: 'Precio Compra *',
                                border: OutlineInputBorder(),
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\\d+\\.?\\d{0,2}'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa el precio';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Precio inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _salePriceController,
                              decoration: const InputDecoration(
                                labelText: 'Precio Venta *',
                                border: OutlineInputBorder(),
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\\d+\\.?\\d{0,2}'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa el precio';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Precio inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Stock
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock Actual: ${widget.product.currentStock} ${widget.product.unit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Para cambiar el stock actual, usa la función "Recibir Stock" o "Ajustar Stock"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _minStockController,
                                    decoration: const InputDecoration(
                                      labelText: 'Stock Mínimo *',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requerido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _maxStockController,
                                    decoration: const InputDecoration(
                                      labelText: 'Stock Máximo *',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requerido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Información adicional
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _supplierController,
                              decoration: const InputDecoration(
                                labelText: 'Proveedor',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Ubicación',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón eliminar (solo Admin)
                PermissionWidget(
                  user: widget.user,
                  allowedRoles: const [UserRole.admin, UserRole.superAdmin],
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _deleteProduct,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                
                // Botones principales
                Row(
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProduct,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Actualizar'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProduct = widget.product.copyWith(
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        purchasePrice: double.parse(_purchasePriceController.text),
        salePrice: double.parse(_salePriceController.text),
        minStock: int.parse(_minStockController.text),
        maxStock: int.parse(_maxStockController.text),
        unit: _selectedUnit,
        supplier: _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      );

      await InventoryService.updateProduct(updatedProduct, widget.user);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onProductUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    // Confirmar eliminación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "${widget.product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await InventoryService.deleteProduct(widget.product.id, widget.user);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onProductUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Diálogo para recibir stock (entrada de mercancía)
class ReceiveStockDialog extends StatefulWidget {
  final ProductModel product;
  final UserModel user;
  final VoidCallback onStockReceived;

  const ReceiveStockDialog({
    super.key,
    required this.product,
    required this.user,
    required this.onStockReceived,
  });

  @override
  State<ReceiveStockDialog> createState() => _ReceiveStockDialogState();
}

class _ReceiveStockDialogState extends State<ReceiveStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _reasonController = TextEditingController(text: 'Recepción de mercancía');
  final _referenceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.product.purchasePrice.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _reasonController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recibir Stock',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Información del producto
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('Código: ${widget.product.code}'),
                  Text('Stock actual: ${widget.product.currentStock} ${widget.product.unit}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad a recibir *',
                      border: const OutlineInputBorder(),
                      suffixText: widget.product.unit,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa la cantidad';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio unitario *',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\\d+\\.?\\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa el precio';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Precio inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa el motivo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Referencia (Factura, Orden)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _receiveStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Recibir Stock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _receiveStock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      final reason = _reasonController.text.trim();
      final reference = _referenceController.text.trim().isNotEmpty 
          ? _referenceController.text.trim() 
          : null;

      await InventoryService.receiveStock(
        widget.product.id,
        quantity,
        price,
        reason,
        widget.user,
        reference: reference,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock recibido: +$quantity ${widget.product.unit}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStockReceived();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Diálogo de detalles del producto
class ProductDetailDialog extends StatelessWidget {
  final ProductModel product;
  final UserModel user;
  final VoidCallback? onEdit;
  final VoidCallback? onReceiveStock;

  const ProductDetailDialog({
    super.key,
    required this.product,
    required this.user,
    this.onEdit,
    this.onReceiveStock,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Estado del stock
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(product.stockStatus.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(product.stockStatus.colorValue).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStockIcon(),
                    color: Color(product.stockStatus.colorValue),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.currentStock} ${product.unit}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(product.stockStatus.colorValue),
                          ),
                        ),
                        Text(
                          product.stockStatus.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(product.stockStatus.colorValue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection('Información General', [
                      _InfoRow('Código', product.code),
                      _InfoRow('Descripción', product.description),
                      _InfoRow('Categoría', product.category),
                      _InfoRow('Unidad', product.unit),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoSection('Precios y Rentabilidad', [
                      _InfoRow('Precio Compra', '\$${_formatNumber(product.purchasePrice)}'),
                      _InfoRow('Precio Venta', '\$${_formatNumber(product.salePrice)}'),
                      _InfoRow('Margen', '${product.profitMargin.toStringAsFixed(1)}%'),
                      _InfoRow('Valor Inventario', '\$${_formatNumber(product.totalInventoryValue)}'),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoSection('Control de Stock', [
                      _InfoRow('Stock Actual', '${product.currentStock} ${product.unit}'),
                      _InfoRow('Stock Mínimo', '${product.minStock} ${product.unit}'),
                      _InfoRow('Stock Máximo', '${product.maxStock} ${product.unit}'),
                    ]),
                    
                    if (product.supplier != null || product.location != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoSection('Información Adicional', [
                        if (product.supplier != null) _InfoRow('Proveedor', product.supplier!),
                        if (product.location != null) _InfoRow('Ubicación', product.location!),
                      ]),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoSection('Fechas', [
                      _InfoRow('Creado', _formatDate(product.createdAt)),
                      _InfoRow('Actualizado', _formatDate(product.updatedAt)),
                    ]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              children: [
                PermissionWidget(
                  user: user,
                  requiredPermission: 'inventory_receive',
                  child: Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onReceiveStock?.call();
                      },
                      icon: const Icon(Icons.add_box),
                      label: const Text('Recibir Stock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PermissionWidget(
                  user: user,
                  requiredPermission: 'inventory_edit',
                  child: Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit?.call();
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: rows.map((row) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${row.label}:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getStockIcon() {
    switch (product.stockStatus) {
      case StockStatus.outOfStock:
        return Icons.remove_circle;
      case StockStatus.lowStock:
        return Icons.warning;
      case StockStatus.excessStock:
        return Icons.trending_up;
      case StockStatus.normal:
        return Icons.check_circle;
    }
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}