import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ IP laptop Anda di jaringan WiFi iamhmzh
  // Kalau IP laptop berubah, cek lagi lewat: ipconfig
  static const String _lanIp = '192.168.1.5';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/api';
    } else {
      return 'http://$_lanIp/api';
    }
  }

  // ==========================================
  // 1. FUNGSI REGISTER
  // ==========================================
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/register.php'),
            body: {'nama': nama, 'email': email, 'password': password},
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Error: $e'};
    }
  }

  // ==========================================
  // 2. FUNGSI LOGIN
  // ==========================================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/login.php'),
            body: {'email': email, 'password': password},
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Error: $e'};
    }
  }

  // ==========================================
  // 3. FUNGSI AMBIL DAFTAR NOTA
  // ==========================================
  static Future<Map<String, dynamic>> getNotas(int userId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/notas.php?user_id=$userId'))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Error: $e'};
    }
  }

  // ==========================================
  // 4. FUNGSI SIMPAN NOTA
  // ==========================================
  static Future<Map<String, dynamic>> simpanNota({
    required int userId,
    required String judul,
    required String isi,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/notas.php'),
            body: {'user_id': '$userId', 'judul': judul, 'isi': isi},
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Error: $e'};
    }
  }
}