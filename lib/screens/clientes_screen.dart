import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClientesScreen extends StatefulWidget {
  final VoidCallback onCambioNegocio; // Refresca el dashboard al prestar o abonar
  const ClientesScreen({super.key, required this.onCambioNegocio});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _clientes = [];
  bool _cargando = false;
  final _searchController = TextEditingController();

  // Llaves para validación de formularios modales
  final _formClienteKey = GlobalKey<FormState>();
  final _formPrestamoKey = GlobalKey<FormState>();
  final _formAbonoKey = GlobalKey<FormState>();

  // Controladores temporales de texto
  final _nombreCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _interesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _buscarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _telCtrl.dispose();
    _montoCtrl.dispose();
    _interesCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarClientes() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final datos = await _apiService.obtenerClientes(cedula: _searchController.text);
      if (mounted) setState(() => _clientes = datos);
    } catch (e) {
      if (mounted) _mostrarSnackBar('Error al cargar clientes: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ================= FORMULARIO MODAL: CREAR CLIENTE =================
  void _modalCrearCliente() {
    _nombreCtrl.clear();
    _cedulaCtrl.clear();
    _telCtrl.clear();

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Form(
          key: _formClienteKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Registrar Nuevo Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _cedulaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cédula / Documento', prefixIcon: Icon(Icons.badge)), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _telCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                onPressed: () async {
                  if (_formClienteKey.currentState!.validate()) {
                    try {
                      await _apiService.crearCliente(nombre: _nombreCtrl.text, cedula: _cedulaCtrl.text, telefono: _telCtrl.text);
                      if (context.mounted) Navigator.pop(context);
                      _buscarClientes();
                      _mostrarSnackBar('Cliente creado con éxito', Colors.green);
                    } catch (e) { 
                      _mostrarSnackBar(e.toString(), Colors.red); 
                    }
                  }
                },
                child: const Text('Guardar Cliente'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FORMULARIO MODAL: NUEVO PRÉSTAMO =================
  void _modalCrearPrestamo(String clienteId, String nombreCliente) {
    _montoCtrl.clear();
    _interesCtrl.text = "20"; // Tasa por defecto sugerida

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Form(
          key: _formPrestamoKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dar Préstamo a: $nombreCliente', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 15),
              TextFormField(controller: _montoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto a Prestar (\$)', prefixIcon: Icon(Icons.money)), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _interesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tasa de Interés % (Ej: 20)', prefixIcon: Icon(Icons.percent)), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                onPressed: () async {
                  if (_formPrestamoKey.currentState!.validate()) {
                    try {
                      await _apiService.crearPrestamo(
                        clienteId: clienteId,
                        monto: double.tryParse(_montoCtrl.text) ?? 0.0,
                        interes: double.tryParse(_interesCtrl.text) ?? 0.0,
                      );
                      if (context.mounted) Navigator.pop(context);
                      _buscarClientes();
                      widget.onCambioNegocio(); // Auto-actualiza el dashboard
                      _mostrarSnackBar('¡Préstamo otorgado e ingresado a cartera!', Colors.green);
                    } catch (e) { 
                      _mostrarSnackBar(e.toString(), Colors.red); 
                    }
                  }
                },
                child: const Text('Aprobar y Entregar Dinero'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FORMULARIO MODAL: REGISTRAR ABONO =================
  void _modalRegistrarAbono(String prestamoId, double saldoActual, String nombreCliente) {
    _montoCtrl.clear(); // Usado para Capital
    _interesCtrl.clear(); // Usado para Interés

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Form(
          key: _formAbonoKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cobrar Cuota - $nombreCliente', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Saldo Pendiente Total: \$$saldoActual', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextFormField(
                controller: _interesCtrl, 
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(labelText: 'Pago a Interés (\$)', prefixIcon: Icon(Icons.percent)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoCtrl, 
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(labelText: 'Abono Directo a Capital (\$)', prefixIcon: Icon(Icons.payments)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                onPressed: () async {
                  double capital = double.tryParse(_montoCtrl.text) ?? 0.0;
                  double interes = double.tryParse(_interesCtrl.text) ?? 0.0;

                  if (capital == 0 && interes == 0) {
                    _mostrarSnackBar('Debes ingresar al menos un valor', Colors.orange);
                    return;
                  }

                  try {
                    // Corregido para enviar de forma independiente Capital e Interés según tu ApiService
                    await _apiService.registrarAbono(
                      prestamoId: prestamoId, 
                      montoCapital: capital,
                      montoInteres: interes,
                    );
                    if (context.mounted) Navigator.pop(context);
                    _buscarClientes();
                    widget.onCambioNegocio(); // Refresca Dashboard en vivo
                    _mostrarSnackBar('¡Abono procesado correctamente!', Colors.green);
                  } catch (e) { 
                    _mostrarSnackBar(e.toString(), Colors.red); 
                  }
                },
                child: const Text('Procesar Pago Recibido'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Buscador superior estético
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Buscar cliente por cédula...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear), 
                  onPressed: () { _searchController.clear(); _buscarClientes(); }
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => _buscarClientes(),
            ),
          ),

          // Lista de clientes con sus préstamos activos amarrados
          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _clientes.isEmpty
                ? const Center(child: Text('No hay clientes registrados.'))
                : ListView.builder(
                    itemCount: _clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = _clientes[index];

                      // EXTRACCIÓN BLINDADA Y COMPLETA DE PRÉSTAMOS
                      final listaPrestamos = cliente['prestamos'];
                      final bool tienePrestamos = listaPrestamos != null && (listaPrestamos as List).isNotEmpty;

                      Map<String, dynamic>? prestamoActivo;
                      if (tienePrestamos) {
                        try {
                          prestamoActivo = (listaPrestamos as List).firstWhere(
                            (p) => p != null && p['estado'].toString().trim().toLowerCase() == 'activo',
                            orElse: () => null,
                          );
                        } catch (e) {
                          prestamoActivo = null;
                        }
                      }

                      final String clienteId = cliente['id'].toString();

                      // Extracción segura del saldo soportando ambas llaves estructurales posibles
                      final double saldo = double.tryParse(
                        (prestamoActivo?['saldo_actual'] ?? prestamoActivo?['saldo_restante'] ?? 0).toString()
                      ) ?? 0.0;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ExpansionTile(
                          leading: CircleAvatar(backgroundColor: Colors.indigo[50], child: const Icon(Icons.person, color: Colors.indigo)),
                          title: Text(cliente['nombre'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('CC: ${cliente['cedula'] ?? "---"} | Tel: ${cliente['telefono'] ?? "---"}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (prestamoActivo == null)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Prestar'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                      onPressed: () => _modalCrearPrestamo(clienteId, cliente['nombre'] ?? ''),
                                    )
                                  else ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Préstamo Activo:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                        Text('Saldo: \$$saldo', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.monetization_on, size: 16),
                                      label: const Text('Cobrar Cuota'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                                      onPressed: () {
                                        final String prestamoId = prestamoActivo!['id'].toString();
                                        _modalRegistrarAbono(prestamoId, saldo, cliente['nombre'] ?? '');
                                      },
                                    ),
                                  ]
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _modalCrearCliente,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }
}