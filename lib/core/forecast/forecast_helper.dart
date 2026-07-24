/// Naive trend projection for the sales forecast screen. Not a statistical
/// model — just extrapolates the average day-over-day change from recent
/// history, clamped at zero. Good enough for a directional estimate; a real
/// forecast needs a lot more data than this mock app has.
List<double> projectNextDays(List<double> history, int days) {
  if (history.length < 2 || days <= 0) {
    return List.filled(days, history.isEmpty ? 0 : history.last);
  }

  var totalChange = 0.0;
  for (var i = 1; i < history.length; i++) {
    totalChange += history[i] - history[i - 1];
  }
  final avgChange = totalChange / (history.length - 1);

  final projected = <double>[];
  var last = history.last;
  for (var i = 0; i < days; i++) {
    last = (last + avgChange).clamp(0, double.infinity);
    projected.add(last);
  }
  return projected;
}
