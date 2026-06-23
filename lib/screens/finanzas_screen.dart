import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FinanzasScreen extends StatefulWidget {
  final VoidCallback onTransaccionAgregada; // Para refrescar el dashboard al guardar
  const FinanzasScreen({super.key, required this.onTransaccionAgregada});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _historial = [];
  bool _cargando = true;

  // Controladores para el formulario de agregar gasto/ingreso
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descController = TextEditingController();
  String _tipoSeleccionado = 'gasto';
  String _categoriaSeleccionada = 'Comida';
  String _metodoPagoSeleccionado = 'Efectivo';
final List<String> _metodosPago = ['Efectivo', 'Transferencia'];

  final List<String> _categorias = ['Comida', 'Arriendo', 'Transporte', 'Salario', 'Servicios', 'Entretenimiento', 'Otros'];

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

  void _guardarTransaccion() async {
    if (_formKey.currentState!.validate()) {
      try {
        final double montoParsed = double.tryParse(_montoController.text) ?? 0.0;
        
        if (montoParsed <= 0) {
          _mostrarSnackBar('Por favor, ingresa un monto mayor a 0', Colors.orange);
          return;
        }

        // Busca esta sección en tu finanzas_screen.dart y déjala así:
await _apiService.registrarTransaccionPersonal(
  tipo: _tipoSeleccionado,
  monto: montoParsed,
  categoria: _categoriaSeleccionada,
  metodoPago: _metodoPagoSeleccionado, // <--- ¡AQUÍ SE AGREGA EL ARGUMENTO FALTARE!
  descripcion: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
);
        
        // Verificación de contexto seguro antes de manipular la navegación o UI
        if (!mounted) return;
        
        _montoController.clear();
        _descController.clear();
        Navigator.pop(context); // Cierra el formulario modal
        
        _cargarHistorial(); // Refresca esta pantalla
        widget.onTransaccionAgregada(); // Refresca el Dashboard general
        
        _mostrarSnackBar('¡Registro exitoso! 🎉', Colors.green);
      } catch (e) {
        _mostrarSnackBar('Error al guardar: $e', Colors.red);
      }
    }
  }

  void _mostrarSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // Ventana moderna que emerge desde abajo para registrar datos (UX Limpia)
  void _mostrarFormularioModal() {
    // Limpiamos y reestablecemos valores por defecto antes de abrir el modal
    _montoController.clear();
    _descController.clear();
    _tipoSeleccionado = 'gasto';
    _categoriaSeleccionada = 'Comida';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder( // Permite cambiar estados visuales dentro del modal en tiempo real
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Evita que el teclado tape el botón
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
                      
                      // Selector de Tipo de Movimiento (Estilo Segmentado)
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

                      // Input de Monto con diseño limpio
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

                      // Dropdown de Categorías
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

                      // Debajo del Dropdown de Categoría, añade esto:
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
                      
                      // Nota opcional
                      TextFormField(
                        controller: _descController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Descripción / Nota (Opcional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón Guardar Dinámico e Inteligente
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _historial.isEmpty
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _historial.length,
                    itemBuilder: (context, index) {
                      final item = _historial[index];
                      final esGasto = item['tipo'].toString().trim().toLowerCase() == 'gasto';
                      
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
                          trailing: Text(
                            '${esGasto ? "-" : "+"}\$${item['monto']}',
                            style: TextStyle(
                              color: esGasto ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioModal,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Movimiento'),
      ),
    );
  }
}