// Copyright (c) 2025 johnsmith600
// Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
// See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

const app = document.getElementById('app');
const panel = document.getElementById('panel');
const subtitle = document.getElementById('subtitle');
const mechanicBtn = document.getElementById('mechanic-btn');

let Locale = {
    labels: { plate: 'Plate Number', new_owner_id: 'New Owner ID', expiry: 'Expiry', owner: 'Owner', status: 'Status' },
    actions: { register: 'Register', renew: 'Renew', transfer: 'Transfer', lookup: 'Lookup', close: 'Close' },
    notify: { lookup_no_result: 'No registration found.' }
};

let PlateStyles = [];
let SelectedStyle = 'standard';
let ConfigData = { printPlateFee: 50, pinkSlipFee: 50, vanityPlateFee: 800 };

function escapeHTML(str) {
    if (!str) return "";
    return String(str)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function setVisible(v) {
    app.classList[v ? 'remove' : 'add']('hidden');
}

function toast(text) {
    const t = document.createElement('div');
    t.className = 'toast';
    t.textContent = text;
    document.body.appendChild(t);
    setTimeout(() => {
        t.style.opacity = '0';
        setTimeout(() => t.remove(), 300);
    }, 3000);
}

function inputGroup(label, ph, id, type = "text") {
    return `<div class="form-group">
        <label for="${id}">${label}</label>
        <input type="${type}" id="${id}" placeholder="${ph}" />
    </div>`;
}

function selectGroup(label, id, options) {
    return `<div class="form-group">
        <label for="${id}">${label}</label>
        <select id="${id}">${options.map(o => `<option value="${o.value}">${o.label}</option>`).join('')}</select>
    </div>`;
}

function renderHome() {
    panel.innerHTML = `
        <div class="welcome-card card">
            <h2>Welcome to Service NSW</h2>
            <p>Manage your vehicle registrations, transfers, and plate services online. Select an option from the sidebar to begin.</p>
        </div>
        <div class="grid">
            <div class="card">
                <h3>Quick Tip</h3>
                <p>Ensure you have a valid Pink Slip before attempting to renew your registration. Pink Slips are valid for 6 months.</p>
            </div>
            <div class="card">
                <h3>New Plates</h3>
                <p>You can now order physical plates for your vehicle and choose from several modern styles.</p>
            </div>
        </div>
    `;
    setActiveBtn('home');
}

function renderRegister() {
    let stylesHtml = '<div class="style-grid">';
    PlateStyles.forEach(s => {
        const id = escapeHTML(s.id);
        const label = escapeHTML(s.label);
        const fee = escapeHTML(s.fee);
        stylesHtml += `
            <div class="style-option ${s.id === SelectedStyle ? 'selected' : ''} style-${id}" onclick="selectStyle('${id}')">
                <div class="plate-preview">ABC-123</div>
                <strong>${label}</strong><br>
                <small>$${fee} fee</small>
            </div>
        `;
    });
    stylesHtml += '</div>';

    panel.innerHTML = `
        <h2>Register New Vehicle</h2>
        <p>Complete the form below to register your vehicle in the NSW system.</p>
        ${inputGroup('Plate Number', 'e.g. NSW123', 'plate')}
        ${selectGroup('Registration Period', 'months', [
            { value: 3, label: '3 Months' },
            { value: 6, label: '6 Months' },
            { value: 12, label: '12 Months' }
        ])}
        <label>Select Plate Style</label>
        ${stylesHtml}
        <button class="submit-btn" onclick="submitRegister()">Register Vehicle</button>
    `;
    setActiveBtn('register');
}

window.selectStyle = (id) => {
    SelectedStyle = id;
    renderRegister();
};

window.submitRegister = () => {
    const plate = document.getElementById('plate').value;
    if (!plate || plate.trim().length === 0) return toast('Please enter a plate number');
    const months = document.getElementById('months').value;
    fetch(`https://${GetParentResourceName()}/nui_register`, {
        method: 'POST',
        body: JSON.stringify({ plate, months, style: SelectedStyle })
    });
};

function renderRenew() {
    panel.innerHTML = `
        <h2>Renew Registration</h2>
        <p>Extend the registration for an existing vehicle. Note: A valid Pink Slip may be required.</p>
        ${inputGroup('Plate Number', 'e.g. NSW123', 'plate')}
        ${selectGroup('Renewal Period', 'months', [
            { value: 3, label: '3 Months' },
            { value: 6, label: '6 Months' },
            { value: 12, label: '12 Months' }
        ])}
        <button class="submit-btn" onclick="submitRenew()">Renew Registration</button>
    `;
    setActiveBtn('renew');
}

window.submitRenew = () => {
    const plate = document.getElementById('plate').value;
    if (!plate || plate.trim().length === 0) return toast('Please enter a plate number');
    const months = document.getElementById('months').value;
    fetch(`https://${GetParentResourceName()}/nui_renew`, {
        method: 'POST',
        body: JSON.stringify({ plate, months })
    });
};

function renderTransfer() {
    panel.innerHTML = `
        <h2>Transfer Ownership</h2>
        <p>Transfer a vehicle registration to another person. Fees apply.</p>
        ${inputGroup('Plate Number', 'e.g. NSW123', 'plate')}
        ${inputGroup('New Owner ID', 'Citizen ID or License', 'newOwner')}
        <button class="submit-btn" onclick="submitTransfer()">Transfer Registration</button>
    `;
    setActiveBtn('transfer');
}

window.submitTransfer = () => {
    const plate = document.getElementById('plate').value;
    if (!plate || plate.trim().length === 0) return toast('Please enter a plate number');
    const newOwner = document.getElementById('newOwner').value;
    if (!newOwner || newOwner.trim().length === 0) return toast('Please enter new owner ID');
    fetch(`https://${GetParentResourceName()}/nui_transfer`, {
        method: 'POST',
        body: JSON.stringify({ plate, newOwner })
    });
};

function renderLookup() {
    panel.innerHTML = `
        <h2>Plate Lookup</h2>
        <p>Check the registration status and history of any NSW plate.</p>
        ${inputGroup('Plate Number', 'e.g. NSW123', 'plate')}
        <button class="submit-btn" onclick="submitLookup()">Lookup Plate</button>
        <div id="lookup-result" style="margin-top: 20px;"></div>
    `;
    setActiveBtn('lookup');
}

window.submitLookup = () => {
    const plate = document.getElementById('plate').value;
    if (!plate || plate.trim().length === 0) return toast('Please enter a plate number');
    fetch(`https://${GetParentResourceName()}/nui_lookup`, {
        method: 'POST',
        body: JSON.stringify({ plate })
    });
};

function renderHistory() {
    panel.innerHTML = `
        <h2>History</h2>
        <p>View recent transactions for a vehicle.</p>
        ${inputGroup('Plate Number', 'e.g. NSW123', 'plate')}
        <button class="submit-btn" onclick="submitHistory()">View History</button>
        <div id="history-result" style="margin-top: 20px;"></div>
    `;
    setActiveBtn('history');
}

window.submitHistory = () => {
    const plate = document.getElementById('plate').value;
    if (!plate || plate.trim().length === 0) return toast('Please enter a plate number');
    fetch(`https://${GetParentResourceName()}/nui_history`, {
        method: 'POST',
        body: JSON.stringify({ plate })
    });
};

function renderPrint() {
    panel.innerHTML = `
        <h2>Print Physical Plate</h2>
        <p>Order a physical metal plate to be manufactured for your vehicle.</p>
        ${inputGroup('Plate Number', 'e.g. NSW123', 'plate')}
        <button class="submit-btn" onclick="submitPrint()">Print Plate ($50)</button>
    `;
    setActiveBtn('print');
}

window.submitPrint = () => {
    const plate = document.getElementById('plate').value;
    if (!plate || plate.trim().length === 0) return toast('Please enter a plate number');
    fetch(`https://${GetParentResourceName()}/nui_print`, {
        method: 'POST',
        body: JSON.stringify({ plate })
    });
};

function renderCustom() {
    panel.innerHTML = `
        <h2>Custom Plate Number</h2>
        <p>Choose a unique plate number for your vehicle. Availability will be checked upon submission.</p>
        ${inputGroup('Current Plate', 'e.g. ABC123', 'oldPlate')}
        ${inputGroup('Desired New Plate', 'e.g. MYPLATE', 'newPlate')}
        <button class="submit-btn" onclick="submitCustom()">Purchase & Apply ($${ConfigData.vanityPlateFee})</button>
    `;
    setActiveBtn('custom');
}

window.submitCustom = () => {
    const oldPlate = document.getElementById('oldPlate').value;
    const newPlate = document.getElementById('newPlate').value;
    if (!oldPlate || oldPlate.trim().length === 0) return toast('Please enter your current plate');
    if (!newPlate || newPlate.trim().length === 0) return toast('Please enter your new desired plate');
    
    fetch(`https://${GetParentResourceName()}/nui_purchase_custom`, {
        method: 'POST',
        body: JSON.stringify({ oldPlate, newPlate })
    });
};

function renderMechanic() {
    panel.innerHTML = `
        <h2>Mechanic Portal</h2>
        <p>Inspect vehicles and issue Pink Slips (Safety Checks).</p>
        ${inputGroup('Plate Number', 'e.g. NSW123', 'plate')}
        <button class="submit-btn" onclick="submitPinkSlip()">Issue Pink Slip</button>
    `;
    setActiveBtn('mechanic');
}

window.submitPinkSlip = () => {
    const plate = document.getElementById('plate').value;
    if (!plate || plate.trim().length === 0) return toast('Please enter a plate number');
    fetch(`https://${GetParentResourceName()}/nui_issue_pink`, {
        method: 'POST',
        body: JSON.stringify({ plate })
    });
};

function setActiveBtn(action) {
    document.querySelectorAll('.actions button').forEach(btn => {
        if (btn.getAttribute('data-action') === action) btn.classList.add('active');
        else btn.classList.remove('active');
    });
}

function bindActions() {
    document.querySelectorAll('[data-action]').forEach(btn => {
        btn.onclick = () => {
            const act = btn.getAttribute('data-action');
            if (act === 'home') renderHome();
            if (act === 'register') renderRegister();
            if (act === 'renew') renderRenew();
            if (act === 'transfer') renderTransfer();
            if (act === 'lookup') renderLookup();
            if (act === 'history') renderHistory();
            if (act === 'custom') renderCustom();
            if (act === 'print') renderPrint();
            if (act === 'mechanic') renderMechanic();
            if (act === 'close') {
                setVisible(false);
                fetch(`https://${GetParentResourceName()}/nui_close`, { method: 'POST', body: '{}' });
            }
        };
    });
}

window.addEventListener('message', (e) => {
    const data = e.data || {};
    if (data.action === 'show') {
        Locale = data.locale || Locale;
        PlateStyles = data.plateStyles || [];
        ConfigData = data.config || ConfigData;
        subtitle.textContent = data.subtitle || 'Service Centre';
        if (data.isMechanic) mechanicBtn.classList.remove('hidden');
        else mechanicBtn.classList.add('hidden');
        setVisible(true);
        bindActions();
        if (data.startPage === 'mechanic' && data.isMechanic) {
            renderMechanic();
        } else {
            renderHome();
        }
    } else if (data.action === 'hide') {
        setVisible(false);
    } else if (data.action === 'toast') {
        toast(data.text || '');
    } else if (data.action === 'lookup_result') {
        const info = data.info;
        const resDiv = document.getElementById('lookup-result');
        if (!info) return toast(Locale.notify.lookup_no_result);
        resDiv.innerHTML = `
            <div class="card">
                <h3>Registration Details: ${escapeHTML(info.plate)}</h3>
                <p><strong>Owner ID:</strong> ${escapeHTML(info.owner_identifier)}</p>
                <p><strong>Status:</strong> <span class="status-badge status-${escapeHTML(info.status)}">${escapeHTML(info.status)}</span></p>
                <p><strong>Expiry Date:</strong> ${escapeHTML(info.formatted_expiry)}</p>
                <p><strong>Pink Slip:</strong> <span class="status-badge status-${escapeHTML(info.pink_status)}">${escapeHTML(info.formatted_pink_expiry)}</span></p>
                <p><strong>Plate Style:</strong> ${escapeHTML(info.plate_style)}</p>
                ${info.flag ? `<div class="card" style="border-color: #d32f2f; background: #fff0f0; margin-top: 15px;">
                    <p><strong>FLAGGED:</strong> ${escapeHTML(info.flag.reason)}</p>
                    <small>By ${escapeHTML(info.flag.actor_identifier)}</small>
                </div>` : ''}
            </div>
        `;
    } else if (data.action === 'history_result') {
        const rows = data.rows || [];
        const resDiv = document.getElementById('history-result');
        let html = '<h3>Transaction History</h3>';
        if (!rows.length) html += '<p>No history found for this vehicle.</p>';
        else html += rows.map(r => `
            <div class="history-item">
                <strong>${escapeHTML(r.action.toUpperCase())}</strong> • $${escapeHTML(r.fee)}<br>
                <small>${escapeHTML(r.created_at)} • Actor: ${escapeHTML(r.actor_identifier)}</small>
            </div>
        `).join('');
        resDiv.innerHTML = html;
    }
});

document.onkeyup = (e) => {
    if (e.key === 'Escape') {
        setVisible(false);
        fetch(`https://${GetParentResourceName()}/nui_close`, { method: 'POST', body: '{}' });
    }
};
