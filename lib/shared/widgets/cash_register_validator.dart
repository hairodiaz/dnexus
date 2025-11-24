import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_extensions.dart';
import '../services/cash_register_service.dart';
import '../../features/cash_register/pages/cash_register_page.dart';

/// Widget para validar que el usuario tenga caja abierta antes de procesar pagos
class CashRegisterValidator extends StatelessWidget {
  final UserModel user;
  final int businessId;
  final Widget child;
  final VoidCallback? onCashRequired;

  const CashRegisterValidator({
    super.key,
    required this.user,
    required this.businessId,
    required this.child,
    this.onCashRequired,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// Valida si el usuario puede procesar pagos y muestra diálogo si no
  static Future<bool> validateCashRegister(
    BuildContext context,
    UserModel user,
    int businessId,
  ) async {
    // Solo validar para roles que manejan dinero
    if (!user.canHandleMoney) {
      return true; // Usuario no necesita caja abierta
    }

    final canProcess = CashRegisterService.canProcessPayments(user.id);
    
    if (!canProcess) {
      final shouldOpenCash = await _showCashRequiredDialog(context, user, businessId);
      return shouldOpenCash;
    }
    
    return true;
  }

  /// Muestra diálogo informando que necesita caja abierta
  static Future<bool> _showCashRequiredDialog(
    BuildContext context,
    UserModel user,
    int businessId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Caja Registradora Requerida',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para procesar pagos y cobrar facturas necesitas tener una caja registradora abierta.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo puedes tener una caja abierta a la vez. Al abrirla podrás procesar pagos hasta que la cierres al final del turno.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Abrir Caja'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      // Navegar a la página de caja registradora
      if (context.mounted) {
        final opened = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => CashRegisterPage(
              user: user,
              businessId: businessId,
            ),
          ),
        );
        return opened ?? false;
      }
    }

    return false;
  }
}

/// Mixin para páginas que requieren validación de caja
mixin CashRegisterValidationMixin<T extends StatefulWidget> on State<T> {
  
  /// Valida caja antes de ejecutar una acción
  Future<bool> validateCashRegisterForAction(
    UserModel user,
    int businessId,
  ) async {
    return await CashRegisterValidator.validateCashRegister(
      context,
      user,
      businessId,
    );
  }

  /// Ejecuta una acción solo si la validación de caja es exitosa
  Future<void> executeWithCashValidation(
    UserModel user,
    int businessId,
    VoidCallback action,
  ) async {
    final isValid = await validateCashRegisterForAction(user, businessId);
    if (isValid) {
      action();
    }
  }
}