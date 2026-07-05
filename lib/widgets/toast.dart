import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';

enum ToastType { success, error, warning, info }

class ToastMessenger {
  ToastMessenger._();
  static final ToastMessenger instance = ToastMessenger._();

  final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  void show(String message, {ToastType type = ToastType.info}) {
    final state = key.currentState;
    if (state == null || message.isEmpty) return;
    state
      ..hideCurrentSnackBar()
      ..showSnackBar(_snackBar(message, type));
  }

  void success(String m) => show(m, type: ToastType.success);
  void error(String m) => show(m, type: ToastType.error);
  void warning(String m) => show(m, type: ToastType.warning);
  void info(String m) => show(m, type: ToastType.info);

  SnackBar _snackBar(String message, ToastType type) {
    final tone = _tone(type);
    return SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.zero,
      duration:
          Duration(milliseconds: type == ToastType.error ? 6000 : 4000),
      content: Container(
        decoration: BoxDecoration(
          color: EdgeColors.card.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EdgeColors.white10),
          boxShadow: const [
            BoxShadow(
              color: Color(0xE6000000),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 22,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(_icon(type), color: tone, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTheme.sans(
                  size: 13.5,
                  color: EdgeColors.slate200,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tone(ToastType t) => switch (t) {
        ToastType.success => EdgeColors.accent,
        ToastType.error => EdgeColors.danger,
        ToastType.warning => EdgeColors.warning,
        ToastType.info => EdgeColors.info,
      };
  IconData _icon(ToastType t) => switch (t) {
        ToastType.success => Icons.check_circle_outline,
        ToastType.error => Icons.error_outline,
        ToastType.warning => Icons.warning_amber_rounded,
        ToastType.info => Icons.info_outline,
      };
}
