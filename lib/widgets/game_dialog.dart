import 'package:flutter/material.dart';

/// Shared surfaces for dialogs, game results, and in-game notices.
class GameModalStyle {
  GameModalStyle(BuildContext context, {this.warning = false})
    : dark = Theme.of(context).brightness == Brightness.dark;

  final bool dark;
  final bool warning;
  Color get surface => dark ? const Color(0xFF162D25) : const Color(0xFFF2F4EC);
  Color get border => dark ? const Color(0xFF456353) : const Color(0xFFBDCDC0);
  Color get title => dark ? const Color(0xFFF4F1E6) : const Color(0xFF203B2D);
  Color get body => dark ? const Color(0xFFB9CCC0) : const Color(0xFF52675A);
  Color get accent => warning
      ? (dark ? const Color(0xFFCE968C) : const Color(0xFF995F56))
      : (dark ? const Color(0xFFA8D7B6) : const Color(0xFF35664B));
  Color get onAccent =>
      dark ? const Color(0xFF172D21) : const Color(0xFFFFFCF5);
  RoundedRectangleBorder get shape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
    side: BorderSide(color: border),
  );
  ButtonStyle get primaryButton => FilledButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: onAccent,
    minimumSize: const Size(0, 48),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );
  ButtonStyle get secondaryButton => TextButton.styleFrom(
    foregroundColor: body,
    minimumSize: const Size(0, 48),
  );
}

class GameDialogEmblem extends StatelessWidget {
  const GameDialogEmblem({
    super.key,
    this.icon,
    this.child,
    this.warning = false,
  });
  final IconData? icon;
  final Widget? child;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final style = GameModalStyle(context, warning: warning);
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              style.accent.withValues(alpha: .18),
              style.accent.withValues(alpha: 0),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: child ?? Icon(icon, color: style.accent, size: 38),
      ),
    );
  }
}

/// A bounded, scroll-safe modal without intrinsic layout measurement.
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.title,
    this.message,
    this.body,
    this.icon,
    this.header,
    this.primaryAction,
    this.secondaryAction,
    this.onClose,
    this.closeKey,
    this.warning = false,
  });

  final String title;
  final String? message;
  final Widget? body;
  final IconData? icon;
  final Widget? header;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final VoidCallback? onClose;
  final Key? closeKey;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final style = GameModalStyle(context, warning: warning);
    final theme = Theme.of(context);
    final width = (MediaQuery.sizeOf(context).width - 32)
        .clamp(0.0, 380.0)
        .toDouble();
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: style.body,
          displayColor: style.title,
        ),
        filledButtonTheme: FilledButtonThemeData(style: style.primaryButton),
        textButtonTheme: TextButtonThemeData(style: style.secondaryButton),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: style.accent,
            side: BorderSide(color: style.border),
            minimumSize: const Size(0, 48),
          ),
        ),
      ),
      child: Dialog(
        backgroundColor: style.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: .24),
        shape: style.shape,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onClose != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        key: closeKey,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        color: style.body,
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  if (header != null || icon != null) ...[
                    header ?? GameDialogEmblem(icon: icon, warning: warning),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: style.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: style.body,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (body != null) ...[const SizedBox(height: 24), body!],
                  if (primaryAction != null || secondaryAction != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (secondaryAction != null)
                          Expanded(child: secondaryAction!),
                        if (primaryAction != null && secondaryAction != null)
                          const SizedBox(width: 12),
                        if (primaryAction != null)
                          Expanded(child: primaryAction!),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
