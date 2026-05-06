/// Local calendar day as `YYYYMMDD` (e.g. 20260416). Used for market price history (date-only, no time-of-day).
int encodeLocalYyyymmdd(DateTime localDate) {
  return localDate.year * 10000 + localDate.month * 100 + localDate.day;
}

DateTime localMidnightFromYyyymmdd(int yyyymmdd) {
  final int y = yyyymmdd ~/ 10000;
  final int m = (yyyymmdd % 10000) ~/ 100;
  final int d = yyyymmdd % 100;
  return DateTime(y, m, d);
}

int encodeLocalYyyymmddFromMs(int msSinceEpoch) {
  final DateTime t = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
  return encodeLocalYyyymmdd(DateTime(t.year, t.month, t.day));
}

/// End of local calendar day [yyyymmdd], for quantity / valuation cutoffs.
int endOfLocalDayMs(int yyyymmdd) {
  final DateTime start = localMidnightFromYyyymmdd(yyyymmdd);
  return DateTime(start.year, start.month, start.day, 23, 59, 59, 999)
      .millisecondsSinceEpoch;
}
