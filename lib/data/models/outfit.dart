import 'package:cloud_firestore/cloud_firestore.dart';

class SubmittedOutfit {
  final String userId;
  final String username;
  final Map<String, dynamic> outfitData;
  final bool isBot;
  final int votesCount;
  final Timestamp? submittedAt;
  final bool finishedInTime;

  const SubmittedOutfit({
    required this.userId,
    required this.username,
    required this.outfitData,
    required this.isBot,
    required this.votesCount,
    this.submittedAt,
    required this.finishedInTime,
  });

  factory SubmittedOutfit.fromFirestore(Map<String, dynamic> data, String id) {
    return SubmittedOutfit(
      userId: data['userId'] as String? ?? id,
      username: data['username'] as String? ?? '',
      outfitData: data['outfitData'] as Map<String, dynamic>? ?? {},
      isBot: data['isBot'] as bool? ?? false,
      votesCount: data['votesCount'] as int? ?? 0,
      submittedAt: data['submittedAt'] as Timestamp?,
      finishedInTime: data['finishedInTime'] as bool? ?? false,
    );
  }
}
