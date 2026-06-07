import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../../theme/app_theme.dart';

class TuCuentaView extends StatefulWidget {
  const TuCuentaView({super.key});

  @override
  State<TuCuentaView> createState() => _TuCuentaViewState();
}

class _TuCuentaViewState extends State<TuCuentaView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formDatosKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  final _formPassKey = GlobalKey<FormState>();
  final _passActualCtrl = TextEditingController();
  final _passNuevaCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Cargar datos actuales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PerfilViewModel>();
      if (vm.perfil != null) {
        _nombreCtrl.text = vm.perfil!.nombreCompleto;
        _telefonoCtrl.text = vm.perfil!.telefono;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  String _validarFuerza(String pass) {
    if (pass.isEmpty) return 'Débil';
    if (pass.length < 6) return 'Muy débil';
    if (pass.length >= 8 && pass.contains(RegExp(r'[A-Z]')) && pass.contains(RegExp(r'[0-9]'))) return 'Fuerte';
    return 'Media';
  }

  Color _colorFuerza(String fuerza) {
    switch (fuerza) {
      case 'Fuerte': return Colors.green;
      case 'Media': return Colors.orange;
      case 'Muy débil': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _guardarDatos() async {
    if (_formDatosKey.currentState!.validate()) {
      final vm = context.read<PerfilViewModel>();
      final success = await vm.actualizarDatosPersonales(_nombreCtrl.text.trim(), _telefonoCtrl.text.trim());
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos guardados correctamente'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Error'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _cambiarPassword() async {
    if (_formPassKey.currentState!.validate()) {
      final vm = context.read<PerfilViewModel>();
      final success = await vm.cambiarContrasena(_passActualCtrl.text, _passNuevaCtrl.text);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada correctamente'), backgroundColor: Colors.green));
          _passActualCtrl.clear();
          _passNuevaCtrl.clear();
          _passConfirmCtrl.clear();
          setState(() {}); // Reset strength indicator
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Error'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tu cuenta'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Datos personales'),
            Tab(text: 'Seguridad'),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Datos personales
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formDatosKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Información pública', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: const Icon(Icons.person, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'El nombre es requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telefonoCtrl,
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: const Icon(Icons.phone, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _guardarDatos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('Guardar datos', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // TAB 2: Seguridad (Contraseña)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formPassKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cambiar contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Protege tu cuenta con una contraseña fuerte.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _passActualCtrl,
                          obscureText: _obscureActual,
                          decoration: InputDecoration(
                            labelText: 'Contraseña actual',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureActual ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setState(() => _obscureActual = !_obscureActual),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _passNuevaCtrl,
                          obscureText: _obscureNueva,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon: const Icon(Icons.lock_reset, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNueva ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setState(() => _obscureNueva = !_obscureNueva),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        
                        // Indicador de fuerza
                        if (_passNuevaCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Row(
                              children: [
                                const Text('Seguridad: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  _validarFuerza(_passNuevaCtrl.text),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _colorFuerza(_validarFuerza(_passNuevaCtrl.text)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _passConfirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar nueva contraseña',
                            prefixIcon: const Icon(Icons.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          validator: (v) {
                            if (v != _passNuevaCtrl.text) return 'Las contraseñas no coinciden';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _cambiarPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('Actualizar contraseña', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
