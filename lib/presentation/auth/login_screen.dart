import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

          // 2. Contenu principal centré
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    // Effet de flou du Glassmorphism
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Titre "Login"
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(
                                0xFF5D3768,
                              ), // Couleur prune/violet foncé
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Champ Email
                          _buildTextField(
                            hintText: 'Email',
                            icon: Icons.email_outlined,
                            controllerInput: _emailController,
                          ),
                          const SizedBox(height: 15),

                          // Champ Password
                          _buildTextField(
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            controllerInput: _passwordController,
                          ),
                          const SizedBox(height: 25),

                          // Bouton Login
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              // Dégradé rosé/corail effet "glossy"
                              gradient: const LinearGradient(
                                colors: [Color(boxColor1), Color(boxColor2)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF7E82,
                                  ).withOpacity(0.4),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  UserCredential userCredential =
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text
                                                .trim(),
                                          );
                                 print("Succès ! L'utilisateur est connecté :${userCredential.user!.uid}");
                                  if (context.mounted) context.go('/menu');

                                } on FirebaseAuthException catch (e) {
                                  print("Échec de la connexion...");
                                  if (e.code == 'user-not-found') {
                                    print(
                                      'Erreur : Aucun utilisateur trouvé pour cet e-mail.',
                                    );
                                  } else if (e.code == 'wrong-password') {
                                    print(
                                      'Erreur : Le mot de passe est incorrect.',
                                    );
                                  } else {
                                    print(
                                      'Autre erreur Firebase : ${e.message}',
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Login',
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
                            'Or, if you don\'t have a profile...',
                            style: TextStyle(
                              color: Color(0xFF5D3768),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Petit Bouton Register
                          TextButton(
                            onPressed: () {
                              context.go('/register');
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
                              'Register',
                              style: TextStyle(
                                color: Color(0xFF5D3768),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Séparateur "Social login"
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.black26.withOpacity(0.1),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'Social login',
                                  style: TextStyle(
                                    color: Color(0xFF5D3768),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.black26.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Boutons de connexion sociaux (Google & Guest)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () async {
                                  try {
                                    final GoogleSignIn googleSignIn =
                                        GoogleSignIn.instance;
                                    await googleSignIn.initialize(
                                      serverClientId:
                                          "489288826768-16qo1oi8oum87tm7elmk7r1q4pm7mhno.apps.googleusercontent.com",
                                    );
                                    if (googleSignIn.supportsAuthenticate()) {
                                      final GoogleSignInAccount? googleUser =
                                          await googleSignIn.authenticate();
                                      if (googleUser == null) {
                                        print(
                                          "Connexion annulée par l'utilisateur",
                                        );
                                        return;
                                      }
                                      final GoogleSignInAuthentication
                                      googleAuth = googleUser.authentication;
                                      final String? idToken =
                                          googleAuth.idToken;
                                      final GoogleSignInClientAuthorization
                                      authorization = await googleUser
                                          .authorizationClient
                                          .authorizeScopes([
                                            'email',
                                            'profile',
                                          ]);
                                      final String? accessToken =
                                          authorization.accessToken;
                                      if (idToken == null ||
                                          accessToken == null) {
                                        print(
                                          "Erreur : Impossible de récupérer l'un des jetons Google.",
                                        );
                                        return;
                                      }
                                      final OAuthCredential credential =
                                          GoogleAuthProvider.credential(
                                            accessToken: accessToken,
                                            idToken: idToken,
                                          );
                                      UserCredential userCredential =
                                          await FirebaseAuth.instance
                                              .signInWithCredential(credential);
                                      print("Connecté avec succès à Firebase : ${userCredential.user!.uid}");
                                      if (context.mounted) context.go('/menu');
                                    }
                                  } on FirebaseException catch (e) {
                                    print("Erreur : $e");
                                  }
                                },
                                child: _buildSocialButton(
                                  label: 'Google',
                                  child: Image.asset(
                                    'assets/login/google.png',
                                    width: 28,
                                    height: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 30),
                              InkWell(
                                onTap: () async {
                                  try {
                                    UserCredential userCredential =
                                        await FirebaseAuth.instance
                                            .signInAnonymously();
                                    print("Connecté en tant qu'invité ! UID : ${userCredential.user!.uid}");
                                      if (context.mounted) context.go('/menu');
                                  } on FirebaseAuthException catch (e) {
                                    print(
                                      "Erreur de connexion anonyme : ${e.message}",
                                    );
                                  }
                                },
                                child: _buildSocialButton(
                                  label: 'Guest',
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF5D3768),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildTextField({
  required String hintText,
  required IconData icon,
  bool isPassword = false,
  required TextEditingController controllerInput,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.8)),
    ),
    child: TextField(
      controller: controllerInput,
      obscureText: isPassword,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: Icon(icon, color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    ),
  );
}

// Widget pour les boutons Google et Guest
Widget _buildSocialButton({required String label, required Widget child}) {
  return Column(
    children: [
      Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white),
        ),
        child: Center(child: child),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF5D3768),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

// Constantes pour le dégradé du bouton Login
const int boxColor1 = 0xFFFF7E82;
const int boxColor2 = 0xFFFF5A60;
