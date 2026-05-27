// // import 'dart:ui';
// // import 'package:fashion_room_girls/data/firebase/auth_service.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:google_sign_in/google_sign_in.dart';

// // class LoginScreen extends StatefulWidget {
// //   const LoginScreen({super.key});

// //   @override
// //   State<LoginScreen> createState() => _LoginScreenState();
// // }

// // class _LoginScreenState extends State<LoginScreen> {
// //   final TextEditingController _emailController = TextEditingController();
// //   final TextEditingController _passwordController = TextEditingController();
// //   AuthService authService = AuthService();
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           Container(
// //             decoration: const BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage('assets/login/background.png'),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //           ),

// //           // 2. Contenu principal centré
// //           Center(
// //             child: SingleChildScrollView(
// //               child: Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 30.0),
// //                 child: ClipRRect(
// //                   borderRadius: BorderRadius.circular(30),
// //                   child: BackdropFilter(
// //                     // Effet de flou du Glassmorphism
// //                     filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
// //                     child: Container(
// //                       padding: const EdgeInsets.all(25.0),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white.withOpacity(0.4),
// //                         borderRadius: BorderRadius.circular(30),
// //                         border: Border.all(
// //                           color: Colors.white.withOpacity(0.5),
// //                           width: 1.5,
// //                         ),
// //                       ),
// //                       child: Column(
// //                         mainAxisSize: MainAxisSize.min,
// //                         children: [
// //                           // Titre "Login"
// //                           const Text(
// //                             'Login',
// //                             style: TextStyle(
// //                               fontSize: 32,
// //                               fontWeight: FontWeight.bold,
// //                               color: Color(
// //                                 0xFF5D3768,
// //                               ), // Couleur prune/violet foncé
// //                             ),
// //                           ),
// //                           const SizedBox(height: 25),

// //                           // Champ Email
// //                           _buildTextField(
// //                             hintText: 'Email',
// //                             icon: Icons.email_outlined,
// //                             controllerInput: _emailController,
// //                           ),
// //                           const SizedBox(height: 15),

// //                           // Champ Password
// //                           _buildTextField(
// //                             hintText: 'Password',
// //                             icon: Icons.lock_outline,
// //                             isPassword: true,
// //                             controllerInput: _passwordController,
// //                           ),
// //                           const SizedBox(height: 25),

// //                           // Bouton Login
// //                           Container(
// //                             width: double.infinity,
// //                             height: 55,
// //                             decoration: BoxDecoration(
// //                               // Dégradé rosé/corail effet "glossy"
// //                               gradient: const LinearGradient(
// //                                 colors: [Color(boxColor1), Color(boxColor2)],
// //                                 begin: Alignment.topCenter,
// //                                 end: Alignment.bottomCenter,
// //                               ),
// //                               borderRadius: BorderRadius.circular(25),
// //                               boxShadow: [
// //                                 BoxShadow(
// //                                   color: const Color(
// //                                     0xFFFF7E82,
// //                                   ).withOpacity(0.4),
// //                                   spreadRadius: 1,
// //                                   blurRadius: 8,
// //                                   offset: const Offset(0, 4),
// //                                 ),
// //                               ],
// //                             ),
// //                             child: ElevatedButton(
// //                               onPressed: () async {
// //                                 try {
// //                                   UserCredential userCredential =
// //                                       await FirebaseAuth.instance
// //                                           .signInWithEmailAndPassword(
// //                                             email: _emailController.text.trim(),
// //                                             password: _passwordController.text
// //                                                 .trim(),
// //                                           );
// //                                   print(
// //                                     "Succès ! L'utilisateur est connecté :${userCredential.user!.uid}",
// //                                   );
// //                                 } on FirebaseAuthException catch (e) {
// //                                   print("Échec de la connexion...");
// //                                   if (e.code == 'user-not-found') {
// //                                     print(
// //                                       'Erreur : Aucun utilisateur trouvé pour cet e-mail.',
// //                                     );
// //                                   } else if (e.code == 'wrong-password') {
// //                                     print(
// //                                       'Erreur : Le mot de passe est incorrect.',
// //                                     );
// //                                   } else {
// //                                     print(
// //                                       'Autre erreur Firebase : ${e.message}',
// //                                     );
// //                                   }
// //                                 }
// //                               },
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: Colors.transparent,
// //                                 shadowColor: Colors.transparent,
// //                                 shape: RoundedRectangleBorder(
// //                                   borderRadius: BorderRadius.circular(25),
// //                                 ),
// //                               ),
// //                               child: const Text(
// //                                 'Login',
// //                                 style: TextStyle(
// //                                   fontSize: 20,
// //                                   fontWeight: FontWeight.bold,
// //                                   color: Colors.white,
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                           const SizedBox(height: 20),

// //                           const Text(
// //                             'Or, if you don\'t have a profile...',
// //                             style: TextStyle(
// //                               color: Color(0xFF5D3768),
// //                               fontSize: 13,
// //                             ),
// //                           ),
// //                           const SizedBox(height: 15),

// //                           // Petit Bouton Register
// //                           TextButton(
// //                             onPressed: () {
// //                               context.go('/register');
// //                             },
// //                             // onPressed: () => Navigator.pop(context),
// //                             style: TextButton.styleFrom(
// //                               backgroundColor: Colors.white.withOpacity(0.8),
// //                               padding: const EdgeInsets.symmetric(
// //                                 horizontal: 40,
// //                                 vertical: 12,
// //                               ),
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(20),
// //                               ),
// //                             ),
// //                             child: const Text(
// //                               'Register',
// //                               style: TextStyle(
// //                                 color: Color(0xFF5D3768),
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           ),
// //                           const SizedBox(height: 25),

// //                           // Séparateur "Social login"
// //                           Row(
// //                             children: [
// //                               Expanded(
// //                                 child: Divider(
// //                                   color: Colors.black26.withOpacity(0.1),
// //                                 ),
// //                               ),
// //                               const Padding(
// //                                 padding: EdgeInsets.symmetric(horizontal: 10),
// //                                 child: Text(
// //                                   'Social login',
// //                                   style: TextStyle(
// //                                     color: Color(0xFF5D3768),
// //                                     fontSize: 13,
// //                                   ),
// //                                 ),
// //                               ),
// //                               Expanded(
// //                                 child: Divider(
// //                                   color: Colors.black26.withOpacity(0.1),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                           const SizedBox(height: 20),

// //                           // Boutons de connexion sociaux (Google & Guest)
// //                           //Google
// //                           Row(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             children: [
// //                               InkWell(
// //                                 onTap: () async {
// //                                   try {
// //                                     final GoogleSignIn googleSignIn =
// //                                         GoogleSignIn.instance;
// //                                     await googleSignIn.initialize(
// //                                       serverClientId:
// //                                           "489288826768-16qo1oi8oum87tm7elmk7r1q4pm7mhno.apps.googleusercontent.com",
// //                                     );
// //                                     if (googleSignIn.supportsAuthenticate()) {
// //                                       final GoogleSignInAccount? googleUser =
// //                                           await googleSignIn.authenticate();
// //                                       if (googleUser == null) {
// //                                         print(
// //                                           "Connexion annulée par l'utilisateur",
// //                                         );
// //                                         return;
// //                                       }
// //                                       final GoogleSignInAuthentication
// //                                       googleAuth = googleUser.authentication;
// //                                       final String? idToken =
// //                                           googleAuth.idToken;
// //                                       final GoogleSignInClientAuthorization
// //                                       authorization = await googleUser
// //                                           .authorizationClient
// //                                           .authorizeScopes([
// //                                             'email',
// //                                             'profile',
// //                                           ]);
// //                                       final String? accessToken =
// //                                           authorization.accessToken;
// //                                       if (idToken == null ||
// //                                           accessToken == null) {
// //                                         print(
// //                                           "Erreur : Impossible de récupérer l'un des jetons Google.",
// //                                         );
// //                                         return;
// //                                       }
// //                                       final OAuthCredential credential =
// //                                           GoogleAuthProvider.credential(
// //                                             accessToken: accessToken,
// //                                             idToken: idToken,
// //                                           );
// //                                       UserCredential userCredential =
// //                                           await FirebaseAuth.instance
// //                                               .signInWithCredential(credential);
// //                                       print(
// //                                         "Connecté avec succès à Firebase : ${userCredential.user!.uid}",
// //                                       );
// //                                     }
// //                                   } on FirebaseException catch (e) {
// //                                     print("Erreur : $e");
// //                                   }
// //                                 },
// //                                 child: _buildSocialButton(
// //                                   label: 'Google',
// //                                   child: Image.asset(
// //                                     'assets/login/google.png',
// //                                     width: 28,
// //                                     height: 28,
// //                                   ),
// //                                 ),
// //                               ),

// //                               // geust
// //                               const SizedBox(width: 30),
// //                               InkWell(
// //                                 onTap: () async {
// //                                   try {
// //                                     UserCredential userCredential =
// //                                         await FirebaseAuth.instance
// //                                             .signInAnonymously();
// //                                     print(
// //                                       "Connecté en tant qu'invité ! UID : ${userCredential.user!.uid}",
// //                                     );
// //                                   } on FirebaseAuthException catch (e) {
// //                                     print(
// //                                       "Erreur de connexion anonyme : ${e.message}",
// //                                     );
// //                                   }
// //                                 },
// //                                 child: _buildSocialButton(
// //                                   label: 'Guest',
// //                                   child: const Icon(
// //                                     Icons.person_outline,
// //                                     color: Color(0xFF5D3768),
// //                                     size: 28,
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // Widget _buildTextField({
// //   required String hintText,
// //   required IconData icon,
// //   bool isPassword = false,
// //   required TextEditingController controllerInput,
// // }) {
// //   return Container(
// //     decoration: BoxDecoration(
// //       color: Colors.white.withOpacity(0.6),
// //       borderRadius: BorderRadius.circular(20),
// //       border: Border.all(color: Colors.white.withOpacity(0.8)),
// //     ),
// //     child: TextField(
// //       controller: controllerInput,
// //       obscureText: isPassword,
// //       decoration: InputDecoration(
// //         border: InputBorder.none,
// //         hintText: hintText,
// //         hintStyle: const TextStyle(color: Colors.black38),
// //         prefixIcon: Icon(icon, color: Colors.black38),
// //         contentPadding: const EdgeInsets.symmetric(vertical: 15),
// //       ),
// //     ),
// //   );
// // }

// // // Widget pour les boutons Google et Guest
// // Widget _buildSocialButton({required String label, required Widget child}) {
// //   return Column(
// //     children: [
// //       Container(
// //         width: 55,
// //         height: 55,
// //         decoration: BoxDecoration(
// //           color: Colors.white.withOpacity(0.8),
// //           borderRadius: BorderRadius.circular(18),
// //           border: Border.all(color: Colors.white),
// //         ),
// //         child: Center(child: child),
// //       ),
// //       const SizedBox(height: 5),
// //       Text(
// //         label,
// //         style: const TextStyle(
// //           fontSize: 12,
// //           color: Color(0xFF5D3768),
// //           fontWeight: FontWeight.w500,
// //         ),
// //       ),
// //     ],
// //   );
// // }

// // // Constantes pour le dégradé du bouton Login
// // const int boxColor1 = 0xFFFF7E82;
// // const int boxColor2 = 0xFFFF5A60;

// import 'dart:ui';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fashion_room_girls/data/services/user_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key, required String roomId});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // 📧 GESTION DU BOUTON LOGIN (EMAIL / PASSWORD)
//   // Future<void> _handleEmailLogin() async {
//   //   final email = _emailController.text.trim();
//   //   final password = _passwordController.text.trim();

//   //   if (email.isEmpty || password.isEmpty) {
//   //     _showSnackBar("Oups ! Remplis tous les champs ✨");
//   //     return;
//   //   }

//   //   try {
//   //     // Connexion classique à un compte existant
//   //     UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//   //       email: email,
//   //       password: password,
//   //     );

//   //     print(
//   //       "Succès ! L'utilisateur est connecté : ${userCredential.user!.uid}",
//   //     );

//   //     if (mounted) {
//   //       // Redirection vers le matchmaking du Lobby de la compétition
//   //       context.go('/lobby?roomId=MATCHMAKING_ROOM_ID');
//   //     }
//   //   } on FirebaseAuthException catch (e) {
//   //     if (e.code == 'user-not-found') {
//   //       _showSnackBar('Aucun utilisateur trouvé pour cet e-mail.');
//   //     } else if (e.code == 'wrong-password') {
//   //       _showSnackBar('Le mot de passe est incorrect.');
//   //     } else {
//   //       _showSnackBar('Erreur : ${e.message}');
//   //     }
//   //   }
//   //}

//   // 📧 GESTION DU BOUTON LOGIN (EMAIL / PASSWORD) AVEC CHOIX DE RÉCUPÉRATION
//   Future<void> _handleEmailLogin() async {
//     final email = _emailController.text.trim();
//     final password = _passwordController.text.trim();
//     UserService userService = UserService();

//     if (email.isEmpty || password.isEmpty) {
//       _showSnackBar("Oups ! Remplis tous les champs ✨");
//       return;
//     }

//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       User? currentUser = _auth.currentUser;

//       // 1. Sauvegarde préventive des infos locales (nouvelle poupée anonyme) au cas où il veut ÉCRASER
//       String currentNickname = prefs.getString('user_nickname') ?? "Joueur";
//       String currentAvatarId =
//           prefs.getString('user_avatarId') ?? "default_avatar";
//       bool wasAnonymous = currentUser != null && currentUser.isAnonymous;

//       // 2. Connexion classique au compte Email existant
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       String existingUid = userCredential.user!.uid;
//       print("Succès ! L'utilisateur existant est authentifié : $existingUid");

//       // 3. On récupère ses anciennes données depuis Firestore
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(existingUid)
//           .get();

//       if (userDoc.exists && wasAnonymous) {
//         // =========================================================================
//         // ⚠️ CONFLIT : Le compte Email possède déjà une poupée ET une partie anonyme était en cours
//         // =========================================================================
//         if (!mounted) return;

//         Map<String, dynamic> oldData = userDoc.data() as Map<String, dynamic>;
//         String oldNickname = oldData['nickname'] ?? "Joueur";
//         String oldAvatarId = oldData['avatarId'] ?? "default_avatar";

//         // Affichage de la boîte de dialogue
//         bool? retrieveOldGame = await showDialog<bool>(
//           context: context,
//           barrierDismissible: false,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text("Partie existante trouvée ! ✨"),
//               content: Text(
//                 "Tu as déjà joué ! Veux-tu récupérer ton ancienne poupée ($oldNickname) ou écraser ton compte pour rejouer avec ta nouvelle poupée actuelle ?",
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () =>
//                       Navigator.of(context).pop(false), // Rejouer (Écraser)
//                   child: const Text(
//                     "Rejouer (Écraser)",
//                     style: TextStyle(color: Colors.red),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Navigator.of(context).pop(true), // Récupérer
//                   child: const Text("Récupérer l'ancienne"),
//                 ),
//               ],
//             );
//           },
//         );

//         if (retrieveOldGame == true) {
//           // ---- CHOIX A : RÉCUPÉRER L'ANCIENNE PARTIE ----
//           await prefs.setString('uid', existingUid);
//           await prefs.setString('user_nickname', oldNickname);
//           await prefs.setString('user_avatarId', oldAvatarId);
//           print("🔄 Ancienne partie restaurée localement : $oldNickname");
//         } else {
//           // ---- CHOIX B : REJOUER (ÉCRASER L'ANCIENNE) ----
//           // 1. On supprime l'ancien document utilisateur dans Firestore
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(existingUid)
//               .delete();

//           // 2. Puisque l'utilisateur est déjà connecté avec cet Email, on met simplement à jour
//           // son document existant avec les données de la NOUVELLE poupée (celle sauvegardée au début)
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(existingUid)
//               .set({
//                 'uid': existingUid,
//                 'nickname': currentNickname,
//                 'email': email,
//                 'avatarId': currentAvatarId,
//               });

//           // 3. On met à jour son profil Firebase Auth DisplayName
//           await userCredential.user?.updateDisplayName(currentNickname);

//           // 4. On écrase les SharedPreferences locales avec la nouvelle config
//           await userService.saveUserLocally(
//             uid: existingUid,
//             nickname: currentNickname,
//             avatarId: currentAvatarId,
//           );
//           print(
//             "🔥 Anciennes données écrasées sur Firestore avec le nouveau profil !",
//           );
//         }
//       } else {
//         // =========================================================================
//         // ✅ PAS DE CONFLIT : Login pur (Pas de session anonyme en cours)
//         // =========================================================================
//         await prefs.setString('uid', existingUid);

//         // Si le joueur a déjà un document, on charge ses infos en local pour que l'interface soit à jour
//         if (userDoc.exists) {
//           Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
//           await prefs.setString('user_nickname', data['nickname'] ?? "Joueur");
//           await prefs.setString(
//             'user_avatarId',
//             data['avatarId'] ?? "default_avatar",
//           );
//         }
//       }

//       if (mounted) {
//         context.go('/lobby?roomId=MATCHMAKING_ROOM_ID');
//       }
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
//         _showSnackBar('Aucun utilisateur trouvé ou mot de passe incorrect.');
//       } else if (e.code == 'wrong-password') {
//         _showSnackBar('Le mot de passe est incorrect.');
//       } else {
//         _showSnackBar('Erreur : ${e.message}');
//       }
//     } catch (e) {
//       print("Erreur Connexion Email : $e");
//       _showSnackBar("Une erreur est survenue lors de la connexion.");
//     }
//   }

//   // // 🌐 GESTION DU BOUTON GOOGLE (CONNEXION OU SYNCHRONISATION)
//   // Future<void> _handleGoogleLogin() async {
//   //   try {
//   //     final GoogleSignIn googleSignIn = GoogleSignIn.instance;
//   //     await googleSignIn.initialize(
//   //       serverClientId:
//   //           "489288826768-16qo1oi8oum87tm7elmk7r1q4pm7mhno.apps.googleusercontent.com",
//   //       // clientId:
//   //       //"489288826768-16qo1oi8oum87tm7elmk7r1q4pm7mhno.apps.googleusercontent.com",
//   //     );

//   //     if (googleSignIn.supportsAuthenticate()) {
//   //       final GoogleSignInAccount? googleUser = await googleSignIn
//   //           .authenticate();
//   //       if (googleUser == null) {
//   //         print("Connexion annulée par l'utilisateur");
//   //         return;
//   //       }

//   //       final GoogleSignInAuthentication googleAuth = googleUser.authentication;
//   //       final String? idToken = googleAuth.idToken;

//   //       final GoogleSignInClientAuthorization authorization = await googleUser
//   //           .authorizationClient
//   //           .authorizeScopes(['email', 'profile']);
//   //       final String? accessToken = authorization.accessToken;

//   //       if (idToken == null || accessToken == null) {
//   //         _showSnackBar("Erreur : Impossible de récupérer les jetons Google.");
//   //         return;
//   //       }

//   //       final OAuthCredential credential = GoogleAuthProvider.credential(
//   //         accessToken: accessToken,
//   //         idToken: idToken,
//   //       );

//   //       User? currentUser = _auth.currentUser;

//   //       if (currentUser != null && currentUser.isAnonymous) {
//   //         // 🚀 CAS 1 : Il y a un compte anonyme actif -> On FUSIONNE sans perdre la poupée !
//   //         await currentUser.linkWithCredential(credential);
//   //         print(
//   //           "🎉 Compte anonyme synchronisé à Google ! UID conservé : ${currentUser.uid}",
//   //         );
//   //       } else {
//   //         // 🔐 CAS 2 : Pas de compte anonyme -> Connexion normale
//   //         UserCredential userCredential = await _auth.signInWithCredential(
//   //           credential,
//   //         );
//   //         print(
//   //           "Connecté avec succès (Connexion normale Google) : ${userCredential.user!.uid}",
//   //         );
//   //       }

//   //       if (mounted) {
//   //         context.go('/lobby?roomId=MATCHMAKING_ROOM_ID');
//   //       }
//   //     }
//   //   } on FirebaseAuthException catch (e) {
//   //     if (e.code == 'credential-already-in-use') {
//   //       _showSnackBar('Ce compte Google appartient déjà à un autre joueur.');
//   //     } else {
//   //       _showSnackBar('Erreur Firebase : ${e.message}');
//   //     }
//   //   } catch (e) {
//   //     print("Erreur : $e");
//   //   }
//   // }

//   // 🌐 GESTION DU BOUTON GOOGLE AVEC CHOIX DE RECUPERATION OU DE REPRISE
//   Future<void> _handleGoogleLogin() async {
//     UserService userService = UserService();

//     try {
//       final GoogleSignIn googleSignIn = GoogleSignIn.instance;
//       await googleSignIn.initialize(
//         serverClientId:
//             "489288826768-16qo1oi8oum87tm7elmk7r1q4pm7mhno.apps.googleusercontent.com",
//       );

//       if (googleSignIn.supportsAuthenticate()) {
//         final GoogleSignInAccount googleUser = await googleSignIn
//             .authenticate();
//         if (googleUser == null) {
//           print("Connexion annulée par l'utilisateur");
//           return;
//         }

//         final GoogleSignInAuthentication googleAuth = googleUser.authentication;
//         final String? idToken = googleAuth.idToken;

//         final GoogleSignInClientAuthorization authorization = await googleUser
//             .authorizationClient
//             .authorizeScopes(['email', 'profile']);
//         final String accessToken = authorization.accessToken;

//         if (idToken == null || accessToken == null) {
//           _showSnackBar("Erreur : Impossible de récupérer les jetons Google.");
//           return;
//         }

//         final OAuthCredential credential = GoogleAuthProvider.credential(
//           accessToken: accessToken,
//           idToken: idToken,
//         );

//         User? currentUser = _auth.currentUser;
//         final SharedPreferences prefs = await SharedPreferences.getInstance();

//         // 1. On vérifie d'abord si ce compte Google existe déjà dans Firebase
//         // Pour cela, on tente une connexion temporaire/silencieuse pour avoir l'UID Google
//         UserCredential checkCredential = await _auth.signInWithCredential(
//           credential,
//         );
//         String googleUid = checkCredential.user!.uid;
//         String? googleEmail = checkCredential.user?.email;

//         // On cherche le document dans Firestore
//         DocumentSnapshot userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(googleUid)
//             .get();

//         if (userDoc.exists && currentUser != null && currentUser.isAnonymous) {
//           // =========================================================================
//           // ⚠️ CONFLIT : Le compte Google existe DEJA et le joueur a une partie anonyme en cours
//           // =========================================================================
//           if (!mounted) return;

//           // On récupère les anciennes infos au cas où il choisit de les charger
//           Map<String, dynamic> oldData = userDoc.data() as Map<String, dynamic>;
//           String oldNickname = oldData['nickname'] ?? "Joueur";
//           String oldAvatarId = oldData['avatarId'] ?? "default_avatar";

//           // On affiche un Dialog de choix à l'utilisateur
//           bool? retrieveOldGame = await showDialog<bool>(
//             context: context,
//             barrierDismissible: false,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text("Partie existante trouvée ! ✨"),
//                 content: Text(
//                   "Tu as déjà joué ! Veux-tu récupérer ton ancienne poupée ($oldNickname) ou écraser ton compte pour rejouer avec ta nouvelle poupée actuelle ?",
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () =>
//                         Navigator.of(context).pop(false), // Rejouer (Écraser)
//                     child: const Text(
//                       "Rejouer (Écraser)",
//                       style: TextStyle(color: Colors.red),
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () =>
//                         Navigator.of(context).pop(true), // Récupérer
//                     child: const Text("Récupérer l'ancienne"),
//                   ),
//                 ],
//               );
//             },
//           );

//           if (retrieveOldGame == true) {
//             // ---- CHOIX A : RÉCUPÉRER L'ANCIENNE PARTIE ----
//             // On stocke l'UID, l'avatar et le nickname de l'ancienne partie dans SharedPreferences
//             await prefs.setString('uid', googleUid);
//             await prefs.setString('user_nickname', oldNickname);
//             await prefs.setString('user_avatarId', oldAvatarId);
//             print(
//               "🔄 Ancienne partie récupérée : $oldNickname (UID: $googleUid)",
//             );
//           } else {
//             // ---- CHOIX B : REJOUER (ÉCRASER L'ANCIENNE) ----
//             // 1. On efface l'ancien compte dans Firestore
//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(googleUid)
//                 .delete();

//             // 2. On se reconnecte à l'anonyme actuel pour faire la fusion proprement
//             // (Parce que signInWithCredential nous avait déconnecté de l'anonyme)
//             String currentNickname =
//                 prefs.getString('user_nickname') ?? "Joueur";
//             String currentAvatarId =
//                 prefs.getString('user_avatarId') ?? "default_avatar";

//             // On relie le compte anonyme actuel avec Google (L'ancien UID Firestore prendra les nouvelles infos)
//             UserCredential linkedCredential = await currentUser
//                 .linkWithCredential(credential);
//             String finalUid = linkedCredential.user!.uid;

//             await linkedCredential.user?.updateDisplayName(currentNickname);

//             // On crée le nouveau document propre lié à Google avec la nouvelle poupée
//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(finalUid)
//                 .set({
//                   'uid': finalUid,
//                   'nickname': currentNickname,
//                   'email': googleEmail ?? "",
//                   'avatarId': currentAvatarId,
//                 });

//             // On met à jour les SharedPreferences locales
//             await userService.saveUserLocally(
//               uid: finalUid,
//               nickname: currentNickname,
//               avatarId: currentAvatarId,
//             );
//             print(
//               "🔥 Ancienne partie écrasée. Nouvelle partie liée à Google !",
//             );
//           }
//         } else {
//           // =========================================================================
//           // ✅ PAS DE CONFLIT : Soit c'est un switch normal, soit un login pur sans anonyme
//           // =========================================================================
//           if (currentUser != null && currentUser.isAnonymous) {
//             // Switch classique (Ton code Register)
//             String currentNickname =
//                 prefs.getString('user_nickname') ?? "Joueur";
//             String currentAvatarId =
//                 prefs.getString('user_avatarId') ?? "default_avatar";

//             UserCredential userCredential = await currentUser
//                 .linkWithCredential(credential);
//             String finalUid = userCredential.user!.uid;

//             await userCredential.user?.updateDisplayName(currentNickname);

//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(finalUid)
//                 .update({'email': googleEmail ?? ""});

//             await userService.saveUserLocally(
//               uid: finalUid,
//               nickname: currentNickname,
//               avatarId: currentAvatarId,
//             );
//           } else {
//             // Login pur sans profil anonyme en cours : on met juste à jour l'UID local
//             await prefs.setString('uid', googleUid);

//             // Si le document existe, on met à jour le pseudo/avatar local par confort
//             if (userDoc.exists) {
//               Map<String, dynamic> data =
//                   userDoc.data() as Map<String, dynamic>;
//               await prefs.setString(
//                 'user_nickname',
//                 data['nickname'] ?? "Joueur",
//               );
//               await prefs.setString(
//                 'user_avatarId',
//                 data['avatarId'] ?? "default_avatar",
//               );
//             }
//           }
//         }

//         if (mounted) {
//           // context.go('/lobby?roomId=MATCHMAKING_ROOM_ID');
//           context.pop();
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'credential-already-in-use') {
//         _showSnackBar('Ce compte Google appartient déjà à un autre joueur.');
//       } else {
//         _showSnackBar('Erreur Firebase : ${e.message}');
//       }
//     } catch (e) {
//       print("Erreur Authentification Google : $e");
//       _showSnackBar("Une erreur est survenue avec Google.");
//     }
//   }

//   // Petite notification Snackbar personnalisée violette
//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: const Color(0xFF5D3768),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // 1. Fond d'écran
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/login/background.png'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),

//           // 2. Contenu principal avec l'effet Glassmorphism flouté
//           Center(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 30.0),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(30),
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//                     child: Container(
//                       padding: const EdgeInsets.all(25.0),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.4),
//                         borderRadius: BorderRadius.circular(30),
//                         border: Border.all(
//                           color: Colors.white.withOpacity(0.5),
//                           width: 1.5,
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Titre Principal
//                           const Text(
//                             'Login',
//                             style: TextStyle(
//                               fontSize: 32,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF5D3768),
//                             ),
//                           ),
//                           const SizedBox(height: 25),

//                           // Champ Email
//                           _buildTextField(
//                             hintText: 'Email',
//                             icon: Icons.email_outlined,
//                             controllerInput: _emailController,
//                           ),
//                           const SizedBox(height: 15),

//                           // Champ Password
//                           _buildTextField(
//                             hintText: 'Password',
//                             icon: Icons.lock_outline,
//                             isPassword: true,
//                             controllerInput: _passwordController,
//                           ),
//                           const SizedBox(height: 25),

//                           // Bouton dégradé Login
//                           Container(
//                             width: double.infinity,
//                             height: 55,
//                             decoration: BoxDecoration(
//                               gradient: const LinearGradient(
//                                 colors: [Color(boxColor1), Color(boxColor2)],
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter,
//                               ),
//                               borderRadius: BorderRadius.circular(25),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: const Color(
//                                     0xFFFF7E82,
//                                   ).withOpacity(0.4),
//                                   spreadRadius: 1,
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 4),
//                                 ),
//                               ],
//                             ),
//                             child: ElevatedButton(
//                               onPressed: _handleEmailLogin,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.transparent,
//                                 shadowColor: Colors.transparent,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(25),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Login',
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 20),

//                           const Text(
//                             "Or, if you don't have a profile...",
//                             style: TextStyle(
//                               color: Color(0xFF5D3768),
//                               fontSize: 13,
//                             ),
//                           ),
//                           const SizedBox(height: 15),

//                           // Bouton d'inscription (Register)
//                           TextButton(
//                             onPressed: () {
//                               context.go('/register');
//                             },
//                             style: TextButton.styleFrom(
//                               backgroundColor: Colors.white.withOpacity(0.8),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 40,
//                                 vertical: 12,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                             child: const Text(
//                               'Register',
//                               style: TextStyle(
//                                 color: Color(0xFF5D3768),
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 25),

//                           // Ligne de séparation Social login
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Divider(
//                                   color: Colors.black26.withOpacity(0.1),
//                                 ),
//                               ),
//                               const Padding(
//                                 padding: EdgeInsets.symmetric(horizontal: 10),
//                                 child: Text(
//                                   'Social login',
//                                   style: TextStyle(
//                                     color: Color(0xFF5D3768),
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Divider(
//                                   color: Colors.black26.withOpacity(0.1),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 20),

//                           // Bouton d'icône Social (Google)
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               InkWell(
//                                 onTap: _handleGoogleLogin,
//                                 child: _buildSocialButton(
//                                   label: 'Google',
//                                   child: Image.asset(
//                                     'assets/login/google.png',
//                                     width: 28,
//                                     height: 28,
//                                     errorBuilder:
//                                         (context, error, stackTrace) =>
//                                             const Icon(
//                                               Icons.g_mobiledata,
//                                               size: 30,
//                                               color: Colors.red,
//                                             ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Les Widgets de structure réutilisables
// Widget _buildTextField({
//   required String hintText,
//   required IconData icon,
//   bool isPassword = false,
//   required TextEditingController controllerInput,
// }) {
//   return Container(
//     decoration: BoxDecoration(
//       color: Colors.white.withOpacity(0.6),
//       borderRadius: BorderRadius.circular(20),
//       border: Border.all(color: Colors.white.withOpacity(0.8)),
//     ),
//     child: TextField(
//       controller: controllerInput,
//       obscureText: isPassword,
//       decoration: InputDecoration(
//         border: InputBorder.none,
//         hintText: hintText,
//         hintStyle: const TextStyle(color: Colors.black38),
//         prefixIcon: Icon(icon, color: Colors.black38),
//         contentPadding: const EdgeInsets.symmetric(vertical: 15),
//       ),
//     ),
//   );
// }

// Widget _buildSocialButton({required String label, required Widget child}) {
//   return Column(
//     children: [
//       Container(
//         width: 55,
//         height: 55,
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.8),
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: Colors.white),
//         ),
//         child: Center(child: child),
//       ),
//       const SizedBox(height: 5),
//       Text(
//         label,
//         style: const TextStyle(
//           fontSize: 12,
//           color: Color(0xFF5D3768),
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     ],
//   );
// }

// // Constantes de couleurs pour le bouton
// const int boxColor1 = 0xFFFF7E82;
// const int boxColor2 = 0xFFFF5A60;

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
      _showSnackBar("Oups ! Remplis tous les champs ✨");
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      User? currentUser = _auth.currentUser;

      String currentNickname = prefs.getString('user_nickname') ?? "Joueur";
      String currentAvatarId =
          prefs.getString('user_avatarId') ?? "default_avatar";
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
        String oldNickname = oldData['nickname'] ?? "Joueur";
        String oldAvatarId = oldData['avatarId'] ?? "default_avatar";

        bool? retrieveOldGame = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Partie existante trouvée ! ✨"),
              content: Text(
                "Tu as déjà joué ! Veux-tu récupérer ton ancienne poupée ($oldNickname) ou écraser ton compte pour rejouer avec ta nouvelle poupée actuelle ?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Rejouer (Écraser)",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Récupérer l'ancienne"),
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
          await prefs.setString('user_nickname', data['nickname'] ?? "Joueur");
          await prefs.setString(
            'user_avatarId',
            data['avatarId'] ?? "default_avatar",
          );
        }
      }

      if (mounted) {
        context.go('/lobby?roomId=${widget.roomId}');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _showSnackBar('Aucun utilisateur trouvé ou mot de passe incorrect.');
      } else if (e.code == 'wrong-password') {
        _showSnackBar('Le mot de passe est incorrect.');
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
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final String? idToken = googleAuth.idToken;

        final GoogleSignInClientAuthorization authorization = await googleUser
            .authorizationClient
            .authorizeScopes(['email', 'profile']);
        final String accessToken = authorization.accessToken;

        if (idToken == null) {
          _showSnackBar("Erreur : Impossible de récupérer les jetons Google.");
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
          String oldNickname = oldData['nickname'] ?? "Joueur";
          String oldAvatarId = oldData['avatarId'] ?? "default_avatar";

          bool? retrieveOldGame = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Partie existante trouvée ! ✨"),
                content: Text(
                  "Tu as déjà joué ! Veux-tu récupérer ton ancienne poupée ($oldNickname) ou écraser ton compte pour rejouer avec ta nouvelle poupée actuelle ?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      "Rejouer (Écraser)",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Récupérer l'ancienne"),
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
                prefs.getString('user_nickname') ?? "Joueur";
            String currentAvatarId =
                prefs.getString('user_avatarId') ?? "default_avatar";

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
              data['nickname'] ?? "Joueur",
            );
            await prefs.setString(
              'user_avatarId',
              data['avatarId'] ?? "default_avatar",
            );
          }
        }

        if (mounted) {
          context.go('/lobby?roomId=${widget.roomId}');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _showSnackBar('Ce compte Google appartient déjà à un autre joueur.');
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
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
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
                                            "Pas de profil ? ",
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
                                    color: Colors.white.withOpacity(0.5),
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
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            "OU",
                                            style: TextStyle(
                                              color: Color(0xFF5D3768),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
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
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
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
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
