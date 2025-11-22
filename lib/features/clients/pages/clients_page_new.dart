import 'package:flutter/material.dart';
import '../../shared/models/client_model.dart';
import '../../shared/services/client_service.dart';
import '../../shared/widgets/client_dialogs.dart';

/// Página principal de gestión de clientes unificados
class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _clientService.initializeDefaultClients();
    _loadClients();
  }

  void _loadClients() {
    setState(() {
      _isLoading = true;
      _clients = _clientService.getAllClients();
      _filteredClients = _clients;
      _isLoading = false;
    });
  }

  void _searchClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clientService.search(query);
      }
    });
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => AddClientDialog(
        onClientAdded: (client) {
          _loadClients();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cliente ${client.nombreCompleto} agregado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showClientDetails(ClientModel client) {
    showDialog(
      context: context,
      builder: (context) => ClientDetailDialog(
        client: client,
        onClientUpdated: (updatedClient) {
          _loadClients();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente actualizado exitosamente'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Clientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_filteredClients.length} cliente(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y estadísticas
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  onChanged: _searchClients,
                  decoration: InputDecoration(
                    hintText: 'Buscar por cédula, nombre o teléfono...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchClients('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                
                if (isMobile) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_filteredClients.length} cliente(s) encontrado(s)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de clientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          return _buildClientCard(client, isMobile);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(isMobile ? 'Agregar' : 'Nuevo Cliente'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No hay clientes registrados'
                : 'No se encontraron clientes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Agrega tu primer cliente usando el botón +'
                : 'Intenta con otro término de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(ClientModel client, bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showClientDetails(client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isMobile 
              ? _buildMobileClientCard(client)
              : _buildDesktopClientCard(client),
        ),
      ),
    );
  }

  Widget _buildMobileClientCard(ClientModel client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 20,
              child: Text(
                client.nombreCompleto.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Cédula: ${_clientService.formatCedula(client.cedula)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.phone, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              client.telefono,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        if (client.negociosAsociados.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Negocios: ${client.negociosAsociados.join(', ')}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopClientCard(ClientModel client) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
          radius: 24,
          child: Text(
            client.nombreCompleto.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.nombreCompleto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Cédula: ${_clientService.formatCedula(client.cedula)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            client.telefono,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          flex: 3,
          child: client.negociosAsociados.isEmpty
              ? Text(
                  'Nuevo cliente',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Wrap(
                  spacing: 4,
                  children: client.negociosAsociados.map((negocio) {
                    Color color = Colors.grey;
                    switch (negocio) {
                      case 'repuestos':
                        color = Colors.green;
                        break;
                      case 'electrodomesticos':
                        color = Colors.blue;
                        break;
                      case 'prestamos':
                        color = Colors.orange;
                        break;
                    }
                    
                    return Chip(
                      label: Text(
                        negocio,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: color,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
        ),
        const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
      ],
    );
  }
}