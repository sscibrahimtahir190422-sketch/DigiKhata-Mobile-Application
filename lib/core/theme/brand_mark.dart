import 'package:flutter/material.dart';
import 'app_theme.dart';

class DigiKhataBrandMark extends StatelessWidget {
  const DigiKhataBrandMark({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .25),
    child: Image.asset(
      'assets/branding/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        color: AppTheme.darkGreen,
        child: Icon(
          Icons.menu_book_rounded,
          color: Colors.white,
          size: size * .55,
        ),
      ),
    ),
  );
}
