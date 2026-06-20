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

  final List<String> _categorias = ['Comida', 'Arriendo', 'Transporte', 'Salario', 'Servicios', 'Entretenimiento', 'Otros'];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    try {
      setState(() => _cargando = true);
      final datos = await _apiService.obtenerTransaccionesPersonales();
      setState(() {
        _historial = datos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _guardarTransaccion() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _apiService.registrarTransaccionPersonal(
          tipo: _tipoSeleccionado,
          monto: double.parse(_montoController.text),
          categoria: _categoriaSeleccionada,
          descripcion: _descController.text.isEmpty ? null : _descController.text,
        );
        
        _montoController.clear();
        _descController.clear();
        Navigator.pop(context); // Cierra el formulario modal
        
        _cargarHistorial(); // Refresca esta pantalla
        widget.onTransaccionAgregada(); // Refresca el Dashboard general
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! 🎉'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Ventana moderna que emerge desde abajo para registrar datos (UX Limpia)
  void _mostrarFormularioModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder( // Permite cambiar estados dentro del modal
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
                        keyboardType: TextInputType.number,
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

                      // Nota opcional
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'Descripción / Nota (Opcional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón Guardar Profesional
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
          }
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
              ? const Center(child: Text('Aún no hay registros personales.\n¡Toca el botón + abajo!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historial.length,
                  itemBuilder: (context, index) {
                    final item = _historial[index];
                    final esGasto = item['tipo'] == 'gasto';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: esGasto ? Colors.red[50] : Colors.green[50],
                          child: Icon(esGasto ? Icons.arrow_downward : Icons.arrow_upward, color: esGasto ? Colors.red : Colors.green),
                        ),
                        title: Text(item['categoria'], style: const TextStyle(fontWeight: FontWeight.bold)),
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