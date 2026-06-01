import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
import {
  getAuth, signInWithEmailAndPassword, signOut, onAuthStateChanged
} from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
import {
  getFirestore, collection, getDocs, deleteDoc, doc, getDoc,
  updateDoc, addDoc, query, orderBy, serverTimestamp
} from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';

// ===== FIREBASE =====
const firebaseConfig = {
  apiKey: 'AIzaSyDB6JgulOU15cKe7V-oNcboWScX6_DbuZY',
  authDomain: 'roommateapp-fbb4f.firebaseapp.com',
  projectId: 'roommateapp-fbb4f',
  storageBucket: 'roommateapp-fbb4f.firebasestorage.app',
  messagingSenderId: '787375402089',
  appId: '1:787375402089:web:bb98d7aa19147eb09586f8',
};

const app  = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db   = getFirestore(app);

// ===== GLOBAL STATE =====
const state = {
  users:    [],
  posts:    [],
  requests: [],
  groups:   [],
  reports:  [],
  filters: {
    users:    { q: '', role: '', status: '' },
    posts:    { q: '', status: '', province: '' },
    requests: { q: '', status: '' },
    groups:   { q: '', status: '' },
    reports:  { q: '', status: '' },
  },
  currentPage: { users: 1, posts: 1, requests: 1, groups: 1, reports: 1 },
  sort: { users: { col: '', dir: 1 }, posts: { col: '', dir: 1 } },
};

const PAGE_SIZE = 25;

// ===== SECURITY: XSS SAFE =====
function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

// ===== HELPERS =====
function formatDate(d) {
  if (!d) return '—';
  const date = d?.toDate ? d.toDate() : new Date(d);
  if (isNaN(date)) return '—';
  return date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

function formatPrice(price) {
  if (!price) return '—';
  const n = typeof price === 'number' ? price : Number(price);
  if (isNaN(n)) return '—';
  return (n / 1_000_000).toFixed(1).replace(/\.0$/, '') + ' tr/tháng';
}

function truncate(str, len) {
  if (!str) return '—';
  const s = String(str);
  return s.length > len ? s.slice(0, len) + '…' : s;
}

function toDate(val) {
  if (!val) return null;
  if (val?.toDate) return val.toDate();
  if (val instanceof Date) return val;
  const d = new Date(val);
  return isNaN(d) ? null : d;
}

// ===== BADGE HELPERS =====
function statusBadge(status) {
  const map = {
    pending:   ['badge-pending',  'Đang chờ'],
    accepted:  ['badge-accepted', 'Chấp nhận'],
    rejected:  ['badge-rejected', 'Từ chối'],
    active:    ['badge-active',   'Hoạt động'],
    hidden:    ['badge-hidden',   'Đã ẩn'],
    sold:      ['badge-sold',     'Hết phòng'],
    blocked:   ['badge-blocked',  'Đã khóa'],
    resolved:  ['badge-resolved', 'Đã xử lý'],
    dismissed: ['badge-dismissed','Bỏ qua'],
    inactive:  ['badge-inactive', 'Không HĐ'],
  };
  const [cls, label] = map[status] || ['badge-pending', escapeHtml(status)];
  return `<span class="badge ${cls}">${label}</span>`;
}

function avatarEl(url, name) {
  const initial = escapeHtml((name || '?').charAt(0).toUpperCase());
  if (url) {
    return `<img src="${escapeHtml(url)}" alt="${initial}" style="width:100%;height:100%;border-radius:50%;object-fit:cover;" onerror="this.remove()" />`;
  }
  return initial;
}

function makeAvatar(url, name) {
  return `<div class="avatar">${avatarEl(url, name)}</div>`;
}

function modalRow(label, value) {
  return `<div class="modal-row"><span class="modal-label">${escapeHtml(label)}</span><span class="modal-value">${value}</span></div>`;
}

function spinnerRow(cols) {
  return `<tr class="state-row"><td colspan="${cols}">
    <div class="empty-msg">
      <svg class="spinner-svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
      </svg>
    </div>
  </td></tr>`;
}

function emptyRow(cols, msg) {
  return `<tr class="state-row"><td colspan="${cols}">
    <div class="empty-msg">
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="opacity:.35"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 9h6M9 13h4"/></svg>
      <span>${escapeHtml(msg)}</span>
    </div>
  </td></tr>`;
}

// ===== PAGINATION =====
function renderPagination(containerId, section, total, onPage) {
  const el = document.getElementById(containerId);
  if (!el) return;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const cur = state.currentPage[section];

  el.innerHTML = '';
  if (totalPages <= 1) return;

  const prev = document.createElement('button');
  prev.textContent = '← Trước';
  prev.disabled = cur <= 1;
  prev.addEventListener('click', () => { state.currentPage[section] = cur - 1; onPage(); });

  const info = document.createElement('span');
  info.className = 'page-info';
  info.textContent = `Trang ${cur} / ${totalPages}  (${total} mục)`;

  const next = document.createElement('button');
  next.textContent = 'Tiếp →';
  next.disabled = cur >= totalPages;
  next.addEventListener('click', () => { state.currentPage[section] = cur + 1; onPage(); });

  el.appendChild(prev);
  el.appendChild(info);
  el.appendChild(next);
}

function pageSlice(arr, section) {
  const p = state.currentPage[section];
  return arr.slice((p - 1) * PAGE_SIZE, p * PAGE_SIZE);
}

// ===== TOAST =====
function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer');
  if (!container) return;
  const t = document.createElement('div');
  t.className = `toast toast-${type}`;
  t.innerHTML = `<span class="toast-dot"></span><span>${escapeHtml(message)}</span>`;
  container.appendChild(t);
  setTimeout(() => { t.style.opacity = '0'; t.style.transform = 'translateX(20px)'; t.style.transition = 'all .25s'; setTimeout(() => t.remove(), 260); }, 3000);
}

// ===== CONFIRM MODAL =====
function showConfirmModal(title, message, onConfirm) {
  const modal = document.getElementById('confirmModal');
  document.getElementById('confirmTitle').textContent = title;
  document.getElementById('confirmMessage').textContent = message;
  modal.hidden = false;

  const ok     = document.getElementById('confirmOk');
  const cancel = document.getElementById('confirmCancel');

  const close = () => { modal.hidden = true; };

  const okClone = ok.cloneNode(true);
  ok.parentNode.replaceChild(okClone, ok);
  const cancelClone = cancel.cloneNode(true);
  cancel.parentNode.replaceChild(cancelClone, cancel);

  document.getElementById('confirmOk').addEventListener('click', () => { close(); onConfirm(); });
  document.getElementById('confirmCancel').addEventListener('click', close);
  modal.addEventListener('click', (e) => { if (e.target === modal) close(); }, { once: true });
}

// ===== MODAL =====
function openModal(html) {
  document.getElementById('modalContent').innerHTML = html;
  document.getElementById('modal').hidden = false;
}

function closeModal() {
  document.getElementById('modal').hidden = true;
  document.getElementById('modalContent').innerHTML = '';
}

// ===== NAVIGATION =====
const SECTION_TITLES = {
  dashboard: 'Dashboard',
  users:     'Người dùng',
  posts:     'Bài đăng',
  requests:  'Yêu cầu ghép phòng',
  groups:    'Nhóm phòng',
  reports:   'Báo cáo',
};

function showSection(name) {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const sec = document.getElementById('section-' + name);
  if (sec) sec.classList.add('active');
  const navEl = document.querySelector(`.nav-item[data-section="${name}"]`);
  if (navEl) navEl.classList.add('active');
  const titleEl = document.getElementById('headerTitle');
  if (titleEl) titleEl.textContent = SECTION_TITLES[name] || name;
  closeSidebar();
}

// ===== SIDEBAR MOBILE =====
function closeSidebar() {
  if (window.innerWidth > 768) return;
  document.getElementById('sidebar').classList.remove('open');
  document.getElementById('sidebarOverlay').classList.remove('open');
}

// ===== AUTH =====
document.addEventListener('DOMContentLoaded', () => {
  updateHeaderDate();
  bindStaticEvents();

  onAuthStateChanged(auth, async (user) => {
    if (!user) { showLoginPage(); return; }
    try {
      const snap = await getDoc(doc(db, 'users', user.uid));
      if (snap.data()?.role !== 'admin') {
        await signOut(auth);
        showLoginError('Tài khoản không có quyền admin.');
        return;
      }
      const nameEl = document.getElementById('adminName');
      if (nameEl) nameEl.textContent = escapeHtml(user.displayName || user.email.split('@')[0]);
      showDashboardPage();
      await loadAllData();
    } catch (e) {
      await signOut(auth);
      showLoginError('Lỗi xác thực: ' + e.message);
    }
  });
});

function bindStaticEvents() {
  // Login form
  document.getElementById('loginForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email    = document.getElementById('loginEmail').value.trim();
    const password = document.getElementById('loginPassword').value;
    const btnText  = document.getElementById('loginBtnText');
    const spinner  = document.getElementById('loginSpinner');
    btnText.hidden = true;
    spinner.hidden = false;
    document.getElementById('loginError').hidden = true;
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      btnText.hidden = false;
      spinner.hidden = true;
      showLoginError(parseAuthError(err.code));
    }
  });

  // Sign out
  document.getElementById('btnSignOut')?.addEventListener('click', () => {
    showConfirmModal('Đăng xuất', 'Bạn có chắc muốn đăng xuất không?', async () => {
      await signOut(auth);
      showLoginPage();
    });
  });

  // Refresh
  document.getElementById('btnRefresh')?.addEventListener('click', () => loadAllData());

  // Hamburger
  document.getElementById('hamburger')?.addEventListener('click', () => {
    document.getElementById('sidebar').classList.toggle('open');
    document.getElementById('sidebarOverlay').classList.toggle('open');
  });
  document.getElementById('sidebarOverlay')?.addEventListener('click', closeSidebar);

  // Nav
  document.querySelectorAll('.nav-item[data-section]').forEach(el => {
    el.addEventListener('click', (e) => { e.preventDefault(); showSection(el.dataset.section); });
  });

  // Modal close
  document.getElementById('modalClose')?.addEventListener('click', closeModal);
  document.getElementById('modal')?.addEventListener('click', (e) => { if (e.target === document.getElementById('modal')) closeModal(); });

  // Section filters
  bindFilterEvents('users',    renderUsersSection);
  bindFilterEvents('posts',    renderPostsSection);
  bindFilterEvents('requests', renderRequestsSection);
  bindFilterEvents('groups',   renderGroupsSection);
  bindFilterEvents('reports',  renderReportsSection);

  // Province filter for posts
  document.getElementById('filterPostProvince')?.addEventListener('change', renderPostsSection);

  // Sort - users table
  document.querySelectorAll('#usersTableEl th[data-col]').forEach(th => {
    th.addEventListener('click', () => {
      const col = th.dataset.col;
      if (state.sort.users.col === col) {
        state.sort.users.dir *= -1;
      } else {
        state.sort.users.col = col;
        state.sort.users.dir = 1;
      }
      state.currentPage.users = 1;
      renderUsersSection();
    });
  });

  // Sort - posts table
  document.querySelectorAll('#postsTableEl th[data-col]').forEach(th => {
    th.addEventListener('click', () => {
      const col = th.dataset.col;
      if (state.sort.posts.col === col) {
        state.sort.posts.dir *= -1;
      } else {
        state.sort.posts.col = col;
        state.sort.posts.dir = 1;
      }
      state.currentPage.posts = 1;
      renderPostsSection();
    });
  });
}

function bindFilterEvents(section, renderFn) {
  const ids = {
    users:    ['searchUsers', 'filterUserRole', 'filterUserStatus', 'clearUsersFilter'],
    posts:    ['searchPosts', 'filterPostStatus', null, 'clearPostsFilter'],
    requests: ['searchRequests', 'filterReqStatus', null, 'clearRequestsFilter'],
    groups:   ['searchGroups', 'filterGroupStatus', null, 'clearGroupsFilter'],
    reports:  ['searchReports', 'filterReportStatus', null, 'clearReportsFilter'],
  };

  const [searchId, filter1Id, filter2Id, clearId] = ids[section];

  const search = document.getElementById(searchId);
  const f1     = document.getElementById(filter1Id);
  const f2     = filter2Id ? document.getElementById(filter2Id) : null;
  const clear  = document.getElementById(clearId);

  const onInput = () => {
    state.currentPage[section] = 1;
    renderFn();
  };

  search?.addEventListener('input', onInput);
  f1?.addEventListener('change', onInput);
  f2?.addEventListener('change', onInput);

  clear?.addEventListener('click', () => {
    if (search) search.value = '';
    if (f1) f1.value = '';
    if (f2) f2.value = '';
    if (section === 'posts') {
      const prov = document.getElementById('filterPostProvince');
      if (prov) prov.value = '';
    }
    state.currentPage[section] = 1;
    renderFn();
  });
}

function parseAuthError(code) {
  const map = {
    'auth/user-not-found':   'Email không tồn tại.',
    'auth/wrong-password':   'Mật khẩu không đúng.',
    'auth/invalid-email':    'Email không hợp lệ.',
    'auth/too-many-requests':'Quá nhiều lần thử. Thử lại sau.',
    'auth/invalid-credential': 'Email hoặc mật khẩu không đúng.',
  };
  return map[code] || 'Đăng nhập thất bại. Vui lòng thử lại.';
}

function showLoginError(msg) {
  const el = document.getElementById('loginError');
  el.textContent = msg;
  el.hidden = false;
}

function showLoginPage() {
  document.getElementById('loginPage').hidden = false;
  document.getElementById('dashboardPage').hidden = true;
  document.getElementById('loginBtnText').hidden = false;
  document.getElementById('loginSpinner').hidden = true;
  document.getElementById('loginError').hidden = true;
}

function showDashboardPage() {
  document.getElementById('loginPage').hidden = true;
  document.getElementById('dashboardPage').hidden = false;
}

function updateHeaderDate() {
  const el = document.getElementById('headerDate');
  if (!el) return;
  el.textContent = new Date().toLocaleDateString('vi-VN', {
    weekday: 'long', day: '2-digit', month: '2-digit', year: 'numeric'
  });
}

// ===== LOAD ALL DATA =====
async function loadAllData() {
  showToast('Đang tải dữ liệu…', 'warning');
  await Promise.allSettled([
    fetchUsers(),
    fetchPosts(),
    fetchRequests(),
    fetchGroups(),
    fetchReports(),
  ]);
  buildProvinceFilter();
  updateBadges();
  renderDashboard();
  renderUsersSection();
  renderPostsSection();
  renderRequestsSection();
  renderGroupsSection();
  renderReportsSection();
  renderCharts(state.users, state.posts, state.requests);
  showToast('Tải dữ liệu thành công', 'success');
}

async function fetchCollection(colName, orderField = 'createdAt') {
  try {
    const snap = await getDocs(query(collection(db, colName), orderBy(orderField, 'desc')));
    return snap.docs.map(d => ({ id: d.id, ...d.data() }));
  } catch (e) {
    console.error(`fetch ${colName}:`, e);
    return [];
  }
}

async function fetchUsers() {
  const docs = await fetchCollection('users');
  // Giữ deleted users trong state để admin có thể thấy, nhưng filter khi render
  state.users = docs.map(d => ({ ...d, uid: d.id }));
}

async function fetchPosts()    { state.posts    = await fetchCollection('posts'); }
async function fetchRequests() { state.requests = await fetchCollection('roommate_requests'); }
async function fetchGroups()   { state.groups   = await fetchCollection('room_groups'); }
async function fetchReports()  { state.reports  = await fetchCollection('reports'); }

// ===== BADGES =====
function updateBadges() {
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('badgeUsers',    state.users.filter(u => !u.deleted && !u.isDeleted).length);
  set('badgePosts',    state.posts.length);
  set('badgeRequests', state.requests.filter(r => r.status === 'pending').length);
  set('badgeGroups',   state.groups.length);
  set('badgeReports',  state.reports.filter(r => !r.status || r.status === 'pending').length);
}

// ===== PROVINCE FILTER =====
function buildProvinceFilter() {
  const sel = document.getElementById('filterPostProvince');
  if (!sel) return;
  while (sel.options.length > 1) sel.remove(1);
  const provinces = [...new Set(state.posts.map(p => p.province).filter(Boolean))].sort();
  provinces.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p; opt.textContent = p;
    sel.appendChild(opt);
  });
}

// ===== DASHBOARD =====
function renderDashboard() {
  const pending  = state.requests.filter(r => r.status === 'pending').length;
  const accepted = state.requests.filter(r => r.status === 'accepted').length;
  const total    = state.requests.length;
  const matchRate = total > 0 ? Math.round((accepted / total) * 100) : 0;
  const rptPending = state.reports.filter(r => !r.status || r.status === 'pending').length;
  const activeGroups = state.groups.filter(g => g.status === 'active').length;

  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('statUsers',        state.users.filter(u => !u.deleted && !u.isDeleted).length);
  set('statPosts',        state.posts.length);
  set('statPendingReqs',  pending);
  set('statGroups',       activeGroups);
  set('statReportsPending', rptPending);
  set('statMatchRate',    matchRate + '%');

  const recentPostsTbody = document.getElementById('recentPosts');
  if (recentPostsTbody) {
    const rows = state.posts.slice(0, 6).map(p => `
      <tr>
        <td><strong>${escapeHtml(truncate(p.title, 32))}</strong></td>
        <td>${escapeHtml(p.province || '—')}</td>
        <td class="mono">${escapeHtml(formatPrice(p.price))}</td>
        <td>${escapeHtml(formatDate(p.createdAt))}</td>
      </tr>`).join('') || emptyRow(4, 'Chưa có dữ liệu');
    recentPostsTbody.innerHTML = rows;
  }

  const recentReqsTbody = document.getElementById('recentRequests');
  if (recentReqsTbody) {
    const rows = state.requests.slice(0, 6).map(r => `
      <tr>
        <td>${escapeHtml(r.requesterName || r.requesterId || '—')}</td>
        <td>${statusBadge(r.status)}</td>
        <td>${escapeHtml(formatDate(r.createdAt))}</td>
      </tr>`).join('') || emptyRow(3, 'Chưa có dữ liệu');
    recentReqsTbody.innerHTML = rows;
  }
}

// ===== USERS =====
function filterUsers() {
  const q      = (document.getElementById('searchUsers')?.value || '').toLowerCase();
  const role   = document.getElementById('filterUserRole')?.value || '';
  const status = document.getElementById('filterUserStatus')?.value || '';

  return state.users.filter(u => {
    // Ẩn user đã bị soft-delete (cả hai field để tương thích ngược)
    if (u.deleted === true || u.isDeleted === true) return false;
    const matchQ      = (u.fullName || '').toLowerCase().includes(q) || (u.email || '').toLowerCase().includes(q);
    const matchRole   = !role   || (u.role || 'user') === role;
    const matchStatus = !status || (status === 'blocked' ? u.isBlocked === true : u.isBlocked !== true);
    return matchQ && matchRole && matchStatus;
  });
}

function getSortedUsers() {
  const data = filterUsers();
  const { col, dir } = state.sort.users;
  if (!col) return data;
  return [...data].sort((a, b) => {
    let va, vb;
    switch (col) {
      case 'fullName':
        va = (a.fullName || '').toLowerCase();
        vb = (b.fullName || '').toLowerCase();
        break;
      case 'isBlocked':
        va = a.isBlocked ? 1 : 0;
        vb = b.isBlocked ? 1 : 0;
        break;
      case 'postCount':
        va = state.posts.filter(p => p.userId === a.uid).length;
        vb = state.posts.filter(p => p.userId === b.uid).length;
        break;
      case 'reportCount':
        va = state.reports.filter(r => r.targetId === a.uid).length;
        vb = state.reports.filter(r => r.targetId === b.uid).length;
        break;
      case 'createdAt':
        va = toDate(a.createdAt)?.getTime() || 0;
        vb = toDate(b.createdAt)?.getTime() || 0;
        break;
      default: return 0;
    }
    if (va < vb) return -dir;
    if (va > vb) return dir;
    return 0;
  });
}

function renderUsersSection() {
  const data   = getSortedUsers();
  const page   = pageSlice(data, 'users');
  const tbody  = document.getElementById('usersTable');
  if (!tbody) return;

  if (!page.length) {
    tbody.innerHTML = data.length === 0
      ? emptyRow(8, 'Không có người dùng nào')
      : emptyRow(8, 'Không có kết quả phù hợp');
    renderPagination('usersPagination', 'users', data.length, renderUsersSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(u => {
    const postCount   = state.posts.filter(p => p.userId === u.uid).length;
    const reportCount = state.reports.filter(r => r.targetId === u.uid).length;
    const isBlocked   = u.isBlocked === true;
    const isAdmin     = u.role === 'admin';

    const tr = document.createElement('tr');
    if (isBlocked) tr.style.opacity = '.55';

    const tdUser = document.createElement('td');
    tdUser.innerHTML = `<div class="user-cell">${makeAvatar(u.avatarUrl, u.fullName)}<div><div class="user-name">${escapeHtml(u.fullName || '—')}</div><div class="user-email">${escapeHtml(u.email || '')}</div></div></div>`;

    const tdEmail  = document.createElement('td'); tdEmail.textContent  = u.email || '—';
    const tdRole   = document.createElement('td'); tdRole.innerHTML     = isAdmin ? '<span class="badge badge-admin">Admin</span>' : '<span class="badge badge-user">User</span>';
    const tdStatus = document.createElement('td'); tdStatus.innerHTML   = isBlocked ? '<span class="badge badge-blocked">Đã khóa</span>' : '<span class="badge badge-active">Hoạt động</span>';
    const tdPosts  = document.createElement('td'); tdPosts.innerHTML    = `<span class="count mono">${postCount}</span>`;
    const tdRpt    = document.createElement('td'); tdRpt.innerHTML      = `<span class="count mono ${reportCount > 0 ? 'count-danger' : ''}">${reportCount}</span>`;
    const tdDate   = document.createElement('td'); tdDate.textContent   = formatDate(u.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnView = document.createElement('button');
    btnView.className = 'btn btn-view';
    btnView.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg> Chi tiết';
    btnView.dataset.uid = u.uid;
    btnView.addEventListener('click', () => viewUser(u.uid));

    const btnToggle = document.createElement('button');
    btnToggle.className = isBlocked ? 'btn btn-success' : 'btn btn-warn';
    btnToggle.textContent = isBlocked ? 'Mở khóa' : 'Khóa';
    btnToggle.dataset.uid = u.uid;
    btnToggle.addEventListener('click', () => {
      const action = isBlocked ? 'mở khóa' : 'khóa';
      showConfirmModal(`${action.charAt(0).toUpperCase() + action.slice(1)} tài khoản`, `Bạn có chắc muốn ${action} tài khoản "${u.fullName || u.email}"?`, () => toggleBlockUser(u.uid, !isBlocked));
    });

    const btnDel = document.createElement('button');
    btnDel.className = 'btn btn-del';
    btnDel.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
    btnDel.title = 'Xóa mềm';
    btnDel.dataset.uid = u.uid;
    btnDel.addEventListener('click', () => {
      showConfirmModal('Vô hiệu hóa tài khoản', `Vô hiệu hóa tài khoản "${u.fullName || u.email}"? Tài khoản sẽ bị ẩn và user sẽ bị đăng xuất tự động.`, () => softDeleteUser(u.uid));
    });

    tdActions.append(btnView, btnToggle, btnDel);
    tr.append(tdUser, tdEmail, tdRole, tdStatus, tdPosts, tdRpt, tdDate, tdActions);
    tbody.appendChild(tr);
  });

  renderPagination('usersPagination', 'users', data.length, renderUsersSection);

  // Update sort icons
  document.querySelectorAll('#usersTableEl th[data-col]').forEach(th => {
    const icon = th.querySelector('.sort-icon');
    if (!icon) return;
    if (th.dataset.col === state.sort.users.col) {
      icon.textContent = state.sort.users.dir === 1 ? '↑' : '↓';
      icon.style.opacity = '1';
    } else {
      icon.textContent = '↕';
      icon.style.opacity = '.45';
    }
  });
}

async function toggleBlockUser(uid, block) {
  try {
    await updateDoc(doc(db, 'users', uid), { isBlocked: block });
    const u = state.users.find(x => x.uid === uid);
    if (u) u.isBlocked = block;
    updateBadges();
    renderUsersSection();
    showToast(`Đã ${block ? 'khóa' : 'mở khóa'} tài khoản`, 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

async function changeUserRole(uid, newRole) {
  try {
    await updateDoc(doc(db, 'users', uid), { role: newRole });
    const u = state.users.find(x => x.uid === uid);
    if (u) u.role = newRole;
    updateBadges();
    renderUsersSection();
    showToast(`Đã ${newRole === 'admin' ? 'thăng quyền Admin' : 'hạ về User'}`, 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

async function softDeleteUser(uid) {
  try {
    // Soft delete trên Firestore — KHÔNG xóa Firebase Auth, KHÔNG dùng Cloud Function.
    // User bị đánh dấu deleted=true, app Flutter sẽ tự đăng xuất user này.
    await updateDoc(doc(db, 'users', uid), {
      deleted:   true,
      deletedAt: serverTimestamp(),
      isBlocked: true,
    });
    // Ẩn khỏi danh sách admin ngay lập tức (vẫn giữ trong state để không reload)
    const u = state.users.find(x => x.uid === uid);
    if (u) { u.deleted = true; u.isBlocked = true; }
    updateBadges();
    renderUsersSection();
    showToast('Đã vô hiệu hóa tài khoản. User sẽ bị đăng xuất tự động.', 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

function viewUser(uid) {
  const u = state.users.find(x => x.uid === uid);
  if (!u) return;
  const postCount   = state.posts.filter(p => p.userId === uid).length;
  const reportCount = state.reports.filter(r => r.targetId === uid).length;
  const isBlocked   = u.isBlocked === true;
  const isAdmin     = u.role === 'admin';

  openModal(`
    <div style="text-align:center;margin-bottom:20px;">
      <div class="avatar" style="width:64px;height:64px;font-size:24px;margin:0 auto 12px;">${avatarEl(u.avatarUrl, u.fullName)}</div>
      <div style="font-size:17px;font-weight:800;">${escapeHtml(u.fullName || '—')}</div>
      <div style="color:var(--text-2);font-size:12px;margin-top:3px;">${escapeHtml(u.email || '')}</div>
      <div style="display:flex;gap:8px;justify-content:center;margin-top:10px;">
        ${isAdmin ? '<span class="badge badge-admin">Admin</span>' : '<span class="badge badge-user">User</span>'}
        ${isBlocked ? '<span class="badge badge-blocked">Đã khóa</span>' : '<span class="badge badge-active">Hoạt động</span>'}
      </div>
    </div>
    <div class="modal-section-label">Thông tin</div>
    ${modalRow('SĐT', escapeHtml(u.phone || '—'))}
    ${modalRow('Giới tính', escapeHtml(u.gender || '—'))}
    ${modalRow('Tuổi', escapeHtml(String(u.age || '—')))}
    ${modalRow('Nghề nghiệp', escapeHtml(u.occupation || '—'))}
    ${modalRow('Ngân sách', escapeHtml(u.budgetRange || '—'))}
    ${modalRow('Khu vực', escapeHtml(u.preferredLocation || '—'))}
    ${modalRow('Bio', escapeHtml(u.bio || '—'))}
    ${modalRow('Số bài đăng', `<span class="mono">${postCount}</span>`)}
    ${modalRow('Số lần bị báo cáo', `<span class="mono ${reportCount > 0 ? 'count-danger' : ''}">${reportCount}</span>`)}
    ${modalRow('Ngày tạo', escapeHtml(formatDate(u.createdAt)))}
    <div class="modal-section-label" style="color:var(--danger);">Hành động Admin</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px;">
      <button class="btn ${isBlocked ? 'btn-success' : 'btn-warn'}" id="btnModalToggleBlock">
        ${isBlocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'}
      </button>
      ${!isAdmin
        ? `<button class="btn btn-primary" id="btnModalPromote">Thăng quyền Admin</button>`
        : `<button class="btn btn-warn" id="btnModalDemote">Hạ về User</button>`}
    </div>
  `);

  document.getElementById('btnModalToggleBlock')?.addEventListener('click', () => {
    showConfirmModal(
      isBlocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
      `Bạn có chắc muốn ${isBlocked ? 'mở khóa' : 'khóa'} tài khoản "${escapeHtml(u.fullName || u.email)}"?`,
      () => { closeModal(); toggleBlockUser(u.uid, !isBlocked); }
    );
  });

  document.getElementById('btnModalPromote')?.addEventListener('click', () => {
    showConfirmModal(
      'Thăng quyền Admin',
      `Cấp quyền Admin cho "${escapeHtml(u.fullName || u.email)}"? Người này sẽ có toàn quyền quản trị.`,
      () => { closeModal(); changeUserRole(u.uid, 'admin'); }
    );
  });

  document.getElementById('btnModalDemote')?.addEventListener('click', () => {
    showConfirmModal(
      'Hạ quyền về User',
      `Hạ quyền "${escapeHtml(u.fullName || u.email)}" từ Admin về User thông thường?`,
      () => { closeModal(); changeUserRole(u.uid, 'user'); }
    );
  });
}

// ===== POSTS =====
function filterPosts() {
  const q        = (document.getElementById('searchPosts')?.value || '').toLowerCase();
  const status   = document.getElementById('filterPostStatus')?.value || '';
  const province = document.getElementById('filterPostProvince')?.value || '';

  return state.posts.filter(p => {
    const matchQ        = (p.title || '').toLowerCase().includes(q) || (p.province || '').toLowerCase().includes(q) || (p.district || '').toLowerCase().includes(q);
    const matchStatus   = !status   || (p.status || 'pending') === status;
    const matchProvince = !province || p.province === province;
    return matchQ && matchStatus && matchProvince;
  });
}

function getSortedPosts() {
  const data = filterPosts();
  const { col, dir } = state.sort.posts;
  if (!col) return data;
  return [...data].sort((a, b) => {
    if (col === 'createdAt') {
      const va = toDate(a.createdAt)?.getTime() || 0;
      const vb = toDate(b.createdAt)?.getTime() || 0;
      if (va < vb) return -dir;
      if (va > vb) return dir;
    }
    return 0;
  });
}

function renderPostsSection() {
  const data  = getSortedPosts();
  const page  = pageSlice(data, 'posts');
  const tbody = document.getElementById('postsTable');
  if (!tbody) return;

  if (!page.length) {
    tbody.innerHTML = emptyRow(7, data.length === 0 ? 'Không có bài đăng nào' : 'Không có kết quả phù hợp');
    renderPagination('postsPagination', 'posts', data.length, renderPostsSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(p => {
    const owner  = state.users.find(u => u.uid === p.userId);
    const status = p.status || 'pending';

    const tr = document.createElement('tr');

    const tdTitle = document.createElement('td');
    tdTitle.innerHTML = `<strong>${escapeHtml(truncate(p.title, 40))}</strong>`;

    const tdOwner = document.createElement('td');
    if (owner) {
      const btn = document.createElement('button');
      btn.className = 'btn-link';
      btn.textContent = owner.fullName || owner.email || '—';
      btn.addEventListener('click', () => viewUser(owner.uid));
      tdOwner.appendChild(btn);
    } else {
      tdOwner.textContent = '—';
    }

    const tdArea   = document.createElement('td'); tdArea.textContent   = [p.district, p.province].filter(Boolean).join(', ') || '—';
    const tdPrice  = document.createElement('td'); tdPrice.className    = 'mono'; tdPrice.textContent = formatPrice(p.price);
    const tdStatus = document.createElement('td'); tdStatus.innerHTML   = statusBadge(status);
    const tdDate   = document.createElement('td'); tdDate.textContent   = formatDate(p.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnView = document.createElement('button');
    btnView.className = 'btn btn-view';
    btnView.textContent = 'Chi tiết';
    btnView.addEventListener('click', () => viewPost(p.id));

    const btnToggle = document.createElement('button');
    if (status !== 'active') {
      btnToggle.className = 'btn btn-success';
      btnToggle.textContent = 'Duyệt';
      btnToggle.addEventListener('click', () => {
        showConfirmModal('Duyệt bài đăng', `Duyệt bài "${truncate(p.title, 40)}"?`, () => updatePostStatus(p.id, 'active'));
      });
    } else {
      btnToggle.className = 'btn btn-warn';
      btnToggle.textContent = 'Ẩn';
      btnToggle.addEventListener('click', () => {
        showConfirmModal('Ẩn bài đăng', `Ẩn bài "${truncate(p.title, 40)}"?`, () => updatePostStatus(p.id, 'hidden'));
      });
    }

    const btnDel = document.createElement('button');
    btnDel.className = 'btn btn-del';
    btnDel.title = 'Xóa bài đăng';
    btnDel.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
    btnDel.addEventListener('click', () => {
      showConfirmModal('Xóa bài đăng', `Xóa bài "${truncate(p.title, 40)}"? Hành động không thể hoàn tác.`, () => deletePost(p.id));
    });

    if (status === 'active') {
      const btnSold = document.createElement('button');
      btnSold.className = 'btn btn-ghost';
      btnSold.textContent = 'Hết phòng';
      btnSold.addEventListener('click', () => {
        showConfirmModal('Đánh dấu hết phòng', `Đánh dấu bài "${truncate(p.title, 40)}" là hết phòng?`, () => updatePostStatus(p.id, 'sold'));
      });
      tdActions.append(btnView, btnToggle, btnSold, btnDel);
    } else {
      tdActions.append(btnView, btnToggle, btnDel);
    }
    tr.append(tdTitle, tdOwner, tdArea, tdPrice, tdStatus, tdDate, tdActions);
    tbody.appendChild(tr);
  });

  renderPagination('postsPagination', 'posts', data.length, renderPostsSection);

  // Update sort icons
  document.querySelectorAll('#postsTableEl th[data-col]').forEach(th => {
    const icon = th.querySelector('.sort-icon');
    if (!icon) return;
    if (th.dataset.col === state.sort.posts.col) {
      icon.textContent = state.sort.posts.dir === 1 ? '↑' : '↓';
      icon.style.opacity = '1';
    } else {
      icon.textContent = '↕';
      icon.style.opacity = '.45';
    }
  });
}

async function deletePost(id) {
  try {
    await deleteDoc(doc(db, 'posts', id));
    state.posts = state.posts.filter(x => x.id !== id);
    updateBadges();
    renderPostsSection();
    showToast('Đã xóa bài đăng', 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

async function updatePostStatus(id, newStatus) {
  try {
    await updateDoc(doc(db, 'posts', id), { status: newStatus });
    const p = state.posts.find(x => x.id === id);
    if (p) p.status = newStatus;
    renderPostsSection();
    showToast(`Đã ${newStatus === 'active' ? 'duyệt' : 'ẩn'} bài đăng`, 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

function viewPost(id) {
  const p = state.posts.find(x => x.id === id);
  if (!p) return;
  const owner = state.users.find(u => u.uid === p.userId);
  const status = p.status || 'pending';

  openModal(`
    <div class="modal-title">${escapeHtml(p.title || '—')}</div>
    <div style="margin-bottom:14px;">${statusBadge(status)}</div>
    ${modalRow('Người đăng', owner ? `${escapeHtml(owner.fullName || '—')} (${escapeHtml(owner.email || '')})` : escapeHtml(p.userId || '—'))}
    ${modalRow('Địa chỉ', escapeHtml(p.location || '—'))}
    ${modalRow('Khu vực', escapeHtml([p.district, p.province].filter(Boolean).join(', ') || '—'))}
    ${modalRow('Loại phòng', escapeHtml(p.roomType || '—'))}
    ${modalRow('Giá', escapeHtml(formatPrice(p.price)))}
    ${modalRow('Diện tích', p.area ? escapeHtml(p.area + ' m²') : '—')}
    ${modalRow('Sức chứa', p.capacity ? escapeHtml(String(p.capacity) + ' người') : '—')}
    ${modalRow('Tiện ích', escapeHtml((p.amenities || []).join(', ') || '—'))}
    ${modalRow('Mô tả', escapeHtml(truncate(p.description, 200)))}
    ${modalRow('Ngày đăng', escapeHtml(formatDate(p.createdAt)))}
  `);
}

// ===== REQUESTS =====
function filterRequests() {
  const q      = (document.getElementById('searchRequests')?.value || '').toLowerCase();
  const status = document.getElementById('filterReqStatus')?.value || '';

  return state.requests.filter(r => {
    const post = state.posts.find(p => p.id === r.postId);
    const matchQ = (r.requesterName || r.requesterId || '').toLowerCase().includes(q)
      || (post?.title || '').toLowerCase().includes(q)
      || (r.message || '').toLowerCase().includes(q);
    const matchStatus = !status || r.status === status;
    return matchQ && matchStatus;
  });
}

function renderRequestsSection() {
  const data  = filterRequests();
  const page  = pageSlice(data, 'requests');
  const tbody = document.getElementById('requestsTable');
  if (!tbody) return;

  if (!page.length) {
    tbody.innerHTML = emptyRow(7, data.length === 0 ? 'Không có yêu cầu nào' : 'Không có kết quả phù hợp');
    renderPagination('requestsPagination', 'requests', data.length, renderRequestsSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(r => {
    const post  = state.posts.find(p => p.id === r.postId);
    const owner = post ? state.users.find(u => u.uid === post.userId) : null;

    const tr = document.createElement('tr');

    const tdSender = document.createElement('td');
    tdSender.innerHTML = `<div class="user-cell">${makeAvatar(r.requesterAvatar, r.requesterName)}<span>${escapeHtml(r.requesterName || r.requesterId || '—')}</span></div>`;

    const tdPost = document.createElement('td');
    if (post) {
      const btn = document.createElement('button');
      btn.className = 'btn-link';
      btn.textContent = truncate(post.title, 28);
      btn.addEventListener('click', () => viewPost(post.id));
      tdPost.appendChild(btn);
    } else {
      tdPost.textContent = truncate(r.postId, 20) || '—';
    }

    const tdOwner = document.createElement('td');
    if (owner) {
      const btn = document.createElement('button');
      btn.className = 'btn-link';
      btn.textContent = owner.fullName || owner.email || '—';
      btn.addEventListener('click', () => viewUser(owner.uid));
      tdOwner.appendChild(btn);
    } else {
      tdOwner.textContent = '—';
    }

    const tdMsg    = document.createElement('td'); tdMsg.textContent    = truncate(r.message, 35);
    const tdStatus = document.createElement('td'); tdStatus.innerHTML   = statusBadge(r.status);
    const tdDate   = document.createElement('td'); tdDate.textContent   = formatDate(r.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnView = document.createElement('button');
    btnView.className = 'btn btn-view';
    btnView.textContent = 'Xem';
    btnView.addEventListener('click', () => viewRequest(r.id));

    const btnDel = document.createElement('button');
    btnDel.className = 'btn btn-del';
    btnDel.title = 'Xóa';
    btnDel.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M9 6V4h6v2"/></svg>';
    btnDel.addEventListener('click', () => {
      showConfirmModal('Xóa yêu cầu', 'Xóa yêu cầu này? Hành động không thể hoàn tác.', () => deleteRequest(r.id));
    });

    tdActions.append(btnView, btnDel);
    tr.append(tdSender, tdPost, tdOwner, tdMsg, tdStatus, tdDate, tdActions);
    tbody.appendChild(tr);
  });

  renderPagination('requestsPagination', 'requests', data.length, renderRequestsSection);
}

async function deleteRequest(id) {
  try {
    await deleteDoc(doc(db, 'roommate_requests', id));
    state.requests = state.requests.filter(r => r.id !== id);
    updateBadges();
    renderRequestsSection();
    showToast('Đã xóa yêu cầu', 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

function viewRequest(id) {
  const r = state.requests.find(x => x.id === id);
  if (!r) return;
  const post  = state.posts.find(p => p.id === r.postId);
  const owner = post ? state.users.find(u => u.uid === post.userId) : null;

  const adminActions = r.status === 'pending' ? `
    <div class="modal-section-label" style="color:var(--danger);">Can thiệp Admin</div>
    <div style="display:flex;gap:8px;margin-top:8px;" id="reqAdminActions">
      <button class="btn btn-success" id="btnForceAccept">✓ Buộc chấp nhận</button>
      <button class="btn btn-danger" id="btnForceReject">✕ Buộc từ chối</button>
    </div>` : '';

  openModal(`
    <div class="modal-title">Chi tiết yêu cầu ghép phòng</div>
    <div class="modal-section-label">Người gửi</div>
    <div class="detail-block">
      ${makeAvatar(r.requesterAvatar, r.requesterName)}
      <div>
        <div style="font-weight:600;">${escapeHtml(r.requesterName || r.requesterId || '—')}</div>
      </div>
    </div>
    <div class="modal-section-label">Bài đăng liên quan</div>
    ${post ? `<div style="font-weight:600;margin-bottom:4px;">${escapeHtml(post.title || '—')}</div><div style="color:var(--text-2);font-size:12px;">${escapeHtml([post.district, post.province].filter(Boolean).join(', '))} · ${escapeHtml(formatPrice(post.price))}</div>` : `<span style="color:var(--text-2);">${escapeHtml(r.postId || '—')}</span>`}
    <div class="modal-section-label">Chủ bài đăng</div>
    <div class="detail-block">
      ${owner ? makeAvatar(owner.avatarUrl, owner.fullName) : ''}
      <div>${owner ? `<div style="font-weight:600;">${escapeHtml(owner.fullName || '—')}</div><div style="color:var(--text-2);font-size:12px;">${escapeHtml(owner.email || '')}</div>` : '<span style="color:var(--text-2);">—</span>'}</div>
    </div>
    <div class="modal-section-label">Thông tin yêu cầu</div>
    ${modalRow('Tin nhắn', escapeHtml(r.message || '—'))}
    ${modalRow('Trạng thái', statusBadge(r.status))}
    ${modalRow('Ngày gửi', escapeHtml(formatDate(r.createdAt)))}
    ${modalRow('Ngày phản hồi', escapeHtml(r.respondedAt ? formatDate(r.respondedAt) : '—'))}
    ${adminActions}
  `);

  if (r.status === 'pending') {
    document.getElementById('btnForceAccept')?.addEventListener('click', () => {
      showConfirmModal('Buộc chấp nhận', 'Admin sẽ buộc chấp nhận yêu cầu này và tạo nhóm phòng.', () => adminForceAccept(r.id));
    });
    document.getElementById('btnForceReject')?.addEventListener('click', () => {
      showConfirmModal('Buộc từ chối', 'Admin sẽ buộc từ chối yêu cầu này.', () => adminForceReject(r.id));
    });
  }
}

async function adminForceAccept(id) {
  const r = state.requests.find(x => x.id === id);
  if (!r) return;
  try {
    await updateDoc(doc(db, 'roommate_requests', id), {
      status: 'accepted',
      respondedAt: serverTimestamp(),
      adminOverride: true,
    });
    await addDoc(collection(db, 'room_groups'), {
      members:   [r.requesterId, r.targetUserId].filter(Boolean),
      postId:    r.postId || null,
      createdAt: serverTimestamp(),
      status:    'active',
      createdBy: 'admin',
    });
    const idx = state.requests.findIndex(x => x.id === id);
    if (idx >= 0) { state.requests[idx].status = 'accepted'; state.requests[idx].respondedAt = new Date(); }
    closeModal();
    updateBadges();
    renderRequestsSection();
    showToast('Đã buộc chấp nhận và tạo nhóm phòng', 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

async function adminForceReject(id) {
  try {
    await updateDoc(doc(db, 'roommate_requests', id), {
      status: 'rejected',
      respondedAt: serverTimestamp(),
      adminOverride: true,
    });
    const idx = state.requests.findIndex(x => x.id === id);
    if (idx >= 0) { state.requests[idx].status = 'rejected'; state.requests[idx].respondedAt = new Date(); }
    closeModal();
    updateBadges();
    renderRequestsSection();
    showToast('Đã buộc từ chối yêu cầu', 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

// ===== GROUPS =====
function filterGroups() {
  const q      = (document.getElementById('searchGroups')?.value || '').toLowerCase();
  const status = document.getElementById('filterGroupStatus')?.value || '';

  return state.groups.filter(g => {
    const matchQ      = (g.id || '').toLowerCase().includes(q) || (g.postId || '').toLowerCase().includes(q);
    const matchStatus = !status || (g.status || 'active') === status;
    return matchQ && matchStatus;
  });
}

function renderGroupsSection() {
  const data  = filterGroups();
  const page  = pageSlice(data, 'groups');
  const tbody = document.getElementById('groupsTable');
  if (!tbody) return;

  if (!page.length) {
    tbody.innerHTML = emptyRow(7, data.length === 0 ? 'Không có nhóm phòng nào' : 'Không có kết quả phù hợp');
    renderPagination('groupsPagination', 'groups', data.length, renderGroupsSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(g => {
    const members  = Array.isArray(g.members) ? g.members : [];
    const post     = state.posts.find(p => p.id === g.postId);
    const gStatus  = g.status || 'active';

    const tr = document.createElement('tr');

    const tdId      = document.createElement('td'); tdId.innerHTML      = `<span class="mono" style="font-size:11px;color:var(--text-2);">${escapeHtml(g.id.slice(0, 12))}…</span>`;
    const tdMembers = document.createElement('td'); tdMembers.innerHTML  = `<span class="mono">${members.length} thành viên</span>`;

    const tdPost = document.createElement('td');
    if (post) {
      const btn = document.createElement('button');
      btn.className = 'btn-link';
      btn.textContent = truncate(post.title, 30);
      btn.addEventListener('click', () => viewPost(post.id));
      tdPost.appendChild(btn);
    } else {
      tdPost.innerHTML = `<span style="color:var(--text-2);font-size:12px;">${escapeHtml(g.postId ? g.postId.slice(0, 16) + '…' : '—')}</span>`;
    }

    const tdStatus    = document.createElement('td'); tdStatus.innerHTML    = statusBadge(gStatus);
    const tdCreatedBy = document.createElement('td'); tdCreatedBy.textContent = g.createdBy || '—';
    const tdDate      = document.createElement('td'); tdDate.textContent      = formatDate(g.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnView = document.createElement('button');
    btnView.className = 'btn btn-view';
    btnView.textContent = 'Chi tiết';
    btnView.addEventListener('click', () => viewGroup(g.id));

    const btnToggleGroup = document.createElement('button');
    btnToggleGroup.className = gStatus === 'active' ? 'btn btn-warn' : 'btn btn-success';
    btnToggleGroup.textContent = gStatus === 'active' ? 'Vô hiệu' : 'Kích hoạt';
    btnToggleGroup.addEventListener('click', () => {
      const newStatus = gStatus === 'active' ? 'inactive' : 'active';
      showConfirmModal(
        gStatus === 'active' ? 'Vô hiệu hóa nhóm' : 'Kích hoạt nhóm',
        `${gStatus === 'active' ? 'Vô hiệu hóa' : 'Kích hoạt'} nhóm phòng này?`,
        () => toggleGroupStatus(g.id, newStatus)
      );
    });

    const btnDelGroup = document.createElement('button');
    btnDelGroup.className = 'btn btn-del';
    btnDelGroup.title = 'Xóa nhóm';
    btnDelGroup.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
    btnDelGroup.addEventListener('click', () => {
      showConfirmModal('Xóa nhóm phòng', 'Xóa nhóm phòng này? Hành động không thể hoàn tác.', () => deleteGroup(g.id));
    });

    tdActions.append(btnView, btnToggleGroup, btnDelGroup);
    tr.append(tdId, tdMembers, tdPost, tdStatus, tdCreatedBy, tdDate, tdActions);
    tbody.appendChild(tr);
  });

  renderPagination('groupsPagination', 'groups', data.length, renderGroupsSection);
}

async function deleteGroup(id) {
  try {
    await deleteDoc(doc(db, 'room_groups', id));
    state.groups = state.groups.filter(x => x.id !== id);
    updateBadges();
    renderGroupsSection();
    showToast('Đã xóa nhóm phòng', 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

async function toggleGroupStatus(id, newStatus) {
  try {
    await updateDoc(doc(db, 'room_groups', id), { status: newStatus });
    const g = state.groups.find(x => x.id === id);
    if (g) g.status = newStatus;
    updateBadges();
    renderGroupsSection();
    showToast(`Đã ${newStatus === 'active' ? 'kích hoạt' : 'vô hiệu hóa'} nhóm phòng`, 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

function viewGroup(id) {
  const g = state.groups.find(x => x.id === id);
  if (!g) return;
  const members = Array.isArray(g.members) ? g.members : [];
  const memberNames = members.map(uid => {
    const u = state.users.find(x => x.uid === uid);
    return u ? `<div class="detail-block">${makeAvatar(u.avatarUrl, u.fullName)}<div><div style="font-weight:600;">${escapeHtml(u.fullName || '—')}</div><div style="font-size:11px;color:var(--text-2);">${escapeHtml(u.email || uid)}</div></div></div>` : `<div style="color:var(--text-2);font-size:12px;">${escapeHtml(uid)}</div>`;
  }).join('') || '<span style="color:var(--text-2);">Không có thành viên</span>';

  const post = state.posts.find(p => p.id === g.postId);

  openModal(`
    <div class="modal-title">Chi tiết nhóm phòng</div>
    ${modalRow('ID', `<span class="mono" style="font-size:12px;">${escapeHtml(g.id)}</span>`)}
    ${modalRow('Trạng thái', statusBadge(g.status || 'active'))}
    ${modalRow('Bài đăng', post ? escapeHtml(post.title || g.postId) : escapeHtml(g.postId || '—'))}
    ${modalRow('Tạo bởi', escapeHtml(g.createdBy || '—'))}
    ${modalRow('Ngày tạo', escapeHtml(formatDate(g.createdAt)))}
    <div class="modal-section-label">Thành viên (${members.length})</div>
    ${memberNames}
  `);
}

// ===== REPORTS =====
function filterReports() {
  const q      = (document.getElementById('searchReports')?.value || '').toLowerCase();
  const status = document.getElementById('filterReportStatus')?.value || '';

  return state.reports.filter(r => {
    const matchQ      = (r.reason || '').toLowerCase().includes(q) || (r.reporterId || '').toLowerCase().includes(q);
    const rStatus     = r.status || 'pending';
    const matchStatus = !status || rStatus === status;
    return matchQ && matchStatus;
  });
}

function renderReportsSection() {
  const data  = filterReports();
  const page  = pageSlice(data, 'reports');
  const tbody = document.getElementById('reportsTable');
  if (!tbody) return;

  if (!page.length) {
    tbody.innerHTML = emptyRow(6, data.length === 0 ? 'Không có báo cáo nào' : 'Không có kết quả phù hợp');
    renderPagination('reportsPagination', 'reports', data.length, renderReportsSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(r => {
    const reporter = state.users.find(u => u.uid === r.reporterId);
    const reported = state.users.find(u => u.uid === r.targetId) || state.posts.find(p => p.id === r.targetId);
    const rStatus  = r.status || 'pending';

    const tr = document.createElement('tr');

    const tdReporter = document.createElement('td');
    tdReporter.innerHTML = reporter
      ? `<div class="user-cell">${makeAvatar(reporter.avatarUrl, reporter.fullName)}<span>${escapeHtml(reporter.fullName || reporter.email || r.reporterId || '—')}</span></div>`
      : `<span style="color:var(--text-2);">${escapeHtml(r.reporterId ? r.reporterId.slice(0, 12) + '…' : '—')}</span>`;

    const tdTarget = document.createElement('td');
    if (reported) {
      tdTarget.textContent = reported.fullName || reported.title || reported.email || r.targetId || '—';
    } else {
      tdTarget.innerHTML = `<span style="color:var(--text-2);font-size:12px;">${escapeHtml(r.targetId ? r.targetId.slice(0, 16) + '…' : '—')}</span>`;
    }

    const tdReason = document.createElement('td'); tdReason.textContent = truncate(r.reason, 40);
    const tdStatus = document.createElement('td'); tdStatus.innerHTML   = statusBadge(rStatus);
    const tdDate   = document.createElement('td'); tdDate.textContent   = formatDate(r.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnViewReport = document.createElement('button');
    btnViewReport.className = 'btn btn-view';
    btnViewReport.textContent = 'Chi tiết';
    btnViewReport.addEventListener('click', () => viewReport(r.id));
    tdActions.appendChild(btnViewReport);

    if (rStatus === 'pending') {
      const btnResolve = document.createElement('button');
      btnResolve.className = 'btn btn-success';
      btnResolve.textContent = 'Đã xử lý';
      btnResolve.addEventListener('click', () => updateReportStatus(r.id, 'resolved'));

      const btnDismiss = document.createElement('button');
      btnDismiss.className = 'btn btn-ghost';
      btnDismiss.textContent = 'Bỏ qua';
      btnDismiss.addEventListener('click', () => updateReportStatus(r.id, 'dismissed'));

      tdActions.append(btnResolve, btnDismiss);
    }

    const btnDelReport = document.createElement('button');
    btnDelReport.className = 'btn btn-del';
    btnDelReport.title = 'Xóa báo cáo';
    btnDelReport.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
    btnDelReport.addEventListener('click', () => {
      showConfirmModal('Xóa báo cáo', 'Xóa báo cáo này? Hành động không thể hoàn tác.', () => deleteReport(r.id));
    });
    tdActions.appendChild(btnDelReport);

    tr.append(tdReporter, tdTarget, tdReason, tdStatus, tdDate, tdActions);
    tbody.appendChild(tr);
  });

  renderPagination('reportsPagination', 'reports', data.length, renderReportsSection);
}

function viewReport(id) {
  const r = state.reports.find(x => x.id === id);
  if (!r) return;
  const reporter = state.users.find(u => u.uid === r.reporterId);
  const reported = state.users.find(u => u.uid === r.targetId) || state.posts.find(p => p.id === r.targetId);
  const rStatus  = r.status || 'pending';

  const actionBlock = `
    <div class="modal-section-label" style="color:var(--danger);">Hành động Admin</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px;">
      ${rStatus === 'pending' ? `
        <button class="btn btn-success" id="btnModalResolve">✓ Đã xử lý</button>
        <button class="btn btn-ghost"   id="btnModalDismiss">Bỏ qua</button>` : ''}
      <button class="btn btn-del" id="btnModalDelReport">Xóa báo cáo</button>
    </div>`;

  openModal(`
    <div class="modal-title">Chi tiết báo cáo</div>
    <div class="modal-section-label">Người báo cáo</div>
    <div class="detail-block">
      ${reporter ? makeAvatar(reporter.avatarUrl, reporter.fullName) : ''}
      <div>${reporter
        ? `<div style="font-weight:600;">${escapeHtml(reporter.fullName || '—')}</div><div style="font-size:11px;color:var(--text-2);">${escapeHtml(reporter.email || '')}</div>`
        : `<span style="color:var(--text-2);">${escapeHtml(r.reporterId ? r.reporterId.slice(0, 16) + '…' : '—')}</span>`}
      </div>
    </div>
    <div class="modal-section-label">Đối tượng bị báo cáo</div>
    <div style="margin-bottom:12px;">
      ${reported
        ? `<div style="font-weight:600;">${escapeHtml(reported.fullName || reported.title || reported.email || r.targetId || '—')}</div>`
        : `<span style="color:var(--text-2);">${escapeHtml(r.targetId ? r.targetId.slice(0, 16) + '…' : '—')}</span>`}
    </div>
    ${modalRow('Lý do', escapeHtml(r.reason || '—'))}
    ${modalRow('Trạng thái', statusBadge(rStatus))}
    ${modalRow('Ngày gửi', escapeHtml(formatDate(r.createdAt)))}
    ${actionBlock}
  `);

  if (rStatus === 'pending') {
    document.getElementById('btnModalResolve')?.addEventListener('click', () => {
      closeModal();
      updateReportStatus(r.id, 'resolved');
    });
    document.getElementById('btnModalDismiss')?.addEventListener('click', () => {
      closeModal();
      updateReportStatus(r.id, 'dismissed');
    });
  }
  document.getElementById('btnModalDelReport')?.addEventListener('click', () => {
    showConfirmModal('Xóa báo cáo', 'Xóa báo cáo này? Hành động không thể hoàn tác.', () => {
      closeModal();
      deleteReport(r.id);
    });
  });
}

async function deleteReport(id) {
  try {
    await deleteDoc(doc(db, 'reports', id));
    state.reports = state.reports.filter(x => x.id !== id);
    updateBadges();
    renderReportsSection();
    showToast('Đã xóa báo cáo', 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

async function updateReportStatus(id, newStatus) {
  try {
    await updateDoc(doc(db, 'reports', id), { status: newStatus });
    const r = state.reports.find(x => x.id === id);
    if (r) r.status = newStatus;
    updateBadges();
    renderReportsSection();
    showToast(`Đã đánh dấu báo cáo: ${newStatus === 'resolved' ? 'Đã xử lý' : 'Bỏ qua'}`, 'success');
  } catch (e) {
    showToast('Lỗi: ' + e.message, 'error');
  }
}

// ===== CHARTS =====
let charts = {};

function renderCharts(users, posts, requests) {
  Object.values(charts).forEach(c => c?.destroy());
  charts = {};
  renderLineChart(users);
  renderDoughnutChart(posts);
  window.addEventListener('resize', handleResize);
}

let resizeTimer;
function handleResize() {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(() => {
    renderCharts(state.users, state.posts, state.requests);
  }, 300);
}

const CHART_GRID_COLOR = '#E5EAF2';
const CHART_TEXT_COLOR = '#8A94A6';

function chartDefaults() {
  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { labels: { color: CHART_TEXT_COLOR, font: { family: "'DM Sans'", size: 12 }, boxWidth: 12 } },
      tooltip: { backgroundColor: '#111827', titleColor: '#ffffff', bodyColor: '#D1D5DB', borderColor: '#374151', borderWidth: 1, cornerRadius: 8, padding: 10 },
    },
  };
}

function renderLineChart(users) {
  const ctx = document.getElementById('chartUsersByMonth');
  if (!ctx) return;

  const now = new Date();
  const labels = [];
  const counts = [];

  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    labels.push(d.toLocaleString('vi-VN', { month: 'short', year: '2-digit' }));
    const c = users.filter(u => {
      const ud = toDate(u.createdAt);
      return ud && ud.getFullYear() === d.getFullYear() && ud.getMonth() === d.getMonth();
    }).length;
    counts.push(c);
  }

  charts.line = new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: 'Người dùng mới',
        data: counts,
        borderColor: '#2F6BFF',
        backgroundColor: 'rgba(47,107,255,0.08)',
        fill: true,
        tension: 0.4,
        pointBackgroundColor: '#2F6BFF',
        pointRadius: 4,
        pointHoverRadius: 6,
        borderWidth: 2,
      }],
    },
    options: {
      ...chartDefaults(),
      scales: {
        x: { grid: { color: CHART_GRID_COLOR }, ticks: { color: CHART_TEXT_COLOR, font: { size: 11 } } },
        y: { beginAtZero: true, grid: { color: CHART_GRID_COLOR }, ticks: { color: CHART_TEXT_COLOR, font: { size: 11 }, stepSize: 1 } },
      },
    },
  });
}

function renderDoughnutChart(posts) {
  const ctx = document.getElementById('chartPostsByStatus');
  if (!ctx) return;

  const counts = {
    active:  posts.filter(p => p.status === 'active').length,
    pending: posts.filter(p => !p.status || p.status === 'pending').length,
    hidden:  posts.filter(p => p.status === 'hidden').length,
  };

  charts.donut = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: ['Đang hiển thị', 'Chờ duyệt', 'Đã ẩn'],
      datasets: [{
        data: [counts.active, counts.pending, counts.hidden],
        backgroundColor: ['#22c55e', '#f59e0b', '#8b8fa8'],
        borderWidth: 0,
        hoverOffset: 6,
      }],
    },
    options: {
      ...chartDefaults(),
      cutout: '65%',
      plugins: {
        ...chartDefaults().plugins,
        legend: { position: 'bottom', labels: { color: CHART_TEXT_COLOR, padding: 16, font: { family: "'DM Sans'", size: 12 }, boxWidth: 12 } },
      },
    },
  });
}

// expose for potential external use
window.renderCharts = renderCharts;
