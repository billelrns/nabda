import os
import json
import shutil

# Paths
json_path = r'C:\nabda_app\assets\data\smart_2500_articles.json'
if not os.path.exists(json_path):
    json_path = r'C:\nabda_app\assets\data\smart_1500_articles.json'

print(f"Loading articles data from: {json_path}")
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

articles = data.get('articles', [])
articles_count = len(articles)
print(f"Total articles loaded: {articles_count}")

# Compact JSON string
articles_json_str = json.dumps(articles, ensure_ascii=False)

# HTML Template (Using __ARTICLES_JSON__ placeholder to avoid escaping CSS curly braces)
html_template = """<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>موسوعة نبضة — دليلكِ الشامل لصحة المرأة، الأمومة والجمال</title>
  <meta name="description" content="موسوعة نبضة الطبية والمصورة: أكثر من 2,500 مقال ودليل موثق حول الحمل والولادة، العناية بالبشرة والجمال، التبويض والخصوبة، صحة المرأة ورعاية الرضيع.">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800;900&family=Tajawal:wght@400;500;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {
      /* Nabda Modern Color Palette */
      --primary-pink: #E91E63;
      --primary-hover: #c91845;
      --soft-pink: #FF6090;
      --light-pink-bg: #fff0f4;
      --accent-teal: #00897B;
      --accent-teal-hover: #006b7d;
      --accent-purple: #7E57C2;
      --text-dark: #222222;
      --text-title: #1a1a1a;
      --text-muted: #6e6e6e;
      --text-light: #8f8f8f;
      --bg-page: #f8f8f8;
      --card-bg: #ffffff;
      --card-border: #e4e9ea;
      --card-radius: 16px;
      --shadow-sm: 0 2px 8px rgba(0,0,0,0.04);
      --shadow-hover: 0 12px 28px rgba(0,0,0,0.08);
      --font-main: 'Cairo', 'Tajawal', sans-serif;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: var(--font-main);
    }

    body {
      background-color: var(--bg-page);
      color: var(--text-dark);
      line-height: 1.6;
      direction: rtl;
      text-align: right;
    }

    a {
      text-decoration: none;
      color: inherit;
    }

    /* Top Promo Banner */
    .top-banner {
      background: linear-gradient(90deg, #fce4ec 0%, #f3e5f5 50%, #e0f2f1 100%);
      border-bottom: 1px solid #ebd4de;
      padding: 8px 16px;
      font-size: 13px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
    }
    .top-banner-title {
      display: flex;
      align-items: center;
      gap: 8px;
      color: #555;
      font-weight: 600;
    }
    .top-banner-title span.pulse {
      display: inline-block;
      width: 8px;
      height: 8px;
      background-color: var(--primary-pink);
      border-radius: 50%;
      box-shadow: 0 0 0 0 rgba(228, 37, 88, 0.7);
      animation: pulseAnim 1.6s infinite;
    }
    @keyframes pulseAnim {
      0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(228, 37, 88, 0.7); }
      70% { transform: scale(1); box-shadow: 0 0 0 8px rgba(228, 37, 88, 0); }
      100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(228, 37, 88, 0); }
    }
    .top-banner-badges {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .store-badge-btn {
      background: #ffffff;
      border: 1px solid #d5dedf;
      color: #333;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 700;
      display: inline-flex;
      align-items: center;
      gap: 5px;
      transition: all 0.2s ease;
    }
    .store-badge-btn:hover {
      background: var(--primary-pink);
      color: #fff;
      border-color: var(--primary-pink);
    }

    /* Main Navigation Bar */
    .main-nav-wrapper {
      background-color: #ffffff;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
      position: sticky;
      top: 0;
      z-index: 1000;
      border-bottom: 1px solid #eaeaea;
    }
    .nav-container {
      max-width: 1280px;
      margin: 0 auto;
      padding: 0 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      height: 74px;
      gap: 16px;
    }
    .brand-logo-area {
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      flex-shrink: 0;
    }
    .brand-logo-img {
      width: 44px;
      height: 44px;
      border-radius: 12px;
      object-fit: cover;
      box-shadow: 0 4px 10px rgba(228, 37, 88, 0.2);
    }
    .brand-names {
      display: flex;
      flex-direction: column;
    }
    .brand-name-main {
      font-size: 24px;
      font-weight: 900;
      color: var(--primary-pink);
      line-height: 1.1;
      letter-spacing: -0.5px;
    }
    .brand-slogan {
      font-size: 11px;
      font-weight: 600;
      color: var(--accent-teal);
    }

    /* Nav Search Form */
    .nav-search-form {
      flex: 1;
      max-width: 480px;
      position: relative;
    }
    .nav-search-box {
      width: 100%;
      display: flex;
      align-items: center;
      border: 1.5px solid #FF6090;
      border-radius: 50px;
      background: #ffffff;
      overflow: hidden;
      transition: all 0.25s ease;
      box-shadow: 0 2px 8px rgba(255, 108, 147, 0.1);
    }
    .nav-search-box:focus-within {
      border-color: var(--primary-pink);
      box-shadow: 0 4px 14px rgba(228, 37, 88, 0.25);
    }
    .nav-search-input {
      flex: 1;
      border: none;
      outline: none;
      padding: 10px 18px;
      font-size: 14px;
      color: var(--text-dark);
      background: transparent;
      direction: rtl;
    }
    .nav-search-btn {
      background: var(--primary-pink);
      border: none;
      color: #ffffff;
      padding: 10px 18px;
      cursor: pointer;
      font-weight: 700;
      font-size: 13px;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: background 0.2s ease;
    }
    .nav-search-btn:hover {
      background: var(--primary-hover);
    }

    .nav-app-btn {
      background: linear-gradient(135deg, var(--primary-pink), var(--accent-purple));
      color: #ffffff;
      padding: 9px 20px;
      border-radius: 50px;
      font-size: 13.5px;
      font-weight: 800;
      box-shadow: 0 4px 14px rgba(228, 37, 88, 0.3);
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.25s ease;
      flex-shrink: 0;
    }
    .nav-app-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 18px rgba(228, 37, 88, 0.45);
    }

    /* Category Navigation Menu */
    .categories-menu-row {
      background-color: #ffffff;
      border-bottom: 1px solid #eef0f1;
      overflow-x: auto;
      white-space: nowrap;
      scrollbar-width: none;
    }
    .categories-menu-row::-webkit-scrollbar {
      display: none;
    }
    .categories-menu-container {
      max-width: 1280px;
      margin: 0 auto;
      padding: 0 20px;
      display: flex;
      align-items: center;
      gap: 4px;
    }
    .cat-menu-item {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 14px 16px;
      font-size: 15px;
      font-weight: 600;
      color: #333333;
      border-bottom: 3px solid transparent;
      cursor: pointer;
      transition: all 0.2s ease;
      user-select: none;
    }
    .cat-menu-item:hover {
      color: var(--primary-pink);
      border-bottom-color: rgba(228, 37, 88, 0.4);
    }
    .cat-menu-item.active {
      color: var(--primary-pink);
      font-weight: 800;
      border-bottom-color: var(--primary-pink);
    }
    .cat-menu-badge {
      background-color: rgba(228, 37, 88, 0.1);
      color: var(--primary-pink);
      border-radius: 50px;
      padding: 2px 8px;
      font-size: 11px;
      font-weight: 700;
    }

    /* Content Wrapper & Breadcrumb */
    .content-wrapper {
      max-width: 1280px;
      margin: 24px auto;
      padding: 0 20px;
    }
    .breadcrumb-row {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      color: var(--text-muted);
      margin-bottom: 18px;
      font-weight: 500;
    }
    .breadcrumb-row a {
      color: var(--accent-teal);
      font-weight: 700;
      transition: color 0.2s ease;
    }
    .breadcrumb-row a:hover {
      color: var(--primary-pink);
    }
    .breadcrumb-row .sep {
      color: #bbb;
      font-size: 12px;
    }
    .breadcrumb-current {
      color: #333;
      font-weight: 700;
    }

    /* Section Main Title Bar */
    .section-title-bar {
      background: #ffffff;
      border-radius: var(--card-radius);
      border: 1px solid var(--card-border);
      padding: 22px 28px;
      margin-bottom: 28px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
      box-shadow: var(--shadow-sm);
    }
    .section-title-main {
      font-size: 26px;
      font-weight: 900;
      color: var(--text-title);
      position: relative;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .section-title-main::after {
      content: "";
      display: block;
      width: 45px;
      height: 3px;
      background: var(--primary-pink);
      border-radius: 3px;
      margin-top: 6px;
    }
    .section-stats-pill {
      background: var(--light-pink-bg);
      color: var(--primary-pink);
      padding: 8px 18px;
      border-radius: 50px;
      font-size: 13.5px;
      font-weight: 800;
      border: 1px solid rgba(228, 37, 88, 0.2);
    }

    /* 3-Column Articles Grid */
    .articles-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 26px;
      margin-bottom: 40px;
    }
    @media (max-width: 1024px) {
      .articles-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 20px;
      }
    }
    @media (max-width: 640px) {
      .articles-grid {
        grid-template-columns: 1fr;
        gap: 18px;
      }
    }

    /* Nabda Card Style */
    .nabda-card, .nb-art-card {
      background: var(--card-bg);
      border-radius: 20px;
      border: 1px solid var(--card-border);
      overflow: hidden;
      display: flex;
      flex-direction: column;
      cursor: pointer;
      transition: all 0.3s cubic-bezier(0.165, 0.84, 0.44, 1);
      position: relative;
    }
    .nabda-card:hover, .nb-art-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 16px 36px rgba(0, 0, 0, 0.09);
      border-color: rgba(228, 37, 88, 0.35);
    }

    .card-img-wrap {
      position: relative;
      width: 100%;
      height: 240px;
      overflow: hidden;
      background: #f0e6eb;
    }
    .card-img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      transition: transform 0.45s ease;
    }
    .nabda-card:hover .card-img, .nb-art-card:hover .card-img {
      transform: scale(1.06);
    }

    .card-floating-cat {
      position: absolute;
      top: 14px;
      right: 14px;
      background: rgba(255, 255, 255, 0.94);
      backdrop-filter: blur(8px);
      color: var(--accent-teal);
      padding: 5px 12px;
      border-radius: 50px;
      font-size: 12px;
      font-weight: 800;
      box-shadow: 0 3px 10px rgba(0, 0, 0, 0.12);
      display: flex;
      align-items: center;
      gap: 5px;
    }

    .card-content-area {
      padding: 20px 20px 16px;
      display: flex;
      flex-direction: column;
      flex-grow: 1;
      justify-content: space-between;
    }
    .card-cat-label {
      color: var(--accent-teal);
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 8px;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .card-title {
      font-size: 17.5px;
      font-weight: 800;
      color: var(--text-title);
      line-height: 1.42;
      margin-bottom: 10px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
      min-height: 48px;
      transition: color 0.2s ease;
    }
    .nabda-card:hover .card-title, .nb-art-card:hover .card-title {
      color: var(--primary-pink);
    }
    .card-snippet {
      font-size: 13.5px;
      color: var(--text-muted);
      line-height: 1.6;
      margin-bottom: 16px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .card-bottom-bar {
      padding-top: 12px;
      border-top: 1px solid #f0f2f3;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .card-views-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background-color: rgba(110, 110, 110, 0.08);
      color: #666666;
      padding: 4px 11px;
      border-radius: 8px;
      font-size: 12.5px;
      font-weight: 600;
    }
    .card-read-time {
      font-size: 12px;
      color: var(--text-light);
      font-weight: 600;
    }
    .card-read-btn {
      color: var(--primary-pink);
      font-weight: 800;
      font-size: 13px;
      display: inline-flex;
      align-items: center;
      gap: 4px;
      transition: transform 0.2s ease;
    }
    .nabda-card:hover .card-read-btn, .nb-art-card:hover .card-read-btn {
      transform: translateX(-4px);
    }

    /* Pagination */
    .pagination-wrapper {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 8px;
      margin: 35px 0 60px;
      flex-wrap: wrap;
    }
    .page-btn {
      background: #ffffff;
      border: 1px solid var(--card-border);
      color: var(--text-dark);
      padding: 8px 16px;
      border-radius: 10px;
      font-size: 14.5px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s ease;
      min-width: 42px;
      text-align: center;
    }
    .page-btn:hover {
      border-color: var(--primary-pink);
      color: var(--primary-pink);
    }
    .page-btn.active {
      background: var(--primary-pink);
      color: #ffffff;
      border-color: var(--primary-pink);
      box-shadow: 0 4px 12px rgba(228, 37, 88, 0.3);
    }
    .page-btn.disabled {
      opacity: 0.5;
      cursor: not-allowed;
      border-color: #eee;
    }
    .page-ellipsis {
      padding: 8px 6px;
      color: #999;
      font-weight: bold;
    }

    /* Article Reading Modal */
    .article-modal-backdrop {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(18, 14, 20, 0.72);
      backdrop-filter: blur(8px);
      z-index: 2000;
      overflow-y: auto;
      padding: 24px 16px;
    }
    .article-modal-container {
      background: #ffffff;
      max-width: 980px;
      margin: 20px auto;
      border-radius: 24px;
      overflow: hidden;
      box-shadow: 0 25px 65px rgba(0, 0, 0, 0.3);
      position: relative;
      animation: modalSlideUp 0.3s ease;
    }
    @keyframes modalSlideUp {
      from { opacity: 0; transform: translateY(24px); }
      to { opacity: 1; transform: translateY(0); }
    }

    .modal-close-btn {
      position: absolute;
      top: 18px;
      left: 18px;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.95);
      border: 1px solid #ddd;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      color: #333;
      cursor: pointer;
      z-index: 20;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      transition: all 0.2s ease;
    }
    .modal-close-btn:hover {
      background: var(--primary-pink);
      color: #ffffff;
      border-color: var(--primary-pink);
      transform: scale(1.08);
    }

    .modal-article-header {
      padding: 34px 36px 20px;
      background: #ffffff;
      border-bottom: 1px solid #f0f0f0;
    }
    .modal-breadcrumb {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 13.5px;
      color: var(--accent-teal);
      font-weight: 700;
      margin-bottom: 14px;
    }
    .modal-article-title {
      font-size: 28px;
      font-weight: 900;
      color: var(--text-title);
      line-height: 1.36;
      margin-bottom: 16px;
    }

    .modal-author-bar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
      padding-top: 12px;
      border-top: 1px solid #f2f4f5;
    }
    .author-info-box {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .author-avatar {
      width: 42px;
      height: 42px;
      border-radius: 50%;
      border: 2px solid var(--primary-pink);
      object-fit: cover;
    }
    .author-details {
      display: flex;
      flex-direction: column;
    }
    .author-name {
      font-size: 14.5px;
      font-weight: 800;
      color: #222;
      display: flex;
      align-items: center;
      gap: 5px;
    }
    .author-verified {
      color: #1da1f2;
      font-size: 14px;
    }
    .publish-date {
      font-size: 12.5px;
      color: var(--text-muted);
    }

    .social-share-row {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .share-icon-btn {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
      border: 1px solid #e0e0e0;
      background: #ffffff;
      color: #444;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .share-icon-btn:hover {
      background: var(--light-pink-bg);
      border-color: var(--primary-pink);
      color: var(--primary-pink);
      transform: translateY(-2px);
    }

    .modal-body-layout {
      display: grid;
      grid-template-columns: 1fr 310px;
      gap: 28px;
      padding: 28px 36px 40px;
      background: #ffffff;
    }
    @media (max-width: 860px) {
      .modal-body-layout {
        grid-template-columns: 1fr;
        padding: 20px;
      }
      .modal-article-header {
        padding: 24px 20px 16px;
      }
      .modal-article-title {
        font-size: 22px;
      }
    }

    .modal-main-content {
      line-height: 1.85;
      font-size: 16px;
      color: #333333;
    }
    .modal-featured-img {
      width: 100%;
      max-height: 420px;
      object-fit: cover;
      border-radius: 16px;
      margin-bottom: 24px;
      box-shadow: 0 4px 14px rgba(0,0,0,0.06);
    }
    .article-lead-box {
      background: var(--light-pink-bg);
      border-right: 4px solid var(--primary-pink);
      padding: 18px 22px;
      border-radius: 12px;
      font-size: 15.5px;
      color: #444;
      line-height: 1.8;
      margin-bottom: 26px;
    }

    .article-section-h2 {
      color: var(--accent-teal);
      font-size: 21px;
      font-weight: 800;
      margin: 28px 0 12px;
      padding-bottom: 8px;
      border-bottom: 1.5px solid #eef2f3;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .article-section-h3 {
      color: var(--primary-pink);
      font-size: 18px;
      font-weight: 800;
      margin: 20px 0 10px;
    }
    .article-text-p {
      margin-bottom: 16px;
      font-size: 15.5px;
      color: #3d3540;
    }

    .nabda-points-list {
      list-style: none;
      padding: 0;
      margin: 16px 0 24px;
    }
    .nabda-points-list li {
      position: relative;
      padding: 10px 16px 10px 12px;
      margin-bottom: 8px;
      background: #fafafa;
      border-radius: 10px;
      border-right: 3px solid var(--accent-teal);
      font-size: 15px;
      color: #444;
      display: flex;
      align-items: flex-start;
      gap: 10px;
    }
    .nabda-points-list li span.dot {
      color: var(--primary-pink);
      font-weight: bold;
    }

    .medical-tip-callout {
      background: #e8f5e9;
      border-right: 4px solid #43a047;
      color: #2e7d32;
      padding: 16px 20px;
      border-radius: 12px;
      margin: 20px 0;
      font-size: 15px;
    }
    .medical-warn-callout {
      background: #fff8e1;
      border-right: 4px solid #ffa000;
      color: #e65100;
      padding: 16px 20px;
      border-radius: 12px;
      margin: 20px 0;
      font-size: 15px;
    }

    .interactive-tool-box {
      background: linear-gradient(135deg, #fff0f4 0%, #ede7f6 100%);
      border: 1.5px dashed var(--soft-pink);
      border-radius: 16px;
      padding: 24px;
      text-align: center;
      margin: 32px 0;
    }
    .interactive-tool-box h4 {
      font-size: 19px;
      font-weight: 800;
      color: var(--primary-pink);
      margin-bottom: 6px;
    }
    .interactive-tool-box p {
      font-size: 14px;
      color: #666;
      margin-bottom: 16px;
    }
    .tool-action-btn {
      background: var(--primary-pink);
      color: #ffffff;
      padding: 11px 26px;
      border-radius: 50px;
      font-weight: 800;
      font-size: 14.5px;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      box-shadow: 0 4px 14px rgba(228, 37, 88, 0.3);
      transition: all 0.2s ease;
    }
    .tool-action-btn:hover {
      background: var(--primary-hover);
      transform: translateY(-2px);
    }

    .resources-collapsible {
      margin: 30px 0 10px;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      overflow: hidden;
    }
    .resources-btn {
      width: 100%;
      background: #f8fafc;
      border: none;
      padding: 14px 20px;
      text-align: right;
      font-size: 15px;
      font-weight: 700;
      color: var(--accent-teal);
      cursor: pointer;
      display: flex;
      justify-content: space-between;
      align-items: center;
      transition: background 0.2s ease;
    }
    .resources-btn:hover {
      background: #f1f5f9;
    }
    .resources-body {
      display: none;
      padding: 16px 20px;
      background: #ffffff;
      border-top: 1px solid #e2e8f0;
      font-size: 13.5px;
      color: #64748b;
      line-height: 1.8;
    }

    .faq-block {
      background: #fcfcfc;
      border: 1px solid #ebebeb;
      border-radius: 12px;
      padding: 16px 18px;
      margin-bottom: 12px;
    }
    .faq-q {
      font-weight: 800;
      color: var(--text-title);
      margin-bottom: 6px;
      font-size: 15px;
    }
    .faq-a {
      color: #555;
      font-size: 14px;
      margin: 0;
    }

    /* Sidebar: Related Articles */
    .modal-sidebar {
      border-right: 1px solid #eee;
      padding-right: 20px;
    }
    @media (max-width: 860px) {
      .modal-sidebar {
        border-right: none;
        border-top: 1px solid #eee;
        padding-right: 0;
        padding-top: 24px;
      }
    }
    .sidebar-title {
      font-size: 18px;
      font-weight: 800;
      color: var(--text-title);
      padding-bottom: 10px;
      border-bottom: 2px solid var(--primary-pink);
      margin-bottom: 20px;
      display: inline-block;
    }
    .related-cards-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .horizontl-card {
      display: flex;
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: 12px;
      overflow: hidden;
      cursor: pointer;
      transition: all 0.2s ease;
      height: 100px;
    }
    .horizontl-card:hover {
      box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
      border-color: var(--primary-pink);
      transform: translateY(-2px);
    }
    .horizontl-thumb-wrap {
      width: 95px;
      flex-shrink: 0;
      background: #eee;
    }
    .horizontl-thumb {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .horizontl-content {
      padding: 8px 12px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      flex: 1;
    }
    .horizontl-cat {
      font-size: 11px;
      color: var(--accent-teal);
      font-weight: 700;
    }
    .horizontl-title {
      font-size: 13px;
      font-weight: 700;
      color: #222;
      line-height: 1.35;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }
    .horizontl-meta {
      font-size: 11px;
      color: var(--text-light);
      display: flex;
      align-items: center;
      gap: 8px;
    }

    /* Footer */
    .site-footer {
      background-color: #181519;
      color: #ffffff;
      padding: 50px 20px 24px;
      margin-top: 60px;
      border-top: 3px solid var(--primary-pink);
    }
    .footer-container {
      max-width: 1280px;
      margin: 0 auto;
      display: grid;
      grid-template-columns: 2fr 1fr 1fr 1fr;
      gap: 36px;
      margin-bottom: 40px;
    }
    @media (max-width: 900px) {
      .footer-container {
        grid-template-columns: 1fr 1fr;
        gap: 28px;
      }
    }
    @media (max-width: 600px) {
      .footer-container {
        grid-template-columns: 1fr;
      }
    }
    .footer-col h4 {
      font-size: 17px;
      font-weight: 800;
      color: #ffffff;
      margin-bottom: 18px;
      position: relative;
      padding-bottom: 8px;
    }
    .footer-col h4::after {
      content: "";
      position: absolute;
      bottom: 0;
      right: 0;
      width: 30px;
      height: 2px;
      background: var(--primary-pink);
    }
    .footer-col p {
      font-size: 13.5px;
      color: #a09ba3;
      line-height: 1.8;
      margin-bottom: 16px;
    }
    .footer-links {
      list-style: none;
      padding: 0;
    }
    .footer-links li {
      margin-bottom: 10px;
    }
    .footer-links a {
      font-size: 13.5px;
      color: #c4bfc8;
      transition: color 0.2s ease;
      display: inline-block;
    }
    .footer-links a:hover {
      color: var(--soft-pink);
      padding-right: 4px;
    }
    .footer-copyright-bar {
      max-width: 1280px;
      margin: 0 auto;
      padding-top: 24px;
      border-top: 1px solid rgba(255, 255, 255, 0.1);
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
      font-size: 12.5px;
      color: #88828c;
    }
    .footer-disclaimer {
      font-size: 12px;
      color: #7a747e;
      margin-top: 8px;
      line-height: 1.6;
    }

    .toast-notice {
      position: fixed;
      bottom: 30px;
      left: 50%;
      transform: translateX(-50%) translateY(100px);
      background: #111;
      color: #fff;
      padding: 12px 24px;
      border-radius: 50px;
      font-size: 14px;
      font-weight: 700;
      box-shadow: 0 10px 25px rgba(0,0,0,0.3);
      z-index: 3000;
      opacity: 0;
      transition: all 0.3s cubic-bezier(0.165, 0.84, 0.44, 1);
    }
    .toast-notice.show {
      transform: translateX(-50%) translateY(0);
      opacity: 1;
    }
  </style>
</head>
<body>

  <!-- Top App Promo Bar -->
  <div class="top-banner">
    <div class="top-banner-title">
      <span class="pulse"></span>
      <span>موسوعة نبضة الطبية والمصورة — أكثر من 2,500 مقال ودليل علمي موثق لصحة وسعادة المرأة</span>
    </div>
    <div class="top-banner-badges">
      <a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank" class="store-badge-btn">
        <span>🤖</span> Google Play
      </a>
      <a href="https://apps.apple.com/app/nabda" target="_blank" class="store-badge-btn">
        <span>🍏</span> App Store
      </a>
    </div>
  </div>

  <!-- Main Navigation Bar -->
  <header class="main-nav-wrapper">
    <div class="nav-container">
      <a href="landing.html" class="brand-logo-area">
        <img src="favicon.png" alt="نبضة" class="brand-logo-img" onerror="this.src='landing-assets/slide-pregnancy.png'">
        <div class="brand-names">
          <span class="brand-name-main">نبضة</span>
          <span class="brand-slogan">صحة المرأة والطفل</span>
        </div>
      </a>

      <!-- Search Box in Nav -->
      <form class="nav-search-form" onsubmit="event.preventDefault(); triggerSearch();">
        <div class="nav-search-box">
          <input type="search" id="searchInput" class="nav-search-input" placeholder="ابحثي في 2,500+ مقال، عَرَض، أو استفسار طبي..." aria-label="بحث">
          <button type="button" class="nav-search-btn" onclick="triggerSearch()">
            <span>🔍</span> بحث
          </button>
        </div>
      </form>

      <!-- App Download CTA -->
      <a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank" class="nav-app-btn">
        <span>📲</span> حملي التطبيق مجاناً
      </a>
    </div>
  </header>

  <!-- Horizontal Category Menu -->
  <nav class="categories-menu-row">
    <div class="categories-menu-container">
      <div class="cat-menu-item active" data-cat="all" onclick="selectCategory('all', this)">
        <span>الكل</span>
        <span class="cat-menu-badge" id="badge-all">2,500</span>
      </div>
      <div class="cat-menu-item" data-cat="pregnancy" onclick="selectCategory('pregnancy', this)">
        <span>🤰 الحمل والولادة</span>
        <span class="cat-menu-badge">1,126</span>
      </div>
      <div class="cat-menu-item" data-cat="beauty" onclick="selectCategory('beauty', this)">
        <span>💄 جمالي وعنايتي</span>
        <span class="cat-menu-badge">762</span>
      </div>
      <div class="cat-menu-item" data-cat="marriage" onclick="selectCategory('marriage', this)">
        <span>💍 زوجيات وسكينة</span>
        <span class="cat-menu-badge">312</span>
      </div>
      <div class="cat-menu-item" data-cat="fertility" onclick="selectCategory('fertility', this)">
        <span>🌸 التبويض والحمل</span>
        <span class="cat-menu-badge">176</span>
      </div>
      <div class="cat-menu-item" data-cat="health" onclick="selectCategory('health', this)">
        <span>🥗 صحة ورشاقة</span>
        <span class="cat-menu-badge">115</span>
      </div>
      <div class="cat-menu-item" data-cat="baby" onclick="selectCategory('baby', this)">
        <span>👶 رعاية الرضيع</span>
        <span class="cat-menu-badge">9</span>
      </div>
    </div>
  </nav>

  <!-- Main Content Area -->
  <main class="content-wrapper">
    <!-- Breadcrumb -->
    <div class="breadcrumb-row">
      <a href="landing.html">الرئيسية</a>
      <span class="sep">&gt;</span>
      <a href="articles.html">موسوعة المقالات</a>
      <span class="sep">&gt;</span>
      <span id="breadcrumbCurrent" class="breadcrumb-current">جميع المقالات الطبية</span>
    </div>

    <!-- Section Title & Results Count Header -->
    <div class="section-title-bar">
      <div>
        <h1 class="section-title-main" id="sectionHeaderTitle">أحدث المقالات والأدلة الموثقة</h1>
      </div>
      <div class="section-stats-pill" id="resultsCountPill">
        عرض 2,500 مقال متاح
      </div>
    </div>

    <!-- Articles Grid -->
    <div id="articlesGrid" class="articles-grid"></div>

    <!-- Pagination -->
    <div id="paginationBar" class="pagination-wrapper"></div>
  </main>

  <!-- Article Reading Modal -->
  <div id="articleModal" class="article-modal-backdrop" onclick="handleModalBackdropClick(event)">
    <div class="article-modal-container">
      <button class="modal-close-btn" onclick="closeArticleModal()" aria-label="إغلاق">×</button>
      <div id="modalArticleInner"></div>
    </div>
  </div>

  <!-- Toast Notification -->
  <div id="toastNotice" class="toast-notice">تم نسخ رابط المقال بنجاح! 📋</div>

  <!-- Footer -->
  <footer class="site-footer">
    <div class="footer-container">
      <div class="footer-col">
        <h4>عن موسوعة نبضة</h4>
        <p>تطبيق وموسوعة نبضة هي المرجع العربي الأول لصحة المرأة، متابعة الحمل أسبوعاً بأسبوع، أدلة التبويض والخصوبة، والعناية المتكاملة بالجمال ورعاية الطفل الرضيع بمحتوى طبي موثوق.</p>
        <p style="color: #FF6090; font-weight: 700;">دقة علمية · خصوصية تامة · تجربة نسائية فريدة</p>
      </div>

      <div class="footer-col">
        <h4>الموضوعات الطبية</h4>
        <ul class="footer-links">
          <li><a href="javascript:void(0)" onclick="selectCategory('pregnancy')">الحمل والولادة ومراحله</a></li>
          <li><a href="javascript:void(0)" onclick="selectCategory('fertility')">التبويض والتخطيط للحمل</a></li>
          <li><a href="javascript:void(0)" onclick="selectCategory('beauty')">العناية بالبشرة والجمال</a></li>
          <li><a href="javascript:void(0)" onclick="selectCategory('health')">الصحة الجسدية والرشاقة</a></li>
          <li><a href="javascript:void(0)" onclick="selectCategory('marriage')">العلاقة الزوجية والسكينة</a></li>
        </ul>
      </div>

      <div class="footer-col">
        <h4>أدوات نبضة الذكية</h4>
        <ul class="footer-links">
          <li><a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank">حاسبة موعد الولادة المتوقع</a></li>
          <li><a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank">حاسبة أيام التبويض الدقيقة</a></li>
          <li><a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank">متتبع ركلات وحركة الجنين</a></li>
          <li><a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank">سجل نمو ووزن الرضيع</a></li>
        </ul>
      </div>

      <div class="footer-col">
        <h4>تحميل التطبيق</h4>
        <p>حمّلي تطبيق نبضة واستمتعي بتجربة تفاعلية متكاملة على هاتفك الذكي:</p>
        <a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank" class="store-badge-btn" style="margin-bottom: 10px; display: inline-flex;">
          <span>🤖</span> Google Play Store
        </a>
        <br>
        <a href="https://apps.apple.com/app/nabda" target="_blank" class="store-badge-btn" style="display: inline-flex;">
          <span>🍏</span> Apple App Store
        </a>
      </div>
    </div>

    <div class="footer-copyright-bar">
      <div>© 2026 تطبيق وموسوعة نبضة — جميع الحقوق محفوظة لشركة نبضة لتكنولوجيا الرعاية الصحية.</div>
      <div class="footer-disclaimer">
        تنبيه طبي: المعلومات والمقالات الطبية الواردة في هذه الموسوعة هي لأغراض التوعية والإرشاد العام فقط، ولا تغني بأي حال عن الفحص الطبي المباشر واستشارة الطبيب المعالج أو المتخصص.
      </div>
    </div>
  </footer>

  <script>
    const allArticles = __ARTICLES_JSON__;
    let currentCategory = 'all';
    let searchQuery = '';
    let currentPage = 1;
    const pageSize = 15; // 3 columns x 5 rows = 15 articles per page
    let filteredArticles = [];

    const categoryMeta = {
      all: { name: 'جميع المقالات الطبية', title: 'أحدث المقالات والأدلة الموثقة', icon: '🌟' },
      pregnancy: { name: 'الحمل والولادة', title: 'تصنيف — الحمل والولادة ومراحله', icon: '🤰' },
      beauty: { name: 'جمالي وعنايتي', title: 'تصنيف — أسرار الجمال والعناية بالبشرة والشعر', icon: '💄' },
      marriage: { name: 'العلاقة الزوجية والسكينة', title: 'تصنيف — السكينة والمودة الزوجية', icon: '💍' },
      fertility: { name: 'التبويض والتخطيط للحمل', title: 'تصنيف — الخصوبة وحساب أيام التبويض', icon: '🌸' },
      health: { name: 'صحة المرأة والرشاقة', title: 'تصنيف — الصحة الجسدية والرشاقة والتغذية', icon: '🥗' },
      baby: { name: 'رعاية وتطور الرضيع', title: 'تصنيف — صحة ونمو ورعاية الرضيع', icon: '👶' }
    };

    const fallbackImages = {
      pregnancy: 'images/smart_articles/photo_pregnant_belly.jpg',
      beauty: 'images/smart_articles/photo_skincare_serum.jpg',
      marriage: 'images/smart_articles/photo_couple_coffee.jpg',
      fertility: 'images/smart_articles/photo_ovulation_calendar.jpg',
      health: 'images/smart_articles/photo_healthy_diet.jpg',
      baby: 'images/smart_articles/photo_newborn_sleep.jpg',
      default: 'images/smart_articles/photo_pregnant_belly.jpg'
    };

    function getArticleImage(art) {
      if (art.photoTag && fallbackImages[art.photoTag]) {
        return fallbackImages[art.photoTag];
      }
      const rank = parseInt(art.rank || 1, 10);
      if (!isNaN(rank) && rank > 0) {
        const imgIndex = ((rank - 1) % 100) + 1;
        const padded = String(imgIndex).padStart(3, '0');
        return 'images/smart_articles/art_' + padded + '.jpg';
      }
      return fallbackImages[art.categoryId] || fallbackImages.default;
    }

    function formatNumber(num) {
      return Number(num).toLocaleString('ar-EG');
    }

    function selectCategory(cat, el) {
      currentCategory = cat;
      currentPage = 1;

      document.querySelectorAll('.cat-menu-item').forEach(item => item.classList.remove('active'));
      if (el) {
        el.classList.add('active');
      } else {
        const target = document.querySelector(`.cat-menu-item[data-cat="${cat}"]`);
        if (target) target.classList.add('active');
      }

      const meta = categoryMeta[cat] || categoryMeta.all;
      const bc = document.getElementById('breadcrumbCurrent');
      if (bc) bc.textContent = meta.name;

      const titleEl = document.getElementById('sectionHeaderTitle');
      if (titleEl) titleEl.textContent = meta.title;

      applyFilterAndRender();
      window.scrollTo({ top: 120, behavior: 'smooth' });
    }

    function triggerSearch() {
      const input = document.getElementById('searchInput');
      searchQuery = input ? input.value.trim() : '';
      currentPage = 1;
      applyFilterAndRender();
    }

    let searchDebounceTimer;
    document.getElementById('searchInput').addEventListener('input', (e) => {
      clearTimeout(searchDebounceTimer);
      searchDebounceTimer = setTimeout(() => {
        searchQuery = e.target.value.trim();
        currentPage = 1;
        applyFilterAndRender();
      }, 250);
    });

    function applyFilterAndRender() {
      const q = searchQuery.toLowerCase();
      filteredArticles = allArticles.filter(art => {
        const matchCat = (currentCategory === 'all') || (art.categoryId === currentCategory);
        if (!matchCat) return false;
        if (!q) return true;
        return (art.title && art.title.toLowerCase().includes(q)) ||
               (art.summary && art.summary.toLowerCase().includes(q)) ||
               (art.categoryName && art.categoryName.toLowerCase().includes(q)) ||
               (art.badge && art.badge.toLowerCase().includes(q));
      });

      const countPill = document.getElementById('resultsCountPill');
      if (countPill) {
        countPill.textContent = `عرض ${formatNumber(filteredArticles.length)} مقال متاح`;
      }

      renderArticlesGrid();
      renderPagination();
    }

    function renderArticlesGrid() {
      const grid = document.getElementById('articlesGrid');
      grid.innerHTML = '';

      if (filteredArticles.length === 0) {
        grid.innerHTML = `
          <div style="grid-column: 1/-1; text-align: center; padding: 70px 20px; background: #ffffff; border-radius: 20px; border: 1px solid var(--card-border);">
            <div style="font-size: 52px; margin-bottom: 14px;">🔍</div>
            <h3 style="font-size: 22px; font-weight: 800; color: var(--text-title); margin-bottom: 8px;">لم نجد نتائج مطابقة لبحثكِ</h3>
            <p style="color: var(--text-muted); font-size: 15px; max-width: 480px; margin: 0 auto 20px;">تأكدي من صحة الكلمات أو جربي تصفح تصنيف مختلف من القائمة العلوية</p>
            <button onclick="selectCategory('all'); document.getElementById('searchInput').value='';" style="background: var(--primary-pink); color: #fff; border: none; padding: 10px 24px; border-radius: 50px; font-weight: 700; cursor: pointer;">عرض جميع المقالات</button>
          </div>
        `;
        return;
      }

      const startIndex = (currentPage - 1) * pageSize;
      const endIndex = Math.min(startIndex + pageSize, filteredArticles.length);
      const pageArticles = filteredArticles.slice(startIndex, endIndex);

      pageArticles.forEach(art => {
        const card = document.createElement('div');
        card.className = 'nabda-card nb-art-card';
        card.onclick = () => openArticleModal(art.id);

        const imgSrc = getArticleImage(art);
        const fallbackImg = fallbackImages[art.categoryId] || fallbackImages.default;
        const viewsCount = art.originalViews || (1450 + (art.rank * 13) % 4200);

        card.innerHTML = `
          <div class="card-img-wrap">
            <img src="${imgSrc}" alt="${art.title}" class="card-img" onerror="this.onerror=null;this.src='${fallbackImg}'" loading="lazy">
            <span class="card-floating-cat">${art.iconEmoji || '🌸'} ${art.categoryName}</span>
          </div>
          <div class="card-content-area">
            <div>
              <div class="card-cat-label" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                <span style="color: var(--accent-teal); font-weight: 800; font-size: 13px;">${art.iconEmoji || '🌸'} ${art.categoryName}</span>
                <span style="background: var(--light-pink-bg); color: var(--primary-pink); padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700;">${art.badge || 'موثق طبياً 🩺'}</span>
              </div>
              <h3 class="card-title">${art.title}</h3>
              <p class="card-snippet">${art.summary}</p>
            </div>
            <div class="card-bottom-bar">
              <div class="card-views-badge">
                <span>👁️</span> <span>${formatNumber(viewsCount)}</span>
              </div>
              <span class="card-read-time">⏱️ ${art.readTime || '6 دقائق'}</span>
              <span class="card-read-btn">اقرأي المقال ←</span>
            </div>
          </div>
        `;
        grid.appendChild(card);
      });
    }

    function renderPagination() {
      const pagination = document.getElementById('paginationBar');
      pagination.innerHTML = '';

      const totalPages = Math.ceil(filteredArticles.length / pageSize);
      if (totalPages <= 1) return;

      const prevBtn = document.createElement('button');
      prevBtn.className = `page-btn ${currentPage === 1 ? 'disabled' : ''}`;
      prevBtn.innerHTML = 'السابق';
      prevBtn.onclick = () => { if (currentPage > 1) goToPage(currentPage - 1); };
      pagination.appendChild(prevBtn);

      const pageNumbers = [];
      const delta = 2;

      for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || (i >= currentPage - delta && i <= currentPage + delta)) {
          pageNumbers.push(i);
        } else if (pageNumbers[pageNumbers.length - 1] !== '...') {
          pageNumbers.push('...');
        }
      }

      pageNumbers.forEach(item => {
        if (item === '...') {
          const ellipsis = document.createElement('span');
          ellipsis.className = 'page-ellipsis';
          ellipsis.textContent = '…';
          pagination.appendChild(ellipsis);
        } else {
          const numBtn = document.createElement('button');
          numBtn.className = `page-btn ${item === currentPage ? 'active' : ''}`;
          numBtn.textContent = formatNumber(item);
          numBtn.onclick = () => goToPage(item);
          pagination.appendChild(numBtn);
        }
      });

      const nextBtn = document.createElement('button');
      nextBtn.className = `page-btn ${currentPage === totalPages ? 'disabled' : ''}`;
      nextBtn.innerHTML = 'التالي';
      nextBtn.onclick = () => { if (currentPage < totalPages) goToPage(currentPage + 1); };
      pagination.appendChild(nextBtn);
    }

    function goToPage(page) {
      currentPage = page;
      renderArticlesGrid();
      renderPagination();
      const contentElem = document.querySelector('.content-wrapper');
      if (contentElem) {
        contentElem.scrollIntoView({ behavior: 'smooth' });
      }
    }

    function openArticleModal(artId) {
      const art = allArticles.find(a => a.id === artId);
      if (!art) return;

      const modal = document.getElementById('articleModal');
      const inner = document.getElementById('modalArticleInner');

      const imgSrc = getArticleImage(art);
      const fallbackImg = fallbackImages[art.categoryId] || fallbackImages.default;
      const viewsCount = art.originalViews || (1850 + (art.rank * 17) % 3600);

      let sectionsHtml = '';
      if (art.sections && art.sections.length > 0) {
        art.sections.forEach(s => {
          let bulletsHtml = '';
          if (s.bulletPoints && s.bulletPoints.length > 0) {
            bulletsHtml = '<ul class="nabda-points-list">' +
              s.bulletPoints.map(b => `<li><span class="dot">●</span> <span>${b}</span></li>`).join('') +
              '</ul>';
          }
          let tipHtml = s.calloutTip ? `<div class="medical-tip-callout">💡 <strong>نصيحة ذهبية:</strong> ${s.calloutTip}</div>` : '';
          let warningHtml = s.calloutWarning ? `<div class="medical-warn-callout">⚠️ <strong>تنبيه طبي هام:</strong> ${s.calloutWarning}</div>` : '';

          const formattedParagraphs = s.content
            .split('\\n\\n')
            .filter(p => p.trim())
            .map(p => {
              if (p.startsWith('## ')) {
                return `<h3 class="article-section-h3">${p.replace('## ', '')}</h3>`;
              }
              return `<p class="article-text-p">${p}</p>`;
            })
            .join('');

          sectionsHtml += `
            <div style="margin-bottom: 26px;">
              <h2 class="article-section-h2">
                <span>❖</span> ${s.title}
              </h2>
              ${formattedParagraphs}
              ${bulletsHtml}
              ${tipHtml}
              ${warningHtml}
            </div>
          `;
        });
      }

      let faqsHtml = '';
      if (art.faqs && art.faqs.length > 0) {
        faqsHtml = `
          <div style="margin-top: 36px; padding-top: 20px; border-top: 1.5px dashed #e2e8f0;">
            <h3 class="article-section-h2"><span>❓</span> الأسئلة الأكثر شيوعاً وإجابات الأطباء</h3>
        `;
        art.faqs.forEach(f => {
          faqsHtml += `
            <div class="faq-block">
              <div class="faq-q">س: ${f.question}</div>
              <p class="faq-a">ج: ${f.answer}</p>
            </div>
          `;
        });
        faqsHtml += `</div>`;
      }

      let toolBannerHtml = '';
      if (art.toolTitle) {
        toolBannerHtml = `
          <div class="interactive-tool-box">
            <h4>⚡ ${art.toolTitle}</h4>
            <p>${art.toolSubtitle || 'أداة طبية ذكية مخصصة لمتابعتكِ اليومية خطوة بخطوة بدقة عالية'}</p>
            <a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank" class="tool-action-btn">
              <span>📱</span> افتحي الأداة مجاناً في تطبيق نبضة
            </a>
          </div>
        `;
      }

      const related = allArticles
        .filter(a => a.id !== art.id && a.categoryId === art.categoryId)
        .slice(0, 4);

      let relatedHtml = '';
      related.forEach(rel => {
        const relImg = getArticleImage(rel);
        const relViews = rel.originalViews || (1100 + (rel.rank * 19) % 3100);
        relatedHtml += `
          <div class="horizontl-card" onclick="openArticleModal('${rel.id}')">
            <div class="horizontl-thumb-wrap">
              <img src="${relImg}" alt="${rel.title}" class="horizontl-thumb" onerror="this.onerror=null;this.src='${fallbackImg}'" loading="lazy">
            </div>
            <div class="horizontl-content">
              <span class="horizontl-cat">${rel.categoryName}</span>
              <h4 class="horizontl-title">${rel.title}</h4>
              <div class="horizontl-meta">
                <span>👁️ ${formatNumber(relViews)}</span>
                <span>⏱️ ${rel.readTime}</span>
              </div>
            </div>
          </div>
        `;
      });

      inner.innerHTML = `
        <div class="modal-article-header">
          <div class="modal-breadcrumb">
            <span onclick="closeArticleModal()" style="cursor:pointer;">الرئيسية</span>
            <span>&gt;</span>
            <span onclick="selectCategory('${art.categoryId}'); closeArticleModal();" style="cursor:pointer;">${art.categoryName}</span>
            <span>&gt;</span>
            <span style="color: #666; font-weight: 500;">عرض المقال</span>
          </div>
          <h1 class="modal-article-title">${art.title}</h1>
          <div class="modal-author-bar">
            <div class="author-info-box">
              <img src="images/smart_articles/photo_womens_clinic.jpg" alt="طبيبة نبضة" class="author-avatar" onerror="this.src='favicon.png'">
              <div class="author-details">
                <span class="author-name">${art.author || 'فريق التحرير الطبي — نبضة'} <span class="author-verified">✓</span></span>
                <span class="publish-date">مراجعة وتدقيق طبي معتمد · ⏱️ ${art.readTime} · 👁️ ${formatNumber(viewsCount)} قراءة</span>
              </div>
            </div>
            <div class="social-share-row">
              <button class="share-icon-btn" onclick="copyArticleLink('${art.title.replace(/'/g, "\\\\'")}')" title="نسخ رابط المقال">🔗</button>
              <button class="share-icon-btn" onclick="shareWhatsApp('${art.title.replace(/'/g, "\\\\'")}')" title="مشاركة على واتساب">💬</button>
              <button class="share-icon-btn" onclick="shareTwitter('${art.title.replace(/'/g, "\\\\'")}')" title="مشاركة على إكس / تويتر">𝕏</button>
            </div>
          </div>
        </div>

        <div class="modal-body-layout">
          <div class="modal-main-content">
            <img src="${imgSrc}" alt="${art.title}" class="modal-featured-img" onerror="this.onerror=null;this.src='${fallbackImg}'">
            <div class="article-lead-box">
              <strong style="color: var(--primary-pink); display: block; margin-bottom: 6px;">خلاصة الدليل والمعلومات الأساسية:</strong>
              ${art.summary}
            </div>

            ${sectionsHtml}
            ${toolBannerHtml}
            ${faqsHtml}

            <div class="resources-collapsible">
              <button class="resources-btn" onclick="toggleResources()">
                <span>📚 المراجع والمصادر الطبية المعتمدة</span>
                <span id="resourcesArrow">▼</span>
              </button>
              <div class="resources-body" id="resourcesBody">
                <p>تم إعداد هذا المحتوى وتدقيقه وفقاً لأحدث البروتوكولات الإكلينيكية الصادرة عن:</p>
                <ul style="padding-right: 22px; margin-top: 8px;">
                  <li>الكلية الأمريكية لأطباء النساء والتوليد (ACOG Guidelines)</li>
                  <li>المعهد الوطني للصحة والرعاية المتميزة (NICE UK)</li>
                  <li>منظمة الصحة العالمية (WHO — Maternal & Child Health)</li>
                  <li>قاعدة بيانات المكتبة الوطنية الأمريكية للطب (PubMed / NIH)</li>
                  <li>الجمعية الملكية لأطباء النساء والتوليد (RCOG)</li>
                </ul>
              </div>
            </div>
          </div>

          <div class="modal-sidebar">
            <h3 class="sidebar-title">مقالات ذات صلة</h3>
            <div class="related-cards-list">
              ${relatedHtml}
            </div>
          </div>
        </div>
      `;

      modal.style.display = 'block';
      document.body.style.overflow = 'hidden';
      history.replaceState(null, '', `?id=${art.id}`);
    }

    function closeArticleModal() {
      const modal = document.getElementById('articleModal');
      if (modal) modal.style.display = 'none';
      document.body.style.overflow = 'auto';
      history.replaceState(null, '', window.location.pathname);
    }

    function handleModalBackdropClick(e) {
      if (e.target.id === 'articleModal') {
        closeArticleModal();
      }
    }

    function toggleResources() {
      const body = document.getElementById('resourcesBody');
      const arrow = document.getElementById('resourcesArrow');
      if (!body) return;
      if (body.style.display === 'block') {
        body.style.display = 'none';
        if (arrow) arrow.textContent = '▼';
      } else {
        body.style.display = 'block';
        if (arrow) arrow.textContent = '▲';
      }
    }

    function showToast(msg) {
      const toast = document.getElementById('toastNotice');
      if (!toast) return;
      toast.textContent = msg;
      toast.classList.add('show');
      setTimeout(() => { toast.classList.remove('show'); }, 2600);
    }

    function copyArticleLink(title) {
      const url = window.location.href;
      navigator.clipboard.writeText(url).then(() => {
        showToast('تم نسخ رابط المقال بنجاح! 📋');
      }).catch(() => {
        showToast('تم نسخ الرابط! 📋');
      });
    }

    function shareWhatsApp(title) {
      const url = encodeURIComponent(window.location.href);
      const text = encodeURIComponent(title + '\\n' + window.location.href);
      window.open('https://api.whatsapp.com/send?text=' + text, '_blank');
    }

    function shareTwitter(title) {
      const url = encodeURIComponent(window.location.href);
      const text = encodeURIComponent(title);
      window.open('https://twitter.com/intent/tweet?text=' + text + '&url=' + url, '_blank');
    }

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') closeArticleModal();
    });

    window.addEventListener('DOMContentLoaded', () => {
      applyFilterAndRender();
      const urlParams = new URLSearchParams(window.location.search);
      const queryId = urlParams.get('id');
      const hashId = window.location.hash ? window.location.hash.substring(1) : null;
      const targetId = queryId || hashId;
      if (targetId) {
        setTimeout(() => { openArticleModal(targetId); }, 200);
      }
    });
  </script>
</body>
</html>
"""

# Replace placeholder with actual articles JSON string
final_html = html_template.replace('__ARTICLES_JSON__', articles_json_str)

web_articles_path = r'C:\nabda_app\web\articles.html'
print(f"Writing complete web portal to: {web_articles_path}")
with open(web_articles_path, 'w', encoding='utf-8') as f:
    f.write(final_html)

# Ensure web images folder exists and images are synchronized
web_img_dir = r'C:\nabda_app\web\images\smart_articles'
os.makedirs(web_img_dir, exist_ok=True)
src_dir = r'C:\nabda_app\assets\images\smart_articles'
if os.path.exists(src_dir):
    for item in os.listdir(src_dir):
        s = os.path.join(src_dir, item)
        d = os.path.join(web_img_dir, item)
        if os.path.isfile(s) and not os.path.exists(d):
            shutil.copy2(s, d)

print(f"SUCCESS: Generated complete Nabda-styled articles portal ({articles_count} articles) at {web_articles_path}")
