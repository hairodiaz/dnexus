import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/employee_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/services/employee_service.dart';

/// Diálogo para agregar un nuevo empleado
class AddEmployeeDialog extends StatefulWidget {
  final UserModel currentUser;
  final Function(EmployeeModel) onEmployeeAdded;

  const AddEmployeeDialog({
    Key? key,
    required this.currentUser,
    required this.onEmployeeAdded,
  }) : super(key: key);

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  final _notesController = TextEditingController();
  
  UserRole selectedRole = UserRole.vendedor;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cedulaController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        maxWidth: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Text(
                      'Agregar Empleado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nombre completo
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    hintText: 'Ej: Juan Carlos Pérez',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    if (value.trim().length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cédula
                TextFormField(
                  controller: _cedulaController,
                  decoration: const InputDecoration(
                    labelText: 'Cédula *',
                    hintText: 'Ej: 12345678',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La cédula es requerida';
                    }
                    if (value.length < 7 || value.length > 10) {
                      return 'La cédula debe tener entre 7 y 10 dígitos';
                    }
                    if (EmployeeService.cedulaExists(value)) {
                      return 'Ya existe un empleado con esta cédula';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Teléfono
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: 'Ej: +57 300 123 4567',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Ej: empleado@empresa.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Ingrese un email válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rol
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Cargo/Rol *',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),
                  items: _getAvailableRoles().map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(
                            _getRoleIcon(role),
                            size: 20,
                            color: Color(_getRoleColor(role)),
                          ),
                          const SizedBox(width: 8),
                          Text(_getRoleDisplayName(role)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (role) => setState(() => selectedRole = role!),
                ),
                const SizedBox(height: 16),

                // Fecha de ingreso
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Ingreso *',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Salario base
                TextFormField(
                  controller: _salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Salario Base *',
                    hintText: 'Ej: 1200000',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    suffixText: 'COP',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El salario es requerido';
                    }
                    final salary = double.tryParse(value);
                    if (salary == null || salary < 0) {
                      return 'Ingrese un salario válido';
                    }
                    if (salary < 1300000) { // Salario mínimo colombiano 2024
                      return 'El salario no puede ser menor al mínimo legal';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notas
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas Adicionales',
                    hintText: 'Información adicional sobre el empleado',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : _saveEmployee,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<UserRole> _getAvailableRoles() {
    // SuperAdmin puede asignar cualquier rol
    if (widget.currentUser.userRole == UserRole.superAdmin) {
      return UserRole.values;
    }
    
    // Admin puede asignar roles operativos pero no admin o superadmin
    if (widget.currentUser.userRole == UserRole.admin) {
      return [
        UserRole.caja,
        UserRole.facturador,
        UserRole.vendedor,
      ];
    }
    
    // Otros roles no pueden agregar empleados
    return [];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _saveEmployee() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final employee = EmployeeService.addEmployee(
        fullName: _nameController.text.trim(),
        cedula: _cedulaController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        email: _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null,
        role: selectedRole,
        hireDate: selectedDate,
        baseSalary: double.parse(_salaryController.text),
        businessId: widget.currentUser.businessId ?? 'business_ferreteria',
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
      );

      widget.onEmployeeAdded(employee);
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar empleado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings;
      case UserRole.admin:
        return Icons.manage_accounts;
      case UserRole.caja:
        return Icons.point_of_sale;
      case UserRole.facturador:
        return Icons.receipt_long;
      case UserRole.vendedor:
        return Icons.store;
    }
  }

  int _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 0xFF9C27B0; // Purple
      case UserRole.admin:
        return 0xFF2196F3; // Blue
      case UserRole.caja:
        return 0xFF4CAF50; // Green
      case UserRole.facturador:
        return 0xFFFF9800; // Orange
      case UserRole.vendedor:
        return 0xFF607D8B; // Blue Grey
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Administrador';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.caja:
        return 'Cajero';
      case UserRole.facturador:
        return 'Facturador';
      case UserRole.vendedor:
        return 'Vendedor';
    }
  }
}

/// Diálogo para editar un empleado existente
class EditEmployeeDialog extends StatefulWidget {
  final EmployeeModel employee;
  final UserModel currentUser;
  final Function(EmployeeModel) onEmployeeUpdated;

  const EditEmployeeDialog({
    Key? key,
    required this.employee,
    required this.currentUser,
    required this.onEmployeeUpdated,
  }) : super(key: key);

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cedulaController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _salaryController;
  late TextEditingController _notesController;
  
  late UserRole selectedRole;
  late DateTime selectedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.fullName);
    _cedulaController = TextEditingController(text: widget.employee.cedula);
    _phoneController = TextEditingController(text: widget.employee.phone ?? '');
    _emailController = TextEditingController(text: widget.employee.email ?? '');
    _salaryController = TextEditingController(text: widget.employee.baseSalary.toStringAsFixed(0));
    _notesController = TextEditingController(text: widget.employee.notes ?? '');
    selectedRole = widget.employee.role;
    selectedDate = widget.employee.hireDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cedulaController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        maxWidth: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Icon(Icons.edit, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Text(
                      'Editar Empleado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campos del formulario (mismo que AddEmployeeDialog)
                _buildFormFields(),

                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : _updateEmployee,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Actualizar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    // Similar al formulario de agregar pero con validación diferente para cédula
    return Column(
      children: [
        // Nombre completo
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre Completo *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es requerido';
            }
            if (value.trim().length < 2) {
              return 'El nombre debe tener al menos 2 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Cédula (no editable para mantener integridad)
        TextFormField(
          controller: _cedulaController,
          decoration: const InputDecoration(
            labelText: 'Cédula',
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
          ),
          enabled: false, // No permitir editar cédula
        ),
        const SizedBox(height: 16),

        // Resto de campos...
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Ingrese un email válido';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Salario
        TextFormField(
          controller: _salaryController,
          decoration: const InputDecoration(
            labelText: 'Salario Base *',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
            suffixText: 'COP',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El salario es requerido';
            }
            final salary = double.tryParse(value);
            if (salary == null || salary < 0) {
              return 'Ingrese un salario válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Notas
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notas Adicionales',
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  void _updateEmployee() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final updatedEmployee = widget.employee.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        email: _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null,
        baseSalary: double.parse(_salaryController.text),
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
      );

      final result = EmployeeService.updateEmployee(widget.employee.id, updatedEmployee);
      
      if (result != null) {
        widget.onEmployeeUpdated(result);
        Navigator.pop(context);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar empleado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}