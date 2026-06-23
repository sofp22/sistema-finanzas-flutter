import 'package:dio/dio.dart';

class ApiService {

  static const String _baseUrl = 'http://192.168.1.6:8000';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 5), // Si el backend no responde en 5s, frena.
    receiveTimeout: const Duration(seconds: 3),
  ));

  // 1. URL del Dashboard Separado (Empresa vs Personal)
  Future<Map<String, dynamic>> obtenerDashboardResumen() async {
    try {
      final response = await _dio.get('/dashboard/resumen');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al conectar con el backend: $e');
    }
  }

  // 2. Registrar un movimiento personal (Ingreso o Gasto con Método de Pago)
  Future<Map<String, dynamic>> registrarTransaccionPersonal({
    required String tipo, // 'ingreso' o 'gasto'
    required double monto,
    required String categoria,
    required String metodoPago, // NUEVO: 'cuenta_bancaria', 'efectivo', 'tarjeta_credito'
    String? descripcion,
  }) async {
    try {
      final response = await _dio.post('/finanzas-personales/', data: {
        'tipo': tipo,
        'monto': monto,
        'categoria': categoria,
        'descripcion': descripcion,
        'metodo_pago': metodoPago, // Mapeado exactamente como lo pide FastAPI
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al guardar la transacción: $e');
    }
  }

  // 3. Obtener el historial de movimientos personales (activos)
  Future<List<dynamic>> obtenerTransaccionesPersonales() async {
    try {
      final response = await _dio.get('/finanzas-personales/');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Error al cargar historial: $e');
    }
  }

  // 3.1. [NUEVO CRUD] Eliminar / Anular una transacción personal
  Future<Map<String, dynamic>> eliminarTransaccionPersonal(String transaccionId) async {
    try {
      final response = await _dio.delete('/finanzas-personales/$transaccionId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al eliminar transacción: $e');
    }
  }

  // 4. Obtener todos los clientes (con opción de buscar por cédula)
  Future<List<dynamic>> obtenerClientes({String? cedula}) async {
    try {
      final queryParams = cedula != null && cedula.isNotEmpty ? {'cedula': cedula} : null;
      final response = await _dio.get('/clientes/', queryParameters: queryParams);
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Error al cargar clientes: $e');
    }
  }

  // 5. Crear un cliente nuevo
  Future<Map<String, dynamic>> crearCliente({
    required String nombre,
    required String cedula,
    required String telefono,
  }) async {
    try {
      final response = await _dio.post('/clientes/', data: {
        'nombre': nombre,
        'cedula': cedula,
        'telefono': telefono,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  // 6. Crear un préstamo amarrado a un cliente
  Future<Map<String, dynamic>> crearPrestamo({
    required String clienteId, 
    required double monto,
    required double interes,
  }) async {
    try {
      final response = await _dio.post('/prestamos/', data: {
        'cliente_id': clienteId,
        'monto_inicial': monto.toInt(), 
        'tasa_interes': interes.toInt(), 
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception('El backend dice: ${e.response?.data}');
      }
      throw Exception('Error al otorgar préstamo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // 7. Registrar un abono amarrado a un préstamo (Separando Capital e Interés)
  Future<Map<String, dynamic>> registrarAbono({
    required String prestamoId, 
    required double montoCapital, // MODIFICADO: Dinero que disminuye la deuda
    required double montoInteres, // MODIFICADO: Dinero de ganancia líquida
  }) async {
    try {
      final response = await _dio.post('/abonos/', data: {
        'prestamo_id': prestamoId,
        'monto_capital': montoCapital,
        'monto_interes': montoInteres,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception('El backend dice: ${e.response?.data}');
      }
      throw Exception('Error al registrar abono: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // 7.1. [NUEVO CRUD] Anular un abono (Restaura la deuda del cliente automáticamente)
  Future<Map<String, dynamic>> anularAbono(String abonoId) async {
    try {
      final response = await _dio.delete('/abonos/$abonoId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception('${e.response?.data['detail'] ?? e.response?.data}');
      }
      throw Exception('Error al anular abono: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // 7.2. [NUEVO CRUD] Editar un abono (Recalcula deudas en caliente)
  Future<Map<String, dynamic>> editarAbono({
    required String abonoId,
    required double montoCapital,
    required double montoInteres,
  }) async {
    try {
      final response = await _dio.put('/abonos/$abonoId', data: {
        'monto_capital': montoCapital,
        'monto_interes': montoInteres,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception('${e.response?.data['detail'] ?? e.response?.data}');
      }
      throw Exception('Error al editar abono: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  Future<List<dynamic>> obtenerAbonosPorPrestamo(String prestamoId) async {
  try {
    // Ajusta la URL '/abonos/prestamo/' según cómo la tengas construida en FastAPI (Backend)
    final response = await _dio.get(
      '$_baseUrl/abonos/prestamo/$prestamoId',
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Error al obtener abonos: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de conexión al obtener abonos: $e');
  }
}

}