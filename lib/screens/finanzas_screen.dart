import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'balance_screen.dart';

class FinanzasScreen extends StatefulWidget {
  final VoidCallback onTransaccionAgregada; 
  const FinanzasScreen({super.key, required this.onTransaccionAgregada});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _historial = [];
  bool _cargando = true;

  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descController = TextEditingController();
  String _tipoSeleccionado = 'gasto';
  String _categoriaSeleccionada = 'Comida';
  String _metodoPagoSeleccionado = 'Efectivo';
  
  final List<String> _metodosPago = ['Efectivo', 'Transferencia', 'Tarjeta de Crédito', 'Otro'];
  final List<String> _categorias = ['Comida', 'Arriendo', 'Transporte', 'Salario', 'Servicios', 'Entretenimiento', 'prestamo', 'abono capital', 'abono interes', 'pago responsabilidades', 'pago capital', 'pago interes', 'Otro'];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final datos = await _apiService.obtenerTransaccionesPersonales();
      if (mounted) {
        setState(() {
          _historial = datos;
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

  // ================= ELIMINAR TRANSACCIÓN =================
  Future<void> _eliminarTransaccion(String transaccionId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: const Text('Esta acción modificará los saldos de tu Dashboard.'),
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
        await _apiService.eliminarTransaccionPersonal(transaccionId);
        _mostrarSnackBar('Transacción eliminada', Colors.green);
        _cargarHistorial(); 
        widget.onTransaccionAgregada(); // Refresca el Dashboard general
      } catch (e) {
        _mostrarSnackBar('Error al eliminar: $e', Colors.red);
      }
    }
  }

  // Traductor UI -> Backend para el Método de Pago
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

  void _guardarTransaccion() async {
    if (_formKey.currentState!.validate()) {
      try {
        final double montoParsed = double.tryParse(_montoController.text) ?? 0.0;
        
        if (montoParsed <= 0) {
          _mostrarSnackBar('Por favor, ingresa un monto mayor a 0', Colors.orange);
          return;
        }

        // CORRECCIÓN MAGNA: Enviamos el formato exacto que pide FastAPI
        await _apiService.registrarTransaccionPersonal(
          tipo: _tipoSeleccionado,
          monto: montoParsed,
          categoria: _categoriaSeleccionada,
          metodoPago: _mapearMetodoPagoParaBackend(_metodoPagoSeleccionado),
          descripcion: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        );
        
        if (!mounted) return;
        
        _montoController.clear();
        _descController.clear();
        Navigator.pop(context); 
        
        _cargarHistorial(); 
        widget.onTransaccionAgregada(); 
        
        _mostrarSnackBar('¡Registro exitoso! 🎉', Colors.green);
      } catch (e) {
        _mostrarSnackBar('Error al guardar: $e', Colors.red);
      }
    }
  }

  void _mostrarSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _mostrarFormularioModal() {
    _montoController.clear();
    _descController.clear();
    _tipoSeleccionado = 'gasto';
    _categoriaSeleccionada = 'Comida';
    _metodoPagoSeleccionado = 'Efectivo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, 
                top: 24, left: 24, right: 24,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nuevo Movimiento Personal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Gasto 🔻')),
                              selected: _tipoSeleccionado == 'gasto',
                              selectedColor: Colors.red[100],
                              onSelected: (val) => setModalState(() => _tipoSeleccionado = 'gasto'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Ingreso 🔺')),
                              selected: _tipoSeleccionado == 'ingreso',
                              selectedColor: Colors.green[100],
                              onSelected: (val) => setModalState(() => _tipoSeleccionado = 'ingreso'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _montoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Monto (\$)',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Digita un valor válido' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _categoriaSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _categorias.map((String cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) => setModalState(() => _categoriaSeleccionada = val!),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _metodoPagoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _metodosPago.map((String metodo) {
                          return DropdownMenuItem(value: metodo, child: Text(metodo));
                        }).toList(),
                        onChanged: (val) => setModalState(() => _metodoPagoSeleccionado = val!),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Descripción / Nota (Opcional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tipoSeleccionado == 'gasto' ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _guardarTransaccion,
                          child: const Text('Guardar Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌟 LE AGREGAMOS UN HEROTAG ÚNICO PARA QUITAR EL ERROR ROJO DE LA CONSOLA
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_registrar_movimiento_personal', // <--- Solución al problema de múltiples Heroes
        onPressed: _mostrarFormularioModal,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Movimiento'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 💳 BOTÓN DE ACCESO AL BALANCE PRIVADO (Opción B)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BalancePage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Ver Mi Balance Privado y Ahorros',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // HISTORIAL DE TRANSACCIONES
                Expanded(
                  child: _historial.isEmpty
                      ? const Center(
                          child: Text(
                            'Aún no hay registros personales.\n¡Toca el botón + abajo!', 
                            textAlign: TextAlign.center, 
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarHistorial,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Margen abajo para que el FAB no tape nada
                            itemCount: _historial.length,
                            itemBuilder: (context, index) {
                              final item = _historial[index];
                              final esGasto = item['tipo'].toString().trim().toLowerCase() == 'gasto';
                              final transaccionId = item['id'].toString();
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: esGasto ? Colors.red[50] : Colors.green[50],
                                    child: Icon(
                                      esGasto ? Icons.arrow_downward : Icons.arrow_upward, 
                                      color: esGasto ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  title: Text(item['categoria'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(item['descripcion'] ?? 'Sin descripción'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${esGasto ? "-" : "+"}\$${item['monto']}',
                                        style: TextStyle(
                                          color: esGasto ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        onSelected: (value) {
                                          if (value == 'eliminar') {
                                            _eliminarTransaccion(transaccionId);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'eliminar', 
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red, size: 20),
                                                SizedBox(width: 8),
                                                Text('Eliminar', style: TextStyle(color: Colors.red))
                                              ],
                                            ),
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
                ),
              ],
            ),
    );
  }
}