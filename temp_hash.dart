import 'package:crypto/crypto.dart';

void main() {
  final password = 'Hernandez14';
  final hashedPassword = sha256.convert(password.codeUnits).toString();
  print('Password: $password');
  print('Hashed: $hashedPassword');
}
