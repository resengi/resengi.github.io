/* ============================================
   Site JavaScript
   Navigation, Tabs, CSV loading
   ============================================ */

// --- HTML escaping (used when rendering CSV data into the DOM) ---
const escapeHtml = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  }[c]));

document.addEventListener('DOMContentLoaded', () => {
  // --- Mobile Navigation Toggle ---
  const toggle = document.querySelector('.nav-toggle');
  const links = document.querySelector('.nav-links');

  if (toggle && links) {
    toggle.addEventListener('click', () => {
      const isOpen = links.classList.toggle('open');
      toggle.setAttribute('aria-expanded', String(isOpen));
    });

    // Close menu when a link is clicked
    links.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => {
        links.classList.remove('open');
        toggle.setAttribute('aria-expanded', 'false');
      });
    });
  }

  // --- Tabs with full ARIA keyboard support ---
  const tablist = document.querySelector('[role="tablist"]');
  if (tablist) {
    const tabs = Array.from(tablist.querySelectorAll('[role="tab"]'));

    function activateTab(tab) {
      tabs.forEach((t) => {
        const selected = t === tab;
        t.setAttribute('aria-selected', String(selected));
        t.setAttribute('tabindex', selected ? '0' : '-1');
        t.classList.toggle('active', selected);
        const panel = document.getElementById(t.getAttribute('aria-controls'));
        if (panel) panel.classList.toggle('active', selected);
      });
      tab.focus();
    }

    tabs.forEach((tab) => {
      tab.addEventListener('click', () => activateTab(tab));
      tab.addEventListener('keydown', (e) => {
        const i = tabs.indexOf(e.target);
        if (i < 0) return;
        if (e.key === 'ArrowRight') {
          e.preventDefault();
          activateTab(tabs[(i + 1) % tabs.length]);
        } else if (e.key === 'ArrowLeft') {
          e.preventDefault();
          activateTab(tabs[(i - 1 + tabs.length) % tabs.length]);
        } else if (e.key === 'Home') {
          e.preventDefault();
          activateTab(tabs[0]);
        } else if (e.key === 'End') {
          e.preventDefault();
          activateTab(tabs[tabs.length - 1]);
        }
      });
    });
  }

  // --- CSV Loading (financials page) ---
  if (document.getElementById('expenses-table')) {
    loadCSV('data/expenses.csv', 'expenses-table', 'expense-stats');
  }
});


// --- Simple CSV Parser (handles basic quoted fields; no escaped quotes or embedded newlines) ---
function parseCSV(text) {
  const lines = text.trim().split('\n');
  const headers = lines[0].split(',').map((h) => h.trim());
  const rows = [];

  for (let i = 1; i < lines.length; i++) {
    const values = [];
    let current = '';
    let inQuotes = false;

    for (let j = 0; j < lines[i].length; j++) {
      const char = lines[i][j];
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        values.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    values.push(current.trim());

    if (values.length === headers.length) {
      const row = {};
      headers.forEach((h, idx) => (row[h] = values[idx]));
      rows.push(row);
    }
  }

  return { headers, rows };
}


// --- Load CSV and Render Table ---
async function loadCSV(url, tableId, statsId) {
  try {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Failed to load ${url}`);
    const text = await response.text();
    const { headers, rows } = parseCSV(text);

    renderTable(tableId, headers, rows);

    if (statsId) {
      renderExpenseStats(statsId, headers, rows);
    }
  } catch (err) {
    const table = document.getElementById(tableId);
    if (table) {
      table.innerHTML = `<p class="loading-state">
        Financial data will appear here once the expenses CSV is populated.
      </p>`;
    }
  }
}


// --- Render HTML Table from CSV Data ---
function renderTable(tableId, headers, rows) {
  const container = document.getElementById(tableId);
  if (!container || rows.length === 0) return;

  // Determine which columns are monetary vs percentage
  const moneyColumns = headers.filter(
    (h) => h.toLowerCase().includes('amount') || h.toLowerCase().includes('cost')
  );

  const percentColumns = headers.filter(
    (h) => h.toLowerCase().includes('%') || h.toLowerCase().includes('percent')
  );

  let html = '<div class="data-table-wrapper"><table class="data-table"><thead><tr>';
  headers.forEach((h) => {
    const cls = moneyColumns.includes(h)
      ? ' class="amount"'
      : percentColumns.includes(h)
      ? ' class="percent"'
      : '';
    html += `<th${cls}>${escapeHtml(h)}</th>`;
  });
  html += '</tr></thead><tbody>';

  rows.forEach((row) => {
    html += '<tr>';
    headers.forEach((h) => {
      let value = row[h] || '';
      let cls = '';

      if (moneyColumns.includes(h) && value) {
        const num = parseFloat(value);
        if (!isNaN(num)) {
          value = '$' + num.toFixed(2);
          cls = ' class="amount"';
        }
      } else if (percentColumns.includes(h) && value) {
        const num = parseFloat(value);
        if (!isNaN(num)) {
          value = Math.round(num * 100) + '%';
          cls = ' class="percent"';
        }
      }

      html += `<td${cls}>${escapeHtml(value)}</td>`;
    });
    html += '</tr>';
  });

  html += '</tbody></table></div>';
  container.innerHTML = html;
}


// --- Render Summary Stats (expenses) ---
function renderExpenseStats(statsId, headers, rows) {
  const container = document.getElementById(statsId);
  if (!container) return;

  const companyAmounts = rows
    .map((r) => parseFloat(r['Company Amount'] || r['Full Amount'] || 0))
    .filter((n) => !isNaN(n));

  const total = companyAmounts.reduce((sum, n) => sum + n, 0);
  // Filter empty strings so rows with missing dates don't inflate the month count
  const months =
    new Set(
      rows.map((r) => (r['Date'] || '').substring(0, 7)).filter(Boolean)
    ).size || 1;
  const monthlyAvg = total / months;

  container.innerHTML = `
    <div class="stats-row">
      <div class="stat-card glass-card">
        <span class="stat-value">$${total.toFixed(2)}</span>
        <span class="stat-label">Total Company Expenses</span>
      </div>
      <div class="stat-card glass-card">
        <span class="stat-value">$${monthlyAvg.toFixed(2)}</span>
        <span class="stat-label">Monthly Average</span>
      </div>
      <div class="stat-card glass-card">
        <span class="stat-value">${rows.length}</span>
        <span class="stat-label">Transactions</span>
      </div>
    </div>
  `;
}