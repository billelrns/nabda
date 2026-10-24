/**
 * Nabda - Ultra-Professional Admin Dashboard Controller
 * Author: فريق تحرير نبضة
 */

import { auth, db, storage } from '../firebase-init.js';
import { isHiddenProduct } from '../shop-rules.js';

let currentStaff = null;
let currentRole = 'agent'; // owner, supervisor, agent
let allOrders = [];
let allProducts = [];
let allReports = [];
let audioContext = null;
let activeModule = 'dashboard';

export async function initAdminDashboard() {
  setupThemeToggle();
  setupSidebarToggle();
  setupKeyboardShortcuts();
  setupIdleTimer();

  // Auth Guard
  auth.onAuthStateChanged(async (user) => {
    if (!user) {
      showLoginView();
      return;
    }

    try {
      const staffDoc = await db.collection('staff').doc(user.uid).get();
      if (!staffDoc.exists || staffDoc.data().isActive !== true) {
        showUnauthorizedView();
        return;
      }

      currentStaff = { uid: user.uid, email: user.email, ...staffDoc.data() };
      currentRole = currentStaff.role || 'agent';

      setupStaffUi();
      showDashboardView();

      // Listen to Realtime Orders
      listenToRealtimeOrders();

      // Setup Module Navigation
      setupNavRouting();

      // Load Initial Data
      loadInitialData();
    } catch (err) {
      console.error('Error verifying staff access:', err);
      showUnauthorizedView();
    }
  });
}

/* ── UI Auth Views ── */
function showLoginView() {
  document.getElementById('ad-app').style.display = 'none';
  document.getElementById('ad-unauthorized').style.display = 'none';
  document.getElementById('ad-login-view').style.display = 'flex';
}

function showUnauthorizedView() {
  document.getElementById('ad-app').style.display = 'none';
  document.getElementById('ad-login-view').style.display = 'none';
  document.getElementById('ad-unauthorized').style.display = 'flex';
}

function showDashboardView() {
  document.getElementById('ad-login-view').style.display = 'none';
  document.getElementById('ad-unauthorized').style.display = 'none';
  document.getElementById('ad-app').style.display = 'flex';
}

function setupStaffUi() {
  const nameEl = document.getElementById('ad-staff-name');
  const roleEl = document.getElementById('ad-staff-role');
  const avatarEl = document.getElementById('ad-staff-avatar');

  if (nameEl) nameEl.textContent = currentStaff.name || currentStaff.email.split('@')[0];
  if (roleEl) {
    const roleLabels = { owner: 'مالك التطبيق 👑', supervisor: 'مشرف عام 🛡️', agent: 'وكيل طلبات 📦' };
    roleEl.textContent = roleLabels[currentRole] || currentRole;
  }
  if (avatarEl) {
    avatarEl.textContent = (currentStaff.name || currentStaff.email)[0].toUpperCase();
  }

  // Restrict UI for agent
  if (currentRole === 'agent') {
    document.querySelectorAll('.ad-owner-only').forEach(el => el.style.display = 'none');
  }
}

/* ── Realtime Orders Listener & Audio Chime ── */
let isFirstOrdersLoad = true;

function listenToRealtimeOrders() {
  db.collection('orders')
    .orderBy('createdAt', 'desc')
    .onSnapshot((snap) => {
      let hasNewPending = false;

      snap.docChanges().forEach((change) => {
        if (change.type === 'added' && !isFirstOrdersLoad) {
          const o = change.doc.data();
          if (o.status === 'pending') {
            hasNewPending = true;
          }
        }
      });

      if (hasNewPending) {
        playOrderNotificationChime();
        showToast('🔔 طلب جديد وارد الآن! تفحصي قائمة الطلبات.', 'info');
      }

      allOrders = [];
      snap.forEach(doc => {
        allOrders.push({ id: doc.id, ...doc.data() });
      });

      isFirstOrdersLoad = false;

      // Update badge
      const pendingCount = allOrders.filter(o => o.status === 'pending').length;
      const badge = document.getElementById('ad-badge-orders');
      if (badge) {
        badge.textContent = pendingCount;
        badge.style.display = pendingCount > 0 ? 'inline-block' : 'none';
      }

      // Re-render active module if it is orders or dashboard
      if (activeModule === 'dashboard') renderDashboardModule();
      if (activeModule === 'orders') renderOrdersModule();
    }, (err) => {
      console.error('Orders snapshot error:', err);
    });
}

function playOrderNotificationChime() {
  try {
    if (!audioContext) {
      audioContext = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioContext.state === 'suspended') {
      audioContext.resume();
    }

    const now = audioContext.currentTime;

    // First soft chime (E5)
    const osc1 = audioContext.createOscillator();
    const gain1 = audioContext.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(659.25, now);
    gain1.gain.setValueAtTime(0.3, now);
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.5);
    osc1.connect(gain1);
    gain1.connect(audioContext.destination);
    osc1.start(now);
    osc1.stop(now + 0.5);

    // Second chime (G5)
    const osc2 = audioContext.createOscillator();
    const gain2 = audioContext.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(783.99, now + 0.15);
    gain2.gain.setValueAtTime(0.3, now + 0.15);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.7);
    osc2.connect(gain2);
    gain2.connect(audioContext.destination);
    osc2.start(now + 0.15);
    osc2.stop(now + 0.7);
  } catch (e) {
    console.warn('Audio chime error:', e);
  }
}

/* ── Navigation Routing ── */
function setupNavRouting() {
  document.querySelectorAll('.ad-nav-item').forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      document.querySelectorAll('.ad-nav-item').forEach(i => i.classList.remove('active'));
      item.classList.add('active');

      const targetMod = item.dataset.module;
      switchModule(targetMod);
    });
  });
}

function switchModule(mod) {
  activeModule = mod;
  document.querySelectorAll('.ad-module-pane').forEach(p => p.style.display = 'none');

  const pane = document.getElementById(`ad-mod-${mod}`);
  if (pane) pane.style.display = 'block';

  switch (mod) {
    case 'dashboard': renderDashboardModule(); break;
    case 'orders': renderOrdersModule(); break;
    case 'products': renderProductsModule(); break;
    case 'shipping': renderShippingModule(); break;
    case 'customers': renderCustomersModule(); break;
    case 'content': renderContentModule(); break;
    case 'moderation': renderModerationModule(); break;
    case 'waitlist': renderWaitlistModule(); break;
    case 'staff': renderStaffModule(); break;
    case 'logs': renderLogsModule(); break;
    case 'settings': renderSettingsModule(); break;
  }
}

async function loadInitialData() {
  renderDashboardModule();
}

/* ══════════════════════════════════════════════════════════════════
   1. Dashboard Module
   ══════════════════════════════════════════════════════════════════ */
let ordersChart = null;
let statusChart = null;
let wilayasChart = null;

function renderDashboardModule() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const todayOrders = allOrders.filter(o => {
    const t = o.createdAt?.toDate ? o.createdAt.toDate() : null;
    return t && t >= today;
  });

  const deliveredOrders = allOrders.filter(o => o.status === 'delivered');
  const deliveredRevenue = deliveredOrders.reduce((sum, o) => sum + ((o.unitPrice || 0) * (o.quantity || 1)), 0);

  const confirmedCount = allOrders.filter(o => ['confirmed', 'shipped', 'delivered'].includes(o.status)).length;
  const confirmRate = allOrders.length > 0 ? Math.round((confirmedCount / allOrders.length) * 100) : 0;

  const deliveredRate = confirmedCount > 0 ? Math.round((deliveredOrders.length / confirmedCount) * 100) : 0;
  const returnedCount = allOrders.filter(o => o.status === 'returned').length;
  const returnRate = confirmedCount > 0 ? Math.round((returnedCount / confirmedCount) * 100) : 0;

  // KPI UI
  document.getElementById('ad-kpi-today-orders').textContent = todayOrders.length;
  document.getElementById('ad-kpi-revenue').textContent = `${deliveredRevenue.toLocaleString()} دج`;
  document.getElementById('ad-kpi-confirm-rate').textContent = `${confirmRate}%`;
  document.getElementById('ad-kpi-deliver-rate').textContent = `${deliveredRate}%`;
  document.getElementById('ad-kpi-return-rate').textContent = `${returnRate}%`;

  // Charts
  renderDashboardCharts();

  // Recent 10 Orders table
  renderRecentOrdersTable();
}

function renderDashboardCharts() {
  if (typeof Chart === 'undefined') return;

  // 1. Orders Timeline (Last 30 Days)
  const ctxOrders = document.getElementById('ad-chart-orders')?.getContext('2d');
  if (ctxOrders) {
    if (ordersChart) ordersChart.destroy();

    const days = [];
    const counts = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const str = d.toLocaleDateString('ar-DZ', { month: 'short', day: 'numeric' });
      days.push(str);

      d.setHours(0, 0, 0, 0);
      const nextD = new Date(d);
      nextD.setDate(d.getDate() + 1);

      const dayOrders = allOrders.filter(o => {
        const t = o.createdAt?.toDate ? o.createdAt.toDate() : null;
        return t && t >= d && t < nextD;
      });
      counts.push(dayOrders.length);
    }

    ordersChart = new Chart(ctxOrders, {
      type: 'line',
      data: {
        labels: days,
        datasets: [{
          label: 'عدد الطلبات',
          data: counts,
          borderColor: '#E91E63',
          backgroundColor: 'rgba(233, 30, 99, 0.1)',
          fill: true,
          tension: 0.35,
          borderWidth: 2.5
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.04)' } },
          x: { grid: { display: false } }
        }
      }
    });
  }

  // 2. Status Donut Chart
  const ctxStatus = document.getElementById('ad-chart-status')?.getContext('2d');
  if (ctxStatus) {
    if (statusChart) statusChart.destroy();

    const statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'returned', 'cancelled'];
    const statusLabels = ['قيد المراجعة', 'مؤكد', 'مشحون', 'تم التسليم', 'مرتجع', 'ملغى'];
    const counts = statuses.map(s => allOrders.filter(o => o.status === s).length);

    statusChart = new Chart(ctxStatus, {
      type: 'doughnut',
      data: {
        labels: statusLabels,
        datasets: [{
          data: counts,
          backgroundColor: ['#E65100', '#0288D1', '#5E35B1', '#2E7D32', '#D84315', '#D32F2F'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { position: 'bottom', rtl: true } }
      }
    });
  }

  // 3. Top 10 Wilayas Bar Chart
  const ctxWilayas = document.getElementById('ad-chart-wilayas')?.getContext('2d');
  if (ctxWilayas) {
    if (wilayasChart) wilayasChart.destroy();

    const wilayaCounts = {};
    allOrders.forEach(o => {
      const w = o.wilaya || 'غير محدد';
      wilayaCounts[w] = (wilayaCounts[w] || 0) + 1;
    });

    const sortedWilayas = Object.entries(wilayaCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10);

    wilayasChart = new Chart(ctxWilayas, {
      type: 'bar',
      data: {
        labels: sortedWilayas.map(s => s[0]),
        datasets: [{
          label: 'عدد الطلبات',
          data: sortedWilayas.map(s => s[1]),
          backgroundColor: '#00897B',
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.04)' } },
          x: { grid: { display: false } }
        }
      }
    });
  }
}

function renderRecentOrdersTable() {
  const tbody = document.getElementById('ad-recent-orders-tbody');
  if (!tbody) return;

  const recent = allOrders.slice(0, 8);
  if (recent.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:24px;color:var(--ad-text-muted)">لا توجد طلبات مسجلة بعد.</td></tr>';
    return;
  }

  tbody.innerHTML = recent.map(o => {
    const total = ((o.unitPrice || 0) * (o.quantity || 1)) + (o.shippingFee || 0);
    const dateStr = o.createdAt?.toDate ? o.createdAt.toDate().toLocaleTimeString('ar-DZ', { hour: '2-digit', minute: '2-digit' }) : 'الآن';

    return `
      <tr>
        <td><strong>#${o.id.slice(-6)}</strong></td>
        <td>${escapeHtml(o.customerName || '—')}</td>
        <td>${escapeHtml(o.wilaya || '—')}</td>
        <td>${escapeHtml(o.productName || '—')} (×${o.quantity || 1})</td>
        <td class="ad-tabular"><strong>${total.toLocaleString()} دج</strong></td>
        <td><span class="ad-pill ${o.status || 'pending'}">${getStatusLabel(o.status)}</span></td>
      </tr>
    `;
  }).join('');
}

/* ══════════════════════════════════════════════════════════════════
   2. Orders Module (Kanban + Table + Order Drawer)
   ══════════════════════════════════════════════════════════════════ */
let ordersViewMode = 'kanban'; // kanban or table

function renderOrdersModule() {
  const kanbanBoard = document.getElementById('ad-orders-kanban');
  const tableView = document.getElementById('ad-orders-table-view');

  if (ordersViewMode === 'kanban') {
    if (kanbanBoard) kanbanBoard.style.display = 'flex';
    if (tableView) tableView.style.display = 'none';
    renderKanbanLanes();
  } else {
    if (kanbanBoard) kanbanBoard.style.display = 'none';
    if (tableView) tableView.style.display = 'block';
    renderOrdersTable();
  }
}

window.toggleOrdersView = function(mode) {
  ordersViewMode = mode;
  document.getElementById('ad-btn-kanban')?.classList.toggle('active', mode === 'kanban');
  document.getElementById('ad-btn-table')?.classList.toggle('active', mode === 'table');
  renderOrdersModule();
};

const ORDER_LANES = [
  { key: 'pending', label: 'قيد المراجعة', badgeClass: 'pending' },
  { key: 'no_answer', label: 'لم يرد', badgeClass: 'no_answer' },
  { key: 'confirmed', label: 'مؤكد', badgeClass: 'confirmed' },
  { key: 'shipped', label: 'تم الشحن', badgeClass: 'shipped' },
  { key: 'delivered', label: 'تم التسليم', badgeClass: 'delivered' },
  { key: 'returned', label: 'مرتجع', badgeClass: 'returned' },
  { key: 'cancelled', label: 'ملغى', badgeClass: 'cancelled' }
];

function renderKanbanLanes() {
  const board = document.getElementById('ad-orders-kanban');
  if (!board) return;

  board.innerHTML = ORDER_LANES.map(lane => {
    const laneOrders = allOrders.filter(o => (o.status || 'pending') === lane.key);

    return `
      <div class="ad-kanban-col" data-status="${lane.key}" ondragover="event.preventDefault()" ondrop="window.dropOrderCard(event, '${lane.key}')">
        <div class="ad-kanban-header">
          <div class="ad-kanban-title">
            <span class="ad-pill ${lane.badgeClass}">${lane.label}</span>
          </div>
          <span class="ad-tabular" style="font-weight:800;font-size:13px;color:var(--ad-text-muted)">${laneOrders.length}</span>
        </div>

        <div class="ad-kanban-cards">
          ${laneOrders.map(o => renderKanbanCard(o)).join('')}
        </div>
      </div>
    `;
  }).join('');
}

function renderKanbanCard(o) {
  const total = ((o.unitPrice || 0) * (o.quantity || 1)) + (o.shippingFee || 0);

  return `
    <div class="ad-kanban-card" draggable="true" ondragstart="window.dragOrderCard(event, '${o.id}')" onclick="window.openOrderDetailDrawer('${o.id}')">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
        <strong style="color:var(--ad-primary);font-size:13px">#${o.id.slice(-6)}</strong>
        <span style="font-size:11.5px;color:var(--ad-text-subtle)">${o.wilaya || '—'}</span>
      </div>

      <div style="font-size:14px;font-weight:800;color:var(--ad-text);margin-bottom:4px">${escapeHtml(o.customerName || 'عميلة')}</div>
      <div style="font-size:12px;color:var(--ad-text-muted);margin-bottom:8px" dir="ltr">${o.customerPhone || '—'}</div>

      <div style="display:flex;justify-content:space-between;align-items:center;border-top:1px solid var(--ad-border-light);padding-top:8px">
        <span style="font-size:11.5px;color:var(--ad-text-subtle)">×${o.quantity || 1} قطعة</span>
        <strong class="ad-tabular" style="font-size:14px;color:var(--ad-text)">${total.toLocaleString()} دج</strong>
      </div>
    </div>
  `;
}

let draggedOrderId = null;
window.dragOrderCard = function(e, id) {
  draggedOrderId = id;
};

window.dropOrderCard = async function(e, newStatus) {
  e.preventDefault();
  if (!draggedOrderId) return;

  const order = allOrders.find(o => o.id === draggedOrderId);
  if (order && order.status !== newStatus) {
    await updateOrderStatus(draggedOrderId, newStatus);
  }
  draggedOrderId = null;
};

async function updateOrderStatus(orderId, newStatus) {
  try {
    const historyItem = {
      status: newStatus,
      by: currentStaff?.name || currentStaff?.email || 'admin',
      at: new Date().toISOString(),
      note: `تم تغيير الحالة إلى ${getStatusLabel(newStatus)}`
    };

    await db.collection('orders').doc(orderId).update({
      status: newStatus,
      history: firebase.firestore.FieldValue.arrayUnion(historyItem),
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });

    logAdminAction('update_order_status', `تغيير حالة الطلب #${orderId.slice(-6)} إلى ${newStatus}`);
    showToast(`تم تحديث حالة الطلب #${orderId.slice(-6)} بنجاح ✓`, 'success');
  } catch (err) {
    console.error('Error updating order status:', err);
    showToast('تعذر تحديث حالة الطلب.', 'danger');
  }
}

/* Order Details Drawer */
window.openOrderDetailDrawer = function(orderId) {
  const o = allOrders.find(item => item.id === orderId);
  if (!o) return;

  const drawer = document.getElementById('ad-order-drawer');
  const backdrop = document.getElementById('ad-order-drawer-backdrop');

  const total = ((o.unitPrice || 0) * (o.quantity || 1)) + (o.shippingFee || 0);

  // Check 24-hr duplicates
  const samePhoneOrders = allOrders.filter(item => item.customerPhone === o.customerPhone && item.id !== o.id);
  const isDuplicate = samePhoneOrders.length > 0;

  const bodyEl = document.getElementById('ad-drawer-order-body');
  if (bodyEl) {
    bodyEl.innerHTML = `
      ${isDuplicate ? `
        <div style="background:#FFF3E0;border:1px solid #FFE0B2;border-radius:12px;padding:12px;margin-bottom:18px;display:flex;align-items:center;gap:10px">
          <span style="font-size:20px">⚠️</span>
          <div style="font-size:12.5px;color:#E65100;font-weight:700">
            تنبيه تكرار: هذا الرقم لديه ${samePhoneOrders.length} طلبات أخرى مسجلة!
          </div>
        </div>
      ` : ''}

      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px">
        <div>
          <h3 style="font-size:18px;font-weight:900;margin:0">طلب #${o.id.slice(-6)}</h3>
          <span style="font-size:12px;color:var(--ad-text-muted)">مصدر الطلب: ${o.source || 'الموقع'}</span>
        </div>
        <select class="ad-form-input" style="width:160px" onchange="window.updateOrderStatusFromDrawer('${o.id}', this.value)">
          ${ORDER_LANES.map(l => `<option value="${l.key}" ${o.status === l.key ? 'selected' : ''}>${l.label}</option>`).join('')}
        </select>
      </div>

      <!-- Customer Card -->
      <div style="background:var(--ad-card-inner);border:1px solid var(--ad-border);border-radius:14px;padding:16px;margin-bottom:18px">
        <div style="font-size:12px;color:var(--ad-text-muted);font-weight:800;margin-bottom:6px">بيانات العميلة:</div>
        <div style="font-size:16px;font-weight:800;margin-bottom:4px">${escapeHtml(o.customerName || '—')}</div>
        <div style="font-size:14px;color:var(--ad-primary);font-weight:800;margin-bottom:8px" dir="ltr">${o.customerPhone || '—'}</div>
        <div style="font-size:13px;color:var(--ad-text-muted)">📍 ${o.wilaya || ''} — ${o.commune || ''} — ${o.address || ''}</div>

        <div style="display:flex;gap:8px;margin-top:14px">
          <a href="tel:${o.customerPhone}" class="ad-btn ad-btn-secondary ad-btn-sm" style="flex:1;text-decoration:none">
            📞 اتصال
          </a>
          <button class="ad-btn ad-btn-secondary ad-btn-sm" style="flex:1;color:#25D366" onclick="window.sendWhatsAppTemplate('${o.customerPhone}', '${escapeHtml(o.customerName)}', '${o.id.slice(-6)}')">
            💬 واتساب
          </button>
        </div>
      </div>

      <!-- Item details -->
      <div style="background:var(--ad-card-inner);border:1px solid var(--ad-border);border-radius:14px;padding:16px;margin-bottom:18px">
        <div style="font-size:12px;color:var(--ad-text-muted);font-weight:800;margin-bottom:10px">المنتجات المطلوبة:</div>
        <div style="display:flex;justify-content:space-between;font-size:13.5px;margin-bottom:6px">
          <span>${escapeHtml(o.productName || 'منتج')} (×${o.quantity || 1})</span>
          <strong class="ad-tabular">${((o.unitPrice || 0) * (o.quantity || 1)).toLocaleString()} دج</strong>
        </div>
        <div style="display:flex;justify-content:space-between;font-size:13.5px;margin-bottom:8px;color:var(--ad-text-muted)">
          <span>الشحن (${o.deliveryType === 'office' ? 'مكتب' : 'منزل'}):</span>
          <strong class="ad-tabular">${(o.shippingFee || 0).toLocaleString()} دج</strong>
        </div>
        <div style="display:flex;justify-content:space-between;font-size:16px;font-weight:900;border-top:1px solid var(--ad-border);padding-top:8px">
          <span>الإجمالي:</span>
          <strong class="ad-tabular" style="color:var(--ad-primary)">${total.toLocaleString()} دج</strong>
        </div>
      </div>

      <!-- Print Buttons -->
      <div style="display:flex;gap:10px;margin-bottom:20px">
        <button class="ad-btn ad-btn-secondary" style="flex:1" onclick="window.printShippingLabel('${o.id}')">
          🖨️ ملصق شحن A6
        </button>
        <button class="ad-btn ad-btn-secondary" style="flex:1" onclick="window.printInvoice('${o.id}')">
          📄 طباعة الفاتورة
        </button>
      </div>

      <!-- Timeline History -->
      <div>
        <div style="font-size:13px;font-weight:800;color:var(--ad-text-muted);margin-bottom:10px">سجل الحالات:</div>
        <div style="display:flex;flex-direction:column;gap:8px;font-size:12.5px">
          ${(o.history || []).map(h => `
            <div style="padding:8px 12px;background:var(--ad-bg);border-radius:8px">
              <span style="font-weight:800">${h.note || h.status}</span>
              <span style="color:var(--ad-text-subtle);float:left">${h.at ? new Date(h.at).toLocaleDateString('ar-DZ') : ''}</span>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  }

  backdrop.classList.add('open');
};

window.closeOrderDetailDrawer = function() {
  document.getElementById('ad-order-drawer-backdrop')?.classList.remove('open');
};

window.updateOrderStatusFromDrawer = async function(orderId, status) {
  await updateOrderStatus(orderId, status);
  window.closeOrderDetailDrawer();
};

window.sendWhatsAppTemplate = function(phone, name, shortId) {
  if (!phone) return;
  const cleanPhone = phone.replace(/^0/, '213');
  const msg = encodeURIComponent(`السلام عليكم أختي ${name}، معكِ خدمة عملاء متجر نبضة بخصوص طلبيتكِ #${shortId}. هل يمكننا تأكيد عنوان التوصيل لشحن طلبكِ اليوم؟`);
  window.open(`https://wa.me/${cleanPhone}?text=${msg}`, '_blank');
};

window.printShippingLabel = function(orderId) {
  const o = allOrders.find(item => item.id === orderId);
  if (!o) return;

  const total = ((o.unitPrice || 0) * (o.quantity || 1)) + (o.shippingFee || 0);

  const printArea = document.getElementById('nb-print-area');
  printArea.innerHTML = `
    <div style="text-align:center;border-bottom:2px solid #000;padding-bottom:8px;margin-bottom:10px">
      <h2 style="margin:0;font-size:22px">متجر نبضة — NABDA</h2>
      <div style="font-size:12px">طرد تجاري — الدفع عند الاستلام (COD)</div>
    </div>

    <div style="margin-bottom:12px;font-size:13px">
      <div><strong>رقم الطلب:</strong> #${o.id.slice(-6)}</div>
      <div><strong>العميلة:</strong> ${o.customerName}</div>
      <div><strong>الهاتف:</strong> ${o.customerPhone}</div>
      <div><strong>الولاية:</strong> ${o.wilaya} | <strong>البلدية:</strong> ${o.commune || '—'}</div>
      <div><strong>العنوان:</strong> ${o.address || '—'}</div>
      <div><strong>نوع التوصيل:</strong> ${o.deliveryType === 'office' ? 'مكتب' : 'باب المنزل'}</div>
    </div>

    <div style="border-top:1px dashed #000;padding-top:8px;margin-bottom:14px;font-size:12px">
      <div><strong>المحتوى:</strong> ${o.productName} (×${o.quantity})</div>
    </div>

    <div style="text-align:center;border:2px solid #000;padding:10px;font-size:18px;font-weight:900">
      المبلغ المطلوب تحصيله:<br>
      ${total.toLocaleString()} دج
    </div>
  `;

  window.print();
};

window.printInvoice = function(orderId) {
  window.printShippingLabel(orderId);
};

/* ══════════════════════════════════════════════════════════════════
   3. Products Module (Catalog, Compliance Guard, Upload)
   ══════════════════════════════════════════════════════════════════ */
async function renderProductsModule() {
  const tbody = document.getElementById('ad-products-tbody');
  if (!tbody) return;

  tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:30px">جاري جلب المنتجات...</td></tr>';

  try {
    const snap = await db.collection('products').get();
    allProducts = [];
    snap.forEach(doc => {
      allProducts.push({ id: doc.id, ...doc.data() });
    });

    if (allProducts.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:30px">لا توجد منتجات مسجلة بعد.</td></tr>';
      return;
    }

    tbody.innerHTML = allProducts.map(p => {
      const img = p.image || p.imageUrl || (p.images && p.images[0]) || '/landing-assets/slide-store.png';
      const isCompliantHidden = isHiddenProduct(p);

      return `
        <tr>
          <td>
            <img src="${img}" style="width:44px;height:44px;border-radius:10px;object-fit:cover">
          </td>
          <td>
            <strong>${escapeHtml(p.name || '—')}</strong>
            ${isCompliantHidden ? '<div style="color:var(--ad-danger);font-size:11px;font-weight:800">⚠️ مخالف: مكملات/أجهزة طبية</div>' : ''}
          </td>
          <td>${escapeHtml(p.category || '—')}</td>
          <td class="ad-tabular"><strong>${Number(p.price || 0).toLocaleString()} دج</strong></td>
          <td class="ad-tabular">${p.stock || 0}</td>
          <td>
            <input type="checkbox" ${p.active ? 'checked' : ''} ${isCompliantHidden ? 'disabled' : ''} onchange="window.toggleProductActive('${p.id}', this.checked)">
          </td>
          <td>
            <button class="ad-btn ad-btn-secondary ad-btn-sm" onclick="window.openEditProductModal('${p.id}')">تعديل ✏️</button>
            ${currentRole !== 'agent' ? `<button class="ad-btn ad-btn-danger ad-btn-sm" onclick="window.deleteProduct('${p.id}')">حذف 🗑️</button>` : ''}
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    console.error('Error loading products for admin:', err);
  }
}

window.toggleProductActive = async function(id, isActive) {
  try {
    await db.collection('products').doc(id).update({
      active: isActive,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('تم تحديث حالة تفعيل المنتج.', 'success');
  } catch (err) {
    console.error('Error toggling active:', err);
    showToast('تعذر تحديث حالة المنتج.', 'danger');
  }
};

window.openNewProductModal = function() {
  document.getElementById('ad-product-modal-title').textContent = 'إضافة منتج جديد';
  document.getElementById('ad-p-form-id').value = '';
  document.getElementById('ad-p-form-name').value = '';
  document.getElementById('ad-p-form-slug').value = '';
  document.getElementById('ad-p-form-category').value = 'مستلزمات الطفل';
  document.getElementById('ad-p-form-price').value = '';
  document.getElementById('ad-p-form-old-price').value = '';
  document.getElementById('ad-p-form-cost').value = '';
  document.getElementById('ad-p-form-stock').value = '15';
  document.getElementById('ad-p-form-desc').value = '';
  document.getElementById('ad-p-compliance-alert').style.display = 'none';

  document.getElementById('ad-product-modal').classList.add('open');
};

window.openEditProductModal = async function(id) {
  const p = allProducts.find(item => item.id === id);
  if (!p) return;

  document.getElementById('ad-product-modal-title').textContent = 'تعديل المنتج';
  document.getElementById('ad-p-form-id').value = p.id;
  document.getElementById('ad-p-form-name').value = p.name || '';
  document.getElementById('ad-p-form-slug').value = p.slug || '';
  document.getElementById('ad-p-form-category').value = p.category || 'مستلزمات الطفل';
  document.getElementById('ad-p-form-price').value = p.price || '';
  document.getElementById('ad-p-form-old-price').value = p.oldPrice || p.originalPrice || '';
  document.getElementById('ad-p-form-stock').value = p.stock || 0;
  document.getElementById('ad-p-form-desc').value = p.description || p.desc || '';

  // Check compliance
  const isHidden = isHiddenProduct(p);
  const alertEl = document.getElementById('ad-p-compliance-alert');
  if (alertEl) alertEl.style.display = isHidden ? 'block' : 'none';

  // Fetch private cost price
  try {
    const privDoc = await db.collection('products_private').doc(id).get();
    if (privDoc.exists) {
      document.getElementById('ad-p-form-cost').value = privDoc.data().costPrice || '';
    }
  } catch (e) {}

  document.getElementById('ad-product-modal').classList.add('open');
};

window.closeProductModal = function() {
  document.getElementById('ad-product-modal').classList.remove('open');
};

window.saveProductForm = async function() {
  const id = document.getElementById('ad-p-form-id').value;
  const name = document.getElementById('ad-p-form-name').value.trim();
  let slug = document.getElementById('ad-p-form-slug').value.trim();
  const category = document.getElementById('ad-p-form-category').value;
  const price = parseFloat(document.getElementById('ad-p-form-price').value) || 0;
  const oldPrice = parseFloat(document.getElementById('ad-p-form-old-price').value) || null;
  const costPrice = parseFloat(document.getElementById('ad-p-form-cost').value) || null;
  const stock = parseInt(document.getElementById('ad-p-form-stock').value, 10) || 0;
  const desc = document.getElementById('ad-p-form-desc').value.trim();

  if (!name || price <= 0) {
    alert('يرجى إدخال اسم المنتج وسعر صحيح.');
    return;
  }

  // Compliance Guard
  const tempCheck = { name, category };
  if (isHiddenProduct(tempCheck)) {
    alert('تنبيه امتثال: هذا المنتج يندرج تحت المكملات الغذائية أو الأجهزة الطبية وهو ممنوع في متجر نبضة وفق سياسة Google Play والمنصة.');
    return;
  }

  if (!slug) {
    slug = name.replace(/[^\u0600-\u06FFa-zA-Z0-9\s-]/g, '').replace(/\s+/g, '-').slice(0, 45) + '-' + Math.random().toString(36).substr(2, 4);
  }

  const productData = {
    name,
    slug,
    category,
    price,
    oldPrice,
    stock,
    description: desc,
    active: true,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  };

  try {
    let targetId = id;
    if (id) {
      await db.collection('products').doc(id).update(productData);
    } else {
      productData.createdAt = firebase.firestore.FieldValue.serverTimestamp();
      const docRef = await db.collection('products').add(productData);
      targetId = docRef.id;
    }

    // Save private cost price
    if (costPrice !== null) {
      await db.collection('products_private').doc(targetId).set({
        costPrice: costPrice,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    }

    showToast('تم حفظ المنتج بنجاح ✓', 'success');
    window.closeProductModal();
    renderProductsModule();
  } catch (err) {
    console.error('Error saving product:', err);
    alert('حدث خطأ أثناء حفظ المنتج: ' + err.message);
  }
};

window.deleteProduct = async function(id) {
  if (!confirm('هل أنتِ متأكدة من حذف هذا المنتج نهائياً؟')) return;
  try {
    await db.collection('products').doc(id).delete();
    showToast('تم حذف المنتج بنجاح.', 'success');
    renderProductsModule();
  } catch (err) {
    console.error('Error deleting product:', err);
  }
};

/* ══════════════════════════════════════════════════════════════════
   4. Shipping Module (58 Wilayas)
   ══════════════════════════════════════════════════════════════════ */
async function renderShippingModule() {
  const tbody = document.getElementById('ad-shipping-tbody');
  if (!tbody) return;

  try {
    const res = await fetch('/data/algeria_cities.json');
    const data = await res.json();
    const snap = await db.collection('site_config').doc('shipping').get();
    const config = snap.exists ? snap.data() : {};

    tbody.innerHTML = (data.wilayas || []).map(w => {
      const name = w.wilaya_name_arabic;
      const rate = config[name] || {};
      const home = rate.home || 600;
      const desk = rate.desk || 400;

      return `
        <tr>
          <td><strong>${w.wilaya_id}</strong></td>
          <td><strong>${name}</strong> (${w.wilaya_name_latin})</td>
          <td>
            <input type="number" class="ad-form-input" style="width:110px" id="ship-home-${w.wilaya_id}" value="${home}">
          </td>
          <td>
            <input type="number" class="ad-form-input" style="width:110px" id="ship-desk-${w.wilaya_id}" value="${desk}">
          </td>
          <td>
            <button class="ad-btn ad-btn-primary ad-btn-sm" onclick="window.saveWilayaShipping('${name}', ${w.wilaya_id})">حفظ</button>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    console.error('Error rendering shipping module:', err);
  }
}

window.saveWilayaShipping = async function(name, id) {
  const home = parseFloat(document.getElementById(`ship-home-${id}`)?.value) || 600;
  const desk = parseFloat(document.getElementById(`ship-desk-${id}`)?.value) || 400;

  try {
    await db.collection('site_config').doc('shipping').set({
      [name]: { home, desk }
    }, { merge: true });
    showToast(`تم حفظ تسعيرة ${name} بنجاح ✓`, 'success');
  } catch (err) {
    console.error('Error saving shipping:', err);
  }
};

/* ══════════════════════════════════════════════════════════════════
   5. Customers Module (Derived from Orders by Phone)
   ══════════════════════════════════════════════════════════════════ */
function renderCustomersModule() {
  const tbody = document.getElementById('ad-customers-tbody');
  if (!tbody) return;

  const phoneMap = {};
  allOrders.forEach(o => {
    const p = o.customerPhone;
    if (!p) return;
    if (!phoneMap[p]) {
      phoneMap[p] = {
        name: o.customerName || 'عميلة',
        phone: p,
        wilaya: o.wilaya || '—',
        ordersCount: 0,
        deliveredCount: 0,
        totalSpent: 0
      };
    }
    phoneMap[p].ordersCount++;
    if (o.status === 'delivered') {
      phoneMap[p].deliveredCount++;
      phoneMap[p].totalSpent += ((o.unitPrice || 0) * (o.quantity || 1));
    }
  });

  const customers = Object.values(phoneMap).sort((a, b) => b.totalSpent - a.totalSpent);

  tbody.innerHTML = customers.map(c => `
    <tr>
      <td><strong>${escapeHtml(c.name)}</strong></td>
      <td dir="ltr">${c.phone}</td>
      <td>${escapeHtml(c.wilaya)}</td>
      <td class="ad-tabular">${c.ordersCount} طلبات</td>
      <td class="ad-tabular" style="color:var(--ad-success);font-weight:800">${c.deliveredCount} مستلم</td>
      <td class="ad-tabular"><strong>${c.totalSpent.toLocaleString()} دج</strong></td>
      <td>
        <button class="ad-btn ad-btn-danger ad-btn-sm" onclick="window.blockPhone('${c.phone}')">حظر الرقم 🚫</button>
      </td>
    </tr>
  `).join('');
}

window.blockPhone = async function(phone) {
  if (!confirm(`هل أنتِ متأكدة من حظر الرقم ${phone} وإضافته للقائمة السوداء؟`)) return;
  try {
    await db.collection('blocked_phones').doc(phone).set({
      blockedAt: firebase.firestore.FieldValue.serverTimestamp(),
      blockedBy: currentStaff?.email || 'admin'
    });
    showToast(`تم حظر الرقم ${phone} بنجاح.`, 'success');
  } catch (err) {
    console.error('Error blocking phone:', err);
  }
};

/* ══════════════════════════════════════════════════════════════════
   6. Moderation Module (Community Reports)
   ══════════════════════════════════════════════════════════════════ */
async function renderModerationModule() {
  const tbody = document.getElementById('ad-moderation-tbody');
  if (!tbody) return;

  try {
    const snap = await db.collection('reports').get();
    allReports = [];
    snap.forEach(doc => allReports.push({ id: doc.id, ...doc.data() }));

    if (allReports.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:24px">لا توجد بلاغات معلقة حالياً ✓</td></tr>';
      return;
    }

    tbody.innerHTML = allReports.map(r => `
      <tr>
        <td><strong>#${r.id.slice(-6)}</strong></td>
        <td>${escapeHtml(r.reason || 'محتوى غير لائق')}</td>
        <td>${r.postId || '—'}</td>
        <td><span class="ad-pill pending">${r.status || 'معلق'}</span></td>
        <td>
          <button class="ad-btn ad-btn-danger ad-btn-sm" onclick="window.deleteReportedPost('${r.postId}', '${r.id}')">حذف المنشور</button>
          <button class="ad-btn ad-btn-secondary ad-btn-sm" onclick="window.dismissReport('${r.id}')">تجاهل البلاغ</button>
        </td>
      </tr>
    `).join('');
  } catch (err) {
    console.error('Error loading reports:', err);
  }
}

window.deleteReportedPost = async function(postId, reportId) {
  if (!confirm('حذف هذا المنشور نهائياً؟')) return;
  try {
    await db.collection('community_posts').doc(postId).delete();
    await db.collection('reports').doc(reportId).update({ status: 'resolved' });
    showToast('تم حذف المنشور المبلغ عنه.', 'success');
    renderModerationModule();
  } catch (e) {
    console.error(e);
  }
};

window.dismissReport = async function(reportId) {
  try {
    await db.collection('reports').doc(reportId).delete();
    showToast('تم تجاهل البلاغ.', 'info');
    renderModerationModule();
  } catch (e) {
    console.error(e);
  }
};

/* ══════════════════════════════════════════════════════════════════
   7. Staff, Logs, Settings, Helpers
   ══════════════════════════════════════════════════════════════════ */
async function renderStaffModule() {
  const tbody = document.getElementById('ad-staff-tbody');
  if (!tbody || currentRole !== 'owner') return;

  try {
    const snap = await db.collection('staff').get();
    tbody.innerHTML = snap.docs.map(doc => {
      const s = doc.data();
      return `
        <tr>
          <td><strong>${escapeHtml(s.name || doc.id)}</strong></td>
          <td>${escapeHtml(s.email || '—')}</td>
          <td><span class="ad-pill ${s.role === 'owner' ? 'shipped' : 'confirmed'}">${s.role}</span></td>
          <td>${s.isActive ? 'نشط ✓' : 'معطل'}</td>
          <td>
            <button class="ad-btn ad-btn-secondary ad-btn-sm" onclick="window.toggleStaffActive('${doc.id}', ${!s.isActive})">
              ${s.isActive ? 'تعطيل' : 'تفعيل'}
            </button>
          </td>
        </tr>
      `;
    }).join('');
  } catch (e) {}
}

window.toggleStaffActive = async function(uid, newStatus) {
  try {
    await db.collection('staff').doc(uid).update({ isActive: newStatus });
    renderStaffModule();
  } catch (e) {}
};

async function logAdminAction(action, target) {
  try {
    await db.collection('admin_logs').add({
      uid: currentStaff?.uid || 'anonymous',
      name: currentStaff?.name || currentStaff?.email || 'admin',
      action: action,
      target: target,
      at: firebase.firestore.FieldValue.serverTimestamp()
    });
  } catch (e) {}
}

function showToast(message, type = 'info') {
  let container = document.getElementById('ad-toasts');
  if (!container) {
    container = document.createElement('div');
    container.id = 'ad-toasts';
    container.className = 'ad-toast-container';
    document.body.appendChild(container);
  }

  const toast = document.createElement('div');
  toast.className = `ad-toast ${type}`;
  toast.innerHTML = `<span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

function setupThemeToggle() {
  window.toggleAdminTheme = function() {
    const current = document.documentElement.getAttribute('data-theme');
    const target = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', target);
    localStorage.setItem('nb_admin_theme', target);
  };

  const saved = localStorage.getItem('nb_admin_theme') || 'light';
  document.documentElement.setAttribute('data-theme', saved);
}

function setupSidebarToggle() {
  window.toggleAdminSidebar = function() {
    document.getElementById('ad-sidebar')?.classList.toggle('collapsed');
  };
}

function setupKeyboardShortcuts() {
  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      document.getElementById('ad-global-search')?.focus();
    }
  });
}

function setupIdleTimer() {
  let idleTime = 0;
  const maxIdleMinutes = 30;

  function resetTimer() { idleTime = 0; }
  window.onmousemove = resetTimer;
  window.onkeypress = resetTimer;

  setInterval(() => {
    idleTime++;
    if (idleTime >= maxIdleMinutes) {
      alert('تم قفل اللوحة بسبب عدم النشاط لمدة 30 دقيقة لحماية البيانات.');
      auth.signOut();
    }
  }, 60000);
}

function getStatusLabel(status) {
  const map = {
    pending: 'قيد المراجعة',
    no_answer: 'لم يرد',
    confirmed: 'مؤكد',
    shipped: 'تم الشحن',
    delivered: 'تم التسليم',
    returned: 'مرتجع',
    cancelled: 'ملغى'
  };
  return map[status] || status || 'جديد';
}

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>"']/g, m => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[m]));
}
