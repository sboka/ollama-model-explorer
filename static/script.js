// State
let allModels = [];
let filteredModels = [];
let capabilities = new Set();
let families = new Set();
let servers = new Set();
let activeCapabilities = new Set();
let activeFamilies = new Set();
let activeServers = new Set();
let currentView = 'grid';
let currentSort = 'name-asc';
let matchAll = false;

// DOM Elements
const serverInputsContainer = document.getElementById('serverInputs');
const addServerBtn = document.getElementById('addServerBtn');
const fetchBtn = document.getElementById('fetchBtn');
const serverStatus = document.getElementById('serverStatus');
const filtersPanel = document.getElementById('filtersPanel');
const resultsPanel = document.getElementById('resultsPanel');
const initialState = document.getElementById('initialState');
const loadingState = document.getElementById('loadingState');
const searchInput = document.getElementById('searchInput');
const capabilityFilters = document.getElementById('capabilityFilters');
const familyFilters = document.getElementById('familyFilters');
const serverFilters = document.getElementById('serverFilters');
const modelGrid = document.getElementById('modelGrid');
const resultsCount = document.getElementById('resultsCount');
const sortSelect = document.getElementById('sortSelect');
const matchAllToggle = document.getElementById('matchAllToggle');
const viewToggle = document.querySelector('.view-toggle');
const clearAllFilters = document.getElementById('clearAllFilters');

// Server Input Management
function addServerRow(value = '') {
    const row = document.createElement('div');
    row.className = 'server-row';
    row.innerHTML = `
                <input type="text" class="server-input" placeholder="http://hostname:11434" value="${value}">
                <button class="btn btn-icon btn-danger remove-server" title="Remove server">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            `;
    serverInputsContainer.appendChild(row);
    updateRemoveButtons();
}

function updateRemoveButtons() {
    const rows = serverInputsContainer.querySelectorAll('.server-row');
    rows.forEach((row, index) => {
        const removeBtn = row.querySelector('.remove-server');
        removeBtn.style.visibility = rows.length > 1 ? 'visible' : 'hidden';
    });
}

function getServerUrls() {
    const inputs = serverInputsContainer.querySelectorAll('.server-input');
    return Array.from(inputs)
        .map(input => input.value.trim())
        .filter(url => url.length > 0);
}

addServerBtn.addEventListener('click', () => addServerRow());

serverInputsContainer.addEventListener('click', (e) => {
    if (e.target.closest('.remove-server')) {
        const row = e.target.closest('.server-row');
        row.remove();
        updateRemoveButtons();
    }
});

// Fetch Models
async function fetchModels() {
    const serverUrls = getServerUrls();
    if (serverUrls.length === 0) {
        alert('Please enter at least one server URL');
        return;
    }

    initialState.style.display = 'none';
    loadingState.style.display = 'flex';
    filtersPanel.style.display = 'none';
    resultsPanel.style.display = 'none';
    serverStatus.innerHTML = '';

    try {
        const response = await fetch('/api/fetch', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ servers: serverUrls })
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Failed to fetch models');
        }

        allModels = data.models || [];

        // Update server status
        serverStatus.innerHTML = (data.server_results || []).map(result => `
                    <span class="server-badge ${result.success ? 'success' : 'error'}">
                        <span class="dot"></span>
                        ${result.server} ${result.success ? `(${result.model_count} models)` : `- ${result.error}`}
                    </span>
                `).join('');

        // Build filter options
        capabilities = new Set(data.capabilities || []);
        families = new Set(data.families || []);
        servers = new Set(allModels.map(m => m.server));

        // Reset filters
        activeCapabilities.clear();
        activeFamilies.clear();
        activeServers.clear();

        renderFilters();
        applyFilters();

        loadingState.style.display = 'none';
        if (allModels.length > 0) {
            filtersPanel.style.display = 'block';
            resultsPanel.style.display = 'block';
        } else {
            initialState.style.display = 'block';
            initialState.innerHTML = `
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M12 2a10 10 0 100 20 10 10 0 000-20z"/>
                        </svg>
                        <h3>No Models Found</h3>
                        <p>No models were found on the connected servers.</p>
                    `;
        }

    } catch (error) {
        loadingState.style.display = 'none';
        initialState.style.display = 'block';
        initialState.innerHTML = `
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="color: var(--accent-danger);">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <h3>Error Fetching Models</h3>
                    <p>${error.message}</p>
                `;
    }
}

fetchBtn.addEventListener('click', fetchModels);

// Render Filters - FIXED: Using button elements instead of label with checkbox
function renderFilters() {
    capabilityFilters.innerHTML = Array.from(capabilities).sort().map(cap => `
                <button type="button" class="filter-chip" data-filter="capability" data-value="${escapeHtml(cap)}">
                    ${escapeHtml(cap)}
                </button>
            `).join('');

    familyFilters.innerHTML = Array.from(families).sort().map(family => `
                <button type="button" class="filter-chip" data-filter="family" data-value="${escapeHtml(family)}">
                    ${escapeHtml(family)}
                </button>
            `).join('');

    serverFilters.innerHTML = Array.from(servers).map(server => {
        let displayName;
        try {
            displayName = new URL(server).host;
        } catch {
            displayName = server;
        }
        return `
                    <button type="button" class="filter-chip" data-filter="server" data-value="${escapeHtml(server)}">
                        ${escapeHtml(displayName)}
                    </button>
                `;
    }).join('');

    updateFilterCounts();
}

// Update filter count badges
function updateFilterCounts() {
    const capCount = document.getElementById('capabilityCount');
    const famCount = document.getElementById('familyCount');
    const srvCount = document.getElementById('serverCount');

    if (activeCapabilities.size > 0) {
        capCount.textContent = activeCapabilities.size;
        capCount.style.display = 'inline';
    } else {
        capCount.style.display = 'none';
    }

    if (activeFamilies.size > 0) {
        famCount.textContent = activeFamilies.size;
        famCount.style.display = 'inline';
    } else {
        famCount.style.display = 'none';
    }

    if (activeServers.size > 0) {
        srvCount.textContent = activeServers.size;
        srvCount.style.display = 'inline';
    } else {
        srvCount.style.display = 'none';
    }
}

// Filter Logic
function applyFilters() {
    const searchTerm = searchInput.value.toLowerCase().trim();

    filteredModels = allModels.filter(model => {
        // Search filter
        if (searchTerm && !model.name.toLowerCase().includes(searchTerm)) {
            return false;
        }

        // Capability filter
        if (activeCapabilities.size > 0) {
            const modelCaps = model.capabilities || [];
            if (matchAll) {
                // All selected capabilities must be present
                for (const cap of activeCapabilities) {
                    if (!modelCaps.includes(cap)) {
                        return false;
                    }
                }
            } else {
                // At least one selected capability must be present
                let hasAny = false;
                for (const cap of activeCapabilities) {
                    if (modelCaps.includes(cap)) {
                        hasAny = true;
                        break;
                    }
                }
                if (!hasAny) return false;
            }
        }

        // Family filter
        if (activeFamilies.size > 0) {
            if (!activeFamilies.has(model.family)) {
                return false;
            }
        }

        // Server filter
        if (activeServers.size > 0) {
            if (!activeServers.has(model.server)) {
                return false;
            }
        }

        return true;
    });

    sortModels();
    renderModels();
    updateFilterCounts();
}

// Sorting
function sortModels() {
    filteredModels.sort((a, b) => {
        switch (currentSort) {
            case 'name-asc':
                return a.name.localeCompare(b.name);
            case 'name-desc':
                return b.name.localeCompare(a.name);
            case 'size-asc':
                return (a.size || 0) - (b.size || 0);
            case 'size-desc':
                return (b.size || 0) - (a.size || 0);
            case 'modified-desc':
                return new Date(b.modified_at || 0) - new Date(a.modified_at || 0);
            case 'modified-asc':
                return new Date(a.modified_at || 0) - new Date(b.modified_at || 0);
            default:
                return 0;
        }
    });
}

// Render Models
function renderModels() {
    resultsCount.innerHTML = `Showing <strong>${filteredModels.length}</strong> of <strong>${allModels.length}</strong> models`;

    if (filteredModels.length === 0) {
        modelGrid.innerHTML = `
                    <div class="empty-state">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M12 2a10 10 0 100 20 10 10 0 000-20z"/>
                        </svg>
                        <h3>No models match your filters</h3>
                        <p>Try adjusting your search or filter criteria.</p>
                    </div>
                `;
        return;
    }

    modelGrid.className = currentView === 'grid' ? 'model-grid' : 'model-list';
    modelGrid.innerHTML = filteredModels.map(model => `
                <div class="model-card">
                    <div class="model-card-header">
                        <div class="model-name">${escapeHtml(model.name)}</div>
                        <div class="model-size">${model.size_formatted || 'N/A'}</div>
                    </div>
                    <div class="model-meta">
                        ${model.parameters ? `
                            <span class="model-meta-item">
                                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                                </svg>
                                ${escapeHtml(model.parameters)}
                            </span>
                        ` : ''}
                        ${model.quantization ? `
                            <span class="model-meta-item">
                                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"/>
                                </svg>
                                ${escapeHtml(model.quantization)}
                            </span>
                        ` : ''}
                        ${model.family ? `
                            <span class="model-meta-item">
                                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>
                                </svg>
                                ${escapeHtml(model.family)}
                            </span>
                        ` : ''}
                        ${model.max_context ? `
                            <span class="model-meta-item">
                                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h12M4 18h8"/>
                                </svg>
                                ${escapeHtml(model.max_context)}K
                            </span>
                        ` : ''}
                    </div>
                    <div class="model-capabilities">
                        ${(model.capabilities || []).map(cap => `
                            <span class="capability-tag capability-${getCapabilityClass(cap)}">${escapeHtml(cap)}</span>
                        `).join('')}
                        ${(model.capabilities || []).length === 0 ? '<span class="capability-tag capability-default">no capabilities</span>' : ''}
                    </div>
                    <div class="model-server">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2"/>
                        </svg>
                        ${escapeHtml(model.server)}
                    </div>
                </div>
            `).join('');
}

function getCapabilityClass(cap) {
    const known = ['completion', 'vision', 'tools', 'embedding', 'insert'];
    const lowerCap = cap.toLowerCase();
    return known.includes(lowerCap) ? lowerCap : 'default';
}

function escapeHtml(text) {
    if (text === null || text === undefined) return '';
    const div = document.createElement('div');
    div.textContent = String(text);
    return div.innerHTML;
}

// Event Listeners
searchInput.addEventListener('input', applyFilters);

// FIXED: Filter chip click handler - now properly handles button clicks
document.addEventListener('click', (e) => {
    const chip = e.target.closest('.filter-chip');
    if (chip && chip.dataset.filter) {
        e.preventDefault();

        chip.classList.toggle('active');
        const filterType = chip.dataset.filter;
        const value = chip.dataset.value;

        let activeSet;
        switch (filterType) {
            case 'capability':
                activeSet = activeCapabilities;
                break;
            case 'family':
                activeSet = activeFamilies;
                break;
            case 'server':
                activeSet = activeServers;
                break;
        }

        if (activeSet) {
            if (chip.classList.contains('active')) {
                activeSet.add(value);
            } else {
                activeSet.delete(value);
            }
            applyFilters();
        }
    }
});

// Clear all filters
clearAllFilters.addEventListener('click', () => {
    activeCapabilities.clear();
    activeFamilies.clear();
    activeServers.clear();
    searchInput.value = '';

    // Remove active class from all chips
    document.querySelectorAll('.filter-chip.active').forEach(chip => {
        chip.classList.remove('active');
    });

    applyFilters();
});

sortSelect.addEventListener('change', (e) => {
    currentSort = e.target.value;
    sortModels();
    renderModels();
});

matchAllToggle.addEventListener('change', (e) => {
    matchAll = e.target.checked;
    applyFilters();
});

viewToggle.addEventListener('click', (e) => {
    const btn = e.target.closest('button');
    if (btn && btn.dataset.view) {
        viewToggle.querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentView = btn.dataset.view;
        renderModels();
    }
});

// Keyboard shortcut for search
document.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        searchInput.focus();
    }
    // ESC to clear search
    if (e.key === 'Escape' && document.activeElement === searchInput) {
        searchInput.value = '';
        searchInput.blur();
        applyFilters();
    }
});