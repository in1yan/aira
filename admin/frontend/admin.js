// Aira Smart Flashcards Web Admin Portal JavaScript

let state = {
  stats: {},
  categories: [],
  cards: [],
  users: [],
  activeTab: 'overview',
  activeMatrixLang: 'en',
  activeModalLang: 'en',
};

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  initColorPickers();
  loadDashboardData();
  setupDropzone();
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

// NAVIGATION & TAB SWITCHING
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
    categories: { title: 'Category Decks', subtitle: 'Organize flashcards into thematic collections' },
    concepts: { title: '6 Cognitive Dimensions Matrix', subtitle: 'Audit Group, Use, Action, Location, Association & Properties' },
    users: { title: 'User Management', subtitle: 'Manage student, teacher, and administrator accounts' },
    scanner: { title: 'AI Card Scanner Test', subtitle: 'Simulate mobile camera vision recognition' },
  };

  if (titles[tabId]) {
    document.getElementById('pageTitle').textContent = titles[tabId].title;
    document.getElementById('pageSubtitle').textContent = titles[tabId].subtitle;
  }
}

// DATA LOADING
async function loadDashboardData() {
  try {
    const [statsRes, catsRes, cardsRes, usersRes] = await Promise.all([
      fetch('/api/admin/stats').then(r => r.json()).catch(() => null),
      fetch('/api/categories').then(r => r.json()).catch(() => []),
      fetch('/api/cards').then(r => r.json()).catch(() => []),
      fetch('/api/admin/users').then(r => r.json()).catch(() => []),
    ]);

    state.stats = statsRes || {
      total_cards: cardsRes.length,
      total_categories: catsRes.length,
      total_users: usersRes.length,
      total_attributes: cardsRes.length * 6,
      category_distribution: [],
    };
    state.categories = catsRes;
    state.cards = cardsRes;
    state.users = usersRes;

    renderKPIs();
    renderDistribution();
    renderCards();
    renderCategories();
    renderConceptsMatrix();
    renderUsers();
    populateCategoryDropdowns();

    document.getElementById('cardCountBadge').textContent = state.cards.length;
    document.getElementById('catCountBadge').textContent = state.categories.length;
  } catch (err) {
    showToast('Failed to load dashboard data: ' + err.message, 'error');
  }
}

// RENDER KPIS
function renderKPIs() {
  document.getElementById('kpiTotalCards').textContent = state.stats.total_cards || state.cards.length;
  document.getElementById('kpiTotalCats').textContent = state.stats.total_categories || state.categories.length;
  document.getElementById('kpiTotalUsers').textContent = state.stats.total_users || state.users.length;
  document.getElementById('kpiTotalConcepts').textContent = state.stats.total_attributes || (state.cards.length * 6);
}

// RENDER DISTRIBUTION
function renderDistribution() {
  const container = document.getElementById('categoryDistributionList');
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

function filterCards() {
  const query = (document.getElementById('cardSearchInput').value || '').toLowerCase();
  const selectedCat = document.getElementById('categoryFilterSelect').value;
  const container = document.getElementById('cardsContainer');

  const filtered = state.cards.filter(c => {
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

  container.innerHTML = filtered.map(c => {
    const cat = state.categories.find(k => k.id === c.category_id) || { name_en: 'General' };
    const attrs = c.attributes || {};
    const attrList = c.attributes_list || Object.values(attrs);
    const uploadedImagesCount = (c.image_url ? 1 : 0) + attrList.filter(a => a.image_url || a.attribute_image).length;
    const subnames = [c.title_ta, c.title_hi, c.title_ml].filter(Boolean).join(' • ');

    return `
      <div class="flashcard-item">
        <div class="card-img-wrap">
          <img src="${c.image_url || 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80'}" alt="${escapeHtml(c.title_en || c.name)}" onerror="this.src='https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80'">
          <span class="card-category-badge">${escapeHtml(cat.name_en)}</span>
        </div>
        <div class="card-content">
          <h4 class="card-title">${escapeHtml(c.title_en || c.name)}</h4>
          ${c.subcategory ? `<span class="card-subcategory-tag"><i class="fa-solid fa-layer-group"></i> ${escapeHtml(c.subcategory)}</span>` : ''}
          <p class="card-subtitles" style="margin-top:6px;">${escapeHtml(subnames || 'Multi-lingual ready')}</p>
          <div class="concept-count-tag" style="margin-top:8px;">
            <i class="fa-solid fa-images"></i>
            <span>${uploadedImagesCount}/7 Images Loaded</span>
          </div>
        </div>
        <div class="card-actions-bar">
          <button class="btn-icon" title="Edit Flashcard (7 Images)" onclick="openEditCardModal(${c.id})">
            <i class="fa-solid fa-pen-to-square"></i>
          </button>
          <button class="btn-icon delete" title="Delete Flashcard" onclick="deleteCard(${c.id}, '${escapeHtml(c.title_en || c.name)}')">
            <i class="fa-solid fa-trash"></i>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

// RENDER CATEGORIES
function renderCategories() {
  const container = document.getElementById('categoriesContainer');
  if (state.categories.length === 0) {
    container.innerHTML = '<p class="text-muted">No categories available.</p>';
    return;
  }

  const iconMap = {
    pets: 'fa-paw',
    eco: 'fa-seedling',
    directions_car: 'fa-car',
    school: 'fa-graduation-cap',
    sports_soccer: 'fa-futbol',
    palette: 'fa-palette',
    music_note: 'fa-music',
    restaurant: 'fa-utensils',
  };

  container.innerHTML = state.categories.map(cat => {
    const iconClass = iconMap[cat.icon_name] || 'fa-folder';
    const subnames = [cat.name_ta, cat.name_hi, cat.name_ml].filter(Boolean).join(' • ');

    return `
      <div class="category-card" style="border-left: 4px solid ${escapeHtml(cat.color_hex || '#4CAF50')};">
        <div class="category-card-header">
          <div class="category-icon-box" style="background-color: ${escapeHtml(cat.color_hex || '#E8F5E9')}; color: #1E293B;">
            <i class="fa-solid ${iconClass}"></i>
          </div>
          <div>
            <h4 class="category-title">${escapeHtml(cat.name_en)}</h4>
            <p class="category-subnames">${escapeHtml(subnames || 'Collection Deck')}</p>
            ${cat.description ? `<p style="font-size:12px; color:var(--text-muted); margin-top:4px;">${escapeHtml(cat.description)}</p>` : ''}
          </div>
        </div>
        <div class="category-footer">
          <span class="category-count"><i class="fa-solid fa-clone"></i> ${cat.card_count || 0} Flashcards</span>
          <div style="display:flex; gap:6px;">
            <button class="btn-icon" title="Edit Category" onclick="openEditCategoryModal(${cat.id})"><i class="fa-solid fa-pen"></i></button>
            <button class="btn-icon delete" title="Delete Category" onclick="deleteCategory(${cat.id}, '${escapeHtml(cat.name_en)}')"><i class="fa-solid fa-trash"></i></button>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

// RENDER 6-CONCEPT MATRIX
function renderConceptsMatrix() {
  const tbody = document.getElementById('conceptsMatrixBody');
  const lang = state.activeMatrixLang;

  if (state.cards.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:32px;">No cards found to display in matrix.</td></tr>';
    return;
  }

  tbody.innerHTML = state.cards.map(c => {
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

// IMAGE SLOT UPLOAD & PREVIEW HANDLERS
function triggerImageSlotUpload(slot) {
  const fileInput = document.getElementById(`file_slot_${slot}`);
  if (fileInput) fileInput.click();
}

async function uploadImageSlot(slot) {
  const fileInput = document.getElementById(`file_slot_${slot}`);
  if (!fileInput || !fileInput.files || fileInput.files.length === 0) return;
  await uploadImageFile(slot, fileInput.files[0]);
}

async function uploadImageFile(slot, file) {
  if (!file) return;

  const formData = new FormData();
  formData.append('file', file);

  try {
    showToast(`Uploading image for ${slot === 'main' ? 'Trigger Image' : slot}...`, 'info');
    const res = await fetch('/api/admin/upload-image', {
      method: 'POST',
      body: formData,
    });

    if (!res.ok) throw new Error('Image upload failed on server');
    const data = await res.json();

    if (slot === 'main') {
      document.getElementById('cardFormImageUrl').value = data.image_url;
      updateSlotPreview('main');
    } else {
      document.getElementById(`${slot}_image`).value = data.image_url;
      const btnTxt = document.getElementById(`btn_txt_${slot}`);
      if (btnTxt) btnTxt.textContent = 'Replace Image';
      updateSlotPreview(slot);
    }

    showToast(`Image uploaded successfully for ${slot === 'main' ? 'Trigger Image' : slot}!`, 'success');
  } catch (err) {
    showToast(`Failed to upload image: ${err.message}`, 'error');
  }
}

function updateSlotPreview(slot) {
  if (slot === 'main') {
    const url = (document.getElementById('cardFormImageUrl').value || '').trim();
    const img = document.getElementById('preview_img_main');
    const txt = document.getElementById('preview_txt_main');
    if (url) {
      img.src = url;
      img.style.display = 'block';
      if (txt) txt.style.display = 'none';
    } else {
      img.style.display = 'none';
      if (txt) txt.style.display = 'block';
    }
  } else {
    const url = (document.getElementById(`${slot}_image`).value || '').trim();
    const img = document.getElementById(`preview_img_${slot}`);
    const ico = document.getElementById(`preview_ico_${slot}`);
    if (url) {
      img.src = url;
      img.style.display = 'block';
      if (ico) ico.style.display = 'none';
    } else {
      img.style.display = 'none';
      if (ico) ico.style.display = 'block';
    }
  }
}

// POPULATE DROPDOWNS
function populateCategoryDropdowns() {
  const filterSelect = document.getElementById('categoryFilterSelect');
  const formSelect = document.getElementById('cardFormCategory');

  const options = state.categories.map(c => `<option value="${c.id}">${escapeHtml(c.name_en)} (${escapeHtml(c.name_ta || '')})</option>`).join('');

  filterSelect.innerHTML = '<option value="">All Categories</option>' + options;
  formSelect.innerHTML = options;
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

  document.getElementById('cardFormId').value = card.id;
  document.getElementById('cardFormCategory').value = card.category_id;
  document.getElementById('cardFormSubcategory').value = card.subcategory || '';
  document.getElementById('cardFormTitleEn').value = card.title_en || card.name || '';
  document.getElementById('cardFormTitleTa').value = card.title_ta || '';
  document.getElementById('cardFormTitleHi').value = card.title_hi || '';
  document.getElementById('cardFormTitleMl').value = card.title_ml || '';
  document.getElementById('cardFormImageUrl').value = card.image_url || card.trigger_image || '';

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

  const attributesList = [];
  const attributesDict = {};

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

  const payload = {
    category_id: parseInt(document.getElementById('cardFormCategory').value, 10),
    subcategory: document.getElementById('cardFormSubcategory').value.trim(),
    name: document.getElementById('cardFormTitleEn').value.trim(),
    title_en: document.getElementById('cardFormTitleEn').value.trim(),
    title_ta: document.getElementById('cardFormTitleTa').value.trim(),
    title_hi: document.getElementById('cardFormTitleHi').value.trim(),
    title_ml: document.getElementById('cardFormTitleMl').value.trim(),
    image_url: document.getElementById('cardFormImageUrl').value.trim(),
    trigger_image: document.getElementById('cardFormImageUrl').value.trim(),
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

    showToast(isEdit ? 'Flashcard updated with 7 images!' : 'Flashcard created with 7 images!', 'success');
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
function openNewCategoryModal() {
  document.getElementById('catForm').reset();
  document.getElementById('catFormId').value = '';
  if (document.getElementById('catFormDesc')) document.getElementById('catFormDesc').value = '';
  document.getElementById('catFormColor').value = '#E8F5E9';
  document.getElementById('colorHexDisplay').textContent = '#E8F5E9';
  document.getElementById('catModalTitle').textContent = 'Create New Category';
  document.getElementById('saveCatBtn').textContent = 'Create Category';
  openModal('catModal');
}

function openEditCategoryModal(catId) {
  const cat = state.categories.find(c => c.id === catId);
  if (!cat) return;

  document.getElementById('catFormId').value = cat.id;
  document.getElementById('catFormNameEn').value = cat.name_en || '';
  document.getElementById('catFormNameTa').value = cat.name_ta || '';
  document.getElementById('catFormNameHi').value = cat.name_hi || '';
  document.getElementById('catFormNameMl').value = cat.name_ml || '';
  if (document.getElementById('catFormDesc')) document.getElementById('catFormDesc').value = cat.description || '';
  document.getElementById('catFormIcon').value = cat.icon_name || 'pets';
  document.getElementById('catFormColor').value = cat.color_hex || '#E8F5E9';
  document.getElementById('colorHexDisplay').textContent = (cat.color_hex || '#E8F5E9').toUpperCase();

  document.getElementById('catModalTitle').textContent = `Edit Category: ${cat.name_en}`;
  document.getElementById('saveCatBtn').textContent = 'Save Changes';
  openModal('catModal');
}

async function handleCategorySubmit(e) {
  e.preventDefault();
  const id = document.getElementById('catFormId').value;
  const isEdit = Boolean(id);

  const payload = {
    name_en: document.getElementById('catFormNameEn').value.trim(),
    name_ta: document.getElementById('catFormNameTa').value.trim(),
    name_hi: document.getElementById('catFormNameHi').value.trim(),
    name_ml: document.getElementById('catFormNameMl').value.trim(),
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
      throw new Error(errData.detail || 'Server error while saving category');
    }

    showToast(isEdit ? 'Category updated successfully!' : 'Category created successfully!', 'success');
    closeModal('catModal');
    loadDashboardData();
  } catch (err) {
    showToast('Failed to save category: ' + err.message, 'error');
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
