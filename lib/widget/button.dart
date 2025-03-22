import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({
    super.key,
    this.width,
    this.height = 52,
    this.onPressed,
    required this.text,
    this.padding,
  });

  final double? width;
  final double? height;
  final VoidCallback? onPressed;
  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      child: ElevatedButton(
        onPressed: onPressed,
        style: const ButtonStyle().copyWith(
          backgroundColor: MaterialStateProperty.all(Colors.teal),
          fixedSize: WidgetStateProperty.all(
            Size(
              MediaQuery.of(context).size.width,
              height ?? 0,
            ),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
