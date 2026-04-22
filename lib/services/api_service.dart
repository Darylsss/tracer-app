// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';



class ApiService {
  static const Map<String, String> _baseHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  
};
   static const String baseUrl = 'http://192.168.1.81:8000/api';
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Pour émulateur Android
  // static const String baseUrl = 'http://192.168.1.X:8000/api'; // Pour vrai téléphone (remplace X par ton IP)

  // Stocker le token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Récupérer le token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Supprimer le token (déconnexion)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Headers avec token
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Inscription
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {                                          // ← try/catch manquait ici
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _baseHeaders,
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

     // Nettoyer les warnings PHP avant de parser
    final cleanBody = response.body
        .replaceAll(RegExp(r'<br\s*/>'), '')
        .replaceAll(RegExp(r'<b>.*?</b>', dotAll: true), '')
        .trim();

    // Trouver le début du JSON
    final jsonStart = cleanBody.indexOf('{');
    if (jsonStart == -1) {
      return {'success': false, 'error': 'Réponse invalide du serveur'};
    }
    final jsonBody = cleanBody.substring(jsonStart);

    final data = jsonDecode(jsonBody);
    if (response.statusCode == 200 || response.statusCode == 201) {
      await saveToken(data['token']);
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['errors'] ?? data['message'] ?? 'Erreur'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Erreur réseau: $e'}; // ← plus de crash
  }
}
  // Connexion
  Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _baseHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

     // Nettoyer les warnings PHP avant de parser
    final cleanBody = response.body
        .replaceAll(RegExp(r'<br\s*/>'), '')
        .replaceAll(RegExp(r'<b>.*?</b>', dotAll: true), '')
        .trim();

    // Trouver le début du JSON
    final jsonStart = cleanBody.indexOf('{');
    if (jsonStart == -1) {
      return {'success': false, 'error': 'Réponse invalide du serveur'};
    }
    final jsonBody = cleanBody.substring(jsonStart);

    final data = jsonDecode(jsonBody);
    if (response.statusCode == 200) {
      await saveToken(data['token']);
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['message'] ?? 'Identifiants incorrects'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Erreur réseau: $e'};
  }
}
  

  // Déconnexion
  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      await removeToken();
      return {'success': true};
    } else {
      return {'success': false, 'error': 'Erreur lors de la déconnexion'};
    }
  }

  // Récupérer l'utilisateur connecté
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'user': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Non authentifié'};
    }
  }
// Utilitaire pour nettoyer la réponse Laravel
String _cleanBody(String body) {
  final clean = body
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<b>.*?</b>', dotAll: true), '')
      .trim();
  final jsonStart = clean.indexOf('['); // liste
  final jsonStartObj = clean.indexOf('{'); // objet

  if (jsonStart == -1 && jsonStartObj == -1) return clean;
  if (jsonStart == -1) return clean.substring(jsonStartObj);
  if (jsonStartObj == -1) return clean.substring(jsonStart);
  return clean.substring(jsonStart < jsonStartObj ? jsonStart : jsonStartObj);
}

  // Revenus
Future<Map<String, dynamic>> getRevenus() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/revenus'),
      headers: await _getHeaders(),
    );
    print('getRevenus STATUS: ${response.statusCode}');
    print('getRevenus BODY: ${response.body}');

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(_cleanBody(response.body))};
    }
    return {'success': false, 'error': 'Erreur chargement revenus'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

Future<Map<String, dynamic>> addRevenu(String date, String origine, double montant) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/revenus'),
      headers: await _getHeaders(),
      body: jsonEncode({'date': date, 'origine': origine, 'montant': montant}),
    );
    print('addRevenu STATUS: ${response.statusCode}');
    print('addRevenu BODY: ${response.body}');

    if (response.statusCode == 201) {
      return {'success': true};
    }
    // Essayer de lire le message d'erreur
    try {
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['message'] ?? 'Erreur'};
    } catch (_) {
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    }
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

Future<Map<String, dynamic>> deleteRevenu(int id) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/revenus/$id'),
      headers: await _getHeaders(),
    );
    print('deleteRevenu STATUS: ${response.statusCode}');
    return {'success': response.statusCode == 200};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

// Récupérer toutes les dépenses
Future<Map<String, dynamic>> getDepenses() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/depenses'),
      headers: await _getHeaders(),
    );
    print('getDepenses STATUS: ${response.statusCode}');
    print('getDepenses BODY: ${response.body}');

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(_cleanBody(response.body))};
    }
    return {'success': false, 'error': 'Erreur chargement dépenses'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

// Ajouter une dépense
Future<Map<String, dynamic>> addDepense(
  String date,
  String objetDepense,
  double montantDepense, {
  File? justificatif,
}) async {
  try {
    final token = await getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/depenses'),
    );

    // Headers
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept']        = 'application/json';
    request.headers['X-Requested-With'] = 'XMLHttpRequest'; // ← ajoute ça

    // Champs
    request.fields['date']            = date;
    request.fields['objet_depense']   = objetDepense;
    request.fields['montant_depense'] = montantDepense.toString();

    // Fichier
    if (justificatif != null) {
      print('Ajout fichier: ${justificatif.path}');
      final mimeType = justificatif.path.endsWith('.pdf') 
          ? 'application/pdf' 
          : 'image/jpeg';
      request.files.add(http.MultipartFile(
        'justificatif',
        justificatif.readAsBytes().asStream(),
        await justificatif.length(),
        filename: justificatif.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      ));
    }

    final streamed  = await request.send();
    final response  = await http.Response.fromStream(streamed);

    print('addDepense STATUS: ${response.statusCode}');
    print('addDepense BODY: ${response.body}');

    if (response.statusCode == 201) return {'success': true};

    try {
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['message'] ?? 'Erreur'};
    } catch (_) {
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    }
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

// Supprimer une dépense
Future<Map<String, dynamic>> deleteDepense(int id) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/depenses/$id'),
      headers: await _getHeaders(),
    );
    print('deleteDepense STATUS: ${response.statusCode}');
    return {'success': response.statusCode == 200};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
}