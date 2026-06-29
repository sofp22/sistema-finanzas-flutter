import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _balanceFuture;

  // Controladores de texto para capturar los inputs del formulario de creación
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _balanceFuture = _apiService.obtenerResumenBalancePrivado();
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _refreshBalance() async {
    setState(() {
      _balanceFuture = _apiService.obtenerResumenBalancePrivado();
    });
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 1️⃣ LÓGICA PARA REINICIAR / COMPLETAR OBLIGACIÓN
  Future<void> _confirmarYCompletar(String id) async {
    final bool? seguro = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('¿Completar mes?'),
          ],
        ),
        content: const Text('El progreso de esta obligación se reiniciará a \$0 para comenzar el ahorro del próximo mes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aceptar y Reiniciar')),
        ],
      ),
    );

    if (seguro == true) {
      try {
        await _apiService.completarObligacion(id);
        _refreshBalance();
        _mostrarSnackBar('¡Ciclo mensual reiniciado con éxito! 🔁', Colors.green);
      } catch (e) {
        _mostrarSnackBar('Error al completar: $e', Colors.red);
      }
    }
  }

  // 2️⃣ LÓGICA PARA ELIMINAR OBLIGACIÓN
  Future<void> _confirmarYEliminar(String id) async {
    final bool? seguro = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('¿Eliminar obligación?'),
          ],
        ),
        content: const Text('Esta acción borrará la meta de balance por completo. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (seguro == true) {
      try {
        await _apiService.eliminarObligacion(id);
        _refreshBalance();
        _mostrarSnackBar('Obligación eliminada correctamente', Colors.orange);
      } catch (e) {
        _mostrarSnackBar('Error al eliminar: $e', Colors.red);
      }
    }
  }

  // 3️⃣ LÓGICA MODAL PARA EDITAR VALORES EXISTENTES
  void _mostrarFormularioEditar(dynamic ob) {
    final String id = ob['id'].toString();
    final TextEditingController editConceptoCtrl = TextEditingController(text: ob['concepto'] ?? '');
    final TextEditingController editMontoCtrl = TextEditingController(text: (ob['monto_meta'] ?? 0.0).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Obligación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editConceptoCtrl,
                decoration: const InputDecoration(labelText: 'Concepto', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: editMontoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto Meta Mensual (\$)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              final nuevoConcepto = editConceptoCtrl.text.trim();
              final double nuevoMonto = double.tryParse(editMontoCtrl.text.trim()) ?? 0.0;

              if (nuevoConcepto.isEmpty || nuevoMonto <= 0) {
                _mostrarSnackBar('Por favor llena los campos correctamente', Colors.orange);
                return;
              }

              try {
                await _apiService.editarObligacion(id, nuevoConcepto, nuevoMonto);
                if (!mounted) return;
                Navigator.pop(context);
                _refreshBalance();
                _mostrarSnackBar('¡Actualizado correctamente! 💾', Colors.green);
              } catch (e) {
                _mostrarSnackBar('Error al editar: $e', Colors.red);
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    ).then((_) {
      editConceptoCtrl.dispose();
      editMontoCtrl.dispose();
    });
  }

  // 📝 VENTANA EMERGENTE CON FORMULARIO PARA CREAR NUEVAS OBLIGACIONES
  void _mostrarFormularioObligacion() {
    _conceptoController.clear();
    _montoController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              TextField(
                controller: _conceptoController,
                decoration: const InputDecoration(
                  labelText: 'Concepto (Ej: Pago Tarjeta, Transporte)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 15),
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () async {
                    final concepto = _conceptoController.text.trim();
                    final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;

                    if (concepto.isEmpty || monto <= 0) {
                      _mostrarSnackBar('Por favor llena todos los campos correctamente', Colors.orange);
                      return;
                    }

                    try {
                      await _apiService.registrarObligacionMensual(concepto, monto);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _refreshBalance();
                      _mostrarSnackBar('Obligación agregada correctamente', Colors.green);
                    } catch (e) {
                      _mostrarSnackBar('Error: $e', Colors.red);
                    }
                  },
                  child: const Text('Guardar Obligación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
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
                            final String obId = ob['id'].toString();

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
                                        // Título Expandido para evitar desbordes visuales
                                        Expanded(
                                          child: Text(
                                            ob['concepto'] ?? 'Obligación', 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Contenedor de montos + Menú desplegable de acciones
                                        Row(
                                          children: [
                                            Text(
                                              '\$${pagado.toStringAsFixed(0)} / \$${meta.toStringAsFixed(0)}', 
                                              style: TextStyle(color: Colors.grey.shade700),
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onSelected: (value) {
                                                if (value == 'completar') {
                                                  _confirmarYCompletar(obId);
                                                } else if (value == 'editar') {
                                                  _mostrarFormularioEditar(ob);
                                                } else if (value == 'eliminar') {
                                                  _confirmarYEliminar(obId);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'completar',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Completar y Reiniciar'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'editar',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, color: Colors.blue, size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Editar Valores'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'eliminar',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, color: Colors.red, size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Eliminar Deuda', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
                              leading: CircleAvatar(backgroundColor: colorIcono.withAlpha((0.1 * 255).round()), child: Icon(icono, color: colorIcono)),
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