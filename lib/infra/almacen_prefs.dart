import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/almacen.dart';

class AlmacenPrefs implements Almacen {
  @override
  Future<String?> leerTexto(String clave) async => (await SharedPreferences.getInstance()).getString(clave);

  @override
  Future<void> guardarTexto(String clave, String valor) async =>
      (await SharedPreferences.getInstance()).setString(clave, valor);

  @override
  Future<void> borrar(String clave) async => (await SharedPreferences.getInstance()).remove(clave);
}