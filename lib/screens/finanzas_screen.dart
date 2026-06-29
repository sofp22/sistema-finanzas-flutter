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

  double _saldoDisponible = 0.0;
  double _totalGastos = 0.0;
  double _totalIngresos = 0.0;

  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descController = TextEditingController();
  
  String _tipoSeleccionado = 'gasto';
  String _categoriaSeleccionada = 'Comida';
  String _metodoPagoSeleccionado = 'Efectivo';

  final List<String> _categorias = [
    'Comida', 'Arriendo', 'Transporte', 'Salario', 'Servicios', 
    'Entretenimiento', 'Prestamo', 'Otro'
  ];

  final List<String> _metodosPago = [
    'Efectivo', 'Transferencia', 'Tarjeta de Crédito'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    // Petición 1: Historial de movimientos
    try {
      final datosHistorial = await _apiService.obtenerTransaccionesPersonales();
      if (mounted) {
        setState(() {
          _historial = datosHistorial;
        });
      }
    } catch (e) {
      debugPrint("🚨 Error en historial: $e");
    }

    // Petición 2: Resumen numérico del Dashboard
    try {
      final resumenBackend = await _apiService.obtenerResumenFinancieroTotal(); 
      final finanzasPersonales = resumenBackend['finanzas_personales'];

      if (mounted && finanzasPersonales != null) {
        setState(() {
          _saldoDisponible = double.tryParse(finanzasPersonales['mi_dinero_libre_disponible'].toString()) ?? 0.0;
          _totalGastos = double.tryParse(finanzasPersonales['mis_gastos_totales'].toString()) ?? 0.0;
          _totalIngresos = double.tryParse(finanzasPersonales['mis_ingresos_totales'].toString()) ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint("🚨 Error en saldos: $e");
    }

    if (mounted) {
      setState(() => _cargando = false);
    }
  }

  void _guardarTransaccion() async {
    if (_formKey.currentState!.validate()) {
      try {
        final double montoParsed = double.tryParse(_montoController.text) ?? 0.0;
        if (montoParsed <= 0) return;

        await _apiService.registrarTransaccionPersonal(
          tipo: _tipoSeleccionado,
          monto: montoParsed,
          categoria: _categoriaSeleccionada,
          metodoPago: _mapearMetodoPagoParaBackend(_metodoPagoSeleccionado),
          descripcion: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pop(context);
        _cargarDatos(); 
        widget.onTransaccionAgregada();
      } catch (e) {
        debugPrint("Error al guardar: $e");
      }
    }
  }

  void _eliminarTransaccion(String id) async {
  try {
    await _apiService.eliminarTransaccionPersonal(id);
    _cargarDatos(); 
    widget.onTransaccionAgregada();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Movimiento eliminado correctamente')),
    );
  } catch (e) {
    debugPrint("🚨 Error al eliminar movimiento: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al eliminar: $e')),
    );
  }
}

void _editarTransaccion(dynamic item) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Funcionalidad de editar para: ${item['categoria']}')),
  );
}

  String _mapearMetodoPagoParaBackend(String metodoUI) {
    switch (metodoUI) {
      case 'Transferencia': return 'cuenta_bancaria';
      case 'Tarjeta de Crédito': return 'tarjeta_credito';
      default: return 'efectivo';
    }
  }

  void _mostrarFormulario(String tipo) {
    setState(() {
      _tipoSeleccionado = tipo;
      _categoriaSeleccionada = tipo == 'gasto' ? 'Comida' : 'Salario';
      _metodoPagoSeleccionado = 'Efectivo';
    });
    _montoController.clear();
    _descController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder( 
        builder: (context, setModalState) => Padding(
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
                  Center(
                    child: Text(
                      tipo == 'gasto' ? 'Registrar Gasto 🔻' : 'Registrar Ingreso 🔺',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  TextFormField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Monto (\$)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    validator: (v) => v!.isEmpty ? 'Ingresa un valor' : null,
                  ),
                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setModalState(() => _categoriaSeleccionada = v!),
                  ),
                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    value: _metodoPagoSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Método de Pago',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.payment),
                    ),
                    items: _metodosPago.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setModalState(() => _metodoPagoSeleccionado = v!),
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Descripción / Nota (Opcional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tipo == 'gasto' ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _guardarTransaccion,
                      child: const Text('Confirmar Registro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildBalanceCard(),
                    _buildStatsRow(),
                    _buildQuickActions(),
                    _buildHistoryTitle(),
                    _buildHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 60, 24, 10),
      child: Text(
        'Mis Finanzas',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1D21)),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF1A1D21), borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saldo Disponible', style: TextStyle(color: Colors.white60, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text('\$${_saldoDisponible.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          _buildSmallStatCard('Gastos Totales', '\$${_totalGastos.toStringAsFixed(2)}', const Color(0xFFFEF3E7), const Color(0xFFE65100)),
          const SizedBox(width: 15),
          _buildSmallStatCard('Ingresos Totales', '\$${_totalIngresos.toStringAsFixed(2)}', const Color(0xFFE8F5E9), const Color(0xFF1B5E20)),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: textCol, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
          child: Text('Acciones Rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionIcon(Icons.arrow_downward, 'Gasto', () => _mostrarFormulario('gasto')),
            _actionIcon(Icons.arrow_upward, 'Ingreso', () => _mostrarFormulario('greso')),
            _actionIcon(Icons.account_balance_wallet, 'Balance', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BalancePage()));
            }),
            const SizedBox(width: 60), 
            const SizedBox(width: 60),
          ],
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(icon, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildHistoryTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Text('Historial de Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHistoryList() {
    if (_historial.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No hay registros aún.')),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final item = _historial[index];
        final esGasto = item['tipo'].toString().toLowerCase() == 'gasto';
        final double montoElemento = double.tryParse(item['monto'].toString()) ?? 0.0;
        
        // Traducir método de pago del backend a la interfaz
        String metodoUI = 'Efectivo';
        final String metodoBackend = (item['metodo_pago'] ?? '').toString().toLowerCase();
        
        if (metodoBackend == 'cuenta_bancaria') {
          metodoUI = 'Transferencia';
        } else if (metodoBackend == 'tarjeta_credito') {
          metodoUI = 'Tarjeta de Crédito';
        }

        final String desc = (item['descripcion'] ?? '').toString().trim();
        final String subtituloTexto = desc.isEmpty ? metodoUI : '$metodoUI • $desc';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: esGasto ? Colors.red[50] : Colors.green[50],
              child: Icon(esGasto ? Icons.arrow_downward : Icons.arrow_upward, color: esGasto ? Colors.red : Colors.green, size: 18),
            ),
            title: Text(item['categoria'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtituloTexto, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            
            // 🛠️ SECCIÓN MODIFICADA: Ahora agrupa el Monto y un Menú de Opciones (...)
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${esGasto ? "-" : "+"}\$${montoElemento.toStringAsFixed(2)}',
                  style: TextStyle(color: esGasto ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
                  onSelected: (value) {
                    if (value == 'editar') {
                      _editarTransaccion(item);
                    } else if (value == 'eliminar') {
                      // Se pasa el ID dinámico que viene desde tu base de datos
                      _eliminarTransaccion(item['id'].toString());
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar'),
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
    );
  }
}