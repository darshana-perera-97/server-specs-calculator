import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/metrics_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/donut_chart.dart';
import '../models/server_metrics.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start auto-refresh and fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MetricsProvider>(context, listen: false);
      provider.fetchMetrics();
      provider.startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Consumer<MetricsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.metrics == null) {
            return _buildLoadingState();
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          return _buildDashboard(provider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<MetricsProvider>(context, listen: false).fetchMetrics();
        },
        backgroundColor: const Color(0xFF129990),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF129990)),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Loading server metrics...',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(MetricsProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 24),
          Text(
            'Error loading data',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            provider.error!,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              provider.clearError();
              provider.fetchMetrics();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF129990),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(MetricsProvider provider) {
    final metrics = provider.metrics!;
    
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Server Analytics',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Real-time system performance monitoring dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (provider.lastUpdated != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy HH:mm:ss').format(provider.lastUpdated!)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Dashboard content
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              
              // System Performance Card
              _buildSystemPerformanceCard(metrics),
              const SizedBox(height: 24),
              
              // Memory Usage Card
              _buildMemoryUsageCard(metrics),
              const SizedBox(height: 24),
              
              // Disk Storage Card
              _buildDiskStorageCard(metrics),
              const SizedBox(height: 24),
              
              // Uptime & Process Card
              _buildUptimeProcessCard(metrics),
              const SizedBox(height: 24),
              
              // Process Memory Card
              _buildProcessMemoryCard(metrics),
              const SizedBox(height: 24),
              
              // Network & Bandwidth Card
              _buildNetworkBandwidthCard(metrics),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemPerformanceCard(ServerMetrics metrics) {
    return MetricCard(
      title: 'System Performance',
      icon: Icons.speed,
      iconColor: const Color(0xFF129990),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            MetricItem(
              value: metrics.cpuCount.toString(),
              label: 'CPU CORES',
            ),
            MetricItem(
              value: metrics.loadAverage,
              label: 'LOAD AVERAGE',
            ),
          ],
        ),
      ],
      chart: DonutChart(
        percentage: metrics.systemCpuUsage,
        title: 'CPU Usage',
        primaryColor: const Color(0xFF129990),
      ),
    );
  }

  Widget _buildMemoryUsageCard(ServerMetrics metrics) {
    return MetricCard(
      title: 'Memory Usage',
      icon: Icons.memory,
      iconColor: const Color(0xFF90D1CA),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            MetricItem(
              value: metrics.totalMemMB,
              label: 'TOTAL MEMORY',
            ),
            MetricItem(
              value: metrics.usedMemMB,
              label: 'USED MEMORY',
            ),
            MetricItem(
              value: metrics.freeMemMB,
              label: 'FREE MEMORY',
            ),
          ],
        ),
      ],
      chart: DonutChart(
        percentage: metrics.memUsagePercent,
        title: 'Memory Usage',
        primaryColor: const Color(0xFF90D1CA),
      ),
    );
  }

  Widget _buildDiskStorageCard(ServerMetrics metrics) {
    return MetricCard(
      title: 'Disk Storage',
      icon: Icons.storage,
      iconColor: const Color(0xFF096B68),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            MetricItem(
              value: metrics.totalDiskGB,
              label: 'TOTAL DISK',
            ),
            MetricItem(
              value: metrics.usedDiskGB,
              label: 'USED DISK',
            ),
            MetricItem(
              value: metrics.freeDiskGB,
              label: 'FREE DISK',
            ),
          ],
        ),
      ],
      chart: DonutChart(
        percentage: metrics.diskUsagePercent,
        title: 'Disk Usage',
        primaryColor: const Color(0xFF096B68),
      ),
    );
  }

  Widget _buildUptimeProcessCard(ServerMetrics metrics) {
    return MetricCard(
      title: 'Uptime & Process',
      icon: Icons.access_time,
      iconColor: const Color(0xFF90D1CA),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            MetricItem(
              value: metrics.systemUptime,
              label: 'SYSTEM UPTIME',
            ),
            MetricItem(
              value: metrics.processUptime,
              label: 'PROCESS UPTIME',
            ),
            MetricItem(
              value: metrics.nodeVersion,
              label: 'NODE.JS VERSION',
            ),
            MetricItem(
              value: metrics.pid.toString(),
              label: 'PROCESS ID',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessMemoryCard(ServerMetrics metrics) {
    return MetricCard(
      title: 'Process Memory',
      icon: Icons.memory,
      iconColor: const Color(0xFF096B68),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            MetricItem(
              value: metrics.processMemory.rss,
              label: 'RSS',
            ),
            MetricItem(
              value: metrics.processMemory.heapTotal,
              label: 'HEAP TOTAL',
            ),
            MetricItem(
              value: metrics.processMemory.heapUsed,
              label: 'HEAP USED',
            ),
            MetricItem(
              value: metrics.processMemory.external,
              label: 'EXTERNAL',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkBandwidthCard(ServerMetrics metrics) {
    return MetricCard(
      title: 'Network & Bandwidth',
      icon: Icons.network_check,
      iconColor: const Color(0xFF90D1CA),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            MetricItem(
              value: metrics.bandwidthUsage.totalRx,
              label: 'TOTAL RX',
            ),
            MetricItem(
              value: metrics.bandwidthUsage.totalTx,
              label: 'TOTAL TX',
            ),
          ],
        ),
        if (metrics.networkInterfaces.isNotEmpty) ...[
          const SizedBox(height: 24),
          ...metrics.networkInterfaces.map((iface) => _buildNetworkInterfaceItem(iface)),
        ],
      ],
    );
  }

  Widget _buildNetworkInterfaceItem(NetworkInterface iface) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${iface.name} (${iface.address})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF129990),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildNetworkMetric('Speed', iface.speed),
              _buildNetworkMetric('RX', iface.rxBytes),
              _buildNetworkMetric('TX', iface.txBytes),
              _buildNetworkMetric('Errors', 'RX: ${iface.rxErrors}, TX: ${iface.txErrors}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
