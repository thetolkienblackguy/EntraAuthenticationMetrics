// Data is injected as reportData
const users = reportData;

let renderedUsers = [];
let selectedId = null;

const STALE_DAYS = 180;

/* ---------- Helpers ---------- */

function isTrue(v) { return String(v).toUpperCase() === "TRUE"; }

function esc(v) {
    return String(v == null ? "" : v)
        .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function isPRMFA(u) { return String(u.PRMFAStatus).toLowerCase() === "enabled"; }

function userMethods(u) { return u.Methods || []; }

function isPasskey(m) { return !!m.PasskeyClass; }

function hasPasskey(u) { return userMethods(u).some(isPasskey); }

function registeredWithin(u, days) {
    const cutoff = Date.now() - days * 86400000;
    return userMethods(u).some(m => {
        const d = parseDate(m.Registered);
        return d && d.getTime() >= cutoff;
    });
}

function windowDays() {
    const v = document.getElementById("reg-window").value;
    return v === "all" ? null : parseInt(v, 10);
}

// Methods to display for a user, scoped to the active registration window
function visibleMethods(u) {
    const days = windowDays();
    if (!days) { return userMethods(u); }
    const cutoff = Date.now() - days * 86400000;
    return userMethods(u).filter(m => {
        const d = parseDate(m.Registered);
        return d && d.getTime() >= cutoff;
    });
}

function pctOf(count, total) {
    if (!total) { return 0; }
    return parseFloat(((count / total) * 100).toFixed(1));
}

function parseDate(v) {
    if (!v) { return null; }
    const d = new Date(v);
    return isNaN(d.getTime()) ? null : d;
}

function relTime(d) {
    const days = Math.floor((Date.now() - d.getTime()) / 86400000);
    if (days < 0) { return { text: "in future", stale: false }; }
    if (days === 0) { return { text: "today", stale: false }; }
    if (days < 30) { return { text: days + "d ago", stale: false }; }
    if (days < 365) { return { text: Math.floor(days / 30) + " mo ago", stale: days > STALE_DAYS }; }
    return { text: (days / 365).toFixed(1) + " yr ago", stale: true };
}

function dateCol(label, iso, nullText) {
    const d = parseDate(iso);
    if (!d) {
        return `<div class="method-date"><div class="d-label">${label}</div><div class="d-val never">${nullText}</div></div>`;
    }
    const r = relTime(d);
    return `<div class="method-date">
        <div class="d-label">${label}</div>
        <div class="d-val">${d.toISOString().slice(0, 10)}</div>
        <div class="d-rel${r.stale ? " stale" : ""}">${r.text}</div>
    </div>`;
}

/* ---------- Summary cards ---------- */

function card(label, count, sub, strengthClass) {
    const cls = "summary-card" + (strengthClass ? " " + strengthClass : "");
    const subHtml = sub ? `<div class="sub">${sub}</div>` : "";
    return `<div class="${cls}"><h3>${label}</h3><div class="count">${count}</div>${subHtml}</div>`;
}

function renderSummaryCards() {
    const total = users.length;
    const prmfa = users.filter(isPRMFA).length;
    const passkey = users.filter(hasPasskey).length;
    const mfaReg = users.filter(u => isTrue(u.IsMfaRegistered)).length;

    document.getElementById("summary-cards").innerHTML = [
        card("Total Users", total, "", ""),
        card("PRMFA Enabled", prmfa, `${pctOf(prmfa, total)}% of users`, "strong"),
        card("Passkey Users", passkey, `${pctOf(passkey, total)}% of users`, "strong"),
        card("MFA Registered", mfaReg, `${pctOf(mfaReg, total)}% of users`, "standard")
    ].join("");
}

/* ---------- User list (master) ---------- */

function filteredUsers() {
    const term = document.getElementById("user-search").value.toLowerCase();
    const filter = document.getElementById("user-filter").value;
    const regWindow = document.getElementById("reg-window").value;
    const sort = document.getElementById("user-sort").value;

    let list = users.filter(u => {
        if (!String(u.User).toLowerCase().includes(term)) { return false; }
        if (regWindow !== "all" && !registeredWithin(u, parseInt(regWindow, 10))) { return false; }
        switch (filter) {
            case "prmfa": return isPRMFA(u);
            case "noPrmfa": return !isPRMFA(u);
            case "passkey": return hasPasskey(u);
            case "none": return userMethods(u).length === 0;
            default: return true;
        }
    });

    list = list.slice().sort((a, b) => {
        if (sort === "methods") { return userMethods(b).length - userMethods(a).length; }
        if (sort === "prmfa") { return (isPRMFA(b) ? 1 : 0) - (isPRMFA(a) ? 1 : 0); }
        return String(a.User).localeCompare(String(b.User));
    });

    return list;
}

function renderUserList() {
    renderedUsers = filteredUsers();
    const listEl = document.getElementById("user-list");

    const items = renderedUsers.map(u => {
        const selected = u.Id === selectedId ? " selected" : "";
        const prmfaCls = isPRMFA(u) ? " prmfa" : "";
        return `<div class="user-list-item${prmfaCls}${selected}" data-id="${esc(u.Id)}">
            <div class="item-name">${esc(u.User)}</div>
            <div class="item-meta">
                <span>${visibleMethods(u).length} method(s)</span>
                <span class="status-pill ${isPRMFA(u) ? "enabled" : "disabled"}">${isPRMFA(u) ? "PRMFA" : "No PRMFA"}</span>
            </div>
        </div>`;
    }).join("");

    listEl.innerHTML = `<div class="list-count">${renderedUsers.length} of ${users.length} users</div>` + items;

    if (!renderedUsers.length) {
        document.getElementById("detail-pane").innerHTML = '<div class="detail-empty">No users match the current filter</div>';
    } else if (!renderedUsers.some(u => u.Id === selectedId)) {
        selectUser(renderedUsers[0].Id);
    } else {
        selectUser(selectedId);
    }
}

/* ---------- Detail pane ---------- */

function chip(label, on, cls) {
    return `<span class="chip ${on ? (cls || "on") : ""}">${label}</span>`;
}

function methodCard(m) {
    const strength = m.Strength || "standard";
    const metaParts = [m.Model, m.Detail].filter(Boolean).map(esc);
    const meta = metaParts.length ? `<div class="method-card-meta">${metaParts.join(" &middot; ")}</div>` : "";
    return `<div class="method-card ${strength}">
        <div class="method-card-top">
            <div>
                <div class="method-card-cat">${esc(m.Category)}</div>
                <div class="method-card-name">${esc(m.Name)}</div>
            </div>
            <span class="strength-badge ${strength}">${strength}</span>
        </div>
        ${meta}
        <div class="method-dates">
            ${dateCol("Registered", m.Registered, "&mdash;")}
            ${dateCol("Last used", m.LastUsed, "Never")}
        </div>
    </div>`;
}

function renderDetail(u) {
    const groups = [
        { key: "strong", label: "Strong (Phishing-Resistant)" },
        { key: "standard", label: "Standard" },
        { key: "weak", label: "Legacy" }
    ];

    let body = "";
    const days = windowDays();
    const methods = visibleMethods(u);

    if (!methods.length) {
        body = `<div class="detail-empty">${days ? "No methods registered in the last " + days + " days" : "No authentication methods registered"}</div>`;
    } else {
        body = groups.map(g => {
            const cards = methods.filter(m => (m.Strength || "standard") === g.key);
            if (!cards.length) { return ""; }
            return `<div class="method-group">
                <div class="method-group-title">${g.label}<span class="group-count">${cards.length}</span></div>
                ${cards.map(methodCard).join("")}
            </div>`;
        }).join("");
    }

    const chips = [
        chip("MFA Registered", isTrue(u.IsMfaRegistered)),
        chip("MFA Capable", isTrue(u.IsMfaCapable)),
        chip("Passwordless Capable", isTrue(u.IsPasswordlessCapable)),
        chip("SSPR Registered", isTrue(u.IsSsprRegistered)),
        chip("Admin", isTrue(u.IsAdmin), "info"),
        chip(`Type: ${esc(u.UserType || "unknown")}`, true, "info"),
        chip(`Default: ${esc(u.DefaultMfaMethod || "none")}`, true, "info")
    ].join("");

    document.getElementById("detail-pane").innerHTML = `
        <div class="detail-header">
            <div class="detail-title-row">
                <div class="detail-title">${esc(u.User)}</div>
                <span class="status-pill ${isPRMFA(u) ? "enabled" : "disabled"}">${isPRMFA(u) ? "PRMFA Enabled" : "No PRMFA"}</span>
            </div>
            <div class="chip-row">${chips}</div>
        </div>
        ${days ? `<div class="detail-note">Showing methods registered in the last ${days} days (${methods.length} of ${userMethods(u).length})</div>` : ""}
        ${body}`;
}

function selectUser(id) {
    selectedId = id;
    document.querySelectorAll(".user-list-item").forEach(el => {
        el.classList.toggle("selected", el.getAttribute("data-id") === id);
    });
    const u = users.find(x => x.Id === id);
    if (u) { renderDetail(u); }
}

/* ---------- Statistics ---------- */

function ringHtml(label, count, total, cls) {
    const p = pctOf(count, total);
    const r = 54;
    const circ = 2 * Math.PI * r;
    const off = circ * (1 - Math.min(p, 100) / 100);
    return `<div class="kpi-ring">
        <div class="ring-wrap">
            <svg class="ring-svg" viewBox="0 0 128 128">
                <circle class="ring-track" cx="64" cy="64" r="${r}"></circle>
                <circle class="ring-fill ${cls}" cx="64" cy="64" r="${r}" style="stroke-dasharray:${circ.toFixed(1)}; stroke-dashoffset:${off.toFixed(1)}"></circle>
            </svg>
            <div class="ring-center">
                <div class="ring-pct">${p}%</div>
                <div class="ring-count">${count} of ${total}</div>
            </div>
        </div>
        <div class="ring-label">${esc(label)}</div>
    </div>`;
}

function barRow(label, valueText, widthPct, cls, tipTitle, tipVal) {
    return `<div class="bar-row" data-tip-title="${esc(tipTitle)}" data-tip-val="${esc(tipVal)}">
        <div class="bar-label" title="${esc(label)}">${esc(label)}</div>
        <div class="bar-track2"><div class="bar-fill2 ${cls}" style="width:${widthPct}%"></div></div>
        <div class="bar-value">${valueText}</div>
    </div>`;
}

function renderStatistics() {
    const total = users.length;
    const prmfa = users.filter(isPRMFA).length;
    const passkey = users.filter(hasPasskey).length;
    const mfaReg = users.filter(u => isTrue(u.IsMfaRegistered)).length;

    let html = `<section class="stats-section">
        <h2>Adoption Overview</h2>
        <div class="kpi-row">
            ${ringHtml("PRMFA Enabled", prmfa, total, "strong")}
            ${ringHtml("Passkey Users", passkey, total, "strong")}
            ${ringHtml("MFA Registered", mfaReg, total, "standard")}
        </div>
    </section>`;

    // Method adoption: users with at least one instance of each category, sorted, colored by strength
    const catStrength = {};
    const catUsers = {};
    users.forEach(u => {
        const seen = new Set();
        userMethods(u).forEach(m => {
            catStrength[m.Category] = m.Strength || "standard";
            if (!seen.has(m.Category)) {
                seen.add(m.Category);
                catUsers[m.Category] = (catUsers[m.Category] || 0) + 1;
            }
        });
    });
    const cats = Object.keys(catUsers).sort((a, b) => catUsers[b] - catUsers[a]);
    if (cats.length) {
        const legend = `<div class="legend">
            <span class="legend-item"><span class="legend-dot strong"></span>Strong (phishing-resistant)</span>
            <span class="legend-item"><span class="legend-dot standard"></span>Standard</span>
            <span class="legend-item"><span class="legend-dot weak"></span>Legacy</span>
        </div>`;
        const rows = cats.map(c => {
            const n = catUsers[c] || 0;
            const p = pctOf(n, total);
            return barRow(c, p + "%", p, catStrength[c], c, `${n} of ${total} users (${p}%)`);
        }).join("");
        html += `<section class="stats-section"><h2>Method Adoption<span class="section-sub">users with at least one</span></h2>${legend}<div class="bar-chart">${rows}</div></section>`;
    }

    // Passkeys by type (instance counts), fixed order, single hue
    const typeOrder = ["Authenticator passkey", "Physical passkey", "Synced passkey", "Windows Hello passkey"];
    const types = {};
    users.forEach(u => userMethods(u).forEach(m => {
        if (isPasskey(m)) {
            types[m.PasskeyClass] = (types[m.PasskeyClass] || 0) + 1;
        }
    }));
    const typeKeys = Object.keys(types).sort((a, b) => {
        const ia = typeOrder.indexOf(a);
        const ib = typeOrder.indexOf(b);
        return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib);
    });
    if (typeKeys.length) {
        const maxType = Math.max.apply(null, typeKeys.map(k => types[k]));
        const rows = typeKeys.map(k => {
            const n = types[k];
            const w = maxType ? (n / maxType) * 100 : 0;
            return barRow(k, String(n), w, "single", k, `${n} passkey${n === 1 ? "" : "s"}`);
        }).join("");
        html += `<section class="stats-section"><h2>Passkeys by Type<span class="section-sub">instances</span></h2><div class="bar-chart">${rows}</div></section>`;
    }

    // Passkeys by model (only instances that carry a model), single hue, scaled to the max
    const models = {};
    users.forEach(u => userMethods(u).forEach(m => {
        if (isPasskey(m) && m.Model) {
            models[m.Model] = (models[m.Model] || 0) + 1;
        }
    }));
    const modelKeys = Object.keys(models).sort((a, b) => models[b] - models[a]);
    if (modelKeys.length) {
        const maxCount = Math.max.apply(null, modelKeys.map(k => models[k]));
        const rows = modelKeys.map(k => {
            const n = models[k];
            const w = maxCount ? (n / maxCount) * 100 : 0;
            return barRow(k, String(n), w, "single", k, `${n} passkey${n === 1 ? "" : "s"}`);
        }).join("");
        html += `<section class="stats-section"><h2>Passkeys by Model<span class="section-sub">instances</span></h2><div class="bar-chart">${rows}</div></section>`;
    }

    document.getElementById("statistics-content").innerHTML = html;
}

/* ---------- CSV (method inventory) ---------- */

function exportInventory() {
    const rows = [["User", "Category", "Strength", "Name", "Model", "Detail", "Registered", "LastUsed"]];
    users.forEach(u => userMethods(u).forEach(m => {
        rows.push([u.User, m.Category, m.Strength, m.Name, m.Model, m.Detail, m.Registered || "", m.LastUsed || ""]);
    }));
    const csv = rows.map(r => r.map(c => `"${String(c == null ? "" : c).replace(/"/g, '""')}"`).join(",")).join("\n");

    const uri = encodeURI("data:text/csv;charset=utf-8," + csv);
    const link = document.createElement("a");
    link.setAttribute("href", uri);
    link.setAttribute("download", `entra_auth_method_inventory_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

/* ---------- Navigation + events ---------- */

function activateTab(name) {
    document.querySelectorAll(".tab-btn").forEach(b => b.classList.toggle("active", b.dataset.tab === name));
    document.querySelectorAll(".tab-panel").forEach(p => p.classList.toggle("active", p.dataset.panel === name));
}

function initEvents() {
    document.querySelectorAll(".tab-btn").forEach(btn => {
        btn.addEventListener("click", () => activateTab(btn.dataset.tab));
    });

    document.getElementById("user-list").addEventListener("click", e => {
        const item = e.target.closest(".user-list-item");
        if (item) { selectUser(item.getAttribute("data-id")); }
    });

    document.getElementById("user-search").addEventListener("input", renderUserList);
    document.getElementById("user-filter").addEventListener("change", renderUserList);
    document.getElementById("reg-window").addEventListener("change", renderUserList);
    document.getElementById("user-sort").addEventListener("change", renderUserList);
    document.getElementById("csv-export").addEventListener("click", exportInventory);

    // Hover tooltip for the statistics bar charts
    const tip = document.createElement("div");
    tip.className = "viz-tooltip";
    document.body.appendChild(tip);
    const statsEl = document.getElementById("statistics-content");
    statsEl.addEventListener("mousemove", e => {
        const row = e.target.closest(".bar-row");
        if (!row) {
            tip.style.opacity = "0";
            return;
        }
        tip.innerHTML = `<div class="tt-title">${esc(row.dataset.tipTitle)}</div><div class="tt-val">${esc(row.dataset.tipVal)}</div>`;
        tip.style.opacity = "1";
        tip.style.left = (e.clientX + 14) + "px";
        tip.style.top = (e.clientY + 16) + "px";
    });
    statsEl.addEventListener("mouseleave", () => {
        tip.style.opacity = "0";
    });

    const themeSwitch = document.getElementById("theme-switch");
    themeSwitch.addEventListener("change", () => {
        const theme = themeSwitch.checked ? "dark" : "light";
        document.documentElement.setAttribute("data-theme", theme);
        localStorage.setItem("eaiq-theme", theme);
    });
}

document.addEventListener("DOMContentLoaded", () => {
    const savedTheme = localStorage.getItem("eaiq-theme") || "light";
    document.documentElement.setAttribute("data-theme", savedTheme);
    document.getElementById("theme-switch").checked = savedTheme === "dark";

    renderSummaryCards();
    renderUserList();
    renderStatistics();
    initEvents();
});
