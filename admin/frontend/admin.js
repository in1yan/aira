// Aira Smart Flashcards Web Admin Portal JavaScript

const DOMAIN_BADGE_MAP = {
  phonology: { label: 'Phonology (Form)', bg: '#E0F2FE', color: '#0284C7' },
  morphology: { label: 'Morphology (Form)', bg: '#DCFCE7', color: '#16A34A' },
  syntax: { label: 'Syntax (Form)', bg: '#F3E8FF', color: '#9333EA' },
  semantic: { label: 'Semantic (Content)', bg: '#FDF4FF', color: '#C026D3' },
  pragmatic: { label: 'Pragmatic (Use)', bg: '#FFEDD5', color: '#EA580C' },
};

const CATEGORY_ICON_MAP = {
  pets: 'fa-paw',
  eco: 'fa-seedling',
  directions_car: 'fa-car',
  school: 'fa-graduation-cap',
  sports_soccer: 'fa-futbol',
  palette: 'fa-palette',
  music_note: 'fa-music',
  restaurant: 'fa-utensils',
  record_voice_over: 'fa-microphone-lines',
  hearing: 'fa-ear-listen',
  graphic_eq: 'fa-waveform-lines',
  volume_up: 'fa-volume-high',
  merge_type: 'fa-code-branch',
  update: 'fa-clock-rotate-left',
  transform: 'fa-shuffle',
  people: 'fa-users',
  menu_book: 'fa-book-open',
  quiz: 'fa-circle-question',
  alt_route: 'fa-route',
  place: 'fa-location-dot',
  sports_esports: 'fa-gamepad',
  forum: 'fa-comments',
  handshake: 'fa-handshake',
  sentiment_satisfied_alt: 'fa-face-smile',
  flutter_dash: 'fa-dove',
  fastfood: 'fa-burger',
  weekend: 'fa-couch',
  checkroom: 'fa-shirt',
  work: 'fa-briefcase',
  water: 'fa-water',
  bug_report: 'fa-bug',
  soup_kitchen: 'fa-bowl-rice',
  category: 'fa-shapes',
  wb_sunny: 'fa-sun',
  celebration: 'fa-champagne-glasses',
  auto_awesome: 'fa-wand-magic-sparkles',
  movie: 'fa-film',
  toys: 'fa-robot',
  public: 'fa-earth-americas',
};

let state = {
  stats: {},
  categories: [],
  cards: [],
  semanticCards: null,
  users: [],
  activeTab: 'overview',
  activeMatrixLang: 'en',
  activeModalLang: 'en',
  selectedCategoryDomain: 'all',
  selectedCardDomain: '',
  currentFolderId: null,
  categoryViewMode: 'explorer',
  cardPage: 1,
  cardPageSize: 24,
  loadedTabs: {
    overview: false,
    cards: false,
    categories: false,
    concepts: false,
    users: false,
    scanner: true,
  },
};

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  initColorPickers();
  setupDropzone();

  // Load lightweight stats once on initial boot, then load ONLY the active tab's data
  fetchStats().then(() => {
    const initialTab = state.activeTab || 'overview';
    loadTabContent(initialTab);
  });
});

function initColorPickers() {
  const colorInput = document.getElementById('catFormColor');
  const hexDisplay = document.getElementById('colorHexDisplay');
  if (colorInput && hexDisplay) {
    colorInput.addEventListener('input', (e) => {
      hexDisplay.textContent = e.target.value.toUpperCase();
    });
  }
}

// NAVIGATION & TAB SWITCHING (ON-DEMAND DATA LOADING)
function initNavigation() {
  const navItems = document.querySelectorAll('.sidebar-nav .nav-item[data-tab]');
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const tab = item.getAttribute('data-tab');
      switchTab(tab);
    });
  });

  window.addEventListener('hashchange', () => {
    const hash = window.location.hash.replace('#', '');
    if (hash && document.getElementById(`tab-${hash}`)) {
      switchTab(hash);
    }
  });

  const initialHash = window.location.hash.replace('#', '');
  if (initialHash && document.getElementById(`tab-${initialHash}`)) {
    switchTab(initialHash);
  }
}

function switchTab(tabId) {
  state.activeTab = tabId;
  window.location.hash = tabId;

  // Update nav active states
  document.querySelectorAll('.sidebar-nav .nav-item[data-tab]').forEach(el => {
    el.classList.toggle('active', el.getAttribute('data-tab') === tabId);
  });

  // Update tab panes
  document.querySelectorAll('.tab-pane').forEach(el => {
    el.classList.toggle('active', el.id === `tab-${tabId}`);
  });

  // Update Page Title
  const titles = {
    overview: { title: 'Dashboard Overview', subtitle: 'Real-time statistics and flashcard management system' },
    cards: { title: 'Flashcards Directory', subtitle: 'View, create, search and edit all learning flashcards' },
    categories: { title: 'Folder & Category Explorer', subtitle: 'Organize flashcards into hierarchical folders and subcategories' },
    concepts: { title: '6 Cognitive Dimensions Matrix', subtitle: 'Audit Group, Use, Action, Location, Association & Properties' },
    users: { title: 'User Management', subtitle: 'Manage student, teacher, and administrator accounts' },
    scanner: { title: 'AI Card Scanner Test', subtitle: 'Simulate mobile camera vision recognition' },
  };

  if (titles[tabId]) {
    document.getElementById('pageTitle').textContent = titles[tabId].title;
    document.getElementById('pageSubtitle').textContent = titles[tabId].subtitle;
  }

  // ON-DEMAND DATA LOADING: Only load data for the active page
  loadTabContent(tabId);
}

// ON-DEMAND DATA LOADERS PER TAB
async function loadTabContent(tabId, force = false) {
  if (!tabId) tabId = state.activeTab || 'overview';

  try {
    switch (tabId) {
      case 'overview':
        if (!state.loadedTabs.overview || force) {
          await fetchStats();
        }
        break;

      case 'categories':
        if (!state.loadedTabs.categories || force) {
          await fetchCategories(true);
        }
        break;

      case 'cards':
        if (!state.loadedTabs.cards || force) {
          if (state.categories.length === 0) {
            await fetchCategories(false);
          }
          await fetchCards();
        }
        break;

      case 'concepts':
        if (!state.loadedTabs.concepts || force) {
          await fetchConceptsCards();
        }
        break;

      case 'users':
        if (!state.loadedTabs.users || force) {
          await fetchUsers();
        }
        break;
    }
  } catch (err) {
    showToast(`Error loading ${tabId}: ` + err.message, 'error');
  }
}

async function fetchStats() {
  try {
    const statsRes = await fetch('/api/admin/stats').then(r => r.json()).catch(() => null);
    if (statsRes) {
      state.stats = statsRes;
      renderKPIs();
      renderDistribution();
      const badgeCards = document.getElementById('cardCountBadge');
      const badgeCats = document.getElementById('catCountBadge');
      if (badgeCards) badgeCards.textContent = state.stats.total_cards || 0;
      if (badgeCats) badgeCats.textContent = state.stats.total_categories || 0;
    }
    state.loadedTabs.overview = true;
  } catch (e) {
    console.error('Failed to fetch stats:', e);
  }
}

async function fetchCategories(render = true) {
  const container = document.getElementById('categoriesContainer');
  if (render && container && state.categories.length === 0) {
    container.innerHTML = '<div style="grid-column: 1/-1; text-align:center; padding: 48px;"><i class="fa-solid fa-spinner fa-spin" style="font-size:28px; color:var(--primary);"></i><p style="margin-top:8px; color:var(--text-muted);">Loading folder hierarchy...</p></div>';
  }
  try {
    const cats = await fetch('/api/categories').then(r => r.json()).catch(() => []);
    state.categories = cats;
    populateCategoryDropdowns();
    if (render) {
      renderCategories();
    }
    state.loadedTabs.categories = true;
    const badgeCats = document.getElementById('catCountBadge');
    if (badgeCats) badgeCats.textContent = state.categories.length;
  } catch (e) {
    console.error('Failed to fetch categories:', e);
  }
}

async function fetchCards() {
  const container = document.getElementById('cardsContainer');
  if (container && state.cards.length === 0) {
    container.innerHTML = '<div style="grid-column: 1/-1; text-align:center; padding: 48px;"><i class="fa-solid fa-spinner fa-spin" style="font-size:28px; color:var(--primary);"></i><p style="margin-top:8px; color:var(--text-muted);">Loading flashcards...</p></div>';
  }
  try {
    const cards = await fetch('/api/cards').then(r => r.json()).catch(() => []);
    state.cards = cards;
    state.cardPage = 1;
    filterCards();
    state.loadedTabs.cards = true;
    const badgeCards = document.getElementById('cardCountBadge');
    if (badgeCards) badgeCards.textContent = state.cards.length;
  } catch (e) {
    console.error('Failed to fetch cards:', e);
  }
}

async function fetchConceptsCards() {
  const tbody = document.getElementById('conceptsMatrixBody');
  if (tbody) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:48px;"><i class="fa-solid fa-spinner fa-spin" style="font-size:24px; color:var(--primary);"></i><p style="margin-top:8px; color:var(--text-muted);">Loading cognitive dimensions matrix...</p></td></tr>';
  }
  try {
    if (state.cards.length > 0) {
      renderConceptsMatrix();
    } else {
      const cards = await fetch('/api/cards?domain=semantic').then(r => r.json()).catch(() => []);
      state.semanticCards = cards;
      renderConceptsMatrix();
    }
    state.loadedTabs.concepts = true;
  } catch (e) {
    console.error('Failed to fetch concepts matrix:', e);
  }
}

async function fetchUsers() {
  const tbody = document.getElementById('usersTableBody');
  if (tbody && state.users.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:32px;"><i class="fa-solid fa-spinner fa-spin" style="font-size:24px; color:var(--primary);"></i><p style="margin-top:8px; color:var(--text-muted);">Loading user directory...</p></td></tr>';
  }
  try {
    const users = await fetch('/api/admin/users').then(r => r.json()).catch(() => []);
    state.users = users;
    renderUsers();
    state.loadedTabs.users = true;
  } catch (e) {
    console.error('Failed to fetch users:', e);
  }
}

async function loadDashboardData() {
  try {
    showToast('Refreshing data...', 'info');
    await fetchStats();
    await loadTabContent(state.activeTab, true);
    showToast('Data refreshed successfully', 'success');
  } catch (err) {
    showToast('Failed to refresh data: ' + err.message, 'error');
  }
}

// RENDER KPIS
function renderKPIs() {
  const kpiCards = document.getElementById('kpiTotalCards');
  const kpiCats = document.getElementById('kpiTotalCats');
  const kpiUsers = document.getElementById('kpiTotalUsers');
  const kpiConcepts = document.getElementById('kpiTotalConcepts');

  if (kpiCards) kpiCards.textContent = state.stats.total_cards || 0;
  if (kpiCats) kpiCats.textContent = state.stats.total_categories || 0;
  if (kpiUsers) kpiUsers.textContent = state.stats.total_users || 0;
  if (kpiConcepts) kpiConcepts.textContent = state.stats.total_attributes || ((state.stats.total_cards || 0) * 6);
}

// RENDER DISTRIBUTION
function renderDistribution() {
  const container = document.getElementById('categoryDistributionList');
  if (!container) return;
  const dist = state.stats.category_distribution || [];

  if (dist.length === 0) {
    container.innerHTML = '<p class="text-muted" style="color:var(--text-muted);font-size:13px;">No category distribution data available yet.</p>';
    return;
  }

  const total = state.stats.total_cards || 1;
  container.innerHTML = dist.map(d => {
    const pct = Math.round((d.card_count / total) * 100);
    return `
      <div style="margin-bottom: 16px;">
        <div style="display: flex; justify-content: space-between; font-size: 13px; font-weight: 600; margin-bottom: 6px;">
          <span>${escapeHtml(d.category_name)}</span>
          <span style="color: var(--text-muted);">${d.card_count} cards (${pct}%)</span>
        </div>
        <div style="height: 8px; background: var(--bg-body); border-radius: 4px; overflow: hidden;">
          <div style="width: ${pct}%; height: 100%; background: var(--primary); border-radius: 4px;"></div>
        </div>
      </div>
    `;
  }).join('');
}

// RENDER CARDS
function renderCards() {
  filterCards();
}

function onCardSearchInput() {
  state.cardPage = 1;
  filterCards();
}

function onCardDomainFilterChanged() {
  const domain = document.getElementById('cardDomainFilterSelect')?.value || '';
  state.selectedCardDomain = domain;
  state.cardPage = 1;
  populateCategoryFilterDropdown(domain);
  filterCards();
}

function onCategoryFilterChanged() {
  state.cardPage = 1;
  filterCards();
}

function populateCategoryFilterDropdown(domain) {
  const filterSelect = document.getElementById('categoryFilterSelect');
  if (!filterSelect) return;
  const currentVal = filterSelect.value;

  let cats = state.categories;
  if (domain) {
    cats = cats.filter(c => (c.domain || 'semantic').toLowerCase() === domain.toLowerCase());
  }

  const options = cats.map(c => `<option value="${c.id}">${escapeHtml(c.name_en)} (${escapeHtml(c.name_ta || '')})</option>`).join('');
  filterSelect.innerHTML = '<option value="">All Categories' + (domain ? ` (${cats.length})` : '') + '</option>' + options;

  if (cats.some(c => c.id == currentVal)) {
    filterSelect.value = currentVal;
  } else {
    filterSelect.value = '';
  }
}

function onCardSearchInput() {
  state.cardPage = 1;
  filterCards();
}

function loadMoreCards() {
  state.cardPage++;
  filterCards();
}

function filterCards() {
  const query = (document.getElementById('cardSearchInput')?.value || '').toLowerCase();
  const selectedDomain = (document.getElementById('cardDomainFilterSelect')?.value || '').toLowerCase();
  const selectedCat = document.getElementById('categoryFilterSelect')?.value;
  const container = document.getElementById('cardsContainer');
  if (!container) return;

  const filtered = state.cards.filter(c => {
    const cat = state.categories.find(k => k.id === c.category_id);
    const cardDomain = (c.domain || cat?.domain || 'semantic').toLowerCase();

    if (selectedDomain && cardDomain !== selectedDomain) return false;
    if (selectedCat && c.category_id != selectedCat) return false;
    if (query) {
      const en = (c.title_en || '').toLowerCase();
      const ta = (c.title_ta || '').toLowerCase();
      const hi = (c.title_hi || '').toLowerCase();
      const ml = (c.title_ml || '').toLowerCase();
      return en.includes(query) || ta.includes(query) || hi.includes(query) || ml.includes(query);
    }
    return true;
  });

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="grid-column: 1 / -1; text-align: center; padding: 48px; color: var(--text-muted);">
        <i class="fa-solid fa-clone" style="font-size: 40px; margin-bottom: 12px; opacity: 0.5;"></i>
        <p>No flashcards match your search criteria.</p>
      </div>
    `;
    return;
  }

  // Pagination support: Render only the current slice of cards
  const maxVisible = (state.cardPage || 1) * (state.cardPageSize || 24);
  const visibleCards = filtered.slice(0, maxVisible);

  let html = visibleCards.map(renderCardHtml).join('');

  if (visibleCards.length < filtered.length) {
    const remaining = filtered.length - visibleCards.length;
    html += `
      <div id="loadMoreCardsContainer" style="grid-column: 1 / -1; text-align: center; padding: 24px 0;">
        <button class="btn btn-secondary" onclick="loadMoreCards()" style="padding: 10px 24px; font-weight: 600; border-radius: 8px;">
          <i class="fa-solid fa-chevron-down" style="margin-right: 8px;"></i>
          Load More Flashcards (${remaining} remaining)
        </button>
      </div>
    `;
  }

  container.innerHTML = html;
}

function renderCardHtml(c) {
  const cat = state.categories.find(k => k.id === c.category_id);
  const domKey = (c.domain || cat?.domain || 'semantic').toLowerCase();
  const domBadge = DOMAIN_BADGE_MAP[domKey] || { label: domKey, bg: '#F1F5F9', color: '#475569' };
  const attrs = c.attributes || {};
  const attrList = c.attributes_list || Object.values(attrs);
  const uploadedImagesCount = (c.image_url ? 1 : 0) + attrList.filter(a => a && (a.image_url || a.attribute_image)).length;
  const isSyntaxCard = domKey === 'syntax';
  const isSemanticCard = domKey === 'semantic';

  let displayTitle = c.title_en || c.name || '';
  if (isSyntaxCard && (!displayTitle || displayTitle === 'Untitled Card') && c.image_url) {
    displayTitle = c.image_url.split('/').pop().split('?')[0];
  }
  if (!displayTitle) displayTitle = 'Untitled Card';

  const subnames = [c.title_ta, c.title_hi, c.title_ml].filter(Boolean).join(' • ');
  const imageCountTag = isSemanticCard
    ? `${uploadedImagesCount}/7 Images Loaded`
    : `${c.image_url ? 1 : 0}/1 Image Loaded`;
  const editBtnTitle = isSemanticCard ? 'Edit Flashcard (7 Images)' : 'Edit Flashcard';
  const catBadgeLabel = cat ? cat.name_en : (isSyntaxCard ? 'No Category' : 'Root Deck');

  // Lightweight inline SVG placeholder avoids multi-megabyte external image downloads
  const placeholderSvg = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='300' height='200' viewBox='0 0 300 200'><rect width='300' height='200' fill='%23F1F5F9'/><text x='50%25' y='50%25' dominant-baseline='middle' text-anchor='middle' fill='%2394A3B8' font-family='sans-serif' font-size='14'>No Image</text></svg>";
  const cardImg = c.image_url || placeholderSvg;

  return `
    <div class="flashcard-item">
      <div class="card-img-wrap">
        <img src="${cardImg}" alt="${escapeHtml(displayTitle)}" loading="lazy" decoding="async" onerror="this.onerror=null;this.src='${placeholderSvg}'">
        <div style="position:absolute; top:8px; left:8px; display:flex; flex-direction:column; gap:4px; align-items:flex-start;">
          <span style="background:${domBadge.bg}; color:${domBadge.color}; font-size:10px; font-weight:700; padding:2px 7px; border-radius:10px; box-shadow:0 1px 3px rgba(0,0,0,0.15);">
            ${escapeHtml(domBadge.label)}
          </span>
          <span class="card-category-badge" style="position:static;">${escapeHtml(catBadgeLabel)}</span>
        </div>
      </div>
      <div class="card-content">
        <h4 class="card-title">${escapeHtml(displayTitle)}</h4>
        ${isSyntaxCard && c.image_url ? `<div style="font-size:11px; color:var(--text-muted); font-family:monospace; margin-bottom:4px; word-break:break-all;"><i class="fa-solid fa-file-image"></i> ${escapeHtml(c.image_url.split('/').pop().split('?')[0])}</div>` : ''}
        ${c.subcategory ? `<span class="card-subcategory-tag"><i class="fa-solid fa-layer-group"></i> ${escapeHtml(c.subcategory)}</span>` : ''}
        <p class="card-subtitles" style="margin-top:6px;">${escapeHtml(subnames || (isSyntaxCard ? 'Single Image Story' : 'Multi-lingual ready'))}</p>
        ${isSemanticCard ? `
        <div class="concept-count-tag" style="margin-top:8px;">
          <i class="fa-solid fa-images"></i>
          <span>${imageCountTag}</span>
        </div>` : ''}
      </div>
      <div class="card-actions-bar">
        <button class="btn-icon" title="${editBtnTitle}" onclick="openEditCardModal(${c.id})">
          <i class="fa-solid fa-pen-to-square"></i>
        </button>
        <button class="btn-icon delete" title="Delete Flashcard" onclick="deleteCard(${c.id}, '${escapeHtml(displayTitle)}')">
          <i class="fa-solid fa-trash"></i>
        </button>
      </div>
    </div>
  `;
}

// =====================================================================
// FOLDER HIERARCHY & EXPLORER ENGINE
// =====================================================================

function getCategoryDescendantIds(catId) {
  const descendants = new Set();
  const queue = [catId];
  while (queue.length > 0) {
    const currId = queue.shift();
    const children = state.categories.filter(c => c.parent_id === currId);
    children.forEach(ch => {
      if (!descendants.has(ch.id)) {
        descendants.add(ch.id);
        queue.push(ch.id);
      }
    });
  }
  return descendants;
}

function buildCategoryTreeOptionsHtml(domain = null, selectedId = null, excludeId = null) {
  let cats = state.categories;
  if (domain && domain !== 'all') {
    cats = cats.filter(c => (c.domain || 'semantic').toLowerCase() === domain.toLowerCase());
  }

  const excludedIds = excludeId ? getCategoryDescendantIds(excludeId) : new Set();
  if (excludeId) excludedIds.add(excludeId);

  const childrenMap = {};
  cats.forEach(c => {
    const pid = c.parent_id || 'root';
    if (!childrenMap[pid]) childrenMap[pid] = [];
    childrenMap[pid].push(c);
  });

  let optionsHtml = '';

  function traverse(parentId, depth) {
    const list = childrenMap[parentId] || [];
    list.sort((a, b) => a.name_en.localeCompare(b.name_en));

    for (const c of list) {
      if (excludedIds.has(c.id)) continue;
      const indent = '&nbsp;&nbsp;'.repeat(depth * 3);
      const prefix = depth > 0 ? '└─ ' : '';
      const isSelected = selectedId && Number(selectedId) === Number(c.id);
      optionsHtml += `<option value="${c.id}" ${isSelected ? 'selected' : ''}>${indent}${prefix}📁 ${escapeHtml(c.name_en)} (${escapeHtml(c.domain || 'semantic')})</option>`;
      traverse(c.id, depth + 1);
    }
  }

  traverse('root', 0);
  return optionsHtml;
}

function populateParentCategoryDropdown(domain, selectedParentId = null, excludeId = null) {
  const select = document.getElementById('catFormParentId');
  if (!select) return;

  const domClean = (domain || 'semantic').toLowerCase();
  const domLabel = DOMAIN_BADGE_MAP[domClean]?.label || domClean;
  const rootOption = `<option value="">📁 Root Level (Directly in ${escapeHtml(domLabel)})</option>`;
  const treeOptions = buildCategoryTreeOptionsHtml(domClean, selectedParentId, excludeId);

  select.innerHTML = rootOption + treeOptions;
  if (selectedParentId) {
    select.value = selectedParentId;
  } else {
    select.value = '';
  }
}

function onCatFormDomainChanged() {
  const domain = document.getElementById('catFormDomain')?.value || 'semantic';
  const currentParentVal = document.getElementById('catFormParentId')?.value;
  const excludeId = document.getElementById('catFormId')?.value ? Number(document.getElementById('catFormId').value) : null;
  populateParentCategoryDropdown(domain, currentParentVal, excludeId);
}

function setCategoryViewMode(mode) {
  state.categoryViewMode = mode;
  document.getElementById('btnViewExplorer')?.classList.toggle('active', mode === 'explorer');
  document.getElementById('btnViewFlat')?.classList.toggle('active', mode === 'flat');

  const explorerView = document.getElementById('explorerViewArea');
  const folderNavBar = document.getElementById('folderNavBar');
  const flatView = document.getElementById('flatGridViewArea');

  if (explorerView) explorerView.style.display = mode === 'explorer' ? 'block' : 'none';
  if (folderNavBar) folderNavBar.style.display = mode === 'explorer' ? 'flex' : 'none';
  if (flatView) flatView.style.display = mode === 'flat' ? 'block' : 'none';

  renderCategories();
}

function openFolder(folderId) {
  state.currentFolderId = folderId;
  const folder = state.categories.find(c => c.id === folderId);
  if (folder && folder.domain) {
    state.selectedCategoryDomain = folder.domain;
    document.querySelectorAll('.domain-filter-btn').forEach(btn => {
      btn.classList.toggle('active', btn.getAttribute('data-domain') === folder.domain);
    });
  }
  renderCategories();
}

function navigateUpFolder() {
  if (!state.currentFolderId) return;
  const curr = state.categories.find(c => c.id === state.currentFolderId);
  state.currentFolderId = curr?.parent_id || null;
  renderCategories();
}

function navigateToBreadcrumb(targetFolderId) {
  state.currentFolderId = targetFolderId;
  renderCategories();
}

function openNewCardInCurrentFolder() {
  openNewCardModal();
  if (state.currentFolderId) {
    const folder = state.categories.find(c => c.id === state.currentFolderId);
    if (folder) {
      if (document.getElementById('cardFormDomain')) {
        document.getElementById('cardFormDomain').value = folder.domain || 'semantic';
        onCardFormDomainChanged();
      }
      setTimeout(() => {
        const catSelect = document.getElementById('cardFormCategory');
        if (catSelect) catSelect.value = state.currentFolderId;
      }, 50);
    }
  }
}

// FILTER CATEGORIES BY DOMAIN
function filterCategoriesByDomain(domain) {
  state.selectedCategoryDomain = domain;
  state.currentFolderId = null; // Reset to root of chosen domain
  document.querySelectorAll('.domain-filter-btn').forEach(btn => {
    btn.classList.toggle('active', btn.getAttribute('data-domain') === domain);
  });
  renderCategories();
}

// RENDER CATEGORIES & FOLDER EXPLORER
function renderCategories() {
  const isExplorer = state.categoryViewMode === 'explorer';

  if (!isExplorer) {
    // FLAT GRID VIEW
    const flatContainer = document.getElementById('flatCategoriesContainer');
    if (!flatContainer) return;

    let cats = state.categories;
    if (state.selectedCategoryDomain && state.selectedCategoryDomain !== 'all') {
      cats = cats.filter(c => (c.domain || 'semantic').toLowerCase() === state.selectedCategoryDomain.toLowerCase());
    }

    if (cats.length === 0) {
      flatContainer.innerHTML = '<p class="text-muted" style="grid-column: 1/-1; text-align:center; padding: 32px;">No categories found for this domain.</p>';
      return;
    }

    flatContainer.innerHTML = cats.map(cat => renderCategoryFolderCardHtml(cat, false)).join('');
    return;
  }

  // EXPLORER VIEW
  const trailContainer = document.getElementById('folderBreadcrumbTrail');
  const subfoldersContainer = document.getElementById('categoriesContainer');
  const cardsContainer = document.getElementById('folderCardsContainer');
  const btnUp = document.getElementById('btnFolderUp');
  const subfolderBadge = document.getElementById('subfolderCountBadge');
  const cardsBadge = document.getElementById('folderCardsCountBadge');
  const summaryEl = document.getElementById('folderItemsSummary');

  // 1. Build Breadcrumb Trail
  const domainLabel = state.selectedCategoryDomain === 'all'
    ? 'All Domains'
    : (DOMAIN_BADGE_MAP[state.selectedCategoryDomain]?.label || state.selectedCategoryDomain);

  let crumbs = [];
  if (state.currentFolderId) {
    let curr = state.categories.find(c => c.id === state.currentFolderId);
    while (curr) {
      crumbs.unshift(curr);
      curr = curr.parent_id ? state.categories.find(c => c.id === curr.parent_id) : null;
    }
  }

  let trailHtml = `
    <span class="breadcrumb-item ${!state.currentFolderId ? 'active' : ''}" onclick="navigateToBreadcrumb(null)" title="Domain Root">
      <i class="fa-solid fa-layer-group"></i> ${escapeHtml(domainLabel)}
    </span>
  `;

  crumbs.forEach((crumb, idx) => {
    const isLast = idx === crumbs.length - 1;
    trailHtml += `
      <span class="breadcrumb-separator"><i class="fa-solid fa-chevron-right"></i></span>
      <span class="breadcrumb-item ${isLast ? 'active' : ''}" ${!isLast ? `onclick="navigateToBreadcrumb(${crumb.id})"` : ''} title="${escapeHtml(crumb.name_en)}">
        <i class="fa-solid ${isLast ? 'fa-folder-open' : 'fa-folder'}"></i> ${escapeHtml(crumb.name_en)}
      </span>
    `;
  });

  if (trailContainer) trailContainer.innerHTML = trailHtml;
  if (btnUp) btnUp.disabled = state.currentFolderId === null;

  // 2. Filter Subfolders
  let subfolders = [];
  if (state.currentFolderId === null) {
    subfolders = state.categories.filter(c => {
      const isRoot = !c.parent_id;
      if (!isRoot) return false;
      if (state.selectedCategoryDomain !== 'all') {
        return (c.domain || 'semantic').toLowerCase() === state.selectedCategoryDomain.toLowerCase();
      }
      return true;
    });
  } else {
    subfolders = state.categories.filter(c => c.parent_id === state.currentFolderId);
  }

  // 3. Filter Flashcards directly in this folder / root
  let cardsInFolder = [];
  if (state.currentFolderId === null) {
    cardsInFolder = state.cards.filter(c => {
      const isRootCard = !c.category_id;
      if (!isRootCard) return false;
      if (state.selectedCategoryDomain !== 'all') {
        return (c.domain || 'semantic').toLowerCase() === state.selectedCategoryDomain.toLowerCase();
      }
      return true;
    });
  } else {
    cardsInFolder = state.cards.filter(c => c.category_id === state.currentFolderId);
  }

  // 4. Render Subfolders
  if (subfoldersContainer) {
    if (subfolders.length === 0) {
      subfoldersContainer.innerHTML = `
        <div style="grid-column: 1 / -1; padding: 24px; text-align: center; color: var(--text-muted); background: #FAFBFB; border-radius: var(--radius-md); border: 1px dashed var(--border-color);">
          <i class="fa-solid fa-folder-open" style="font-size: 28px; opacity: 0.4; margin-bottom: 8px;"></i>
          <p style="font-size: 13px; margin: 0 0 10px 0;">No subfolders inside this location.</p>
          <button class="btn btn-sm btn-outline-primary" onclick="openNewCategoryModal(state.currentFolderId)">
            <i class="fa-solid fa-folder-plus"></i> Create Subfolder Here
          </button>
        </div>
      `;
    } else {
      subfoldersContainer.innerHTML = subfolders.map(cat => renderCategoryFolderCardHtml(cat, true)).join('');
    }
  }

  // 5. Render Cards in Folder
  if (cardsContainer) {
    if (cardsInFolder.length === 0) {
      cardsContainer.innerHTML = `
        <div style="grid-column: 1 / -1; padding: 24px; text-align: center; color: var(--text-muted); background: #FAFBFB; border-radius: var(--radius-md); border: 1px dashed var(--border-color);">
          <i class="fa-solid fa-clone" style="font-size: 28px; opacity: 0.4; margin-bottom: 8px;"></i>
          <p style="font-size: 13px; margin: 0 0 10px 0;">No flashcards directly inside this folder.</p>
          <button class="btn btn-sm btn-outline-primary" onclick="openNewCardInCurrentFolder()">
            <i class="fa-solid fa-plus"></i> Add Flashcard Here
          </button>
        </div>
      `;
    } else {
      cardsContainer.innerHTML = cardsInFolder.map(renderCardHtml).join('');
    }
  }

  // 6. Update Badges & Summary
  if (subfolderBadge) subfolderBadge.textContent = subfolders.length;
  if (cardsBadge) cardsBadge.textContent = cardsInFolder.length;
  if (summaryEl) {
    summaryEl.textContent = `${subfolders.length} subfolders • ${cardsInFolder.length} direct cards`;
  }
}

function renderCategoryFolderCardHtml(cat, isExplorer = true) {
  const iconClass = CATEGORY_ICON_MAP[cat.icon_name] || 'fa-folder';
  const subnames = [cat.name_ta, cat.name_hi, cat.name_ml].filter(Boolean).join(' • ');
  const domKey = (cat.domain || 'semantic').toLowerCase();
  const domBadge = DOMAIN_BADGE_MAP[domKey] || { label: cat.domain || 'Semantic', bg: '#F1F5F9', color: '#475569' };
  const subCount = cat.subcategories_count || 0;
  const directCards = cat.card_count || 0;
  const totalCards = cat.total_card_count !== undefined ? cat.total_card_count : directCards;

  return `
    <div class="category-card folder-card-clickable" style="border-left: 4px solid ${escapeHtml(cat.color_hex || '#4CAF50')};">
      <div class="category-card-header" onclick="openFolder(${cat.id})" title="Click to open folder: ${escapeHtml(cat.name_en)}" style="cursor:pointer;">
        <div class="category-icon-box" style="background-color: ${escapeHtml(cat.color_hex || '#E8F5E9')}; color: #1E293B;">
          <i class="fa-solid ${iconClass}"></i>
        </div>
        <div style="flex:1;">
          <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:8px;">
            <h4 class="category-title" style="display:flex; align-items:center; gap:6px;">
              <i class="fa-solid fa-folder" style="font-size:13px; color:${escapeHtml(cat.color_hex || '#4CAF50')};"></i>
              ${escapeHtml(cat.name_en)}
            </h4>
            <span style="background:${domBadge.bg}; color:${domBadge.color}; font-size:11px; font-weight:700; padding:2px 8px; border-radius:12px; white-space:nowrap;">
              ${escapeHtml(domBadge.label)}
            </span>
          </div>
          <p class="category-subnames">${escapeHtml(subnames || 'Folder Collection')}</p>
          ${cat.description ? `<p style="font-size:12px; color:var(--text-muted); margin-top:4px;">${escapeHtml(cat.description)}</p>` : ''}
        </div>
      </div>

      <div class="folder-badges" onclick="openFolder(${cat.id})" style="cursor:pointer; padding: 4px 0;">
        <span class="badge-subfolder" title="Nested Subfolders">
          <i class="fa-solid fa-folder-tree"></i> ${subCount} ${subCount === 1 ? 'subfolder' : 'subfolders'}
        </span>
        <span class="badge-cardcount" title="${directCards} cards in this folder, ${totalCards} in folder + subfolders">
          <i class="fa-solid fa-clone"></i> ${directCards} cards ${totalCards !== directCards ? `(${totalCards} total)` : ''}
        </span>
      </div>

      <div class="category-footer">
        <button class="btn btn-sm btn-outline-primary" onclick="openFolder(${cat.id})" title="Open Folder">
          <i class="fa-solid fa-folder-open"></i> Open
        </button>
        <div style="display:flex; gap:6px;">
          <button class="btn-icon" title="Add Subfolder inside here" onclick="openNewCategoryModal(${cat.id})">
            <i class="fa-solid fa-folder-plus"></i>
          </button>
          <button class="btn-icon" title="Edit Folder" onclick="openEditCategoryModal(${cat.id})">
            <i class="fa-solid fa-pen"></i>
          </button>
          <button class="btn-icon delete" title="Delete Folder and contents" onclick="deleteCategory(${cat.id}, '${escapeHtml(cat.name_en)}')">
            <i class="fa-solid fa-trash"></i>
          </button>
        </div>
      </div>
    </div>
  `;
}

// RENDER 6-CONCEPT MATRIX (Semantic Domain only)
function renderConceptsMatrix() {
  const tbody = document.getElementById('conceptsMatrixBody');
  const lang = state.activeMatrixLang;

  const semanticCards = state.cards.filter(c => {
    const cat = state.categories.find(k => k.id === c.category_id);
    return (c.domain || cat?.domain || 'semantic').toLowerCase() === 'semantic';
  });

  if (semanticCards.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:32px;">No semantic cards found to display in matrix.</td></tr>';
    return;
  }

  tbody.innerHTML = semanticCards.map(c => {
    const attrs = c.attributes || {};
    const getVal = (key) => {
      const item = attrs[key];
      if (!item) return '<span style="color:var(--text-light);">-</span>';
      return escapeHtml(item[lang] || item['en'] || '-');
    };

    return `
      <tr>
        <td style="font-weight: 700; color: var(--primary);"><i class="fa-solid fa-clone"></i> ${escapeHtml(c.title_en)}</td>
        <td>${getVal('group')}</td>
        <td>${getVal('use')}</td>
        <td>${getVal('action')}</td>
        <td>${getVal('location')}</td>
        <td>${getVal('association')}</td>
        <td>${getVal('properties')}</td>
      </tr>
    `;
  }).join('');
}

function switchMatrixLang(lang) {
  state.activeMatrixLang = lang;
  document.querySelectorAll('.lang-selector-group .lang-btn').forEach(btn => {
    btn.classList.toggle('active', btn.getAttribute('data-lang') === lang);
  });
  renderConceptsMatrix();
}

// RENDER USERS
function renderUsers() {
  const tbody = document.getElementById('usersTableBody');
  if (state.users.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:24px;">No users registered yet.</td></tr>';
    return;
  }

  tbody.innerHTML = state.users.map(u => {
    const roleClass = `role-${(u.role || 'guest').toLowerCase()}`;
    return `
      <tr>
        <td>#${u.id}</td>
        <td style="font-weight:700;">${escapeHtml(u.name)}</td>
        <td>${escapeHtml(u.email)}</td>
        <td><span class="role-badge ${roleClass}">${escapeHtml(u.role || 'user')}</span></td>
        <td><span style="color:#4CAF50;font-weight:600;"><i class="fa-solid fa-circle-check"></i> Active</span></td>
        <td>
          <select onchange="updateUserRole(${u.id}, this.value)" style="padding:4px 8px; border-radius:6px; font-size:12px; border:1px solid var(--border-color);">
            <option value="admin" ${u.role === 'admin' ? 'selected' : ''}>Admin</option>
            <option value="educator" ${u.role === 'educator' ? 'selected' : ''}>Educator</option>
            <option value="student" ${u.role === 'student' ? 'selected' : ''}>Student</option>
            <option value="guest" ${u.role === 'guest' ? 'selected' : ''}>Guest</option>
          </select>
        </td>
      </tr>
    `;
  }).join('');
}

async function updateUserRole(userId, newRole) {
  try {
    const res = await fetch(`/api/admin/users/${userId}/role`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role: newRole }),
    });
    if (!res.ok) throw new Error('Role update failed');
    showToast(`Updated user role to ${newRole.toUpperCase()}`, 'success');
    loadDashboardData();
  } catch (e) {
    showToast('Failed to update role: ' + e.message, 'error');
  }
}

// =====================================================================
// IMAGE CROPPER & SLOT UPLOAD MANAGEMENT
// =====================================================================

let cropperState = {
  instance: null,
  slot: null,
  rawFile: null,
  fileName: '',
  aspectRatio: 1,
  scaleX: 1,
  scaleY: 1,
};

function triggerImageSlotUpload(slot) {
  const fileInput = document.getElementById(`file_slot_${slot}`);
  if (fileInput) {
    fileInput.value = ''; // Reset so onChange fires even for same file
    fileInput.click();
  }
}

async function uploadImageSlot(slot) {
  const fileInput = document.getElementById(`file_slot_${slot}`);
  if (!fileInput || !fileInput.files || fileInput.files.length === 0) return;
  const file = fileInput.files[0];
  openCropperWithFile(slot, file);
}

function openCropperWithFile(slot, file) {
  cropperState.slot = slot;
  cropperState.rawFile = file;
  cropperState.fileName = file.name || 'image.png';
  cropperState.scaleX = 1;
  cropperState.scaleY = 1;

  const reader = new FileReader();
  reader.onload = (e) => {
    initCropperModal(slot, e.target.result);
  };
  reader.readAsDataURL(file);
}

function openCropperForCurrent(slot) {
  let url = '';
  if (slot === 'main') {
    url = (document.getElementById('cardFormImageUrl').value || '').trim();
  } else {
    url = (document.getElementById(`${slot}_image`).value || '').trim();
  }

  if (!url) {
    showToast('No image available to crop. Please upload an image first.', 'warning');
    return;
  }

  cropperState.slot = slot;
  cropperState.rawFile = null;
  const parts = url.split('/');
  cropperState.fileName = parts[parts.length - 1].split('?')[0] || 'cropped_image.png';
  cropperState.scaleX = 1;
  cropperState.scaleY = 1;

  initCropperModal(slot, url);
}

function getSlotDisplayName(slot) {
  if (slot === 'main') return 'Trigger / Main Image';
  const slotNum = slot.replace('attr_', '');
  const nameInput = document.getElementById(`${slot}_name`);
  const customName = nameInput ? nameInput.value.trim() : '';
  return customName ? `Attribute ${slotNum} (${customName})` : `Attribute ${slotNum}`;
}

function initCropperModal(slot, imageSrc) {
  const targetImg = document.getElementById('cropperTargetImg');
  const subtitle = document.getElementById('cropperModalSubtitle');
  const skipBtn = document.getElementById('btnUploadRawOriginal');

  if (subtitle) {
    subtitle.textContent = `Target Slot: ${getSlotDisplayName(slot)}`;
  }

  if (skipBtn) {
    skipBtn.style.display = cropperState.rawFile ? 'inline-flex' : 'none';
  }

  // Destroy previous cropper if exists
  if (cropperState.instance) {
    cropperState.instance.destroy();
    cropperState.instance = null;
  }

  targetImg.src = imageSrc;
  openModal('cropperModal');

  // Reset Aspect Ratio Buttons (default 1:1)
  cropperState.aspectRatio = 1;
  document.querySelectorAll('.btn-aspect').forEach(btn => {
    const ratio = parseFloat(btn.getAttribute('data-ratio'));
    if (ratio === 1) btn.classList.add('active');
    else btn.classList.remove('active');
  });

  // Initialize Cropper when modal opens
  setTimeout(() => {
    cropperState.instance = new Cropper(targetImg, {
      aspectRatio: 1,
      viewMode: 1,
      dragMode: 'move',
      autoCropArea: 0.9,
      restore: false,
      guides: true,
      center: true,
      highlight: true,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false,
      preview: '.cropper-preview-box',
      checkCrossOrigin: false,
    });
  }, 150);
}

function setCropperRatio(ratio, buttonElement) {
  cropperState.aspectRatio = ratio;
  document.querySelectorAll('.btn-aspect').forEach(btn => btn.classList.remove('active'));
  if (buttonElement) buttonElement.classList.add('active');

  if (cropperState.instance) {
    cropperState.instance.setAspectRatio(ratio);
  }
}

function cropperRotate(deg) {
  if (cropperState.instance) {
    cropperState.instance.rotate(deg);
  }
}

function cropperFlip(dir) {
  if (!cropperState.instance) return;
  if (dir === 'h') {
    cropperState.scaleX = -cropperState.scaleX;
    cropperState.instance.scaleX(cropperState.scaleX);
  } else if (dir === 'v') {
    cropperState.scaleY = -cropperState.scaleY;
    cropperState.instance.scaleY(cropperState.scaleY);
  }
}

function cropperZoom(ratio) {
  if (cropperState.instance) {
    cropperState.instance.zoom(ratio);
  }
}

function cropperReset() {
  if (cropperState.instance) {
    cropperState.scaleX = 1;
    cropperState.scaleY = 1;
    cropperState.instance.reset();
  }
}

function closeCropperModal() {
  if (cropperState.instance) {
    cropperState.instance.destroy();
    cropperState.instance = null;
  }
  closeModal('cropperModal');
}

async function uploadRawOriginalImage() {
  if (!cropperState.rawFile || !cropperState.slot) {
    closeCropperModal();
    return;
  }
  const slot = cropperState.slot;
  const file = cropperState.rawFile;
  closeCropperModal();
  await uploadImageFile(slot, file);
}

async function applyCropAndUpload() {
  if (!cropperState.instance || !cropperState.slot) return;

  const slot = cropperState.slot;
  const originalName = cropperState.fileName || 'image.png';
  const nameWithoutExt = originalName.substring(0, originalName.lastIndexOf('.')) || originalName;

  const canvas = cropperState.instance.getCroppedCanvas({
    maxWidth: 2048,
    maxHeight: 2048,
    fillColor: '#fff',
    imageSmoothingEnabled: true,
    imageSmoothingQuality: 'high',
  });

  if (!canvas) {
    showToast('Failed to process cropped canvas.', 'error');
    return;
  }

  const applyBtn = document.getElementById('btnApplyCropUpload');
  if (applyBtn) {
    applyBtn.disabled = true;
    applyBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Uploading...';
  }

  canvas.toBlob(async (blob) => {
    try {
      if (!blob) throw new Error('Could not generate image blob from cropped canvas');
      const croppedFile = new File([blob], `${nameWithoutExt}_cropped.png`, { type: 'image/png' });
      closeCropperModal();
      await uploadImageFile(slot, croppedFile);
    } catch (err) {
      showToast('Crop & upload error: ' + err.message, 'error');
    } finally {
      if (applyBtn) {
        applyBtn.disabled = false;
        applyBtn.innerHTML = '<i class="fa-solid fa-crop-simple"></i> Crop & Upload';
      }
    }
  }, 'image/png', 0.95);
}

async function uploadImageFile(slot, file) {
  if (!file) return;

  const formData = new FormData();
  formData.append('file', file);

  const slotLabel = getSlotDisplayName(slot);

  try {
    showToast(`Uploading image for ${slotLabel}...`, 'info');
    const res = await fetch('/api/admin/upload-image', {
      method: 'POST',
      body: formData,
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      throw new Error(errData.detail || 'Image upload failed on server');
    }
    const data = await res.json();

    if (slot === 'main') {
      document.getElementById('cardFormImageUrl').value = data.image_url;
      const fnBadge = document.getElementById('preview_filename_badge');
      const fnTxt = document.getElementById('preview_filename_txt');
      const originalFileName = file.name || (data.image_url.split('/').pop().split('?')[0]);
      if (fnBadge && fnTxt) {
        fnTxt.textContent = originalFileName;
        fnBadge.style.display = 'inline-flex';
      }

      const domain = (document.getElementById('cardFormDomain')?.value || '').toLowerCase();
      const titleInput = document.getElementById('cardFormTitleEn');
      if (domain === 'syntax' || !titleInput.value.trim()) {
        if (titleInput) {
          titleInput.value = originalFileName;
        }
      }
      updateSlotPreview('main');
    } else {
      document.getElementById(`${slot}_image`).value = data.image_url;
      const btnTxt = document.getElementById(`btn_txt_${slot}`);
      if (btnTxt) btnTxt.textContent = 'Replace Image';
      updateSlotPreview(slot);
    }

    showToast(`Image uploaded successfully for ${slotLabel}!`, 'success');
  } catch (err) {
    showToast(`Failed to upload image: ${err.message}`, 'error');
  }
}

function updateSlotPreview(slot) {
  if (slot === 'main') {
    const url = (document.getElementById('cardFormImageUrl').value || '').trim();
    const img = document.getElementById('preview_img_main');
    const txt = document.getElementById('preview_txt_main');
    const cropBtn = document.getElementById('btn_crop_main');
    const fnBadge = document.getElementById('preview_filename_badge');
    const fnTxt = document.getElementById('preview_filename_txt');
    if (url) {
      img.src = url;
      img.style.display = 'block';
      if (txt) txt.style.display = 'none';
      if (cropBtn) cropBtn.style.display = 'inline-flex';
      if (fnBadge && fnTxt && (!fnTxt.textContent || fnTxt.textContent === 'file_name.png')) {
        const parts = url.split('/');
        fnTxt.textContent = parts[parts.length - 1].split('?')[0];
        fnBadge.style.display = 'inline-flex';
      }
    } else {
      img.style.display = 'none';
      if (txt) txt.style.display = 'block';
      if (cropBtn) cropBtn.style.display = 'none';
      if (fnBadge) fnBadge.style.display = 'none';
    }
  } else {
    const url = (document.getElementById(`${slot}_image`).value || '').trim();
    const img = document.getElementById(`preview_img_${slot}`);
    const ico = document.getElementById(`preview_ico_${slot}`);
    const cropBtn = document.getElementById(`btn_crop_${slot}`);
    if (url) {
      img.src = url;
      img.style.display = 'block';
      if (ico) ico.style.display = 'none';
      if (cropBtn) cropBtn.style.display = 'inline-flex';
    } else {
      img.style.display = 'none';
      if (ico) ico.style.display = 'block';
      if (cropBtn) cropBtn.style.display = 'none';
    }
  }
}

// POPULATE DROPDOWNS
function populateCategoryDropdowns() {
  const domain = state.selectedCardDomain || '';
  populateCategoryFilterDropdown(domain);
  const cardDomain = document.getElementById('cardFormDomain')?.value || 'semantic';
  populateCardCategorySelect(cardDomain);
}

function onCardFormDomainChanged() {
  const domain = document.getElementById('cardFormDomain')?.value || '';
  populateCardCategorySelect(domain);
  toggleCardAttributesVisibility(domain);
}

function toggleCardAttributesVisibility(domain) {
  const domLower = (domain || '').toLowerCase();
  const isSemantic = domLower === 'semantic';
  const isSyntax = domLower === 'syntax';
  const attrCol = document.getElementById('cardAttributesCol');
  const formGrid = document.getElementById('cardFormGrid');
  const modalContainer = document.querySelector('#cardModal .modal-container');
  const modalTitle = document.getElementById('cardModalTitle');
  const saveBtn = document.getElementById('saveCardBtn');
  const notice = document.getElementById('domainAttrNotice');
  const noticeText = document.getElementById('domainAttrNoticeText');
  const catGroup = document.getElementById('cardCategoryGroup');
  const titleHint = document.getElementById('cardTitleHint');
  const isEdit = Boolean(document.getElementById('cardFormId')?.value);

  if (attrCol) {
    attrCol.style.display = isSemantic ? '' : 'none';
  }
  if (formGrid) {
    if (isSemantic) {
      formGrid.classList.remove('single-col');
    } else {
      formGrid.classList.add('single-col');
    }
  }
  if (modalContainer) {
    if (isSemantic) {
      modalContainer.classList.add('large-modal');
      modalContainer.style.maxWidth = '';
    } else {
      modalContainer.classList.remove('large-modal');
      modalContainer.style.maxWidth = '680px';
    }
  }
  if (catGroup) {
    catGroup.style.display = isSyntax ? 'none' : 'block';
  }
  if (titleHint) {
    titleHint.style.display = isSyntax ? 'block' : 'none';
  }
  if (notice) {
    if (isSemantic) {
      notice.style.display = 'none';
    } else {
      notice.style.display = 'block';
      if (noticeText) {
        if (isSyntax) {
          noticeText.textContent = 'Syntax Domain: Flashcards require no category deck. Simply upload your target image, and its file name will automatically be used in the UI.';
        } else {
          noticeText.textContent = 'Non-Semantic Domain: Flashcards in this domain only require the Target / Main Image. The 6 semantic attributes and their image slots are disabled.';
        }
      }
    }
  }
  if (!isEdit && modalTitle) {
    const domainNames = {
      phonology: 'Phonology',
      morphology: 'Morphology',
      syntax: 'Syntax (Stories)',
      semantic: 'Semantic',
      pragmatic: 'Pragmatic'
    };
    const domLabel = domainNames[domLower] || domain || 'Target Domain';
    modalTitle.textContent = isSemantic 
      ? 'Create New Flashcard (7 Images)' 
      : `Create New Flashcard (${domLabel})`;
  }
  if (saveBtn) {
    saveBtn.textContent = isEdit 
      ? 'Save Changes' 
      : (isSemantic ? 'Save Flashcard (7 Images)' : 'Save Flashcard');
  }
}

function populateCardCategorySelect(domain, selectedCatId = null) {
  const formSelect = document.getElementById('cardFormCategory');
  if (!formSelect) return;

  const domLower = (domain || '').toLowerCase();
  if (domLower === 'syntax') {
    formSelect.innerHTML = '<option value="">(No Category - Direct Story Deck)</option>';
    formSelect.value = '';
    return;
  }

  let cats = state.categories;
  if (domain) {
    cats = cats.filter(c => (c.domain || 'semantic').toLowerCase() === domLower);
  }

  if (cats.length === 0) {
    formSelect.innerHTML = `<option value="">No categories found for ${escapeHtml(domain || 'this domain')} - Add one first</option>`;
    return;
  }

  const treeOptions = buildCategoryTreeOptionsHtml(domLower, selectedCatId);
  formSelect.innerHTML = '<option value="">-- Choose Category / Folder Deck --</option>' + treeOptions;

  if (selectedCatId && cats.some(c => c.id == selectedCatId)) {
    formSelect.value = selectedCatId;
  } else if (cats.length > 0) {
    formSelect.value = cats[0].id;
  }
}

// DEFAULT ATTRIBUTE DEFINITIONS
const DEFAULT_ATTRIBUTES = [
  { key: 'group', name: 'Group', placeholder_en: 'e.g. Domestic Pet, Wild Animal' },
  { key: 'location', name: 'Location', placeholder_en: 'e.g. Houses & Farms, Oceans' },
  { key: 'association', name: 'Association', placeholder_en: 'e.g. Bone & Kennel, Nest' },
  { key: 'property', name: 'Property', placeholder_en: 'e.g. Loyal & 4 Legs, Soft Fur' },
  { key: 'attr_5', name: 'Attribute 5', placeholder_en: 'e.g. Action / Behavior' },
  { key: 'attr_6', name: 'Attribute 6', placeholder_en: 'e.g. Use / Function' },
];

// MODAL HANDLERS: CARD
function openNewCardModal() {
  document.getElementById('cardForm').reset();
  document.getElementById('cardFormId').value = '';
  document.getElementById('cardFormSubcategory').value = '';
  document.getElementById('cardFormImageUrl').value = '';
  document.getElementById('cardModalTitle').textContent = 'Create New Flashcard (7 Images)';
  document.getElementById('saveCardBtn').textContent = 'Create Flashcard';

  const fnBadge = document.getElementById('preview_filename_badge');
  if (fnBadge) fnBadge.style.display = 'none';

  // Domain & Category initialization
  let initialDomain = 'semantic';
  if (state.selectedCardDomain) {
    initialDomain = state.selectedCardDomain;
  } else if (state.selectedCategoryDomain && state.selectedCategoryDomain !== 'all') {
    initialDomain = state.selectedCategoryDomain;
  }

  if (document.getElementById('cardFormDomain')) {
    document.getElementById('cardFormDomain').value = initialDomain;
  }
  populateCardCategorySelect(initialDomain);
  toggleCardAttributesVisibility(initialDomain);

  // Reset main trigger image preview
  updateSlotPreview('main');

  // Reset 6 attribute slots
  for (let i = 1; i <= 6; i++) {
    const slot = `attr_${i}`;
    const def = DEFAULT_ATTRIBUTES[i - 1];
    document.getElementById(`${slot}_name`).value = def.name;
    document.getElementById(`${slot}_image`).value = '';
    const btnTxt = document.getElementById(`btn_txt_${slot}`);
    if (btnTxt) btnTxt.textContent = 'Upload Image';
    ['en', 'ta', 'hi', 'ml'].forEach(lang => {
      const el = document.getElementById(`${slot}_${lang}`);
      if (el) el.value = '';
    });
    updateSlotPreview(slot);
  }

  switchModalLang('en');
  openModal('cardModal');
}

function openEditCardModal(cardId) {
  const card = state.cards.find(c => c.id === cardId);
  if (!card) return;

  const cat = state.categories.find(k => k.id === card.category_id);
  const dom = (cat?.domain || card.domain || 'semantic').toLowerCase();

  document.getElementById('cardFormId').value = card.id;

  if (document.getElementById('cardFormDomain')) {
    document.getElementById('cardFormDomain').value = dom;
  }
  populateCardCategorySelect(dom, card.category_id);
  toggleCardAttributesVisibility(dom);

  document.getElementById('cardFormCategory').value = card.category_id || '';
  document.getElementById('cardFormSubcategory').value = card.subcategory || '';
  document.getElementById('cardFormTitleEn').value = card.title_en || card.name || '';
  document.getElementById('cardFormTitleTa').value = card.title_ta || '';
  document.getElementById('cardFormTitleHi').value = card.title_hi || '';
  document.getElementById('cardFormTitleMl').value = card.title_ml || '';
  document.getElementById('cardFormImageUrl').value = card.image_url || card.trigger_image || '';

  const fnBadge = document.getElementById('preview_filename_badge');
  const fnTxt = document.getElementById('preview_filename_txt');
  const imgUrl = card.image_url || card.trigger_image || '';
  if (imgUrl && fnBadge && fnTxt) {
    fnTxt.textContent = imgUrl.split('/').pop().split('?')[0];
    fnBadge.style.display = 'inline-flex';
  } else if (fnBadge) {
    fnBadge.style.display = 'none';
  }

  updateSlotPreview('main');

  // Populate 6 attributes from attributes_list or attributes dict
  const attrList = card.attributes_list || [];
  const attrDict = card.attributes || {};

  for (let i = 1; i <= 6; i++) {
    const slot = `attr_${i}`;
    const def = DEFAULT_ATTRIBUTES[i - 1];
    
    // Find matching attribute by index, key or def key
    let item = attrList[i - 1];
    if (!item) {
      item = attrDict[def.key] || attrDict[slot] || attrDict[def.name.toLowerCase()] || {};
    }

    const name = item.name || item.label || def.name;
    const imgUrl = item.image_url || item.attribute_image || '';

    document.getElementById(`${slot}_name`).value = name;
    document.getElementById(`${slot}_image`).value = imgUrl;

    const btnTxt = document.getElementById(`btn_txt_${slot}`);
    if (btnTxt) btnTxt.textContent = imgUrl ? 'Replace Image' : 'Upload Image';

    document.getElementById(`${slot}_en`).value = item.value_en || item.en || '';
    document.getElementById(`${slot}_ta`).value = item.value_ta || item.ta || '';
    document.getElementById(`${slot}_hi`).value = item.value_hi || item.hi || '';
    document.getElementById(`${slot}_ml`).value = item.value_ml || item.ml || '';

    updateSlotPreview(slot);
  }

  document.getElementById('cardModalTitle').textContent = `Edit Flashcard: ${card.title_en || card.name}`;
  document.getElementById('saveCardBtn').textContent = 'Save Changes';
  switchModalLang('en');
  openModal('cardModal');
}

function switchModalLang(lang) {
  state.activeModalLang = lang;
  document.querySelectorAll('.modal-lang-tabs .modal-lang-tab').forEach(b => {
    b.classList.toggle('active', b.getAttribute('data-lang') === lang);
  });

  const langNames = { en: 'English', ta: 'Tamil', hi: 'Hindi', ml: 'Malayalam' };
  document.querySelectorAll('.active-lang-indicator').forEach(el => {
    el.textContent = langNames[lang];
  });

  document.querySelectorAll('.concept-field').forEach(field => {
    field.classList.toggle('hidden', !field.classList.contains(`lang-${lang}`));
  });
}

async function handleCardSubmit(e) {
  e.preventDefault();
  const id = document.getElementById('cardFormId').value;
  const isEdit = Boolean(id);

  const domain = (document.getElementById('cardFormDomain')?.value || 'semantic').toLowerCase();
  const isSemantic = domain === 'semantic';
  const isSyntax = domain === 'syntax';

  const attributesList = [];
  const attributesDict = {};

  if (isSemantic) {
    for (let i = 1; i <= 6; i++) {
      const slot = `attr_${i}`;
      const def = DEFAULT_ATTRIBUTES[i - 1];
      const name = (document.getElementById(`${slot}_name`).value || def.name).trim();
      const imageUrl = (document.getElementById(`${slot}_image`).value || '').trim();
      const en = (document.getElementById(`${slot}_en`).value || '').trim();
      const ta = (document.getElementById(`${slot}_ta`).value || '').trim();
      const hi = (document.getElementById(`${slot}_hi`).value || '').trim();
      const ml = (document.getElementById(`${slot}_ml`).value || '').trim();

      const key = def.key || slot;
      const attrObj = {
        key: key,
        name: name,
        label: name,
        image_url: imageUrl,
        attribute_image: imageUrl,
        value_en: en,
        value_ta: ta,
        value_hi: hi,
        value_ml: ml,
        en: en,
        ta: ta,
        hi: hi,
        ml: ml,
      };

      attributesList.push(attrObj);
      attributesDict[key] = attrObj;
    }
  }

  let categoryId = null;
  if (!isSyntax) {
    const catVal = document.getElementById('cardFormCategory').value;
    if (!catVal) {
      showToast('Please select a valid category deck for the chosen domain', 'error');
      return;
    }
    categoryId = parseInt(catVal, 10);
  } else {
    const catVal = document.getElementById('cardFormCategory').value;
    if (catVal) categoryId = parseInt(catVal, 10);
  }

  const imageUrl = document.getElementById('cardFormImageUrl').value.trim();
  let titleEn = document.getElementById('cardFormTitleEn').value.trim();
  if (isSyntax && !titleEn && imageUrl) {
    const parts = imageUrl.split('/');
    titleEn = parts[parts.length - 1].split('?')[0];
  }
  if (!titleEn) {
    titleEn = 'Untitled Card';
  }

  const payload = {
    domain: domain,
    category_id: categoryId,
    subcategory: document.getElementById('cardFormSubcategory').value.trim(),
    name: titleEn,
    title_en: titleEn,
    title_ta: document.getElementById('cardFormTitleTa').value.trim(),
    title_hi: document.getElementById('cardFormTitleHi').value.trim(),
    title_ml: document.getElementById('cardFormTitleMl').value.trim(),
    image_url: imageUrl,
    trigger_image: imageUrl,
    is_published: true,
    attributes: attributesDict,
    attributes_list: attributesList,
  };

  try {
    const url = isEdit ? `/api/cards/${id}` : '/api/cards';
    const method = isEdit ? 'PUT' : 'POST';

    const res = await fetch(url, {
      method: method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      throw new Error(errData.detail || 'Server error while saving card');
    }

    showToast(isEdit ? 'Flashcard updated successfully!' : 'Flashcard created with domain & category!', 'success');
    closeModal('cardModal');
    loadDashboardData();
  } catch (err) {
    showToast('Failed to save flashcard: ' + err.message, 'error');
  }
}

async function deleteCard(id, title) {
  if (!confirm(`Are you sure you want to delete the flashcard "${title}"?`)) return;

  try {
    const res = await fetch(`/api/cards/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Delete failed');
    showToast(`Deleted card "${title}"`, 'success');
    loadDashboardData();
  } catch (err) {
    showToast('Failed to delete card: ' + err.message, 'error');
  }
}

// MODAL HANDLERS: CATEGORY
// MODAL HANDLERS: CATEGORY / FOLDER
function openNewCategoryModal(parentId = null) {
  document.getElementById('catForm').reset();
  document.getElementById('catFormId').value = '';

  const targetParentId = parentId !== null && parentId !== undefined ? parentId : state.currentFolderId;
  const parentCat = targetParentId ? state.categories.find(c => c.id === targetParentId) : null;

  let domain = 'semantic';
  if (parentCat && parentCat.domain) {
    domain = parentCat.domain;
  } else if (state.selectedCategoryDomain && state.selectedCategoryDomain !== 'all') {
    domain = state.selectedCategoryDomain;
  }

  if (document.getElementById('catFormDomain')) {
    document.getElementById('catFormDomain').value = domain;
  }

  populateParentCategoryDropdown(domain, targetParentId, null);

  if (document.getElementById('catFormDesc')) document.getElementById('catFormDesc').value = '';
  document.getElementById('catFormColor').value = '#E8F5E9';
  document.getElementById('colorHexDisplay').textContent = '#E8F5E9';

  const modalTitle = document.getElementById('catModalTitle');
  if (modalTitle) {
    modalTitle.textContent = parentCat 
      ? `Create Subfolder inside: ${parentCat.name_en}`
      : 'Create New Folder / Category';
  }
  document.getElementById('saveCatBtn').textContent = 'Save Folder';
  openModal('catModal');
}

function openEditCategoryModal(catId) {
  const cat = state.categories.find(c => c.id === catId);
  if (!cat) return;

  document.getElementById('catFormId').value = cat.id;
  const dom = (cat.domain || 'semantic').toLowerCase();
  if (document.getElementById('catFormDomain')) {
    document.getElementById('catFormDomain').value = dom;
  }

  populateParentCategoryDropdown(dom, cat.parent_id, cat.id);

  document.getElementById('catFormNameEn').value = cat.name_en || '';
  document.getElementById('catFormNameTa').value = cat.name_ta || '';
  document.getElementById('catFormNameHi').value = cat.name_hi || '';
  document.getElementById('catFormNameMl').value = cat.name_ml || '';
  if (document.getElementById('catFormDesc')) document.getElementById('catFormDesc').value = cat.description || '';
  document.getElementById('catFormIcon').value = cat.icon_name || 'pets';
  document.getElementById('catFormColor').value = cat.color_hex || '#E8F5E9';
  document.getElementById('colorHexDisplay').textContent = (cat.color_hex || '#E8F5E9').toUpperCase();

  document.getElementById('catModalTitle').textContent = `Edit Folder: ${cat.name_en}`;
  document.getElementById('saveCatBtn').textContent = 'Save Changes';
  openModal('catModal');
}

async function handleCategorySubmit(e) {
  e.preventDefault();
  const id = document.getElementById('catFormId').value;
  const isEdit = Boolean(id);

  const parentIdVal = document.getElementById('catFormParentId')?.value;
  const parentId = parentIdVal ? parseInt(parentIdVal, 10) : null;

  const payload = {
    name_en: document.getElementById('catFormNameEn').value.trim(),
    parent_id: parentId,
    name_ta: document.getElementById('catFormNameTa').value.trim(),
    name_hi: document.getElementById('catFormNameHi').value.trim(),
    name_ml: document.getElementById('catFormNameMl').value.trim(),
    domain: document.getElementById('catFormDomain')?.value || 'semantic',
    description: (document.getElementById('catFormDesc')?.value || '').trim(),
    icon_name: document.getElementById('catFormIcon').value,
    color_hex: document.getElementById('catFormColor').value,
  };

  try {
    const url = isEdit ? `/api/categories/${id}` : '/api/categories';
    const method = isEdit ? 'PUT' : 'POST';

    const res = await fetch(url, {
      method: method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      throw new Error(errData.detail || 'Server error while saving category folder');
    }

    showToast(isEdit ? 'Folder updated successfully!' : 'New folder created successfully!', 'success');
    closeModal('catModal');
    await loadDashboardData();
    // If we just created a subfolder inside a parent, stay in that folder
    if (!isEdit && parentId) {
      state.currentFolderId = parentId;
      renderCategories();
    }
  } catch (err) {
    showToast('Failed to save folder: ' + err.message, 'error');
  }
}

async function deleteCategory(id, name) {
  if (!confirm(`Are you sure you want to delete category "${name}"? Flashcards in this category may also be deleted.`)) return;

  try {
    const res = await fetch(`/api/categories/${id}`, { method: 'DELETE' });
    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      throw new Error(errData.detail || 'Delete failed');
    }
    showToast(`Deleted category "${name}"`, 'success');
    loadDashboardData();
  } catch (err) {
    showToast('Failed to delete category: ' + err.message, 'error');
  }
}

// SCANNER TEST & MODAL DROPZONE RUNNER
function setupDropzone() {
  const dropzone = document.getElementById('dropzone');
  if (dropzone) {
    ['dragenter', 'dragover'].forEach(name => {
      dropzone.addEventListener(name, (e) => {
        e.preventDefault();
        dropzone.style.borderColor = 'var(--primary)';
        dropzone.style.backgroundColor = 'var(--primary-light)';
      });
    });

    ['dragleave', 'drop'].forEach(name => {
      dropzone.addEventListener(name, (e) => {
        e.preventDefault();
        dropzone.style.borderColor = '#CBD5E1';
        dropzone.style.backgroundColor = 'var(--bg-body)';
      });
    });

    dropzone.addEventListener('drop', (e) => {
      const files = e.dataTransfer.files;
      if (files.length > 0) processScanFile(files[0]);
    });
  }

  // Setup drag & drop for Trigger Main Image Preview Box
  setupSlotDropTarget('preview_box_main', 'main');

  // Setup drag & drop for all 6 Attribute Thumbnail Boxes
  for (let i = 1; i <= 6; i++) {
    setupSlotDropTarget(`thumb_box_attr_${i}`, `attr_${i}`);
  }
}

function setupSlotDropTarget(elementId, slot) {
  const el = document.getElementById(elementId);
  if (!el) return;

  ['dragenter', 'dragover'].forEach(name => {
    el.addEventListener(name, (e) => {
      e.preventDefault();
      e.stopPropagation();
      el.classList.add('drag-over');
    });
  });

  ['dragleave', 'drop'].forEach(name => {
    el.addEventListener(name, (e) => {
      e.preventDefault();
      e.stopPropagation();
      el.classList.remove('drag-over');
    });
  });

  el.addEventListener('drop', (e) => {
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      uploadImageFile(slot, files[0]);
    }
  });
}

function handleScannerFile(e) {
  const file = e.target.files[0];
  if (file) processScanFile(file);
}

async function processScanFile(file) {
  const previewArea = document.getElementById('scannerPreviewArea');
  const previewImg = document.getElementById('scannerPreviewImg');
  const resultCard = document.getElementById('scannerResultCard');

  previewArea.style.display = 'grid';
  previewImg.src = URL.createObjectURL(file);
  resultCard.innerHTML = '<div style="padding:20px; text-align:center;"><i class="fa-solid fa-spinner fa-spin" style="font-size:24px; color:var(--primary);"></i><p style="margin-top:8px;">Running Vision & OCR Pipeline...</p></div>';

  const formData = new FormData();
  formData.append('file', file);

  try {
    const res = await fetch('/api/detect', {
      method: 'POST',
      body: formData,
    });
    const data = await res.json();

    if (data.card) {
      resultCard.innerHTML = `
        <div style="border-left: 4px solid var(--primary); padding-left: 12px; margin-bottom: 12px;">
          <span style="font-size:11px; font-weight:700; color:var(--primary); text-transform:uppercase;">Recognition Success</span>
          <h3 style="font-size:20px; font-weight:800;">${escapeHtml(data.card.title_en || data.card.title)}</h3>
          <p style="font-size:12px; color:var(--text-muted);">${escapeHtml(data.card.title_ta || '')} • ${escapeHtml(data.card.title_hi || '')}</p>
        </div>
        <p style="font-size:13px; color:var(--text-main); margin-bottom:12px;"><strong>Confidence:</strong> ${(data.confidence ? (data.confidence * 100).toFixed(1) : 95)}%</p>
        <div style="background:var(--bg-body); padding:10px; border-radius:8px; font-size:12px;">
          <strong>Matching Concepts:</strong> ${Object.keys(data.card.attributes || {}).length} Dimensions Verified
        </div>
      `;
    } else {
      resultCard.innerHTML = `
        <div style="border-left: 4px solid var(--warning); padding-left: 12px;">
          <h4 style="color:var(--warning);">Object Detected</h4>
          <p style="font-size:13px;">${escapeHtml(data.message || 'Detected object with no direct flashcard match.')}</p>
        </div>
      `;
    }
  } catch (err) {
    resultCard.innerHTML = `<p style="color:var(--danger);"><i class="fa-solid fa-circle-exclamation"></i> Error running scan test: ${err.message}</p>`;
  }
}

// MODAL UTILITIES
function openModal(modalId) {
  document.getElementById(modalId).classList.add('open');
}

function closeModal(modalId) {
  document.getElementById(modalId).classList.remove('open');
}

function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <i class="fa-solid ${type === 'success' ? 'fa-circle-check' : 'fa-circle-exclamation'}"></i>
    <span>${escapeHtml(message)}</span>
  `;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// DATABASE & VISUAL CONTEXT EXPORT ACTIONS
async function downloadDatabaseBundle() {
  const btn = document.getElementById('btnDownloadBundle');
  const originalText = btn ? btn.innerHTML : '';
  if (btn) {
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Preparing ZIP Package...';
  }
  showToast('Generating complete Database & Visual Context ZIP package...', 'success');

  try {
    const res = await fetch('/api/admin/export/bundle');
    if (!res.ok) {
      throw new Error(`Export failed: ${res.statusText}`);
    }

    const blob = await res.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.style.display = 'none';
    a.href = url;

    // Get filename from header or fallback
    const disposition = res.headers.get('Content-Disposition');
    let filename = 'aira_db_with_visual_context.zip';
    if (disposition && disposition.indexOf('filename=') !== -1) {
      const matches = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/.exec(disposition);
      if (matches != null && matches[1]) {
        filename = matches[1].replace(/['"]/g, '');
      }
    }

    a.download = filename;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    a.remove();

    showToast('Download started: ' + filename, 'success');
  } catch (err) {
    showToast('Failed to download bundle: ' + err.message, 'error');
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.innerHTML = originalText;
    }
  }
}

function downloadRawDb() {
  showToast('Downloading SQLite database (aira.db)...', 'success');
  const a = document.createElement('a');
  a.href = '/api/admin/export/db';
  a.download = 'aira.db';
  document.body.appendChild(a);
  a.click();
  a.remove();
}

function downloadJsonExport() {
  showToast('Downloading Visual Context JSON manifest...', 'success');
  const a = document.createElement('a');
  a.href = '/api/admin/export/json';
  a.download = 'aira_visual_context.json';
  document.body.appendChild(a);
  a.click();
  a.remove();
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
