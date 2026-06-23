import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Asegúrate de que esta ruta sea la correcta en tu proyecto

class ClienteDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final Map<String, dynamic> prestamo; // Préstamo activo del cliente

  const ClienteDetalleScreen({super.key, required this.cliente, required this.prestamo});

  @override
  State<ClienteDetalleScreen> createState() => _ClienteDetalleScreenState();
}

class _ClienteDetalleScreenState extends State<ClienteDetalleScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _historialAbonos = [];
  bool _cargando = true;

  // Controladores para el formulario de cobro
  final TextEditingController _capitalController = TextEditingController();
  final TextEditingController _interesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      // Convertimos el ID a String de forma segura para Dio
      final abonos = await _apiService.obtenerAbonosPorPrestamo(widget.prestamo['id'].toString());
      if (mounted) {
        setState(() {
          _historialAbonos = abonos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _abrirModalCobro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Registrar Recibo de Pago", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _interesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Pago a Interés Mensual (\$)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _capitalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Abono Directo a Capital (\$)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: _procesarPago,
                  child: const Text("Confirmar Transacción", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarPago() async {
    double capital = double.tryParse(_capitalController.text) ?? 0.0;
    double interes = double.tryParse(_interesController.text) ?? 0.0;

    if (capital == 0 && interes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes ingresar al menos un valor"), backgroundColor: Colors.orange)
      );
      return;
    }

    Navigator.pop(context); // Cerrar el modal de forma segura
    setState(() => _cargando = true);

    try {
      // Enviamos de forma separada los montos al api_service actualizado
      await _apiService.registrarAbono(
        prestamoId: widget.prestamo['id'].toString(),
        montoCapital: capital,
        montoInteres: interes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Pago registrado exitosamente!"), backgroundColor: Colors.green)
        );
        _capitalController.clear();
        _interesController.clear();
        _cargarHistorial(); // Recarga los saldos actualizados desde el backend
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrestado = double.tryParse(widget.prestamo['monto_inicial'].toString()) ?? 0.0;
    double saldoRestante = double.tryParse(widget.prestamo['saldo_actual'].toString()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.cliente['nombre'] ?? "Perfil Cliente")),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TARJETA DE RESUMEN FINANCIERO DEL CLIENTE
                Card(
                  color: Colors.indigo.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Dinero Prestado:", style: TextStyle(fontSize: 16)),
                            Text("\$$totalPrestado", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Saldo Pendiente:", style: TextStyle(fontSize: 16, color: Colors.red)),
                            Text("\$$saldoRestante", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Historial de Actividad Financiera", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // LISTA CRONOLÓGICA DE ABONOS DETALLADOS
                Expanded(
                  child: _historialAbonos.isEmpty
                      ? const Center(child: Text("Este cliente no registra abonos aún."))
                      : ListView.builder(
                          itemCount: _historialAbonos.length,
                          itemBuilder: (context, index) {
                            final abono = _historialAbonos[index];
                            final bool esAnulado = abono['estado'].toString().toLowerCase() == 'anulado';
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Icon(Icons.monetization_on, color: esAnulado ? Colors.grey : Colors.green),
                                title: Text(
                                  "Total Pagado: \$${abono['monto_total']}",
                                  style: TextStyle(
                                    decoration: esAnulado ? TextDecoration.lineThrough : null,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                subtitle: Text("Capital: \$${abono['monto_capital']} | Interés: \$${abono['monto_interes']}"),
                                trailing: Text(
                                  esAnulado ? "ANULADO" : "VÁLIDO",
                                  style: TextStyle(
                                    color: esAnulado ? Colors.red : Colors.blue, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // BOTÓN DE COBRO COMPLETO
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: _abrirModalCobro,
                    icon: const Icon(Icons.add_card, color: Colors.white),
                    label: const Text("Registrar Abono / Interés", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
    );
  }
}