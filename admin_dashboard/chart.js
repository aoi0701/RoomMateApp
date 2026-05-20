// chart.js — Vẽ tất cả biểu đồ cho Dashboard
// Được gọi sau khi app.js load xong data (window.allUsers, window.allPosts, window.allRequests)

const COLORS = {
  blue:   '#2F6BFF',
  green:  '#22C55E',
  orange: '#F59E0B',
  red:    '#EF4444',
  teal:   '#14B8A6',
  purple: '#8B5CF6',
  pink:   '#EC4899',
};

const CHART_DEFAULTS = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      labels: { font: { family: "'Segoe UI', system-ui, sans-serif", size: 12 }, color: '#8A94A6' },
    },
    tooltip: {
      backgroundColor: '#111827',
      titleFont: { size: 13, weight: 'bold' },
      bodyFont: { size: 12 },
      padding: 10,
      cornerRadius: 8,
    },
  },
};

let charts = {};

// Hàm public — gọi từ app.js sau khi fetch xong data
window.renderCharts = function(users, posts, requests) {
  destroyAll();
  renderUsersByMonth(users);
  renderRequestStatus(requests);
  renderPostsByProvince(posts);
  renderPostsByType(posts);
  renderAvgPrice(posts);
};

function destroyAll() {
  Object.values(charts).forEach(c => c?.destroy());
  charts = {};
}

// ===== 1. Người dùng đăng ký theo tháng (Line) =====
function renderUsersByMonth(users) {
  const months = Array.from({ length: 12 }, (_, i) =>
    new Date(0, i).toLocaleString('vi-VN', { month: 'short' })
  );
  const counts = Array(12).fill(0);
  const currentYear = new Date().getFullYear();

  users.forEach(u => {
    const d = toDate(u.createdAt);
    if (d && d.getFullYear() === currentYear) {
      counts[d.getMonth()]++;
    }
  });

  const ctx = document.getElementById('chartUsersByMonth');
  if (!ctx) return;

  charts.usersByMonth = new Chart(ctx, {
    type: 'line',
    data: {
      labels: months,
      datasets: [{
        label: 'Người dùng mới',
        data: counts,
        borderColor: COLORS.blue,
        backgroundColor: 'rgba(47,107,255,0.08)',
        fill: true,
        tension: 0.4,
        pointBackgroundColor: COLORS.blue,
        pointRadius: 4,
        pointHoverRadius: 6,
        borderWidth: 2.5,
      }],
    },
    options: {
      ...CHART_DEFAULTS,
      scales: {
        x: { grid: { display: false }, ticks: { color: '#8A94A6', font: { size: 11 } } },
        y: { beginAtZero: true, ticks: { color: '#8A94A6', font: { size: 11 }, stepSize: 1 }, grid: { color: '#F0F2F5' } },
      },
    },
  });
}

// ===== 2. Tỷ lệ yêu cầu ghép phòng (Donut) =====
function renderRequestStatus(requests) {
  const pending  = requests.filter(r => r.status === 'pending').length;
  const accepted = requests.filter(r => r.status === 'accepted').length;
  const rejected = requests.filter(r => r.status === 'rejected').length;

  const ctx = document.getElementById('chartRequestStatus');
  if (!ctx) return;

  charts.requestStatus = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: ['Đang chờ', 'Chấp nhận', 'Từ chối'],
      datasets: [{
        data: [pending, accepted, rejected],
        backgroundColor: [COLORS.orange, COLORS.green, COLORS.red],
        borderWidth: 0,
        hoverOffset: 8,
      }],
    },
    options: {
      ...CHART_DEFAULTS,
      cutout: '65%',
      plugins: {
        ...CHART_DEFAULTS.plugins,
        legend: { position: 'bottom', labels: { padding: 16, font: { size: 12 }, color: '#8A94A6' } },
      },
    },
  });
}

// ===== 3. Bài đăng theo tỉnh/thành (Bar ngang) =====
function renderPostsByProvince(posts) {
  const map = {};
  posts.forEach(p => {
    const key = p.province || 'Khác';
    map[key] = (map[key] || 0) + 1;
  });

  const sorted = Object.entries(map).sort((a, b) => b[1] - a[1]).slice(0, 8);
  const labels = sorted.map(x => x[0]);
  const data   = sorted.map(x => x[1]);

  const ctx = document.getElementById('chartPostsByProvince');
  if (!ctx) return;

  charts.postsByProvince = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Số bài đăng',
        data,
        backgroundColor: 'rgba(47,107,255,0.15)',
        borderColor: COLORS.blue,
        borderWidth: 2,
        borderRadius: 6,
      }],
    },
    options: {
      ...CHART_DEFAULTS,
      indexAxis: 'y',
      scales: {
        x: { beginAtZero: true, ticks: { color: '#8A94A6', font: { size: 11 }, stepSize: 1 }, grid: { color: '#F0F2F5' } },
        y: { grid: { display: false }, ticks: { color: '#111827', font: { size: 12 } } },
      },
      plugins: { ...CHART_DEFAULTS.plugins, legend: { display: false } },
    },
  });
}

// ===== 4. Bài đăng theo loại phòng (Pie) =====
function renderPostsByType(posts) {
  const map = {};
  posts.forEach(p => {
    const key = p.roomType || 'Khác';
    map[key] = (map[key] || 0) + 1;
  });

  const labels = Object.keys(map);
  const data   = Object.values(map);
  const bgColors = [COLORS.blue, COLORS.teal, COLORS.purple, COLORS.pink, COLORS.orange];

  const ctx = document.getElementById('chartPostsByType');
  if (!ctx) return;

  charts.postsByType = new Chart(ctx, {
    type: 'pie',
    data: {
      labels,
      datasets: [{
        data,
        backgroundColor: bgColors.slice(0, labels.length),
        borderWidth: 0,
        hoverOffset: 8,
      }],
    },
    options: {
      ...CHART_DEFAULTS,
      plugins: {
        ...CHART_DEFAULTS.plugins,
        legend: { position: 'bottom', labels: { padding: 14, font: { size: 12 }, color: '#8A94A6' } },
      },
    },
  });
}

// ===== 5. Giá trung bình theo tỉnh/thành (Bar) =====
function renderAvgPrice(posts) {
  const map = {};
  posts.forEach(p => {
    const key   = p.province || 'Khác';
    const price = typeof p.price === 'number' ? p.price : Number(p.price) || 0;
    if (!map[key]) map[key] = { total: 0, count: 0 };
    map[key].total += price;
    map[key].count++;
  });

  const sorted = Object.entries(map)
    .map(([k, v]) => ({ label: k, avg: v.total / v.count / 1_000_000 }))
    .sort((a, b) => b.avg - a.avg)
    .slice(0, 8);

  const labels = sorted.map(x => x.label);
  const data   = sorted.map(x => parseFloat(x.avg.toFixed(2)));

  const ctx = document.getElementById('chartAvgPrice');
  if (!ctx) return;

  charts.avgPrice = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Giá TB (triệu/tháng)',
        data,
        backgroundColor: [
          COLORS.blue, COLORS.teal, COLORS.purple, COLORS.pink,
          COLORS.orange, COLORS.green, COLORS.red, COLORS.blue,
        ].slice(0, labels.length).map(c => c + '99'),
        borderColor: [
          COLORS.blue, COLORS.teal, COLORS.purple, COLORS.pink,
          COLORS.orange, COLORS.green, COLORS.red, COLORS.blue,
        ].slice(0, labels.length),
        borderWidth: 2,
        borderRadius: 8,
      }],
    },
    options: {
      ...CHART_DEFAULTS,
      scales: {
        x: { grid: { display: false }, ticks: { color: '#111827', font: { size: 12 } } },
        y: {
          beginAtZero: true,
          ticks: {
            color: '#8A94A6',
            font: { size: 11 },
            callback: v => v + ' tr',
          },
          grid: { color: '#F0F2F5' },
        },
      },
      plugins: { ...CHART_DEFAULTS.plugins, legend: { display: false } },
    },
  });
}

// ===== HELPER =====
function toDate(val) {
  if (!val) return null;
  if (val?.toDate) return val.toDate();       // Firestore Timestamp
  if (val instanceof Date) return val;
  const d = new Date(val);
  return isNaN(d) ? null : d;
}
