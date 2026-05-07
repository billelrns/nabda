# Handoff: تطبيق نبضة (Nabda) — Women's Health & Pregnancy App

## Overview
Nabda is a mobile women's health and pregnancy companion app, fully in **Arabic (RTL)**, targeting Algerian users. It combines pregnancy tracking, a baby/maternity store with local Algerian payment methods, an AI health assistant ("نبضة"), and an admin dashboard. Visual direction is Material Design 3 with a warm, feminine identity (teal + pink accents).

The handoff bundle is a **clickable HTML/React prototype** with 6 connected screens and a tweaks panel.

---

## About the Design Files
The files in this bundle are **design references created in HTML/JSX** — interactive prototypes showing the intended look, layout, and behavior. They are **not production code to copy directly**.

Your task is to **recreate these designs in the target codebase's environment** (Flutter / React Native / native iOS+Android / Next.js — whichever the team has chosen) using its established patterns, component library, and state management. If no codebase exists yet, **Flutter is recommended** since the original brief mentions Material Design 3, SliverAppBar, and the Material widget vocabulary — those map 1:1 to Flutter.

The HTML prototype uses inline JSX + plain CSS variables purely so the design is editable and previewable in the browser. None of the React components, CSS architecture, or routing approach should be ported as-is.

---

## Fidelity
**High-fidelity (hifi).** Final colors, typography, spacing, copy, iconography, gradients, shadows, and interaction patterns are all decided. Recreate pixel-perfectly.

---

## Tech Recommendation (Flutter)
| Concern | Suggested approach |
|---|---|
| Framework | Flutter 3.x (Material 3 enabled) |
| Localization | `flutter_localizations` + `intl`, locale `ar_DZ`, `Directionality.rtl` |
| Fonts | `google_fonts: Almarai` |
| State | Riverpod or Bloc — auth, cart, user profile, pregnancy state |
| Navigation | `go_router` with shell route for the bottom nav |
| Storage | `shared_preferences` for tweaks + cart, `hive` for offline content |
| Network | `dio` + a REST/Firebase backend |
| AI Chat | Stream from your LLM provider; render as `ListView.builder` |
| Admin | Same app gated by role, or separate Flutter Web dashboard |

---

## Design Tokens

### Colors
| Token | Hex | Usage |
|---|---|---|
| `teal` (primary) | `#00897B` | Primary actions, app bars, focus, "home" tab |
| `teal-700` | `#00796B` | Pressed/dark teal |
| `teal-50` | `#E0F2F1` | Tinted backgrounds, chip bg |
| `pink` (secondary) | `#E91E63` | Accents, prices, badges, "AI" tab |
| `pink-700` | `#C2185B` | Pressed pink |
| `pink-50` | `#FCE4EC` | Soft pink fills |
| `purple` (admin) | `#7E57C2` | Admin app bar, admin chips |
| `purple-700` | `#5E35B1` | Pressed purple |
| `purple-50` | `#EDE7F6` | Admin tinted bg |
| `bg` | `#FFF8FB` | App background (warm off-white) |
| `bg-2` | `#FDF2F6` | Secondary surface tint |
| `surface` | `#FFFFFF` | Cards |
| `ink` | `#1F1A20` | Primary text |
| `ink-2` | `#4A434B` | Secondary text |
| `ink-3` | `#8B8190` | Tertiary text, icons |
| `line` | `#F0E4EA` | Dividers, borders |
| `gold` | `#F2B544` | Stars, "popular" badge |
| `green` | `#34A853` | Success, free shipping |

**Dark theme overrides** (data-theme="dark"): `bg #18121A`, `surface #241A23`, `ink #F6EBF1`, `line #3A2A33`.

### Typography
- **Family**: `Almarai` (Google Fonts), fallback `Tajawal`, then system Arabic.
- **Weights used**: 400, 700, 800.
- **Scale** (in px, line-height 1.3–1.7):
  - h1: 22 / 800
  - h2: 18 / 800
  - h3: 15–17 / 700–800
  - body: 14 / 400 — line-height 1.6
  - small: 12 / 400
  - tiny: 10–11 / 600–700

### Spacing & radius
- Padding scale: 4, 8, 12, 14, 16, 18, 20, 24
- Card radius: 18 (small), 20 (regular), 24 (large), 28 (sheets), 32 (hero)
- Button radius: **999 (pill — all CTAs are pills)**
- Icon button: 40×40 round, 32×32 small round

### Shadows
- `shadow-sm`: `0 1px 2px rgba(31,26,32,.04), 0 2px 8px rgba(233,30,99,.04)`
- `shadow-md`: `0 4px 12px rgba(31,26,32,.06), 0 8px 24px rgba(233,30,99,.06)`
- `shadow-lg`: `0 12px 32px rgba(31,26,32,.08), 0 20px 60px rgba(233,30,99,.08)`
- Primary CTA shadow: `0 6px 16px rgba(0,137,123,.3)`
- Pink CTA shadow: `0 6px 16px rgba(233,30,99,.3)`

### Gradients (used heavily)
- **Primary teal**: `linear-gradient(135deg, #00897B 0%, #00796B 100%)`
- **Pink CTA**: `linear-gradient(135deg, #E91E63 0%, #C2185B 100%)`
- **AI / pink-purple**: `linear-gradient(135deg, #E91E63 0%, #7E57C2 100%)` — used on AI bubble, AI tab, profile avatar
- **Home hero**: `linear-gradient(160deg, #FCE4EC 0%, #FFF8FB 50%, #E0F2F1 100%)`
- **Admin app bar**: `linear-gradient(135deg, #7E57C2 0%, #5E35B1 100%)`
- **Pregnancy progress bar**: `linear-gradient(90deg, #00897B, #4DB6AC, #E91E63)`

---

## Global Layout
- **Direction**: RTL throughout. Use `Directionality(textDirection: TextDirection.rtl, ...)` at the app root.
- **Bottom nav**: 4 tabs — الرئيسية (home), المتجر (store), نبضة (AI, pink), الإعدادات (settings). 84px tall, blurred white background, top divider, active tab uses tinted icon container.
- **Status bar**: dark icons over light surfaces, light icons over teal/purple/pink app bars.
- **Hide bottom nav** on: product detail, cart/checkout, admin dashboard.

---

## Screens

### 1. Home (Pregnancy)
**Purpose**: Daily pregnancy companion — current week, fetus size, articles.

Layout (top to bottom):
1. **Hero block** — soft pink→white→teal gradient with rounded bottom (32px), decorative blob circles. Contains:
   - Greeting row: "صباح الخير 🌷" + user name "سارة", with notification icon (badge 3) and avatar (gradient pink→purple).
   - **Pregnancy card** (translucent white, blur, rounded 24): gradient pink fetus avatar with 👶 emoji (90×90), "الأسبوع 25 من 40" pill, "تبقّى 15 أسبوع", expected due date, **40-week progress bar** (gradient teal→pink with white circle thumb at current week), milestones row (الحمل / الثلث الثاني / الولادة).
2. **Fetus size card** — teal-tinted icon (76×76, fruit emoji), "حجم القرنبيط" + length cm + weight g, descriptive paragraph below.
3. **Quick categories row** — horizontal scroll of 5 chips (تغذية, رياضة, صحة نفسية, نوم, جمال) — pill cards 84×84 with emoji + label, alternating teal/pink/purple tints.
4. **Articles carousel** — section header "مقالات لهذا الأسبوع" + "عرض الكل" link. Cards 240px wide, image 130px tall, category pill overlaid top-left, title + read time below.
5. **Daily tip card** — purple gradient card with 💡 icon and tip text.

Week data is parameterized — current weeks with full content: 12, 20, 25, 30, 36. Default is 25.

### 2. Store
**Purpose**: Browse and shop maternity/baby products.

1. **App bar** — teal gradient, rounded bottom 28, "متجر نبضة" + "كل ما تحتاجينه 🛍️", trailing heart + cart icons (cart with count badge).
2. **Floating search bar** — overlaps app bar bottom by 36px. White card, search icon, RTL placeholder "ابحثي عن منتج...", trailing mic button.
3. **Promo banner** — pink gradient, "خصم 25%" headline + subtitle, large 🎀 emoji.
4. **Categories row** — horizontal scroll of **15 categories** (ملابس حمل، لوازم رضيع، رضاعة، حفاضات، فيتامينات، حقيبة ولادة، ألعاب، العناية، عربات، أسرّة وفرش، الاستحمام، شفّاطات، السلامة، كتب وقصص، هدايا) + "الكل" first. Each is 78×~88, emoji + label. Active = filled teal.
5. **Per-category carousels** — when "الكل" selected show 4 featured cats, otherwise just the active one. Section header per cat.
6. **Product card** (170×~280, vertical):
   - Image 150px tall, top-left discount badge `-XX%` (pink), top-right circular favorite button.
   - Name (2 lines, 13px/700)
   - Stars + (review count)
   - Price block: pink-700 bold + struck-through old price
   - Round teal "+" add-to-cart button bottom-right (raises a `nabda:add` event in the prototype — replace with cart provider call).
7. **Trust badges row** — 3-column card: 🚚 توصيل 48 ولاية، ✅ دفع آمن CCP/Edahabia، ↩️ إرجاع 7 أيام.

### 3. Product Detail
**Purpose**: View product, change quantity, add to cart.

1. **Image gallery** — 360px tall, swipe-able with translateX, dot indicators bottom center (active dot is wider). Top overlays: glass back button (right, since RTL), favorite + cart glass buttons (left). If discount, centered "-XX%" pink pill at top.
2. **Content sheet** — rounded 28 top, overlaps gallery by -24:
   - "متوفر — شحن سريع" teal pill
   - Product name (h1)
   - Stars + numeric rating + "(412 تقييم)"
   - **Price block** (pink gradient bg): price (24/800) + struck old price + quantity stepper (round white pill with − [N] +).
   - **Description** section
   - **Specs grid** 2×2: الفئة / العلامة / الضمان / الإرجاع
   - **Additional images** grid 2-col (110px tall each)
   - **Reviews preview** card (avatar, name, date, stars, quote)
3. **Bottom action bar** (fixed): purple AI consult icon button + full-width pink primary CTA "أضيفي للسلة • <total>".

### 4. Cart + Checkout
3-step flow with progress segments at top of pink app bar.

**Step 1 — السلة**:
- List of cart rows: 76×76 image, name, price, qty stepper, "إزالة" link.
- Promo code card with "تطبيق" button.

**Step 2 — العنوان**:
- Form fields: full name, phone, **wilaya select** (15 Algerian wilayas), address (multiline).
- Info card: "التوصيل: 2-4 أيام عمل عبر Yalidine / ZR Express".

**Step 3 — الدفع** — radio-cards for 4 methods:
- 💵 الدفع عند الاستلام (default, "الأكثر استخدامًا" gold badge)
- 💳 بطاقة الذهبية (Edahabia/CIB)
- 🏦 CCP — حساب بريدي (when selected, show mock account number `0099 4567 8912 34 / 56` + note about sending receipt)
- 📱 BaridiMob

**Order summary card** (always visible bottom of content): subtotal, shipping (free over 5,000 DZD), total. Currency formatted as `<n>.toLocaleString('ar-DZ') + ' دج'`.

**Done screen** — green checkmark circle, "شكرًا لك! 💕", order # `#NB-2026-04829`, expected delivery.

### 5. AI Chat (نبضة)
- **Header** — pink→purple gradient, ✨ avatar with green online dot, "نبضة" + "مساعدتك الذكية • متاحة الآن", menu icon. Disclaimer chip below: "⚠️ المعلومات للإرشاد فقط، لا تغني عن استشارة طبيبك المعالج.".
- **Messages list** — date separator, then bubbles:
  - **AI**: avatar (gradient circle with ✨) + bubble (white, shadow, radius `20 20 20 4`).
  - **Me**: bubble (teal gradient, white text, radius `20 20 4 20`), aligned end. Multi-line text supported (`whiteSpace: pre-wrap`).
- **Typing indicator** — 3 bouncing pink dots.
- **Suggestion chips** (only when ≤ 3 msgs) — outlined pills in purple text.
- **Input bar** — round "+" attach + rounded text field with image icon + send/mic round button (gradient pink→purple). When input non-empty → send icon; else mic.

### 6. Settings + Admin
**Settings**:
- Profile header: pink→teal gradient bg, large gradient avatar "س", name, "الأسبوع 25 من الحمل • الجزائر العاصمة", chips "💕 عضوة منذ 2025" + "⭐ 12 طلب".
- 10 settings rows (icon + title + subtitle + chevron).
- **Admin entry** row (highlighted purple gradient bg) — opens admin dashboard.
- Logout (red).
- Version footer.

**Admin Dashboard**:
- Purple gradient app bar with back button, "أهلًا بكِ" + "لوحة المشرف 🛡️", notification badge 5.
- **4 stats cards** (2×2 grid, overlapping app bar by -40px): icon tile + green delta % + value + label. Values: 12,840 مستخدمات / 1,247 طلبات / 486 منتج / 4.2M دج إيرادات.
- **Weekly revenue chart card** — 7 bars (last bar highlighted purple-700, others light purple), Arabic day initials.
- **9 module cards** in a 2-col grid: المستخدمات / الطلبات / المنتجات / المقالات / الدردشة / الأقسام / المدفوعات / الإشعارات / التقارير. Each: emoji + title + description.

---

## Interactions & Behavior
- Tab change → instant content swap with subtle 280ms fade-up enter.
- Add-to-cart → toast at bottom-center "أُضيف للسلة 💕" for ~2s.
- Product image swipe → translateX gallery with dot indicator update.
- Cart stepper qty=0 → remove item.
- Checkout step transitions → swap content, advance progress bar.
- AI message send → optimistic user bubble + 1.4s typing delay → mock reply (in production, stream tokens).
- Tweaks panel posts `__edit_mode_set_keys` to persist changes (prototype-only — not needed in production).

---

## Tweakable parameters (expose via in-app settings)
- Theme: light / dark
- Primary color: 4 swatches (`#00897B`, `#0097A7`, `#7E57C2`, `#5E35B1`)
- Secondary color: 4 swatches (`#E91E63`, `#EC407A`, `#F06292`, `#FF7043`)
- Visual persona: warm / bloom / serene (changes home gradient pair)
- Pregnancy week (snaps to weeks with content: 12, 20, 25, 30, 36 — production should support all 4–40)

---

## Data Model (sketch)

```
User { id, name, phone, wilaya, address, dueDate, currentWeek, role: 'user'|'admin' }
PregnancyWeek { week, sizeName, sizeIcon, lengthCm, weightG, description, milestone }
Article { id, title, category, readMinutes, coverUrl, body, weekRange[] }
Category { id, name, icon, parentId? }
Product { id, categoryId, name, price, oldPrice?, images[], description, rating, reviewCount, stock }
CartItem { productId, qty }
Order { id, userId, items[], wilaya, address, paymentMethod, subtotal, shipping, total, status }
ChatMessage { id, threadId, from: 'user'|'ai', text, timestamp }
```

Data fixtures used in the prototype live in `data.js` — copy out the products, categories, wilayas, and admin modules verbatim.

---

## Assets
- **Fonts**: Almarai (Google Fonts) — load via `google_fonts` package or self-host.
- **Product images**: prototype uses Unsplash CDN URLs. Replace with your own product photography or licensed stock.
- **Article images**: same — Unsplash.
- **Icons**: prototype uses inline SVG paths in `ui.jsx`. In Flutter use `Icons.*` (Material) or `lucide_icons` for closer match.
- **Emoji**: used liberally for category icons. Acceptable on iOS/Android; for cross-platform consistency consider Twemoji or replace with custom SVG icons later.

---

## Files in this bundle
- `Nabda.html` — entry point, loads everything.
- `styles.css` — design tokens (CSS custom properties), reusable classes.
- `data.js` — all fixture data (user, weeks, products, categories, wilayas, admin).
- `ui.jsx` — shared primitives: `Icon`, `Stars`, `AppBar`, `IconBtn`, `BottomNav`, `SmartImg`, `Toast`.
- `app.jsx` — top-level shell, tab routing, overlay stack, cart state, theming, tweaks wiring.
- `screens/home.jsx` — Pregnancy home.
- `screens/store.jsx` — Store list + ProductCard.
- `screens/product.jsx` — Product detail.
- `screens/cart.jsx` — Cart, address, payment, done.
- `screens/chat.jsx` — AI chat.
- `screens/settings.jsx` — Settings + Admin dashboard.
- `ios-frame.jsx`, `tweaks-panel.jsx` — prototype chrome only, **do not port**.

---

## Open questions for the team
1. Backend: Firebase, Supabase, or custom REST?
2. Authentication method (phone OTP via Algerian carriers? Email?)
3. AI model + safety guardrails (medical disclaimer is shown but content review is needed).
4. Real CCP / BaridiMob integration vs. manual receipt verification?
5. Shipping integration: Yalidine / ZR Express APIs?
6. Push notifications (FCM)?
7. RTL-aware analytics events naming convention?
