import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget(
      {super.key, this.height, this.width, this.constraints, this.loader});
  final double? height;
  final double? width;
  final BoxConstraints? constraints;
  final Widget? loader;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: constraints,
      width: width,
      height: height,
      child: loader ?? const CircularProgressIndicator.adaptive(),
    );
  }
}
