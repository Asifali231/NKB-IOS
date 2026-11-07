import 'package:cloud_firestore/cloud_firestore.dart';

class ProposalFeedSettings {
  const ProposalFeedSettings({
    this.prioritizeExactMatches = true,
    this.showFallbackNotice = true,
    this.bannerText = '',
  });

  final bool prioritizeExactMatches;
  final bool showFallbackNotice;
  final String bannerText;

  static DocumentReference<Map<String, dynamic>> document(
    FirebaseFirestore firestore,
  ) =>
      firestore.collection('config').doc('proposal_feed');

  static Future<ProposalFeedSettings> load(
    FirebaseFirestore firestore,
  ) async {
    final snapshot = await document(firestore).get();
    final data = snapshot.data();
    return ProposalFeedSettings(
      prioritizeExactMatches: data?['prioritizeExactMatches'] as bool? ?? true,
      showFallbackNotice: data?['showFallbackNotice'] as bool? ?? true,
      bannerText: data?['bannerText'] as String? ?? '',
    );
  }
}
