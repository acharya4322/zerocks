/// Represents the status and capabilities of a connected printer.
/// Used by the shop app's printer management feature.
class PrinterStatusModel {
  final String name;
  final String? url;
  final bool isDefault;
  final PrinterState state;
  final DateTime lastCheckedAt;

  const PrinterStatusModel({
    required this.name,
    this.url,
    this.isDefault = false,
    this.state = PrinterState.unknown,
    required this.lastCheckedAt,
  });

  bool get isReady => state == PrinterState.ready;
  bool get hasIssue =>
      state == PrinterState.error ||
      state == PrinterState.offline ||
      state == PrinterState.paperJam ||
      state == PrinterState.lowInk;

  PrinterStatusModel copyWith({
    String? name,
    String? url,
    bool? isDefault,
    PrinterState? state,
    DateTime? lastCheckedAt,
  }) {
    return PrinterStatusModel(
      name: name ?? this.name,
      url: url ?? this.url,
      isDefault: isDefault ?? this.isDefault,
      state: state ?? this.state,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }
}

enum PrinterState {
  ready,
  offline,
  error,
  paperJam,
  lowInk,
  busy,
  unknown;

  String get label {
    switch (this) {
      case PrinterState.ready:
        return 'Ready';
      case PrinterState.offline:
        return 'Offline';
      case PrinterState.error:
        return 'Error';
      case PrinterState.paperJam:
        return 'Paper Jam';
      case PrinterState.lowInk:
        return 'Low Ink';
      case PrinterState.busy:
        return 'Busy';
      case PrinterState.unknown:
        return 'Unknown';
    }
  }
}
