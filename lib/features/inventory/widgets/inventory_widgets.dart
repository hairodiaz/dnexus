import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_extensions.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/inventory_service.dart';
import '../../../core/utils/currency_formatter.dart';

// Exportar widgets adicionales
export 'inventory_dialogs.dart';
export 'inventory_stats.dart';

/// Widget de tarjeta de producto con acciones según permisos
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final UserModel user;
  final bool isMobile;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onReceiveStock;
  final BuildContext? context;

  const ProductCard({
    super.key,
    required this.product,
    required this.user,
    required this.isMobile,
    required this.onTap,
    this.onEdit,
    this.onReceiveStock,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Código: ${product.code}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildStockChip(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoColumn('Stock', product.stockDisplay),
            ),
            Expanded(
              child: _buildInfoColumn('Precio', _getPriceDisplay()),
            ),
            Expanded(
              child: _buildInfoColumn('Categoría', product.category),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Código: ${product.code}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            product.category,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.stockDisplay,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _getStockColor(),
                  fontSize: 14,
                ),
              ),
              _buildStockChip(),
            ],
          ),
        ),
        Expanded(
          child: Text(
            '\$${_formatPrice(product.salePrice)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(
          width: 160,
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStockChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(product.stockStatus.colorValue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(product.stockStatus.colorValue).withOpacity(0.3),
        ),
      ),
      child: Text(
        product.stockStatus.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(product.stockStatus.colorValue),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botones de venta (disponible para todos los roles)
        if (product.currentStock > 0)
          _buildSellButton(
            'Vender ${product.unit}',
            Icons.check,
            Colors.orange[600]!,
            false,
          ),
        if (product.hasMultipleUnits && product.fullPackages > 0)
          _buildSellButton(
            'Vender ${product.packageName ?? 'paquete'}',
            Icons.arrow_forward,
            Colors.purple[600]!,
            true,
          ),
        
        // Botón de recibir stock (solo Admin y Caja)
        if (user.hasPermission('inventory_receive') && onReceiveStock != null)
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.add,
                color: Colors.green[700],
                size: 20,
              ),
              onPressed: onReceiveStock,
              tooltip: 'Recibir Stock',
            ),
          ),
        
        // Botón de editar (solo Admin y Caja)
        if (user.hasPermission('inventory_edit') && onEdit != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.edit,
                color: Colors.blue[700],
                size: 20,
              ),
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
          ),
      ],
    );
  }

  Widget _buildSellButton(String tooltip, IconData icon, Color color, bool isPackage) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: color,
          size: 18,
        ),
        onPressed: () {
          if (context != null) {
            _showSellDialog(isPackage, context!);
          }
        },
        tooltip: tooltip,
      ),
    );
  }

  void _showSellDialog(bool isPackage, BuildContext context) {
    // TODO: Implementar diálogo de venta
    // Por ahora solo mostramos un snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vender ${isPackage ? product.packageName : product.unit} - Próximamente'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStockColor() {
    return Color(product.stockStatus.colorValue);
  }

  String _formatPrice(double price) {
    return CurrencyFormatter.formatForDashboard(price);
  }

  String _getPriceDisplay() {
    if (product.hasMultipleUnits && product.packagePrice != null) {
      return 'Unidad: ${CurrencyFormatter.formatForDashboard(product.salePrice)}\n${product.packageName}: ${CurrencyFormatter.formatForDashboard(product.packagePrice!)}';
    }
    return CurrencyFormatter.formatForDashboard(product.salePrice);
  }
}

/// Diálogo para agregar nuevo producto
class AddProductDialog extends StatefulWidget {
  final UserModel user;
  final int businessId;
  final List<String> categories;
  final VoidCallback onProductAdded;

  const AddProductDialog({
    super.key,
    required this.user,
    required this.businessId,
    required this.categories,
    required this.onProductAdded,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _supplierController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Controladores para unidades múltiples
  final _conversionFactorController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _packagePriceController = TextEditingController();
  
  String _selectedCategory = '';
  String _selectedUnit = 'Unidades';
  bool _isLoading = false;
  bool _hasMultipleUnits = false;
  bool _canSellByUnit = true;
  bool _canSellByPackage = false;

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
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
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
            Text(
              'Agregar Producto',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                              initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
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
                                  _selectedCategory = value ?? '';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecciona una categoría';
                                }
                                return null;
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
                                  _selectedUnit = value ?? 'Unidades';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
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
                                  RegExp(r'^\d+\.?\d{0,2}'),
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
                                  RegExp(r'^\d+\.?\d{0,2}'),
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
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock Inicial',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
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
                      const SizedBox(height: 16),
                      
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
                      const SizedBox(height: 24),
                      
                      // SECCIÓN: UNIDADES MÚLTIPLES
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unidades Múltiples',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '¿Se vende por unidad individual y también por empaque? (Ej: aceite por litro o por caja)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CheckboxListTile(
                              title: const Text('Producto con unidades múltiples'),
                              subtitle: Text('Ej: Caja de 12 aceites, sixpack de 6 bebidas'),
                              value: _hasMultipleUnits,
                              onChanged: (value) {
                                setState(() {
                                  _hasMultipleUnits = value ?? false;
                                  if (!_hasMultipleUnits) {
                                    _canSellByPackage = false;
                                    _conversionFactorController.clear();
                                    _packageNameController.clear();
                                    _packagePriceController.clear();
                                  }
                                });
                              },
                            ),
                            
                            if (_hasMultipleUnits) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _conversionFactorController,
                                      decoration: const InputDecoration(
                                        labelText: 'Cantidad por empaque *',
                                        hintText: 'Ej: 12 (unidades por caja)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (value) {
                                        if (_hasMultipleUnits && (value == null || value.isEmpty)) {
                                          return 'Requerido para unidades múltiples';
                                        }
                                        if (_hasMultipleUnits && int.tryParse(value!) == null) {
                                          return 'Debe ser un número';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _packageNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre del empaque *',
                                        hintText: 'Ej: caja, sixpack, blister',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (_hasMultipleUnits && (value == null || value.isEmpty)) {
                                          return 'Requerido para unidades múltiples';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _packagePriceController,
                                decoration: InputDecoration(
                                  labelText: 'Precio por empaque',
                                  hintText: 'Ej: 130000 (precio de la caja completa)',
                                  border: const OutlineInputBorder(),
                                  suffixText: 'COP',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              CheckboxListTile(
                                title: const Text('Permitir venta por unidad'),
                                subtitle: const Text('El cliente puede comprar unidades individuales'),
                                value: _canSellByUnit,
                                onChanged: (value) {
                                  setState(() {
                                    _canSellByUnit = value ?? true;
                                  });
                                },
                              ),
                              
                              CheckboxListTile(
                                title: const Text('Permitir venta por empaque'),
                                subtitle: const Text('El cliente puede comprar empaques completos'),
                                value: _canSellByPackage,
                                onChanged: (value) {
                                  setState(() {
                                    _canSellByPackage = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final product = ProductModel(
        id: 0, // Se asignará automáticamente
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        purchasePrice: double.parse(_purchasePriceController.text),
        salePrice: double.parse(_salePriceController.text),
        currentStock: int.tryParse(_stockController.text) ?? 0,
        minStock: int.parse(_minStockController.text),
        maxStock: int.parse(_maxStockController.text),
        unit: _selectedUnit,
        isActive: true,
        businessId: widget.businessId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        supplier: _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        // Campos para unidades múltiples
        conversionFactor: _hasMultipleUnits && _conversionFactorController.text.isNotEmpty 
            ? int.tryParse(_conversionFactorController.text) : null,
        packageName: _hasMultipleUnits && _packageNameController.text.isNotEmpty 
            ? _packageNameController.text.trim() : null,
        packagePrice: _hasMultipleUnits && _packagePriceController.text.isNotEmpty 
            ? double.tryParse(_packagePriceController.text) : null,
        canSellByUnit: _canSellByUnit,
        canSellByPackage: _canSellByPackage,
      );

      await InventoryService.createProduct(product, widget.user);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onProductAdded();
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