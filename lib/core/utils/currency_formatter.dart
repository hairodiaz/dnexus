import 'package:intl/intl.dart';

/// Utilidad para formatear valores monetarios en pesos dominicanos
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_US', // Para formato correcto de comas
    symbol: 'RD\$',
    decimalDigits: 2,
  );

  static final NumberFormat _formatterNoDecimals = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'RD\$',
    decimalDigits: 0,
  );

  /// Formatea un valor double a pesos dominicanos con decimales
  /// Ejemplo: 1500.50 -> "RD$ 1,500.50"
  static String format(double value) {
    return _formatter.format(value);
  }

  /// Formatea un valor double a pesos dominicanos sin decimales
  /// Ejemplo: 1500.50 -> "RD$ 1,501"
  static String formatNoDecimals(double value) {
    return _formatterNoDecimals.format(value);
  }

  /// Formatea un valor int a pesos dominicanos sin decimales
  /// Ejemplo: 1500 -> "RD$ 1,500"
  static String formatInt(int value) {
    return _formatterNoDecimals.format(value);
  }

  /// Formatea solo el número sin el símbolo de moneda
  /// Ejemplo: 1500.50 -> "1,500.50"
  static String formatNumberOnly(double value) {
    return NumberFormat('#,##0.00', 'en_US').format(value);
  }

  /// Formatea solo el número sin decimales y sin símbolo
  /// Ejemplo: 1500.50 -> "1,501"
  static String formatNumberOnlyNoDecimals(double value) {
    return NumberFormat('#,##0', 'en_US').format(value);
  }

  /// Parsea una cadena de texto a double removiendo formato
  /// Ejemplo: "RD$ 1,500.50" -> 1500.50
  static double? parseFromFormatted(String formattedValue) {
    try {
      // Remover símbolo de moneda y espacios
      String cleanValue = formattedValue
          .replaceAll('RD\$', '')
          .replaceAll(' ', '')
          .replaceAll(',', '');
      
      return double.tryParse(cleanValue);
    } catch (e) {
      return null;
    }
  }

  /// Valida si una cadena tiene formato de moneda válido
  static bool isValidCurrency(String value) {
    return parseFromFormatted(value) != null;
  }

  /// Formatea un valor para mostrar en inputs de texto
  /// Sin símbolo pero con formato de números
  static String formatForInput(double value) {
    return NumberFormat('#,##0.00', 'en_US').format(value);
  }

  /// Formatea específicamente para facturas (con símbolo completo)
  static String formatForInvoice(double value) {
    return format(value);
  }

  /// Formatea para dashboard y estadísticas (versión compacta)
  static String formatForDashboard(double value) {
    if (value >= 1000000) {
      return 'RD\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'RD\$ ${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return formatNoDecimals(value);
    }
  }
}