import 'package:flutter/material.dart';
import '../enums/transaction_filter_enum.dart';

/// Widget para mostrar filtros de transacciones optimizado para móvil
class TransactionFiltersWidget extends StatelessWidget {
  final TransactionPeriodFilter selectedPeriodFilter;
  final TransactionTypeFilter? selectedTypeFilter;
  final TransactionPaymentFilter? selectedPaymentFilter;
  final ValueChanged<TransactionPeriodFilter> onPeriodFilterChanged;
  final ValueChanged<TransactionTypeFilter?> onTypeFilterChanged;
  final ValueChanged<TransactionPaymentFilter?> onPaymentFilterChanged;

  const TransactionFiltersWidget({
    super.key,
    required this.selectedPeriodFilter,
    this.selectedTypeFilter,
    this.selectedPaymentFilter,
    required this.onPeriodFilterChanged,
    required this.onTypeFilterChanged,
    required this.onPaymentFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Detectar si es móvil
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.all(isMobile ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título de filtros
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (selectedTypeFilter != null || selectedPaymentFilter != null)
                TextButton.icon(
                  onPressed: () {
                    onTypeFilterChanged(null);
                    onPaymentFilterChanged(null);
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: isMobile ? 12 : 16),
          
          // Layout responsive: columna en móvil, fila en desktop
          isMobile
              ? Column(
                  children: [
                    _buildPeriodDropdown(context),
                    const SizedBox(height: 12),
                    _buildTypeDropdown(context),
                    const SizedBox(height: 12),
                    _buildPaymentDropdown(context),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildPeriodDropdown(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTypeDropdown(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPaymentDropdown(context)),
                  ],
                ),
        ],
      ),
    );
  }

  /// Construir dropdown de período
  Widget _buildPeriodDropdown(BuildContext context) {
    return _buildDropdown(
      context: context,
      label: 'Período',
      icon: Icons.date_range,
      value: selectedPeriodFilter.displayName,
      items: TransactionPeriodFilter.values.map((filter) {
        return DropdownMenuItem<TransactionPeriodFilter>(
          value: filter,
          child: Row(
            children: [
              Text(filter.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filter.displayName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => onPeriodFilterChanged(value!),
      color: Colors.blue,
    );
  }

  /// Construir dropdown de tipo
  Widget _buildTypeDropdown(BuildContext context) {
    return _buildDropdown(
      context: context,
      label: 'Tipo',
      icon: Icons.category,
      value: selectedTypeFilter?.displayName ?? 'Todos',
      items: [
        const DropdownMenuItem<TransactionTypeFilter?>(
          value: null,
          child: Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('Todos', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        ...TransactionTypeFilter.values.map((filter) {
          return DropdownMenuItem<TransactionTypeFilter?>(
            value: filter,
            child: Row(
              children: [
                Text(filter.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filter.displayName,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) => onTypeFilterChanged(value),
      color: _getTypeColor(selectedTypeFilter),
    );
  }

  /// Construir dropdown de método de pago
  Widget _buildPaymentDropdown(BuildContext context) {
    return _buildDropdown(
      context: context,
      label: 'Método de Pago',
      icon: Icons.payment,
      value: selectedPaymentFilter?.displayName ?? 'Todos',
      items: [
        const DropdownMenuItem<TransactionPaymentFilter?>(
          value: null,
          child: Row(
            children: [
              Text('💳', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('Todos', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        ...TransactionPaymentFilter.values.map((filter) {
          return DropdownMenuItem<TransactionPaymentFilter?>(
            value: filter,
            child: Row(
              children: [
                Text(filter.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filter.displayName,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) => onPaymentFilterChanged(value),
      color: _getPaymentColor(selectedPaymentFilter),
    );
  }

  /// Widget base para dropdowns
  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required Color color,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: items.any((item) => item.value.toString() == value) 
              ? items.firstWhere((item) => item.value.toString() == value).value
              : items.first.value,
          items: items,
          onChanged: onChanged,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: isMobile ? 13 : 14,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          icon: Icon(
            Icons.arrow_drop_down,
            color: color,
            size: isMobile ? 20 : 24,
          ),
        ),
      ),
    );
  }

  /// Obtener color según el tipo de filtro
  Color _getTypeColor(TransactionTypeFilter? filter) {
    if (filter == null) return Colors.grey;
    switch (filter) {
      case TransactionTypeFilter.all:
        return Colors.grey;
      case TransactionTypeFilter.ingreso:
        return Colors.green;
      case TransactionTypeFilter.egreso:
        return Colors.red;
    }
  }

  /// Obtener color según el método de pago
  Color _getPaymentColor(TransactionPaymentFilter? filter) {
    if (filter == null) return Colors.grey;
    switch (filter) {
      case TransactionPaymentFilter.all:
        return Colors.grey;
      case TransactionPaymentFilter.efectivo:
        return Colors.green;
      case TransactionPaymentFilter.banco:
        return Colors.blue;
      case TransactionPaymentFilter.tarjeta:
        return Colors.purple;
    }
  }
}