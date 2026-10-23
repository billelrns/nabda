// ═══════════════════════════════════════════════════════════════════
//  تهيئة خدمات Firebase لموقع نبضة (v10 compat)
// ═══════════════════════════════════════════════════════════════════

import { firebaseConfig } from './site-config.js';

// تهيئة تطبيق Firebase إن لم يكن قد تم تهيئته مسبقاً
if (!window.firebase.apps.length) {
  window.firebase.initializeApp(firebaseConfig);
}

export const firebase = window.firebase;
export const auth = window.firebase.auth();
export const db = window.firebase.firestore();
export const storage = window.firebase.storage();
export const googleProvider = new window.firebase.auth.GoogleAuthProvider();

// إعدادات إضافية لمزود Google
googleProvider.setCustomParameters({ prompt: 'select_account' });

/**
 * دالة مساعدة للحصول على المستخدم الحالي أو الانتظار حتى اكتمال التهيئة
 */
export function getCurrentUser() {
  return new Promise((resolve) => {
    const unsubscribe = auth.onAuthStateChanged((user) => {
      unsubscribe();
      resolve(user);
    });
  });
}

/**
 * جلب وثيقة المستخدم من مجموعة users/{uid}
 */
export async function getUserProfile(uid) {
  if (!uid) return null;
  try {
    const snap = await db.collection('users').doc(uid).get();
    return snap.exists ? snap.data() : null;
  } catch (err) {
    console.error('Error fetching user profile:', err);
    return null;
  }
}
