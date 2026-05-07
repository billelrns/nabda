// Nabda — shared UI primitives
const { useState, useEffect, useRef, useMemo } = React;

// Inline SVG icons (Material-style, 24px)
const Icon = ({ name, size = 24, color = 'currentColor', strokeWidth = 2 }) => {
  const paths = {
    home: 'M3 11.5L12 4l9 7.5V20a1 1 0 01-1 1h-5v-6h-6v6H4a1 1 0 01-1-1v-8.5z',
    store: 'M4 7h16l-1 13a2 2 0 01-2 2H7a2 2 0 01-2-2L4 7zM9 7V5a3 3 0 016 0v2',
    bot: 'M12 2v3M5 8h14a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2v-8a2 2 0 012-2zM9 13h.01M15 13h.01M9 17h6',
    settings: 'M12 1v6m0 10v6M4.22 4.22l4.24 4.24m7.08 7.08l4.24 4.24M1 12h6m10 0h6M4.22 19.78l4.24-4.24m7.08-7.08l4.24-4.24',
    search: 'M11 19a8 8 0 100-16 8 8 0 000 16zM21 21l-4.35-4.35',
    bell: 'M18 8a6 6 0 10-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 01-3.46 0',
    cart: 'M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4H6zM3 6h18M16 10a4 4 0 11-8 0',
    heart: 'M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z',
    plus: 'M12 5v14M5 12h14',
    minus: 'M5 12h14',
    chevron_left: 'M15 18l-6-6 6-6',
    chevron_right: 'M9 18l6-6-6-6',
    chevron_down: 'M6 9l6 6 6-6',
    arrow_left: 'M19 12H5M12 19l-7-7 7-7',
    arrow_right: 'M5 12h14M12 5l7 7-7 7',
    star: 'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z',
    send: 'M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z',
    mic: 'M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3zM19 10v2a7 7 0 01-14 0v-2M12 19v3M8 22h8',
    image: 'M21 15V5a2 2 0 00-2-2H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2zM8.5 10a1.5 1.5 0 100-3 1.5 1.5 0 000 3zM21 15l-5-5L5 21',
    menu: 'M3 12h18M3 6h18M3 18h18',
    close: 'M18 6L6 18M6 6l12 12',
    map: 'M9 20l-6-3V4l6 3m0 13l6-3m-6 3V7m6 10l6 3V7l-6-3m0 13V4',
    credit: 'M2 7h20v12H2zM2 11h20',
    truck: 'M1 3h15v13H1zM16 8h4l3 3v5h-7M5.5 19a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM18.5 19a2.5 2.5 0 100-5 2.5 2.5 0 000 5z',
    calendar: 'M19 4H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2V6a2 2 0 00-2-2zM16 2v4M8 2v4M3 10h18',
    book: 'M4 19.5A2.5 2.5 0 016.5 17H20V2H6.5A2.5 2.5 0 004 4.5v15zM4 19.5A2.5 2.5 0 006.5 22H20',
    activity: 'M22 12h-4l-3 9L9 3l-3 9H2',
    sparkle: 'M12 2l2 7 7 2-7 2-2 7-2-7-7-2 7-2 2-7z',
    play: 'M5 3l14 9-14 9V3z',
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
      <path d={paths[name] || paths.sparkle} />
    </svg>
  );
};

// Star rating
const Stars = ({ value = 4.5, size = 12 }) => {
  const full = Math.floor(value);
  const half = value - full >= 0.4;
  return (
    <span className="stars">
      {[0,1,2,3,4].map(i => (
        <svg key={i} width={size} height={size} viewBox="0 0 24 24" fill={i < full ? '#F2B544' : (i === full && half ? 'url(#hf)' : '#E5DBD7')}>
          {i === full && half && (
            <defs><linearGradient id="hf"><stop offset="50%" stopColor="#F2B544"/><stop offset="50%" stopColor="#E5DBD7"/></linearGradient></defs>
          )}
          <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
        </svg>
      ))}
    </span>
  );
};

// Top app bar
const AppBar = ({ title, variant = 'teal', leading, trailing, children, large = false }) => (
  <div className={`appbar ${variant === 'pink' ? 'appbar-pink' : variant === 'purple' ? 'appbar-purple' : ''}`}
       style={{ paddingBottom: large ? 32 : 24 }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative', zIndex: 1 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {leading}
        {title && <h2 style={{ margin: 0, fontSize: 20, fontWeight: 800, color: '#fff' }}>{title}</h2>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>{trailing}</div>
    </div>
    {children}
  </div>
);

const IconBtn = ({ name, onClick, badge, color = '#fff', bg = 'rgba(255,255,255,.18)' }) => (
  <button onClick={onClick} style={{
    width: 40, height: 40, borderRadius: 999, border: 0, cursor: 'pointer',
    background: bg, color, display: 'flex', alignItems: 'center', justifyContent: 'center',
    position: 'relative', backdropFilter: 'blur(8px)',
  }}>
    <Icon name={name} size={20} />
    {badge != null && (
      <span style={{
        position: 'absolute', top: 4, right: 4, minWidth: 16, height: 16, padding: '0 4px',
        background: '#E91E63', color: '#fff', borderRadius: 999, fontSize: 10, fontWeight: 800,
        display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid #fff',
      }}>{badge}</span>
    )}
  </button>
);

// Bottom Nav (4 tabs — pill style)
const BottomNav = ({ active, onChange }) => {
  const tabs = [
    { id: 'home', label: 'الرئيسية', icon: 'home' },
    { id: 'store', label: 'المتجر', icon: 'store' },
    { id: 'ai', label: 'نبضة', icon: 'sparkle', pink: true },
    { id: 'settings', label: 'الإعدادات', icon: 'settings' },
  ];
  return (
    <nav className="bottom-nav">
      {tabs.map(t => (
        <button key={t.id}
                className={`bnav-item ${active === t.id ? 'active' : ''} ${t.pink && active === t.id ? 'pink' : ''}`}
                onClick={() => onChange(t.id)}>
          <span className="bnav-icon">
            <Icon name={t.icon} size={22} strokeWidth={active === t.id ? 2.4 : 2} />
          </span>
          <span>{t.label}</span>
        </button>
      ))}
    </nav>
  );
};

// Image with graceful fallback
const SmartImg = ({ src, alt = '', style, fallback }) => {
  const [err, setErr] = useState(false);
  if (err || !src) {
    return <div className="img-fallback" style={{ ...style, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#C295A8', fontSize: 32 }}>{fallback || '🌸'}</div>;
  }
  return <img src={src} alt={alt} style={style} onError={() => setErr(true)} loading="lazy" />;
};

// Snackbar / Toast
const Toast = ({ msg, onDone }) => {
  useEffect(() => { const t = setTimeout(onDone, 2000); return () => clearTimeout(t); }, []);
  return (
    <div style={{
      position: 'absolute', bottom: 100, left: '50%', transform: 'translateX(-50%)',
      background: 'rgba(31,26,32,.92)', color: '#fff', padding: '10px 18px',
      borderRadius: 999, fontSize: 13, fontWeight: 700, zIndex: 100,
      boxShadow: '0 8px 24px rgba(0,0,0,.2)', whiteSpace: 'nowrap',
      animation: 'fadeUp .25s ease-out',
    }}>{msg}</div>
  );
};

// Expose to other JSX scripts
Object.assign(window, { Icon, Stars, AppBar, IconBtn, BottomNav, SmartImg, Toast });
