import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/data/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int boxColor1 = 0xFFFF7E82;
  static const int boxColor2 = 0xFFFF5A60;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 📧 CONNEXION EMAIL
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    UserService userService = UserService();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      User? currentUser = _auth.currentUser;

      String currentNickname = prefs.getString('user_nickname') ?? "Player";
      String currentAvatarId =
          prefs.getString('user_avatarId') ?? "avatar1";
      bool wasAnonymous = currentUser != null && currentUser.isAnonymous;

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String existingUid = userCredential.user!.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(existingUid)
          .get();

      if (userDoc.exists && wasAnonymous) {
        if (!mounted) return;

        Map<String, dynamic> oldData = userDoc.data() as Map<String, dynamic>;
        String oldNickname = oldData['nickname'] ?? "Player";
        String oldAvatarId = oldData['avatarId'] ?? "avatar1";

        bool? retrieveOldGame = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Existing save found"),
              content: Text(
                "You've played before! Want to restore your old doll ($oldNickname), or overwrite your account to play with your current new doll?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Replay (Overwrite)",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Restore old doll"),
                ),
              ],
            );
          },
        );

        if (retrieveOldGame == true) {
          await prefs.setString('uid', existingUid);
          await prefs.setString('user_nickname', oldNickname);
          await prefs.setString('user_avatarId', oldAvatarId);
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(existingUid)
              .delete();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(existingUid)
              .set({
                'uid': existingUid,
                'nickname': currentNickname,
                'email': email,
                'avatarId': currentAvatarId,
              });

          await userCredential.user?.updateDisplayName(currentNickname);
          await userService.saveUserLocally(
            uid: existingUid,
            nickname: currentNickname,
            avatarId: currentAvatarId,
          );
        }
      } else {
        await prefs.setString('uid', existingUid);
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          await prefs.setString('user_nickname', data['nickname'] ?? "Player");
          await prefs.setString(
            'user_avatarId',
            data['avatarId'] ?? "avatar1",
          );
        }
      }

      if (mounted) {
        context.go(
          widget.roomId.isNotEmpty
              ? '/lobby?roomId=${widget.roomId}'
              : '/menu',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _showSnackBar('No user found, or incorrect password.');
      } else if (e.code == 'wrong-password') {
        _showSnackBar('Incorrect password.');
      } else {
        _showSnackBar('Erreur : ${e.message}');
      }
    } catch (e) {
      _showSnackBar("Une erreur est survenue lors de la connexion.");
    }
  }

  // 🌐 CONNEXION GOOGLE
  Future<void> _handleGoogleLogin() async {
    UserService userService = UserService();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId:
            "489288826768-16qo1oi8oum87tm7elmk7r1q4pm7mhno.apps.googleusercontent.com",
      );

      if (googleSignIn.supportsAuthenticate()) {
        final GoogleSignInAccount googleUser = await googleSignIn
            .authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final String? idToken = googleAuth.idToken;

        final GoogleSignInClientAuthorization authorization = await googleUser
            .authorizationClient
            .authorizeScopes(['email', 'profile']);
        final String accessToken = authorization.accessToken;

        if (idToken == null) {
          _showSnackBar("Error: couldn't retrieve Google tokens.");
          return;
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );

        User? currentUser = _auth.currentUser;
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        UserCredential checkCredential = await _auth.signInWithCredential(
          credential,
        );
        String googleUid = checkCredential.user!.uid;
        String? googleEmail = checkCredential.user?.email;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(googleUid)
            .get();

        if (userDoc.exists && currentUser != null && currentUser.isAnonymous) {
          if (!mounted) return;

          Map<String, dynamic> oldData = userDoc.data() as Map<String, dynamic>;
          String oldNickname = oldData['nickname'] ?? "Player";
          String oldAvatarId = oldData['avatarId'] ?? "avatar1";

          bool? retrieveOldGame = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Existing save found"),
                content: Text(
                  "You've played before! Want to restore your old doll ($oldNickname), or overwrite your account to play with your current new doll?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      "Replay (Overwrite)",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Restore old doll"),
                  ),
                ],
              );
            },
          );

          if (retrieveOldGame == true) {
            await prefs.setString('uid', googleUid);
            await prefs.setString('user_nickname', oldNickname);
            await prefs.setString('user_avatarId', oldAvatarId);
          } else {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(googleUid)
                .delete();

            String currentNickname =
                prefs.getString('user_nickname') ?? "Player";
            String currentAvatarId =
                prefs.getString('user_avatarId') ?? "avatar1";

            UserCredential linkedCredential = await currentUser
                .linkWithCredential(credential);
            String finalUid = linkedCredential.user!.uid;

            await linkedCredential.user?.updateDisplayName(currentNickname);

            await FirebaseFirestore.instance
                .collection('users')
                .doc(finalUid)
                .set({
                  'uid': finalUid,
                  'nickname': currentNickname,
                  'email': googleEmail ?? "",
                  'avatarId': currentAvatarId,
                });

            await userService.saveUserLocally(
              uid: finalUid,
              nickname: currentNickname,
              avatarId: currentAvatarId,
            );
          }
        } else {
          await prefs.setString('uid', googleUid);
          if (userDoc.exists) {
            Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
            await prefs.setString(
              'user_nickname',
              data['nickname'] ?? "Player",
            );
            await prefs.setString(
              'user_avatarId',
              data['avatarId'] ?? "avatar1",
            );
          }
        }

        if (mounted) {
          context.go(
            widget.roomId.isNotEmpty
                ? '/lobby?roomId=${widget.roomId}'
                : '/menu',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _showSnackBar('This Google account already belongs to another player.');
      } else {
        _showSnackBar('Erreur Firebase : ${e.message}');
      }
    } catch (e) {
      _showSnackBar("Une erreur est survenue avec Google.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isLandscape
                      ? 650
                      : 400, // Plus large en paysage pour accueillir les 2 colonnes
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: SingleChildScrollView(
                  // Le scroll ne s'active que si le clavier est présent
                  physics: isKeyboardOpen
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(25.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Connexion',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5D3768),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 🌗 Division de l'écran en deux colonnes (ou lignes si mode portrait vertical)
                            Flex(
                              direction: isLandscape
                                  ? Axis.horizontal
                                  : Axis.vertical,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // --- CÔTÉ GAUCHE : EMAIL & PASSWORD ---
                                Expanded(
                                  flex: isLandscape ? 11 : 0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildTextField(
                                        hintText: 'Email',
                                        icon: Icons.email_outlined,
                                        controllerInput: _emailController,
                                      ),
                                      const SizedBox(height: 10),
                                      _buildTextField(
                                        hintText: 'Password',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        controllerInput: _passwordController,
                                      ),
                                      const SizedBox(height: 15),
                                      Container(
                                        width: double.infinity,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(boxColor1),
                                              Color(boxColor2),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _handleEmailLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                          ),
                                          child: const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            "No profile yet? ",
                                            style: TextStyle(
                                              color: Color(0xFF5D3768),
                                              fontSize: 12,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () =>
                                                context.go('/register'),
                                            child: const Text(
                                              'S\'inscrire',
                                              style: TextStyle(
                                                color: Color(0xFF5D3768),
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // --- SÉPARATEUR ---
                                if (isLandscape)
                                  Container(
                                    height: 140,
                                    width: 1.5,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            "OR",
                                            style: TextStyle(
                                              color: Color(0xFF5D3768),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // --- CÔTÉ DROIT : SOCIAL LOGIN (GOOGLE) ---
                                Expanded(
                                  flex: isLandscape ? 9 : 0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Connexion rapide',
                                        style: TextStyle(
                                          color: Color(0xFF5D3768),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: _handleGoogleLogin,
                                        borderRadius: BorderRadius.circular(18),
                                        child: _buildSocialButton(
                                          label: 'Google',
                                          child: Image.asset(
                                            'assets/login/google.png',
                                            width: 28,
                                            height: 28,
                                          ),
                                        ),
                                      ),
                                    ],
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
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controllerInput,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: TextField(
        controller: controllerInput,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: Icon(icon, color: Colors.black38, size: 18),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String label, required Widget child}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: child),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5D3768),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
