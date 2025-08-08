import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:surveyapp/widgets/custom_stream_builder.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String collection;
  final String? filter;
  final Color? color;
  final Color? darkColor;
  final bool isLocal;
  const StatCard(
      {super.key,
      required this.collection,
      this.filter,
      required this.title,
      this.color,
      this.isLocal = false,
      this.darkColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    return Card.filled(
      color: (isDark ? darkColor : color) ??
          Theme.of(context).colorScheme.secondaryContainer,
      margin: EdgeInsets.only(right: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minWidth: 200, maxWidth: 280, maxHeight: 150),
          // height: 100,
          child: isLocal
              ? _buildLocalValueListener(context)
              : _buildStreamBuilder(context),
        ),
      ),
    );
  }

  Widget _buildLocalValueListener(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box<String>('surveys').listenable(),
        builder: (context, box, child) {
          return _buildContent(context, box.values);
        });
  }

  CustomStreamBuilder<Map<String, dynamic>> _buildStreamBuilder(
      BuildContext context) {
    return CustomStreamBuilder<Map<String, dynamic>>(
      collection: collection,
      fromMap: (map) => map,
      filter: filter,
      onEmpty: () => _buildContent(context, []),
      builder: (context, data) {
        return _buildContent(context, data);
      },
    );
  }

  Column _buildContent(BuildContext context, Iterable data) {
    final color = Colors.grey.shade100;
    return Column(
      children: [
        Text(
          title,
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
        const SizedBox(height: 8),
        Text(
          "${data.length}",
          style: TextStyle(
              fontSize: 37, fontWeight: FontWeight.bold, color: color),
        ),
        // Add more stats as needed
      ],
    );
  }
}
