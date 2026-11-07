import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_animtype.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/utils/animate.dart';
import 'package:nikah_blessing/theme/app_colors.dart';

Future<void> showAppAlert({
  required BuildContext context,
  required QuickAlertType type,
  String? title,
  String? text,
  Widget? widget,
  QuickAlertAnimType animType = QuickAlertAnimType.scale,
  bool barrierDismissible = true,
  VoidCallback? onConfirmBtnTap,
  VoidCallback? onCancelBtnTap,
  String confirmBtnText = 'Okay',
  String cancelBtnText = 'Cancel',
  TextStyle? confirmBtnTextStyle,
  TextStyle? cancelBtnTextStyle,
  Color backgroundColor = Colors.white,
  Color titleColor = Colors.black,
  Color textColor = Colors.black,
  bool showCancelBtn = false,
  bool showConfirmBtn = true,
  double borderRadius = 15,
  String? customAsset,
  double? width,
  Duration? autoCloseDuration,
  bool disableBackBtn = false,
}) async {
  Timer? timer;
  if (autoCloseDuration != null) {
    timer = Timer(autoCloseDuration, () {
      if (context.mounted &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  final alertTitle = title ?? _defaultTitle(type);
  final asset = customAsset ?? _assetForType(type);
  final isError = type == QuickAlertType.error;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: autoCloseDuration == null && barrierDismissible,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final content = PopScope(
        canPop: !disableBackBtn,
        child: AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              color: backgroundColor,
              width: width ?? MediaQuery.of(dialogContext).size.shortestSide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 150,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isError ? const Color(0xFFD64545) : null,
                      gradient: isError ? null : kBrandGradient,
                    ),
                    child: _alertImage(type, asset),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (alertTitle != null)
                          Text(
                            alertTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(dialogContext)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: titleColor) ??
                                TextStyle(color: titleColor),
                          ),
                        if (alertTitle != null) const SizedBox(height: 5),
                        if (text != null || type == QuickAlertType.loading)
                          Text(
                            text ?? 'Loading',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textColor),
                          ),
                        if (type == QuickAlertType.custom && widget != null)
                          widget,
                        const SizedBox(height: 10),
                        if (type != QuickAlertType.loading)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (type == QuickAlertType.confirm ||
                                  showCancelBtn)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      timer?.cancel();
                                      if (onCancelBtnTap != null) {
                                        onCancelBtnTap();
                                      } else {
                                        Navigator.pop(dialogContext);
                                      }
                                    },
                                    child: Center(
                                      child: Text(
                                        cancelBtnText,
                                        style: cancelBtnTextStyle ??
                                            const TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (showConfirmBtn)
                                if (type == QuickAlertType.confirm ||
                                    showCancelBtn)
                                  Expanded(
                                    child: _confirmButton(
                                      dialogContext,
                                      timer,
                                      confirmBtnText,
                                      confirmBtnTextStyle,
                                      onConfirmBtnTap,
                                    ),
                                  )
                                else
                                  _confirmButton(
                                    dialogContext,
                                    timer,
                                    confirmBtnText,
                                    confirmBtnTextStyle,
                                    onConfirmBtnTap,
                                  ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      return content;
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      switch (animType) {
        case QuickAlertAnimType.scale:
          return Animate.scale(child: child, animation: animation);
        case QuickAlertAnimType.rotate:
          return Animate.rotate(child: child, animation: animation);
        case QuickAlertAnimType.slideInDown:
          return Animate.slideInDown(child: child, animation: animation);
        case QuickAlertAnimType.slideInUp:
          return Animate.slideInUp(child: child, animation: animation);
        case QuickAlertAnimType.slideInLeft:
          return Animate.slideInLeft(child: child, animation: animation);
        case QuickAlertAnimType.slideInRight:
          return Animate.slideInRight(child: child, animation: animation);
      }
    },
  );
  timer?.cancel();
}

Widget _confirmButton(
  BuildContext context,
  Timer? timer,
  String text,
  TextStyle? textStyle,
  VoidCallback? onConfirmBtnTap,
) {
  return MaterialButton(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    color: kBrandPrimary,
    onPressed: () {
      timer?.cancel();
      if (onConfirmBtnTap != null) {
        onConfirmBtnTap();
      } else {
        Navigator.pop(context);
      }
    },
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(7.5),
        child: Text(
          text,
          style: textStyle ??
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
        ),
      ),
    ),
  );
}

String? _defaultTitle(QuickAlertType type) {
  switch (type) {
    case QuickAlertType.success:
      return 'Success';
    case QuickAlertType.error:
      return 'Error';
    case QuickAlertType.warning:
      return 'Warning';
    case QuickAlertType.confirm:
      return 'Are You Sure?';
    case QuickAlertType.info:
      return 'Info';
    case QuickAlertType.custom:
    case QuickAlertType.loading:
      return null;
  }
}

String _assetForType(QuickAlertType type) {
  switch (type) {
    case QuickAlertType.success:
      return 'packages/quickalert/assets/success.gif';
    case QuickAlertType.error:
      return 'packages/quickalert/assets/error.gif';
    case QuickAlertType.warning:
      return 'packages/quickalert/assets/warning.gif';
    case QuickAlertType.confirm:
      return 'packages/quickalert/assets/confirm.gif';
    case QuickAlertType.loading:
      return 'packages/quickalert/assets/loading.gif';
    case QuickAlertType.info:
    case QuickAlertType.custom:
      return 'packages/quickalert/assets/info.gif';
  }
}

Widget _alertImage(QuickAlertType type, String asset) {
  final useBlueChannel = type == QuickAlertType.info;
  final alphaThreshold = useBlueChannel ? 210.0 : 165.0;
  final alphaRow = useBlueChannel
      ? [0.0, 0.0, 3.0, 0.0, -alphaThreshold]
      : [3.0, 0.0, 0.0, 0.0, -alphaThreshold];
  final image = Image.asset(asset, fit: BoxFit.cover);

  if (type == QuickAlertType.error) return image;

  return ColorFiltered(
    colorFilter: ColorFilter.matrix([
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      ...alphaRow,
    ]),
    child: image,
  );
}
