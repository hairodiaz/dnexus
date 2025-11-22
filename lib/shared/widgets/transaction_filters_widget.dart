import 'package:flutter/material.dart';
import '../enums/transaction_filter_enum.dart';

/// Widget para mostrar filtros de transacciones
class TransactionFiltersWidget extends StatelessWidget {
  final TransactionPeriodFilter selectedPeriodFilter;
  final TransactionTypeFilter selectedTypeFilter;
  final TransactionPaymentFilter selectedPaymentFilter;
  final ValueChanged<TransactionPeriodFilter> onPeriodFilterChanged;
  final ValueChanged<TransactionTypeFilter> onTypeFilterChanged;
  final ValueChanged<TransactionPaymentFilter> onPaymentFilterChanged;

  const TransactionFiltersWidget({
    super.key,
    required this.selectedPeriodFilter,
    required this.selectedTypeFilter,
    required this.selectedPaymentFilter,
    required this.onPeriodFilterChanged,
    required this.onTypeFilterChanged,
    required this.onPaymentFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros de período
          _buildSectionTitle('📅 Período'),
          const SizedBox(height: 8),
          _buildPeriodFilters(),
          
          const SizedBox(height: 16),
          
          // Filtros de tipo y método de pago en fila
          Row(
            children: [
              // Filtros de tipo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('💼 Tipo'),
                    const SizedBox(height: 8),
                    _buildTypeFilters(),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Filtros de método de pago
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('💳 Pago'),
                    const SizedBox(height: 8),
                    _buildPaymentFilters(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir título de sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }

  /// Construir filtros de período
  Widget _buildPeriodFilters() {
    return Wrap(
      spacing: 8,
      children: TransactionPeriodFilter.values.map((filter) {
        final isSelected = filter == selectedPeriodFilter;
        return FilterChip(
          label: Text(
            '${filter.icon} ${filter.displayName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onPeriodFilterChanged(filter),
          selectedColor: Colors.blue,
          backgroundColor: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  /// Construir filtros de tipo
  Widget _buildTypeFilters() {
    return Wrap(
      spacing: 6,
      children: TransactionTypeFilter.values.map((filter) {
        final isSelected = filter == selectedTypeFilter;
        return FilterChip(
          label: Text(
            '${filter.icon} ${filter.displayName}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onTypeFilterChanged(filter),
          selectedColor: _getTypeFilterColor(filter),
          backgroundColor: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  /// Construir filtros de método de pago
  Widget _buildPaymentFilters() {
    return Wrap(
      spacing: 6,
      children: TransactionPaymentFilter.values.map((filter) {
        final isSelected = filter == selectedPaymentFilter;
        return FilterChip(
          label: Text(
            '${filter.icon} ${filter.displayName}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onPaymentFilterChanged(filter),
          selectedColor: Colors.purple,
          backgroundColor: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  /// Obtener color según el tipo de filtro
  Color _getTypeFilterColor(TransactionTypeFilter filter) {
    switch (filter) {
      case TransactionTypeFilter.all:
        return Colors.grey;
      case TransactionTypeFilter.ingreso:
        return Colors.green;
      case TransactionTypeFilter.egreso:
        return Colors.red;
    }
  }
}