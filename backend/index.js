import os from 'os';
import checkDiskSpace from 'check-disk-space';
import si from 'systeminformation';
import express from 'express';
import cors from 'cors';

const app = express();
const PORT = 3100;

// Middleware
app.use(cors());
app.use(express.json());

// Helper function to convert bytes to MB with 2 decimal places
function bytesToMB(bytes) {
  return (bytes / (1024 * 1024)).toFixed(2);
}

// Helper function to convert bytes to appropriate unit
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Helper to get system CPU usage % over an interval
function getSystemCpuUsage() {
  return new Promise((resolve) => {
    const cpus1 = os.cpus();

    setTimeout(() => {
      const cpus2 = os.cpus();

      let idleDiff = 0;
      let totalDiff = 0;

      for (let i = 0; i < cpus1.length; i++) {
        const cpu1 = cpus1[i].times;
        const cpu2 = cpus2[i].times;

        const idle = cpu2.idle - cpu1.idle;
        const total = 
          (cpu2.user - cpu1.user) +
          (cpu2.nice - cpu1.nice) +
          (cpu2.sys - cpu1.sys) +
          (cpu2.irq - cpu1.irq) +
          idle;

        idleDiff += idle;
        totalDiff += total;
      }

      const usagePercent = 100 - (idleDiff / totalDiff) * 100;
      resolve(usagePercent.toFixed(2));
    }, 1000); // sample interval 1 second
  });
}

// Helper to get Node.js process CPU usage % over an interval
function getProcessCpuUsage() {
  return new Promise((resolve) => {
    const startUsage = process.cpuUsage();
    const startTime = process.hrtime();

    setTimeout(() => {
      const elapUsage = process.cpuUsage(startUsage);
      const elapTime = process.hrtime(startTime);

      const elapTimeMS = (elapTime[0] * 1000) + (elapTime[1] / 1e6);

      // elapUsage.user + elapUsage.system are in microseconds
      const cpuPercent = ((elapUsage.user + elapUsage.system) / 1000) / elapTimeMS * 100;

      resolve(cpuPercent.toFixed(2));
    }, 1000);
  });
}

// Helper to get process memory usage
function getProcessMemoryUsage() {
  const memUsage = process.memoryUsage();
  return {
    rss: formatBytes(memUsage.rss), // Resident Set Size
    heapTotal: formatBytes(memUsage.heapTotal), // V8 heap total
    heapUsed: formatBytes(memUsage.heapUsed), // V8 heap used
    external: formatBytes(memUsage.external), // External memory
    arrayBuffers: formatBytes(memUsage.arrayBuffers) // ArrayBuffers and SharedArrayBuffers
  };
}

// Helper to get uptime information
function getUptimeInfo() {
  const systemUptime = os.uptime();
  const processUptime = process.uptime();
  
  const formatUptime = (seconds) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (days > 0) return `${days}d ${hours}h ${minutes}m ${secs}s`;
    if (hours > 0) return `${hours}h ${minutes}m ${secs}s`;
    if (minutes > 0) return `${minutes}m ${secs}s`;
    return `${secs}s`;
  };

  return {
    systemUptime: formatUptime(systemUptime),
    processUptime: formatUptime(processUptime),
    systemUptimeSeconds: Math.floor(systemUptime),
    processUptimeSeconds: Math.floor(processUptime)
  };
}

// Helper to get network interface information
async function getNetworkInfo() {
  try {
    const networkInterfaces = os.networkInterfaces();
    const networkStats = await si.networkStats();
    
    const interfaces = [];
    
    for (const [name, nets] of Object.entries(networkInterfaces)) {
      for (const net of nets) {
        if (net.family === 'IPv4' && !net.internal) {
          const stats = networkStats.find(stat => stat.iface === name);
          
          interfaces.push({
            name: name,
            address: net.address,
            netmask: net.netmask,
            mac: net.mac,
            type: net.type,
            speed: stats ? `${stats.speed} Mbps` : 'Unknown',
            rx_bytes: stats ? formatBytes(stats.rx_bytes) : 'Unknown',
            tx_bytes: stats ? formatBytes(stats.tx_bytes) : 'Unknown',
            rx_dropped: stats ? stats.rx_dropped : 'Unknown',
            tx_dropped: stats ? stats.tx_dropped : 'Unknown',
            rx_errors: stats ? stats.rx_errors : 'Unknown',
            tx_errors: stats ? stats.tx_errors : 'Unknown'
          });
        }
      }
    }
    
    return interfaces;
  } catch (error) {
    console.error('Error getting network info:', error);
    return [];
  }
}

// Helper to get bandwidth usage over time
async function getBandwidthUsage() {
  try {
    const networkStats = await si.networkStats();
    const totalRx = networkStats.reduce((sum, stat) => sum + stat.rx_bytes, 0);
    const totalTx = networkStats.reduce((sum, stat) => sum + stat.tx_bytes, 0);
    
    return {
      totalRx: formatBytes(totalRx),
      totalTx: formatBytes(totalTx),
      totalRxMB: (totalRx / (1024 * 1024)).toFixed(2),
      totalTxMB: (totalTx / (1024 * 1024)).toFixed(2)
    };
  } catch (error) {
    console.error('Error getting bandwidth usage:', error);
    return { totalRx: 'Unknown', totalTx: 'Unknown', totalRxMB: '0', totalTxMB: '0' };
  }
}

async function getServerPerformanceAndStorage() {
  const cpus = os.cpus();

  // CPU load average (1 minute)
  const loadAverage = os.loadavg()[0];

  // Memory in MB
  const totalMemMB = os.totalmem() / (1024 * 1024);
  const freeMemMB = os.freemem() / (1024 * 1024);
  const usedMemMB = totalMemMB - freeMemMB;
  const memUsagePercent = (usedMemMB / totalMemMB) * 100;

  // Determine disk path based on platform
  const diskPath = process.platform === 'win32' ? 'C:' : '/';

  try {
    // Get disk space info
    const diskSpace = await checkDiskSpace(diskPath);

    const totalDiskGB = diskSpace.size / (1024 * 1024 * 1024);
    const freeDiskGB = diskSpace.free / (1024 * 1024 * 1024);
    const usedDiskGB = totalDiskGB - freeDiskGB;
    const diskUsagePercent = (usedDiskGB / totalDiskGB) * 100;

    // Fetch all metrics in parallel
    const [systemCpuUsage, processCpuUsage, networkInfo, bandwidthUsage] = await Promise.all([
      getSystemCpuUsage(),
      getProcessCpuUsage(),
      getNetworkInfo(),
      getBandwidthUsage(),
    ]);

    // Get uptime and process memory info
    const uptimeInfo = getUptimeInfo();
    const processMemory = getProcessMemoryUsage();

    return {
      // System Information
      cpuCount: cpus.length,
      loadAverage: loadAverage.toFixed(2),
      totalMemMB: totalMemMB.toFixed(2) + ' MB',
      freeMemMB: freeMemMB.toFixed(2) + ' MB',
      usedMemMB: usedMemMB.toFixed(2) + ' MB',
      memUsagePercent: memUsagePercent.toFixed(2) + '%',
      totalDiskGB: totalDiskGB.toFixed(2) + ' GB',
      freeDiskGB: freeDiskGB.toFixed(2) + ' GB',
      usedDiskGB: usedDiskGB.toFixed(2) + ' GB',
      diskUsagePercent: diskUsagePercent.toFixed(2) + '%',
      systemCpuUsage: systemCpuUsage + ' %',
      processCpuUsage: processCpuUsage + ' %',
      
      // Uptime Information
      systemUptime: uptimeInfo.systemUptime,
      processUptime: uptimeInfo.processUptime,
      systemUptimeSeconds: uptimeInfo.systemUptimeSeconds,
      processUptimeSeconds: uptimeInfo.processUptimeSeconds,
      
      // Process Metrics
      processMemory: processMemory,
      nodeVersion: process.version,
      platform: process.platform,
      arch: process.arch,
      pid: process.pid,
      
      // Network and Bandwidth Metrics
      networkInterfaces: networkInfo,
      bandwidthUsage: bandwidthUsage
    };

  } catch (err) {
    console.error('Failed to get server metrics:', err);
    return null;
  }
}

// API Routes

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Get all metrics
app.get('/api/metrics', async (req, res) => {
  try {
    const metrics = await getServerPerformanceAndStorage();
    if (metrics) {
      res.json({
        success: true,
        timestamp: new Date().toISOString(),
        data: metrics
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to retrieve metrics'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get system metrics only
app.get('/api/metrics/system', async (req, res) => {
  try {
    const metrics = await getServerPerformanceAndStorage();
    if (metrics) {
      const systemMetrics = {
        cpuCount: metrics.cpuCount,
        loadAverage: metrics.loadAverage,
        totalMemMB: metrics.totalMemMB,
        freeMemMB: metrics.freeMemMB,
        usedMemMB: metrics.usedMemMB,
        memUsagePercent: metrics.memUsagePercent,
        totalDiskGB: metrics.totalDiskGB,
        freeDiskGB: metrics.freeDiskGB,
        usedDiskGB: metrics.usedDiskGB,
        diskUsagePercent: metrics.diskUsagePercent,
        systemCpuUsage: metrics.systemCpuUsage,
        processCpuUsage: metrics.processCpuUsage
      };
      
      res.json({
        success: true,
        timestamp: new Date().toISOString(),
        data: systemMetrics
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to retrieve system metrics'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get uptime and process metrics only
app.get('/api/metrics/uptime', async (req, res) => {
  try {
    const metrics = await getServerPerformanceAndStorage();
    if (metrics) {
      const uptimeMetrics = {
        systemUptime: metrics.systemUptime,
        processUptime: metrics.processUptime,
        systemUptimeSeconds: metrics.systemUptimeSeconds,
        processUptimeSeconds: metrics.processUptimeSeconds,
        processMemory: metrics.processMemory,
        nodeVersion: metrics.nodeVersion,
        platform: metrics.platform,
        arch: metrics.arch,
        pid: metrics.pid
      };
      
      res.json({
        success: true,
        timestamp: new Date().toISOString(),
        data: uptimeMetrics
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to retrieve uptime metrics'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get network and bandwidth metrics only
app.get('/api/metrics/network', async (req, res) => {
  try {
    const metrics = await getServerPerformanceAndStorage();
    if (metrics) {
      const networkMetrics = {
        networkInterfaces: metrics.networkInterfaces,
        bandwidthUsage: metrics.bandwidthUsage
      };
      
      res.json({
        success: true,
        timestamp: new Date().toISOString(),
        data: networkMetrics
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to retrieve network metrics'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Root endpoint with API information
app.get('/', (req, res) => {
  res.json({
    message: 'Server Specs Calculator API',
    version: '1.0.0',
    endpoints: {
      'GET /health': 'Health check endpoint',
      'GET /api/metrics': 'Get all metrics',
      'GET /api/metrics/system': 'Get system performance metrics only',
      'GET /api/metrics/uptime': 'Get uptime and process metrics only',
      'GET /api/metrics/network': 'Get network and bandwidth metrics only'
    },
    timestamp: new Date().toISOString()
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`🚀 Server Specs Calculator API running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`📈 All metrics: http://localhost:${PORT}/api/metrics`);
  console.log(`💻 System metrics: http://localhost:${PORT}/api/metrics/system`);
  console.log(`⏱️  Uptime metrics: http://localhost:${PORT}/api/metrics/uptime`);
  console.log(`🌐 Network metrics: http://localhost:${PORT}/api/metrics/network`);
});
