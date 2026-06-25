import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({Key? key}) : super(key: key);

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _balanceFuture;

  // Controladores de texto para capturar los inputs del formulario
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _balanceFuture = _apiService.obtenerResumenBalancePrivado();
  }

  Future<void> _refreshBalance() async {
    setState(() {
      _balanceFuture = _apiService.obtenerResumenBalancePrivado();
    });
  }

  // 📝 VENTANA EMERGENTE CON FORMULARIO (INPUTS)
  void _mostrarFormularioObligacion() {
    _conceptoController.clear();
    _montoController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que suba si el teclado se abre
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nueva Obligación Mensual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              // Input 1: Concepto
              TextField(
                controller: _conceptoController,
                decoration: const InputDecoration(
                  labelText: 'Concepto (Ej: Pago Tarjeta, Transporte)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 15),
              
              // Input 2: Monto Meta
              TextField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Meta Mensual (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 20),
              
              // Botón de Enviar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () async {
                    final concepto = _conceptoController.text.trim();
                    final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;

                    if (concepto.isEmpty || monto <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor llena todos los campos correctamente')),
                      );
                      return;
                    }

                    try {
                      // Enviamos la información al backend
                      await _apiService.registrarObligacionMensual(concepto, monto);
                      Navigator.pop(context); // Cerrar formulario
                      _refreshBalance(); // Refrescar la pantalla de inmediato
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Obligación agregada correctamente'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Guardar Obligación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Balance Privado', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      // ➕ BOTÓN FLOTANTE PARA INGRESAR DATOS DESDE LA APP
      floatingActionButton: FloatingActionButton(
        heroTag: 'btn_balance',
        onPressed: _mostrarFormularioObligacion,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBalance,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _balanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No hay datos disponibles.'));
            }

            final data = snapshot.data!;
            final double ahorroTotal = double.tryParse(data['ahorro_total'].toString()) ?? 0.0;
            final List<dynamic> obligaciones = data['obligaciones'] ?? [];
            final List<dynamic> historialFondos = data['historial_fondos'] ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TARJETA DE AHORRO PRINCIPAL
                  Card(
                    color: Colors.indigo.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 50, color: Colors.white),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mi Ahorro Neto Total', style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(height: 5),
                              Text(
                                '\$${ahorroTotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // SECCIÓN DE OBLIGACIONES MENSUALES
                  const Text('Obligaciones del Mes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  obligaciones.isEmpty
                      ? const Text('No tienes obligaciones registradas. ¡Toca el botón "+" para agregar una!')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: obligaciones.length,
                          itemBuilder: (context, index) {
                            final ob = obligaciones[index];
                            final double meta = double.tryParse(ob['monto_meta'].toString()) ?? 0.0;
                            final double pagado = double.tryParse(ob['monto_pagado_mes'].toString()) ?? 0.0;
                            final double progreso = meta > 0 ? (pagado / meta) : 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(ob['concepto'] ?? 'Obligación', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('\$${pagado.toStringAsFixed(0)} / \$${meta.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade700)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progreso > 1.0 ? 1.0 : progreso,
                                      backgroundColor: Colors.grey.shade200,
                                      color: progreso >= 1.0 ? Colors.green : Colors.orange,
                                      minHeight: 8,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 25),

                  // HISTORIAL PRIVADO DE MOVIMIENTOS
                  const Text('Historial de Fondos Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  historialFondos.isEmpty
                      ? const Text('Aún no hay movimientos de capital o intereses.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: historialFondos.length,
                          itemBuilder: (context, index) {
                            final mov = historialFondos[index];
                            final double monto = double.tryParse(mov['monto'].toString()) ?? 0.0;
                            final String tipo = mov['tipo'] ?? '';
                            
                            String titulo = tipo == '15_Capital' ? '15% Capital Automático' : 'Excedente de Interés';
                            IconData icono = tipo == '15_Capital' ? Icons.pie_chart : Icons.trending_up;
                            Color colorIcono = tipo == '15_Capital' ? Colors.blue : Colors.green;

                            return ListTile(
                              leading: CircleAvatar(backgroundColor: colorIcono.withOpacity(0.1), child: Icon(icono, color: colorIcono)),
                              title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(mov['fecha'] != null ? mov['fecha'].toString().substring(0, 10) : ''),
                              trailing: Text(
                                '+\$${monto.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            );
                          },
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}