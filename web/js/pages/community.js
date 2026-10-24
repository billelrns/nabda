/**
 * Nabda - Community Page Logic (نظير شاشة المجتمع في التطبيق)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';

let currentUser = null;
let userProfile = null;
let currentFilter = 'all';
let posts = [];

export async function initCommunityPage() {
  auth.onAuthStateChanged(async (user) => {
    currentUser = user;
    const visitorOverlay = document.getElementById('nb-community-visitor-view');
    const memberView = document.getElementById('nb-community-member-view');

    if (user) {
      if (visitorOverlay) visitorOverlay.style.display = 'none';
      if (memberView) memberView.style.display = 'block';

      try {
        const snap = await db.collection('users').doc(user.uid).get();
        if (snap.exists) userProfile = snap.data();
      } catch (e) {
        console.warn('Could not load user profile for community:', e);
      }

      loadCommunityPosts();
    } else {
      if (visitorOverlay) visitorOverlay.style.display = 'block';
      if (memberView) memberView.style.display = 'none';
    }
  });

  setupGroupFilters();
  setupPostModal();
  setupReportModal();
}

function setupGroupFilters() {
  const pills = document.querySelectorAll('.nb-group-pill');
  pills.forEach(pill => {
    pill.addEventListener('click', () => {
      pills.forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentFilter = pill.dataset.group || 'all';
      renderPosts();
    });
  });
}

async function loadCommunityPosts() {
  const container = document.getElementById('nb-posts-feed');
  if (!container) return;

  container.innerHTML = '<div style="text-align:center;padding:40px;color:var(--nb-ink-3)">جاري تحميل منشورات المجتمع...</div>';

  try {
    const snap = await db.collection('community_posts')
      .orderBy('createdAt', 'desc')
      .limit(30)
      .get();

    posts = [];
    snap.forEach(doc => {
      posts.push({ id: doc.id, ...doc.data() });
    });

    renderPosts();
  } catch (err) {
    console.error('Error fetching community posts:', err);
    container.innerHTML = '<div style="text-align:center;padding:40px;color:var(--nb-ink-3)">تعذر تحميل المنشورات حالياً، يرجى المحاولة لاحقاً.</div>';
  }
}

function renderPosts() {
  const container = document.getElementById('nb-posts-feed');
  if (!container) return;

  const filtered = currentFilter === 'all'
    ? posts
    : posts.filter(p => p.group === currentFilter || p.category === currentFilter);

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="background:#FFFFFF;border:1px solid #F8E1EA;border-radius:20px;padding:40px 20px;text-align:center;box-shadow:0 6px 20px rgba(0,0,0,0.02)">
        <div style="font-size:40px;margin-bottom:10px">🌸</div>
        <h4 style="font-size:16px;font-weight:800;color:var(--nb-ink);margin-bottom:6px">لا توجد منشورات في هذه المجموعة بعد</h4>
        <p style="font-size:13px;color:var(--nb-ink-3);margin-bottom:16px">كوني أول من يطرح سؤالاً أو يشارك تجربته في هذا القسم!</p>
        <button class="nb-btn-primary" onclick="window.openCreatePostModal()">كتابة منشور جديد ✍️</button>
      </div>
    `;
    return;
  }

  container.innerHTML = filtered.map(post => {
    const isLiked = currentUser && Array.isArray(post.likedBy) && post.likedBy.includes(currentUser.uid);
    const likesCount = post.likes || (Array.isArray(post.likedBy) ? post.likedBy.length : 0);
    const commentsCount = Array.isArray(post.comments) ? post.comments.length : (post.commentCount || 0);

    const timeStr = post.createdAt?.toDate
      ? post.createdAt.toDate().toLocaleDateString('ar-DZ', { month: 'short', day: 'numeric' })
      : 'حديثاً';

    const authorName = post.authorName || 'أم من نبضة';
    const authorStage = post.authorStage || 'عضوة نبضة';

    return `
      <article class="nb-post-card" id="post-${post.id}">
        <!-- Post Header -->
        <div class="nb-post-header">
          <div style="display:flex;align-items:center;gap:12px">
            <div class="nb-post-avatar">🌸</div>
            <div>
              <div style="font-weight:800;color:var(--nb-ink);font-size:14.5px">${authorName}</div>
              <div style="font-size:11.5px;color:var(--nb-ink-3)">${authorStage} • ${timeStr}</div>
            </div>
          </div>

          <div style="display:flex;align-items:center;gap:8px">
            <span class="nb-post-badge">${post.group || 'عام'}</span>
            <button class="nb-btn-secondary" style="font-size:11px;padding:2px 8px;border:none;background:transparent;color:#999" onclick="window.openReportModal('${post.id}')" title="إبلاغ">⚠️</button>
          </div>
        </div>

        <!-- Post Content -->
        <div class="nb-post-content">${escapeHtml(post.content || '')}</div>

        <!-- Post Actions -->
        <div class="nb-post-actions">
          <button class="nb-action-btn ${isLiked ? 'liked' : ''}" onclick="window.toggleLikePost('${post.id}')">
            <span>${isLiked ? '❤️' : '🤍'}</span>
            <span>${likesCount} إعجاب</span>
          </button>

          <button class="nb-action-btn" onclick="window.toggleComments('${post.id}')">
            <span>💬</span>
            <span>${commentsCount} تعليق</span>
          </button>

          <button class="nb-action-btn" onclick="navigator.clipboard.writeText(window.location.origin + '/community/post/' + '${post.id}');alert('تم نسخ رابط المنشور!')">
            <span>🔗</span>
            <span>مشاركة</span>
          </button>
        </div>

        <!-- Comments Section -->
        <div class="nb-comments-box" id="comments-${post.id}" style="display:none">
          <div class="nb-comments-list" id="comments-list-${post.id}">
            ${renderCommentsList(post.comments || [])}
          </div>
          <div class="nb-comment-form">
            <input type="text" id="comment-input-${post.id}" placeholder="اكتبي تعليقاً لطيفاً ومشجعاً..." class="nb-comment-input">
            <button class="nb-btn-primary" style="font-size:12.5px;padding:6px 14px" onclick="window.submitComment('${post.id}')">إرسال</button>
          </div>
        </div>
      </article>
    `;
  }).join('');
}

function renderCommentsList(comments) {
  if (!comments || comments.length === 0) {
    return '<div style="font-size:12px;color:var(--nb-ink-3);padding:8px 0">لا توجد تعليقات بعد. كوني أول المعلقات!</div>';
  }
  return comments.map(c => `
    <div class="nb-comment-item">
      <div style="font-weight:800;font-size:12px;color:var(--nb-ink);margin-bottom:2px">${escapeHtml(c.authorName || 'أم من نبضة')}</div>
      <div style="font-size:13px;color:var(--nb-ink-2);line-height:1.5">${escapeHtml(c.text || '')}</div>
    </div>
  `).join('');
}

window.toggleComments = function(postId) {
  const box = document.getElementById(`comments-${postId}`);
  if (box) {
    box.style.display = box.style.display === 'none' ? 'block' : 'none';
  }
};

window.toggleLikePost = async function(postId) {
  if (!currentUser) return;
  const post = posts.find(p => p.id === postId);
  if (!post) return;

  const likedBy = Array.isArray(post.likedBy) ? [...post.likedBy] : [];
  const idx = likedBy.indexOf(currentUser.uid);

  if (idx > -1) {
    likedBy.splice(idx, 1);
  } else {
    likedBy.push(currentUser.uid);
  }

  post.likedBy = likedBy;
  post.likes = likedBy.length;
  renderPosts();

  try {
    await db.collection('community_posts').doc(postId).update({
      likedBy: likedBy,
      likes: likedBy.length,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
  } catch (err) {
    console.error('Error updating like:', err);
  }
};

window.submitComment = async function(postId) {
  if (!currentUser) return;
  const input = document.getElementById(`comment-input-${postId}`);
  if (!input || !input.value.trim()) return;

  const text = input.value.trim();
  const authorName = userProfile?.displayName || 'أم من نبضة';

  const newComment = {
    authorId: currentUser.uid,
    authorName: authorName,
    text: text,
    createdAt: new Date().toISOString()
  };

  const post = posts.find(p => p.id === postId);
  if (!post) return;

  post.comments = post.comments || [];
  post.comments.push(newComment);

  input.value = '';
  const listEl = document.getElementById(`comments-list-${postId}`);
  if (listEl) listEl.innerHTML = renderCommentsList(post.comments);

  try {
    await db.collection('community_posts').doc(postId).update({
      comments: firebase.firestore.FieldValue.arrayUnion(newComment),
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
  } catch (err) {
    console.error('Error submitting comment:', err);
  }
};

function setupPostModal() {
  window.openCreatePostModal = function() {
    const modal = document.getElementById('nb-create-post-modal');
    if (modal) modal.classList.add('open');
  };

  window.closeCreatePostModal = function() {
    const modal = document.getElementById('nb-create-post-modal');
    if (modal) modal.classList.remove('open');
  };

  window.submitNewPost = async function() {
    if (!currentUser) return;
    const contentInput = document.getElementById('nb-post-content-input');
    const groupInput = document.getElementById('nb-post-group-select');

    if (!contentInput || !contentInput.value.trim()) {
      alert('يرجى كتابة نص المنشور.');
      return;
    }

    const content = contentInput.value.trim();
    if (content.length > 2000) {
      alert('الحد الأقصى لطول المنشور هو 2000 حرف.');
      return;
    }

    const group = groupInput?.value || 'عام';
    const authorName = userProfile?.displayName || 'أم من نبضة';

    let stage = 'عضوة';
    if (userProfile?.lifeStage === 'pregnant') stage = 'حامل';
    else if (userProfile?.lifeStage === 'baby') stage = 'أم جديدة';

    try {
      const docRef = await db.collection('community_posts').add({
        userId: currentUser.uid,
        authorName: authorName,
        authorStage: stage,
        group: group,
        content: content,
        likes: 0,
        likedBy: [],
        comments: [],
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      });

      contentInput.value = '';
      window.closeCreatePostModal();
      loadCommunityPosts();
    } catch (err) {
      console.error('Error creating post:', err);
      alert('حدث خطأ أثناء نشر المشاركة: ' + err.message);
    }
  };
}

function setupReportModal() {
  let targetPostId = null;

  window.openReportModal = function(postId) {
    targetPostId = postId;
    const modal = document.getElementById('nb-report-modal');
    if (modal) modal.classList.add('open');
  };

  window.closeReportModal = function() {
    targetPostId = null;
    const modal = document.getElementById('nb-report-modal');
    if (modal) modal.classList.remove('open');
  };

  window.submitReport = async function() {
    if (!currentUser || !targetPostId) return;
    const reasonInput = document.getElementById('nb-report-reason-select');
    const reason = reasonInput?.value || 'محتوى غير لائق';

    try {
      await db.collection('reports').add({
        reporterUid: currentUser.uid,
        postId: targetPostId,
        reason: reason,
        status: 'pending',
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      });

      alert('شكراً لحرصكِ. تم رفع البلاغ لمراجعته من قِبل إدارة نبضة.');
      window.closeReportModal();
    } catch (err) {
      console.error('Error sending report:', err);
      alert('حدث خطأ أثناء إرسال البلاغ.');
    }
  };
}

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>"']/g, m => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[m]));
}
