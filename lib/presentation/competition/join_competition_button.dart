import 'package:fashion_room_girls/data/services/lobby_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoinCompetitionButton extends StatelessWidget {
  const JoinCompetitionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null || currentUser.isAnonymous) {
          if (context.mounted) {
            context.push('/login?roomId=none');
          }
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final SharedPreferences prefs = await SharedPreferences.getInstance();

          String myUid = currentUser.uid;
          String myNickname = prefs.getString('user_nickname') ?? "Player";
          String myAvatarId =
              prefs.getString('user_avatarId') ?? "avatar1";
          int myLevel = prefs.getInt('user_level') ?? 1;

          String roomId = await LobbyService().findOrCreateLobby(
            currentUserId: myUid,
            currentUserNickname: myNickname,
            currentUserAvatarId: myAvatarId,
            userLevel: myLevel,
          );

          if (context.mounted) {
            Navigator.pop(context);
          }

          if (context.mounted) {
            context.push('/lobby?roomId=$roomId');
          }
        } catch (error) {
          if (context.mounted) {
            Navigator.pop(context);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Couldn't find a room: $error"),
              ),
            );
          }
        }
      },
      child: const Text("Join the Contest"),
    );
  }
}
