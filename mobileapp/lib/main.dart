import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
	runApp(const ServerAnalyticsApp());
}

class ServerAnalyticsApp extends StatelessWidget {
	const ServerAnalyticsApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Server Analytics',
			theme: ThemeData(
				colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF129990)),
				useMaterial3: true,
			),
			debugShowCheckedModeBanner: false,
			home: const SplashPage(),
		);
	}
}

class SplashPage extends StatefulWidget {
	const SplashPage({super.key});

	@override
	State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
	@override
	void initState() {
		super.initState();
		// Simulate brief startup work before showing the dashboard
		Future.delayed(const Duration(milliseconds: 1500), () {
			if (!mounted) return;
			Navigator.of(context).pushReplacement(
				MaterialPageRoute(builder: (_) => const DashboardPage()),
			);
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Container(
				decoration: const BoxDecoration(
					gradient: LinearGradient(
						colors: [Color(0xFF129990), Color(0xFF90D1CA)],
						begin: Alignment.topLeft,
						end: Alignment.bottomRight,
					),
				),
				child: Center(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: const [
							Icon(Icons.analytics_outlined, color: Colors.white, size: 84),
							SizedBox(height: 12),
							Text(
								'Server Analytics',
								style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
							),
							SizedBox(height: 24),
							SizedBox(
								width: 36,
								height: 36,
								child: CircularProgressIndicator(
									valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
									strokeWidth: 3,
								),
							),
						],
					),
				),
			),
		);
	}
}

class ApiClient {
	ApiClient();

	String get baseUrl {
		if (kIsWeb) return 'http://69.197.187.24:3100';
    // http://69.197.187.24/
		// if (kIsWeb) return 'http://localhost:3100';
		try {
			if (Platform.isAndroid) return 'http://10.0.2.2:3100';
		} catch (_) {}
		return 'http://69.197.187.24:3100';
		// return 'http://localhost:3100';
	}

	Future<Map<String, dynamic>> fetchMetrics() async {
		final uri = Uri.parse('$baseUrl/api/metrics');
		final response = await http.get(uri).timeout(const Duration(seconds: 10));
		if (response.statusCode != 200) {
			throw Exception('HTTP ${response.statusCode}');
		}
		final jsonBody = json.decode(response.body) as Map<String, dynamic>;
		if (jsonBody['success'] != true) {
			throw Exception(jsonBody['error'] ?? 'Failed to load data');
		}
		return jsonBody['data'] as Map<String, dynamic>;
	}
}

class DashboardPage extends StatefulWidget {
	const DashboardPage({super.key});

	@override
	State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
	final ApiClient _api = ApiClient();
	Map<String, dynamic>? _metrics;
	String? _error;
	bool _loading = false;
	Timer? _refreshTimer;
	DateTime? _lastUpdated;

	@override
	void initState() {
		super.initState();
		_loadData();
		_refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
	}

	@override
	void dispose() {
		_refreshTimer?.cancel();
		super.dispose();
	}

	Future<void> _loadData() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final data = await _api.fetchMetrics();
			setState(() {
				_metrics = data;
				_lastUpdated = DateTime.now();
			});
		} catch (e) {
			setState(() {
				_error = 'Error loading data: $e';
			});
		} finally {
			if (mounted) {
				setState(() {
					_loading = false;
				});
			}
		}
	}

	double _parsePercent(dynamic value) {
		if (value == null) return 0;
		final s = value.toString();
		final cleaned = s.replaceAll('%', '').replaceAll(' ', '');
		return double.tryParse(cleaned) ?? 0;
	}

	String _string(dynamic value) => value?.toString() ?? '-';

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Server Analytics'),
				actions: [
					IconButton(
						onPressed: _loadData,
						tooltip: 'Refresh',
						icon: const Icon(Icons.refresh),
					),
				],
			),
			body: _buildBody(context),
		);
	}

	Widget _buildBody(BuildContext context) {
		if (_loading && _metrics == null) {
			return const Center(child: CircularProgressIndicator());
		}
		return RefreshIndicator(
			onRefresh: _loadData,
			child: SingleChildScrollView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Center(
							child: Column(
								children: [
									Text(
										'Server Analytics',
										style: Theme.of(context).textTheme.headlineMedium,
									),
									const SizedBox(height: 8),
									Text(
										'Real-time system performance monitoring dashboard',
										style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
										textAlign: TextAlign.center,
									),
								],
							),
						),
						const SizedBox(height: 16),
						if (_loading) ...[
							const SizedBox(height: 8),
							_LoadingTile(message: 'Loading server metrics...'),
							const SizedBox(height: 16),
						],
						if (_error != null) ...[
							_ErrorTile(message: _error!),
							const SizedBox(height: 16),
						],
						if (_metrics != null) ...[
							_buildSystemPerformanceCard(_metrics!),
							const SizedBox(height: 16),
							_buildMemoryCard(_metrics!),
							const SizedBox(height: 16),
							_buildDiskCard(_metrics!),
							const SizedBox(height: 16),
							_buildUptimeProcessCard(_metrics!),
							const SizedBox(height: 16),
							_buildProcessMemoryCard(_metrics!),
							const SizedBox(height: 16),
							_buildNetworkCard(_metrics!),
						],
						const SizedBox(height: 16),
						if (_lastUpdated != null)
							Center(
								child: Container(
									padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
									decoration: BoxDecoration(
										color: Colors.white,
										border: Border.all(color: Colors.grey.shade200),
										borderRadius: BorderRadius.circular(12),
									),
									child: Text(
										'Last updated: ${_lastUpdated!}',
										style: TextStyle(color: Colors.grey.shade600),
									),
								),
							),
					],
				),
			),
		);
	}

	Widget _buildSystemPerformanceCard(Map<String, dynamic> m) {
		final cpuPercent = _parsePercent(m['systemCpuUsage']);
		return _Card(
			title: 'System Performance',
			leadingIcon: Icons.speed,
			accentGradient: const [Color(0xFF129990), Color(0xFF90D1CA)],
			child: Column(
				children: [
					Row(
						children: [
							Expanded(child: _StatBox(label: 'CPU Cores', value: _string(m['cpuCount']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Load Average', value: _string(m['loadAverage']))),
						],
					),
					const SizedBox(height: 12),
					SizedBox(
						height: 240,
						child: _DonutChart(
							percent: cpuPercent,
							usedColor: const Color(0xFF129990),
							label: 'CPU Usage',
						),
					),
				],
			),
		);
	}

	Widget _buildMemoryCard(Map<String, dynamic> m) {
		final memPercent = _parsePercent(m['memUsagePercent']);
		return _Card(
			title: 'Memory Usage',
			leadingIcon: Icons.memory,
			accentGradient: const [Color(0xFF90D1CA), Color(0xFF129990)],
			child: Column(
				children: [
					Row(
						children: [
							Expanded(child: _StatBox(label: 'Total Memory', value: _string(m['totalMemMB']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Used Memory', value: _string(m['usedMemMB']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Free Memory', value: _string(m['freeMemMB']))),
						],
					),
					const SizedBox(height: 12),
					SizedBox(
						height: 240,
						child: _DonutChart(
							percent: memPercent,
							usedColor: const Color(0xFF90D1CA),
							label: 'Memory Usage',
						),
					),
				],
			),
		);
	}

	Widget _buildDiskCard(Map<String, dynamic> m) {
		final diskPercent = _parsePercent(m['diskUsagePercent']);
		return _Card(
			title: 'Disk Storage',
			leadingIcon: Icons.storage,
			accentGradient: const [Color(0xFF129990), Color(0xFF096B68)],
			child: Column(
				children: [
					Row(
						children: [
							Expanded(child: _StatBox(label: 'Total Disk', value: _string(m['totalDiskGB']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Used Disk', value: _string(m['usedDiskGB']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Free Disk', value: _string(m['freeDiskGB']))),
						],
					),
					const SizedBox(height: 12),
					SizedBox(
						height: 240,
						child: _DonutChart(
							percent: diskPercent,
							usedColor: const Color(0xFF129990),
							label: 'Disk Usage',
						),
					),
				],
			),
		);
	}

	Widget _buildUptimeProcessCard(Map<String, dynamic> m) {
		return _Card(
			title: 'Uptime & Process',
			leadingIcon: Icons.access_time,
			accentGradient: const [Color(0xFF90D1CA), Color(0xFF129990)],
			child: Column(
				children: [
					Row(
						children: [
							Expanded(child: _StatBox(label: 'System Uptime', value: _string(m['systemUptime']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Process Uptime', value: _string(m['processUptime']))),
						],
					),
					const SizedBox(height: 12),
					Row(
						children: [
							Expanded(child: _StatBox(label: 'Node.js Version', value: _string(m['nodeVersion']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Process ID', value: _string(m['pid']))),
						],
					),
				],
			),
		);
	}

	Widget _buildProcessMemoryCard(Map<String, dynamic> m) {
		final pm = (m['processMemory'] as Map?) ?? {};
		return _Card(
			title: 'Process Memory',
			leadingIcon: Icons.memory_outlined,
			accentGradient: const [Color(0xFF129990), Color(0xFF096B68)],
			child: Column(
				children: [
					Row(
						children: [
							Expanded(child: _StatBox(label: 'RSS', value: _string(pm['rss']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Heap Total', value: _string(pm['heapTotal']))),
						],
					),
					const SizedBox(height: 12),
					Row(
						children: [
							Expanded(child: _StatBox(label: 'Heap Used', value: _string(pm['heapUsed']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'External', value: _string(pm['external']))),
						],
					),
				],
			),
		);
	}

	Widget _buildNetworkCard(Map<String, dynamic> m) {
		final bw = (m['bandwidthUsage'] as Map?) ?? {};
		final interfaces = (m['networkInterfaces'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
		return _Card(
			title: 'Network & Bandwidth',
			leadingIcon: Icons.cable,
			accentGradient: const [Color(0xFF90D1CA), Color(0xFF129990)],
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						children: [
							Expanded(child: _StatBox(label: 'Total RX', value: _string(bw['totalRx']))),
							const SizedBox(width: 12),
							Expanded(child: _StatBox(label: 'Total TX', value: _string(bw['totalTx']))),
						],
					),
					const SizedBox(height: 8),
					for (final iface in interfaces)
						Padding(
							padding: const EdgeInsets.symmetric(vertical: 6),
							child: Container(
								padding: const EdgeInsets.all(12),
								decoration: BoxDecoration(
									color: const Color(0xFFF6F7F9),
									border: Border.all(color: Colors.grey.shade200),
									borderRadius: BorderRadius.circular(12),
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'${_string(iface['name'])} (${_string(iface['address'])})',
											style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF129990)),
										),
										const SizedBox(height: 8),
										Wrap(
											spacing: 16,
											runSpacing: 8,
											children: [
												_KeyValue('Speed', _string(iface['speed'])),
												_KeyValue('RX', _string(iface['rx_bytes'])),
												_KeyValue('TX', _string(iface['tx_bytes'])),
												_KeyValue('Errors', 'RX: ${_string(iface['rx_errors'])}, TX: ${_string(iface['tx_errors'])}'),
											],
										),
									],
								),
							),
						),
					if (interfaces.isEmpty)
						Container(
							padding: const EdgeInsets.all(12),
							decoration: BoxDecoration(
								color: const Color(0xFFF6F7F9),
								border: Border.all(color: Colors.grey.shade200),
								borderRadius: BorderRadius.circular(12),
							),
							child: const Center(child: Text('No network interfaces found')),
						),
				],
			),
		);
	}
}

class _Card extends StatelessWidget {
	const _Card({
		required this.title,
		required this.leadingIcon,
		required this.child,
		required this.accentGradient,
	});

	final String title;
	final IconData leadingIcon;
	final Widget child;
	final List<Color> accentGradient;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: Colors.grey.shade200),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withOpacity(0.03),
						blurRadius: 10,
						offset: const Offset(0, 6),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Container(
						height: 4,
						decoration: BoxDecoration(
							borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
							gradient: LinearGradient(colors: accentGradient),
						),
					),
					Padding(
						padding: const EdgeInsets.all(16),
						child: Row(
							children: [
								Container(
									width: 48,
									height: 48,
									decoration: BoxDecoration(
										borderRadius: BorderRadius.circular(14),
										gradient: LinearGradient(colors: accentGradient),
									),
									child: Icon(leadingIcon, color: Colors.white),
								),
								const SizedBox(width: 12),
								Expanded(
									child: Text(
										title,
										style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
									),
								),
							],
						),
					),
					const Divider(height: 1),
					Padding(
						padding: const EdgeInsets.all(16),
						child: child,
					),
				],
			),
		);
	}
}

class _StatBox extends StatelessWidget {
	const _StatBox({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
			decoration: BoxDecoration(
				color: const Color(0xFFF6F7F9),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: Colors.grey.shade200),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.center,
				children: [
					Text(
						value,
						style: const TextStyle(
							fontSize: 18,
							fontWeight: FontWeight.bold,
							color: Color(0xFF129990),
						),
					),
					const SizedBox(height: 4),
					Text(
						label.toUpperCase(),
						style: TextStyle(
							fontSize: 12,
							color: Colors.grey.shade600,
							fontWeight: FontWeight.w500,
							letterSpacing: 0.5,
						),
					),
				],
			),
		);
	}
}

class _KeyValue extends StatelessWidget {
	const _KeyValue(this.k, this.v);
	final String k;
	final String v;

	@override
	Widget build(BuildContext context) {
		return Row(
			mainAxisSize: MainAxisSize.min,
			children: [
				Text('$k: ', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
				Text(v, style: TextStyle(color: Colors.grey.shade700)),
			],
		);
	}
}

class _DonutChart extends StatelessWidget {
	const _DonutChart({required this.percent, required this.usedColor, required this.label});

	final double percent; // 0..100
	final Color usedColor;
	final String label;

	@override
	Widget build(BuildContext context) {
		final double used = percent.clamp(0.0, 100.0).toDouble();
		final double available = 100.0 - used;
		return Stack(
			alignment: Alignment.center,
			children: [
				PieChart(
					PieChartData(
						sectionsSpace: 0,
						centerSpaceRadius: 70,
						startDegreeOffset: -90,
						sections: [
							PieChartSectionData(
								color: usedColor,
								value: used,
								showTitle: false,
							),
							PieChartSectionData(
								color: const Color(0xFFE8E8E8),
								value: available,
								showTitle: false,
							),
						],
					),
				),
				Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(
							'${used.toStringAsFixed(1)}%',
							style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF129990)),
						),
						const SizedBox(height: 6),
						Text(
							label,
							style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
						),
						const SizedBox(height: 8),
						Wrap(
							alignment: WrapAlignment.center,
							spacing: 12,
							children: const [
								_Legend(color: Color(0xFF129990), label: 'Used'),
								_Legend(color: Color(0xFFE0E0E0), label: 'Available'),
							],
						)
					],
				),
			],
		);
	}
}

class _Legend extends StatelessWidget {
	const _Legend({required this.color, required this.label});
	final Color color;
	final String label;
	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(8),
				border: Border.all(color: const Color(0x1F129990)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20))),
					const SizedBox(width: 6),
					Text(label, style: TextStyle(color: Colors.grey.shade700)),
				],
			),
		);
	}
}

class _ErrorTile extends StatelessWidget {
	const _ErrorTile({required this.message});
	final String message;
	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: const Color(0xFFFFEBEE),
				border: Border.all(color: const Color(0xFFFFCDD2)),
				borderRadius: BorderRadius.circular(12),
			),
			child: Text(message, style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w600)),
		);
	}
}

class _LoadingTile extends StatelessWidget {
	const _LoadingTile({required this.message});
	final String message;
	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				const SizedBox(height: 12),
				const SizedBox(
					height: 48,
					width: 48,
					child: CircularProgressIndicator(strokeWidth: 4),
				),
				const SizedBox(height: 12),
				Text(message, style: TextStyle(color: Colors.grey.shade600)),
			],
		);
	}
}
