// Nabda — Settings + Admin Dashboard
const ADM = window.NABDA_DATA;

function SettingsScreen({ onOpenAdmin }) {
  return (
    <div className="screen-enter">
      {/* Profile header */}
      <div style={{
        background: 'linear-gradient(160deg, #FCE4EC 0%, #E0F2F1 100%)',
        padding: '20px 20px 30px', borderRadius: '0 0 28px 28px',
        textAlign: 'center', position: 'relative',
      }}>
        <div style={{
          width: 86, height: 86, borderRadius: '50%', margin: '6px auto 12px',
          background: 'linear-gradient(135deg, #E91E63, #7E57C2)',
          color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 32, fontWeight: 800,
          boxShadow: '0 8px 20px rgba(233,30,99,.3)', border: '4px solid #fff',
        }}>س</div>
        <h2 className="t-h1">سارة بن علي</h2>
        <p className="t-small" style={{ marginTop: 4 }}>الأسبوع 25 من الحمل • الجزائر العاصمة</p>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 8, marginTop: 12 }}>
          <span className="pill pill-pink">💕 عضوة منذ 2025</span>
          <span className="pill pill-teal">⭐ 12 طلب</span>
        </div>
      </div>

      <div style={{ padding: 20 }}>
        {[
          { icon: '👤', t: 'حسابي ومعلوماتي', d: 'تعديل البيانات الشخصية' },
          { icon: '🤰', t: 'متابعة الحمل', d: 'الأسبوع، الموعد المتوقع' },
          { icon: '📦', t: 'طلباتي', d: '3 طلبات نشطة' },
          { icon: '❤️', t: 'المفضّلة', d: '14 منتج' },
          { icon: '📍', t: 'العناوين', d: 'الجزائر العاصمة' },
          { icon: '🔔', t: 'الإشعارات', d: 'مفعّلة' },
          { icon: '🌙', t: 'المظهر', d: 'فاتح' },
          { icon: '🌍', t: 'اللغة', d: 'العربية' },
          { icon: '🛡️', t: 'الخصوصية والأمان' },
          { icon: '❓', t: 'المساعدة والدعم' },
        ].map((it, i) => (
          <button key={i} style={settingRow}>
            <span style={{ fontSize: 22 }}>{it.icon}</span>
            <div style={{ flex: 1, textAlign: 'right' }}>
              <p style={{ margin: 0, fontSize: 14, fontWeight: 700 }}>{it.t}</p>
              {it.d && <p className="t-small" style={{ marginTop: 2 }}>{it.d}</p>}
            </div>
            <Icon name="chevron_left" size={18} color="#8B8190" />
          </button>
        ))}

        {/* Admin entry */}
        <button onClick={onOpenAdmin} style={{
          ...settingRow,
          background: 'linear-gradient(135deg, #EDE7F6 0%, #fff 100%)',
          border: '1px solid #D1C4E9', marginTop: 16,
        }}>
          <span style={{ fontSize: 22 }}>⚙️</span>
          <div style={{ flex: 1, textAlign: 'right' }}>
            <p style={{ margin: 0, fontSize: 14, fontWeight: 800, color: 'var(--purple-700)' }}>لوحة المشرف</p>
            <p className="t-small" style={{ marginTop: 2 }}>للمسؤولات فقط</p>
          </div>
          <span className="pill pill-purple">Admin</span>
        </button>

        <button style={{
          ...settingRow, color: '#D32F2F', marginTop: 12,
          background: '#FFEBEE', border: 'none',
        }}>
          <span style={{ fontSize: 20 }}>🚪</span>
          <span style={{ flex: 1, textAlign: 'right', fontWeight: 700, fontSize: 14 }}>تسجيل الخروج</span>
        </button>

        <p className="t-small" style={{ textAlign: 'center', marginTop: 24 }}>نبضة • الإصدار 2.4.1</p>
      </div>
    </div>
  );
}

const settingRow = {
  width: '100%', display: 'flex', alignItems: 'center', gap: 14,
  padding: 14, borderRadius: 16, border: '1px solid var(--line)',
  background: 'var(--surface)', cursor: 'pointer', fontFamily: 'inherit',
  marginBottom: 8,
};

// ────────────── Admin Dashboard ──────────────
function AdminScreen({ onBack }) {
  return (
    <div className="screen-enter" style={{ height: '100%', overflowY: 'auto' }}>
      {/* Purple appbar */}
      <div className="appbar appbar-purple" style={{ paddingBottom: 60 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative', zIndex: 1 }}>
          <IconBtn name="arrow_right" onClick={onBack} />
          <div style={{ flex: 1 }}>
            <p style={{ margin: 0, fontSize: 12, color: 'rgba(255,255,255,.85)', fontWeight: 700 }}>أهلًا بكِ</p>
            <h2 style={{ margin: '2px 0 0', fontSize: 20, fontWeight: 800, color: '#fff' }}>لوحة المشرف 🛡️</h2>
          </div>
          <IconBtn name="bell" badge={5} />
        </div>
      </div>

      {/* Stats cards (overlap) */}
      <div style={{ padding: '0 20px', marginTop: -40, position: 'relative', zIndex: 2 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {ADM.adminStats.map((s, i) => (
            <div key={i} className="card" style={{ padding: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 12,
                  background: i % 2 === 0 ? 'var(--purple-50)' : 'var(--pink-50)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18,
                }}>{s.icon}</div>
                <span style={{ fontSize: 11, fontWeight: 800, color: 'var(--green)' }}>{s.delta}</span>
              </div>
              <p style={{ margin: '12px 0 0', fontSize: 18, fontWeight: 800 }}>{s.value}</p>
              <p className="t-small" style={{ marginTop: 2 }}>{s.label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Quick chart */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="card" style={{ padding: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <h3 className="t-h3">الإيرادات الأسبوعية</h3>
              <p className="t-small" style={{ marginTop: 4 }}>آخر 7 أيام</p>
            </div>
            <span className="pill pill-purple">+18% ↑</span>
          </div>
          <MiniChart />
        </div>
      </div>

      {/* Modules grid */}
      <div className="section-title"><h3>الوحدات الإدارية</h3></div>
      <div style={{ padding: '0 20px 30px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {ADM.adminModules.map((m, i) => (
          <button key={i} style={{
            border: 0, background: 'var(--surface)', borderRadius: 18,
            padding: 16, cursor: 'pointer', textAlign: 'right',
            fontFamily: 'inherit', boxShadow: 'var(--shadow-sm)',
            display: 'flex', flexDirection: 'column', gap: 6,
            minHeight: 110,
          }}>
            <span style={{ fontSize: 28 }}>{m.icon}</span>
            <p style={{ margin: '4px 0 0', fontSize: 14, fontWeight: 800 }}>{m.title}</p>
            <p className="t-small" style={{ fontSize: 11, lineHeight: 1.5 }}>{m.desc}</p>
          </button>
        ))}
      </div>
    </div>
  );
}

function MiniChart() {
  const bars = [42, 58, 35, 71, 64, 88, 76];
  const days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
  const max = Math.max(...bars);
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 100, marginTop: 14 }}>
      {bars.map((b, i) => (
        <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
          <div style={{
            width: '100%', height: `${(b / max) * 80}px`, borderRadius: 6,
            background: i === bars.length - 1
              ? 'linear-gradient(180deg, #7E57C2, #5E35B1)'
              : 'linear-gradient(180deg, #E1BEE7, #CE93D8)',
          }} />
          <span style={{ fontSize: 10, color: 'var(--ink-3)' }}>{days[i]}</span>
        </div>
      ))}
    </div>
  );
}

Object.assign(window, { SettingsScreen, AdminScreen });
