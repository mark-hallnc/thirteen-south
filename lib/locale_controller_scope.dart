import 'package:flutter/material.dart';

class LocaleControllerScope extends InheritedWidget {
  const LocaleControllerScope({
    super.key,
    required this.locale,
    required this.setLocale,
    required super.child,
  });

  final Locale? locale;
  final Future<void> Function(Locale? locale) setLocale;

  static LocaleControllerScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleControllerScope>()!;
  }

  @override
  bool updateShouldNotify(LocaleControllerScope oldWidget) =>
      locale != oldWidget.locale;
}
