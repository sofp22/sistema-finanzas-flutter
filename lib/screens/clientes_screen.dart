import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'cliente_detalle_screen.dart'; 

class ClientesScreen extends StatefulWidget {
  final VoidCallback onCambioNegocio; 
  const ClientesScreen({super.key, required this.onCambioNegocio});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _clientes = [];
  bool _cargando = false;
  final _searchController = TextEditingController();

  final _formClienteKey = GlobalKey<FormState>();
  final _formPrestamoKey = GlobalKey<FormState>();

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
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // ================= ELIMINAR CLIENTE =================
  Future<void> _eliminarCliente(String clienteId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Cliente?'),
        content: const Text('Esta acción no se puede deshacer. Si el cliente tiene préstamos activos, la base de datos podría bloquear la eliminación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sí, Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _apiService.eliminarCliente(clienteId);
        _mostrarSnackBar('Cliente eliminado correctamente', Colors.green);
        _buscarClientes(); 
      } catch (e) {
        _mostrarSnackBar('No se pudo eliminar: $e', Colors.red);
      }
    }
  }

  // ================= FORMULARIO MODAL: CREAR O EDITAR CLIENTE =================
  void _modalCliente({Map<String, dynamic>? clienteExistente}) {
    final bool esEdicion = clienteExistente != null;
    
    _nombreCtrl.text = esEdicion ? clienteExistente['nombre'] ?? '' : '';
    _cedulaCtrl.text = esEdicion ? clienteExistente['cedula'] ?? '' : '';
    _telCtrl.text = esEdicion ? clienteExistente['telefono'] ?? '' : '';

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
              Text(esEdicion ? 'Editar Cliente' : 'Registrar Nuevo Cliente', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _cedulaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cédula / Documento', prefixIcon: Icon(Icons.badge)), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _telCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: esEdicion ? Colors.blue : Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                onPressed: () async {
                  if (_formClienteKey.currentState!.validate()) {
                    try {
                      if (esEdicion) {
                        await _apiService.editarCliente(
                          clienteExistente['id'].toString(), 
                          {'nombre': _nombreCtrl.text, 'cedula': _cedulaCtrl.text, 'telefono': _telCtrl.text}
                        );
                        _mostrarSnackBar('Cliente actualizado con éxito', Colors.blue);
                      } else {
                        await _apiService.crearCliente(nombre: _nombreCtrl.text, cedula: _cedulaCtrl.text, telefono: _telCtrl.text);
                        _mostrarSnackBar('Cliente creado con éxito', Colors.green);
                      }
                      if (context.mounted) Navigator.pop(context);
                      _buscarClientes();
                    } catch (e) { 
                      _mostrarSnackBar(e.toString(), Colors.red); 
                    }
                  }
                },
                child: Text(esEdicion ? 'Actualizar Cliente' : 'Guardar Cliente'),
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
    _interesCtrl.text = "20"; 

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
                      widget.onCambioNegocio(); 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _clientes.isEmpty
                ? const Center(child: Text('No hay clientes registrados.'))
                : ListView.builder(
                    itemCount: _clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = _clientes[index];
                      final listaPrestamos = cliente['prestamos'];
                      final bool tienePrestamos = listaPrestamos != null && (listaPrestamos as List).isNotEmpty;

                      Map<String, dynamic>? prestamoActivo;
                      
                      // MAGIA: Validación Inmune a "Activo", "activo", "ACTIVO" o "pendiente"
                      if (tienePrestamos) {
                        try {
                          final prestamos = listaPrestamos as List;
                          prestamoActivo = prestamos.firstWhere((p) {
                            if (p == null) return false;
                            final saldo = double.tryParse((p['saldo_actual'] ?? p['saldo_restante'] ?? 0).toString()) ?? 0.0;
                            // Esto convierte cualquier cosa a minúsculas, así no importará cómo lo mande el backend
                            final estado = p['estado']?.toString().trim().toLowerCase() ?? '';
                            
                            return estado == 'activo' || estado == 'pendiente' || saldo > 0;
                          }, orElse: () => null);

                          if (prestamoActivo == null && prestamos.isNotEmpty) {
                             prestamoActivo = prestamos.last;
                          }
                        } catch (e) {
                          prestamoActivo = null;
                        }
                      }

                      final String clienteId = cliente['id'].toString();
                      final double saldo = double.tryParse(
                        (prestamoActivo?['saldo_actual'] ?? prestamoActivo?['saldo_restante'] ?? 0).toString()
                      ) ?? 0.0;

                      // Si no hay préstamo activo y el saldo es 0, no tiene deudas
                      final bool sinDeudas = prestamoActivo == null || (saldo <= 0 && prestamoActivo['estado'].toString().toLowerCase() != 'activo');

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.indigo[50], child: const Icon(Icons.person, color: Colors.indigo)),
                          title: Text(cliente['nombre'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            sinDeudas
                                ? 'CC: ${cliente['cedula'] ?? "---"} | Sin deudas'
                                : 'CC: ${cliente['cedula'] ?? "---"} | Saldo: \$$saldo',
                            style: TextStyle(color: sinDeudas ? Colors.grey[600] : Colors.red),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              sinDeudas
                                  ? IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
                                      onPressed: () => _modalCrearPrestamo(clienteId, cliente['nombre'] ?? ''),
                                    )
                                  : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.indigo),
                              
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (value) {
                                  if (value == 'editar') {
                                    _modalCliente(clienteExistente: cliente);
                                  } else if (value == 'eliminar') {
                                    _eliminarCliente(clienteId);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Editar')])),
                                  const PopupMenuItem(value: 'eliminar', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!sinDeudas && prestamoActivo != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClienteDetalleScreen(
                                    cliente: cliente, 
                                    prestamo: prestamoActivo!,
                                  ),
                                ),
                              ).then((_) {
                                _buscarClientes(); 
                                widget.onCambioNegocio(); 
                              });
                            } else {
                              _mostrarSnackBar('Este cliente no tiene un préstamo activo. Dale al botón (+) para crear uno.', Colors.orange);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _modalCliente(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }
}