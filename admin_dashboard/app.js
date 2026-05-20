import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
import {
  getAuth, signInWithEmailAndPassword, signOut, onAuthStateChanged
} from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
import {
  getFirestore, collection, getDocs, deleteDoc, doc, query, orderBy, getDoc
} from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';

// ===== FIREBASE CONFIG =====
const firebaseConfig = {
  apiKey: 'AIzaSyDB6JgulOU15cKe7V-oNcboWScX6_DbuZY',
  authDomain: 'roommateapp-fbb4f.firebaseapp.com',
  projectId: 'roommateapp-fbb4f',
  storageBucket: 'roommateapp-fbb4f.firebasestorage.app',
  messagingSenderId: '787375402089',
  appId: '1:787375402089:web:bb98d7aa19147eb09586f8',
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

// ===== STATE =====
let allUsers = [];
let allPosts = [];
let allRequests = [];
let allGroups = [];
let allReports = [];

// ===== INIT =====
document.addEventListener('DOMContentLoaded', () => {
  updateHeaderDate();
  onAuthStateChanged(auth, async (user) => {
    if (!user) {
      showLoginPage();
      return;
    }
    // Kiểm tra role admin
    const userDoc = await getDoc(doc(db, 'users', user.uid));
    const role = userDoc.data()?.role;
    if (role !== 'admin') {
      await signOut(auth);
      showError('Tài khoản không có quyền admin.');
      return;
    }
    document.getElementById('adminName').textContent = user.displayName || user.email.split('@')[0];
    showDashboardPage();
    await loadAllData();
  });
});

function updateHeaderDate() {
  const el = document.getElementById('headerDate');
  if (!el) return;
  const now = new Date();
  el.textContent = now.toLocaleDateString('vi-VN', { weekday: 'long', day: '2-digit', month: '2-digit', year: 'numeric' });
}

// ===== AUTH =====
window.handleLogin = async function(e) {
  e.preventDefault();
  const email = document.getElementById('loginEmail').value.trim();
  const password = document.getElementById('loginPassword').value;
  const errorEl = document.getElementById('loginError');
  const btnText = document.getElementById('loginBtnText');
  const spinner = document.getElementById('loginSpinner');

  errorEl.style.display = 'none';
  btnText.style.display = 'none';
  spinner.style.display = 'inline-block';

  try {
    await signInWithEmailAndPassword(auth, email, password);
    // onAuthStateChanged sẽ xử lý tiếp
  } catch (err) {
    btnText.style.display = 'inline';
    spinner.style.display = 'none';
    showError(parseAuthError(err.code));
  }
};

window.handleLogout = async function() {
  await signOut(auth);
  showLoginPage();
};

function parseAuthError(code) {
  const map = {
    'auth/user-not-found': 'Email không tồn tại.',
    'auth/wrong-password': 'Mật khẩu không đúng.',
    'auth/invalid-email': 'Email không hợp lệ.',
    'auth/too-many-requests': 'Quá nhiều lần thử. Vui lòng thử lại sau.',
    'auth/invalid-credential': 'Email hoặc mật khẩu không đúng.',
  };
  return map[code] || 'Đăng nhập thất bại. Vui lòng thử lại.';
}

function showError(msg) {
  const el = document.getElementById('loginError');
  el.textContent = msg;
  el.style.display = 'block';
}

function showLoginPage() {
  document.getElementById('loginPage').style.display = 'flex';
  document.getElementById('dashboardPage').style.display = 'none';
  document.getElementById('loginBtnText').style.display = 'inline';
  document.getElementById('loginSpinner').style.display = 'none';
}

function showDashboardPage() {
  document.getElementById('loginPage').style.display = 'none';
  document.getElementById('dashboardPage').style.display = 'flex';
}

// ===== LOAD ALL DATA =====
async function loadAllData() {
  showToast('Đang tải dữ liệu...');
  await Promise.all([fetchUsers(), fetchPosts(), fetchRequests(), fetchGroups(), fetchReports()]);
  loadDashboard();
  loadUsers();
  loadPosts();
  loadRequests();
  updateBadges();
  buildProvinceFilter();
  if (typeof window.renderCharts === 'function') {
    window.renderCharts(allUsers, allPosts, allRequests);
  }
  showToast('Tải dữ liệu thành công ✓');
}

async function fetchUsers() {
  try {
    const snap = await getDocs(query(collection(db, 'users'), orderBy('createdAt', 'desc')));
    allUsers = snap.docs.map(d => ({ uid: d.id, ...d.data() }));
  } catch (e) {
    console.error('fetchUsers:', e);
  }
}

async function fetchPosts() {
  try {
    const snap = await getDocs(query(collection(db, 'posts'), orderBy('createdAt', 'desc')));
    allPosts = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  } catch (e) {
    console.error('fetchPosts:', e);
  }
}

async function fetchRequests() {
  try {
    const snap = await getDocs(query(collection(db, 'roommate_requests'), orderBy('createdAt', 'desc')));
    allRequests = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  } catch (e) {
    console.error('fetchRequests:', e);
  }
}

async function fetchGroups() {
  try {
    const snap = await getDocs(query(collection(db, 'groups'), orderBy('createdAt', 'desc')));
    allGroups = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  } catch (e) {
    console.error('fetchGroups:', e);
  }
}

async function fetchReports() {
  try {
    const snap = await getDocs(query(collection(db, 'reports'), orderBy('createdAt', 'desc')));
    allReports = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  } catch (e) {
    console.error('fetchReports:', e);
  }
}

// ===== NAVIGATION =====
window.showSection = function(name, el) {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const sec = document.getElementById('section-' + name);
  if (sec) sec.classList.add('active');
  if (el) el.classList.add('active');
  const titles = {
    dashboard:  'Dashboard',
    users:      'Quản lý người dùng',
    violations: 'Quản lý vi phạm',
    reports:    'Quản lý báo cáo',
    posts:      'Quản lý bài đăng',
    groups:     'Quản lý nhóm phòng',
    requests:   'Quản lý yêu cầu ghép phòng',
    expenses:   'Quản lý khoản chi',
    invoices:   'Hóa đơn',
    payments:   'Thanh toán',
    disputes:   'Tranh chấp chi phí',
    media:      'Quản lý Media',
    config:     'Cấu hình hệ thống',
    logs:       'Nhật ký hoạt động',
  };
  document.getElementById('headerTitle').textContent = titles[name] || name;
};

// ===== PLACEHOLDER FILTERS =====
window.filterGroups    = function() {};

window.viewGroup = function(id) {
  showSection('groups', document.querySelector('.nav-item[onclick*="groups"]'));
  closeModal();
  showToast('Đã chuyển đến nhóm phòng');
};
window.filterMedia     = function() {};
window.filterViolations = function() {};
window.filterReports   = function() {};
window.filterExpenses  = function() {};
window.filterDisputes  = function() {};

// ===== DASHBOARD =====
function loadDashboard() {
  const pending  = allRequests.filter(r => r.status === 'pending').length;
  const accepted = allRequests.filter(r => r.status === 'accepted').length;
  const total    = allRequests.length;
  const matchRate = total > 0 ? Math.round((accepted / total) * 100) : 0;
  const reportsPending = allReports.filter(r => r.status === 'pending' || !r.status).length;

  document.getElementById('statUsers').textContent         = allUsers.length;
  document.getElementById('statPosts').textContent         = allPosts.length;
  document.getElementById('statGroups').textContent        = allGroups.length;
  document.getElementById('statPending').textContent       = pending;
  document.getElementById('statReportsPending').textContent = reportsPending;
  document.getElementById('statMatchRate').textContent     = matchRate + '%';

  document.getElementById('recentPosts').innerHTML = allPosts.slice(0, 5).map(p => `
    <tr>
      <td><strong>${p.title || '—'}</strong></td>
      <td>${p.district || ''}, ${p.province || ''}</td>
      <td>${formatPrice(p.price)}</td>
      <td>${formatDate(p.createdAt)}</td>
    </tr>`).join('') || '<tr><td colspan="4" class="empty-row">Chưa có dữ liệu</td></tr>';

  document.getElementById('recentRequests').innerHTML = allRequests.slice(0, 5).map(r => `
    <tr>
      <td>${r.requesterName || '—'}</td>
      <td>${truncate(r.message, 30)}</td>
      <td>${statusBadge(r.status)}</td>
      <td>${formatDate(r.createdAt)}</td>
    </tr>`).join('') || '<tr><td colspan="4" class="empty-row">Chưa có dữ liệu</td></tr>';
}

// ===== USERS =====
function loadUsers(data = allUsers) {
  const tbody = document.getElementById('usersTable');
  if (!data.length) {
    tbody.innerHTML = '<tr><td colspan="8" class="empty-row">Không có người dùng nào</td></tr>';
    return;
  }
  tbody.innerHTML = data.map(u => {
    const postCount    = allPosts.filter(p => p.userId === u.uid).length;
    const reportCount  = allReports.filter(r => r.targetId === u.uid).length;
    const isBlocked    = u.isBlocked === true;
    const isAdmin      = u.role === 'admin';

    const roleBadge    = isAdmin
      ? `<span class="badge badge-purple">Admin</span>`
      : `<span class="badge badge-gray">User</span>`;

    const statusBadgeEl = isBlocked
      ? `<span class="badge badge-red">Đã khóa</span>`
      : `<span class="badge badge-green">Hoạt động</span>`;

    const toggleBtn = isBlocked
      ? `<button class="btn-action btn-success" onclick="toggleBlockUser('${u.uid}', false, '${u.fullName}')"><i class="fa-solid fa-lock-open"></i> Mở khóa</button>`
      : `<button class="btn-action btn-warning" onclick="toggleBlockUser('${u.uid}', true, '${u.fullName}')"><i class="fa-solid fa-lock"></i> Khóa</button>`;

    return `<tr class="${isBlocked ? 'row-blocked' : ''}">
      <td>
        <div class="user-cell">
          <div class="avatar">${avatarEl(u.avatarUrl, u.fullName)}</div>
          <div>
            <div class="user-name">${u.fullName || '—'}</div>
            <div class="user-sub">${u.email || ''}</div>
          </div>
        </div>
      </td>
      <td>${u.email || '—'}</td>
      <td>${roleBadge}</td>
      <td>${statusBadgeEl}</td>
      <td><span class="count-badge">${postCount}</span></td>
      <td><span class="count-badge ${reportCount > 0 ? 'count-badge-red' : ''}">${reportCount}</span></td>
      <td>${formatDate(u.createdAt)}</td>
      <td class="action-cell">
        <button class="btn-action btn-view" onclick="viewUser('${u.uid}')"><i class="fa-solid fa-eye"></i> Chi tiết</button>
        ${toggleBtn}
        <button class="btn-action btn-delete" onclick="softDeleteUser('${u.uid}','${u.fullName}')"><i class="fa-solid fa-ban"></i></button>
      </td>
    </tr>`;
  }).join('');
}

window.filterUsers = function() {
  const q      = document.getElementById('searchUsers').value.toLowerCase();
  const role   = document.getElementById('filterUserRole').value;
  const status = document.getElementById('filterUserStatus').value;
  loadUsers(allUsers.filter(u => {
    const matchQ      = (u.fullName || '').toLowerCase().includes(q) || (u.email || '').toLowerCase().includes(q);
    const matchRole   = !role   || (u.role || 'user') === role;
    const matchStatus = !status || (status === 'blocked' ? u.isBlocked === true : u.isBlocked !== true);
    return matchQ && matchRole && matchStatus;
  }));
};

window.toggleBlockUser = async function(uid, block, name) {
  const action = block ? 'khóa' : 'mở khóa';
  if (!confirm(`Bạn có chắc muốn ${action} tài khoản "${name}"?`)) return;
  try {
    const { updateDoc, doc: fsDoc } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');
    await updateDoc(fsDoc(db, 'users', uid), { isBlocked: block });
    const u = allUsers.find(x => x.uid === uid);
    if (u) u.isBlocked = block;
    loadUsers();
    showToast(`Đã ${action} tài khoản "${name}" ✓`);
  } catch (e) {
    showToast('Lỗi: ' + e.message);
  }
};

window.softDeleteUser = async function(uid, name) {
  if (!confirm(`Xóa mềm tài khoản "${name}"? Tài khoản sẽ bị ẩn khỏi hệ thống.`)) return;
  try {
    const { updateDoc, doc: fsDoc } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');
    await updateDoc(fsDoc(db, 'users', uid), { isDeleted: true, isBlocked: true });
    allUsers = allUsers.filter(x => x.uid !== uid);
    loadUsers();
    showToast(`Đã xóa mềm tài khoản "${name}" ✓`);
  } catch (e) {
    showToast('Lỗi: ' + e.message);
  }
};

window.viewUser = function(uid) {
  const u = allUsers.find(x => x.uid === uid);
  if (!u) return;
  const postCount   = allPosts.filter(p => p.userId === uid).length;
  const reportCount = allReports.filter(r => r.targetId === uid).length;
  const isBlocked   = u.isBlocked === true;
  document.getElementById('modalContent').innerHTML = `
    <div style="text-align:center;margin-bottom:16px;">
      <div class="avatar" style="width:72px;height:72px;font-size:28px;margin:0 auto 12px;">${avatarEl(u.avatarUrl, u.fullName)}</div>
      <div style="font-size:18px;font-weight:800;">${u.fullName || '—'}</div>
      <div style="color:var(--text-secondary);font-size:13px;">${u.email || ''}</div>
      <div style="margin-top:8px;display:flex;gap:8px;justify-content:center;">
        <span class="badge ${u.role === 'admin' ? 'badge-purple' : 'badge-gray'}">${u.role || 'user'}</span>
        <span class="badge ${isBlocked ? 'badge-red' : 'badge-green'}">${isBlocked ? 'Đã khóa' : 'Hoạt động'}</span>
      </div>
    </div>
    <div style="border-top:1px solid var(--border);padding-top:16px;">
      ${modalRow('SĐT', u.phone || '—')}
      ${modalRow('Giới tính', u.gender || '—')}
      ${modalRow('Tuổi', u.age || '—')}
      ${modalRow('Nghề nghiệp', u.occupation || '—')}
      ${modalRow('Ngân sách', u.budgetRange || '—')}
      ${modalRow('Khu vực ưa thích', u.preferredLocation || '—')}
      ${modalRow('Bio', u.bio || '—')}
      ${modalRow('Thói quen', (u.habits || []).join(', ') || '—')}
      ${modalRow('Tiêu chí', (u.roommateCriteria || []).join(', ') || '—')}
      ${modalRow('Số bài đăng', postCount)}
      ${modalRow('Số lần bị báo cáo', reportCount)}
      ${modalRow('Ngày tạo', formatDate(u.createdAt))}
    </div>`;
  openModal();
};

// ===== POSTS =====
function postStatusBadge(status, reportCount) {
  if (reportCount > 0 && status !== 'hidden') return `<span class="badge badge-red">Bị báo cáo</span>`;
  const map = {
    active:  `<span class="badge badge-green">Đang hiển thị</span>`,
    pending: `<span class="badge badge-orange">Chờ duyệt</span>`,
    hidden:  `<span class="badge badge-gray">Đã ẩn</span>`,
    sold:    `<span class="badge badge-purple">Hết phòng</span>`,
  };
  return map[status] || `<span class="badge badge-orange">Chờ duyệt</span>`;
}

function buildProvinceFilter() {
  const sel = document.getElementById('filterPostProvince');
  if (!sel || sel.options.length > 1) return;
  const provinces = [...new Set(allPosts.map(p => p.province).filter(Boolean))].sort();
  provinces.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p; opt.textContent = p;
    sel.appendChild(opt);
  });
}

function loadPosts(data = allPosts) {
  const tbody = document.getElementById('postsTable');
  if (!data.length) {
    tbody.innerHTML = '<tr><td colspan="10" class="empty-row">Không có bài đăng nào</td></tr>';
    return;
  }
  const reportedPostIds = new Set(allReports.filter(r => r.targetType === 'post').map(r => r.targetId));
  tbody.innerHTML = data.map(p => {
    const reportCount = allReports.filter(r => r.targetId === p.id).length;
    const owner = allUsers.find(u => u.uid === p.userId);
    const ownerName = owner ? owner.fullName || owner.email : '—';
    const status = p.status || 'pending';
    const isHidden = status === 'hidden';

    return `<tr class="${isHidden ? 'row-blocked' : ''}">
      <td>${postImgEl(p.imageUrl)}</td>
      <td><strong>${p.title || '—'}</strong></td>
      <td>
        <button class="btn-link" onclick="viewUser('${p.userId}')">${ownerName}</button>
      </td>
      <td>${p.district || ''}, ${p.province || ''}</td>
      <td>${p.roomType || '—'}</td>
      <td>${formatPrice(p.price)}</td>
      <td>${postStatusBadge(status, reportCount)}</td>
      <td><span class="count-badge ${reportCount > 0 ? 'count-badge-red' : ''}">${reportCount}</span></td>
      <td>${formatDate(p.createdAt)}</td>
      <td class="action-cell">
        <button class="btn-action btn-view" onclick="viewPost('${p.id}')"><i class="fa-solid fa-eye"></i> Chi tiết</button>
        ${status !== 'active'
          ? `<button class="btn-action btn-success" onclick="updatePostStatus('${p.id}','active','${(p.title||'').replace(/'/g,'')}')"><i class="fa-solid fa-check"></i> Duyệt</button>`
          : `<button class="btn-action btn-warning" onclick="updatePostStatus('${p.id}','hidden','${(p.title||'').replace(/'/g,'')}')"><i class="fa-solid fa-eye-slash"></i> Ẩn</button>`
        }
        <button class="btn-action btn-view" onclick="viewPostRequests('${p.id}','${(p.title||'').replace(/'/g,'')}')"><i class="fa-solid fa-handshake"></i> Yêu cầu</button>
      </td>
    </tr>`;
  }).join('');
}

window.filterPosts = function() {
  const q        = document.getElementById('searchPosts').value.toLowerCase();
  const type     = document.getElementById('filterRoomType').value;
  const status   = document.getElementById('filterPostStatus').value;
  const province = document.getElementById('filterPostProvince').value;
  const price    = document.getElementById('filterPriceRange').value;
  const reportedIds = new Set(allReports.filter(r => r.targetType === 'post').map(r => r.targetId));

  loadPosts(allPosts.filter(p => {
    const matchQ        = (p.title||'').toLowerCase().includes(q) || (p.province||'').toLowerCase().includes(q) || (p.district||'').toLowerCase().includes(q);
    const matchType     = !type     || p.roomType === type;
    const matchProvince = !province || p.province === province;
    const pStatus       = p.status || 'pending';
    const isReported    = reportedIds.has(p.id);
    const matchStatus   = !status   || (status === 'reported' ? isReported : pStatus === status);
    const matchPrice    = !price    || (() => {
      const [min, max] = price.split('-').map(Number);
      const pr = (p.price || 0) / 1_000_000;
      return pr >= min && pr < max;
    })();
    return matchQ && matchType && matchProvince && matchStatus && matchPrice;
  }));
};

window.updatePostStatus = async function(id, newStatus, title) {
  const label = newStatus === 'active' ? 'duyệt' : 'ẩn';
  if (!confirm(`Bạn có chắc muốn ${label} bài "${title}"?`)) return;
  try {
    const { updateDoc, doc: fsDoc } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');
    await updateDoc(fsDoc(db, 'posts', id), { status: newStatus });
    const p = allPosts.find(x => x.id === id);
    if (p) p.status = newStatus;
    loadPosts();
    showToast(`Đã ${label} bài "${title}" ✓`);
  } catch (e) {
    showToast('Lỗi: ' + e.message);
  }
};

window.viewPostRequests = function(postId, title) {
  const reqs = allRequests.filter(r => r.postId === postId);
  const rows = reqs.length
    ? reqs.map(r => `
        <tr>
          <td>${r.requesterName || r.senderId || '—'}</td>
          <td>${truncate(r.message || '', 40)}</td>
          <td>${statusBadge(r.status)}</td>
          <td>${formatDate(r.createdAt)}</td>
        </tr>`).join('')
    : '<tr><td colspan="4" class="empty-row">Chưa có yêu cầu nào</td></tr>';
  document.getElementById('modalContent').innerHTML = `
    <div class="modal-title"><i class="fa-solid fa-handshake"></i> Yêu cầu ghép phòng</div>
    <div style="color:var(--text-secondary);font-size:13px;margin-bottom:16px;">${title}</div>
    <table class="data-table">
      <thead><tr><th>Người gửi</th><th>Tin nhắn</th><th>Trạng thái</th><th>Ngày gửi</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>`;
  openModal();
};

window.viewPost = function(id) {
  const p = allPosts.find(x => x.id === id);
  if (!p) return;
  const reportCount = allReports.filter(r => r.targetId === id).length;
  const owner = allUsers.find(u => u.uid === p.userId);
  document.getElementById('modalContent').innerHTML = `
    ${p.imageUrl ? `<img src="${p.imageUrl}" style="width:100%;height:180px;object-fit:cover;border-radius:10px;margin-bottom:16px;" />` : ''}
    <div class="modal-title">${p.title || '—'}</div>
    <div style="margin-bottom:12px;">${postStatusBadge(p.status || 'pending', reportCount)}</div>
    ${modalRow('Người đăng', owner ? `${owner.fullName || '—'} (${owner.email || ''})` : p.userId)}
    ${modalRow('Địa chỉ', p.location || '—')}
    ${modalRow('Khu vực', `${p.district || ''}, ${p.province || ''}`)}
    ${modalRow('Loại phòng', p.roomType || '—')}
    ${modalRow('Giá', formatPrice(p.price))}
    ${modalRow('Diện tích', p.area ? p.area + ' m²' : '—')}
    ${modalRow('Sức chứa', p.capacity ? p.capacity + ' người' : '—')}
    ${modalRow('Tiện ích', (p.amenities || []).join(', ') || '—')}
    ${modalRow('Số bị báo cáo', reportCount)}
    ${modalRow('Mô tả', p.description || '—')}
    ${modalRow('Ngày đăng', formatDate(p.createdAt))}`;
  openModal();
};

// ===== REQUESTS =====
function loadRequests(data = allRequests) {
  const tbody = document.getElementById('requestsTable');
  if (!data.length) {
    tbody.innerHTML = '<tr><td colspan="8" class="empty-row">Không có yêu cầu nào</td></tr>';
    return;
  }
  tbody.innerHTML = data.map(r => {
    const post  = allPosts.find(p => p.id === r.postId);
    const owner = post ? allUsers.find(u => u.uid === post.userId) : null;
    const group = allGroups.find(g => g.requestId === r.id || (r.groupId && g.id === r.groupId));
    const postCell = post
      ? `<button class="btn-link" onclick="viewPost('${post.id}')">${truncate(post.title || post.id, 28)}</button>`
      : `<span class="text-muted">${truncate(r.postId || '—', 20)}</span>`;
    const ownerCell = owner
      ? `<button class="btn-link" onclick="viewUser('${owner.uid}')">${owner.fullName || owner.email || '—'}</button>`
      : `<span class="text-muted">—</span>`;
    const groupCell = group
      ? `<span class="badge badge-group" onclick="viewGroup('${group.id}')"><i class="fa-solid fa-people-roof"></i> ${truncate(group.name || 'Nhóm', 16)}</span>`
      : (r.status === 'accepted'
          ? `<span class="badge badge-warn"><i class="fa-solid fa-circle-exclamation"></i> Chưa tạo</span>`
          : `<span class="text-muted">—</span>`);
    return `
    <tr>
      <td>
        <div class="user-cell">
          <div class="avatar">${avatarEl(r.requesterAvatar, r.requesterName)}</div>
          <button class="btn-link" onclick="viewUser('${r.senderId || ''}')">${r.requesterName || r.senderId || '—'}</button>
        </div>
      </td>
      <td>${postCell}</td>
      <td>${ownerCell}</td>
      <td class="text-muted">${truncate(r.message, 35)}</td>
      <td>${statusBadge(r.status)}</td>
      <td>${groupCell}</td>
      <td>${formatDate(r.createdAt)}</td>
      <td>
        <button class="btn-action btn-view" onclick="viewRequest('${r.id}')"><i class="fa-solid fa-eye"></i> Xem</button>
        <button class="btn-action btn-delete" onclick="confirmDelete('roommate_requests','${r.id}','yêu cầu này')"><i class="fa-solid fa-trash"></i></button>
      </td>
    </tr>`;
  }).join('');
}

window.filterRequests = function() {
  const status  = document.getElementById('filterStatus').value;
  const groupF  = document.getElementById('filterRequestGroup').value;
  const q       = (document.getElementById('searchRequests').value || '').toLowerCase();
  let filtered  = allRequests;
  if (status)  filtered = filtered.filter(r => r.status === status);
  if (groupF === 'has_group') filtered = filtered.filter(r => r.groupId || allGroups.some(g => g.requestId === r.id));
  if (groupF === 'no_group')  filtered = filtered.filter(r => !r.groupId && !allGroups.some(g => g.requestId === r.id));
  if (q) filtered = filtered.filter(r => {
    const post = allPosts.find(p => p.id === r.postId);
    return (r.requesterName || '').toLowerCase().includes(q)
        || (post?.title || '').toLowerCase().includes(q)
        || (r.message || '').toLowerCase().includes(q);
  });
  loadRequests(filtered);
};

window.viewRequest = function(id) {
  const r = allRequests.find(x => x.id === id);
  if (!r) return;
  const post  = allPosts.find(p => p.id === r.postId);
  const owner = post ? allUsers.find(u => u.uid === post.userId) : null;
  const group = allGroups.find(g => g.requestId === r.id || (r.groupId && g.id === r.groupId));
  const sender = allUsers.find(u => u.uid === r.senderId);

  const senderInfo = sender
    ? `<div style="display:flex;align-items:center;gap:10px;">
        <div class="avatar">${avatarEl(sender.photoURL, sender.fullName)}</div>
        <div>
          <div style="font-weight:600;">${sender.fullName || sender.email || '—'}</div>
          <div style="font-size:12px;color:var(--text-secondary);">${sender.email || ''}</div>
        </div>
        <button class="btn-action btn-view" onclick="viewUser('${sender.uid}');closeModal()"><i class="fa-solid fa-arrow-up-right-from-square"></i> Xem profile</button>
      </div>`
    : `<span>${r.requesterName || r.senderId || '—'}</span>`;

  const postInfo = post
    ? `<div style="display:flex;align-items:center;gap:10px;">
        ${post.imageUrl ? `<img src="${post.imageUrl}" style="width:48px;height:36px;object-fit:cover;border-radius:6px;" />` : ''}
        <div>
          <div style="font-weight:600;">${post.title || '—'}</div>
          <div style="font-size:12px;color:var(--text-secondary);">${post.district || ''}, ${post.province || ''} · ${formatPrice(post.price)}</div>
        </div>
        <button class="btn-action btn-view" onclick="viewPost('${post.id}');closeModal()"><i class="fa-solid fa-arrow-up-right-from-square"></i> Xem bài</button>
      </div>`
    : `<span class="text-muted">${r.postId || '—'}</span>`;

  const ownerInfo = owner
    ? `<div style="display:flex;align-items:center;gap:10px;">
        <div class="avatar">${avatarEl(owner.photoURL, owner.fullName)}</div>
        <div>
          <div style="font-weight:600;">${owner.fullName || owner.email || '—'}</div>
          <div style="font-size:12px;color:var(--text-secondary);">${owner.email || ''}</div>
        </div>
        <button class="btn-action btn-view" onclick="viewUser('${owner.uid}');closeModal()"><i class="fa-solid fa-arrow-up-right-from-square"></i> Xem profile</button>
      </div>`
    : `<span class="text-muted">—</span>`;

  const groupInfo = group
    ? `<div style="display:flex;align-items:center;gap:10px;">
        <i class="fa-solid fa-people-roof" style="color:var(--primary);font-size:20px;"></i>
        <div>
          <div style="font-weight:600;">${group.name || 'Nhóm phòng'}</div>
          <div style="font-size:12px;color:var(--text-secondary);">${(group.members || []).length} thành viên · Ngày tạo: ${formatDate(group.createdAt)}</div>
        </div>
        <button class="btn-action btn-view" onclick="showSection('groups', document.querySelector('[onclick*=\"groups\"]'));closeModal()"><i class="fa-solid fa-arrow-up-right-from-square"></i> Xem nhóm</button>
      </div>`
    : (r.status === 'accepted'
        ? `<span class="badge badge-warn"><i class="fa-solid fa-circle-exclamation"></i> Đã chấp nhận nhưng chưa tạo nhóm phòng</span>`
        : `<span class="text-muted">Chưa có nhóm phòng</span>`);

  document.getElementById('modalContent').innerHTML = `
    <div class="modal-title"><i class="fa-solid fa-handshake"></i> Chi tiết yêu cầu ghép phòng</div>

    <div class="detail-section-label">Người gửi yêu cầu</div>
    <div class="detail-section-body">${senderInfo}</div>

    <div class="detail-section-label">Bài đăng liên quan</div>
    <div class="detail-section-body">${postInfo}</div>

    <div class="detail-section-label">Chủ bài đăng (người nhận)</div>
    <div class="detail-section-body">${ownerInfo}</div>

    <div class="detail-section-label">Nhóm phòng kết quả</div>
    <div class="detail-section-body">${groupInfo}</div>

    <div class="detail-section-label">Thông tin yêu cầu</div>
    ${modalRow('Tin nhắn', r.message || '—')}
    ${modalRow('Trạng thái', statusBadge(r.status))}
    ${modalRow('Ngày gửi', formatDate(r.createdAt))}
    ${modalRow('Ngày phản hồi', r.respondedAt ? formatDate(r.respondedAt) : '—')}

    ${r.status === 'pending' ? `
    <div class="detail-section-label" style="color:var(--red);">Can thiệp admin</div>
    <div class="detail-section-body" style="display:flex;gap:8px;">
      <button class="btn-action btn-approve" onclick="adminForceAccept('${r.id}')"><i class="fa-solid fa-check"></i> Buộc chấp nhận</button>
      <button class="btn-action btn-reject" onclick="adminForceReject('${r.id}')"><i class="fa-solid fa-xmark"></i> Buộc từ chối</button>
    </div>` : ''}`;
  openModal();
};

window.adminForceAccept = async function(id) {
  try {
    const { updateDoc, doc: fsDoc } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');
    await updateDoc(fsDoc(db, 'roommate_requests', id), { status: 'accepted', respondedAt: new Date(), adminOverride: true });
    const idx = allRequests.findIndex(r => r.id === id);
    if (idx >= 0) { allRequests[idx].status = 'accepted'; allRequests[idx].respondedAt = new Date(); }
    loadRequests(); closeModal(); showToast('Đã buộc chấp nhận yêu cầu ✓');
  } catch(e) { showToast('Lỗi: ' + e.message); }
};

window.adminForceReject = async function(id) {
  try {
    const { updateDoc, doc: fsDoc } = await import('https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js');
    await updateDoc(fsDoc(db, 'roommate_requests', id), { status: 'rejected', respondedAt: new Date(), adminOverride: true });
    const idx = allRequests.findIndex(r => r.id === id);
    if (idx >= 0) { allRequests[idx].status = 'rejected'; allRequests[idx].respondedAt = new Date(); }
    loadRequests(); closeModal(); showToast('Đã buộc từ chối yêu cầu ✓');
  } catch(e) { showToast('Lỗi: ' + e.message); }
};

// ===== DELETE (Firestore thật) =====
window.confirmDelete = function(colName, id, name) {
  document.getElementById('modalContent').innerHTML = `
    <div class="modal-title" style="color:var(--red)"><i class="fa-solid fa-triangle-exclamation"></i> Xác nhận xóa</div>
    <p style="color:var(--text-secondary);font-size:14px;line-height:1.6;">
      Bạn có chắc muốn xóa <strong style="color:var(--text-primary)">${name}</strong> không?<br/>Hành động này không thể hoàn tác.
    </p>
    <div class="confirm-actions">
      <button class="btn-cancel" onclick="closeModal()">Hủy</button>
      <button class="btn-confirm-delete" onclick="doDelete('${colName}','${id}')"><i class="fa-solid fa-trash"></i> Xóa</button>
    </div>`;
  openModal();
};

window.doDelete = async function(colName, id) {
  try {
    await deleteDoc(doc(db, colName, id));
    if (colName === 'users') {
      allUsers = allUsers.filter(u => u.uid !== id);
      loadUsers();
    } else if (colName === 'posts') {
      allPosts = allPosts.filter(p => p.id !== id);
      loadPosts();
    } else if (colName === 'roommate_requests') {
      allRequests = allRequests.filter(r => r.id !== id);
      loadRequests();
    }
    loadDashboard();
    updateBadges();
    closeModal();
    showToast('Đã xóa thành công ✓');
  } catch (e) {
    closeModal();
    showToast('Lỗi: ' + e.message);
  }
};

// ===== BADGES =====
function updateBadges() {
  document.getElementById('badgeUsers').textContent   = allUsers.length;
  document.getElementById('badgePosts').textContent   = allPosts.length;
  document.getElementById('badgeRequests').textContent = allRequests.filter(r => r.status === 'pending').length;
}

// ===== MODAL =====
window.openModal = function() {
  document.getElementById('modal').style.display = 'flex';
};

window.closeModal = function(e) {
  if (e && e.target !== document.getElementById('modal')) return;
  document.getElementById('modal').style.display = 'none';
};

// ===== TOAST =====
function showToast(msg) {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.style.display = 'block';
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => { toast.style.display = 'none'; }, 2500);
}

// ===== HELPERS =====
function formatPrice(price) {
  if (!price) return '—';
  const n = typeof price === 'number' ? price : Number(price);
  return (n / 1_000_000).toFixed(1).replace('.0', '') + ' triệu/tháng';
}

function formatDate(d) {
  if (!d) return '—';
  const date = d?.toDate ? d.toDate() : new Date(d);
  if (isNaN(date)) return '—';
  return date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

function truncate(str, len) {
  if (!str) return '—';
  return str.length > len ? str.slice(0, len) + '...' : str;
}

function statusBadge(status) {
  const map = {
    pending:  '<span class="badge badge-pending">Đang chờ</span>',
    accepted: '<span class="badge badge-accepted">Chấp nhận</span>',
    rejected: '<span class="badge badge-rejected">Từ chối</span>',
  };
  return map[status] || status;
}

function avatarEl(url, name) {
  if (url) return `<img src="${url}" alt="${name||''}" style="width:100%;height:100%;border-radius:50%;object-fit:cover;" onerror="this.style.display='none'" />`;
  return (name || '?').charAt(0).toUpperCase();
}

function postImgEl(url) {
  if (url) return `<img src="${url}" class="post-img" onerror="this.style.display='none'" />`;
  return `<div class="post-img" style="display:flex;align-items:center;justify-content:center;color:var(--text-secondary);font-size:18px;"><i class="fa-solid fa-image"></i></div>`;
}

function modalRow(label, value) {
  return `<div class="modal-row"><span class="modal-label">${label}</span><span class="modal-value">${value}</span></div>`;
}
