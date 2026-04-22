import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'package:tracer/services/api_service.dart';
import '../services/auth_service.dart';  
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;


  static const _lightBlue = Color(0xFFEAF2FB);
  static const _mutedBlue = Color(0xFF8899BB);
  static const _borderBlue = Color(0xFFD8E4F5);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
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
                _backButton(context),
                const Expanded(
                  child: Text('TRACER77',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 1, 75, 170) , letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ]),
              const SizedBox(height: 32),

              // Icône
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _lightBlue,
                ),
                child: const Icon(Icons.location_on, color: Color.fromARGB(255, 1, 75, 170) , size: 30),
              ),
              const SizedBox(height: 16),

              const Text('Bon retour !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color.fromRGBO(1, 75, 170, 1.0))),
              _accentBar(),
              const Text('Connectez-vous à votre compte',
                style: TextStyle(fontSize: 13, color: _mutedBlue)),
              const SizedBox(height: 28),

              // Champs
              _buildField('EMAIL', _emailCtrl, false, null),
              const SizedBox(height: 20),
              _buildField('MOT DE PASSE', _passCtrl, _obscurePass,
                () => setState(() => _obscurePass = !_obscurePass)),
              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Mot de passe oublié ?',
                    style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 1, 75, 170))),
                ),
              ),
              const SizedBox(height: 8),

              // Bouton principal
              ElevatedButton(
                onPressed: () async {
  final api = ApiService();
  final result = await api.login(
    _emailCtrl.text,
    _passCtrl.text,
  );
  
  if (result['success']) {
    // Sauvegarder les données utilisateur
    await AuthService.saveUserData(
      result['data']['token'],
      _emailCtrl.text,
      result['data']['user']['name'] ?? _emailCtrl.text.split('@')[0],
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Connexion réussie !')),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    }
  }
},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 1, 75, 170),
                  minimumSize: const Size(double.infinity, 52),
                  shape: const StadiumBorder(), elevation: 0,
                ),
                child: const Text('Se connecter',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
              const SizedBox(height: 20),

              // Divider
             

              // Boutons sociaux
             

              GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen())),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: _mutedBlue),
                    children: [
                      TextSpan(text: "Pas de compte ? "),
                      TextSpan(text: "S'inscrire",
                        style: TextStyle(color: Color.fromARGB(255, 1, 75, 170), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _lightBlue),
        child: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(255, 1, 75, 170) , size: 16),
      ),
    );
  }

  Widget _accentBar() {
    return Container(
      width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 1, 75, 170)  , borderRadius: BorderRadius.circular(4)),
    );
  }

 

  Widget _buildField(String label, TextEditingController ctrl,
      bool obscure, VoidCallback? onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 11, color: Color.fromARGB(255, 1, 75, 170) , fontWeight: FontWeight.w700, letterSpacing: .5)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 1, 75, 170)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _borderBlue, width: 1.5)),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color.fromARGB(255, 1, 75, 170), width: 2)),
            suffixIcon: onToggle != null ? IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _mutedBlue, size: 20),
              onPressed: onToggle,
            ) : null,
          ),
        ),
      ],
    );
  }
}