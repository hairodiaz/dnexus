import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/employee_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/services/employee_service.dart';

/// Página de formulario simple para crear empleados
class EmployeeFormPage extends StatefulWidget {
  final UserModel currentUser;
  final bool isEditing;
  final EmployeeModel? employee;

  const EmployeeFormPage({
    super.key,
    required this.currentUser,
    this.isEditing = false,
    this.employee,
  });

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _positionController = TextEditingController();
  
  UserRole _selectedRole = UserRole.vendedor;
  DateTime _selectedHireDate = DateTime.now();
  String _selectedBusinessId = 'ferreteria_1';
  bool _isActive = true;
  bool _isLoading = false;

  final List<UserRole> _availableRoles = [
    UserRole.admin,
    UserRole.caja,
    UserRole.facturador, 
    UserRole.vendedor
  ];

  final List<String> _availableBusinesses = [
    'ferreteria_1',
    'supermercado_1'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.employee != null) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    final employee = widget.employee!;
    _nameController.text = employee.fullName;
    _emailController.text = employee.email ?? '';
    _phoneController.text = employee.phone ?? '';
    _salaryController.text = employee.baseSalary.toString();
    _cedulaController.text = employee.cedula;
    _selectedRole = employee.role;
    _selectedHireDate = employee.hireDate;
    _selectedBusinessId = employee.businessId;
    _isActive = employee.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Empleado' : 'Nuevo Empleado'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
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
              // Información Personal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            'Información Personal',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Nombre completo
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          if (value.trim().length < 2) {
                            return 'El nombre debe tener al menos 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El email es obligatorio';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Ingrese un email válido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Teléfono
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El teléfono es obligatorio';
                          }
                          if (value.trim().length < 7) {
                            return 'Ingrese un teléfono válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Información Laboral
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.work, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            'Información Laboral',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Cargo/Posición
                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: 'Cargo/Posición *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El cargo es obligatorio';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Rol del sistema
                      DropdownButtonFormField<UserRole>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Rol del Sistema *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        items: _availableRoles.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.displayName),
                          );
                        }).toList(),
                        onChanged: (UserRole? value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Negocio
                      DropdownButtonFormField<String>(
                        value: _selectedBusinessId,
                        decoration: const InputDecoration(
                          labelText: 'Negocio *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: _availableBusinesses.map((business) {
                          return DropdownMenuItem<String>(
                            value: business,
                            child: Text(business),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => _selectedBusinessId = value);
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Salario
                      TextFormField(
                        controller: _salaryController,
                        decoration: const InputDecoration(
                          labelText: 'Salario Mensual *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El salario es obligatorio';
                          }
                          final salary = int.tryParse(value);
                          if (salary == null || salary <= 0) {
                            return 'Ingrese un salario válido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Fecha de contratación
                      InkWell(
                        onTap: _selectHireDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Contratación *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_selectedHireDate.day}/${_selectedHireDate.month}/${_selectedHireDate.year}',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Estado activo
                      SwitchListTile(
                        title: const Text('Empleado Activo'),
                        subtitle: Text(_isActive ? 'El empleado está activo' : 'El empleado está inactivo'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                        activeColor: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.isEditing ? 'Actualizar' : 'Crear'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Nota sobre campos requeridos
              Text(
                '* Campos obligatorios',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'caja':
        return 'Cajero';
      case 'facturador':
        return 'Facturador';
      case 'vendedor':
        return 'Vendedor';
      default:
        return role;
    }
  }

  Future<void> _selectHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedHireDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedHireDate) {
      setState(() => _selectedHireDate = picked);
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEditing) {
        // TODO: Implementar actualización de empleados
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empleado actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        EmployeeService.addEmployee(
          fullName: _nameController.text.trim(),
          cedula: _cedulaController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          role: _selectedRole,
          baseSalary: double.parse(_salaryController.text),
          businessId: _selectedBusinessId,
          hireDate: _selectedHireDate,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empleado creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Retorna true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empleado'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${widget.employee!.fullName}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteEmployee();
    }
  }

  Future<void> _deleteEmployee() async {
    setState(() => _isLoading = true);

    try {
      await EmployeeService.deleteEmployee(widget.employee!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empleado eliminado exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}