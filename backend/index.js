import os from 'os';
import checkDiskSpace from 'check-disk-space';

// Helper function to convert bytes to MB with 2 decimal places
function bytesToMB(bytes) {
  return (bytes / (1024 * 1024)).toFixed(2);
}

// Helper to get system CPU usage %
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

    const totalDiskMB = diskSpace.size / (1024 * 1024);
    const freeDiskMB = diskSpace.free / (1024 * 1024);
    const usedDiskMB = totalDiskMB - freeDiskMB;
    const diskUsagePercent = (usedDiskMB / totalDiskMB) * 100;

    // Fetch CPU usages in parallel
    const [systemCpuUsage, processCpuUsage] = await Promise.all([
      getSystemCpuUsage(),
      getProcessCpuUsage(),
    ]);

    return {
      cpuCount: cpus.length,
      loadAverage: loadAverage.toFixed(2),
      totalMemMB: totalMemMB.toFixed(2) + ' MB',
      freeMemMB: freeMemMB.toFixed(2) + ' MB',
      usedMemMB: usedMemMB.toFixed(2) + ' MB',
      memUsagePercent: memUsagePercent.toFixed(2) + '%',
      totalDiskMB: totalDiskMB.toFixed(2) + ' MB',
      freeDiskMB: freeDiskMB.toFixed(2) + ' MB',
      usedDiskMB: usedDiskMB.toFixed(2) + ' MB',
      diskUsagePercent: diskUsagePercent.toFixed(2) + '%',
      systemCpuUsage: systemCpuUsage + ' %',
      processCpuUsage: processCpuUsage + ' %',
    };

  } catch (err) {
    console.error('Failed to get disk usage:', err);
    return null;
  }
}

// Run and print the info
getServerPerformanceAndStorage().then(stats => {
  if (stats) {
    console.log('=== Server Performance & Usage ===');
    console.log(`CPU Count: ${stats.cpuCount}`);
    console.log(`Load Average (1 min): ${stats.loadAverage}`);
    console.log(`Memory - Total: ${stats.totalMemMB}, Free: ${stats.freeMemMB}, Used: ${stats.usedMemMB}, Usage: ${stats.memUsagePercent}`);
    console.log(`Disk Storage (${process.platform === 'win32' ? 'C:' : '/'}): Total: ${stats.totalDiskMB}, Free: ${stats.freeDiskMB}, Used: ${stats.usedDiskMB}, Usage: ${stats.diskUsagePercent}`);
    console.log(`System CPU Usage (all cores): ${stats.systemCpuUsage}`);
    console.log(`Process CPU Usage (Node.js process): ${stats.processCpuUsage}`);
  }
});
