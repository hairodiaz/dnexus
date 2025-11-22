import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/inventory_service.dart';

/// Diálogo de estadísticas del inventario
class InventoryStatsDialog extends StatefulWidget {
  final int businessId;
  final UserModel user;

  const InventoryStatsDialog({
    Key? key,
    required this.businessId,
    required this.user,
  }) : super(key: key);

  @override
  State<InventoryStatsDialog> createState() => _InventoryStatsDialogState();
}

class _InventoryStatsDialogState extends State<InventoryStatsDialog> {
  InventoryStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await InventoryService.getInventoryStats(widget.businessId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                const Icon(Icons.analytics, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estadísticas de Inventario',
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
            
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_stats != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Estadísticas generales
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      
                      // Valor del inventario
                      _buildValueSection(),
                      const SizedBox(height: 24),
                      
                      // Alertas de stock
                      _buildAlertsSection(),
                    ],
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text('No se pudieron cargar las estadísticas'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _stats!;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Productos',
          stats.totalProducts.toString(),
          Icons.inventory_2,
          Colors.blue,
        ),
        _buildStatCard(
          'Stock Bajo',
          stats.lowStockProducts.toString(),
          Icons.warning,
          Colors.orange,
        ),
        _buildStatCard(
          'Agotados',
          stats.outOfStockProducts.toString(),
          Icons.remove_circle,
          Colors.red,
        ),
        _buildStatCard(
          'Margen',
          '${stats.profitMargin.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValueSection() {
    final stats = _stats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valorización del Inventario',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              _buildValueRow(
                'Valor de Compra',
                '\$${_formatNumber(stats.totalInventoryValue)}',
                Colors.blue[700]!,
              ),
              const SizedBox(height: 8),
              _buildValueRow(
                'Valor de Venta',
                '\$${_formatNumber(stats.totalSaleValue)}',
                Colors.green[700]!,
              ),
              const Divider(),
              _buildValueRow(
                'Ganancia Potencial',
                '\$${_formatNumber(stats.potentialProfit)}',
                Colors.green[800]!,
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValueRow(String label, String value, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection() {
    final stats = _stats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertas de Stock',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (stats.outOfStockProducts > 0)
          _buildAlertCard(
            '${stats.outOfStockProducts} productos agotados',
            'Requieren reposición inmediata',
            Icons.error,
            Colors.red,
          ),
        
        if (stats.lowStockProducts > 0)
          _buildAlertCard(
            '${stats.lowStockProducts} productos con stock bajo',
            'Considerar realizar pedidos',
            Icons.warning,
            Colors.orange,
          ),
        
        if (stats.outOfStockProducts == 0 && stats.lowStockProducts == 0)
          _buildAlertCard(
            'Stock en buen estado',
            'No hay alertas críticas',
            Icons.check_circle,
            Colors.green,
          ),
      ],
    );
  }

  Widget _buildAlertCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }
}

/// Página para ver movimientos de inventario
class InventoryMovementsPage extends StatefulWidget {
  final int businessId;
  final UserModel user;

  const InventoryMovementsPage({
    Key? key,
    required this.businessId,
    required this.user,
  }) : super(key: key);

  @override
  State<InventoryMovementsPage> createState() => _InventoryMovementsPageState();
}

class _InventoryMovementsPageState extends State<InventoryMovementsPage> {
  List<InventoryMovement> _movements = [];
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        InventoryService.getAllMovements(widget.businessId),
        InventoryService.getProducts(widget.businessId),
      ]);
      
      final movements = results[0] as List<InventoryMovement>;
      final products = results[1] as List<ProductModel>;

      if (mounted) {
        setState(() {
          _movements = movements;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar movimientos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos de Inventario'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMovements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movements.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay movimientos registrados',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMovements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _movements.length,
                    itemBuilder: (context, index) {
                      final movement = _movements[index];
                      final product = _products.firstWhere(
                        (p) => p.id == movement.productId,
                        orElse: () => ProductModel(
                          id: 0,
                          code: 'N/A',
                          name: 'Producto no encontrado',
                          description: '',
                          category: '',
                          purchasePrice: 0,
                          salePrice: 0,
                          currentStock: 0,
                          minStock: 0,
                          maxStock: 0,
                          unit: '',
                          isActive: false,
                          businessId: 0,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );

                      return _buildMovementCard(movement, product);
                    },
                  ),
                ),
    );
  }

  Widget _buildMovementCard(InventoryMovement movement, ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(movement.type.colorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMovementIcon(movement.type),
                    color: Color(movement.type.colorValue),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                      ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(movement.type.colorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(movement.type.colorValue).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    movement.type.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(movement.type.colorValue),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn('Cantidad', 
                    '${_getQuantitySign(movement.type)}${movement.quantity} ${product.unit}'),
                ),
                Expanded(
                  child: _buildInfoColumn('Precio Unit.', 
                    '\$${_formatNumber(movement.unitPrice)}'),
                ),
                Expanded(
                  child: _buildInfoColumn('Valor Total', 
                    '\$${_formatNumber(movement.totalValue)}'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn('Motivo', movement.reason),
                ),
                if (movement.reference != null)
                  Expanded(
                    child: _buildInfoColumn('Referencia', movement.reference!),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateTime(movement.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Usuario ID: ${movement.userId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  IconData _getMovementIcon(MovementType type) {
    switch (type) {
      case MovementType.entry:
        return Icons.add_box;
      case MovementType.exit:
        return Icons.remove_circle_outline;
      case MovementType.adjustment:
        return Icons.tune;
      case MovementType.transfer:
        return Icons.swap_horiz;
    }
  }

  String _getQuantitySign(MovementType type) {
    switch (type) {
      case MovementType.entry:
        return '+';
      case MovementType.exit:
        return '-';
      case MovementType.adjustment:
      case MovementType.transfer:
        return '';
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}