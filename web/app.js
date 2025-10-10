// Copyright (c) 2025 johnsmith600
// Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
// See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

const app = document.getElementById('app');
const panel = document.getElementById('panel');
const subtitle = document.getElementById('subtitle');

let Locale = {
	labels: { plate: 'Plate', new_owner_id: 'New Owner ID', expiry: 'Expiry', owner: 'Owner', status: 'Status' },
	actions: { register: 'Register', renew: 'Renew', transfer: 'Transfer', lookup: 'Lookup', close: 'Close' },
	notify: { lookup_no_result: 'No registration found.' }
};

function setVisible(v) {
	app.classList[v ? 'remove' : 'add']('hidden');
	document.body.classList[v ? 'add' : 'remove']('nui-active');
}
function toast(text) {
	const t = document.createElement('div');
	t.className = 'toast';
	t.textContent = text;
	document.body.appendChild(t);
	setTimeout(()=> t.remove(), 2000);
}

function inputRow(ph, id) {
	return `<div class="row"><input id="${id}" placeholder="${ph}" /></div>`;
}

function renderRegister() {
    panel.innerHTML = `<h3>${Locale.actions.register}</h3>${inputRow(Locale.labels.plate,'plate')}
        <div class="row"><select id="months"><option value="3">3 months</option><option value="6">6 months</option><option value="12">12 months</option></select></div>
        <div class="submit" id="submit">${Locale.actions.register}</div>`;
	document.getElementById('submit').onclick = () => {
        fetch(`https://${GetParentResourceName()}/nui_register`, { method:'POST', body: JSON.stringify({ plate: document.getElementById('plate').value, months: document.getElementById('months').value }) });
	};
}

function renderRenew() {
    panel.innerHTML = `<h3>${Locale.actions.renew}</h3>${inputRow(Locale.labels.plate,'plate')}
        <div class="row"><select id="months"><option value="3">3 months</option><option value="6">6 months</option><option value="12">12 months</option></select></div>
        <div class="submit" id="submit">${Locale.actions.renew}</div>`;
	document.getElementById('submit').onclick = () => {
        fetch(`https://${GetParentResourceName()}/nui_renew`, { method:'POST', body: JSON.stringify({ plate: document.getElementById('plate').value, months: document.getElementById('months').value }) });
	};
}

function renderTransfer() {
	panel.innerHTML = `<h3>${Locale.actions.transfer}</h3>${inputRow(Locale.labels.plate,'plate')}${inputRow(Locale.labels.new_owner_id,'newOwner')}<div class="submit" id="submit">${Locale.actions.transfer}</div>`;
	document.getElementById('submit').onclick = () => {
		fetch(`https://${GetParentResourceName()}/nui_transfer`, { method:'POST', body: JSON.stringify({ plate: document.getElementById('plate').value, newOwner: document.getElementById('newOwner').value }) });
	};
}

function renderLookup() {
	panel.innerHTML = `<h3>${Locale.actions.lookup}</h3>${inputRow(Locale.labels.plate,'plate')}<div class="submit" id="submit">${Locale.actions.lookup}</div>`;
	document.getElementById('submit').onclick = () => {
		fetch(`https://${GetParentResourceName()}/nui_lookup`, { method:'POST', body: JSON.stringify({ plate: document.getElementById('plate').value }) });
	};
}

function renderHistory() {
	panel.innerHTML = `<h3>History</h3>${inputRow(Locale.labels.plate,'plate')}<div class="submit" id="submit">Load</div><div class="note">Shows last 25 actions.</div>`;
	document.getElementById('submit').onclick = async () => {
		const plate = document.getElementById('plate').value;
		const res = await fetch(`https://${GetParentResourceName()}/nui_history`, { method:'POST', body: JSON.stringify({ plate }) });
		res.text(); // fire and forget
	};
}

function renderFees() {
	panel.innerHTML = `<h3>Fee Calculator</h3>
		<div class="row"><select id="act">
			<option value="register">Register</option>
			<option value="renew">Renew</option>
			<option value="transfer">Transfer</option>
		</select></div>
		${inputRow('Late days (optional)','late')}
		<div class="submit" id="submit">Calculate</div>`;
	document.getElementById('submit').onclick = async () => {
		const act = document.getElementById('act').value;
		const late = document.getElementById('late').value;
		const res = await fetch(`https://${GetParentResourceName()}/nui_calc`, { method:'POST', body: JSON.stringify({ action: act, lateDays: late }) });
		res.text();
	};
}

function renderVanity() {
	panel.innerHTML = `<h3>Vanity Plate</h3>${inputRow('Desired Plate','plate')}
		<div class="row"><button id="check" class="submit">Check</button><button id="reserve" class="submit" style="margin-left:8px">Reserve</button></div>
		<div class="note">Reservation holds for 24h. Fees apply on registration.</div>`;
	document.getElementById('check').onclick = async () => {
		const plate = document.getElementById('plate').value;
		const res = await fetch(`https://${GetParentResourceName()}/nui_check`, { method:'POST', body: JSON.stringify({ plate }) });
		res.text();
	};
	document.getElementById('reserve').onclick = async () => {
		const plate = document.getElementById('plate').value;
		const res = await fetch(`https://${GetParentResourceName()}/nui_reserve`, { method:'POST', body: JSON.stringify({ plate }) });
		res.text();
	};
}

function bindActions() {
    document.querySelectorAll('[data-action]').forEach(btn => {
        btn.onclick = () => {
			const act = btn.getAttribute('data-action');
			if (act === 'register') return renderRegister();
			if (act === 'renew') return renderRenew();
			if (act === 'transfer') return renderTransfer();
            if (act === 'lookup') return renderLookup();
            if (act === 'history') return renderHistory();
            if (act === 'fees') return renderFees();
            if (act === 'vanity') return renderVanity();
            if (act === 'close') {
                // Hide immediately, then notify client
                setVisible(false);
                fetch(`https://${GetParentResourceName()}/nui_close`, { method:'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
                return;
            }
		};
	});
}

window.addEventListener('message', (e) => {
	const data = e.data || {};
    if (data.action === 'show') {
		Locale = data.locale || Locale;
		subtitle.textContent = data.subtitle || 'Service Centre';
		setVisible(true);
		bindActions();
	} else if (data.action === 'hide') {
        setVisible(false);
	} else if (data.action === 'toast') {
		toast(data.text || '');
	} else if (data.action === 'lookup_result') {
		const info = data.info;
		if (!info) return toast(Locale.notify.lookup_no_result);
		panel.innerHTML = `<h3>${Locale.actions.lookup}</h3>
			<div class="row">${Locale.labels.plate}: ${info.plate}</div>
			<div class="row">${Locale.labels.owner}: ${info.owner_identifier}</div>
			<div class="row">${Locale.labels.status}: ${info.status}</div>
            <div class="row">${Locale.labels.expiry}: ${info.formatted_expiry}</div>
            ${info.flag ? `<div class="card"><div class="row">FLAGGED: ${info.flag.reason}</div><div class="note">By ${info.flag.actor_identifier}</div></div>` : ''}`;
    } else if (data.action === 'history_result') {
        const rows = data.rows || [];
        let html = '<h3>History</h3>';
        if (!rows.length) html += '<div class="note">No history.</div>';
        else html += rows.map(r => `<div class="card"><div class="row">${r.action.toUpperCase()} • $${r.fee} • ${r.created_at}</div><div class="note">Actor: ${r.actor_identifier}</div></div>`).join('');
        panel.innerHTML = html;
    } else if (data.action === 'fees_result') {
        const f = data.fees;
        if (!f) return;
        panel.innerHTML = `<h3>Fee Calculator</h3>
            <div class="card"><div class="row">Base: $${f.base}</div><div class="row">Discount: ${f.discount}%</div><div class="row">Late Penalty: ${f.latePercent}%</div><div class="row"><b>Total: $${f.total}</b></div></div>`;
    } else if (data.action === 'vanity_check') {
        const r = data.result;
        if (!r) return;
        if (r.available) return toast('Available!');
        if (r.reason === 'reserved') return toast('Reserved (expires soon).');
        if (r.reason === 'taken') return toast('Taken.');
        if (r.reason === 'blacklisted') return toast('Not allowed.');
        toast('Unavailable.');
    } else if (data.action === 'vanity_reserved') {
        toast('Reserved for 24h.');
	}
});

document.onkeyup = (e) => { if (e.key === 'Escape') fetch(`https://${GetParentResourceName()}/nui_close`, { method:'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }); };

