import 'package:dio/dio.dart';

class ApiService {
  // CONFIGURACIÓN DE TU BACKEND:
  // Si pruebas en Web (Chrome), usas 'localhost'. 
  // Si pruebas en Emulador Android, se usa la IP especial '10.0.2.2'.
  static const String _baseUrl = 'http://127.0.0.1:8000'; 

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

}