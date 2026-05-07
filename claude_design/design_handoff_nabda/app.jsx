// Nabda — main app shell
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "dark": false,
  "primaryColor": "#00897B",
  "secondaryColor": "#E91E63",
  "week": 25,
  "persona": "warm"
}/*EDITMODE-END*/;

const PRIMARY_OPTIONS = ['#00897B', '#0097A7', '#7E57C2', '#5E35B1'];
const SECONDARY_OPTIONS = ['#E91E63', '#EC407A', '#F06292', '#FF7043'];

const PERSONAS = {
  warm:    { name: 'دافئ',     bg1: '#FCE4EC', bg2: '#E0F2F1' },
  bloom:   { name: 'مزهر',     bg1: '#F3E5F5', bg2: '#FCE4EC' },
  serene:  { name: 'هادئ',     bg1: '#E1F5FE', bg2: '#E8EAF6' },
};

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [tab, setTab] = useState('home');
  const [stack, setStack] = useState([]); // overlays: 'product' | 'cart' | 'admin'
  const [activeProduct, setActiveProduct] = useState(null);
  const [cart, setCart] = useState([]);
  const [toast, setToast] = useState(null);

  // Apply theme + colors
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', t.dark ? 'dark' : 'light');
    document.documentElement.style.setProperty('--teal', t.primaryColor);
    document.documentElement.style.setProperty('--pink', t.secondaryColor);
    // Derived
    const lighten = (hex, amt) => {
      const n = parseInt(hex.slice(1), 16);
      let r = (n >> 16) + amt, g = ((n >> 8) & 0xff) + amt, b = (n & 0xff) + amt;
      r = Math.min(255, r); g = Math.min(255, g); b = Math.min(255, b);
      return '#' + ((r << 16) | (g << 8) | b).toString(16).padStart(6, '0');
    };
    document.documentElement.style.setProperty('--teal-700', lighten(t.primaryColor, -20));
    document.documentElement.style.setProperty('--pink-700', lighten(t.secondaryColor, -20));
  }, [t.dark, t.primaryColor, t.secondaryColor]);

  // Persona-driven page bg
  const persona = PERSONAS[t.persona] || PERSONAS.warm;

  // Cart helpers
  const addToCart = (p, qty = 1) => {
    setCart(c => {
      const existing = c.find(x => x.id === p.id);
      if (existing) return c.map(x => x.id === p.id ? { ...x, qty: x.qty + qty } : x);
      return [...c, { ...p, qty }];
    });
    setToast('أُضيف للسلة 💕');
  };
  const updateCart = (id, qty) => {
    if (qty <= 0) setCart(c => c.filter(x => x.id !== id));
    else setCart(c => c.map(x => x.id === id ? { ...x, qty } : x));
  };
  const cartCount = cart.reduce((s, x) => s + x.qty, 0);

  // Listen to ProductCard "add" events
  useEffect(() => {
    const h = (e) => addToCart(e.detail);
    window.addEventListener('nabda:add', h);
    return () => window.removeEventListener('nabda:add', h);
  }, []);

  const openProduct = (p) => { setActiveProduct(p); setStack(s => [...s, 'product']); };
  const openCart = () => setStack(s => [...s, 'cart']);
  const openAdmin = () => setStack(s => [...s, 'admin']);
  const popStack = () => setStack(s => s.slice(0, -1));

  // Top of stack determines what's rendered
  const topOverlay = stack[stack.length - 1];

  // Hide bottom nav for: product, cart, admin
  const hideNav = topOverlay === 'product' || topOverlay === 'cart' || topOverlay === 'admin';

  // Tab content
  let tabContent;
  if (tab === 'home') tabContent = <HomeScreen week={t.week} />;
  else if (tab === 'store') tabContent = <StoreScreen onOpenProduct={openProduct} onOpenCart={openCart} cartCount={cartCount} />;
  else if (tab === 'ai') tabContent = <ChatScreen persona="نبضة" />;
  else if (tab === 'settings') tabContent = <SettingsScreen onOpenAdmin={openAdmin} />;

  // Overlay content
  let overlay = null;
  if (topOverlay === 'product' && activeProduct) {
    overlay = <ProductDetailScreen product={activeProduct} onBack={popStack} onAddToCart={(p, q) => { addToCart(p, q); popStack(); }} onOpenCart={openCart} cartCount={cartCount} />;
  } else if (topOverlay === 'cart') {
    overlay = <CartScreen items={cart} onBack={popStack} onUpdate={updateCart} onCheckout={() => setCart([])} />;
  } else if (topOverlay === 'admin') {
    overlay = <AdminScreen onBack={popStack} />;
  }

  return (
    <>
      <IOSDevice>
        <IOSStatusBar dark={!t.dark && !hideNav && tab !== 'ai'} />
        <div className="app" style={{
          background: tab === 'home' && !hideNav
            ? `linear-gradient(180deg, ${persona.bg1} 0%, var(--bg) 220px)`
            : 'var(--bg)',
        }}
             data-screen-label={
               hideNav ? topOverlay
               : tab === 'home' ? '01 Home — Pregnancy'
               : tab === 'store' ? '02 Store'
               : tab === 'ai' ? '03 AI Chat'
               : '04 Settings'
             }>
          {/* Main scrollable content (under bottom nav) */}
          <div className="scroll" style={{ bottom: hideNav ? 0 : 84 }}>
            {overlay || tabContent}
          </div>

          {/* Bottom nav */}
          {!hideNav && <BottomNav active={tab} onChange={setTab} />}

          {/* Toast */}
          {toast && <Toast msg={toast} onDone={() => setToast(null)} />}
        </div>
      </IOSDevice>

      {/* Tweaks panel */}
      <TweaksPanel title="تعديلات">
        <TweakSection label="المظهر" />
        <TweakToggle label="الوضع الداكن" value={t.dark} onChange={v => setTweak('dark', v)} />
        <TweakColor label="اللون الأساسي" value={t.primaryColor} options={PRIMARY_OPTIONS} onChange={v => setTweak('primaryColor', v)} />
        <TweakColor label="اللون الثانوي" value={t.secondaryColor} options={SECONDARY_OPTIONS} onChange={v => setTweak('secondaryColor', v)} />
        <TweakRadio label="الشخصية البصرية" value={t.persona} options={Object.keys(PERSONAS)} onChange={v => setTweak('persona', v)} />
        <TweakSection label="الحمل" />
        <TweakSlider label="أسبوع الحمل" value={t.week} min={4} max={40} step={1} unit=""
                     onChange={v => setTweak('week', [12, 20, 25, 30, 36].reduce((a, b) => Math.abs(b - v) < Math.abs(a - v) ? b : a, 25))} />
        <p style={{ fontSize: 10, color: 'rgba(0,0,0,.5)', margin: '4px 0 0' }}>
          (يثبّت على أسابيع لها بيانات: 12, 20, 25, 30, 36)
        </p>
      </TweaksPanel>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
