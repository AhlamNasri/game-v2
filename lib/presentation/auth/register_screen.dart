import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Contenu Central (Carte en verre)
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Create Profile',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D3768),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Champ Nickname (Fond Rose)
                          _buildPinkField(
                            hintText: 'Choose Nickname',
                            icon: Icons.person_outline,
                            controllerInput: _nicknameController,
                          ),
                          const SizedBox(height: 15),

                          // Champ Email
                          _buildPinkField(
                            hintText: 'Email',
                            icon: Icons.email_outlined,
                            controllerInput: _emailController,
                          ),
                          const SizedBox(height: 15),

                          // Champ Password
                          _buildPinkField(
                            hintText: 'Create Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            controllerInput: _passwordController,
                          ),
                          const SizedBox(height: 25),

                          // Bouton Start Adventure (Dégradé Violet)
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFCCADF9), Color(0xFFA594F9)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFA594F9,
                                  ).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            // button register
                            child: ElevatedButton(
                              onPressed: () async {
                                final nickname = _nicknameController.text.trim();
                                final email = _emailController.text.trim();
                                final password = _passwordController.text.trim();

                                if (nickname.isEmpty || email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill in all fields.')),
                                  );
                                  return;
                                }

                                try {
                                  final userCredential =
                                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );
                                  // ✅ Save nickname to Firebase Auth profile
                                  await userCredential.user!.updateProfile(displayName: nickname);
                                  // ✅ Navigate to menu after registration
                                  if (context.mounted) context.go('/menu');
                                } on FirebaseAuthException catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.message ?? 'Registration failed.')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Start Adventure',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Or, if you already have a profile...',
                            style: TextStyle(
                              color: Color(0xFF5D3768),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Petit Bouton Login
                          TextButton(
                            onPressed: () {
                              context.go('/login');
                            },
                            // onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Color(0xFF5D3768),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Personnage (Bas Gauche)
          Positioned(
            left: -20,
            bottom: 0,
            child: Image.asset(
              'assets/login/poupe_logo.png', // Image de la petite fille (PNG transparent)
              height: 300,
            ),
          ),

          // 4. Étoile/Brillance (Bas Droite)
          const Positioned(
            right: 20,
            bottom: 20,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildPinkField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controllerInput,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFDDE1).withOpacity(0.8), // Fond Rose Pastel
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controllerInput,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Color.fromARGB(255, 46, 42, 42)),
          prefixIcon: Icon(icon, color: Color(0xFFB18EA2)),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
