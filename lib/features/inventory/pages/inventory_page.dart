import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_extensions.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/inventory_service.dart';
import '../../../shared/widgets/permission_widgets.dart';
import '../widgets/inventory_widgets.dart';

/// Página principal de inventario con control de permisos por rol
class InventoryPage extends StatefulWidget {
  final UserModel user;
  final int businessId;

  const InventoryPage({
    super.key,
    required this.user,
    required this.businessId,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with TickerProviderStateMixin, PermissionMixin {
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<String> _categories = [];
  String _selectedCategory = 'Todas';
  bool _isLoading = true;
  bool _showOnlyLowStock = false;
  bool _showOnlyOutOfStock = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInventoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryData() async {
    setState(() => _isLoading = true);
    
    try {
      // Inicializar datos de ejemplo si es necesario
      InventoryService.initializeWithSampleData(widget.businessId);
      
      final results = await Future.wait([
        InventoryService.getProducts(widget.businessId),
        InventoryService.getCategories(widget.businessId),
      ]);
      
      final products = results[0] as List<ProductModel>;
      final categories = results[1] as List<String>;

      setState(() {
        _products = products;
        _filteredProducts = products;
        _categories = ['Todas', ...categories];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar inventario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredProducts = _products.where((product) {
        // Filtro por texto
        bool matchesSearch = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.code.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);

        // Filtro por categoría
        bool matchesCategory = _selectedCategory == 'Todas' ||
            product.category == _selectedCategory;

        // Filtros de stock
        bool matchesStockFilter = true;
        if (_showOnlyLowStock) {
          matchesStockFilter = product.isLowStock;
        } else if (_showOnlyOutOfStock) {
          matchesStockFilter = product.isOutOfStock;
        }

        return matchesSearch && matchesCategory && matchesStockFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Solo mostrar botón de agregar si tiene permisos
          PermissionWidget(
            user: widget.user,
            requiredPermission: 'inventory_create',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddProductDialog,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _loadInventoryData();
                  break;
                case 'stats':
                  _showInventoryStats();
                  break;
                case 'movements':
                  _showInventoryMovements();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Actualizar'),
                  ],
                ),
              ),
              if (widget.user.hasPermission('reports_view'))
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('Estadísticas'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'movements',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Movimientos'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Productos', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Stock Bajo', icon: Icon(Icons.warning)),
            Tab(text: 'Agotados', icon: Icon(Icons.remove_circle)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(isMobile),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsList(_filteredProducts),
                _buildLowStockTab(),
                _buildOutOfStockTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, código o categoría...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterProducts();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => _filterProducts(),
          ),
          
          const SizedBox(height: 12),
          
          // Filtros
          Row(
            children: [
              // Filtro de categoría
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'Todas';
                    });
                    _filterProducts();
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Filtros de stock
              if (!isMobile) ...[
                FilterChip(
                  label: const Text('Stock Bajo'),
                  selected: _showOnlyLowStock,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyLowStock = selected;
                      if (selected) _showOnlyOutOfStock = false;
                    });
                    _filterProducts();
                  },
                  selectedColor: Colors.orange[100],
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Agotados'),
                  selected: _showOnlyOutOfStock,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyOutOfStock = selected;
                      if (selected) _showOnlyLowStock = false;
                    });
                    _filterProducts();
                  },
                  selectedColor: Colors.red[100],
                ),
              ],
            ],
          ),
          
          // Filtros móviles
          if (isMobile) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text('Stock Bajo'),
                    selected: _showOnlyLowStock,
                    onSelected: (selected) {
                      setState(() {
                        _showOnlyLowStock = selected;
                        if (selected) _showOnlyOutOfStock = false;
                      });
                      _filterProducts();
                    },
                    selectedColor: Colors.orange[100],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Agotados'),
                    selected: _showOnlyOutOfStock,
                    onSelected: (selected) {
                      setState(() {
                        _showOnlyOutOfStock = selected;
                        if (selected) _showOnlyLowStock = false;
                      });
                      _filterProducts();
                    },
                    selectedColor: Colors.red[100],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsList(List<ProductModel> products) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            PermissionWidget(
              user: widget.user,
              requiredPermission: 'inventory_create',
              child: ElevatedButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Producto'),
              ),
            ),
          ],
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: _loadInventoryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            user: widget.user,
            isMobile: isMobile,
            context: context,
            onTap: () => _showProductDetails(product),
            onEdit: () => _showEditProductDialog(product),
            onReceiveStock: () => _showReceiveStockDialog(product),
          );
        },
      ),
    );
  }

  Widget _buildLowStockTab() {
    return FutureBuilder<List<ProductModel>>(
      future: InventoryService.getLowStockProducts(widget.businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];
        
        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay productos con stock bajo',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        return _buildProductsList(products);
      },
    );
  }

  Widget _buildOutOfStockTab() {
    return FutureBuilder<List<ProductModel>>(
      future: InventoryService.getOutOfStockProducts(widget.businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];
        
        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay productos agotados',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        return _buildProductsList(products);
      },
    );
  }

  void _showAddProductDialog() {
    if (!checkPermissionOrError(context, widget.user, 'inventory_create')) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        user: widget.user,
        businessId: widget.businessId,
        categories: _categories.where((c) => c != 'Todas').toList(),
        onProductAdded: () {
          _loadInventoryData();
        },
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    if (!checkPermissionOrError(context, widget.user, 'inventory_edit')) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EditProductDialog(
        product: product,
        user: widget.user,
        categories: _categories.where((c) => c != 'Todas').toList(),
        onProductUpdated: () {
          _loadInventoryData();
        },
      ),
    );
  }

  void _showReceiveStockDialog(ProductModel product) {
    if (!checkPermissionOrError(context, widget.user, 'inventory_receive')) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReceiveStockDialog(
        product: product,
        user: widget.user,
        onStockReceived: () {
          _loadInventoryData();
        },
      ),
    );
  }

  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailDialog(
        product: product,
        user: widget.user,
        onEdit: () => _showEditProductDialog(product),
        onReceiveStock: () => _showReceiveStockDialog(product),
      ),
    );
  }

  void _showInventoryStats() {
    showDialog(
      context: context,
      builder: (context) => InventoryStatsDialog(
        businessId: widget.businessId,
        user: widget.user,
      ),
    );
  }

  void _showInventoryMovements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryMovementsPage(
          businessId: widget.businessId,
          user: widget.user,
        ),
      ),
    );
  }
}