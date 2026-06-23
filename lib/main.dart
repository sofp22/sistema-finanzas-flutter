import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/finanzas_screen.dart';
import 'screens/clientes_screen.dart';

void main() {
  runApp(const MiAppFinanciera());
}

class MiAppFinanciera extends StatelessWidget {
  const MiAppFinanciera({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Financiero',
      debugShowCheckedModeBanner: false, // Quita la banda roja de "Debug"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const NavegacionPrincipal(), // Nuestra pantalla principal separada
    );
  }
}
class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceSeleccionado = 0;
  
  static final GlobalKey<DashboardScreenState> childKey = GlobalKey<DashboardScreenState>();

  @override
  Widget build(BuildContext context) {
    // Lista de las 3 pestañas principales de la app móvil
    final List<Widget> pantallas = [
      DashboardScreen(key: childKey),
      ClientesScreen(onCambioNegocio: () {
        // Cuando prestas o cobras, refresca automáticamente el cuadro verde del Dashboard
        childKey.currentState?.cargarInformacionExterna();
      }),
      FinanzasScreen(onTransaccionAgregada: () {
        // Cuando gastas de tu bolsillo, refresca el cuadro azul del Dashboard
        childKey.currentState?.cargarInformacionExterna();
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Billetera & Negocio', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSeleccionado,
        onDestinationSelected: (int index) {
          setState(() {
            _indiceSeleccionado = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Mis Finanzas',
          ),
        ],
      ),
      body: IndexedStack(
        index: _indiceSeleccionado,
        children: pantallas,
      ),
    );
  }
}