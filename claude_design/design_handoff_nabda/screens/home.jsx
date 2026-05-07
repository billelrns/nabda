// Nabda — Home screen (pregnancy week)
const D = window.NABDA_DATA;

function HomeScreen({ week, onOpenArticle }) {
  const info = D.weekInfo[week] || D.weekInfo[25];
  const progressPct = (week / 40) * 100;

  return (
    <div className="screen-enter">
      {/* Hero header — gradient with pregnancy info */}
      <div style={{
        background: 'linear-gradient(160deg, #FCE4EC 0%, #FFF8FB 50%, #E0F2F1 100%)',
        padding: '8px 20px 24px',
        borderRadius: '0 0 32px 32px',
        position: 'relative',
        overflow: 'hidden',
      }}>
        {/* Decorative blobs */}
        <div style={{ position: 'absolute', top: -40, left: -40, width: 160, height: 160, borderRadius: '50%', background: 'radial-gradient(circle, rgba(233,30,99,.12), transparent 70%)' }} />
        <div style={{ position: 'absolute', bottom: -30, right: -30, width: 140, height: 140, borderRadius: '50%', background: 'radial-gradient(circle, rgba(0,137,123,.12), transparent 70%)' }} />

        {/* Greeting row */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0 16px', position: 'relative', zIndex: 1 }}>
          <div>
            <p className="t-small" style={{ color: 'var(--ink-3)' }}>صباح الخير 🌷</p>
            <h2 style={{ margin: '2px 0 0', fontSize: 22, fontWeight: 800 }}>{D.user.name}</h2>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <IconBtn name="bell" bg="rgba(255,255,255,.7)" color="#5E35B1" badge={3} />
            <div style={{
              width: 40, height: 40, borderRadius: '50%',
              background: 'linear-gradient(135deg, #E91E63, #7E57C2)',
              color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontWeight: 800, fontSize: 16, boxShadow: '0 4px 12px rgba(233,30,99,.3)',
            }}>س</div>
          </div>
        </div>

        {/* Pregnancy week card */}
        <div style={{
          background: 'rgba(255,255,255,.7)',
          backdropFilter: 'blur(12px)',
          borderRadius: 24,
          padding: 18,
          border: '1px solid rgba(255,255,255,.8)',
          boxShadow: '0 8px 24px rgba(233,30,99,.08)',
          position: 'relative',
          zIndex: 1,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            {/* Fetus avatar */}
            <div style={{
              width: 90, height: 90, borderRadius: '50%',
              background: 'radial-gradient(circle at 35% 30%, #FCE4EC, #F8BBD0 60%, #F06292 100%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 44, flexShrink: 0,
              boxShadow: 'inset -6px -10px 16px rgba(194,24,91,.2), 0 6px 18px rgba(233,30,99,.25)',
              position: 'relative',
            }}>
              <div style={{ filter: 'drop-shadow(0 2px 4px rgba(0,0,0,.15))' }}>👶</div>
            </div>
            <div style={{ flex: 1 }}>
              <div className="pill pill-pink" style={{ marginBottom: 6 }}>الأسبوع {week} من 40</div>
              <h3 style={{ margin: 0, fontSize: 17, fontWeight: 800 }}>تبقّى <span style={{ color: 'var(--pink-700)' }}>{40 - week}</span> أسبوع</h3>
              <p className="t-small" style={{ marginTop: 4 }}>الموعد المتوقع: {D.user.dueDate}</p>
            </div>
          </div>

          {/* 40-week progress bar */}
          <div style={{ marginTop: 14 }}>
            <div style={{
              height: 8, borderRadius: 999, background: '#F0E4EA', position: 'relative', overflow: 'hidden',
            }}>
              <div style={{
                position: 'absolute', insetInlineStart: 0, top: 0, bottom: 0,
                width: `${progressPct}%`,
                background: 'linear-gradient(90deg, #00897B, #4DB6AC, #E91E63)',
                borderRadius: 999,
                boxShadow: '0 2px 6px rgba(233,30,99,.3)',
              }} />
              <div style={{
                position: 'absolute', insetInlineStart: `calc(${progressPct}% - 8px)`, top: -4,
                width: 16, height: 16, borderRadius: '50%', background: '#fff',
                border: '3px solid #E91E63', boxShadow: '0 2px 6px rgba(0,0,0,.15)',
              }} />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 11, color: 'var(--ink-3)' }}>
              <span>الحمل</span><span>الثلث الثاني</span><span>الولادة</span>
            </div>
          </div>
        </div>
      </div>

      {/* Fetus size compared to fruit */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="card" style={{ padding: 18, display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{
            width: 76, height: 76, borderRadius: 22,
            background: 'linear-gradient(135deg, #E0F2F1, #B2DFDB)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 42, flexShrink: 0,
          }}>{info.sizeIcon}</div>
          <div style={{ flex: 1 }}>
            <p className="t-small" style={{ color: 'var(--teal-700)', fontWeight: 700 }}>هذا الأسبوع</p>
            <h3 style={{ margin: '2px 0 6px', fontSize: 16, fontWeight: 800 }}>{info.size}</h3>
            <div style={{ display: 'flex', gap: 12, fontSize: 12, color: 'var(--ink-2)' }}>
              <span>📏 {info.lengthCm} سم</span>
              <span>⚖️ {info.weightG} غ</span>
            </div>
          </div>
        </div>
        <p style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.7, margin: '12px 4px 0' }}>{info.desc}</p>
      </div>

      {/* Quick sections (تغذية، رياضة...) */}
      <div className="row-scroll" style={{ paddingTop: 20 }}>
        {D.homeSections.map(s => (
          <button key={s.id} style={{
            width: 84, padding: '14px 8px', border: 0, cursor: 'pointer',
            background: s.color === 'teal' ? 'var(--teal-50)' : s.color === 'pink' ? 'var(--pink-50)' : 'var(--purple-50)',
            borderRadius: 20, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
            color: s.color === 'teal' ? 'var(--teal-700)' : s.color === 'pink' ? 'var(--pink-700)' : 'var(--purple-700)',
            fontFamily: 'inherit', fontSize: 12, fontWeight: 700,
          }}>
            <span style={{ fontSize: 28 }}>{s.icon}</span>
            <span>{s.name}</span>
          </button>
        ))}
      </div>

      {/* Articles carousel */}
      <div className="section-title">
        <h3>مقالات لهذا الأسبوع</h3>
        <a href="#">عرض الكل</a>
      </div>
      <div className="row-scroll">
        {D.articles.map((a, i) => (
          <button key={i} onClick={() => onOpenArticle && onOpenArticle(a)} style={{
            width: 240, border: 0, padding: 0, background: 'var(--surface)', borderRadius: 20,
            overflow: 'hidden', boxShadow: 'var(--shadow-sm)', cursor: 'pointer', textAlign: 'right',
            fontFamily: 'inherit',
          }}>
            <div style={{ position: 'relative', height: 130 }}>
              <SmartImg src={a.img} style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} fallback="📖" />
              <span style={{
                position: 'absolute', top: 10, insetInlineStart: 10,
                background: 'rgba(255,255,255,.9)', backdropFilter: 'blur(6px)',
                padding: '4px 10px', borderRadius: 999, fontSize: 11, fontWeight: 700,
                color: 'var(--pink-700)',
              }}>{a.cat}</span>
            </div>
            <div style={{ padding: 14 }}>
              <h4 style={{ margin: 0, fontSize: 14, fontWeight: 800, lineHeight: 1.4, color: 'var(--ink)' }}>{a.title}</h4>
              <p className="t-small" style={{ marginTop: 6, display: 'flex', alignItems: 'center', gap: 6 }}>
                <Icon name="book" size={12} /> قراءة {a.read}
              </p>
            </div>
          </button>
        ))}
      </div>

      {/* Daily tip card */}
      <div style={{ padding: '8px 20px 24px' }}>
        <div style={{
          background: 'linear-gradient(135deg, #7E57C2 0%, #5E35B1 100%)',
          color: '#fff', borderRadius: 24, padding: 18,
          display: 'flex', gap: 14, alignItems: 'center',
          boxShadow: '0 8px 20px rgba(126,87,194,.3)',
        }}>
          <div style={{
            width: 52, height: 52, borderRadius: 16, background: 'rgba(255,255,255,.18)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 26, flexShrink: 0,
          }}>💡</div>
          <div style={{ flex: 1 }}>
            <p style={{ margin: 0, fontSize: 11, opacity: .85, fontWeight: 700 }}>نصيحة اليوم</p>
            <p style={{ margin: '4px 0 0', fontSize: 14, fontWeight: 700, lineHeight: 1.5 }}>
              اشربي 8 أكواب ماء يوميًا لتحسين الدورة الدموية ومنع تورّم القدمين.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

window.HomeScreen = HomeScreen;
