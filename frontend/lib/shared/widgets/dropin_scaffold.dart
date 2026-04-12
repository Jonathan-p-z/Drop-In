import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Scaffold de base Drop'In — fond #111111 et AppBar optionnelle sans ombre.
class DropInScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showAppBar;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const DropInScaffold({
    super.key,
    required this.body,
    this.title,
    this.showAppBar = false,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title ?? 'Drop\'In',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: actions,
            )
          : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
