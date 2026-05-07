// Nabda — Store screen
const SD = window.NABDA_DATA;

function StoreScreen({ onOpenProduct, onOpenCart, cartCount }) {
  const [search, setSearch] = useState('');
  const [activeCat, setActiveCat] = useState('all');

  // Group products by category
  const byCat = useMemo(() => {
    const map = {};
    SD.products.forEach(p => {
      if (!map[p.cat]) map[p.cat] = [];
      map[p.cat].push(p);
    });
    return map;
  }, []);

  const featuredCats = ['maternity', 'feeding', 'diapers', 'vitamins'];

  return (
    <div className="screen-enter">
      {/* Sliver app bar with teal gradient */}
      <div className="appbar" style={{ paddingBottom: 60 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative', zIndex: 1 }}>
          <div>
            <p style={{ margin: 0, fontSize: 12, color: 'rgba(255,255,255,.85)', fontWeight: 700 }}>متجر نبضة</p>
            <h2 style={{ margin: '2px 0 0', fontSize: 22, fontWeight: 800, color: '#fff' }}>كل ما تحتاجينه 🛍️</h2>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <IconBtn name="heart" />
            <IconBtn name="cart" badge={cartCount > 0 ? cartCount : undefined} onClick={onOpenCart} />
          </div>
        </div>
      </div>

      {/* Floating search bar — overlapping appbar */}
      <div style={{ padding: '0 20px', marginTop: -36, position: 'relative', zIndex: 2 }}>
        <div style={{
          background: '#fff', borderRadius: 18, padding: '12px 16px',
          display: 'flex', alignItems: 'center', gap: 10,
          boxShadow: '0 8px 24px rgba(0,0,0,.08)',
        }}>
          <Icon name="search" size={20} color="#8B8190" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="ابحثي عن منتج..."
            style={{
              border: 0, outline: 0, flex: 1, fontFamily: 'inherit',
              fontSize: 14, background: 'transparent', color: 'var(--ink)',
            }}
          />
          <button style={{
            width: 32, height: 32, borderRadius: 10, border: 0, cursor: 'pointer',
            background: 'var(--teal-50)', color: 'var(--teal-700)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="mic" size={16} />
          </button>
        </div>
      </div>

      {/* Promo banner */}
      <div style={{ padding: '20px 20px 0' }}>
        <div style={{
          borderRadius: 24, padding: 20,
          background: 'linear-gradient(135deg, #F8BBD0 0%, #FCE4EC 70%)',
          display: 'flex', alignItems: 'center', gap: 14,
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', top: -20, insetInlineEnd: -20, width: 100, height: 100, borderRadius: '50%', background: 'rgba(255,255,255,.4)' }} />
          <div style={{ flex: 1, position: 'relative', zIndex: 1 }}>
            <p style={{ margin: 0, fontSize: 11, fontWeight: 800, color: 'var(--pink-700)' }}>🎉 عرض الأسبوع</p>
            <h3 style={{ margin: '4px 0', fontSize: 18, fontWeight: 800, color: 'var(--ink)' }}>خصم 25% على كل لوازم الرضيع</h3>
            <p className="t-small" style={{ color: 'var(--ink-2)' }}>شحن مجاني لطلبات +5,000 دج</p>
          </div>
          <div style={{ fontSize: 56, position: 'relative', zIndex: 1 }}>🎀</div>
        </div>
      </div>

      {/* Categories — horizontal */}
      <div className="section-title" style={{ paddingBottom: 0 }}>
        <h3>الأقسام</h3>
        <a href="#">الكل ({SD.storeCategories.length})</a>
      </div>
      <div className="row-scroll" style={{ padding: '12px 20px 16px' }}>
        <button onClick={() => setActiveCat('all')} style={catBtnStyle(activeCat === 'all')}>
          <span style={{ fontSize: 28 }}>🏷️</span>
          <span>الكل</span>
        </button>
        {SD.storeCategories.map(c => (
          <button key={c.id} onClick={() => setActiveCat(c.id)} style={catBtnStyle(activeCat === c.id)}>
            <span style={{ fontSize: 28 }}>{c.icon}</span>
            <span>{c.name}</span>
          </button>
        ))}
      </div>

      {/* Per-category carousels */}
      {(activeCat === 'all' ? featuredCats : [activeCat]).map(catId => {
        const cat = SD.storeCategories.find(c => c.id === catId);
        const items = byCat[catId] || [];
        if (!items.length) return null;
        return (
          <div key={catId}>
            <div className="section-title">
              <h3>{cat?.icon} {cat?.name}</h3>
              <a href="#">المزيد</a>
            </div>
            <div className="row-scroll">
              {items.map(p => <ProductCard key={p.id} p={p} onClick={() => onOpenProduct(p)} />)}
            </div>
          </div>
        );
      })}

      {/* Trust badges */}
      <div style={{ padding: '4px 20px 24px' }}>
        <div className="card" style={{ padding: 16, display: 'flex', justifyContent: 'space-around', textAlign: 'center' }}>
          {[
            { i: '🚚', t: 'توصيل', s: '48 ولاية' },
            { i: '✅', t: 'دفع آمن', s: 'CCP/Edahabia' },
            { i: '↩️', t: 'إرجاع', s: '7 أيام' },
          ].map((x, i) => (
            <div key={i} style={{ flex: 1 }}>
              <div style={{ fontSize: 24, marginBottom: 4 }}>{x.i}</div>
              <p style={{ margin: 0, fontSize: 12, fontWeight: 800 }}>{x.t}</p>
              <p className="t-small" style={{ fontSize: 10 }}>{x.s}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

const catBtnStyle = (active) => ({
  width: 78, padding: '12px 8px', border: 0, cursor: 'pointer',
  background: active ? 'var(--teal)' : 'var(--surface)',
  color: active ? '#fff' : 'var(--ink)',
  borderRadius: 18, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
  fontFamily: 'inherit', fontSize: 11, fontWeight: 700,
  boxShadow: active ? '0 6px 14px rgba(0,137,123,.3)' : 'var(--shadow-sm)',
  transition: 'all .2s',
});

function ProductCard({ p, onClick }) {
  const discount = p.oldPrice ? Math.round((1 - p.price / p.oldPrice) * 100) : 0;
  return (
    <button onClick={onClick} style={{
      width: 170, border: 0, padding: 0, background: 'var(--surface)', borderRadius: 20,
      overflow: 'hidden', boxShadow: 'var(--shadow-sm)', cursor: 'pointer', textAlign: 'right',
      fontFamily: 'inherit', display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ position: 'relative', height: 150, background: '#FAF7F8' }}>
        <SmartImg src={p.img} style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} fallback="🛍️" />
        {discount > 0 && (
          <span style={{
            position: 'absolute', top: 10, insetInlineStart: 10,
            background: 'var(--pink)', color: '#fff', padding: '4px 10px',
            borderRadius: 999, fontSize: 11, fontWeight: 800,
          }}>-{discount}%</span>
        )}
        <button onClick={(e) => { e.stopPropagation(); }} style={{
          position: 'absolute', top: 8, insetInlineEnd: 8,
          width: 32, height: 32, borderRadius: '50%',
          background: 'rgba(255,255,255,.9)', border: 0, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--ink-3)',
        }}>
          <Icon name="heart" size={16} />
        </button>
      </div>
      <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 6, flex: 1 }}>
        <h4 style={{ margin: 0, fontSize: 13, fontWeight: 700, lineHeight: 1.4, minHeight: 36 }}>{p.name}</h4>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11 }}>
          <Stars value={p.rating} size={11} />
          <span style={{ color: 'var(--ink-3)' }}>({p.reviews})</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginTop: 'auto' }}>
          <div>
            <div className="t-price">{window.formatDZD(p.price)}</div>
            {p.oldPrice && <div className="t-price-old">{window.formatDZD(p.oldPrice)}</div>}
          </div>
          <button onClick={(e) => { e.stopPropagation(); window.dispatchEvent(new CustomEvent('nabda:add', { detail: p })); }} style={{
            width: 32, height: 32, borderRadius: 10, border: 0, cursor: 'pointer',
            background: 'linear-gradient(135deg, var(--teal), var(--teal-700))',
            color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 10px rgba(0,137,123,.3)',
          }}>
            <Icon name="plus" size={16} />
          </button>
        </div>
      </div>
    </button>
  );
}

Object.assign(window, { StoreScreen, ProductCard });
