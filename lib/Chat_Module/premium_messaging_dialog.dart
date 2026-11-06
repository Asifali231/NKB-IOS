import 'package:flutter/material.dart';
import 'package:nikah_blessing/FirebaseOperation/payment_visibility_service.dart';
import 'package:nikah_blessing/Packages_Module/allPackagesModule.dart';
import 'package:nikah_blessing/theme/app_brand_colors.dart';

Future<bool> showPremiumMessagingDialog(BuildContext context) async {
  if (!context.mounted) return false;
  final isHidden = await PaymentVisibilityService.arePaymentsHidden();
  if (!context.mounted) return false;
  if (isHidden) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Package upgrades are currently hidden.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return false;
  }

  final shouldOpenPackages = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Messaging upgrade',
        barrierColor: Colors.black.withOpacity(0.72),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          Widget pill(IconData icon, String label) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppBrandColors.brandPurple,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: const Color(0xFFFF6F9C)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          Widget feature({
            required IconData icon,
            required String title,
            required String subtitle,
          }) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppBrandColors.brandPurple,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF93B8), Color(0xFFFF5E8D)],
                      ),
                    ),
                    child: Icon(icon, color: const Color(0xFF411024), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF311423),
                                Color(0xFF25152A),
                                Color(0xFF17131F),
                              ],
                            ),
                            border: Border.all(
                              color: AppBrandColors.brandPurple,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 36,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -30,
                                right: -10,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFF6F9C)
                                        .withOpacity(0.18),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -40,
                                left: -20,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFF4F79)
                                        .withOpacity(0.14),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 24, 24, 22),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF98BD),
                                                Color(0xFFFF5B89),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF5B89)
                                                    .withOpacity(0.30),
                                                blurRadius: 18,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.chat_bubble_rounded,
                                            color: Color(0xFF451126),
                                            size: 30,
                                          ),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          onTap: () =>
                                              Navigator.of(dialogContext)
                                                  .pop(false),
                                          child: Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFA0C1)
                                            .withOpacity(0.16),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: AppBrandColors.brandPurple,
                                        ),
                                      ),
                                      child: const Text(
                                        'Premium Messaging',
                                        style: TextStyle(
                                          color: Color(0xFFFFA9C8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Upgrade to start meaningful conversations',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Unlock chat access, connect faster with serious matches, and move from browsing to real conversations.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.74),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        pill(Icons.lock_open_rounded,
                                            'Direct messaging'),
                                        pill(Icons.workspace_premium_rounded,
                                            'Premium plans'),
                                        pill(Icons.verified_user_rounded,
                                            'Secure checkout'),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    feature(
                                      icon: Icons.mark_chat_read_rounded,
                                      title: 'Chat without the paywall feeling',
                                      subtitle:
                                          'Open conversations instantly from profiles and respond while the interest is fresh.',
                                    ),
                                    const SizedBox(height: 12),
                                    feature(
                                      icon: Icons.favorite_rounded,
                                      title: 'Reach more serious matches',
                                      subtitle:
                                          'Paid plans are designed for users who are ready to connect, reply, and move forward.',
                                    ),
                                    const SizedBox(height: 12),
                                    feature(
                                      icon: Icons.auto_awesome_rounded,
                                      title: 'A cleaner premium experience',
                                      subtitle:
                                          'Explore packages built for better visibility, stronger engagement, and smoother matchmaking.',
                                    ),
                                    const SizedBox(height: 22),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              side: BorderSide(
                                                color:
                                                    AppBrandColors.brandPurple,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.of(dialogContext)
                                                    .pop(false),
                                            child: const Text(
                                              'Maybe later',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppBrandColors.brandGradient,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF4E7B)
                                                      .withOpacity(0.28),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(dialogContext)
                                                      .pop(true),
                                              child: const Text(
                                                'See Upgrade Plans',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Choose the plan that fits your journey and unlock messaging right away.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.56),
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ) ??
      false;

  return shouldOpenPackages && context.mounted;
}

Future<void> showPremiumMessagingUpgrade(BuildContext context) async {
  if (!await showPremiumMessagingDialog(context) || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PackagesPage()),
  );
}
