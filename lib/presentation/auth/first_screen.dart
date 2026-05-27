import 'package:fashion_room_girls/data/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<FirstScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final UserService _userService = UserService();
  final FocusNode _nicknameFocusNode = FocusNode();
  // 1. On ajoute un contrôleur pour le scroll
  final ScrollController _scrollController = ScrollController();

  String _selectedAvatarId = 'avatar_doux';
  bool _isLoading = false;
  bool _isKeyboardOpen = false;

  final Color _cozyPinkBg = const Color(0xFFFFF0F2);
  final Color _cozyRoseTheme = const Color(0xFFD18A91);

  final List<Map<String, String>> _avatars = [
    {
      'id': 'avatar_doux',
      'path': 'assets/avatars/avatar_doux.png',
      'name': 'Style Doux',
    },
    {
      'id': 'avatar_chic',
      'path': 'assets/avatars/avatar_chic.png',
      'name': 'Style Chic',
    },
    {
      'id': 'avatar_sport',
      'path': 'assets/avatars/avatar_sport.png',
      'name': 'Style Sport',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nicknameFocusNode.addListener(() {
      setState(() {
        _isKeyboardOpen = _nicknameFocusNode.hasFocus;
      });

      // 2. Si le clavier SE FERME, on force le scroll à revenir au top (0.0)
      if (!_nicknameFocusNode.hasFocus) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleStart() async {
    String nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Oups ! Entre un pseudonyme pour ta poupée ✨"),
          backgroundColor: _cozyRoseTheme,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.createAnonymousPlayer(
        nickname: nickname,
        avatarId: _selectedAvatarId,
      );

      if (mounted) {
        context.go('/test');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Bienvenue $nickname !")));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la création : $e")),
      );
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    _scrollController.dispose(); // Ne pas oublier de le dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login/firstimage.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // 3. On attache le contrôleur ici
              controller: _scrollController,
              physics: _isKeyboardOpen
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Container(
                width: 420,
                margin: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                decoration: BoxDecoration(
                  color: _cozyPinkBg.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. TITRE PRINCIPAL
                    Text(
                      "FASHION ROOM",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _cozyRoseTheme,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. TEXT FIELD (NICKNAME)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _cozyRoseTheme.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _nicknameController,
                        focusNode: _nicknameFocusNode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade700,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Enter Nickname...",
                          hintStyle: TextStyle(
                            color: Color.fromARGB(255, 95, 95, 95),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. TEXTE "CHOOSE AVATAR"
                    Text(
                      "Choose Avatar",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. SELECTION DES AVATARS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _avatars.map((avatar) {
                        bool isSelected = _selectedAvatarId == avatar['id'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatarId = avatar['id']!;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? _cozyRoseTheme
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      avatar['path']!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.face,
                                              size: 35,
                                              color: _cozyRoseTheme,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: _cozyRoseTheme,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 5. BOUTON START
                    _isLoading
                        ? CircularProgressIndicator(color: _cozyRoseTheme)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cozyRoseTheme,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(200, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _handleStart,
                            child: const Text(
                              "START",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
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
    );
  }
}
