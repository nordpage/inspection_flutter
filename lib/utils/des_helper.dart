import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encryption_pkg;
import 'package:pointycastle/export.dart';

class MyDesCBC implements encryption_pkg.Algorithm {
  final encryption_pkg.Key key;

  MyDesCBC(this.key);

  @override
  encryption_pkg.Encrypted encrypt(
      Uint8List bytes, {
        Uint8List? associatedData,
        encryption_pkg.IV? iv,
      }) {
    if (iv == null) {
      throw ArgumentError('IV required for DES/CBC');
    }
    final cipher = PaddedBlockCipher('DES/CBC/PKCS7')
      ..init(
        true,
        PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(key.bytes), iv.bytes),
          null,
        ),
      );
    return encryption_pkg.Encrypted(cipher.process(bytes));
  }

  @override
  Uint8List decrypt(
      encryption_pkg.Encrypted encrypted, {
        Uint8List? associatedData,
        encryption_pkg.IV? iv,
      }) {
    if (iv == null) {
      throw ArgumentError('IV required for DES/CBC');
    }
    final cipher = PaddedBlockCipher('DES/CBC/PKCS7')
      ..init(
        false,
        PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(key.bytes), iv.bytes),
          null,
        ),
      );
    return cipher.process(encrypted.bytes);
  }
}