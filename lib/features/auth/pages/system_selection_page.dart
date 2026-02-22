import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemSelectionPage extends StatefulWidget {
  const SystemSelectionPage({super.key});

  @override
  State<SystemSelectionPage> createState() => _SystemSelectionPageState();
}

class _SystemSelectionPageState extends State<SystemSelectionPage> {
  late FocusNode _focusNode;
  bool _ctrlPressed = false;
  bool _downPressed = false;
  bool _upPressed = false;
  bool _leftPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Delay to ensure widget is fully mounted before requesting focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.controlLeft) || 
        event.isKeyPressed(LogicalKeyboardKey.controlRight)) {
      _ctrlPressed = true;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      _downPressed = true;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      _upPressed = true;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      _leftPressed = true;
    }

    // Check if Ctrl+ArrowDown+ArrowUp is pressed (User Management)
    if (_ctrlPressed && _downPressed && _upPressed) {
      _navigateToUserManagement();
      // Reset flags
      _ctrlPressed = false;
      _downPressed = false;
      _upPressed = false;
    }

    // Check if Ctrl+ArrowDown+ArrowLeft is pressed (Owner Login)
    if (_ctrlPressed && _downPressed && _leftPressed) {
      _navigateToOwnerLogin();
      // Reset flags
      _ctrlPressed = false;
      _downPressed = false;
      _leftPressed = false;
    }

    // Reset on key release
    if (event.isKeyPressed(LogicalKeyboardKey.controlLeft) || 
        event.isKeyPressed(LogicalKeyboardKey.controlRight)) {
      _ctrlPressed = false;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      _downPressed = false;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      _upPressed = false;
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      _leftPressed = false;
    }
  }

  void _navigateToUserManagement() {
    Navigator.of(context).pushNamed('/user_management_login');
  }

  void _navigateToOwnerLogin() {
    Navigator.of(context).pushNamed('/owner_login');
  }

  void _navigateToSystemLogin(String systemType) {
    String route = '';
    switch (systemType) {
      case 'repuestos':
        route = '/repuestos_login';
        break;
      case 'prestamos':
        route = '/prestamos_login';
        break;
      case 'inmuebles':
        route = '/inmuebles_login';
        break;
    }
    if (route.isNotEmpty) {
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!,
                Colors.grey[800]!,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Column(
                    children: [
                      Text(
                        'D-Nexus',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona tu Sistema',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),

                // System Cards
                Wrap(
                  spacing: 30,
                  runSpacing: 30,
                  alignment: WrapAlignment.center,
                  children: [
                    // Repuestos Card
                    _buildSystemCard(
                      title: 'Repuestos',
                      emoji: '🔧',
                      color: const Color(0xFFFF8C00),
                      onTap: () => _navigateToSystemLogin('repuestos'),
                    ),

                    // Préstamos Card
                    _buildSystemCard(
                      title: 'Préstamos',
                      emoji: '💰',
                      color: const Color(0xFF4CAF50),
                      onTap: () => _navigateToSystemLogin('prestamos'),
                    ),

                    // Inmuebles Card
                    _buildSystemCard(
                      title: 'Inmuebles',
                      emoji: '🏠',
                      color: const Color(0xFF2196F3),
                      onTap: () => _navigateToSystemLogin('inmuebles'),
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

  Widget _buildSystemCard({
    required String title,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 250,
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
