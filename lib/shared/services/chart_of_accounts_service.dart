import '../models/chart_of_accounts_model.dart';

/// Servicio para gestionar el Plan de Cuentas
class ChartOfAccountsService {
  // Lista estática para simular base de datos
  static List<ChartOfAccountsModel> _accounts = [];
  static int _nextId = 1;

  /// Obtiene todas las cuentas de un negocio
  static Future<List<ChartOfAccountsModel>> getAccountsByBusiness(int businessId) async {
    await Future.delayed(Duration.zero); // Simular async
    return _accounts.where((account) => 
      account.businessId == businessId && account.activa
    ).toList()..sort((a, b) => a.codigo.compareTo(b.codigo));
  }

  /// Obtiene las cuentas por tipo
  static Future<List<ChartOfAccountsModel>> getAccountsByType(int businessId, String tipo) async {
    await Future.delayed(Duration.zero);
    return _accounts.where((account) => 
      account.businessId == businessId && 
      account.tipo == tipo && 
      account.activa
    ).toList()..sort((a, b) => a.codigo.compareTo(b.codigo));
  }

  /// Obtiene las cuentas que aceptan movimiento
  static Future<List<ChartOfAccountsModel>> getMovementAccounts(int businessId) async {
    await Future.delayed(Duration.zero);
    return _accounts.where((account) => 
      account.businessId == businessId && 
      account.aceptaMovimiento && 
      account.activa
    ).toList()..sort((a, b) => a.codigo.compareTo(b.codigo));
  }

  /// Crea una nueva cuenta
  static Future<int> createAccount(ChartOfAccountsModel account) async {
    await Future.delayed(Duration.zero);
    final newAccount = account.copyWith(
      id: _nextId++,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _accounts.add(newAccount);
    return newAccount.id;
  }

  /// Inicializa el plan de cuentas básico para un negocio
  static Future<void> initializeBasicChartOfAccounts(int businessId) async {
    // Verificar si ya tiene cuentas
    final existingAccounts = await getAccountsByBusiness(businessId);
    if (existingAccounts.isNotEmpty) {
      return; // Ya tiene plan de cuentas
    }

    final basicAccounts = [
      // ACTIVOS
      ChartOfAccountsModel(
        id: 0, // Se asignará automáticamente
        businessId: businessId,
        codigo: '1101',
        nombre: 'CAJA',
        tipo: 'ACTIVO',
        subtipo: 'CIRCULANTE',
        nivel: 4,
        aceptaMovimiento: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ChartOfAccountsModel(
        id: 0,
        businessId: businessId,
        codigo: '1102',
        nombre: 'BANCOS',
        tipo: 'ACTIVO',
        subtipo: 'CIRCULANTE',
        nivel: 4,
        aceptaMovimiento: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // PASIVOS
      ChartOfAccountsModel(
        id: 0,
        businessId: businessId,
        codigo: '2101',
        nombre: 'CUENTAS POR PAGAR',
        tipo: 'PASIVO',
        subtipo: 'CORRIENTE',
        nivel: 4,
        aceptaMovimiento: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // PATRIMONIO
      ChartOfAccountsModel(
        id: 0,
        businessId: businessId,
        codigo: '3101',
        nombre: 'CAPITAL SOCIAL',
        tipo: 'PATRIMONIO',
        subtipo: 'CAPITAL',
        nivel: 4,
        aceptaMovimiento: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // INGRESOS
      ChartOfAccountsModel(
        id: 0,
        businessId: businessId,
        codigo: '4101',
        nombre: 'VENTAS',
        tipo: 'INGRESO',
        subtipo: 'OPERACIONAL',
        nivel: 4,
        aceptaMovimiento: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // GASTOS
      ChartOfAccountsModel(
        id: 0,
        businessId: businessId,
        codigo: '5101',
        nombre: 'GASTOS OPERACIONALES',
        tipo: 'GASTO',
        subtipo: 'OPERACIONAL',
        nivel: 4,
        aceptaMovimiento: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Insertar las cuentas básicas
    for (var account in basicAccounts) {
      await createAccount(account);
    }
  }

  /// Limpia todos los datos (para testing)
  static void clearAll() {
    _accounts.clear();
    _nextId = 1;
  }
}