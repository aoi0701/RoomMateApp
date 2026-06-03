// ===== FIREBASE IMPORTS (v10.7.1 CDN) =====
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
import {
  getAuth, signInWithEmailAndPassword, signOut, onAuthStateChanged
} from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
import {
  getFirestore, collection, getDocs, deleteDoc, doc, getDoc,
  updateDoc, addDoc, query, orderBy, serverTimestamp, where, setDoc,
  onSnapshot
} from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';

// ===== FIREBASE INIT =====
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
const HABITS_MAP = {
  stay_up_late:   'Thức khuya',
  early_bird:     'Dậy sớm',
  has_pet:        'Có thú cưng',
  pet_friendly:   'Thân thiện với thú cưng',
  no_pet:         'Không nuôi thú cưng',
  neat:           'Ngăn nắp, gọn gàng',
  messy:          'Lộn xộn',
  like_gathering: 'Thích tụ tập',
  less_partying:  'Ít tiệc tùng',
  quiet:          'Thích yên tĩnh',
  social:         'Hòa đồng, năng động',
  smoke:          'Hút thuốc',
  no_smoke:       'Không hút thuốc',
  drink:          'Uống rượu bia',
  no_drink:       'Không uống rượu bia',
  exercise:       'Tập thể dục',
  vegetarian:     'Ăn chay',
  cook:           'Thích nấu ăn',
  no_cook:        'Không nấu ăn',
  work_from_home: 'Làm việc tại nhà',
  night_shift:    'Làm ca đêm',
  introvert:      'Hướng nội',
  extrovert:      'Hướng ngoại',
};

function habitLabel(key) {
  return HABITS_MAP[key] || key.replace(/_/g, ' ');
}

const state = {
  users:         [],
  posts:         [],
  requests:      [],
  groups:        [],
  expenses:      [],
  expenseShares: [],
  filters: {
    users:    { q: '', role: '', status: '' },
    posts:    { q: '', status: '', province: '' },
    requests: { q: '', status: '' },
    groups:   { q: '', status: '' },
    expenses: { q: '', groupId: '' },
  },
  currentPage: {
    users: 1, posts: 1, requests: 1, groups: 1, expenses: 1
  },
  sort: {
    users:  { col: '', dir: 1 },
    posts:  { col: '', dir: 1 },
    expenses: { col: '', dir: 1 },
  },
};

const PAGE_SIZE = 25;

// ===== CHARTS GLOBAL =====
const charts = {};
const chartDefaults = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { labels: { color: '#64748B', font: { family: 'Plus Jakarta Sans', size: 12 } } },
    tooltip: { backgroundColor: '#0F172A', titleColor: '#fff', bodyColor: '#94A3B8', cornerRadius: 8 }
  }
};

function destroyChart(key) {
  if (charts[key]) {
    charts[key].destroy();
    charts[key] = null;
  }
}

function debounce(fn, ms) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  };
}

// =====================================================================
//  1. HELPERS
// =====================================================================

function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

function formatDate(d) {
  if (!d) return '—';
  const date = d?.toDate ? d.toDate() : new Date(d);
  if (isNaN(date)) return '—';
  return date.toLocaleDateString('vi-VN', {
    day: '2-digit', month: '2-digit', year: 'numeric'
  });
}

function formatMoney(num) {
  if (num === null || num === undefined) return '—';
  const n = typeof num === 'number' ? num : Number(num);
  if (isNaN(n)) return '—';
  return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + '\u0111';
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
  return s.length > len ? s.slice(0, len) + '\u2026' : s;
}

function toDate(val) {
  if (!val) return null;
  if (val?.toDate) return val.toDate();
  if (val instanceof Date) return val;
  const d = new Date(val);
  return isNaN(d) ? null : d;
}

function statusBadge(status) {
  const map = {
    pending:   ['badge-pending',   '\u0110ang ch\u1edd'],
    accepted:  ['badge-accepted',  'Ch\u1ea5p nh\u1eadn'],
    rejected:  ['badge-rejected',  'T\u1eeb ch\u1ed1i'],
    active:    ['badge-active',    'Ho\u1ea1t \u0111\u1ed9ng'],
    hidden:    ['badge-hidden',    '\u0110\xe3 \u1ea9n'],
    sold:      ['badge-sold',      'H\u1ebft ph\xf2ng'],
    blocked:   ['badge-blocked',   '\u0110\xe3 kh\xf3a'],
    resolved:  ['badge-resolved',  '\u0110\xe3 x\u1eed l\xfd'],
    dismissed: ['badge-dismissed', 'B\u1ecf qua'],
    inactive:  ['badge-inactive',  'Kh\xf4ng H\u0110'],
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

// =====================================================================
//  2. PAGINATION
// =====================================================================

function renderPagination(containerId, section, total, onPage) {
  const el = document.getElementById(containerId);
  if (!el) return;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const cur = state.currentPage[section];
  if (totalPages <= 1) { el.innerHTML = ''; return; }

  el.innerHTML = '';
  const prev = document.createElement('button');
  prev.textContent = '\u2190 Tr\u01b0\u1edbc';
  prev.disabled = cur <= 1;
  prev.addEventListener('click', () => { state.currentPage[section] = cur - 1; onPage(); });

  const info = document.createElement('span');
  info.className = 'page-info';
  info.textContent = `Trang ${cur} / ${totalPages}  (${total} m\u1ee5c)`;

  const next = document.createElement('button');
  next.textContent = 'Ti\u1ebfp \u2192';
  next.disabled = cur >= totalPages;
  next.addEventListener('click', () => { state.currentPage[section] = cur + 1; onPage(); });

  el.append(prev, info, next);
}

function pageSlice(arr, section) {
  const p = state.currentPage[section] || 1;
  return arr.slice((p - 1) * PAGE_SIZE, p * PAGE_SIZE);
}

// =====================================================================
//  3. TOAST
// =====================================================================

function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const t = document.createElement('div');
  t.className = `toast toast-${type}`;
  t.innerHTML = `<span class="toast-dot"></span><span>${escapeHtml(message)}</span>`;
  container.appendChild(t);

  setTimeout(() => {
    t.classList.add('removing');
    setTimeout(() => t.remove(), 300);
  }, 3000);
}

// =====================================================================
//  4. MODAL
// =====================================================================

function openModal(html) {
  document.getElementById('modalContent').innerHTML = html;
  document.getElementById('modal').hidden = false;
}

function closeModal() {
  document.getElementById('modal').hidden = true;
  document.getElementById('modalContent').innerHTML = '';
}

function showConfirmModal(title, message, onConfirm) {
  const modal = document.getElementById('confirmModal');
  document.getElementById('confirmTitle').textContent = title;
  document.getElementById('confirmMessage').textContent = message;
  modal.hidden = false;

  const close = () => { modal.hidden = true; };

  const ok     = document.getElementById('confirmOk');
  const cancel = document.getElementById('confirmCancel');

  const okClone = ok.cloneNode(true);
  ok.parentNode.replaceChild(okClone, ok);
  const cancelClone = cancel.cloneNode(true);
  cancel.parentNode.replaceChild(cancelClone, cancel);

  document.getElementById('confirmOk').addEventListener('click', () => { close(); onConfirm(); });
  document.getElementById('confirmCancel').addEventListener('click', close);
  modal.addEventListener('click', (e) => { if (e.target === modal) close(); }, { once: true });
}

// =====================================================================
//  5. AUTH
// =====================================================================

function parseAuthError(code) {
  const map = {
    'auth/user-not-found':      'Email kh\xf4ng t\u1ed3n t\u1ea1i.',
    'auth/wrong-password':      'M\u1eadt kh\u1ea9u kh\xf4ng \u0111\xfang.',
    'auth/invalid-email':       'Email kh\xf4ng h\u1ee3p l\u1ec7.',
    'auth/too-many-requests':   'Qu\xe1 nhi\u1ec1u l\u1ea7n th\u1eed. Th\u1eed l\u1ea1i sau.',
    'auth/invalid-credential':  'Email ho\u1eb7c m\u1eadt kh\u1ea9u kh\xf4ng \u0111\xfang.',
    'auth/user-disabled':       'T\xe0i kho\u1ea3n \u0111\xe3 b\u1ecb v\xf4 hi\u1ec7u h\xf3a.',
    'auth/network-request-failed': 'L\u1ed7i m\u1ea1ng. Vui l\xf2ng ki\u1ec3m tra k\u1ebft n\u1ed1i.',
  };
  return map[code] || '\u0110\u0103ng nh\u1eadp th\u1ea5t b\u1ea1i. Vui l\xf2ng th\u1eed l\u1ea1i.';
}

function showLoginError(msg) {
  const el = document.getElementById('loginError');
  el.textContent = msg;
  el.hidden = false;
}

function showLoginPage(clearError = true) {
  document.getElementById('loginPage').hidden = false;
  document.getElementById('dashboardPage').hidden = true;
  document.getElementById('loginBtnText').hidden = false;
  document.getElementById('loginSpinner').hidden = true;
  if (clearError) document.getElementById('loginError').hidden = true;
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

// =====================================================================
//  6. NAVIGATION
// =====================================================================

const SECTION_TITLES = {
  dashboard: 'Dashboard',
  users:     'Ng\u01b0\u1eddi d\xf9ng',
  posts:     'B\xe0i \u0111\u0103ng',
  requests:  'Y\xeau c\u1ea7u gh\xe9p ph\xf2ng',
  groups:    'Nh\xf3m ph\xf2ng',
  expenses:  'Chi ti\xeau nh\xf3m',
  reports:   'B\xe1o c\xe1o vi ph\u1ea1m',
  analytics: 'Th\u1ed1ng k\xea & ph\xe2n t\xedch',
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

function closeSidebar() {
  if (window.innerWidth > 768) return;
  document.getElementById('sidebar').classList.remove('open');
  document.getElementById('sidebarOverlay').classList.remove('open');
}

// =====================================================================
//  7. DATA LOADING
// =====================================================================

// ===== REAL-TIME LISTENERS =====
const _unsubs = {};

function listenCollection(colName, orderField, onUpdate) {
  if (_unsubs[colName]) _unsubs[colName]();
  const q = query(collection(db, colName), orderBy(orderField, 'desc'));
  _unsubs[colName] = onSnapshot(q,
    snap => onUpdate(snap.docs.map(d => ({ id: d.id, ...d.data() }))),
    err  => console.error('snapshot ' + colName + ':', err)
  );
}

function stopAllListeners() {
  Object.values(_unsubs).forEach(fn => fn && fn());
  Object.keys(_unsubs).forEach(k => delete _unsubs[k]);
}

function updateBadges() {
  const set = (id, val) => {
    const el = document.getElementById(id);
    if (el) el.textContent = val;
  };
  set('badgeUsers',    state.users.filter(u => !u.deleted && !u.isDeleted).length);
  set('badgePosts',    state.posts.length);
  set('badgeRequests', state.requests.filter(r => r.status === 'pending').length);
  set('badgeGroups',   state.groups.length);
  set('badgeExpenses', state.expenseShares.filter(s => !s.isPaid && s.isArchived !== true).length);
}

function _rerender() {
  buildProvinceFilter();
  buildGroupFilter();
  updateBadges();
  renderDashboard();
  renderUsersSection();
  renderPostsSection();
  renderRequestsSection();
  renderGroupsSection();
  renderExpensesSection();
  try { renderCharts(); } catch (e) { console.warn(e); }
  try { renderAnalytics(); } catch (e) { console.warn(e); }
}
const _rerenderDebounced = debounce(_rerender, 350);

function loadAllData() {
  showToast('\u0110ang k\u1ebft n\u1ed1i d\u1eef li\u1ec7u th\u1eddi gian th\u1ef1c\u2026', 'warning');
  const _loaded = new Set();
  const TOTAL = 6;

  function onUpdate(key, updateFn) {
    return docs => {
      updateFn(docs);
      const isFirst = !_loaded.has(key);
      _loaded.add(key);
      if (isFirst && _loaded.size === TOTAL) {
        _rerender();
        showToast('K\u1ebft n\u1ed1i th\u1eddi gian th\u1ef1c th\u00e0nh c\u00f4ng', 'success');
      } else if (!isFirst) {
        _rerenderDebounced();
      }
    };
  }

  listenCollection('users', 'createdAt', onUpdate('users', docs => {
    state.users = docs.map(d => ({ ...d, uid: d.id }));
  }));
  listenCollection('posts', 'createdAt', onUpdate('posts', docs => {
    state.posts = docs;
  }));
  listenCollection('roommate_requests', 'createdAt', onUpdate('requests', docs => {
    state.requests = docs;
  }));
  listenCollection('room_groups', 'createdAt', onUpdate('groups', docs => {
    state.groups = docs;
  }));
  listenCollection('expenses', 'createdAt', onUpdate('expenses', docs => {
    state.expenses = docs;
  }));
  listenCollection('expense_shares', 'createdAt', onUpdate('expenseShares', docs => {
    state.expenseShares = docs.filter(s => s.isArchived !== true);
  }));
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

// ===== EXPENSE GROUP FILTER =====
function buildGroupFilter() {
  const sel = document.getElementById('filterExpenseGroup');
  if (!sel) return;
  while (sel.options.length > 1) sel.remove(1);
  state.groups.forEach(g => {
    const opt = document.createElement('option');
    opt.value = g.id;
    opt.textContent = g.name || g.id.slice(0, 12) + '\u2026';
    sel.appendChild(opt);
  });
}

// =====================================================================
//  8. EVENT BINDING
// =====================================================================

function bindFilterEvents(section, renderFn) {
  const ids = {
    users:    ['searchUsers', 'filterUserRole', 'filterUserStatus', 'clearUsersFilter'],
    posts:    ['searchPosts', 'filterPostStatus', null, 'clearPostsFilter'],
    requests: ['searchRequests', 'filterReqStatus', null, 'clearRequestsFilter'],
    groups:   ['searchGroups', 'filterGroupStatus', null, 'clearGroupsFilter'],
    expenses: ['searchExpenses', 'filterExpenseGroup', null, 'clearExpensesFilter'],
    reports:  ['searchReports', 'filterReportStatus', 'filterReportTargetType', 'clearReportsFilter'],
  };
  const [searchId, filter1Id, filter2Id, clearId] = ids[section] || [];
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
    showConfirmModal(
      '\u0110\u0103ng xu\u1ea5t',
      'B\u1ea1n c\xf3 ch\u1eafc mu\u1ed1n \u0111\u0103ng xu\u1ea5t kh\xf4ng?',
      async () => { stopAllListeners(); await signOut(auth); showLoginPage(); }
    );
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
    el.addEventListener('click', (e) => {
      e.preventDefault();
      const section = el.dataset.section;
      showSection(section);
      if (section === 'analytics') {
        try { renderAnalytics(); } catch (e) { console.warn(e); }
      }
    });
  });

  // Modal close
  document.getElementById('modalClose')?.addEventListener('click', closeModal);
  document.getElementById('modal')?.addEventListener('click', (e) => {
    if (e.target === document.getElementById('modal')) closeModal();
  });

  // Section filters
  bindFilterEvents('users',    renderUsersSection);
  bindFilterEvents('posts',    renderPostsSection);
  bindFilterEvents('requests', renderRequestsSection);
  bindFilterEvents('groups',   renderGroupsSection);
  bindFilterEvents('expenses', renderExpensesSection);

  // Province filter (extra)
  document.getElementById('filterPostProvince')?.addEventListener('change', () => {
    state.currentPage.posts = 1;
    renderPostsSection();
  });

  // Sort handlers
  document.querySelectorAll('#usersTableEl th[data-col]').forEach(th => {
    th.addEventListener('click', () => {
      sortAndRender('users', th.dataset.col, renderUsersSection);
    });
  });
  document.querySelectorAll('#postsTableEl th[data-col]').forEach(th => {
    th.addEventListener('click', () => {
      sortAndRender('posts', th.dataset.col, renderPostsSection);
    });
  });
  document.querySelectorAll('#expensesTableEl th[data-col]').forEach(th => {
    th.addEventListener('click', () => {
      sortAndRender('expenses', th.dataset.col, renderExpensesSection);
    });
  });
}

function sortAndRender(section, col, renderFn) {
  const s = state.sort[section];
  if (!s) return;
  if (s.col === col) {
    s.dir *= -1;
  } else {
    s.col = col;
    s.dir = 1;
  }
  state.currentPage[section] = 1;
  renderFn();
}

function updateSortIcons(tableId, section) {
  document.querySelectorAll(`${tableId} th[data-col]`).forEach(th => {
    const icon = th.querySelector('.sort-icon');
    if (!icon) return;
    const s = state.sort[section];
    if (s && th.dataset.col === s.col) {
      icon.textContent = s.dir === 1 ? '\u2191' : '\u2193';
      icon.style.opacity = '1';
    } else {
      icon.textContent = '\u2195';
      icon.style.opacity = '.45';
    }
  });
}

// =====================================================================
//  INIT
// =====================================================================

document.addEventListener('DOMContentLoaded', () => {
  updateHeaderDate();
  bindStaticEvents();

  let pendingError = '';
  let sessionReady = false;

  onAuthStateChanged(auth, async (user) => {
    if (!user) {
      sessionReady = false;
      showLoginPage(!pendingError);
      if (pendingError) {
        showLoginError(pendingError);
        pendingError = '';
      }
      return;
    }

    // Firebase fires onAuthStateChanged on every token refresh \u2014 only init once
    if (sessionReady) return;

    try {
      const snap = await getDoc(doc(db, 'users', user.uid));
      if (!snap.exists()) {
        pendingError = 'T\u00e0i kho\u1ea3n ch\u01b0a \u0111\u01b0\u1ee3c \u0111\u0103ng k\u00fd trong h\u1ec7 th\u1ed1ng. UID: ' + user.uid;
        await signOut(auth);
        return;
      }
      if (snap.data()?.role !== 'admin') {
        pendingError = 'T\u00e0i kho\u1ea3n kh\u00f4ng c\u00f3 quy\u1ec1n admin. Role hi\u1ec7n t\u1ea1i: ' + (snap.data()?.role || 'ch\u01b0a \u0111\u1eb7t');
        await signOut(auth);
        return;
      }

      sessionReady = true;
      const nameEl = document.getElementById('adminName');
      if (nameEl) {
        nameEl.textContent = escapeHtml(user.displayName || user.email.split('@')[0]);
      }
      showDashboardPage();
      await loadAllData();
    } catch (e) {
      // Firestore error \u2014 show message but do NOT sign out (avoids reload loop)
      showLoginError('L\u1ed7i k\u1ebft n\u1ed1i Firestore: ' + e.message);
      console.error('Auth init error:', e);
    }
  });
});

// =====================================================================
//  DASHBOARD RENDER
// =====================================================================

function renderDashboard() {
  const pending       = state.requests.filter(r => r.status === 'pending').length;
  const accepted      = state.requests.filter(r => r.status === 'accepted').length;
  const totalReqs     = state.requests.length;
  const matchRate     = totalReqs > 0 ? Math.round((accepted / totalReqs) * 100) : 0;
  const activeGroups  = state.groups.filter(g => g.status === 'active').length;
  const totalExpense  = state.expenses.reduce((sum, e) => sum + (e.amount || 0), 0);
  const unpaidDebts   = state.expenseShares.filter(s => !s.isPaid && s.isArchived !== true).length;

  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('statUsers',          state.users.filter(u => !u.deleted && !u.isDeleted).length);
  set('statPosts',          state.posts.length);
  set('statPendingReqs',    pending);
  set('statGroups',         activeGroups);
  set('statExpenses',       state.expenses.length);
  set('statTotalAmount',    formatMoney(totalExpense));
  set('statUnpaidDebts',    unpaidDebts);
  set('statMatchRate',      matchRate + '%');
  const bar = document.getElementById('statMatchRateBar');
  if (bar) bar.style.width = matchRate + '%';

  // Recent posts mini-table
  const recentPostsTbody = document.getElementById('recentPosts');
  if (recentPostsTbody) {
    const rows = state.posts.slice(0, 6).map(p => `
      <tr>
        <td><strong>${escapeHtml(truncate(p.title, 32))}</strong></td>
        <td>${escapeHtml(p.province || '—')}</td>
        <td class="mono">${formatPrice(p.price)}</td>
        <td>${formatDate(p.createdAt)}</td>
      </tr>`).join('') || emptyRow(4, 'Chưa có dữ liệu');
    recentPostsTbody.innerHTML = rows;
  }

  // Recent requests mini-table
  const recentReqsTbody = document.getElementById('recentRequests');
  if (recentReqsTbody) {
    const rows = state.requests.slice(0, 6).map(r => `
      <tr>
        <td>${escapeHtml(r.requesterName || r.requesterId || '—')}</td>
        <td>${statusBadge(r.status)}</td>
        <td>${formatDate(r.createdAt)}</td>
      </tr>`).join('') || emptyRow(3, 'Chưa có dữ liệu');
    recentReqsTbody.innerHTML = rows;
  }
}

// =====================================================================
//  CHARTS – DASHBOARD
// =====================================================================

function renderCharts() {
  try {
    renderChartUsersByMonth();
    renderChartPostsByStatus();
  } catch (e) {
    console.warn('Charts not available:', e);
  }
}

function renderChartUsersByMonth() {
  destroyChart('dashUsersByMonth');
  const labels = [];
  const data   = [];
  const now    = new Date();
  for (let i = 5; i >= 0; i--) {
    const m = new Date(now.getFullYear(), now.getMonth() - i, 1);
    labels.push(m.toLocaleDateString('vi-VN', { month: 'short', year: '2-digit' }));
    const end = new Date(now.getFullYear(), now.getMonth() - i + 1, 1);
    data.push(state.users.filter(u => {
      const d = toDate(u.createdAt);
      return d && d >= m && d < end;
    }).length);
  }

  const ctx = document.getElementById('chartUsersByMonth')?.getContext('2d');
  if (!ctx) return;
  charts.dashUsersByMonth = new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: 'Người dùng mới',
        data,
        borderColor: '#2563EB',
        backgroundColor: 'rgba(37,99,235,0.08)',
        borderWidth: 2,
        fill: true,
        tension: 0.35,
        pointBackgroundColor: '#2563EB',
        pointRadius: 4,
      }]
    },
    options: {
      ...chartDefaults,
      scales: {
        y: { beginAtZero: true, grid: { color: '#E2E8F0' }, ticks: { color: '#94A3B8' } },
        x: { grid: { display: false }, ticks: { color: '#94A3B8' } }
      }
    }
  });
}

function renderChartPostsByStatus() {
  destroyChart('dashPostsByStatus');
  const counts = { active: 0, pending: 0, hidden: 0, sold: 0 };
  state.posts.forEach(p => { const s = p.status || 'active'; counts[s] = (counts[s] || 0) + 1; });

  const ctx = document.getElementById('chartPostsByStatus')?.getContext('2d');
  if (!ctx) return;
  charts.dashPostsByStatus = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['Đang hiển thị', 'Chờ duyệt', 'Đã ẩn', 'Hết phòng'],
      datasets: [{
        label: 'Số bài',
        data: [counts.active, counts.pending, counts.hidden, counts.sold],
        backgroundColor: ['#22C55E', '#F59E0B', '#94A3B8', '#0D9488'],
        borderRadius: 4,
      }]
    },
    options: {
      ...chartDefaults,
      scales: {
        y: { beginAtZero: true, grid: { color: '#E2E8F0' }, ticks: { color: '#94A3B8' } },
        x: { grid: { display: false }, ticks: { color: '#94A3B8' } }
      },
      plugins: { ...chartDefaults.plugins, legend: { display: false } }
    }
  });
}

// =====================================================================
//  USERS SECTION
// =====================================================================

function filterUsers() {
  const q      = (document.getElementById('searchUsers')?.value || '').toLowerCase();
  const role   = document.getElementById('filterUserRole')?.value || '';
  const status = document.getElementById('filterUserStatus')?.value || '';
  return state.users.filter(u => {
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
        va = state.posts.filter(p => p.ownerId === a.uid).length;
        vb = state.posts.filter(p => p.ownerId === b.uid).length;
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
      ? emptyRow(7, 'Kh\u00f4ng c\xf3 ng\u01b0\u1eddi d\xf9ng n\xe0o')
      : emptyRow(7, 'Kh\xf4ng c\xf3 k\u1ebft qu\u1ea3 ph\xf9 h\u1ee3p');
    renderPagination('usersPagination', 'users', data.length, renderUsersSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(u => {
    const postCount   = state.posts.filter(p => p.ownerId === u.uid).length;
    const isBlocked   = u.isBlocked === true;
    const isAdmin     = u.role === 'admin';
    const tr          = document.createElement('tr');


    const tdUser = document.createElement('td');
    tdUser.innerHTML = `
      <div class="user-cell">
        <div>
          <div class="user-name">${escapeHtml(u.fullName || '—')}</div>
          <div class="user-email">${escapeHtml(u.email || '')}</div>
        </div>
      </div>`;

    const tdEmail  = document.createElement('td');
    tdEmail.textContent  = u.email || '—';
    const tdRole   = document.createElement('td');
    tdRole.innerHTML     = isAdmin
      ? '<span class="badge badge-admin">Admin</span>'
      : '<span class="badge badge-user">User</span>';
    const tdStatus = document.createElement('td');
    tdStatus.innerHTML   = isBlocked
      ? '<span class="badge badge-blocked">\u0110\xe3 kh\xf3a</span>'
      : '<span class="badge badge-active">Ho\u1ea1t \u0111\u1ed9ng</span>';
    const tdPosts  = document.createElement('td');
    tdPosts.innerHTML    = `<span class="count mono">${postCount}</span>`;
    const tdDate   = document.createElement('td');
    tdDate.textContent   = formatDate(u.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    if (isBlocked) {
      const btnUnlock = document.createElement('button');
      btnUnlock.className = 'btn btn-success';
      btnUnlock.textContent = 'M\u1edf kh\xf3a';
      btnUnlock.addEventListener('click', () => {
        showConfirmModal(
          'M\u1edf kh\xf3a t\xe0i kho\u1ea3n',
          `M\u1edf kh\xf3a t\xe0i kho\u1ea3n "${u.fullName || u.email}"?`,
          () => toggleBlockUser(u.uid, false)
        );
      });
      tdActions.append(btnUnlock);
    } else {
      const btnView = document.createElement('button');
      btnView.className = 'btn btn-view';
      btnView.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg> Chi ti\u1ebft';
      btnView.addEventListener('click', () => viewUser(u.uid));

      const btnLock = document.createElement('button');
      btnLock.className = 'btn btn-warn';
      btnLock.textContent = 'Kh\xf3a';
      btnLock.addEventListener('click', () => {
        showConfirmModal(
          'Kh\xf3a t\xe0i kho\u1ea3n',
          `Kh\xf3a t\xe0i kho\u1ea3n "${u.fullName || u.email}"?`,
          () => toggleBlockUser(u.uid, true)
        );
      });

      const btnDel = document.createElement('button');
      btnDel.className = 'btn btn-del';
      btnDel.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
      btnDel.title = 'X\xf3a m\u1ec1m';
      btnDel.addEventListener('click', () => {
        showConfirmModal(
          'V\xf4 hi\u1ec7u h\xf3a t\xe0i kho\u1ea3n',
          `V\xf4 hi\u1ec7u h\xf3a t\xe0i kho\u1ea3n "${u.fullName || u.email}"? T\xe0i kho\u1ea3n s\u1ebd b\u1ecb \u1ea9n v\xe0 user s\u1ebd b\u1ecb \u0111\u0103ng xu\u1ea5t t\u1ef1 \u0111\u1ed9ng.`,
          () => softDeleteUser(u.uid)
        );
      });
      tdActions.append(btnView, btnLock, btnDel);
    }
    tr.append(tdUser, tdEmail, tdRole, tdStatus, tdPosts, tdDate, tdActions);
    tbody.appendChild(tr);
  });

  renderPagination('usersPagination', 'users', data.length, renderUsersSection);
  updateSortIcons('#usersTableEl', 'users');
}

async function toggleBlockUser(uid, block) {
  try {
    await updateDoc(doc(db, 'users', uid), { isBlocked: block });
    const u = state.users.find(x => x.uid === uid);
    if (u) u.isBlocked = block;
    updateBadges();
    renderUsersSection();
    showToast(`\u0110\xe3 ${block ? 'kh\xf3a' : 'm\u1edf kh\xf3a'} t\xe0i kho\u1ea3n`, 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

async function changeUserRole(uid, newRole) {
  try {
    await updateDoc(doc(db, 'users', uid), { role: newRole });
    const u = state.users.find(x => x.uid === uid);
    if (u) u.role = newRole;
    updateBadges();
    renderUsersSection();
    const msg = newRole === 'admin' ? 'th\u0103ng quy\u1ec1n Admin' : 'h\u1ea1 v\u1ec1 User';
    showToast(`\u0110\xe3 ${msg}`, 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

async function softDeleteUser(uid) {
  try {
    await updateDoc(doc(db, 'users', uid), {
      deleted:   true,
      deletedAt: serverTimestamp(),
      isBlocked: true,
    });
    const u = state.users.find(x => x.uid === uid);
    if (u) { u.deleted = true; u.isBlocked = true; }
    updateBadges();
    renderUsersSection();
    showToast('\u0110\xe3 v\xf4 hi\u1ec7u h\xf3a t\xe0i kho\u1ea3n. User s\u1ebd b\u1ecb \u0111\u0103ng xu\u1ea5t t\u1ef1 \u0111\u1ed9ng.', 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

function viewUser(uid) {
  const u = state.users.find(x => x.uid === uid);
  if (!u) return;

  const postCount   = state.posts.filter(p => p.ownerId === uid).length;
  const isBlocked   = u.isBlocked === true;
  const isAdmin     = u.role === 'admin';
  const profileDone = u.profileCompleted === true;
  const habits      = Array.isArray(u.habits) ? u.habits : [];
  const criteria    = Array.isArray(u.roommateCriteria) ? u.roommateCriteria : [];

  const habitsHtml = habits.length
    ? habits.map(h => `<span class="habit-tag">${escapeHtml(habitLabel(h))}</span>`).join('')
    : '<span style="color:var(--text-3);font-size:13px;">Chưa cập nhật</span>';

  const criteriaHtml = criteria.length
    ? '<ul style="margin:4px 0 0 16px;padding:0;color:var(--text-1);font-size:13px;line-height:1.8;">'
      + criteria.map(c => `<li>${escapeHtml(c)}</li>`).join('')
      + '</ul>'
    : null;

  const infoRows = [
    u.phone             ? modalRow('SĐT', escapeHtml(u.phone)) : '',
    u.gender            ? modalRow('Giới tính', escapeHtml(u.gender === 'male' ? 'Nam' : u.gender === 'female' ? 'Nữ' : u.gender)) : '',
    u.preferredLocation ? modalRow('Khu vực', escapeHtml(u.preferredLocation)) : '',
    u.address           ? modalRow('Địa chỉ', escapeHtml(u.address)) : '',
  ].filter(Boolean).join('');

  openModal(`
    <div style="text-align:center;margin-bottom:20px;">
      <div class="avatar" style="width:64px;height:64px;font-size:24px;margin:0 auto 12px;">${avatarEl(u.avatarUrl, u.fullName)}</div>
      <div style="font-size:17px;font-weight:800;">${escapeHtml(u.fullName || '—')}</div>
      <div style="color:var(--text-2);font-size:12px;margin-top:3px;">${escapeHtml(u.email || '')}</div>
      <div style="display:flex;gap:6px;justify-content:center;margin-top:10px;flex-wrap:wrap;">
        ${isAdmin ? '<span class="badge badge-admin">Admin</span>' : '<span class="badge badge-user">User</span>'}
        ${isBlocked ? '<span class="badge badge-blocked">Đã khóa</span>' : '<span class="badge badge-active">Hoạt động</span>'}
        ${profileDone ? '<span class="badge badge-profile-done">Đã hoàn tất</span>' : '<span class="badge badge-pending">Chưa hoàn tất</span>'}
      </div>
    </div>

    ${infoRows ? `<div class="modal-section-label">Thông tin cá nhân</div>${infoRows}` : ''}

    ${u.bio ? `<div class="modal-section-label">Giới thiệu</div><div style="font-size:13px;color:var(--text-1);line-height:1.6;padding:2px 0 10px;">${escapeHtml(u.bio)}</div>` : ''}

    <div class="modal-section-label">Sở thích / Thói quen</div>
    <div style="padding:4px 0 10px;display:flex;flex-wrap:wrap;gap:6px;">${habitsHtml}</div>

    ${criteriaHtml ? `<div class="modal-section-label">Tiêu chí tìm bạn ở ghép</div>${criteriaHtml}` : ''}

    <div class="modal-section-label">Thống kê</div>
    ${modalRow('Số bài đăng', `<span class="mono">${postCount}</span>`)}
    ${modalRow('Ngày tạo', formatDate(u.createdAt))}

    <div class="modal-section-label" style="color:var(--danger);margin-top:20px;">Hành động Admin</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px;">
      <button class="btn ${isBlocked ? 'btn-success' : 'btn-warn'}" id="btnModalToggleBlock">
        ${isBlocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'}
      </button>
      ${!isAdmin
        ? '<button class="btn btn-primary" id="btnModalPromote">Thăng quyền Admin</button>'
        : '<button class="btn btn-warn" id="btnModalDemote">Hạ về User</button>'}
    </div>
  `);
}

// =====================================================================
//  POSTS SECTION
// =====================================================================

function filterPosts() {
  const q        = (document.getElementById('searchPosts')?.value || '').toLowerCase();
  const status   = document.getElementById('filterPostStatus')?.value || '';
  const province = document.getElementById('filterPostProvince')?.value || '';
  return state.posts.filter(p => {
    const ps = p.status || 'active';
    const matchQ        = (p.title || '').toLowerCase().includes(q)
      || (p.province || '').toLowerCase().includes(q)
      || (p.district || '').toLowerCase().includes(q);
    const matchStatus   = !status   || ps === status;
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
      return va < vb ? -dir : va > vb ? dir : 0;
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
    tbody.innerHTML = emptyRow(8,
      data.length === 0
        ? 'Kh\xf4ng c\xf3 b\xe0i \u0111\u0103ng n\xe0o'
        : 'Kh\xf4ng c\xf3 k\u1ebft qu\u1ea3 ph\xf9 h\u1ee3p');
    renderPagination('postsPagination', 'posts', data.length, renderPostsSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(p => {
    const owner  = state.users.find(u => u.uid === p.ownerId);
    const status = p.status || 'active';
    const tr     = document.createElement('tr');

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

    const tdArea   = document.createElement('td');
    tdArea.textContent   = [p.district, p.province].filter(Boolean).join(', ') || '—';
    const tdPrice  = document.createElement('td');
    tdPrice.className    = 'mono';
    tdPrice.textContent  = formatPrice(p.price);
    const tdType   = document.createElement('td');
    tdType.textContent   = escapeHtml(p.roomType || '—');
    const tdStatus = document.createElement('td');
    tdStatus.innerHTML   = statusBadge(status);
    const tdDate   = document.createElement('td');
    tdDate.textContent   = formatDate(p.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnView = document.createElement('button');
    btnView.className = 'btn btn-view';
    btnView.textContent = 'Chi ti\u1ebft';
    btnView.addEventListener('click', () => viewPost(p.id));

    if (status !== 'active') {
      // Locked: show ONLY "M\u1edf kh\u00f3a"
      const btnUnlock = document.createElement('button');
      btnUnlock.className = 'btn btn-success';
      btnUnlock.textContent = 'M\u1edf kh\xf3a';
      btnUnlock.addEventListener('click', () => {
        showConfirmModal(
          'M\u1edf kh\xf3a b\xe0i \u0111\u0103ng',
          `M\u1edf kh\xf3a b\xe0i "${truncate(p.title, 40)}"?`,
          () => updatePostStatus(p.id, 'active'));
      });
      tdActions.append(btnUnlock);
    } else {
      // Active: Chi ti\u1ebft + Kh\u00f3a + Delete
      const btnLock = document.createElement('button');
      btnLock.className = 'btn btn-warn';
      btnLock.textContent = 'Kh\xf3a';
      btnLock.addEventListener('click', () => {
        showConfirmModal(
          'Kh\xf3a b\xe0i \u0111\u0103ng',
          `Kh\xf3a b\xe0i "${truncate(p.title, 40)}"?`,
          () => updatePostStatus(p.id, 'hidden'));
      });

      const btnDel = document.createElement('button');
      btnDel.className = 'btn btn-del';
      btnDel.title = 'X\xf3a b\xe0i \u0111\u0103ng';
      btnDel.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
      btnDel.addEventListener('click', () => {
        showConfirmModal(
          'X\xf3a b\xe0i \u0111\u0103ng',
          `X\xf3a b\xe0i "${truncate(p.title, 40)}"? H\xe0nh \u0111\u1ed9ng kh\xf4ng th\u1ec3 ho\xe0n t\xe1c.`,
          () => deletePost(p.id));
      });
      tdActions.append(btnView, btnLock, btnDel);
    }
    tr.append(tdTitle, tdOwner, tdArea, tdPrice, tdType, tdStatus, tdDate, tdActions);
    tbody.appendChild(tr);
  });

  renderPagination('postsPagination', 'posts', data.length, renderPostsSection);
  updateSortIcons('#postsTableEl', 'posts');
}

async function deletePost(id) {
  try {
    await deleteDoc(doc(db, 'posts', id));
    state.posts = state.posts.filter(x => x.id !== id);
    updateBadges();
    renderPostsSection();
    showToast('\u0110\xe3 x\xf3a b\xe0i \u0111\u0103ng', 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

async function updatePostStatus(id, newStatus) {
  // NOTE: Flutter post_repository.dart must read `status` field from Firestore
  // to reflect admin changes (active/pending/hidden/sold).
  try {
    await updateDoc(doc(db, 'posts', id), { status: newStatus });
    const p = state.posts.find(x => x.id === id);
    if (p) p.status = newStatus;
    renderPostsSection();
    const label = newStatus === 'active' ? 'duy\u1ec7t' : newStatus === 'hidden' ? '\u1ea9n' : '\u0111\xe1nh d\u1ea5u h\u1ebft ph\xf2ng';
    showToast(`\u0110\xe3 ${label} b\xe0i \u0111\u0103ng`, 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

function viewPost(id) {
  const p = state.posts.find(x => x.id === id);
  if (!p) return;
  const owner  = state.users.find(u => u.uid === p.ownerId);
  const status = p.status || 'active';

  const amenities = Array.isArray(p.amenities) ? p.amenities : [];
  const habits    = Array.isArray(p.lifestyleHabits) ? p.lifestyleHabits : [];

  const amenityHtml = amenities.length
    ? amenities.map(a =>
        `<span style="display:inline-block;background:var(--bg);color:var(--text-1);border:1px solid var(--border);border-radius:20px;padding:3px 12px;font-size:12px;font-weight:500;margin:2px 4px 2px 0;">${escapeHtml(a)}</span>`
      ).join('')
    : '<span style="color:var(--text-3);font-size:13px;">Kh\xf4ng c\xf3</span>';

  const habitHtml = habits.length
    ? habits.map(h =>
        `<span style="display:inline-block;background:var(--primary-light);color:var(--primary);border-radius:20px;padding:3px 12px;font-size:12px;font-weight:500;margin:2px 4px 2px 0;">${escapeHtml(h)}</span>`
      ).join('')
    : '';

  const imgSrc = p.imageUrl || (Array.isArray(p.imageUrls) && p.imageUrls[0]) || null;
  const imgHtml = imgSrc
    ? `<div style="margin:12px 0;text-align:center;"><img src="${escapeHtml(imgSrc)}" alt="${escapeHtml(p.title)}" style="max-width:100%;max-height:280px;border-radius:10px;border:1px solid var(--border);object-fit:cover;" /></div>`
    : '';

  openModal(`
    <div class="modal-title">${escapeHtml(p.title || '—')}</div>
    <div style="margin-bottom:14px;">${statusBadge(status)}</div>
    ${imgHtml}
    ${modalRow('Ng\u01b0\u1eddi \u0111\u0103ng', owner
      ? `<button class="btn-link" data-view-user="${owner.uid}">${escapeHtml(owner.fullName || owner.email || '—')}</button>`
      : escapeHtml(p.ownerId || '—'))}
    ${modalRow('\u0110\u1ecba ch\u1ec9', escapeHtml(p.location || p.address || '—'))}
    ${modalRow('Khu v\u1ef1c', escapeHtml([p.district, p.province].filter(Boolean).join(', ') || '—'))}
    ${modalRow('Lo\u1ea1i ph\xf2ng', escapeHtml(p.roomType || '—'))}
    ${modalRow('Gi\xe1', formatPrice(p.price))}
    ${modalRow('Di\u1ec7n t\xedch', p.area ? escapeHtml(p.area + ' m\xb2') : '<span style="color:var(--text-3)">—</span>')}
    ${modalRow('S\u1ee9c ch\u1ee9a', p.capacity ? escapeHtml(String(p.capacity) + ' ng\u01b0\u1eddi') : '<span style="color:var(--text-3)">—</span>')}
    ${modalRow('Ng\xe0y \u0111\u0103ng', formatDate(p.createdAt))}
    ${modalRow('C\u1eadp nh\u1eadt', p.updatedAt ? formatDate(p.updatedAt) : '<span style="color:var(--text-3)">—</span>')}
    <div class="modal-section-label">Ti\u1ec7n \xedch</div>
    <div style="padding:2px 0 10px;">${amenityHtml}</div>
    ${habitHtml ? `<div class="modal-section-label">Th\xf3i quen sinh ho\u1ea1t</div><div style="padding:2px 0 10px;">${habitHtml}</div>` : ''}
    <div class="modal-section-label">M\xf4 t\u1ea3</div>
    <div style="font-size:13px;color:var(--text-1);line-height:1.7;padding:2px 0 10px;white-space:pre-wrap;">${escapeHtml(p.description || 'Kh\xf4ng c\xf3 m\xf4 t\u1ea3.')}</div>
  `);
  document.querySelector('[data-view-user]')?.addEventListener('click', (e) => {
    viewUser(e.currentTarget.dataset.viewUser);
  });
}

// =====================================================================
//  REQUESTS SECTION
// =====================================================================

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
    tbody.innerHTML = emptyRow(7,
      data.length === 0
        ? 'Kh\xf4ng c\xf3 y\xeau c\u1ea7u n\xe0o'
        : 'Kh\xf4ng c\xf3 k\u1ebft qu\u1ea3 ph\xf9 h\u1ee3p');
    renderPagination('requestsPagination', 'requests', data.length, renderRequestsSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(r => {
    const post   = state.posts.find(p => p.id === r.postId);
    const ownerId = r.postOwnerId || post?.ownerId;
    const owner  = ownerId ? state.users.find(u => u.uid === ownerId) : null;
    const tr     = document.createElement('tr');

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

    const tdMsg    = document.createElement('td');
    tdMsg.textContent    = truncate(r.message, 35);
    const tdStatus = document.createElement('td');
    tdStatus.innerHTML   = statusBadge(r.status);
    const tdDate   = document.createElement('td');
    tdDate.textContent   = formatDate(r.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnView = document.createElement('button');
    btnView.className = 'btn btn-view';
    btnView.textContent = 'Xem';
    btnView.addEventListener('click', () => viewRequest(r.id));

    const btnDel = document.createElement('button');
    btnDel.className = 'btn btn-del';
    btnDel.title = 'X\xf3a';
    btnDel.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
    btnDel.addEventListener('click', () => {
      showConfirmModal(
        'X\xf3a y\xeau c\u1ea7u',
        'X\xf3a y\xeau c\u1ea7u n\xe0y? H\xe0nh \u0111\u1ed9ng kh\xf4ng th\u1ec3 ho\xe0n t\xe1c.',
        () => deleteRequest(r.id));
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
    state.requests = state.requests.filter(x => x.id !== id);
    updateBadges();
    renderRequestsSection();
    showToast('\u0110\xe3 x\xf3a y\xeau c\u1ea7u', 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

function viewRequest(id) {
  const r = state.requests.find(x => x.id === id);
  if (!r) return;
  const post    = state.posts.find(p => p.id === r.postId);
  const ownerId = r.postOwnerId || post?.ownerId;
  const owner   = ownerId ? state.users.find(u => u.uid === ownerId) : null;
  const invType = r.inviteType === 'profile_invite' ? 'M\u1eddi qua h\u1ed3 s\u01a1' : 'Y\xeau c\u1ea7u b\xe0i \u0111\u0103ng';

  const adminActions = r.status === 'pending' ? `
    <div class="modal-section-label" style="color:var(--danger);">Can thi\u1ec7p Admin</div>
    <div style="display:flex;gap:8px;margin-top:8px;" id="reqAdminActions">
      <button class="btn btn-success" id="btnForceAccept">\u2713 Bu\u1ed9c ch\u1ea5p nh\u1eadn</button>
      <button class="btn btn-danger" id="btnForceReject">\u2715 Bu\u1ed9c t\u1eeb ch\u1ed1i</button>
    </div>` : '';

  openModal(`
    <div class="modal-title">Chi ti\u1ebft y\xeau c\u1ea7u gh\xe9p ph\xf2ng</div>
    <div class="modal-section-label">Ng\u01b0\u1eddi g\u1eedi</div>
    <div class="detail-block">
      ${makeAvatar(r.requesterAvatar, r.requesterName)}
      <div><div style="font-weight:600;">${escapeHtml(r.requesterName || r.requesterId || '—')}</div></div>
    </div>
    <div class="modal-section-label">B\xe0i \u0111\u0103ng li\xean quan</div>
    ${post
      ? `<div style="font-weight:600;margin-bottom:4px;">${escapeHtml(post.title || '—')}</div><div style="color:var(--text-2);font-size:12px;">${escapeHtml([post.district, post.province].filter(Boolean).join(', '))} \xb7 ${formatPrice(post.price)}</div>`
      : `<span style="color:var(--text-2);">${escapeHtml(r.postId || '—')}</span>`}
    <div class="modal-section-label">Ch\u1ee7 b\xe0i \u0111\u0103ng</div>
    <div class="detail-block">
      ${owner ? makeAvatar(owner.avatarUrl, owner.fullName) : ''}
      <div>${owner
        ? `<div style="font-weight:600;">${escapeHtml(owner.fullName || '—')}</div><div style="color:var(--text-2);font-size:12px;">${escapeHtml(owner.email || '')}</div>`
        : '<span style="color:var(--text-2);">\u2014</span>'}</div>
    </div>
    <div class="modal-section-label">Th\xf4ng tin y\xeau c\u1ea7u</div>
    ${modalRow('Lo\u1ea1i', invType)}
    ${modalRow('Tin nh\u1eafn', escapeHtml(r.message || '—'))}
    ${modalRow('Tr\u1ea1ng th\xe1i', statusBadge(r.status))}
    ${modalRow('Ng\xe0y g\u1eedi', formatDate(r.createdAt))}
    ${modalRow('Ng\xe0y ph\u1ea3n h\u1ed3i', r.respondedAt ? formatDate(r.respondedAt) : '<span style="color:var(--text-3)">—</span>')}
    ${adminActions}
  `);

  if (r.status === 'pending') {
    document.getElementById('btnForceAccept')?.addEventListener('click', () => {
      showConfirmModal(
        'Bu\u1ed9c ch\u1ea5p nh\u1eadn',
        'Admin s\u1ebd bu\u1ed9c ch\u1ea5p nh\u1eadn y\xeau c\u1ea7u n\xe0y v\xe0 t\u1ea1o nh\xf3m ph\xf2ng.',
        () => adminForceAccept(r.id));
    });
    document.getElementById('btnForceReject')?.addEventListener('click', () => {
      showConfirmModal(
        'Bu\u1ed9c t\u1eeb ch\u1ed1i',
        'Admin s\u1ebd bu\u1ed9c t\u1eeb ch\u1ed1i y\xeau c\u1ea7u n\xe0y.',
        () => adminForceReject(r.id));
    });
  }
}

async function adminForceAccept(id) {
  const r = state.requests.find(x => x.id === id);
  if (!r) return;
  const owner   = state.users.find(u => u.uid === r.postOwnerId);
  const requesterName = r.requesterName || r.requesterId?.slice(0, 6) || 'User';
  const ownerName = owner?.fullName || r.postOwnerId?.slice(0, 6) || 'Owner';
  const ownerId = r.postOwnerId || state.posts.find(p => p.id === r.postId)?.ownerId;
  try {
    await updateDoc(doc(db, 'roommate_requests', id), {
      status: 'accepted',
      respondedAt: serverTimestamp(),
      adminOverride: true,
    });
    await addDoc(collection(db, 'room_groups'), {
      name: `Nh\xf3m ph\xf2ng - ${requesterName} & ${ownerName}`,
      ownerId: r.postOwnerId || null,
      memberIds: [r.postOwnerId, r.requesterId].filter(Boolean),
      postId: r.postId || null,
      createdAt: serverTimestamp(),
      status: 'active',
    });
    const idx = state.requests.findIndex(x => x.id === id);
    if (idx >= 0) { state.requests[idx].status = 'accepted'; state.requests[idx].respondedAt = new Date(); }
    closeModal();
    updateBadges();
    renderRequestsSection();
    showToast('\u0110\xe3 bu\u1ed9c ch\u1ea5p nh\u1eadn v\xe0 t\u1ea1o nh\xf3m ph\xf2ng', 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
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
    showToast('\u0110\xe3 bu\u1ed9c t\u1eeb ch\u1ed1i y\xeau c\u1ea7u', 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

// =====================================================================
//  GROUPS SECTION
// =====================================================================

function filterGroups() {
  const q      = (document.getElementById('searchGroups')?.value || '').toLowerCase();
  const status = document.getElementById('filterGroupStatus')?.value || '';
  return state.groups.filter(g => {
    const matchQ = (g.name || g.id || '').toLowerCase().includes(q)
      || (g.postId || '').toLowerCase().includes(q);
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
    tbody.innerHTML = emptyRow(6,
      data.length === 0
        ? 'Kh\xf4ng c\xf3 nh\xf3m ph\xf2ng n\xe0o'
        : 'Kh\xf4ng c\xf3 k\u1ebft qu\u1ea3 ph\xf9 h\u1ee3p');
    renderPagination('groupsPagination', 'groups', data.length, renderGroupsSection);
    return;
  }

  tbody.innerHTML = '';
  page.forEach(g => {
    const mids = Array.isArray(g.memberIds) ? g.memberIds : [];
    const post    = state.posts.find(p => p.id === g.postId);
    const gStatus = g.status || 'active';
    const tr      = document.createElement('tr');

    const tdName = document.createElement('td');
    tdName.innerHTML = `<strong>${escapeHtml(g.name || g.id.slice(0, 12) + '\u2026')}</strong>`;

    const tdMembers = document.createElement('td');
    tdMembers.innerHTML = `<span class="mono">${mids.length} th\xe0nh vi\xean</span>`;

    const tdPost = document.createElement('td');
    if (post) {
      const btn = document.createElement('button');
      btn.className = 'btn-link';
      btn.textContent = truncate(post.title, 30);
      btn.addEventListener('click', () => viewPost(post.id));
      tdPost.appendChild(btn);
    } else {
      tdPost.innerHTML = `<span style="color:var(--text-2);font-size:12px;">${escapeHtml(g.postId ? g.postId.slice(0, 16) + '\u2026' : '\u2014')}</span>`;
    }

    const tdStatus = document.createElement('td');
    tdStatus.innerHTML = statusBadge(gStatus);
    const tdDate   = document.createElement('td');
    tdDate.textContent = formatDate(g.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnView = document.createElement('button');
    btnView.className = 'btn btn-view';
    btnView.textContent = 'Chi ti\u1ebft';
    btnView.addEventListener('click', () => viewGroup(g.id));

    const btnToggle = document.createElement('button');
    if (gStatus === 'active') {
      btnToggle.className = 'btn btn-warn';
      btnToggle.textContent = 'V\xf4 hi\u1ec7u';
      btnToggle.addEventListener('click', () => {
        showConfirmModal(
          'V\xf4 hi\u1ec7u h\xf3a nh\xf3m',
          'V\xf4 hi\u1ec7u h\xf3a nh\xf3m ph\xf2ng n\xe0y?',
          () => toggleGroupStatus(g.id, 'inactive'));
      });
    } else if (gStatus === 'inactive' || gStatus === 'disbanded') {
      btnToggle.className = 'btn btn-success';
      btnToggle.textContent = 'K\xedch ho\u1ea1t';
      btnToggle.addEventListener('click', () => {
        showConfirmModal(
          'K\xedch ho\u1ea1t nh\xf3m',
          'K\xedch ho\u1ea1t l\u1ea1i nh\xf3m ph\xf2ng n\xe0y?',
          () => toggleGroupStatus(g.id, 'active'));
      });
    }

    const btnDel = document.createElement('button');
    btnDel.className = 'btn btn-del';
    btnDel.title = 'X\xf3a nh\xf3m';
    btnDel.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
    btnDel.addEventListener('click', () => {
      showConfirmModal(
        'X\xf3a nh\xf3m ph\xf2ng',
        'X\xf3a nh\xf3m ph\xf2ng n\xe0y? H\xe0nh \u0111\u1ed9ng kh\xf4ng th\u1ec3 ho\xe0n t\xe1c.',
        () => deleteGroup(g.id));
    });

    tdActions.append(btnView, btnToggle, btnDel);
    tr.append(tdName, tdMembers, tdPost, tdStatus, tdDate, tdActions);
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
    showToast('\u0110\xe3 x\xf3a nh\xf3m ph\xf2ng', 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

async function toggleGroupStatus(id, newStatus) {
  try {
    await updateDoc(doc(db, 'room_groups', id), { status: newStatus });
    const g = state.groups.find(x => x.id === id);
    if (g) g.status = newStatus;
    updateBadges();
    renderGroupsSection();
    const label = newStatus === 'active' ? 'k\xedch ho\u1ea1t' : 'v\xf4 hi\u1ec7u h\xf3a';
    showToast(`\u0110\xe3 ${label} nh\xf3m ph\xf2ng`, 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

function viewGroup(id) {
  const g = state.groups.find(x => x.id === id);
  if (!g) return;
  const mids = Array.isArray(g.memberIds) ? g.memberIds : [];
  const post = state.posts.find(p => p.id === g.postId);

  const memberHtml = mids.length
    ? mids.map(uid => {
        const u = state.users.find(x => x.uid === uid);
        return u
          ? `<div class="detail-block">${makeAvatar(u.avatarUrl, u.fullName)}<div><div style="font-weight:600;">${escapeHtml(u.fullName || '—')}</div><div style="font-size:11px;color:var(--text-2);">${escapeHtml(u.email || uid)}</div></div></div>`
          : `<div style="color:var(--text-2);font-size:12px;">${escapeHtml(uid)}</div>`;
      }).join('')
    : '<div style="color:var(--text-3);font-size:13px;">Kh\xf4ng c\xf3 th\xe0nh vi\xean</div>';

  const groupExpenses = state.expenses.filter(e => e.roomGroupId === g.id);
  const totalExpense  = groupExpenses.reduce((sum, e) => sum + (e.amount || 0), 0);

  openModal(`
    <div class="modal-title">${escapeHtml(g.name || 'Nh\xf3m ph\xf2ng')}</div>
    ${modalRow('Tr\u1ea1ng th\xe1i', statusBadge(g.status || 'active'))}
    ${modalRow('Ng\xe0y t\u1ea1o', formatDate(g.createdAt))}
    ${modalRow('T\u1ed5ng chi ti\xeau', `<span class="mono" style="font-weight:700;">${formatMoney(totalExpense)}</span>`)}
    <div class="modal-section-label">B\xe0i \u0111\u0103ng li\xean quan</div>
    ${post
      ? `<div style="font-weight:600;">${escapeHtml(post.title || '—')}</div><div style="color:var(--text-2);font-size:12px;margin-top:4px;">${escapeHtml([post.district, post.province].filter(Boolean).join(', '))} \xb7 ${formatPrice(post.price)}</div>`
      : '<span style="color:var(--text-3);font-size:13px;">Kh\xf4ng c\xf3</span>'}
    <div class="modal-section-label">Th\xe0nh vi\xean (${mids.length})</div>
    <div style="display:flex;flex-direction:column;gap:6px;margin-bottom:12px;">${memberHtml}</div>
    <div style="display:flex;gap:8px;margin-top:4px;">
      <button class="btn btn-view" id="btnViewGroupExpenses" data-groupid="${escapeHtml(g.id)}">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        Xem chi ti\xeau c\u1ee7a nh\xf3m
      </button>
    </div>
  `);

  document.getElementById('btnViewGroupExpenses')?.addEventListener('click', () => {
    const groupId = g.id;
    closeModal();
    showSection('expenses');
    const filterEl = document.getElementById('filterExpenseGroup');
    if (filterEl) {
      const opt = Array.from(filterEl.options).find(o => o.value === groupId);
      if (opt) { filterEl.value = groupId; }
    }
    renderExpensesSection();
  });
}

// =====================================================================
//  EXPENSES SECTION
// =====================================================================

function filterExpenses() {
  const q       = (document.getElementById('searchExpenses')?.value || '').toLowerCase();
  const groupId = document.getElementById('filterExpenseGroup')?.value || '';
  return state.expenses.filter(e => {
    const group = state.groups.find(g => g.id === e.roomGroupId);
    const matchQ = (e.title || '').toLowerCase().includes(q)
      || (group?.name || '').toLowerCase().includes(q);
    const matchGroup = !groupId || e.roomGroupId === groupId;
    return matchQ && matchGroup;
  });
}

function getSortedExpenses() {
  const data = filterExpenses();
  const { col, dir } = state.sort.expenses;
  if (!col) return data;
  return [...data].sort((a, b) => {
    if (col === 'createdAt') {
      const va = toDate(a.createdAt)?.getTime() || 0;
      const vb = toDate(b.createdAt)?.getTime() || 0;
      return va < vb ? -dir : va > vb ? dir : 0;
    }
    return 0;
  });
}

function renderExpensesSection() {
  renderExpenseStats();
  const data  = getSortedExpenses();
  const page  = pageSlice(data, 'expenses');
  const tbody = document.getElementById('expensesTable');
  if (!tbody) return;

  if (!page.length) {
    tbody.innerHTML = emptyRow(8,
      data.length === 0
        ? 'Kh\xf4ng c\xf3 kho\u1ea3n chi n\xe0o'
        : 'Kh\xf4ng c\xf3 k\u1ebft qu\u1ea3 ph\xf9 h\u1ee3p');
    renderPagination('expensesPagination', 'expenses', data.length, renderExpensesSection);
    renderDebtSummary();
    renderDebtSection();
    return;
  }

  tbody.innerHTML = '';
  page.forEach(e => {
    const group      = state.groups.find(g => g.id === e.roomGroupId);
    const payer      = state.users.find(u => u.uid === e.paidBy || u.uid === e.payerId);
    const participants = Array.isArray(e.participantIds) ? e.participantIds : [];
    const tr = document.createElement('tr');

    const tdTitle = document.createElement('td');
    tdTitle.innerHTML = `<strong>${escapeHtml(truncate(e.title, 30))}</strong>`;

    const tdGroup = document.createElement('td');
    tdGroup.textContent = group?.name || truncate(e.roomGroupId, 16) || '\u2014';

    const tdPayer = document.createElement('td');
    if (payer) {
      const btn = document.createElement('button');
      btn.className = 'btn-link';
      btn.textContent = truncate(payer.fullName || payer.email || '\u2014', 20);
      btn.addEventListener('click', () => viewUser(payer.uid));
      tdPayer.appendChild(btn);
    } else {
      tdPayer.textContent = '\u2014';
    }

    const tdAmount = document.createElement('td');
    tdAmount.className = 'mono';
    tdAmount.textContent = formatMoney(e.amount);
    tdAmount.style.fontWeight = '700';

    const tdSplit = document.createElement('td');
    const splitLabel = e.splitType === 'equal' ? 'Equal' : e.splitType === 'custom' ? 'T\xf9y ch\u1ec9nh' : e.splitType || e.splitMethod || '\u2014';
    tdSplit.textContent = splitLabel;

    const tdParticipants = document.createElement('td');
    tdParticipants.innerHTML = `<span class="mono">${participants.length} ng\u01b0\u1eddi</span>`;

    const tdDate = document.createElement('td');
    tdDate.textContent = formatDate(e.createdAt);

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnView = document.createElement('button');
    btnView.className = 'btn btn-view';
    btnView.textContent = 'Chi ti\u1ebft';
    btnView.addEventListener('click', () => viewExpense(e.id));

    const btnDel = document.createElement('button');
    btnDel.className = 'btn btn-del';
    btnDel.title = 'X\xf3a';
    btnDel.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>';
    btnDel.addEventListener('click', () => {
      showConfirmModal(
        'X\xf3a chi ti\xeau',
        `X\xf3a kho\u1ea3n "${truncate(e.title, 30)}"? C\xe1c c\xf4ng n\u1ee3 li\xean quan c\u0169ng s\u1ebd b\u1ecb x\xf3a.`,
        () => deleteExpense(e.id));
    });

    tdActions.append(btnView, btnDel);
    tr.append(tdTitle, tdGroup, tdPayer, tdAmount, tdSplit, tdParticipants, tdDate, tdActions);
    tbody.appendChild(tr);
  });

  renderPagination('expensesPagination', 'expenses', data.length, renderExpensesSection);
  renderDebtSummary();
  renderDebtSection();
  updateSortIcons('#expensesTableEl', 'expenses');
}

function renderExpenseStats() {
  const section = document.getElementById('section-expenses');
  if (!section) return;
  let statsEl = document.getElementById('expenseStatsBar');
  if (!statsEl) {
    statsEl = document.createElement('div');
    statsEl.id = 'expenseStatsBar';
    statsEl.style.cssText = 'display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:16px;';
    const toolbar = section.querySelector('.section-toolbar');
    if (toolbar) {
      toolbar.insertAdjacentElement('afterend', statsEl);
    } else {
      section.insertBefore(statsEl, section.querySelector('.card'));
    }
  }

  const totalExpenses = state.expenses.filter(e => !e.deleted).length;
  const totalAmount   = state.expenses.reduce((s, e) => s + (e.amount || 0), 0);
  const unpaidCount   = state.expenseShares.filter(s => !s.isPaid && !s.isArchived).length;

  statsEl.innerHTML = `
    <div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:14px 18px;display:flex;align-items:center;gap:14px;">
      <div style="width:36px;height:36px;border-radius:10px;background:var(--primary-light);color:var(--primary);display:flex;align-items:center;justify-content:center;flex-shrink:0;">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
      </div>
      <div><div class="mono" style="font-size:22px;font-weight:800;">${totalExpenses}</div><div style="font-size:12px;color:var(--text-2);">T\u1ed5ng kho\u1ea3n chi</div></div>
    </div>
    <div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:14px 18px;display:flex;align-items:center;gap:14px;">
      <div style="width:36px;height:36px;border-radius:10px;background:var(--success-bg);color:var(--success-text);display:flex;align-items:center;justify-content:center;flex-shrink:0;">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/></svg>
      </div>
      <div><div class="mono" style="font-size:22px;font-weight:800;">${formatMoney(totalAmount)}</div><div style="font-size:12px;color:var(--text-2);">T\u1ed5ng ti\u1ec1n ghi nh\u1eadn</div></div>
    </div>
    <div style="background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:14px 18px;display:flex;align-items:center;gap:14px;">
      <div style="width:36px;height:36px;border-radius:10px;background:var(--danger-bg);color:var(--danger-text);display:flex;align-items:center;justify-content:center;flex-shrink:0;">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
      </div>
      <div><div class="mono" style="font-size:22px;font-weight:800;">${unpaidCount}</div><div style="font-size:12px;color:var(--text-2);">C\xf4ng n\u1ee3 ch\u01b0a thanh to\xe1n</div></div>
    </div>`;
}

async function deleteExpense(id) {
  try {
    await deleteDoc(doc(db, 'expenses', id));
    const relatedShares = state.expenseShares.filter(s => s.expenseId === id);
    await Promise.allSettled(relatedShares.map(s => deleteDoc(doc(db, 'expense_shares', s.id))));
    state.expenses       = state.expenses.filter(x => x.id !== id);
    state.expenseShares  = state.expenseShares.filter(x => x.expenseId !== id);
    updateBadges();
    renderExpensesSection();
    showToast('\u0110\xe3 x\xf3a kho\u1ea3n chi v\xe0 c\xe1c c\xf4ng n\u1ee3 li\xean quan', 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

function viewExpense(id) {
  const e = state.expenses.find(x => x.id === id);
  if (!e) return;
  const group   = state.groups.find(g => g.id === e.roomGroupId);
  const payer   = state.users.find(u => u.uid === e.paidBy || u.uid === e.payerId);
  const shares  = state.expenseShares.filter(s => s.expenseId === id);
  const splitLabel = e.splitType === 'equal' ? 'Equal' : e.splitType === 'custom' ? 'T\xf9y ch\u1ec9nh' : e.splitType || e.splitMethod || '\u2014';

  const participants = Array.isArray(e.participantIds) ? e.participantIds : [];
  const participantHtml = participants.length
    ? participants.map(uid => {
        const u   = state.users.find(x => x.uid === uid);
        const sh  = shares.find(s => s.fromUserId === uid);
        const amt = sh ? formatMoney(sh.amountOwed) : '\u2014';
        const paid = sh?.isPaid;
        const label = paid === true
          ? '<span class="badge badge-active" style="font-size:10px;">\u0110\xe3 tr\u1ea3</span>'
          : paid === false
            ? '<span class="badge badge-pending" style="font-size:10px;">Ch\u01b0a tr\u1ea3</span>'
            : '';
        return `<div class="detail-block">
          ${makeAvatar(u?.avatarUrl, u?.fullName)}
          <div style="flex:1;display:flex;align-items:center;justify-content:space-between;">
            <div><div style="font-weight:600;font-size:13px;">${escapeHtml(u?.fullName || uid)}</div></div>
            <div style="text-align:right;"><div class="mono" style="font-weight:700;">${amt}</div><div>${label}</div></div>
          </div>
        </div>`;
      }).join('')
    : '<div style="color:var(--text-3);font-size:13px;">Kh\xf4ng c\xf3 th\xf4ng tin ng\u01b0\u1eddi tham gia</div>';

  openModal(`
    <div class="modal-title">${escapeHtml(e.title || '\u2014')}</div>
    <div style="margin-bottom:16px;">
      <span style="background:var(--bg);color:var(--text-2);border-radius:20px;padding:4px 12px;font-size:12px;">${escapeHtml(group?.name || e.roomGroupId || '')}</span>
      <span style="margin-left:8px;font-size:12px;color:var(--text-3);">${formatDate(e.createdAt)}</span>
    </div>
    <div style="display:flex;align-items:center;gap:14px;padding:12px 0;border-top:1px solid var(--border);border-bottom:1px solid var(--border);margin-bottom:14px;">
      <div class="avatar" style="width:40px;height:40px;font-size:16px;">${avatarEl(payer?.avatarUrl, payer?.fullName)}</div>
      <div>
        <div style="font-size:12px;color:var(--text-2);">Ng\u01b0\u1eddi tr\u1ea3</div>
        <div style="font-weight:700;">${escapeHtml(payer?.fullName || payer?.email || '\u2014')}</div>
      </div>
      <div style="margin-left:auto;text-align:right;">
        <div style="font-size:12px;color:var(--text-2);">T\u1ed5ng ti\u1ec1n</div>
        <div class="mono" style="font-size:22px;font-weight:800;color:var(--primary);">${formatMoney(e.amount)}</div>
      </div>
    </div>
    ${modalRow('Lo\u1ea1i chia', splitLabel)}
    ${modalRow('Ng\xe0y t\u1ea1o', formatDate(e.createdAt))}
    ${e.note || e.description ? modalRow('Ghi ch\xfa', escapeHtml(e.note || e.description)) : ''}
    <div class="modal-section-label">Ng\u01b0\u1eddi tham gia (${participants.length})</div>
    <div style="display:flex;flex-direction:column;gap:4px;">${participantHtml}</div>
  `);
}

// ===== DEBT SUMMARY =====
function renderDebtSummary() {
  const section = document.getElementById('section-expenses');
  if (!section) return;

  const allShares      = state.expenseShares.filter(s => !s.isArchived);
  const unpaidShares   = allShares.filter(s => !s.isPaid);
  const paidShares     = allShares.filter(s => s.isPaid);
  const totalUnpaid    = unpaidShares.reduce((s, sh) => s + (sh.amountOwed || 0), 0);

  let summaryEl = document.getElementById('debtSummaryCard');
  if (!summaryEl) {
    summaryEl = document.createElement('div');
    summaryEl.id = 'debtSummaryCard';
    summaryEl.className = 'card';
    summaryEl.style.marginBottom = '16px';
    const debtSection = document.getElementById('debtSection');
    if (debtSection) {
      debtSection.parentNode.insertBefore(summaryEl, debtSection);
    }
  }

  const pairs = {};
  unpaidShares.forEach(sh => {
    const key = `${sh.fromUserId}|${sh.toUserId}`;
    if (!pairs[key]) {
      pairs[key] = { fromUserId: sh.fromUserId, toUserId: sh.toUserId, total: 0, count: 0 };
    }
    pairs[key].total += sh.amountOwed || 0;
    pairs[key].count += 1;
  });

  const sortedPairs = Object.values(pairs).sort((a, b) => b.total - a.total);
  const top5 = sortedPairs.slice(0, 5);

  const top5Html = top5.length
    ? top5.map(p => {
        const from = state.users.find(u => u.uid === p.fromUserId);
        const to   = state.users.find(u => u.uid === p.toUserId);
        return `<div style="display:flex;align-items:center;justify-content:space-between;padding:6px 0;border-bottom:1px solid var(--border);font-size:13px;">
          <span><strong>${escapeHtml(from?.fullName || p.fromUserId.slice(0, 8))}</strong> \u2192 <strong>${escapeHtml(to?.fullName || p.toUserId.slice(0, 8))}</strong></span>
          <span class="mono" style="font-weight:700;color:var(--danger-text);">${formatMoney(p.total)}</span>
        </div>`;
      }).join('')
    : '<div style="color:var(--text-3);font-size:13px;padding:8px 0;">Kh\xf4ng c\xf3 d\u1eef li\u1ec7u</div>';

  summaryEl.innerHTML = `
    <div style="padding:16px 20px;border-bottom:1px solid var(--border);font-size:14px;font-weight:700;display:flex;align-items:center;gap:10px;">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1v22"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
      T\u1ed5ng quan c\xf4ng n\u1ee3
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;padding:16px 20px;">
      <div>
        <div style="font-size:12px;color:var(--text-2);margin-bottom:4px;">T\u1ed5ng n\u1ee3 ch\u01b0a tr\u1ea3</div>
        <div class="mono" style="font-size:20px;font-weight:800;color:var(--danger-text);">${formatMoney(totalUnpaid)}</div>
      </div>
      <div>
        <div style="font-size:12px;color:var(--text-2);margin-bottom:4px;">S\u1ed1 kho\u1ea3n n\u1ee3</div>
        <div class="mono" style="font-size:20px;font-weight:800;">${unpaidShares.length}</div>
      </div>
      <div>
        <div style="font-size:12px;color:var(--text-2);margin-bottom:4px;">\u0110\xe3 thanh to\xe1n</div>
        <div class="mono" style="font-size:20px;font-weight:800;color:var(--success-text);">${paidShares.length} / ${allShares.length}</div>
      </div>
    </div>
    <div style="border-top:1px solid var(--border);padding:12px 20px;">
      <div style="font-size:12px;font-weight:600;color:var(--text-2);text-transform:uppercase;letter-spacing:0.05em;margin-bottom:8px;">Top 5 c\u1eb7p n\u1ee3 l\u1edbn nh\u1ea5t</div>
      ${top5Html}
    </div>`;
}

// ===== DEBT SECTION =====
function renderDebtSection() {
  const tbody = document.getElementById('debtTableBody');
  if (!tbody) return;

  const unpaidShares = state.expenseShares.filter(s => !s.isPaid && !s.isArchived);
  if (!unpaidShares.length) {
    tbody.innerHTML = emptyRow(7, 'Kh\xf4ng c\xf3 c\xf4ng n\u1ee3 ch\u01b0a thanh to\xe1n');
    return;
  }

  const pairs = {};
  unpaidShares.forEach(sh => {
    const key = `${sh.fromUserId}|${sh.toUserId}|${sh.roomGroupId}`;
    if (!pairs[key]) {
      pairs[key] = { fromUserId: sh.fromUserId, toUserId: sh.toUserId, roomGroupId: sh.roomGroupId, total: 0, ids: [] };
    }
    pairs[key].total += sh.amountOwed || 0;
    pairs[key].ids.push(sh.id);
  });

  const grouped = Object.values(pairs).sort((a, b) => b.total - a.total);

  tbody.innerHTML = '';
  grouped.forEach(g => {
    const debtor   = state.users.find(u => u.uid === g.fromUserId);
    const creditor = state.users.find(u => u.uid === g.toUserId);
    const group    = state.groups.find(gr => gr.id === g.roomGroupId);
    const tr = document.createElement('tr');

    const tdDebtor = document.createElement('td');
    tdDebtor.innerHTML = `<div class="user-cell">${makeAvatar(debtor?.avatarUrl, debtor?.fullName)}<span>${escapeHtml(debtor?.fullName || debtor?.email || g.fromUserId)}</span></div>`;

    const tdCreditor = document.createElement('td');
    tdCreditor.innerHTML = `<div class="user-cell">${makeAvatar(creditor?.avatarUrl, creditor?.fullName)}<span>${escapeHtml(creditor?.fullName || creditor?.email || g.toUserId)}</span></div>`;

    const tdGroup = document.createElement('td');
    tdGroup.textContent = group?.name || truncate(g.roomGroupId, 16) || '\u2014';

    const tdAmount = document.createElement('td');
    tdAmount.className = 'mono';
    tdAmount.style.fontWeight = '700';
    tdAmount.textContent = formatMoney(g.total);

    const tdCount = document.createElement('td');
    tdCount.innerHTML = `<span class="mono">${g.ids.length} kho\u1ea3n</span>`;

    const tdDate = document.createElement('td');
    tdDate.textContent = '\u2014';

    const tdActions = document.createElement('td');
    tdActions.className = 'action-cell';

    const btnMarkPaid = document.createElement('button');
    btnMarkPaid.className = 'btn btn-success';
    btnMarkPaid.textContent = '\u0110\xe3 tr\u1ea3';
    btnMarkPaid.addEventListener('click', () => {
      showConfirmModal(
        'Thanh to\xe1n c\xf4ng n\u1ee3',
        `\u0110\xe1nh d\u1ea5u t\u1ea5t c\u1ea3 ${g.ids.length} kho\u1ea3n n\u1ee3 gi\u1eefa ${escapeHtml(debtor?.fullName || g.fromUserId)} v\xe0 ${escapeHtml(creditor?.fullName || g.toUserId)} \u0111\xe3 thanh to\xe1n?`,
        () => markAllPaid(g.ids));
    });

    tdActions.appendChild(btnMarkPaid);
    tr.append(tdDebtor, tdCreditor, tdGroup, tdAmount, tdCount, tdDate, tdActions);
    tbody.appendChild(tr);
  });
}

async function markAllPaid(shareIds) {
  try {
    await Promise.allSettled(shareIds.map(id => updateDoc(doc(db, 'expense_shares', id), { isPaid: true, paidAt: serverTimestamp() })));
    shareIds.forEach(id => {
      const s = state.expenseShares.find(x => x.id === id);
      if (s) s.isPaid = true;
    });
    renderExpensesSection();
    showToast(`\u0110\xe3 \u0111\xe1nh d\u1ea5u ${shareIds.length} kho\u1ea3n n\u1ee3 \u0111\xe3 thanh to\xe1n`, 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}

async function markDebtPaid(shareId) {
  try {
    await updateDoc(doc(db, 'expense_shares', shareId), { isPaid: true, paidAt: serverTimestamp() });
    const s = state.expenseShares.find(x => x.id === shareId);
    if (s) s.isPaid = true;
    renderExpensesSection();
    showToast('\u0110\xe3 \u0111\xe1nh d\u1ea5u \u0111\xe3 thanh to\xe1n', 'success');
  } catch (e) {
    showToast('L\u1ed7i: ' + e.message, 'error');
  }
}


// =====================================================================
//  ANALYTICS SECTION
// =====================================================================

function renderAnalytics() {
  renderAnalyticsStatCards();
  renderUserGrowthChart();
  renderPostsByProvinceChart();
  renderHabitsChart();
  renderRequestStatusChart();
}

function renderAnalyticsStatCards() {
  const acceptedReqs = state.requests.filter(r => r.status === 'accepted').length;
  const totalReqs = state.requests.length;
  const matchRate = totalReqs > 0 ? Math.round((acceptedReqs / totalReqs) * 100) : 0;

  const totalExpense = state.expenses.reduce((s, e) => s + (e.amount || 0), 0);
  const groupCount = Math.max(1, state.groups.length);
  const avgExpense = Math.round(totalExpense / groupCount);

  const provinceCounts = {};
  state.posts.forEach(p => {
    if (p.province) provinceCounts[p.province] = (provinceCounts[p.province] || 0) + 1;
  });
  const topProvince = Object.entries(provinceCounts).sort((a, b) => b[1] - a[1])[0];

  const habitCounts = {};
  state.users.forEach(u => {
    if (Array.isArray(u.habits)) u.habits.forEach(h => { habitCounts[h] = (habitCounts[h] || 0) + 1; });
  });
  const topHabit = Object.entries(habitCounts).sort((a, b) => b[1] - a[1])[0];

  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('analyticsMatchRate', matchRate + '%');
  set('analyticsAvgExpense', formatMoney(avgExpense));
  set('analyticsTopProvince', topProvince ? escapeHtml(topProvince[0]) : '—');
  set('analyticsTopHabit', topHabit ? escapeHtml(habitLabel(topHabit[0])) : '—');
}

// =====================================================================
//  ANALYTICS CHARTS
// =====================================================================

function renderUserGrowthChart() {
  destroyChart('userGrowth');
  const labels = [];
  const data = [];
  const now = new Date();
  for (let i = 5; i >= 0; i--) {
    const m = new Date(now.getFullYear(), now.getMonth() - i, 1);
    labels.push(m.toLocaleDateString('vi-VN', { month: 'short', year: '2-digit' }));
    const end = new Date(now.getFullYear(), now.getMonth() - i + 1, 1);
    data.push(state.users.filter(u => {
      const d = toDate(u.createdAt);
      return d && d >= m && d < end;
    }).length);
  }

  const ctx = document.getElementById('chartUserGrowth')?.getContext('2d');
  if (!ctx) return;
  charts.userGrowth = new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: 'Người dùng mới',
        data,
        borderColor: '#2563EB',
        backgroundColor: 'rgba(37,99,235,0.08)',
        borderWidth: 2,
        fill: true,
        tension: 0.35,
        pointBackgroundColor: '#2563EB',
        pointRadius: 4,
      }]
    },
    options: {
      ...chartDefaults,
      scales: {
        y: { beginAtZero: true, grid: { color: '#E2E8F0' }, ticks: { color: '#94A3B8' } },
        x: { grid: { display: false }, ticks: { color: '#94A3B8' } }
      }
    }
  });
}

function renderPostsByProvinceChart() {
  destroyChart('postsByProvince');
  const counts = {};
  state.posts.forEach(p => {
    if (p.province) counts[p.province] = (counts[p.province] || 0) + 1;
  });
  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 8);
  const labels = sorted.map(e => e[0]);
  const data = sorted.map(e => e[1]);

  const ctx = document.getElementById('chartPostsByProvince')?.getContext('2d');
  if (!ctx) return;
  charts.postsByProvince = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Số bài đăng',
        data,
        backgroundColor: '#2563EB',
        borderRadius: 4,
      }]
    },
    options: {
      indexAxis: 'y',
      ...chartDefaults,
      scales: {
        x: { beginAtZero: true, grid: { color: '#E2E8F0' }, ticks: { color: '#94A3B8' } },
        y: { grid: { display: false }, ticks: { color: '#94A3B8' } }
      },
      plugins: {
        ...chartDefaults.plugins,
        legend: { display: false },
        tooltip: chartDefaults.plugins.tooltip,
        datalabels: { display: false }
      }
    },
    plugins: [{
      id: 'barLabels',
      afterDatasetsDraw(ch) {
        const ctx2 = ch.ctx;
        ch.data.datasets.forEach((ds, i) => {
          const meta = ch.getDatasetMeta(i);
          meta.data.forEach((bar, idx) => {
            const val = ds.data[idx];
            ctx2.fillStyle = '#0F172A';
            ctx2.font = '600 12px Plus Jakarta Sans, sans-serif';
            ctx2.textAlign = 'left';
            ctx2.textBaseline = 'middle';
            ctx2.fillText(val, bar.x + 6, bar.y);
          });
        });
      }
    }]
  });
}

function renderHabitsChart() {
  destroyChart('habits');
  const counts = {};
  state.users.forEach(u => {
    if (Array.isArray(u.habits)) u.habits.forEach(h => { counts[h] = (counts[h] || 0) + 1; });
  });
  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 8);
  const labels = sorted.map(e => e[0]);
  const data = sorted.map(e => e[1]);

  const bluePalette = ['#2563EB', '#3B82F6', '#60A5FA', '#93C5FD', '#1D4ED8', '#1E40AF', '#BFDBFE', '#DBEAFE'];

  const ctx = document.getElementById('chartHabits')?.getContext('2d');
  if (!ctx) return;
  charts.habits = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels,
      datasets: [{
        data,
        backgroundColor: bluePalette.slice(0, labels.length),
        borderWidth: 0,
      }]
    },
    options: {
      ...chartDefaults,
      cutout: '65%',
      plugins: {
        ...chartDefaults.plugins,
        legend: { position: 'right', labels: { color: '#64748B', font: { family: 'Plus Jakarta Sans', size: 12 } } }
      }
    }
  });
}

function renderRequestStatusChart() {
  destroyChart('requestStatus');
  const counts = { accepted: 0, pending: 0, rejected: 0 };
  state.requests.forEach(r => {
    const s = r.status || 'pending';
    if (counts[s] !== undefined) counts[s]++;
  });

  const ctx = document.getElementById('chartRequestStatus')?.getContext('2d');
  if (!ctx) return;
  charts.requestStatus = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['Đã chấp nhận', 'Đang chờ', 'Từ chối'],
      datasets: [{
        label: 'Số yêu cầu',
        data: [counts.accepted, counts.pending, counts.rejected],
        backgroundColor: ['#22C55E', '#F59E0B', '#EF4444'],
        borderRadius: 4,
      }]
    },
    options: {
      ...chartDefaults,
      scales: {
        y: { beginAtZero: true, grid: { color: '#E2E8F0' }, ticks: { color: '#94A3B8' } },
        x: { grid: { display: false }, ticks: { color: '#94A3B8' } }
      },
      plugins: { ...chartDefaults.plugins, legend: { display: false } }
    }
  });
}

// =====================================================================
//  RESIZE HANDLER
// =====================================================================

const handleResize = debounce(() => {
  const section = document.querySelector('.section.active')?.id;
  if (section === 'section-dashboard') {
    renderChartUsersByMonth();
    renderChartPostsByStatus();
  } else if (section === 'section-analytics') {
    renderUserGrowthChart();
    renderPostsByProvinceChart();
    renderHabitsChart();
    renderRequestStatusChart();
  }
}, 300);

window.addEventListener('resize', handleResize);
