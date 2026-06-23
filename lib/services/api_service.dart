import 'package:dio/dio.dart';

class ApiService {
  // CONFIGURACIÓN DE TU BACKEND:
  // Si pruebas en Web (Chrome), usas 'localhost'. 
  // Si pruebas en Emulador Android, se usa la IP especial '10.0.2.2'.
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

  // 2. Registrar un movimiento personal (Ingreso o Gasto)
  Future<Map<String, dynamic>> registrarTransaccionPersonal({
    required String tipo,
    required double monto,
    required String categoria,
    String? descripcion,
  }) async {
    try {
      final response = await _dio.post('/finanzas-personales/', data: {
        'tipo': tipo,
        'monto': monto,
        'categoria': categoria,
        'descripcion': descripcion,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al guardar la transacción: $e');
    }
  }

  // 3. Obtener el historial de movimientos personales
  Future<List<dynamic>> obtenerTransaccionesPersonales() async {
    try {
      final response = await _dio.get('/finanzas-personales/');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Error al cargar historial: $e');
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
    required String clienteId, // Recibe un String (UUID)
    required double monto,
    required double interes,
  }) async {
    try {
      final response = await _dio.post('/prestamos/', data: {
        'cliente_id': clienteId,
        'monto_inicial': monto.toInt(), // El backend pide 'monto_inicial'
        'tasa_interes': interes.toInt(), // El backend pide 'tasa_interes'
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

  // 7. Registrar un abono amarrado a un préstamo
  Future<Map<String, dynamic>> registrarAbono({
    required String prestamoId, // El id del préstamo es UUID (String)
    required double monto,
  }) async {
    try {
      final response = await _dio.post('/abonos/', data: {
        'prestamo_id': prestamoId,
        'monto': monto,
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
}