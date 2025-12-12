import 'package:flutter/material.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/transaction_service.dart';

/// Formulario para editar transacción existente
class EditTransactionPage extends StatefulWidget {
  final BusinessModel business;
  final TransactionModel transaction;
  final int userId;
  final String? userFullName;

  const EditTransactionPage({
    super.key,
    required this.business,
    required this.transaction,
    required this.userId,
    this.userFullName,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _transactionService = TransactionService();
  
  // Controladores de formulario
  final _montoController = TextEditingController();
  final _conceptoController = TextEditingController();
  final _clienteController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _reasonController = TextEditingController();
  
  // Variables de estado
  String _tipoSeleccionado = 'ingreso';
  String? _categoriaSeleccionada;
  String _metodoPagoSeleccionado = 'efectivo';
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactionData();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    _clienteController.dispose();
    _observacionesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Cargar datos de la transacción a editar
  void _loadTransactionData() {
    _montoController.text = widget.transaction.monto.toString();
    _conceptoController.text = widget.transaction.concepto;
    _clienteController.text = widget.transaction.cliente ?? '';
    _observacionesController.text = widget.transaction.observaciones ?? '';
    
    _tipoSeleccionado = widget.transaction.tipo;
    _categoriaSeleccionada = widget.transaction.categoria;
    _metodoPagoSeleccionado = widget.transaction.metodoPago;
    _fechaSeleccionada = widget.transaction.fecha;
  }

  /// Obtener categorías según tipo de negocio y tipo de transacción
  List<String> get _categoriasDisponibles {
    return TransactionModel.getCategoriasPorTipo(widget.business.tipo, _tipoSeleccionado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Transacción'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _guardarCambios,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con info del negocio y transacción
              _buildTransactionHeader(),
              
              const SizedBox(height: 24),
              
              // Tipo de transacción (Ingreso/Egreso)
              _buildTipoTransaccionSelector(),
              
              const SizedBox(height: 20),
              
              // Monto
              _buildMontoField(),
              
              const SizedBox(height: 20),
              
              // Concepto
              _buildConceptoField(),
              
              const SizedBox(height: 20),
              
              // Categoría
              _buildCategoriaDropdown(),
              
              const SizedBox(height: 20),
              
              // Cliente (especialmente para préstamos)
              _buildClienteField(),
              
              const SizedBox(height: 20),
              
              // Método de pago
              _buildMetodoPagoDropdown(),
              
              const SizedBox(height: 20),
              
              // Fecha
              _buildFechaSelector(),
              
              const SizedBox(height: 20),
              
              // Observaciones
              _buildObservacionesField(),
              
              const SizedBox(height: 24),
              
              // Motivo del cambio (OBLIGATORIO)
              _buildMotivoField(),
              
              const SizedBox(height: 32),
              
              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Header con información del negocio y transacción original
  Widget _buildTransactionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                color: Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editando Transacción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      '${widget.business.nombre} • ID: ${widget.transaction.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Text(
                  'Original: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${widget.transaction.concepto} • ${widget.transaction.montoFormateado}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Selector de tipo de transacción
  Widget _buildTipoTransaccionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Transacción',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _tipoSeleccionado = 'ingreso';
                  _categoriaSeleccionada = null; // Reset categoría
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _tipoSeleccionado == 'ingreso' 
                        ? Colors.green[100] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _tipoSeleccionado == 'ingreso' 
                          ? Colors.green 
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: _tipoSeleccionado == 'ingreso' 
                            ? Colors.green[700] 
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ingreso',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _tipoSeleccionado == 'ingreso' 
                              ? Colors.green[700] 
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _tipoSeleccionado = 'egreso';
                  _categoriaSeleccionada = null; // Reset categoría
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _tipoSeleccionado == 'egreso' 
                        ? Colors.red[100] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _tipoSeleccionado == 'egreso' 
                          ? Colors.red 
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.remove_circle,
                        color: _tipoSeleccionado == 'egreso' 
                            ? Colors.red[700] 
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Egreso',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _tipoSeleccionado == 'egreso' 
                              ? Colors.red[700] 
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Campo de monto
  Widget _buildMontoField() {
    return TextFormField(
      controller: _montoController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Monto *',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El monto es obligatorio';
        }
        final monto = double.tryParse(value.trim());
        if (monto == null || monto <= 0) {
          return 'Ingrese un monto válido mayor a 0';
        }
        return null;
      },
    );
  }

  /// Campo de concepto
  Widget _buildConceptoField() {
    return TextFormField(
      controller: _conceptoController,
      decoration: InputDecoration(
        labelText: 'Concepto *',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'Ej: Venta de producto, Pago de préstamo...',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El concepto es obligatorio';
        }
        return null;
      },
    );
  }

  /// Dropdown de categoría
  Widget _buildCategoriaDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _categoriaSeleccionada,
      decoration: InputDecoration(
        labelText: 'Categoría *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _categoriasDisponibles.map((categoria) {
        return DropdownMenuItem<String>(
          value: categoria,
          child: Text(categoria),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _categoriaSeleccionada = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione una categoría';
        }
        return null;
      },
    );
  }

  /// Campo de cliente (condicional)
  Widget _buildClienteField() {
    // Mostrar especialmente para préstamos
    final showCliente = widget.business.tipo == 'prestamos' || 
                       _tipoSeleccionado == 'ingreso';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCliente) ...[
          TextFormField(
            controller: _clienteController,
            decoration: InputDecoration(
              labelText: widget.business.tipo == 'prestamos' ? 'Cliente/Prestatario' : 'Cliente',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'Nombre del cliente',
            ),
          ),
        ],
      ],
    );
  }

  /// Dropdown de método de pago
  Widget _buildMetodoPagoDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _metodoPagoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Método de Pago *',
        prefixIcon: const Icon(Icons.payment),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: TransactionModel.metodosPago.map((metodo) {
        return DropdownMenuItem<String>(
          value: metodo,
          child: Text(TransactionModel(
            id: 0,
            tipo: 'ingreso',
            monto: 0,
            concepto: '',
            categoria: '',
            metodoPago: metodo,
            fecha: DateTime.now(),
            negocioId: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).metodoPagoDescripcion),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _metodoPagoSeleccionado = value!;
        });
      },
    );
  }

  /// Selector de fecha
  Widget _buildFechaSelector() {
    return InkWell(
      onTap: _seleccionarFecha,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha *',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: Text(
          '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Campo de observaciones
  Widget _buildObservacionesField() {
    return TextFormField(
      controller: _observacionesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Observaciones (opcional)',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'Información adicional sobre la transacción...',
      ),
    );
  }

  /// Campo de motivo (OBLIGATORIO para edición)
  Widget _buildMotivoField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Motivo de la Edición',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Motivo *',
              hintText: 'Explique por qué está editando esta transacción...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El motivo de la edición es obligatorio';
              }
              if (value.trim().length < 10) {
                return 'El motivo debe tener al menos 10 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Botones de acción
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                : const Text('Guardar Cambios'),
          ),
        ),
      ],
    );
  }

  /// Seleccionar fecha
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('es', 'ES'),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  /// Guardar cambios
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final monto = double.parse(_montoController.text.trim());
      
      final updates = {
        'tipo': _tipoSeleccionado,
        'monto': monto,
        'concepto': _conceptoController.text.trim(),
        'categoria': _categoriaSeleccionada!,
        'metodoPago': _metodoPagoSeleccionado,
        'cliente': _clienteController.text.trim().isNotEmpty 
            ? _clienteController.text.trim() 
            : null,
        'fecha': _fechaSeleccionada,
        'observaciones': _observacionesController.text.trim().isNotEmpty 
            ? _observacionesController.text.trim() 
            : null,
      };
      
      await _transactionService.updateTransaction(
        widget.transaction.id,
        updates,
        widget.userId,
        _reasonController.text.trim(),
        userFullName: widget.userFullName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción actualizada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}