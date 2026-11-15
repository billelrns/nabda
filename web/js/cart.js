// ═══════════════════════════════════════════════════════════════════
//  سلة التسوق — متجر نبضة (localStorage)
// ═══════════════════════════════════════════════════════════════════

import { currentMarket } from './market.js';

// سلة مستقلة لكل سوق (عملة واحدة في كل سلة): الجزائر = المفتاح التاريخي
export const cartKey = (code = currentMarket()) => (code === 'DZ' ? 'nb_cart_v1' : 'nb_cart_' + code);

export function getCart() {
  try {
    const raw = localStorage.getItem(cartKey());
    return raw ? JSON.parse(raw) : { items: [] };
  } catch (e) {
    console.error('Error reading cart:', e);
    return { items: [] };
  }
}

export function saveCart(cart) {
  try {
    localStorage.setItem(cartKey(), JSON.stringify(cart));
    window.dispatchEvent(new CustomEvent('nb-cart-updated', { detail: cart }));
  } catch (e) {
    console.error('Error saving cart:', e);
  }
}

export function addToCart(item) {
  const cart = getCart();
  const variantKey = item.variant || '';
  const idx = cart.items.findIndex(
    i => i.productId === item.productId && (i.variant || '') === variantKey
  );

  const addQty = Math.max(1, parseInt(item.qty || 1, 10));

  if (idx > -1) {
    cart.items[idx].qty = (cart.items[idx].qty || 1) + addQty;
  } else {
    cart.items.push({
      productId: item.productId,
      slug: item.slug || item.productId,
      name: item.name || '',
      image: item.image || item.imageUrl || '',
      price: Number(item.price) || 0,
      originalPrice: Number(item.oldPrice || item.originalPrice) || 0,
      variant: variantKey,
      qty: addQty
    });
  }

  saveCart(cart);
  return cart;
}

export function updateQty(productId, variant, qty) {
  const cart = getCart();
  const vKey = variant || '';
  const parsedQty = parseInt(qty, 10);

  if (parsedQty <= 0) {
    cart.items = cart.items.filter(
      i => !(i.productId === productId && (i.variant || '') === vKey)
    );
  } else {
    const itm = cart.items.find(
      i => i.productId === productId && (i.variant || '') === vKey
    );
    if (itm) itm.qty = parsedQty;
  }

  saveCart(cart);
  return cart;
}

export function removeFromCart(productId, variant) {
  const cart = getCart();
  const vKey = variant || '';
  cart.items = cart.items.filter(
    i => !(i.productId === productId && (i.variant || '') === vKey)
  );
  saveCart(cart);
  return cart;
}

export function clearCart() {
  const empty = { items: [] };
  saveCart(empty);
  return empty;
}

export function getCartCount() {
  const cart = getCart();
  return cart.items.reduce((sum, item) => sum + (parseInt(item.qty, 10) || 1), 0);
}

export function getCartTotal() {
  const cart = getCart();
  return cart.items.reduce((sum, item) => sum + ((Number(item.price) || 0) * (parseInt(item.qty, 10) || 1)), 0);
}

export function onCartChange(callback) {
  window.addEventListener('nb-cart-updated', (e) => {
    callback(e.detail);
  });
}
