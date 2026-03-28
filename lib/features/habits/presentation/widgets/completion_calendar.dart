import 'package:flutter/material.dart';
import 'package:habit_coach/core/utils/date_utils.dart';

/// T051: CompletionCalendar — monthly grid showing which days a habit was
/// completed.
///
/// Completed days are filled with the primary colour. Today is outlined.
/// Non-completed past days within the month are shown in a muted colour.
class CompletionCalendar extends StatelessWidget {
  const CompletionCalendar({
    super.key,
    required this.completedDates,
    this.month,
  });

  /// Set of date strings (yyyy-MM-dd) on which completions exist.
  final Set<String> completedDates;

  /// Month to display. Defaults to the current month.
  final DateTime? month;

  @override
  Widget build(BuildContext context) {
    final reference = month ?? HabitDateUtils.today();
    final displayMonth = DateTime(reference.year, reference.month);
    final today = HabitDateUtils.today();

    final daysInMonth = DateUtils.getDaysInMonth(
      displayMonth.year,
      displayMonth.month,
    );
    final firstWeekday =
        DateTime(displayMonth.year, displayMonth.month, 1).weekday;
    // weekday: 1=Mon … 7=Sun → offset so Monday is first column
    final offset = (firstWeekday - 1) % 7;

    final theme = Theme.of(context);
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonthHeader(month: displayMonth),
        const SizedBox(height: 8),
        _WeekdayRow(),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: rows * 7,
          itemBuilder: (context, index) {
            final dayNumber = index - offset + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(
              displayMonth.year,
              displayMonth.month,
              dayNumber,
            );
            final dateStr = HabitDateUtils.toDateString(date);
            final isCompleted = completedDates.contains(dateStr);
            final isToday = date == today;
            final isFuture = date.isAfter(today);

            return _DayCell(
              dayNumber: dayNumber,
              isCompleted: isCompleted,
              isToday: isToday,
              isFuture: isFuture,
              theme: theme,
            );
          },
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month});

  final DateTime month;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_months[month.month - 1]} ${month.year}',
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          _labels
              .map(
                (l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.isCompleted,
    required this.isToday,
    required this.isFuture,
    required this.theme,
  });

  final int dayNumber;
  final bool isCompleted;
  final bool isToday;
  final bool isFuture;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor;
    BoxBorder? border;

    if (isCompleted) {
      bgColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isToday) {
      textColor = theme.colorScheme.primary;
      border = Border.all(color: theme.colorScheme.primary, width: 1.5);
    } else if (isFuture) {
      textColor = theme.colorScheme.onSurfaceVariant.withAlpha(80);
    } else {
      textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Text(
          '$dayNumber',
          style: theme.textTheme.labelSmall?.copyWith(color: textColor),
        ),
      ),
    );
  }
}
