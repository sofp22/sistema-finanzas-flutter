import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  
  // Manejo del método de pago seleccionado
  String? _metodoSeleccionado = 'Efectivo'; 
  final List<String> _metodosPago = ['Efectivo', 'Transferencia', 'Tarjeta de Crédito'];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _capitalController.dispose();
    _interesController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
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
        _mostrarSnackBar('Error al cargar historial: $e', Colors.red);
      }
    }
  }

  // Traductor UI -> Backend para evitar el Error 400 en los abonos
  String _mapearMetodoPagoParaBackend(String metodoUI) {
    switch (metodoUI) {
      case 'Transferencia':
        return 'cuenta_bancaria';
      case 'Tarjeta de Crédito':
        return 'tarjeta_credito';
      case 'Efectivo':
      default:
        return 'efectivo';
    }
  }

  // ================= ANULAR ABONO =================
  Future<void> _anularAbono(String abonoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Anular este Cobro?'),
        content: const Text('Esta acción restaurará la deuda del cliente de forma automática en el sistema.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sí, Anular', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _cargando = true);
      try {
        await _apiService.anularAbono(abonoId);
        _mostrarSnackBar('Cobro anulado con éxito', Colors.green);
        _cargarHistorial(); // Recargar saldos en caliente
      } catch (e) {
        setState(() => _cargando = false);
        _mostrarSnackBar('Error al anular: $e', Colors.red);
      }
    }
  }

  void _abrirModalCobro() {
    // CORRECCIÓN: Limpieza preventiva al abrir el formulario
    _capitalController.clear();
    _interesController.clear();
    _metodoSeleccionado = 'Efectivo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder( 
          builder: (BuildContext context, StateSetter setModalState) {
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
                  
                  DropdownButtonFormField<String>(
                    value: _metodoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: "Canal de Pago",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: _metodosPago.map((String metodo) {
                      return DropdownMenuItem<String>(
                        value: metodo,
                        child: Text(metodo),
                      );
                    }).toList(),
                    onChanged: (String? nuevoValor) {
                      setModalState(() {
                        _metodoSeleccionado = nuevoValor;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: _interesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Pago a Interés Mensual (\$)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.percent)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _capitalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Abono Directo a Capital (\$)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments)),
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
          }
        );
      },
    );
  }

  Future<void> _procesarPago() async {
    double capital = double.tryParse(_capitalController.text) ?? 0.0;
    double interes = double.tryParse(_interesController.text) ?? 0.0;

    if (capital == 0 && interes == 0) {
      _mostrarSnackBar("Debes ingresar al menos un valor", Colors.orange);
      return;
    }

    Navigator.pop(context); 
    setState(() => _cargando = true);

    try {
      // CORRECCIÓN: Enviamos el método de pago mapeado de manera limpia y segura
      await _apiService.registrarAbono(
        prestamoId: widget.prestamo['id'].toString(),
        montoCapital: capital,
        montoInteres: interes,
        metodoPago: _mapearMetodoPagoParaBackend(_metodoSeleccionado ?? 'Efectivo'), 
      );

      if (mounted) {
        _mostrarSnackBar("¡Pago registrado exitosamente!", Colors.green);
        _capitalController.clear();
        _interesController.clear();
        _cargarHistorial(); 
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        _mostrarSnackBar("Error: $e", Colors.red);
      }
    }
  }

  void _mostrarSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPrestado = double.tryParse(
      (widget.prestamo['monto_inicial'] ?? widget.prestamo['monto'] ?? 0).toString()
    ) ?? 0.0;
    
    double saldoRestante = double.tryParse(
      (widget.prestamo['saldo_actual'] ?? widget.prestamo['saldo_restante'] ?? 0).toString()
    ) ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.cliente['nombre'] ?? "Perfil Cliente")),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                
                Expanded(
                  child: _historialAbonos.isEmpty
                      ? const Center(child: Text("Este cliente no registra abonos aún."))
                      : ListView.builder(
                          itemCount: _historialAbonos.length,
                          itemBuilder: (context, index) {
                            final abono = _historialAbonos[index];
                            final bool esAnulado = abono['estado'].toString().toLowerCase() == 'anulado';
                            final String metodo = abono['metodo_pago'] ?? abono['medio'] ?? 'Efectivo';
                            final String abonoId = abono['id'].toString();
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Icon(
                                  metodo == 'Transferencia' 
                                      ? Icons.account_balance 
                                      : metodo == 'Tarjeta de Crédito' 
                                          ? Icons.credit_card 
                                          : Icons.monetization_on, 
                                  color: esAnulado ? Colors.grey : Colors.green
                                ),
                                title: Text(
                                  "Total Pagado: \$${abono['monto_total'] ?? (double.parse((abono['monto_capital'] ?? 0).toString()) + double.parse((abono['monto_interes'] ?? 0).toString()))}",
                                  style: TextStyle(
                                    decoration: esAnulado ? TextDecoration.lineThrough : null,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                subtitle: Text("Cap: \$${abono['monto_capital']} | Int: \$${abono['monto_interes']}\nVía: $metodo"),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      esAnulado ? "ANULADO" : "VÁLIDO",
                                      style: TextStyle(
                                        color: esAnulado ? Colors.red : Colors.blue, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                    // MENÚ DE ACCIONES: Te permite anular cobros en vivo
                                    if (!esAnulado)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        onSelected: (value) {
                                          if (value == 'anular') {
                                            _anularAbono(abonoId);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'anular', 
                                            child: Row(children: [Icon(Icons.cancel, color: Colors.red, size: 20), SizedBox(width: 8), Text('Anular Abono', style: TextStyle(color: Colors.red))])
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
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