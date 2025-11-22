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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16, 
        vertical: isMobile ? 6 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: isMobile 
        ? _buildCompactMobileFilters(context)
        : _buildDesktopFilters(context),
    );
  }

  /// Filtros compactos para móvil - una sola línea mejorada
  Widget _buildCompactMobileFilters(BuildContext context) {
    return Row(
      children: [
        // Icono de filtro
        Icon(
          Icons.tune,
          size: 18,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        
        // Dropdown de período (principal)
        Expanded(
          flex: 2,
          child: _buildCompactDropdown(
            context: context,
            value: selectedPeriodFilter,
            displayText: selectedPeriodFilter.displayName,
            items: TransactionPeriodFilter.values.map((filter) {
              return DropdownMenuItem<TransactionPeriodFilter>(
                value: filter,
                child: Row(
                  children: [
                    Text(filter.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        filter.displayName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => onPeriodFilterChanged(value!),
            color: Colors.blue,
          ),
        ),
        
        const SizedBox(width: 6),
        
        // Dropdown de tipo (compacto con iconos)
        Expanded(
          child: _buildCompactDropdown<TransactionTypeFilter?>(
            context: context,
            value: selectedTypeFilter,
            displayText: selectedTypeFilter == null 
              ? 'Todos' 
              : '${selectedTypeFilter!.icon} ${selectedTypeFilter!.displayName.substring(0, 3)}',
            items: [
              const DropdownMenuItem<TransactionTypeFilter?>(
                value: null,
                child: Row(
                  children: [
                    Text('📋', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text('Todos', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              ...TransactionTypeFilter.values.map((filter) {
                return DropdownMenuItem<TransactionTypeFilter?>(
                  value: filter,
                  child: Row(
                    children: [
                      Text(filter.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          filter.displayName,
                          style: const TextStyle(fontSize: 12),
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
          ),
        ),
        
        const SizedBox(width: 6),
        
        // Dropdown de pago (compacto con iconos)
        Expanded(
          child: _buildCompactDropdown<TransactionPaymentFilter?>(
            context: context,
            value: selectedPaymentFilter,
            displayText: selectedPaymentFilter == null 
              ? 'Todos' 
              : '${selectedPaymentFilter!.icon} ${selectedPaymentFilter!.displayName.substring(0, 3)}',
            items: [
              const DropdownMenuItem<TransactionPaymentFilter?>(
                value: null,
                child: Row(
                  children: [
                    Text('💳', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text('Todos', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              ...TransactionPaymentFilter.values.map((filter) {
                return DropdownMenuItem<TransactionPaymentFilter?>(
                  value: filter,
                  child: Row(
                    children: [
                      Text(filter.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          filter.displayName,
                          style: const TextStyle(fontSize: 12),
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
          ),
        ),
        
        // Botón limpiar (si hay filtros)
        if (selectedTypeFilter != null || selectedPaymentFilter != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              onTypeFilterChanged(null);
              onPaymentFilterChanged(null);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.clear,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Dropdown compacto mejorado que muestra correctamente la selección
  Widget _buildCompactDropdown<T>({
    required BuildContext context,
    required T value,
    required String displayText,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required Color color,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Filtros completos para desktop
  Widget _buildDesktopFilters(BuildContext context) {
    return Column(
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
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
        
        const SizedBox(height: 16),
        
        // Filtros en fila
        Row(
          children: [
            Expanded(child: _buildPeriodDropdown(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildTypeDropdown(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildPaymentDropdown(context)),
          ],
        ),
      ],
    );
  }



  Color _getTypeColor(TransactionTypeFilter? filter) {
    if (filter == null) return Colors.grey;
    switch (filter) {
      case TransactionTypeFilter.ingreso:
        return Colors.green;
      case TransactionTypeFilter.egreso:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentColor(TransactionPaymentFilter? filter) {
    if (filter == null) return Colors.grey;
    switch (filter) {
      case TransactionPaymentFilter.efectivo:
        return Colors.green;
      case TransactionPaymentFilter.tarjeta:
        return Colors.blue;
      case TransactionPaymentFilter.banco:
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((item) {
              return Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              );
            }).toList();
          },
          items: items,
          onChanged: onChanged,
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

}