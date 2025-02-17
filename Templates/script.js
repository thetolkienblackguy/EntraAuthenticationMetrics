const methodConfig = {
    prmfa: {
        name: "Phishing-Resistant MFA",
        description: "Strong authentication methods that are resistant to phishing attacks. A user is considered PRMFA-enabled if they have any of the following methods enabled: FIDO2, Windows Hello for Business, or Certificate-based authentication.",
        methods: ["Fido2", "WindowsHelloForBusiness", "Certificate"],  
        strength: "Strong",
        showAllMethods: true
    },
    fido2: {
        name: "FIDO2 Security Keys",
        description: "FIDO2 security keys provide phishing-resistant authentication using hardware tokens or biometric devices.",
        methods: ["Fido2"],
        strength: "Strong"
    },
    whfb: {
        name: "Windows Hello for Business",
        description: "Enterprise-grade biometric and PIN-based authentication that's tied to the user's device.",
        methods: ["WindowsHelloForBusiness"],
        strength: "Strong"
    },
    cert: {
        name: "Certificate-based Authentication",
        description: "Authentication using digital certificates stored on smart cards or devices.",
        methods: ["Certificate"], 
        strength: "Strong"
    },
    email: {
        name: "Email Authentication",
        description: "One-time codes sent via email for verification.",
        methods: ["EmailAuthentication"],
        strength: "Weak"
    },
    /*qrCode: {
        name: "QR Code Authentication",
        description: "QR code authentication for frontline workers.",
        methods: ["QRCodeAuthentication"],
        strength: "Weak"
    },*/
    /*password: {
        name: "Password Authentication",
        description: "Traditional password-based authentication.",
        methods: ["PasswordAuthentication"],
        strength: "Weak"
    },*/
    phone: {
        name: "Phone Authentication",
        description: "SMS and voice call-based verification methods.",
        methods: ["PhoneAuthentication"],
        strength: "Weak"
    },
    authenticator: {
        name: "Authenticator App",
        description: "Time-based one-time password (TOTP) authentication using mobile authenticator apps.",
        methods: ["AuthenticatorApp"],
        strength: "Standard"
    },
    oath: {
        name: "Software OATH",
        description: "Software-based OATH tokens for generating one-time passwords.",
        methods: ["SoftwareOath"],
        strength: "Standard"
    },
    temp: {
        name: "Temporary Access Pass",
        description: "Time-limited passcodes for temporary access needs.",
        methods: ["TemporaryAccessPass"],
        strength: "Standard"
    }
};

// User data will be injected here
const users = USERDATA;

function isPRMFAEnabled(user) {
    return methodConfig.prmfa.methods.some(method => String(user[method]).toUpperCase() === "TRUE");
}

function calculateAuthStats() {
    const stats = [];
    const totalUsers = users.length;
    
    // Calculate PRMFA stats first
    const prmfaCount = users.filter(user => isPRMFAEnabled(user)).length;
    const prmfaPercentage = ((prmfaCount / totalUsers) * 100).toFixed(1);
    stats.push({
        name: "Phishing-Resistant MFA",
        count: prmfaCount,
        percentage: parseFloat(prmfaPercentage),
        strength: "Strong"
    });

    // Calculate individual method stats
    Object.entries(methodConfig).forEach(([key, config]) => {
        if (key !== 'prmfa') {
            const method = config.methods[0];
            if (method) {
                const enabledCount = users.filter(user => String(user[method]).toUpperCase() === "TRUE").length;
                const percentage = ((enabledCount / totalUsers) * 100).toFixed(1);
                
                stats.push({
                    name: config.name,
                    count: enabledCount,
                    percentage: parseFloat(percentage),
                    strength: config.strength
                });
            }
        }
    });

    return stats.sort((a, b) => b.percentage - a.percentage);
}

function updateStatsPanel() {
    const stats = calculateAuthStats();
    const statsPanel = document.getElementById('statsPanel');
    
    // Calculate key metrics
    const totalUsers = users.length;
    const prmfaUsers = users.filter(user => isPRMFAEnabled(user)).length;
    const prmfaPercentage = ((prmfaUsers / totalUsers) * 100).toFixed(1);
    
    // Create summary view
    const summary = document.createElement('div');
    summary.className = 'stats-summary';
    
    // Add PRMFA stats first
    const prmfaStat = document.createElement('div');
    prmfaStat.className = 'stat-card';
    prmfaStat.innerHTML = `
        <h4>
            Phishing-Resistant MFA
            <span class="strength-badge Strong">Strong</span>
        </h4>
        <div class="stat-value">${prmfaPercentage}%</div>
        <div>${prmfaUsers} of ${totalUsers} users enabled</div>
        <div class="percentage-bar-container" style="margin-top: 10px;">
            <div class="percentage-bar" 
                 style="width: ${prmfaPercentage}%; 
                        background-color: var(--strong-color)">
            </div>
        </div>
    `;
    
    // Add strong authentication stats
    const strongAuthMethods = stats.filter(s => s.strength === "Strong" && s.name !== "Phishing-Resistant MFA");
    const strongStat = document.createElement('div');
    strongStat.className = 'stat-card';
    strongStat.innerHTML = `
        <h4>
            Strong Authentication Methods
            <span class="strength-badge Strong">Strong</span>
        </h4>
        <div style="margin-bottom: 10px;">
            ${strongAuthMethods.map(method => `
                <div style="margin-bottom: 5px;">
                    <div style="display: flex; justify-content: space-between;">
                        <span>${method.name}</span>
                        <span>${method.percentage}%</span>
                    </div>
                    <div class="percentage-bar-container" style="margin-top: 5px;">
                        <div class="percentage-bar" 
                             style="width: ${method.percentage}%; 
                                    background-color: var(--strong-color)">
                        </div>
                    </div>
                </div>
            `).join('')}
        </div>
    `;

    // Add weak authentication stats
    const weakAuthMethods = stats.filter(s => s.strength === "Weak");
    const weakStat = document.createElement('div');
    weakStat.className = 'stat-card';
    weakStat.innerHTML = `
        <h4>
            Legacy Authentication Methods
            <span class="strength-badge Weak">Weak</span>
        </h4>
        <div style="margin-bottom: 10px;">
            ${weakAuthMethods.map(method => `
                <div style="margin-bottom: 5px;">
                    <div style="display: flex; justify-content: space-between;">
                        <span>${method.name}</span>
                        <span>${method.percentage}%</span>
                    </div>
                    <div class="percentage-bar-container" style="margin-top: 5px;">
                        <div class="percentage-bar" 
                             style="width: ${method.percentage}%; 
                                    background-color: var(--weak-color)">
                        </div>
                    </div>
                </div>
            `).join('')}
        </div>
    `;

    summary.appendChild(prmfaStat);
    summary.appendChild(strongStat);
    summary.appendChild(weakStat);
    
    statsPanel.innerHTML = '';
    statsPanel.appendChild(summary);
}

function createDetailedStats() {
    const stats = calculateAuthStats();
    const container = document.createElement('div');

    // Group methods by strength
    const strengthGroups = {
        Strong: stats.filter(s => s.strength === 'Strong'),
        Standard: stats.filter(s => s.strength === 'Standard'),
        Weak: stats.filter(s => s.strength === 'Weak')
    };

    Object.entries(strengthGroups).forEach(([strength, methods]) => {
        if (methods.length === 0) return;

        const section = document.createElement('div');
        section.innerHTML = `
            <h3>${strength} Authentication Methods</h3>
            <div class="stats-grid">
                ${methods.map(method => `
                    <div class="method-stats">
                        <h4>
                            ${method.name}
                            <span class="strength-badge ${strength}">${strength}</span>
                        </h4>
                        <div class="stat-value">${method.percentage}%</div>
                        <div>${method.count} of ${users.length} users enabled</div>
                        <div class="percentage-bar-container" style="margin-top: 10px;">
                            <div class="percentage-bar" 
                                 style="width: ${method.percentage}%; 
                                        background-color: var(--${strength.toLowerCase()}-color)">
                            </div>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
        container.appendChild(section);
    });

    return container;
}

function createUserTable(tabKey) {
    const config = methodConfig[tabKey];
    const table = document.createElement('table');
    
    const thead = document.createElement('thead');
    thead.innerHTML = `
        <tr>
            <th>User</th>
            <th>Status</th>
            ${config.showAllMethods ? '<th>Enabled Methods</th>' : ''}
        </tr>
    `;
    table.appendChild(thead);

    const tbody = document.createElement('tbody');
    users.forEach(user => {
        const row = document.createElement('tr');
        
        if (tabKey === 'prmfa') {
            const enabledMethods = config.methods.filter(method => String(user[method]).toUpperCase() === "TRUE");
            const status = isPRMFAEnabled(user);
            
            row.innerHTML = `
                <td>${user.User}</td>
                <td>
                    <span class="status ${status ? 'enabled' : 'disabled'}">
                        ${status ? 'Enabled' : 'Disabled'}
                    </span>
                </td>
                <td>${enabledMethods.join(', ') || 'None'}</td>
            `;
        } else {
            const method = config.methods[0];
            const status = method ? String(user[method]).toUpperCase() === "TRUE" : false;
            
            row.innerHTML = `
                <td>${user.User}</td>
                <td>
                    <span class="status ${status ? 'enabled' : 'disabled'}">
                        ${status ? 'Enabled' : 'Disabled'}
                    </span>
                </td>
            `;
        }
        
        tbody.appendChild(row);
    });
    
    table.appendChild(tbody);
    return table;
}

function showTab(tabKey) {
    const config = methodConfig[tabKey];
    
    // Update description
    const descriptionPanel = document.getElementById('descriptionPanel');
    descriptionPanel.innerHTML = `
        <h2>${config.name}</h2>
        <p>${config.description}</p>
        <span class="strength-badge ${config.strength}">${config.strength} Authentication</span>
    `;

    // Update content
    const contentPanel = document.getElementById('contentPanel');
    contentPanel.innerHTML = '';
    contentPanel.appendChild(createUserTable(tabKey));
    filterUsersByStatus();
}

function filterUsersByStatus() {
    const showEnabled = document.querySelector('input[value="enabled"]').checked;
    const showDisabled = document.querySelector('input[value="disabled"]').checked;
    const searchTerm = document.getElementById('userSearch').value.toLowerCase();

    document.querySelectorAll('table tbody tr').forEach(row => {
        const userName = row.querySelector('td').textContent.toLowerCase();
        const status = row.querySelector('.status').classList.contains('enabled');
        
        const matchesSearch = userName.includes(searchTerm);
        const matchesFilter = (status && showEnabled) || (!status && showDisabled);
        
        row.style.display = matchesSearch && matchesFilter ? '' : 'none';
    });
}

function initializeEventListeners() {
    // Theme toggle
    const themeToggle = document.getElementById('themeToggle');
    themeToggle.addEventListener('click', () => {
        themeToggle.classList.toggle('active');
        document.body.setAttribute('data-theme', 
            document.body.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
    });

    // Filter dropdown
    const filterToggle = document.getElementById('filterToggle');
    const filterDropdown = document.getElementById('filterDropdown');
    
    filterToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        filterDropdown.classList.toggle('show');
    });

    document.addEventListener('click', (e) => {
        if (!filterDropdown.contains(e.target)) {
            filterDropdown.classList.remove('show');
        }
    });

    // Status filter checkboxes
    document.querySelectorAll('.filter-option input').forEach(checkbox => {
        checkbox.addEventListener('change', filterUsersByStatus);
    });
    
    // Tab switching
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            showTab(tab.dataset.tab);
        });
    });
    
    // Search
    const searchInput = document.getElementById('userSearch');
    searchInput.addEventListener('input', filterUsersByStatus);

    // Stats Modal
    const statsButton = document.getElementById('statsButton');
    const statsModal = document.getElementById('statsModal');
    const closeStatsModal = document.getElementById('closeStatsModal');
    const statsModalContent = document.getElementById('statsModalContent');

    statsButton.addEventListener('click', () => {
        statsModalContent.innerHTML = '';
        statsModalContent.appendChild(createDetailedStats());
        statsModal.classList.add('show');
    });

    closeStatsModal.addEventListener('click', () => {
        statsModal.classList.remove('show');
    });

    statsModal.addEventListener('click', (e) => {
        if (e.target === statsModal) {
            statsModal.classList.remove('show');
        }
    });
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    updateStatsPanel();
    showTab('prmfa');
    initializeEventListeners();
});