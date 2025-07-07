import 'package:flutter/material.dart';

class NumberedMarker extends StatelessWidget {
  final int number;
  final Color backgroundColor;
  final Color textColor;
  final double size;

  const NumberedMarker({
    super.key,
    required this.number,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

class MapPinMarker extends StatelessWidget {
  final Color color;
  final double size;

  const MapPinMarker({
    super.key,
    this.color = Colors.green,
    this.size = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on,
      color: color,
      size: size,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}