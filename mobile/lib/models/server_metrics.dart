class ServerMetrics {
  final int cpuCount;
  final String loadAverage;
  final double systemCpuUsage;
  final String totalMemMB;
  final String usedMemMB;
  final String freeMemMB;
  final double memUsagePercent;
  final String totalDiskGB;
  final String usedDiskGB;
  final String freeDiskGB;
  final double diskUsagePercent;
  final String systemUptime;
  final String processUptime;
  final String nodeVersion;
  final int pid;
  final ProcessMemory processMemory;
  final BandwidthUsage bandwidthUsage;
  final List<NetworkInterface> networkInterfaces;

  ServerMetrics({
    required this.cpuCount,
    required this.loadAverage,
    required this.systemCpuUsage,
    required this.totalMemMB,
    required this.usedMemMB,
    required this.freeMemMB,
    required this.memUsagePercent,
    required this.totalDiskGB,
    required this.usedDiskGB,
    required this.freeDiskGB,
    required this.diskUsagePercent,
    required this.systemUptime,
    required this.processUptime,
    required this.nodeVersion,
    required this.pid,
    required this.processMemory,
    required this.bandwidthUsage,
    required this.networkInterfaces,
  });

  factory ServerMetrics.fromJson(Map<String, dynamic> json) {
    return ServerMetrics(
      cpuCount: json['cpuCount'] ?? 0,
      loadAverage: json['loadAverage'] ?? '-',
      systemCpuUsage: (json['systemCpuUsage'] ?? 0.0).toDouble(),
      totalMemMB: json['totalMemMB'] ?? '-',
      usedMemMB: json['usedMemMB'] ?? '-',
      freeMemMB: json['freeMemMB'] ?? '-',
      memUsagePercent: (json['memUsagePercent'] ?? 0.0).toDouble(),
      totalDiskGB: json['totalDiskGB'] ?? '-',
      usedDiskGB: json['usedDiskGB'] ?? '-',
      freeDiskGB: json['freeDiskGB'] ?? '-',
      diskUsagePercent: (json['diskUsagePercent'] ?? 0.0).toDouble(),
      systemUptime: json['systemUptime'] ?? '-',
      processUptime: json['processUptime'] ?? '-',
      nodeVersion: json['nodeVersion'] ?? '-',
      pid: json['pid'] ?? 0,
      processMemory: ProcessMemory.fromJson(json['processMemory'] ?? {}),
      bandwidthUsage: BandwidthUsage.fromJson(json['bandwidthUsage'] ?? {}),
      networkInterfaces: (json['networkInterfaces'] as List<dynamic>?)
              ?.map((e) => NetworkInterface.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ProcessMemory {
  final String rss;
  final String heapTotal;
  final String heapUsed;
  final String external;

  ProcessMemory({
    required this.rss,
    required this.heapTotal,
    required this.heapUsed,
    required this.external,
  });

  factory ProcessMemory.fromJson(Map<String, dynamic> json) {
    return ProcessMemory(
      rss: json['rss'] ?? '-',
      heapTotal: json['heapTotal'] ?? '-',
      heapUsed: json['heapUsed'] ?? '-',
      external: json['external'] ?? '-',
    );
  }
}

class BandwidthUsage {
  final String totalRx;
  final String totalTx;

  BandwidthUsage({
    required this.totalRx,
    required this.totalTx,
  });

  factory BandwidthUsage.fromJson(Map<String, dynamic> json) {
    return BandwidthUsage(
      totalRx: json['totalRx'] ?? '-',
      totalTx: json['totalTx'] ?? '-',
    );
  }
}

class NetworkInterface {
  final String name;
  final String address;
  final String speed;
  final String rxBytes;
  final String txBytes;
  final int rxErrors;
  final int txErrors;

  NetworkInterface({
    required this.name,
    required this.address,
    required this.speed,
    required this.rxBytes,
    required this.txBytes,
    required this.rxErrors,
    required this.txErrors,
  });

  factory NetworkInterface.fromJson(Map<String, dynamic> json) {
    return NetworkInterface(
      name: json['name'] ?? '-',
      address: json['address'] ?? '-',
      speed: json['speed'] ?? '-',
      rxBytes: json['rx_bytes'] ?? '-',
      txBytes: json['tx_bytes'] ?? '-',
      rxErrors: json['rx_errors'] ?? 0,
      txErrors: json['tx_errors'] ?? 0,
    );
  }
}
