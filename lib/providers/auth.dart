import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import '../models/http_exception.dart';
import '../secrets/secret.dart' as secret;

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;

  static const String apiKey = secret.API_KEY;

  bool get isAuth {
    return token != null;
  }

  String get userId {
    return _userId;
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  Future<void> _authenticate(
      String email, String password, String segment) async {
    try {
      final url =
          'https://identitytoolkit.googleapis.com/v1/accounts:$segment?key=$apiKey';
      final response = await http.post(url,
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true
          }));

      final responseData = json.decode(response.body);
      //print(responseData);
      if (responseData['error'] != null) {
        //print(responseData['error']['message']);
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  void logout() {
    _token = null;
    _userId = null;
    _expiryDate = null;
    notifyListeners();
  }
}
