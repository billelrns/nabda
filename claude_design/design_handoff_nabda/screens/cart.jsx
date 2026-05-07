// Nabda — Cart + Checkout screen
const CD = window.NABDA_DATA;

function CartScreen({ items, onBack, onUpdate, onCheckout }) {
  const subtotal = items.reduce((s, it) => s + it.price * it.qty, 0);
  const shipping = subtotal > 5000 ? 0 : 600;
  const total = subtotal + shipping;
  const [step, setStep] = useState('cart'); // 'cart' | 'address' | 'payment' | 'done'
  const [wilaya, setWilaya] = useState(CD.wilayas[0]);
  const [addr, setAddr] = useState({ name: 'سارة بن علي', phone: '0555 12 34 56', street: 'حي النصر، رقم 14' });
  const [pay, setPay] = useState('cod');

  return (
    <div className="screen-enter" style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div className="appbar-pink appbar" style={{ paddingBottom: 24 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative', zIndex: 1 }}>
          <IconBtn name="arrow_right" onClick={step === 'cart' ? onBack : () => setStep(step === 'payment' ? 'address' : 'cart')} />
          <div style={{ flex: 1 }}>
            <h2 style={{ margin: 0, fontSize: 20, fontWeight: 800, color: '#fff' }}>
              {step === 'cart' ? 'سلتي' : step === 'address' ? 'عنوان التوصيل' : step === 'payment' ? 'الدفع' : 'تم الطلب'}
            </h2>
            <p style={{ margin: '2px 0 0', fontSize: 12, color: 'rgba(255,255,255,.85)' }}>{items.length} منتج • {window.formatDZD(total)}</p>
          </div>
        </div>

        {/* Stepper */}
        <div style={{ display: 'flex', gap: 6, marginTop: 16, position: 'relative', zIndex: 1 }}>
          {['cart', 'address', 'payment'].map((s, i) => {
            const order = ['cart','address','payment'];
            const idx = order.indexOf(step);
            const active = i <= idx;
            return (
              <div key={s} style={{
                flex: 1, height: 4, borderRadius: 999,
                background: active ? '#fff' : 'rgba(255,255,255,.3)',
              }} />
            );
          })}
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '16px 20px 110px' }}>
        {step === 'cart' && (
          <CartItems items={items} onUpdate={onUpdate} />
        )}

        {step === 'address' && (
          <AddressForm wilaya={wilaya} setWilaya={setWilaya} addr={addr} setAddr={setAddr} />
        )}

        {step === 'payment' && (
          <PaymentForm pay={pay} setPay={setPay} total={total} />
        )}

        {step === 'done' && (
          <DoneScreen onBack={onBack} />
        )}

        {/* Order summary always visible */}
        {step !== 'done' && items.length > 0 && (
          <div className="card" style={{ padding: 16, marginTop: 16 }}>
            <h3 className="t-h3">ملخص الطلب</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 12 }}>
              <Row k="المجموع الفرعي" v={window.formatDZD(subtotal)} />
              <Row k="التوصيل" v={shipping === 0 ? <span style={{ color: 'var(--green)' }}>مجاني 🎉</span> : window.formatDZD(shipping)} />
              <div style={{ borderTop: '1px dashed var(--line)', margin: '4px 0' }} />
              <Row k={<b>المجموع</b>} v={<b style={{ color: 'var(--pink-700)', fontSize: 16 }}>{window.formatDZD(total)}</b>} />
            </div>
          </div>
        )}
      </div>

      {/* Bottom action */}
      {step !== 'done' && items.length > 0 && (
        <div style={{
          position: 'absolute', bottom: 0, left: 0, right: 0,
          background: 'rgba(255,255,255,.95)', backdropFilter: 'blur(20px)',
          borderTop: '1px solid var(--line)', padding: '14px 20px', zIndex: 10,
        }}>
          <button onClick={() => {
            if (step === 'cart') setStep('address');
            else if (step === 'address') setStep('payment');
            else { setStep('done'); onCheckout && onCheckout(); }
          }} className="btn btn-pink" style={{ width: '100%', padding: 16, fontSize: 15 }}>
            {step === 'cart' ? 'متابعة للعنوان' : step === 'address' ? 'متابعة للدفع' : 'تأكيد الطلب • ' + window.formatDZD(total)}
            <Icon name="arrow_left" size={18} />
          </button>
        </div>
      )}
    </div>
  );
}

function CartItems({ items, onUpdate }) {
  if (!items.length) return (
    <div style={{ textAlign: 'center', padding: 40 }}>
      <div style={{ fontSize: 64, marginBottom: 12 }}>🛒</div>
      <h3 className="t-h2">سلتك فارغة</h3>
      <p className="t-small" style={{ marginTop: 8 }}>تصفّحي المتجر وأضيفي ما يعجبك 💕</p>
    </div>
  );
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {items.map(it => (
        <div key={it.id} className="card" style={{ padding: 12, display: 'flex', gap: 12 }}>
          <SmartImg src={it.img} style={{ width: 76, height: 76, borderRadius: 14, objectFit: 'cover', flexShrink: 0 }} />
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
            <div>
              <p style={{ margin: 0, fontSize: 13, fontWeight: 700, lineHeight: 1.4 }}>{it.name}</p>
              <p style={{ margin: '4px 0 0', fontSize: 14, fontWeight: 800, color: 'var(--pink-700)' }}>{window.formatDZD(it.price)}</p>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 6 }}>
              <div style={{ display: 'flex', alignItems: 'center', background: 'var(--bg-2)', borderRadius: 999, padding: 2 }}>
                <button onClick={() => onUpdate(it.id, it.qty - 1)} style={{ ...qtyMini }}><Icon name="minus" size={14} /></button>
                <span style={{ minWidth: 24, textAlign: 'center', fontWeight: 700, fontSize: 13 }}>{it.qty}</span>
                <button onClick={() => onUpdate(it.id, it.qty + 1)} style={{ ...qtyMini }}><Icon name="plus" size={14} /></button>
              </div>
              <button onClick={() => onUpdate(it.id, 0)} style={{ background: 'transparent', border: 0, cursor: 'pointer', color: 'var(--ink-3)', fontSize: 12, fontFamily: 'inherit' }}>
                إزالة
              </button>
            </div>
          </div>
        </div>
      ))}

      {/* Promo code */}
      <div className="card" style={{ padding: 14, display: 'flex', gap: 10, alignItems: 'center', marginTop: 6 }}>
        <span style={{ fontSize: 22 }}>🎫</span>
        <input placeholder="رمز الخصم" style={{
          flex: 1, border: 0, outline: 0, background: 'transparent',
          fontFamily: 'inherit', fontSize: 14, color: 'var(--ink)',
        }} />
        <button className="btn btn-ghost" style={{ padding: '8px 16px', fontSize: 13 }}>تطبيق</button>
      </div>
    </div>
  );
}

function AddressForm({ wilaya, setWilaya, addr, setAddr }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      <Field label="الاسم الكامل" value={addr.name} onChange={v => setAddr({...addr, name: v})} />
      <Field label="رقم الهاتف" value={addr.phone} onChange={v => setAddr({...addr, phone: v})} />
      <div>
        <label style={{ display: 'block', fontSize: 12, fontWeight: 700, marginBottom: 6, color: 'var(--ink-2)' }}>الولاية</label>
        <select value={wilaya} onChange={e => setWilaya(e.target.value)} style={{
          width: '100%', padding: '14px 16px', borderRadius: 14, border: '1px solid var(--line)',
          background: 'var(--surface)', fontFamily: 'inherit', fontSize: 14, color: 'var(--ink)',
        }}>
          {CD.wilayas.map(w => <option key={w}>{w}</option>)}
        </select>
      </div>
      <Field label="العنوان (الحي، الشارع، الرقم)" value={addr.street} onChange={v => setAddr({...addr, street: v})} multi />

      <div className="card" style={{ padding: 12, display: 'flex', gap: 10, alignItems: 'center', background: 'var(--teal-50)', boxShadow: 'none' }}>
        <Icon name="truck" size={20} color="#00796B" />
        <p style={{ margin: 0, fontSize: 12, color: 'var(--teal-900)', flex: 1 }}>التوصيل: 2-4 أيام عمل عبر Yalidine / ZR Express</p>
      </div>
    </div>
  );
}

function PaymentForm({ pay, setPay, total }) {
  const methods = [
    { id: 'cod', icon: '💵', name: 'الدفع عند الاستلام', desc: 'ادفعي نقدًا عند توصيل الطلب', popular: true },
    { id: 'edahabia', icon: '💳', name: 'بطاقة الذهبية', desc: 'الدفع الإلكتروني CIB / Edahabia' },
    { id: 'ccp', icon: '🏦', name: 'CCP — حساب بريدي', desc: 'تحويل بنكي إلى حساب CCP' },
    { id: 'baridimob', icon: '📱', name: 'BaridiMob', desc: 'دفع فوري عبر تطبيق بريدي موب' },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {methods.map(m => (
        <button key={m.id} onClick={() => setPay(m.id)} style={{
          width: '100%', textAlign: 'right', padding: 16, borderRadius: 18,
          border: pay === m.id ? '2px solid var(--pink)' : '1px solid var(--line)',
          background: pay === m.id ? 'var(--pink-50)' : 'var(--surface)',
          display: 'flex', gap: 12, alignItems: 'center', cursor: 'pointer',
          fontFamily: 'inherit', position: 'relative',
          transition: 'all .15s',
        }}>
          <div style={{
            width: 48, height: 48, borderRadius: 14, background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24,
            boxShadow: 'var(--shadow-sm)',
          }}>{m.icon}</div>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <p style={{ margin: 0, fontSize: 14, fontWeight: 800 }}>{m.name}</p>
              {m.popular && <span style={{ background: 'var(--gold)', color: '#fff', fontSize: 9, padding: '2px 6px', borderRadius: 999, fontWeight: 800 }}>الأكثر استخدامًا</span>}
            </div>
            <p className="t-small" style={{ marginTop: 2 }}>{m.desc}</p>
          </div>
          <div style={{
            width: 22, height: 22, borderRadius: '50%',
            border: pay === m.id ? '6px solid var(--pink)' : '2px solid var(--line)',
            background: '#fff',
          }} />
        </button>
      ))}

      {pay === 'ccp' && (
        <div className="card" style={{ padding: 14, marginTop: 4 }}>
          <p className="t-small">رقم الحساب البريدي:</p>
          <p style={{ margin: '6px 0 0', fontSize: 16, fontWeight: 800, fontFamily: 'monospace', letterSpacing: 1 }}>0099 4567 8912 34 / 56</p>
          <p className="t-small" style={{ marginTop: 8 }}>أرسلي صورة الوصل بعد التحويل ليتم تأكيد الطلب.</p>
        </div>
      )}
    </div>
  );
}

function DoneScreen({ onBack }) {
  return (
    <div style={{ textAlign: 'center', padding: '40px 20px' }}>
      <div style={{
        width: 100, height: 100, borderRadius: '50%', margin: '0 auto',
        background: 'linear-gradient(135deg, var(--green), #2E7D32)',
        color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 48, boxShadow: '0 12px 30px rgba(52,168,83,.3)',
      }}>✓</div>
      <h2 className="t-h1" style={{ marginTop: 20 }}>شكرًا لك! 💕</h2>
      <p className="t-body" style={{ marginTop: 8 }}>تم استلام طلبك بنجاح. سنتواصل معك قريبًا لتأكيد التوصيل.</p>
      <div className="card" style={{ padding: 16, marginTop: 24, textAlign: 'right' }}>
        <p className="t-small">رقم الطلب</p>
        <p style={{ margin: '6px 0 0', fontSize: 18, fontWeight: 800, fontFamily: 'monospace' }}>#NB-2026-04829</p>
        <p className="t-small" style={{ marginTop: 12 }}>التوصيل المتوقع: 8 - 10 مايو 2026</p>
      </div>
      <button onClick={onBack} className="btn btn-primary" style={{ marginTop: 20, padding: '14px 32px' }}>
        متابعة التسوّق
      </button>
    </div>
  );
}

const Row = ({ k, v }) => (
  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 13, color: 'var(--ink-2)' }}>
    <span>{k}</span><span>{v}</span>
  </div>
);

const Field = ({ label, value, onChange, multi }) => (
  <div>
    <label style={{ display: 'block', fontSize: 12, fontWeight: 700, marginBottom: 6, color: 'var(--ink-2)' }}>{label}</label>
    {multi ? (
      <textarea value={value} onChange={e => onChange(e.target.value)} rows={2} style={fieldStyle} />
    ) : (
      <input value={value} onChange={e => onChange(e.target.value)} style={fieldStyle} />
    )}
  </div>
);

const fieldStyle = {
  width: '100%', padding: '14px 16px', borderRadius: 14, border: '1px solid var(--line)',
  background: 'var(--surface)', fontFamily: 'inherit', fontSize: 14, color: 'var(--ink)',
  outline: 'none', resize: 'vertical',
};
const qtyMini = { width: 26, height: 26, border: 0, cursor: 'pointer', background: 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--ink)' };

window.CartScreen = CartScreen;
