import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:tracer/services/api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static const _darkBlue = Color(0xFF0A1A6B);
  static const _accentBlue = Color(0xFF4A6FE3);
  static const _lightBlue = Color(0xFFEAF2FB);
  static const _mutedBlue = Color(0xFF8899BB);
  static const _borderBlue = Color(0xFFD8E4F5);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 248, 243, 240),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              // Top bar
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: _lightBlue),
                    child: const Icon(Icons.arrow_back_ios_new,
                      color: _darkBlue, size: 16),
                  ),
                ),
                const Expanded(
                  child: Text('TRACER77',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                      color: _darkBlue, letterSpacing: 2)),
                ),
                const SizedBox(width: 40),
              ]),
              const SizedBox(height: 28),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: _lightBlue, borderRadius: BorderRadius.circular(50)),
                child: const Text('NOUVEAU COMPTE',
                  style: TextStyle(fontSize: 10, color: _darkBlue,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
              const SizedBox(height: 12),

              const Text('Créer un compte',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _darkBlue)),
              Container(
                width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _accentBlue, borderRadius: BorderRadius.circular(4)),
              ),
             

              _buildField('EMAIL', _emailCtrl, false, null),
              const SizedBox(height: 20),
              _buildField('MOT DE PASSE', _passCtrl, _obscurePass,
                () => setState(() => _obscurePass = !_obscurePass)),
              const SizedBox(height: 20),
              _buildField('CONFIRMER', _confirmCtrl, _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm)),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () async {
    // Vérifier que les mots de passe correspondent
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }
    
    // Appel API
    final api = ApiService();
    final result = await api.register(
      _emailCtrl.text,
      _passCtrl.text,
      _emailCtrl.text.split('@')[0], // Nom par défaut = partie avant @
    );
    
    if (result['success']) {
      // Navigation vers l'écran principal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['data']['message'])),
      );
      Navigator.pushReplacementNamed(context, '/home'); // À créer
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'].toString())),
      );
    }
  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 19, 47, 187),
                  minimumSize: const Size(double.infinity, 52),
                  shape: const StadiumBorder(), elevation: 0,
                ),
                child: const Text("S'inscrire",
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: _darkBlue, width: 1.5),
                ),
                child: const Text('Se connecter',
                  style: TextStyle(color: _darkBlue, fontSize: 15)),
              ),
              const SizedBox(height: 20),

              const Text("En créant un compte, vous acceptez nos",
                style: TextStyle(fontSize: 11, color: _mutedBlue)),
              const Text("conditions d'utilisation",
                style: TextStyle(fontSize: 11, color: _accentBlue, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      bool obscure, VoidCallback? onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 11, color: _accentBlue,
          fontWeight: FontWeight.w700, letterSpacing: .5)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14, color: _darkBlue),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _borderBlue, width: 1.5)),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _accentBlue, width: 2)),
            suffixIcon: onToggle != null ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _mutedBlue, size: 20),
              onPressed: onToggle,
            ) : null,
          ),
        ),
      ],
    );
  }
}