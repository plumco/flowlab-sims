import 'dart:math';

enum FixtureType {
  wc,
  washbasin,
  shower,
  idle,
}

extension FixtureTypeExt on FixtureType {
  String get displayName {
    switch (this) {
      case FixtureType.wc:
        return 'WC (6L Cistern)';
      case FixtureType.washbasin:
        return 'Washbasin';
      case FixtureType.shower:
        return 'Shower / Floor Trap';
      case FixtureType.idle:
        return 'Idle';
    }
  }

  String get shortCode {
    switch (this) {
      case FixtureType.wc:
        return 'WC';
      case FixtureType.washbasin:
        return 'Basin';
      case FixtureType.shower:
        return 'Trap';
      case FixtureType.idle:
        return 'Idle';
    }
  }

  String get icon {
    switch (this) {
      case FixtureType.wc:
        return '🚽';
      case FixtureType.washbasin:
        return '🚰';
      case FixtureType.shower:
        return '🚿';
      case FixtureType.idle:
        return '⚪';
    }
  }

  double get du {
    switch (this) {
      case FixtureType.wc:
        return 2.0;
      case FixtureType.washbasin:
        return 0.5;
      case FixtureType.shower:
        return 0.6;
      case FixtureType.idle:
        return 0.0;
    }
  }

  /// Peak instantaneous flow in L/s per fixture
  double get flowRateLs {
    switch (this) {
      case FixtureType.wc:
        return 1.8; // 6L flush over ~3.3-4.0s average active discharge
      case FixtureType.washbasin:
        return 0.5; // EN 12056-2 standard washbasin tap
      case FixtureType.shower:
        return 0.6; // EN 12056-2 floor trap shower without plug
      case FixtureType.idle:
        return 0.0;
    }
  }

  /// Duration in seconds for simulation step
  double get durationSeconds {
    switch (this) {
      case FixtureType.wc:
        return 6.5;
      case FixtureType.washbasin:
        return 15.0;
      case FixtureType.shower:
        return 25.0;
      case FixtureType.idle:
        return 0.0;
    }
  }
}

/// Represents a single chronological fixture discharge event captured with live laptop clock
class FixtureEventLog {
  final int seq;
  final DateTime realTimestamp;
  final String simulatedClock; // e.g. "07:34:18 AM"
  final int floor;
  final FixtureType fixtureType;
  final double du;
  final double flowRateLs;
  final double timeGapSeconds;
  final double instantaneousStackFlowLs;
  final double peakPositiveSurgeMm;
  final double peakSuctionPullMm;
  final double minTrapSealMm;

  FixtureEventLog({
    required this.seq,
    required this.realTimestamp,
    required this.simulatedClock,
    required this.floor,
    required this.fixtureType,
    required this.du,
    required this.flowRateLs,
    required this.timeGapSeconds,
    required this.instantaneousStackFlowLs,
    required this.peakPositiveSurgeMm,
    required this.peakSuctionPullMm,
    required this.minTrapSealMm,
  });

  String get timeFormatted {
    final h = realTimestamp.hour.toString().padLeft(2, '0');
    final m = realTimestamp.minute.toString().padLeft(2, '0');
    final s = realTimestamp.second.toString().padLeft(2, '0');
    final ms = (realTimestamp.millisecond ~/ 100).toString();
    return '$h:$m:$s.$ms';
  }
}

/// State tracking for single-occupancy mutual exclusivity in each bathroom
class FloorOccupancyState {
  final int floor;
  FixtureType activeFixture = FixtureType.idle;
  double remainingDuration = 0.0;
  DateTime? lastDischargeTime;

  FloorOccupancyState({required this.floor});

  bool get isBusy => activeFixture != FixtureType.idle && remainingDuration > 0;

  void triggerFixture(FixtureType fixture, DateTime now) {
    activeFixture = fixture;
    remainingDuration = fixture.durationSeconds;
    lastDischargeTime = now;
  }

  void update(double dt) {
    if (activeFixture != FixtureType.idle) {
      remainingDuration = max(0.0, remainingDuration - dt);
      if (remainingDuration <= 0) {
        activeFixture = FixtureType.idle;
      }
    }
  }

  void reset() {
    activeFixture = FixtureType.idle;
    remainingDuration = 0.0;
  }
}
