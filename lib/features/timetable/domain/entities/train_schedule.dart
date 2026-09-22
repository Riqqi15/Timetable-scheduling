class TrainSchedule {
  const TrainSchedule({
    required this.trainName,
    required this.route,
    required this.departureTime,
    required this.arrivalTime,
    required this.platform,
    required this.trainType, // 'KRL', 'LRT', 'MRT'
    required this.stationName, // 'Setiabudi', 'Cawang', 'Manggarai', 'Tanah Abang', 'Halim'
    required this.isWeekend, // true = Weekend, false = Weekday
    this.dayOffset = 0,
    this.nextStation,
    this.destination,
    this.direction,
  });

  final String trainName;
  final String route;
  final String departureTime;
  final String arrivalTime;
  final String platform;
  final String trainType;
  final String stationName;
  final bool isWeekend;
  final int dayOffset;
  final String? nextStation;
  final String? destination;
  final String? direction;
}
