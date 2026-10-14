import 'package:flutter/material.dart';

String formatListDate(BuildContext context, DateTime? date, {DateTime? now}) {
  if (date == null) return '';
  final l = MaterialLocalizations.of(context);
  final today = now ?? DateTime.now();
  if (DateUtils.isSameDay(date, today)) {
    return l.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
  if (date.year == today.year) return l.formatShortMonthDay(date);
  return l.formatShortDate(date);
}

String formatDetailDate(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final l = MaterialLocalizations.of(context);
  final time = l.formatTimeOfDay(
    TimeOfDay.fromDateTime(date),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return DateUtils.isSameDay(date, DateTime.now())
      ? time
      : '${l.formatShortMonthDay(date)}, $time';
}
