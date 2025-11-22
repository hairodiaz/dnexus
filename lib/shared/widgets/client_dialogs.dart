import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/models/client_model.dart';
import '../../shared/services/client_service.dart';

/// Diálogo para agregar nuevo cliente
class AddClientDialog extends StatefulWidget {
  final Function(ClientModel) onClientAdded;

  const AddClientDialog({
    super.key,
    required this.onClientAdded,
  });

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();
  
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  
  String? _selectedBusiness;
  bool _isLoading = false;

  final List<Map<String, String>> _businesses = [
    {'value': 'repuestos', 'label': 'AutoRepuestos'},
    {'value': 'electrodomesticos', 'label': 'Electrodomésticos'},
    {'value': 'prestamos', 'label': 'Préstamos'},
  ];

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = _clientService.registerClient(
        cedula: _cedulaController.text.trim(),
        nombreCompleto: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        negocioInicial: _selectedBusiness,
      );

      widget.onClientAdded(client);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isMobile ? double.infinity : 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nuevo Cliente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cédula
                      TextFormField(
                        controller: _cedulaController,
                        decoration: const InputDecoration(
                          labelText: 'Cédula *',
                          hintText: 'Ej: 12345678901',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La cédula es requerida';
                          }
                          if (!_clientService.isValidCedula(value)) {
                            return 'Cédula inválida (7-11 dígitos)';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Validar en tiempo real si la cédula ya existe
                          if (value.length >= 7 && _clientService.findByCedula(value) != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta cédula ya está registrada'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),

                      // Nombre completo
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo *',
                          hintText: 'Ej: Juan Carlos Pérez',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          if (value.trim().length < 3) {
                            return 'El nombre debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),

                      // Teléfono
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          hintText: 'Ej: 809-555-1234',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El teléfono es requerido';
                          }
                          if (value.trim().length < 10) {
                            return 'Teléfono inválido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),

                      // Email (opcional)
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email (opcional)',
                          hintText: 'Ej: cliente@email.com',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Email inválido';
                            }
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),

                      // Dirección (opcional)
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección (opcional)',
                          hintText: 'Ej: Calle Principal #123',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),

                      // Negocio inicial
                      DropdownButtonFormField<String>(
                        value: _selectedBusiness,
                        decoration: const InputDecoration(
                          labelText: 'Negocio inicial (opcional)',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        items: _businesses.map((business) {
                          return DropdownMenuItem<String>(
                            value: business['value'],
                            child: Text(business['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedBusiness = value);
                        },
                        hint: const Text('Seleccionar negocio'),
                      ),
                      
                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveClient,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text('Guardar Cliente'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para ver y editar detalles del cliente
class ClientDetailDialog extends StatefulWidget {
  final ClientModel client;
  final Function(ClientModel) onClientUpdated;

  const ClientDetailDialog({
    super.key,
    required this.client,
    required this.onClientUpdated,
  });

  @override
  State<ClientDetailDialog> createState() => _ClientDetailDialogState();
}

class _ClientDetailDialogState extends State<ClientDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();
  
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _direccionController;
  
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.client.nombreCompleto);
    _telefonoController = TextEditingController(text: widget.client.telefono);
    _emailController = TextEditingController(text: widget.client.email ?? '');
    _direccionController = TextEditingController(text: widget.client.direccion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _updateClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedClient = _clientService.updateClient(
        widget.client.cedula,
        nombreCompleto: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
      );

      widget.onClientUpdated(updatedClient);
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isMobile ? double.infinity : 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalles del Cliente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      tooltip: 'Editar',
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _isEditing ? _buildEditForm() : _buildDetailsView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(
          icon: Icons.badge,
          label: 'Cédula',
          value: _clientService.formatCedula(widget.client.cedula),
        ),
        _buildDetailItem(
          icon: Icons.person,
          label: 'Nombre completo',
          value: widget.client.nombreCompleto,
        ),
        _buildDetailItem(
          icon: Icons.phone,
          label: 'Teléfono',
          value: widget.client.telefono,
        ),
        if (widget.client.email != null)
          _buildDetailItem(
            icon: Icons.email,
            label: 'Email',
            value: widget.client.email!,
          ),
        if (widget.client.direccion != null)
          _buildDetailItem(
            icon: Icons.home,
            label: 'Dirección',
            value: widget.client.direccion!,
          ),
        _buildDetailItem(
          icon: Icons.calendar_today,
          label: 'Fecha de registro',
          value: '${widget.client.fechaRegistro.day}/${widget.client.fechaRegistro.month}/${widget.client.fechaRegistro.year}',
        ),
        if (widget.client.negociosAsociados.isNotEmpty)
          _buildDetailItem(
            icon: Icons.business,
            label: 'Negocios asociados',
            value: widget.client.negociosAsociados.join(', '),
          ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Cédula (solo lectura)
          TextFormField(
            initialValue: _clientService.formatCedula(widget.client.cedula),
            decoration: const InputDecoration(
              labelText: 'Cédula',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            enabled: false,
          ),
          
          const SizedBox(height: 16),

          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre completo *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es requerido';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),

          TextFormField(
            controller: _telefonoController,
            decoration: const InputDecoration(
              labelText: 'Teléfono *',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El teléfono es requerido';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email (opcional)',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: 16),

          TextFormField(
            controller: _direccionController,
            decoration: const InputDecoration(
              labelText: 'Dirección (opcional)',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            maxLines: 2,
          ),
          
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => setState(() => _isEditing = false),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}