import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Registra un usuario nuevo en Supabase Auth e inserta su perfil.
  Future<void> registrar({
    required String email,
    required String password,
    required String nombreCompleto,
    required String telefono,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('No se pudo crear el usuario.');
    }

    // Insertar perfil en la tabla pública
    await _client.from('perfiles').insert({
      'id': user.id,
      'nombre_completo': nombreCompleto,
      'telefono': telefono,
    });
  }

  /// Inicia sesión con email y contraseña.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Cierra la sesión del usuario actual.
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Obtiene el perfil del usuario actual.
  Future<PerfilModel?> obtenerPerfilActual() async {
    final id = currentUserId;
    if (id == null) return null;

    final data =
        await _client.from('perfiles').select().eq('id', id).maybeSingle();

    if (data == null) return null;
    return PerfilModel.fromMap(data);
  }
}
