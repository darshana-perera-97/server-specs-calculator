# Server Specs Calculator - Analytics Dashboard

A beautiful, responsive web dashboard for monitoring server performance metrics in real-time.

## 🚀 Features

- **Real-time Metrics**: Live server performance data
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Auto-refresh**: Updates every 30 seconds automatically
- **Interactive Cards**: Hover effects and smooth animations
- **Progress Bars**: Visual representation of usage percentages
- **Network Monitoring**: Detailed network interface information

## 📊 Dashboard Sections

1. **System Performance**: CPU cores, load average, system & process CPU usage
2. **Memory Usage**: Total, used, free memory with usage percentage
3. **Disk Storage**: Disk space information with usage visualization
4. **Uptime & Process**: System and process uptime, Node.js version, PID
5. **Process Memory**: RSS, heap usage, external memory details
6. **Network & Bandwidth**: Network interfaces, RX/TX data, error counts

## 🛠️ Setup Instructions

### Prerequisites
- Backend API server running on port 3100
- Modern web browser with JavaScript enabled

### Quick Start
1. **Start the Backend Server:**
   ```bash
   cd backend
   npm install
   npm start
   ```

2. **Open the Dashboard:**
   - Navigate to the `web` folder
   - Open `index.html` in your web browser
   - Or serve it using a local web server

3. **Access the API:**
   - Backend: `http://localhost:3100`
   - Dashboard: Open `web/index.html`

## 🌐 API Endpoints

The dashboard connects to these backend endpoints:
- `GET /api/metrics` - All metrics
- `GET /api/metrics/system` - System performance only
- `GET /api/metrics/uptime` - Uptime and process metrics
- `GET /api/metrics/network` - Network and bandwidth metrics

## 🎨 Customization

### Colors and Themes
- Modify CSS variables in the `<style>` section
- Change gradient backgrounds and card colors
- Adjust progress bar colors and animations

### Layout
- Modify grid layouts in `.dashboard` and `.metric-grid`
- Adjust card sizes and spacing
- Change responsive breakpoints

### Auto-refresh Interval
- Modify the refresh interval in the JavaScript (currently 30 seconds)
- Change `setInterval(loadData, 30000)` to your preferred interval

## 📱 Responsive Design

The dashboard automatically adapts to different screen sizes:
- **Desktop**: Multi-column grid layout
- **Tablet**: Adjusted spacing and sizing
- **Mobile**: Single-column layout with optimized touch targets

## 🔧 Troubleshooting

### Common Issues

1. **"Error loading data" message:**
   - Ensure backend server is running on port 3100
   - Check if CORS is properly configured
   - Verify network connectivity

2. **Dashboard not loading:**
   - Check browser console for JavaScript errors
   - Ensure all dependencies are loaded
   - Verify API endpoint accessibility

3. **Metrics not updating:**
   - Check if auto-refresh is enabled
   - Verify backend is returning valid data
   - Check browser console for errors

### Browser Compatibility
- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## 📈 Future Enhancements

- Real-time charts and graphs
- Historical data tracking
- Alert notifications
- Export functionality
- Dark/light theme toggle
- Custom metric thresholds

## 🤝 Contributing

Feel free to enhance the dashboard with:
- Additional metrics
- Improved visualizations
- Better error handling
- Performance optimizations

---

**Note**: Make sure your backend server is running before opening the dashboard. The dashboard will automatically attempt to connect to `http://localhost:3100`.
