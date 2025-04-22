import 'package:flutter/material.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final double gap; // Расстояние между чекбоксом и текстом
  final TextStyle? textStyle;

  const CustomCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.gap = 4.0,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(width: gap),
          Text(
            label,
            style: textStyle ?? const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}