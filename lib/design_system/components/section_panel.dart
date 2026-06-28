import 'package:flutter/material.dart';

class SectionPanel extends StatelessWidget {
  const SectionPanel({
    required this.title,
    required this.child,
    super.key,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
