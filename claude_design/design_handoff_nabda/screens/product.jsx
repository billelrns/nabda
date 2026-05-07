// Nabda — Product Detail screen
const PD = window.NABDA_DATA;

function ProductDetailScreen({ product, onBack, onAddToCart, onOpenCart, cartCount }) {
  const [imgIdx, setImgIdx] = useState(0);
  const [qty, setQty] = useState(1);
  const [fav, setFav] = useState(false);
  const images = (product.images && product.images.length) ? product.images : [product.img];
  const discount = product.oldPrice ? Math.round((1 - product.price / product.oldPrice) * 100) : 0;

  return (
    <div className="screen-enter" style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Image gallery */}
      <div style={{ position: 'relative', height: 360, background: '#FAF7F8' }}>
        <div style={{
          display: 'flex', height: '100%', transition: 'transform .3s ease',
          transform: `translateX(${imgIdx * 100}%)`,
        }}>
          {images.map((src, i) => (
            <SmartImg key={i} src={src} style={{ minWidth: '100%', height: '100%', objectFit: 'cover' }} fallback="🛍️" />
          ))}
        </div>

        {/* Top controls */}
        <div style={{ position: 'absolute', top: 12, insetInline: 16, display: 'flex', justifyContent: 'space-between', zIndex: 2 }}>
          <button onClick={onBack} style={glassBtn}><Icon name="arrow_right" size={20} /></button>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => setFav(!fav)} style={{ ...glassBtn, color: fav ? '#E91E63' : '#1F1A20' }}>
              <Icon name="heart" size={20} strokeWidth={fav ? 0 : 2} color={fav ? '#E91E63' : '#1F1A20'} />
            </button>
            <button onClick={onOpenCart} style={{ ...glassBtn, position: 'relative' }}>
              <Icon name="cart" size={20} />
              {cartCount > 0 && <span style={badge}>{cartCount}</span>}
            </button>
          </div>
        </div>

        {/* Discount badge */}
        {discount > 0 && (
          <span style={{
            position: 'absolute', top: 16, left: '50%', transform: 'translateX(-50%)',
            background: 'var(--pink)', color: '#fff', padding: '6px 14px',
            borderRadius: 999, fontSize: 12, fontWeight: 800,
            boxShadow: '0 4px 10px rgba(233,30,99,.4)',
          }}>خصم {discount}%</span>
        )}

        {/* Dot indicators */}
        {images.length > 1 && (
          <div style={{
            position: 'absolute', bottom: 16, left: '50%', transform: 'translateX(-50%)',
            display: 'flex', gap: 6,
          }}>
            {images.map((_, i) => (
              <button key={i} onClick={() => setImgIdx(i)} style={{
                width: i === imgIdx ? 24 : 8, height: 8, borderRadius: 999,
                background: i === imgIdx ? '#fff' : 'rgba(255,255,255,.5)',
                border: 0, cursor: 'pointer', transition: 'all .2s',
              }} />
            ))}
          </div>
        )}
      </div>

      {/* Content sheet */}
      <div style={{
        flex: 1, overflowY: 'auto', background: 'var(--bg)',
        borderRadius: '28px 28px 0 0', marginTop: -24, position: 'relative', zIndex: 1,
        padding: '20px 20px 110px',
      }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
          <div style={{ flex: 1 }}>
            <span className="pill pill-teal" style={{ marginBottom: 8 }}>متوفر — شحن سريع</span>
            <h2 className="t-h1" style={{ marginTop: 6 }}>{product.name}</h2>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8 }}>
              <Stars value={product.rating} size={14} />
              <span style={{ fontSize: 13, fontWeight: 700 }}>{product.rating}</span>
              <span style={{ fontSize: 12, color: 'var(--ink-3)' }}>({product.reviews} تقييم)</span>
            </div>
          </div>
        </div>

        {/* Price block */}
        <div style={{
          marginTop: 16, padding: 16, borderRadius: 18,
          background: 'linear-gradient(135deg, #FCE4EC, #FFF8FB)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div>
            <p className="t-small">السعر</p>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 4 }}>
              <span style={{ fontSize: 24, fontWeight: 800, color: 'var(--pink-700)' }}>{window.formatDZD(product.price)}</span>
              {product.oldPrice && <span className="t-price-old">{window.formatDZD(product.oldPrice)}</span>}
            </div>
          </div>
          {/* Quantity stepper */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 0, background: '#fff', borderRadius: 999, padding: 4, boxShadow: 'var(--shadow-sm)' }}>
            <button onClick={() => setQty(Math.max(1, qty - 1))} style={qtyBtn}><Icon name="minus" size={16} /></button>
            <span style={{ minWidth: 32, textAlign: 'center', fontWeight: 800, fontSize: 14 }}>{qty}</span>
            <button onClick={() => setQty(qty + 1)} style={{ ...qtyBtn, background: 'var(--teal)', color: '#fff' }}><Icon name="plus" size={16} /></button>
          </div>
        </div>

        {/* Description */}
        <h3 className="t-h2" style={{ marginTop: 24 }}>الوصف</h3>
        <p className="t-body" style={{ marginTop: 8 }}>{product.desc}</p>

        {/* Specs */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 16 }}>
          {[
            { k: 'الفئة', v: PD.storeCategories.find(c => c.id === product.cat)?.name || '—' },
            { k: 'العلامة', v: 'Nabda Care' },
            { k: 'الضمان', v: '6 أشهر' },
            { k: 'الإرجاع', v: 'خلال 7 أيام' },
          ].map((s, i) => (
            <div key={i} className="card" style={{ padding: 12 }}>
              <p className="t-small">{s.k}</p>
              <p style={{ margin: '4px 0 0', fontSize: 13, fontWeight: 700 }}>{s.v}</p>
            </div>
          ))}
        </div>

        {/* Description images (gallery) */}
        {images.length > 1 && (
          <>
            <h3 className="t-h2" style={{ marginTop: 24 }}>صور إضافية</h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 12 }}>
              {images.slice(0, 4).map((src, i) => (
                <SmartImg key={i} src={src} style={{ width: '100%', height: 110, objectFit: 'cover', borderRadius: 14 }} />
              ))}
            </div>
          </>
        )}

        {/* Reviews preview */}
        <h3 className="t-h2" style={{ marginTop: 24 }}>آراء الأمهات</h3>
        <div className="card" style={{ padding: 14, marginTop: 12 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'linear-gradient(135deg, #E91E63, #7E57C2)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800 }}>أ</div>
              <div>
                <p style={{ margin: 0, fontSize: 13, fontWeight: 800 }}>أمينة</p>
                <p className="t-small">قبل 3 أيام</p>
              </div>
            </div>
            <Stars value={5} size={12} />
          </div>
          <p className="t-body" style={{ marginTop: 10, fontSize: 13 }}>
            "ممتاز جدًا، الجودة فوق التوقعات والتوصيل وصل في يومين فقط للجزائر العاصمة. أنصح به بشدة 💕"
          </p>
        </div>
      </div>

      {/* Bottom action bar */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        background: 'rgba(255,255,255,.95)', backdropFilter: 'blur(20px)',
        borderTop: '1px solid var(--line)', padding: '14px 20px',
        display: 'flex', gap: 10, alignItems: 'center', zIndex: 10,
      }}>
        <button style={{
          width: 52, height: 52, borderRadius: 16, border: '1px solid var(--line)',
          background: 'var(--surface)', display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
        }}>
          <Icon name="bot" size={22} color="#7E57C2" />
        </button>
        <button onClick={() => onAddToCart(product, qty)} className="btn btn-primary" style={{ flex: 1, padding: '14px 20px', fontSize: 15 }}>
          <Icon name="cart" size={18} />
          أضيفي للسلة • {window.formatDZD(product.price * qty)}
        </button>
      </div>
    </div>
  );
}

const glassBtn = {
  width: 40, height: 40, borderRadius: '50%',
  background: 'rgba(255,255,255,.9)', backdropFilter: 'blur(12px)',
  border: 0, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
  color: '#1F1A20', boxShadow: '0 4px 12px rgba(0,0,0,.08)',
};
const badge = {
  position: 'absolute', top: 4, right: 4, minWidth: 16, height: 16,
  background: '#E91E63', color: '#fff', borderRadius: 999, fontSize: 10, fontWeight: 800,
  display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '0 4px',
  border: '2px solid #fff',
};
const qtyBtn = {
  width: 32, height: 32, borderRadius: 999, border: 0, cursor: 'pointer',
  background: 'transparent', color: 'var(--ink)',
  display: 'flex', alignItems: 'center', justifyContent: 'center',
};

window.ProductDetailScreen = ProductDetailScreen;
