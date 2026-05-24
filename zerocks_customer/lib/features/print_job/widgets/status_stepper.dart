import 'package:flutter/material.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/constants/app_constants.dart';

class StatusStepper extends StatelessWidget {
  final PrintJobStatus currentStatus;

  const StatusStepper({super.key, required this.currentStatus});

  static const _steps = PrintJobStatus.values;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentIndex = _steps.indexOf(currentStatus);

    return SizedBox(
      height: 100,
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          // Even indices = step circles, odd = connecting lines
          if (index.isOdd) {
            final lineIndex = index ~/ 2;
            final isCompleted = lineIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppConstants.statusColor(_steps[lineIndex])
                      : colorScheme.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final step = _steps[stepIndex];
          final isCompleted = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;
          final color = AppConstants.statusColor(step);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 40 : 32,
                height: isCurrent ? 40 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isCurrent
                      ? color
                      : colorScheme.surfaceContainerHighest,
                  border: isCurrent
                      ? Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 3,
                        )
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : AppConstants.statusIcon(step),
                  size: isCurrent ? 20 : 16,
                  color: isCompleted || isCurrent
                      ? Colors.white
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              // Label
              Text(
                step.label,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent
                      ? color
                      : isCompleted
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }),
      ),
    );
  }
}
