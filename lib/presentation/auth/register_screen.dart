import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/data/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  final String roomId;
  const RegisterScreen({super.key, required this.roomId});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🚀 ACTION DE L'INSCRIPTION & FUSION
  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    UserService userService = UserService();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Oups ! Remplis tous les champs ✨");
      return;
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      User? currentUser = _auth.currentUser;
      String finalUid = "";

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String currentNickname = prefs.getString('user_nickname') ?? "Joueur";
      String currentAvatarId =
          prefs.getString('user_avatarId') ?? "default_avatar";

      if (currentUser != null && currentUser.isAnonymous) {
        UserCredential userCredential = await currentUser.linkWithCredential(
          credential,
        );
        finalUid = userCredential.user!.uid;

        await userCredential.user?.updateDisplayName(currentNickname);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(finalUid)
            .update({'email': email});

        print(
          "🎉 Compte anonyme fusionné ! UID conservé : $finalUid et Nickname conservé : $currentNickname",
        );
      } else {
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);
        finalUid = userCredential.user!.uid;

        await userCredential.user?.updateDisplayName(currentNickname);

        await FirebaseFirestore.instance.collection('users').doc(finalUid).set({
          'uid': finalUid,
          'nickname': currentNickname,
          'email': email,
          'avatarId': currentAvatarId,
        });

        print("Compte créé normalement ! ID du joueur : $finalUid");
      }

      await userService.saveUserLocally(
        uid: finalUid,
        nickname: currentNickname,
        avatarId: currentAvatarId,
      );

      if (mounted) {
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnackBar('Cet e-mail est déjà utilisé par un autre joueur.');
      } else if (e.code == 'weak-password') {
        _showSnackBar('Le mot de passe doit contenir au moins 6 caractères.');
      } else if (e.code == 'credential-already-in-use') {
        _showSnackBar('Cet e-mail est déjà lié à un compte existant.');
      } else {
        _showSnackBar('Erreur : ${e.message}');
      }
    } catch (e) {
      print("Erreur Inscription : $e");
      _showSnackBar("Une erreur est survenue lors de l'aventure.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF5D3768),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      // 👑 ÉTAPE 1 : On réactive le redimensionnement pour laisser de la place au clavier
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Fond d'écran
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Contenu Horizontal
          SafeArea(
            child: Row(
              children: [
                // 🏛️ PARTIE GAUCHE : Titre et Poupée (Fixe, ne bouge pas)
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 40.0,
                      top: 25.0,
                      bottom: 10.0,
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Fashion Room',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D3768),
                                  shadows: [
                                    Shadow(
                                      color: Colors.white70,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: -15,
                          child: Image.asset(
                            'assets/login/poupe_logo.png',
                            height: screenSize.height * 0.9,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 📝 PARTIE DROITE : Formulaire avec Scroll intelligent pour le clavier
                Expanded(
                  flex: 6,
                  child: Center(
                    // 👑 ÉTAPE 2 : On encapsule la carte de droite dans un ScrollView
                    // pour qu'elle puisse remonter lorsque le clavier apparaît
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 40.0,
                          left: 20.0,
                          top: 10,
                          bottom: 10,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 12.0,
                              sigmaY: 12.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30.0,
                                vertical: 20.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(30),
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
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5D3768),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Champ Email
                                  _buildPinkField(
                                    hintText: 'Email',
                                    icon: Icons.email_outlined,
                                    controllerInput: _emailController,
                                  ),
                                  const SizedBox(height: 12),

                                  // Champ Password
                                  _buildPinkField(
                                    hintText: 'Create Password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    controllerInput: _passwordController,
                                  ),
                                  const SizedBox(height: 20),

                                  // Bouton Start Adventure
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFCCADF9),
                                          Color(0xFFA594F9),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFA594F9,
                                          ).withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Start Adventure',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Redirection vers Login
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Already have a profile? ',
                                        style: TextStyle(
                                          color: Color(0xFF5D3768),
                                          fontSize: 13,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => context.go('/login'),
                                        child: const Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Color(0xFF5D3768),
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
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
                ),
              ],
            ),
          ),

          // 3. Étoile décorative
          const Positioned(
            right: 20,
            top: 20,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 25),
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
        color: const Color(0xFFFFDDE1).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controllerInput,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Color.fromARGB(255, 46, 42, 42)),
          prefixIcon: Icon(icon, color: const Color(0xFFB18EA2)),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
