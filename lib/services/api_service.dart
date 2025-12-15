import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
// تعديل اسم الحزمة هنا
import 'package:iptv_flutter/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Riverpod Provider for the API Service
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class Credentials {
  final String host;
  final String username;
  final String password;

  Credentials(this.host, this.username, this.password);

  String get apiUrl {
    // Construct the base API URL using the provided credentials
    return '${host.replaceAll(RegExp(r'/(player_api\.php)?$'), '')}/player_api.php?username=$username&password=$password';
  }
}

class ApiService {
  Credentials? _credentials;

  // -----------------------------------------------------------------
  // Local Storage (Shared Preferences)
  // -----------------------------------------------------------------

  Future<void> saveCredentials(Credentials creds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('host', creds.host);
    await prefs.setString('username', creds.username);
    await prefs.setString('password', creds.password);
    _credentials = creds;
  }

  Future<Credentials?> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('host');
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (host != null && username != null && password != null) {
      _credentials = Credentials(host, username, password);
      return _credentials;
    }
    return null;
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _credentials = null;
  }

  // -----------------------------------------------------------------
  // Data Fetching Functions
  // -----------------------------------------------------------------

  Future<LoginResponse> login(String host, String username, String password) async {
    if (!host.startsWith('http')) host = 'http://$host'; // Ensure scheme is present

    final creds = Credentials(host, username, password);
    // Use get_live_streams as a simple API check action
    final url = Uri.parse('${creds.apiUrl}&action=get_live_streams');
    
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data.containsKey('user_info') && data['user_info']['auth'] == 1) {
      final loginData = LoginResponse.fromJson(data);
      await saveCredentials(creds);
      return loginData;
    } else {
      throw Exception(data['user_info']['message'] ?? 'فشل تسجيل الدخول: بيانات غير صحيحة');
    }
  }

  Future<List<Category>> fetchCategories(String type) async {
    if (_credentials == null) throw Exception('User not logged in');

    String action;
    if (type == 'live') action = 'get_live_categories';
    else if (type == 'vod') action = 'get_vod_categories';
    else if (type == 'series') action = 'get_series_categories';
    else throw Exception('Invalid category type');

    final url = Uri.parse('${_credentials!.apiUrl}&action=$action');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  Future<List<StreamItem>> fetchStreams(String type, {String? categoryId}) async {
    if (_credentials == null) throw Exception('User not logged in');

    String action;
    if (type == 'live') action = 'get_live_streams';
    else if (type == 'vod') action = 'get_vod_streams';
    else if (type == 'series') action = 'get_series';
    else throw Exception('Invalid stream type');

    String url = '${_credentials!.apiUrl}&action=$action';
    if (categoryId != null && categoryId != '0') {
      url += '&category_id=$categoryId';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      // Inject stream type into the model
      return jsonList.map((json) {
        return StreamItem.fromJson({...json, 'stream_type': type});
      }).toList();
    } else {
      throw Exception('Failed to load streams: ${response.statusCode}');
    }
  }
}
