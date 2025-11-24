import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';

/// Página simple para mostrar que la funcionalidad de crear empleados está en desarrollo
class EmployeeFormPage extends StatelessWidget {
  final UserModel currentUser;

  const EmployeeFormPage({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Empleado'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 80,
                color: Colors.orange[600],
              ),
              const SizedBox(height: 24),
              Text(
                'Formulario de Empleados',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'La funcionalidad completa de creación y edición de empleados está en desarrollo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Por el momento, puedes ver los 8 empleados de muestra en la lista principal.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Características planeadas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Características planeadas:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeature('Crear nuevos empleados'),
                    _buildFeature('Editar información existente'),
                    _buildFeature('Gestión de salarios y roles'),
                    _buildFeature('Asignación de negocios'),
                    _buildFeature('Validación de campos'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Volver a Empleados'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}