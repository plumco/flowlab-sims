/**
 * app.js - UI Controller and Interactive Visualizer
 * Connects AIRNETPhysics with Canvas rendering, real-time telemetry, and diagnostic analytics.
 */

(function() {
    'use strict';

    // State Variables
    let system = null;
    let isRunning = true;
    let currentPreset = 'standard_flush';
    let animationFrameId = null;
    let lastRenderTime = performance.now();

    // History buffer for oscilloscope
    const MAX_HISTORY = 400;
    const timeHistory = []; // { t, p_top, p_mid, p_base, papa_vol }

    // Canvas Elements
    let stackCanvas, stackCtx;
    let profileCanvas, profileCtx;
    let scopeCanvas, scopeCtx;

    // UI DOM Elements
    let playPauseBtn, resetBtn, dischargeBtn;
    let floorSlider, floorVal;
    let rateSlider, rateVal;
    let surchargeCheck, aavCheck, papaCheck, acousticCheck;
    let trapListContainer;
    let guidanceText;
    let statusPill, statusText;
    let metricMaxSuction, metricMaxBackpressure, metricDepletedCount, metricSimTime;

    function init() {
        // DOM binding
        stackCanvas = document.getElementById('stackCanvas');
        stackCtx = stackCanvas.getContext('2d');

        profileCanvas = document.getElementById('profileCanvas');
        profileCtx = profileCanvas.getContext('2d');

        scopeCanvas = document.getElementById('scopeCanvas');
        scopeCtx = scopeCanvas.getContext('2d');

        playPauseBtn = document.getElementById('playPauseBtn');
        resetBtn = document.getElementById('resetBtn');
        dischargeBtn = document.getElementById('dischargeBtn');

        floorSlider = document.getElementById('floorSlider');
        floorVal = document.getElementById('floorVal');
        rateSlider = document.getElementById('rateSlider');
        rateVal = document.getElementById('rateVal');

        surchargeCheck = document.getElementById('surchargeCheck');
        aavCheck = document.getElementById('aavCheck');
        papaCheck = document.getElementById('papaCheck');
        acousticCheck = document.getElementById('acousticCheck');

        trapListContainer = document.getElementById('trapListContainer');
        guidanceText = document.getElementById('guidanceText');
        statusPill = document.getElementById('statusPill');
        statusText = document.getElementById('statusText');

        metricMaxSuction = document.getElementById('metricMaxSuction');
        metricMaxBackpressure = document.getElementById('metricMaxBackpressure');
        metricDepletedCount = document.getElementById('metricDepletedCount');
        metricSimTime = document.getElementById('metricSimTime');

        // Create Physics Engine
        system = new AIRNETPhysics.AIRNETSystem({
            floors: 15,
            floorHeight: 3.0,
            diameter: 0.100
        });

        setupPresetChips();
        bindEvents();
        applyPreset('standard_flush');
        resizeCanvases();
        window.addEventListener('resize', resizeCanvases);

        // Start Loop
        requestAnimationFrame(renderLoop);
    }

    function setupPresetChips() {
        const container = document.getElementById('presetChipsContainer');
        container.innerHTML = '';

        Object.keys(AIRNETPresets).forEach(key => {
            const preset = AIRNETPresets[key];
            const chip = document.createElement('button');
            chip.className = `preset-chip ${key === currentPreset ? 'active' : ''}`;
            chip.innerHTML = `
                <span class="preset-tag" style="background-color: ${preset.badgeColor}22; color: ${preset.badgeColor}; border: 1px solid ${preset.badgeColor}44;">
                    ${preset.badge}
                </span>
                <span>${preset.title}</span>
            `;
            chip.addEventListener('click', () => {
                document.querySelectorAll('.preset-chip').forEach(c => c.classList.remove('active'));
                chip.classList.add('active');
                applyPreset(key);
            });
            container.appendChild(chip);
        });
    }

    function applyPreset(presetKey) {
        currentPreset = presetKey;
        const preset = AIRNETPresets[presetKey];
        if (!preset) return;

        system.reset();
        timeHistory.length = 0;

        // Apply config
        floorSlider.value = preset.dischargeFloor;
        floorVal.textContent = preset.dischargeFloor > 0 ? `Floor ${preset.dischargeFloor}` : 'None';

        rateSlider.value = preset.dischargeRate;
        rateVal.textContent = `${preset.dischargeRate.toFixed(1)} L/s`;

        surchargeCheck.checked = preset.baseSurcharge;
        system.baseSurcharged = preset.baseSurcharge;

        aavCheck.checked = preset.enableAAV;
        papaCheck.checked = preset.enablePAPA;
        acousticCheck.checked = preset.acousticTest;

        system.setupControls({
            enableAAV: preset.enableAAV,
            enablePAPA: preset.enablePAPA,
            papaCapacity: preset.papaCapacity || 24.0
        });

        system.acousticTestActive = preset.acousticTest;

        // Deplete traps if required by scenario (e.g. Amoy Gardens)
        if (preset.depleteFloors && preset.depleteFloors.length > 0) {
            preset.depleteFloors.forEach(f => {
                const trap = system.traps.find(t => t.floor === f);
                if (trap) {
                    trap.currentWaterLevel = 0.0;
                    trap.isDepleted = true;
                    trap.depletionReason = 'EVAPORATED_DRY';
                }
            });
        }

        if (preset.dischargeFloor > 0 && preset.dischargeRate > 0) {
            system.setDischarge(preset.dischargeFloor, preset.dischargeRate);
        }

        guidanceText.textContent = preset.guidance;
        renderTrapList();
    }

    function bindEvents() {
        playPauseBtn.addEventListener('click', () => {
            isRunning = !isRunning;
            playPauseBtn.innerHTML = isRunning ? '⏸ Pause' : '▶ Resume';
            playPauseBtn.className = isRunning ? 'btn btn-secondary' : 'btn btn-primary';
        });

        resetBtn.addEventListener('click', () => {
            system.reset();
            timeHistory.length = 0;
            renderTrapList();
        });

        dischargeBtn.addEventListener('click', () => {
            const f = parseInt(floorSlider.value, 10);
            const r = parseFloat(rateSlider.value);
            system.clearAllDischarges();
            if (f > 0 && r > 0) {
                system.setDischarge(f, r);
            }
        });

        floorSlider.addEventListener('input', (e) => {
            const val = parseInt(e.target.value, 10);
            floorVal.textContent = val > 0 ? `Floor ${val}` : 'None';
        });

        rateSlider.addEventListener('input', (e) => {
            const val = parseFloat(e.target.value);
            rateVal.textContent = `${val.toFixed(1)} L/s`;
        });

        surchargeCheck.addEventListener('change', (e) => {
            system.baseSurcharged = e.target.checked;
        });

        aavCheck.addEventListener('change', (e) => {
            system.setupControls({
                enableAAV: e.target.checked,
                enablePAPA: papaCheck.checked
            });
        });

        papaCheck.addEventListener('change', (e) => {
            system.setupControls({
                enableAAV: aavCheck.checked,
                enablePAPA: e.target.checked
            });
        });

        acousticCheck.addEventListener('change', (e) => {
            system.acousticTestActive = e.target.checked;
        });

        // Export Data Feature (CSV)
        document.getElementById('exportBtn').addEventListener('click', exportSimulationCSV);
    }

    function resizeCanvases() {
        [stackCanvas, profileCanvas, scopeCanvas].forEach(canvas => {
            if (!canvas) return;
            const rect = canvas.getBoundingClientRect();
            canvas.width = rect.width * window.devicePixelRatio || rect.width;
            canvas.height = rect.height * window.devicePixelRatio || rect.height;
        });
    }

    function renderLoop(timestamp) {
        // Run physics sub-steps for stability and real-time feel
        if (isRunning && system) {
            // Step multiple times per animation frame for smooth sound-speed wave resolution
            const stepsPerFrame = 12;
            for (let i = 0; i < stepsPerFrame; i++) {
                system.step();
            }

            // Record oscilloscope telemetry
            const N = system.stack.numNodes;
            const p_top = AIRNETPhysics.paToMmWG(system.stack.p[N - 1]);
            const p_mid = AIRNETPhysics.paToMmWG(system.stack.p[Math.floor(N / 2)]);
            const p_base = AIRNETPhysics.paToMmWG(system.stack.p[0]);
            const papa_vol = system.papaUnits.length > 0 ? system.papaUnits[0].currentVolumeLiters : 0;

            timeHistory.push({ t: system.simTime, p_top, p_mid, p_base, papa_vol });
            if (timeHistory.length > MAX_HISTORY) timeHistory.shift();
        }

        // Render visual components
        drawStack();
        drawProfile();
        drawOscilloscope();
        updateTelemetry();

        requestAnimationFrame(renderLoop);
    }

    /**
     * Draw 2D Architectural Cross-section of High-Rise Building Drainage Stack
     */
    function drawStack() {
        const w = stackCanvas.width;
        const h = stackCanvas.height;
        const ctx = stackCtx;

        ctx.clearRect(0, 0, w, h);

        const floors = system.floors;
        const marginY = 30;
        const usableH = h - marginY * 2;
        const floorH = usableH / floors;
        const pipeX = w * 0.45;
        const pipeW = 16;

        // Draw Building Floors
        ctx.strokeStyle = '#1e293b';
        ctx.lineWidth = 1;
        ctx.fillStyle = '#64748b';
        ctx.font = `${Math.max(10, Math.floor(floorH * 0.4))}px sans-serif`;

        for (let f = 1; f <= floors; f++) {
            const y = h - marginY - (f - 1) * floorH;
            ctx.beginPath();
            ctx.moveTo(30, y);
            ctx.lineTo(w - 30, y);
            ctx.stroke();

            // Floor label
            ctx.fillText(`F${f}`, 8, y - 4);
        }

        // Draw Main Vertical Stack Pipe
        ctx.fillStyle = '#0f172a';
        ctx.fillRect(pipeX, marginY, pipeW, usableH);
        ctx.strokeStyle = '#334155';
        ctx.lineWidth = 2;
        ctx.strokeRect(pipeX, marginY, pipeW, usableH);

        // Water Downflow Film (Annular Flow Animation)
        for (let i = 0; i < system.stack.numNodes; i++) {
            if (system.stack.isWet[i] === 1) {
                const fraction = i / (system.stack.numNodes - 1);
                const y = h - marginY - fraction * usableH;
                const nodeH = usableH / system.stack.numNodes;

                // Blue falling water layer
                ctx.fillStyle = 'rgba(56, 189, 248, 0.75)';
                // Annular film adheres to both walls with central air core
                ctx.fillRect(pipeX, y - nodeH, 4, nodeH + 1);
                ctx.fillRect(pipeX + pipeW - 4, y - nodeH, 4, nodeH + 1);
            }
        }

        // Draw Stack Base Surcharge (if active)
        if (system.baseSurcharged) {
            ctx.fillStyle = 'rgba(239, 68, 68, 0.7)';
            ctx.fillRect(pipeX - 10, h - marginY - 14, pipeW + 20, 18);
            ctx.fillStyle = '#fff';
            ctx.font = '9px monospace';
            ctx.fillText('SURCHARGE', pipeX - 22, h - marginY + 16);
        }

        // Draw P.A.P.A. Unit at Floor 1 / Base
        if (system.papaUnits.length > 0 && system.papaUnits[0].isActive) {
            const papa = system.papaUnits[0];
            const papaY = h - marginY - floorH * 0.7;
            const expandFactor = papa.currentVolumeLiters / papa.capacityLiters;
            const bagRadius = 10 + expandFactor * 14;

            // Bag expansion
            ctx.beginPath();
            ctx.arc(pipeX + pipeW + 16, papaY, bagRadius, 0, Math.PI * 2);
            ctx.fillStyle = expandFactor > 0.1 ? 'rgba(14, 165, 233, 0.85)' : 'rgba(56, 189, 248, 0.4)';
            ctx.fill();
            ctx.strokeStyle = '#38bdf8';
            ctx.stroke();

            // Connecting pipe
            ctx.beginPath();
            ctx.moveTo(pipeX + pipeW, papaY);
            ctx.lineTo(pipeX + pipeW + 16 - bagRadius, papaY);
            ctx.lineWidth = 3;
            ctx.strokeStyle = '#0284c7';
            ctx.stroke();

            ctx.fillStyle = '#38bdf8';
            ctx.font = '9px sans-serif';
            ctx.fillText(`P.A.P.A. (${papa.currentVolumeLiters.toFixed(1)}L)`, pipeX + pipeW + 26, papaY + 3);
        }

        // Draw AAV at Stack Top
        if (system.aavUnits.length > 0 && system.aavUnits[0].isActive) {
            const aav = system.aavUnits[0];
            const aavY = marginY - 10;
            ctx.fillStyle = aav.isOpen ? '#10b981' : '#64748b';
            ctx.fillRect(pipeX - 4, aavY, pipeW + 8, 10);
            ctx.fillStyle = '#cbd5e1';
            ctx.font = '8px sans-serif';
            ctx.fillText(aav.isOpen ? 'AAV OPEN' : 'AAV CLOSED', pipeX - 12, aavY - 4);
        } else if (system.stackTopOpen) {
            // Open cowl
            ctx.fillStyle = '#94a3b8';
            ctx.font = '9px sans-serif';
            ctx.fillText('ROOF COWL (OPEN)', pipeX - 20, marginY - 6);
        }

        // Draw Branch Traps & Pressure indicators on each floor
        for (let f = 1; f <= floors; f++) {
            const trap = system.traps[f - 1];
            const y = h - marginY - (f - 0.5) * floorH;

            // Waste pipe to trap
            ctx.beginPath();
            ctx.moveTo(pipeX, y);
            ctx.lineTo(pipeX - 25, y);
            ctx.lineWidth = 2;
            ctx.strokeStyle = '#475569';
            ctx.stroke();

            // P-Trap Icon
            ctx.beginPath();
            ctx.arc(pipeX - 30, y + 4, 5, 0, Math.PI);
            ctx.lineWidth = 2;
            ctx.strokeStyle = trap.isDepleted ? '#ef4444' : '#38bdf8';
            ctx.stroke();

            // Water seal fill
            if (!trap.isDepleted && trap.currentWaterLevel > 5) {
                ctx.fillStyle = '#38bdf8';
                ctx.beginPath();
                ctx.arc(pipeX - 30, y + 4, 3, 0, Math.PI);
                ctx.fill();
            } else {
                // Bio-hazard cross if depleted
                ctx.fillStyle = '#ef4444';
                ctx.font = 'bold 10px monospace';
                ctx.fillText('⚠ DRY', pipeX - 60, y + 3);
            }
        }
    }

    /**
     * Draw Height vs Air Pressure Profile (Continuous MoC Nodal Curve)
     */
    function drawProfile() {
        const w = profileCanvas.width;
        const h = profileCanvas.height;
        const ctx = profileCtx;

        ctx.clearRect(0, 0, w, h);

        const margin = { top: 25, right: 30, bottom: 25, left: 45 };
        const plotW = w - margin.left - margin.right;
        const plotH = h - margin.top - margin.bottom;

        // Zero Pressure Axis (Center)
        const zeroX = margin.left + plotW / 2;
        ctx.strokeStyle = '#334155';
        ctx.lineWidth = 1;
        ctx.setLineDash([4, 4]);
        ctx.beginPath();
        ctx.moveTo(zeroX, margin.top);
        ctx.lineTo(zeroX, h - margin.bottom);
        ctx.stroke();
        ctx.setLineDash([]);

        // Pressure Scale: -100 mm WG to +100 mm WG
        const maxRange_mmWG = 80.0;
        function pToX(p_mmWG) {
            const clamped = Math.max(-maxRange_mmWG, Math.min(maxRange_mmWG, p_mmWG));
            return zeroX + (clamped / maxRange_mmWG) * (plotW / 2);
        }

        // Draw Safe Trap Seal Limit Boundary (-25 mm to +25 mm WG)
        const safeMinX = pToX(-25.0);
        const safeMaxX = pToX(25.0);
        ctx.fillStyle = 'rgba(16, 185, 129, 0.08)';
        ctx.fillRect(safeMinX, margin.top, safeMaxX - safeMinX, plotH);
        ctx.strokeStyle = 'rgba(16, 185, 129, 0.3)';
        ctx.strokeRect(safeMinX, margin.top, safeMaxX - safeMinX, plotH);

        // Labels
        ctx.fillStyle = '#64748b';
        ctx.font = '10px monospace';
        ctx.fillText('-50 mm', pToX(-50) - 15, h - 8);
        ctx.fillText('0', zeroX - 3, h - 8);
        ctx.fillText('+50 mm', pToX(50) - 15, h - 8);
        ctx.fillText('Safe Operating Zone (±25 mm)', safeMinX + 4, margin.top - 8);

        // Plot Continuous Pressure Profile along Stack
        const N = system.stack.numNodes;
        ctx.beginPath();
        for (let i = 0; i < N; i++) {
            const fraction = i / (N - 1);
            const y = (h - margin.bottom) - fraction * plotH;
            const p_mmWG = AIRNETPhysics.paToMmWG(system.stack.p[i]);
            const x = pToX(p_mmWG);

            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.lineWidth = 3;
        ctx.strokeStyle = '#38bdf8';
        ctx.stroke();

        // Highlight Suction Peak and Backpressure Peak
        let minP = 0, maxP = 0;
        for (let i = 0; i < N; i++) {
            const p = AIRNETPhysics.paToMmWG(system.stack.p[i]);
            if (p < minP) minP = p;
            if (p > maxP) maxP = p;
        }

        ctx.fillStyle = '#38bdf8';
        ctx.font = '11px sans-serif';
        ctx.fillText(`Max Suction: ${minP.toFixed(1)} mm WG`, margin.left, margin.top + 16);
        ctx.fillStyle = maxP > 25.0 ? '#ef4444' : '#10b981';
        ctx.fillText(`Max Pressure: +${maxP.toFixed(1)} mm WG`, margin.left, margin.top + 32);
    }

    /**
     * Draw Real-Time Oscilloscope Time-History Trace
     */
    function drawOscilloscope() {
        const w = scopeCanvas.width;
        const h = scopeCanvas.height;
        const ctx = scopeCtx;

        ctx.clearRect(0, 0, w, h);

        // Grid lines
        ctx.strokeStyle = '#1e293b';
        ctx.lineWidth = 1;
        const zeroY = h / 2;

        ctx.beginPath();
        ctx.moveTo(0, zeroY);
        ctx.lineTo(w, zeroY);
        ctx.stroke();

        if (timeHistory.length < 2) return;

        const maxRange = 60.0; // +/- 60 mm WG
        function valToY(v) {
            return zeroY - (v / maxRange) * (h * 0.42);
        }

        // Trace 1: Stack Base Pressure (Red / Orange)
        ctx.beginPath();
        for (let i = 0; i < timeHistory.length; i++) {
            const x = (i / MAX_HISTORY) * w;
            const y = valToY(timeHistory[i].p_base);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.strokeStyle = '#ef4444';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Trace 2: Stack Mid-Floor Suction (Cyan)
        ctx.beginPath();
        for (let i = 0; i < timeHistory.length; i++) {
            const x = (i / MAX_HISTORY) * w;
            const y = valToY(timeHistory[i].p_mid);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.strokeStyle = '#06b6d4';
        ctx.lineWidth = 1.5;
        ctx.stroke();

        // Trace 3: P.A.P.A. Bladder Volume (Green, scaled)
        if (system.papaUnits.length > 0 && system.papaUnits[0].isActive) {
            ctx.beginPath();
            for (let i = 0; i < timeHistory.length; i++) {
                const x = (i / MAX_HISTORY) * w;
                // scale 0 to 24L across lower half
                const vol = timeHistory[i].papa_vol;
                const y = (h - 10) - (vol / 24.0) * (h * 0.35);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.strokeStyle = '#10b981';
            ctx.lineWidth = 1.5;
            ctx.setLineDash([3, 3]);
            ctx.stroke();
            ctx.setLineDash([]);
        }

        // Legend
        ctx.font = '10px monospace';
        ctx.fillStyle = '#ef4444';
        ctx.fillText('— Stack Base P (mm WG)', 15, 18);
        ctx.fillStyle = '#06b6d4';
        ctx.fillText('— Mid Floor P (mm WG)', 190, 18);
        ctx.fillStyle = '#10b981';
        ctx.fillText('-- P.A.P.A. Volume', 350, 18);
    }

    /**
     * Render Trap Seal Manometer Cards
     */
    function renderTrapList() {
        trapListContainer.innerHTML = '';
        system.traps.forEach(trap => {
            const card = document.createElement('div');
            card.className = `trap-card ${trap.isDepleted ? 'compromised' : ''}`;
            const percent = Math.max(0, Math.min(100, (trap.currentWaterLevel / trap.nominalDepth) * 100));
            let barClass = 'trap-bar-fill';
            if (percent < 30) barClass += ' danger';
            else if (percent < 70) barClass += ' warning';

            card.innerHTML = `
                <div class="trap-header">
                    <span>Floor ${trap.floor} P-Trap</span>
                    <span style="color: ${trap.isDepleted ? '#ef4444' : '#38bdf8'}">
                        ${trap.isDepleted ? 'DEPLETED (0mm)' : `${trap.currentWaterLevel.toFixed(1)} mm`}
                    </span>
                </div>
                <div class="trap-bar-bg">
                    <div class="${barClass}" style="width: ${percent}%;"></div>
                </div>
                ${trap.depletionReason ? `<div style="font-size:0.65rem; color:#ef4444; font-weight:600;">⚠ ${trap.depletionReason}</div>` : ''}
            `;
            trapListContainer.appendChild(card);
        });
    }

    /**
     * Update Telemetry & Metrics
     */
    function updateTelemetry() {
        let minP = 0, maxP = 0;
        const N = system.stack.numNodes;
        for (let i = 0; i < N; i++) {
            const p = AIRNETPhysics.paToMmWG(system.stack.p[i]);
            if (p < minP) minP = p;
            if (p > maxP) maxP = p;
        }

        metricMaxSuction.textContent = `${minP.toFixed(1)} mm`;
        metricMaxBackpressure.textContent = `+${maxP.toFixed(1)} mm`;
        metricSimTime.textContent = `${system.simTime.toFixed(2)} s`;

        const metrics = system.calculateTrapDepletionMetrics();
        metricDepletedCount.textContent = `${metrics.depletedCount} / ${system.floors}`;

        if (metrics.depletedCount > 0) {
            statusPill.className = 'status-pill danger';
            statusText.textContent = `CRITICAL: ${metrics.depletedCount} TRAPS COMPROMISED`;
        } else {
            statusPill.className = 'status-pill';
            statusText.textContent = 'AIRNET SOLVER ACTIVE';
        }

        // Periodically refresh trap cards
        if (Math.floor(system.simTime * 10) % 5 === 0) {
            renderTrapList();
        }
    }

    /**
     * Export Simulation Results to CSV for Engineering Analysis
     */
    function exportSimulationCSV() {
        let csv = 'Time (s),Stack Base P (mm WG),Mid Stack P (mm WG),Roof Vent P (mm WG),PAPA Vol (L)\n';
        timeHistory.forEach(row => {
            csv += `${row.t.toFixed(4)},${row.p_base.toFixed(2)},${row.p_mid.toFixed(2)},${row.p_top.toFixed(2)},${row.papa_vol.toFixed(2)}\n`;
        });

        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `AIRNET_Simulation_Data_${Date.now()}.csv`;
        link.click();
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
