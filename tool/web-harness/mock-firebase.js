// Mock Firebase compat SDK for local headless testing (NOT shipped).
(function () {
  const params = new URLSearchParams(location.search);
  const LOGGED = localStorage.getItem('mock_user') || null; // 'mom' | 'admin' | null
  const now = Date.now();
  const day = 86400000;
  class Timestamp {
    constructor(ms) { this._ms = ms; this.seconds = Math.floor(ms / 1000); this.nanoseconds = 0; }
    toDate() { return new Date(this._ms); }
    toMillis() { return this._ms; }
    static fromDate(d) { return new Timestamp(d.getTime()); }
    static now() { return new Timestamp(Date.now()); }
  }
  const T = (msAgo) => new Timestamp(now - msAgo);
  const cats = ['ملابس الأطفال', 'مستلزمات الرضاعة', 'العناية بالأم', 'ألعاب تعليمية', 'مستلزمات الحمل', 'فيتامينات ومكملات'];
  const products = {};
  for (let i = 1; i <= 24; i++) {
    products['p' + i] = {
      name: (i === 6 ? 'مكمل حديد للحامل' : 'منتج تجريبي رقم ' + i), slug: 'prod-' + i,
      category: cats[i % cats.length], brand: ['Chicco', 'Pigeon', 'Avent'][i % 3],
      price: 1500 + i * 230, oldPrice: i % 3 === 0 ? 2500 + i * 230 : 0,
      image: '/landing-assets/slide-store.png', images: ['/landing-assets/slide-store.png', '/landing-assets/baby.png'],
      description: 'وصف تجريبي للمنتج.\nسطر ثانٍ.', rating: 4.5, reviewCount: 12 + i, stock: i % 7 === 0 ? 0 : (i % 5 === 0 ? 3 : 20),
      active: true, featured: i < 9, soldCount: 30 - i, lifeStageTags: i % 2 ? ['pregnant'] : ['newborn'],
      createdAt: T(i * day),
    };
  }
  const orders = {};
  const st = ['pending', 'confirmed', 'shipped', 'delivered', 'returned', 'cancelled', 'no_answer'];
  for (let i = 1; i <= 30; i++) {
    orders['o' + i] = { userId: i % 4 ? null : 'u_mom', source: 'website', status: st[i % st.length], customerName: 'زبونة ' + i,
      customerPhone: '055' + String(1000000 + i * 37).slice(0, 7), wilaya: ['الجزائر', 'وهران', 'سطيف', 'قسنطينة'][i % 4], commune: 'بلدية',
      address: 'حي ' + i, productId: 'p' + ((i % 20) + 1), productName: 'منتج تجريبي رقم ' + ((i % 20) + 1), quantity: 1 + (i % 2),
      unitPrice: 2000, shippingFee: 500, total: 4500, cartId: 'c' + Math.ceil(i / 2), createdAt: T(i * day / 3), history: [] };
  }
  const DB = {
    products, orders,
    users: { u_mom: { displayName: 'billel', email: 'mom@test.dz', lifeStage: 'pregnant', pregnancyStartDate: T(19 * 7 * day + 2 * day), onboardingDone: true, createdAt: T(100 * day) } },
    staff: { u_admin: { role: 'owner', isActive: true, name: 'المالك' } },
    site_config: { shipping: { rates: { 'الجزائر': { home: 400, desk: 250, enabled: true } } }, home: {}, shop: {}, settings: { whatsapp: '' } },
    community_posts: { cp1: { userId: 'u_x', author: 'أم ياسين', title: 'سؤال', content: 'مرحبا بالجميع', category: 'pregnancy', likes: 3, likedBy: [], comments: [], createdAt: T(day) } },
    reports: {}, waitlist: {}, admin_logs: {}, blocked_phones: {}, products_private: {}, dynamic_articles: {}, specialized_articles: {}, users_directory: {}, stats: { users: { count: 1234 } },
  };
  window.__mockDB = DB;
  const sub = {}; // path -> map
  function coll(path) { const parts = path.split('/'); if (parts.length === 1) { DB[path] = DB[path] || {}; return DB[path]; } sub[path] = sub[path] || {}; return sub[path]; }
  let autoId = 0;
  const FV = { serverTimestamp: () => Timestamp.now(), increment: (n) => ({ __inc: n }), arrayUnion: (...a) => ({ __union: a }), arrayRemove: (...a) => ({ __remove: a }), delete: () => ({ __del: 1 }) };
  function applyData(old, data) {
    const out = { ...(old || {}) };
    for (const [k, v] of Object.entries(data)) {
      if (v && v.__inc !== undefined) out[k] = (out[k] || 0) + v.__inc;
      else if (v && v.__union) out[k] = [...(out[k] || []), ...v.__union];
      else if (v && v.__remove) out[k] = (out[k] || []).filter((x) => !v.__remove.includes(x));
      else if (v && v.__del) delete out[k];
      else out[k] = v;
    }
    return out;
  }
  function snapDoc(path, id, data) { return { id, ref: docRef(path, id), exists: data !== undefined, data: () => (data === undefined ? undefined : JSON.parse(JSON.stringify(data), reviver)), get: (f) => data && data[f] }; }
  function reviver(k, v) { if (v && typeof v === 'object' && 'seconds' in v && 'nanoseconds' in v) return new Timestamp(v.seconds * 1000); return v; }
  function docRef(path, id) {
    id = id || 'auto' + (++autoId);
    return {
      id, path: path + '/' + id,
      get: async () => snapDoc(path, id, coll(path)[id]),
      set: async (d, o) => { const c = coll(path); c[id] = o && o.merge ? applyData(c[id], d) : applyData({}, d); },
      update: async (d) => { const c = coll(path); if (!c[id]) throw new Error('not-found'); c[id] = applyData(c[id], d); },
      delete: async () => { delete coll(path)[id]; },
      onSnapshot: (cb) => { setTimeout(() => cb(snapDoc(path, id, coll(path)[id])), 10); return () => {}; },
      collection: (sub) => query(path + '/' + id + '/' + sub),
    };
  }
  function query(path, filters = [], order = [], lim = 0) {
    const run = () => {
      let docs = Object.entries(coll(path)).map(([id, d]) => ({ id, d }));
      for (const [f, op, val] of filters) {
        docs = docs.filter(({ d }) => {
          const x = d[f];
          if (op === '==') return x === val; if (op === '!=') return x !== val;
          if (op === 'in') return val.includes(x); if (op === 'array-contains') return (x || []).includes(val);
          if (op === 'array-contains-any') return (x || []).some((y) => val.includes(y));
          const a = x && x.toMillis ? x.toMillis() : x, b = val && val.toMillis ? val.toMillis() : val;
          if (op === '>=') return a >= b; if (op === '<=') return a <= b; if (op === '>') return a > b; if (op === '<') return a < b; return true;
        });
      }
      for (const [f, dir] of order.slice().reverse()) docs.sort((p, q) => { const a = p.d[f], b = q.d[f]; const av = a && a.toMillis ? a.toMillis() : a, bv = b && b.toMillis ? b.toMillis() : b; return (av > bv ? 1 : av < bv ? -1 : 0) * (dir === 'desc' ? -1 : 1); });
      if (lim) docs = docs.slice(0, lim);
      const list = docs.map(({ id, d }) => snapDoc(path, id, d));
      return { docs: list, size: list.length, empty: !list.length, forEach: (fn) => list.forEach(fn), docChanges: () => list.map((doc) => ({ type: 'added', doc })) };
    };
    return {
      where: (f, op, v) => query(path, [...filters, [f, op, v]], order, lim),
      orderBy: (f, dir) => query(path, filters, [...order, [f, dir || 'asc']], lim),
      limit: (n) => query(path, filters, order, n), startAfter: () => query(path, filters, order, lim),
      get: async () => run(),
      onSnapshot: (cb, err) => { setTimeout(() => cb(run()), 10); return () => {}; },
      doc: (id) => docRef(path, id),
      add: async (d) => { const r = docRef(path); coll(path)[r.id] = applyData({}, d); return r; },
      count: () => ({ get: async () => ({ data: () => ({ count: run().size }) }) }),
    };
  }
  const users = { mom: { uid: 'u_mom', email: 'mom@test.dz', displayName: 'billel', photoURL: null }, admin: { uid: 'u_admin', email: 'admin@test.dz', displayName: 'Admin', photoURL: null } };
  let current = LOGGED ? users[LOGGED] : null;
  const listeners = [];
  const authObj = {
    get currentUser() { return current; },
    onAuthStateChanged(cb) { listeners.push(cb); setTimeout(() => cb(current), 20); return () => {}; },
    async signOut() { current = null; localStorage.removeItem('mock_user'); listeners.forEach((l) => l(null)); },
    async signInWithEmailAndPassword(e) { current = e.startsWith('admin') ? users.admin : users.mom; localStorage.setItem('mock_user', e.startsWith('admin') ? 'admin' : 'mom'); listeners.forEach((l) => l(current)); return { user: current }; },
    async createUserWithEmailAndPassword(e) { current = { uid: 'u_new', email: e, displayName: null, updateProfile: async () => {} }; listeners.forEach((l) => l(current)); return { user: current, additionalUserInfo: { isNewUser: true } }; },
    async signInWithPopup() { return this.signInWithEmailAndPassword('mom'); },
    async signInWithRedirect() {}, async getRedirectResult() { return { user: null }; },
    async sendPasswordResetEmail() {}, async setPersistence() {},
  };
  if (current) current.updateProfile = async () => {};
  function GoogleAuthProvider() { this.setCustomParameters = () => {}; this.addScope = () => {}; }
  const fsInstance = { collection: (p) => query(p), doc: (p) => { const i = p.lastIndexOf('/'); return docRef(p.slice(0, i), p.slice(i + 1)); }, batch: () => { const ops = []; return { set: (r, d, o) => ops.push(() => r.set(d, o)), update: (r, d) => ops.push(() => r.update(d)), delete: (r) => ops.push(() => r.delete()), commit: async () => { for (const o of ops) await o(); } }; }, runTransaction: async (fn) => fn({ get: (r) => r.get(), set: (r, d, o) => r.set(d, o), update: (r, d) => r.update(d) }), enablePersistence: async () => {} };
  const firestore = () => fsInstance; firestore.FieldValue = FV; firestore.Timestamp = Timestamp;
  const auth = () => authObj; auth.GoogleAuthProvider = GoogleAuthProvider; auth.Auth = { Persistence: { LOCAL: 'local', SESSION: 'session' } };
  const storage = () => ({ ref: (p) => ({ child: (c) => storage().ref(p + '/' + c), put: async () => ({ ref: { getDownloadURL: async () => '/landing-assets/baby.png' } }), getDownloadURL: async () => '/landing-assets/baby.png', delete: async () => {} }) });
  const apps = [];
  window.firebase = { apps, initializeApp: (c) => { apps.push({ options: c }); return {}; }, firestore, auth, storage, app: () => apps[0] };
})();
