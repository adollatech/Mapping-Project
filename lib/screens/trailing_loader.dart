import 'package:flutter/material.dart';

class TrailingLoader extends StatelessWidget {
  const TrailingLoader({super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return  SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator.adaptive(
        backgroundColor: colorScheme.onSecondaryContainer,
        valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
        strokeWidth: 3,
      ),
    );
  }
}
