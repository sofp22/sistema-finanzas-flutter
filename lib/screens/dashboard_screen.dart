import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState(); // <-- Quitamos el guion bajo (_) para hacerlo público
}

class DashboardScreenState extends State<DashboardScreen> { // <-- Aquí también quitamos el guion bajo
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _datosEmpresa;
  Map<String, dynamic>? _datosPersonales;
  bool _cargando = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _cargarInformacion();
  }

  // Esta es la función clave para que el main.dart pueda actualizar los datos desde fuera
  void cargarInformacionExterna() {
    _cargarInformacion();
  }

  Future<void> _cargarInformacion() async {
    try {
      setState(() {
        _cargando = true;
        _errorMsg = '';
      });
      final data = await _apiService.obtenerDashboardResumen();
      setState(() {
        _datosEmpresa = data['empresa_prestamos'];
        _datosPersonales = data['finanzas_personales'];
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le quitamos el AppBar a esta pantalla individual para que no se duplique con la navegación principal
    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg.isNotEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(_errorMsg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.store, color: Colors.green, size: 28),
                          SizedBox(width: 8),
                          Text('Mi Negocio de Préstamos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _construirFilaDato('Total Histórico Prestado', '\$${_datosEmpresa?['total_historico_prestado']}', Colors.black),
                              const Divider(),
                              _construirFilaDato('Dinero en la Calle (Cartera)', '\$${_datosEmpresa?['dinero_actual_en_la_calle']}', Colors.orange, resaltar: true),
                              const Divider(),
                              _construirFilaDato('Total Cobrado/Recuperado', '\$${_datosEmpresa?['total_recuperado_por_cobros']}', Colors.green),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue, size: 28),
                          SizedBox(width: 8),
                          Text('Mis Finanzas Personales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _construirFilaDato('Mis Ingresos Totales', '\$${_datosPersonales?['mis_ingresos_totales']}', Colors.green),
                              const Divider(),
                              _construirFilaDato('Mis Gastos Totales', '\$${_datosPersonales?['mis_gastos_totales']}', Colors.red),
                              const Divider(),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: _construirFilaDato('Mi Dinero Libre Disponible', '\$${_datosPersonales?['mi_dinero_libre_disponible']}', Colors.blue, resaltar: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _construirFilaDato(String titulo, String valor, Color colorValor, {bool resaltar = false}) {
    // Limpiamos los decimales innecesarios (ej: $20000.0 -> $20000)
    String valorLimpio = valor.replaceAll('.0', ''); 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expanded evita que el texto empuje los números fuera de la pantalla
          Expanded(
            child: Text(titulo, style: TextStyle(fontSize: 15, color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          Text(
            valorLimpio, 
            style: TextStyle(
              fontSize: resaltar ? 18 : 16, 
              fontWeight: resaltar ? FontWeight.bold : FontWeight.normal, 
              color: colorValor
            )
          ),
        ],
      ),
    );
  }
}