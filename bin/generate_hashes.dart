import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  String password1 = 'Hernandez14';
  String password2 = 'admin123';
  String password3 = '123456';
  
  print('=== SHA256 Password Hashes ===');
  print('hairo password: $password1');
  print('Hash: ${sha256.convert(utf8.encode(password1)).toString()}');
  print('');
  print('admin password: $password2');
  print('Hash: ${sha256.convert(utf8.encode(password2)).toString()}');
  print('');
  print('superadmin password: $password3');
  print('Hash: ${sha256.convert(utf8.encode(password3)).toString()}');
}
