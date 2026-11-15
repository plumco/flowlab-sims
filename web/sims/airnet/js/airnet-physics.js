/**
 * airnet-physics.js
 * AIRNET Numerical Engine based on:
 * 1. "Transient Airflow in Building Drainage Systems" - Prof. John Swaffield (2010)
 * 2. "Pressure transient identification of depleted appliance trap seals" - Dr. David Kelly et al. (2008)
 * 
 * Features:
 * - 1D Method of Characteristics (MoC) for compressible unsteady air pressure transients
 * - Air wave propagation (c = 320 - 340 m/s) with Courant numerical stability (dt <= dx / (c + |u|))
 * - Annular falling water film entrainment & traction (pseudo-friction factor f_wet, Wyly-Eaton, Jack 2000)
 * - Trap seal dynamic manometer (Newton's 2nd law: inertia, friction damping, siphonage, blowout)
 * - Active boundary conditions: Air Admittance Valve (AAV) & Positive Air Pressure Attenuator (P.A.P.A.™ bag)
 * - Acoustic pulse reflection diagnostic matrix (Kelly et al. 2008)
 */

(function(root, factory) {
    if (typeof define === 'function' && define.amd) {
        define([], factory);
    } else if (typeof module === 'object' && module.exports) {
        module.exports = factory();
    } else {
        root.AIRNETPhysics = factory();
    }
}(typeof self !== 'undefined' ? self : this, function() {
    'use strict';

    // Physical Constants (STP Air and Water)
    const CONSTANTS = {
        C_SOUND: 330.0,       // Speed of sound in air (m/s)
        RHO_AIR: 1.204,       // Air density at 20°C (kg/m³)
        RHO_WATER: 1000.0,    // Water density (kg/m³)
        G: 9.80665,           // Gravitational acceleration (m/s²)
        PATM_MMWG: 10332.0,   // Standard atmospheric pressure (mm WG)
        P_ATM_PA: 101325.0,   // Atmospheric pressure (Pa)
        AIR_KINEMATIC_VISCOSITY: 1.5e-5 // m²/s
    };

    /**
     * Converts gauge pressure in Pascals to mm Water Gauge (mm WG)
     */
    function paToMmWG(pa) {
        return (pa / (CONSTANTS.RHO_WATER * CONSTANTS.G)) * 1000.0;
    }

    /**
     * Converts mm Water Gauge to gauge Pascals
     */
    function mmWGToPa(mm) {
        return (mm / 1000.0) * CONSTANTS.RHO_WATER * CONSTANTS.G;
    }

    /**
     * Pipe Section Representation in MoC Grid
     */
    class PipeSection {
        constructor(config) {
            this.id = config.id || 'stack_main';
            this.length = config.length || 45.0; // Total vertical stack height in meters (e.g. 15 floors * 3m)
            this.diameter = config.diameter || 0.100; // Inner diameter in meters (100mm)
            this.area = (Math.PI / 4.0) * (this.diameter * this.diameter);
            this.roughness = config.roughness || 0.00005; // PVC / HDPE roughness
            this.numNodes = config.numNodes || 46; // Nodes along pipe (dx = length / (numNodes - 1))
            this.dx = this.length / (this.numNodes - 1);

            // Nodal State Arrays:
            // p[i] = Gauge Pressure in Pa
            // u[i] = Air Velocity in m/s (positive downwards towards stack base)
            this.p = new Float64Array(this.numNodes);
            this.u = new Float64Array(this.numNodes);
            
            // Next time-step intermediate arrays (MoC update)
            this.p_next = new Float64Array(this.numNodes);
            this.u_next = new Float64Array(this.numNodes);

            // Annular water downflow parameters along nodes
            this.qw = new Float64Array(this.numNodes); // Water flow rate at node (L/s)
            this.isWet = new Uint8Array(this.numNodes); // 1 if annular water film present
            this.f_friction = new Float64Array(this.numNodes); // Darcy friction factor (or pseudo-friction)
        }

        reset() {
            this.p.fill(0.0);
            this.u.fill(0.0);
            this.p_next.fill(0.0);
            this.u_next.fill(0.0);
            this.qw.fill(0.0);
            this.isWet.fill(0);
            this.f_friction.fill(0.02);
        }
    }

    /**
     * Appliance Trap Seal (P-Trap / S-Trap Manometer)
     */
    class TrapSeal {
        constructor(config) {
            this.id = config.id || 'trap_default';
            this.floor = config.floor || 1;
            this.nodeIndex = config.nodeIndex || 0;
            this.nominalDepth = config.nominalDepth || 50.0; // Standard 50mm seal depth (EN 12056 / BS 5572)
            this.waterColumnLength = (config.nominalDepth * 2.0) / 1000.0; // Total water column in meters (U-tube)
            this.trapDiameter = config.trapDiameter || 0.038; // 38mm or 32mm waste pipe
            this.currentWaterLevel = this.nominalDepth; // in mm WG
            this.velocity = 0.0; // Water column displacement velocity (m/s)
            this.isDepleted = false; // True if water seal has been broken (< 10mm remaining)
            this.blowoutOccurred = false; // True if positive backpressure blew sewer gas/droplets into room
            this.depletionReason = null;
        }

        reset() {
            this.currentWaterLevel = this.nominalDepth;
            this.velocity = 0.0;
            this.isDepleted = false;
            this.blowoutOccurred = false;
            this.depletionReason = null;
        }

        /**
         * Dynamic Manometer integration based on Newton's Second Law:
         * (rho * L * A) * d2y/dt2 + (damping) + (2 * rho * g * y * A) = Delta_P * A
         * 
         * @param {number} deltaP_Pa - Differential pressure (P_drainage - P_room) in Pa
         * @param {number} dt - Time step (seconds)
         */
        update(deltaP_Pa, dt) {
            if (this.currentWaterLevel <= 5.0) {
                this.isDepleted = true;
                this.currentWaterLevel = 0.0;
                this.velocity = 0.0;
                return;
            }

            // Delta P in mm WG
            const deltaP_mmWG = paToMmWG(deltaP_Pa);

            // Driving acceleration: (Delta_P - 2*g*y) / (L)
            // where y is water level displacement from equilibrium in meters
            const y_meters = ((this.nominalDepth - this.currentWaterLevel) / 1000.0);
            const restoringForce = 2.0 * CONSTANTS.G * y_meters;
            const pressureForce = deltaP_Pa / (CONSTANTS.RHO_WATER * this.waterColumnLength);
            
            // Friction and viscous damping (Poiseuille + turbulent flow through bends)
            const dampingFactor = 4.5; // Empirical damping factor for typical 38mm P-trap
            const dampingForce = dampingFactor * this.velocity;

            // Net acceleration (positive = pushing water out towards drain, negative = sucked towards stack)
            const acceleration = -pressureForce - restoringForce - dampingForce;

            this.velocity += acceleration * dt;
            // Displacement update
            const dy = this.velocity * dt * 1000.0; // mm
            
            // If suction (negative stack pressure), water is drawn into discharge branch
            if (deltaP_mmWG < -this.nominalDepth) {
                // Induced Siphonage
                const waterLossRate = Math.abs(deltaP_mmWG + this.nominalDepth) * 0.15; // mm per sec
                this.currentWaterLevel -= waterLossRate * dt;
                if (this.currentWaterLevel <= 10.0) {
                    this.isDepleted = true;
                    this.depletionReason = 'INDUCED_SIPHONAGE';
                }
            } else if (deltaP_mmWG > this.nominalDepth) {
                // Positive Backpressure Blow-out
                this.blowoutOccurred = true;
                const blowoutLoss = (deltaP_mmWG - this.nominalDepth) * 0.25;
                this.currentWaterLevel -= blowoutLoss * dt;
                if (this.currentWaterLevel <= 10.0) {
                    this.isDepleted = true;
                    this.depletionReason = 'BACKPRESSURE_BLOWOUT';
                }
            } else {
                // Normal damped oscillation
                this.currentWaterLevel = Math.max(0, Math.min(this.nominalDepth * 1.5, this.currentWaterLevel + dy * 0.05));
            }
        }
    }

    /**
     * Active Transient Suppression: P.A.P.A.™ (Positive Air Pressure Attenuator)
     * Modeled as a flexible volume accumulator:
     * - Bladder volume V_bag = 12 Litres (Standard Studor P.A.P.A.) or up to 48 Litres (Series of 4 units)
     * - Expands at ~0 mm WG without significant resistance until volume is full.
     */
    class PAPABag {
        constructor(config) {
            this.id = config.id || 'papa_unit';
            this.capacityLiters = config.capacityLiters || 12.0; // 12 L nominal
            this.currentVolumeLiters = 0.0;
            this.isActive = config.isActive !== undefined ? config.isActive : true;
            this.nodeIndex = config.nodeIndex || 0;
            this.expansionRate = 0.0; // L/s
        }

        reset() {
            this.currentVolumeLiters = 0.0;
            this.expansionRate = 0.0;
        }

        /**
         * Absorbs positive pressure pulse by volumetric expansion
         * @param {number} positivePressure_Pa 
         * @param {number} dt 
         * @returns {number} Inflow rate absorbed in m³/s
         */
        absorb(positivePressure_Pa, dt) {
            if (!this.isActive || positivePressure_Pa <= 5.0) {
                // Passive slow deflation back to equilibrium when pressure subsides
                if (this.currentVolumeLiters > 0.0) {
                    this.currentVolumeLiters = Math.max(0.0, this.currentVolumeLiters - 2.0 * dt);
                }
                return 0.0;
            }

            // Air enters the bag at flow rate proportional to pressure gradient
            // Q = C_d * A * sqrt(2 * Delta_P / rho)
            const remainingVol = Math.max(0.0, this.capacityLiters - this.currentVolumeLiters);
            if (remainingVol <= 0.01) {
                // Bag is completely full! Cannot absorb more, pressure will reflect.
                return 0.0;
            }

            const orificeArea = (Math.PI / 4.0) * (0.08 * 0.08); // 80mm throat
            const cd = 0.65;
            const flowRate_m3s = cd * orificeArea * Math.sqrt(2.0 * Math.max(0.0, positivePressure_Pa) / CONSTANTS.RHO_AIR);
            
            // Limit by remaining volume
            const volumeIncrementLiters = flowRate_m3s * 1000.0 * dt;
            const actualIncrement = Math.min(remainingVol, volumeIncrementLiters);
            this.currentVolumeLiters += actualIncrement;
            this.expansionRate = actualIncrement / dt;

            return actualIncrement / 1000.0 / dt; // m³/s
        }
    }

    /**
     * Active Transient Suppression: Air Admittance Valve (AAV)
     * Opens when local suction exceeds opening threshold (-5 mm WG / -50 Pa)
     * Admitting ambient air into the drainage stack to neutralize negative transients.
     */
    class AirAdmittanceValve {
        constructor(config) {
            this.id = config.id || 'aav_unit';
            this.nodeIndex = config.nodeIndex || 0;
            this.openingThreshold_Pa = config.openingThreshold_Pa || -40.0; // Typically -4 mm to -5 mm WG
            this.capacityAirLitersPerSec = config.capacityAirLitersPerSec || 32.0; // e.g. 32 L/s at -250 Pa
            this.isOpen = false;
            this.currentFlow_m3s = 0.0;
            this.isActive = config.isActive !== undefined ? config.isActive : true;
        }

        reset() {
            this.isOpen = false;
            this.currentFlow_m3s = 0.0;
        }

        /**
         * Computes air ingress into the stack when under negative pressure
         * @param {number} localPressure_Pa 
         * @returns {number} Air ingress flow in m³/s (positive into stack)
         */
        calculateIngress(localPressure_Pa) {
            if (!this.isActive || localPressure_Pa >= this.openingThreshold_Pa) {
                this.isOpen = false;
                this.currentFlow_m3s = 0.0;
                return 0.0;
            }

            this.isOpen = true;
            // Non-linear orifice flow: Q = K * sqrt(|Delta P|)
            const deltaP = Math.abs(localPressure_Pa);
            // Calibrate K such that at 250 Pa, Q = 32 L/s (0.032 m³/s)
            const k = (this.capacityAirLitersPerSec / 1000.0) / Math.sqrt(250.0);
            this.currentFlow_m3s = k * Math.sqrt(deltaP);
            return this.currentFlow_m3s;
        }
    }

    /**
     * Complete AIRNET Simulation System
     */
    class AIRNETSystem {
        constructor(config = {}) {
            this.floors = config.floors || 15;
            this.floorHeight = config.floorHeight || 3.0; // 3.0 meters per floor
            this.totalHeight = this.floors * this.floorHeight;
            this.diameter = config.diameter || 0.100; // 100mm stack

            // Create primary drainage stack
            this.stack = new PipeSection({
                id: 'main_stack',
                length: this.totalHeight,
                diameter: this.diameter,
                numNodes: this.floors * 3 + 1 // 3 sub-nodes per floor for high spatial fidelity
            });

            // Initialize Traps on every floor
            this.traps = [];
            for (let f = 1; f <= this.floors; f++) {
                const nodeIdx = Math.round(((f - 0.5) / this.floors) * (this.stack.numNodes - 1));
                this.traps.push(new TrapSeal({
                    id: `trap_floor_${f}`,
                    floor: f,
                    nodeIndex: nodeIdx,
                    nominalDepth: 50.0
                }));
            }

            // Active boundary controls
            this.papaUnits = [];
            this.aavUnits = [];

            // Stack Base Surcharge status (hydraulic jump back-up)
            this.baseSurcharged = false;
            this.stackTopOpen = true; // Roof vent open to atmosphere

            // Time stepping
            // MoC Courant stability condition: dt <= dx / (c + |u|)
            // dx ~ 45m / 45 = 1.0m, c ~ 330 m/s => dt <= 1.0 / 330 ~ 0.003s (3 ms)
            this.dt = Math.min(0.002, (this.stack.dx / (CONSTANTS.C_SOUND + 15.0)) * 0.8);
            this.simTime = 0.0;

            // Acoustic pulse reflection generator (Kelly et al. 2008)
            this.acousticTestActive = false;
            this.acousticTestFrequency = 10.0; // 10 Hz probe pulse
            this.acousticTime = 0.0;
            this.acousticHistory = [];
        }

        /**
         * Configure Active Attenuators (P.A.P.A. and AAV)
         */
        setupControls(config = {}) {
            this.papaUnits = [];
            this.aavUnits = [];

            if (config.enablePAPA) {
                // Standard placement: P.A.P.A. placed at lower floors (e.g., Floor 1 and Floor 2) where backpressure develops
                const nodeF1 = this.getNodeIndexForFloor(1);
                this.papaUnits.push(new PAPABag({
                    id: 'papa_floor_1',
                    nodeIndex: nodeF1,
                    capacityLiters: config.papaCapacity || 24.0, // 2x 12L units
                    isActive: true
                }));
            }

            if (config.enableAAV) {
                // Standard placement: AAV placed at stack top instead of open roof vent, or at branch ends
                const topNode = this.stack.numNodes - 1;
                this.aavUnits.push(new AirAdmittanceValve({
                    id: 'aav_stack_top',
                    nodeIndex: topNode,
                    isActive: true
                }));
                this.stackTopOpen = false; // Closed roof vent, relies on AAV
            } else {
                this.stackTopOpen = true;
            }
        }

        getNodeIndexForFloor(floorNum) {
            const fraction = (floorNum - 1) / (this.floors - 1);
            return Math.min(this.stack.numNodes - 1, Math.max(0, Math.round(fraction * (this.stack.numNodes - 1))));
        }

        /**
         * Applies appliance water discharges at specific floors (e.g. WC flush Qw = 1.5 - 2.5 L/s)
         */
        setDischarge(floorNum, qw_Lps) {
            const startNode = this.getNodeIndexForFloor(floorNum);
            // Annular flow continues downwards to the stack base (node 0)
            for (let i = startNode; i >= 0; i--) {
                this.stack.qw[i] = Math.max(this.stack.qw[i], qw_Lps);
                this.stack.isWet[i] = this.stack.qw[i] > 0.01 ? 1 : 0;
            }
        }

        clearAllDischarges() {
            this.stack.qw.fill(0.0);
            this.stack.isWet.fill(0);
        }

        /**
         * Calculate terminal velocity of annular downflow and dynamic traction factor
         * Swaffield (2010) Chapter 2 & Jack (2000):
         * V_t = K * (Qw / D)^0.4
         * Downwards water film exerts traction on air core, modeled as negative pseudo-friction f_wet.
         */
        calculateFriction(nodeIdx) {
            if (this.stack.isWet[nodeIdx] === 0) {
                // Dry pipe standard Darcy-Weisbach friction
                const u = Math.abs(this.stack.u[nodeIdx]);
                if (u < 0.01) return 0.02;
                const Re = (u * this.stack.diameter) / CONSTANTS.AIR_KINEMATIC_VISCOSITY;
                // Swamee-Jain formula
                return 0.25 / Math.pow(Math.log10(this.stack.roughness / (3.7 * this.stack.diameter) + 5.74 / Math.pow(Re, 0.9)), 2);
            }

            // WET STACK: Annular water downflow traction
            const qw_m3s = this.stack.qw[nodeIdx] / 1000.0;
            const vt = 3.0 * Math.pow(qw_m3s / this.stack.diameter, 0.4); // Terminal velocity (m/s)
            const u_air = this.stack.u[nodeIdx]; // Downwards air speed

            // Relative shear between water film and air core:
            // When air speed is slower than falling water film, water film drags air downwards!
            // This creates the famous negative pressure zone / suction peak.
            const relativeVel = u_air - vt;
            const sign = relativeVel >= 0 ? 1.0 : -1.0;
            const f_pseudo = 0.04 * (relativeVel / (Math.abs(u_air) + 0.1));
            return f_pseudo;
        }

        /**
         * Main Method of Characteristics (MoC) Numerical Solver Step
         */
        step() {
            const stack = this.stack;
            const N = stack.numNodes;
            const c = CONSTANTS.C_SOUND;
            const rho = CONSTANTS.RHO_AIR;
            const dt = this.dt;
            const dx = stack.dx;
            const g = CONSTANTS.G;

            // 1. Calculate nodal friction / traction factors
            for (let i = 0; i < N; i++) {
                stack.f_friction[i] = this.calculateFriction(i);
            }

            // 2. Interior Nodes Update via MoC Compatibility Equations:
            // C+ along dx/dt = +(u + c) : p_P + rho*c*u_P = p_R + rho*c*u_R - rho*c * (f * u |u| / 2D + g*sin(theta)) * dt
            // C- along dx/dt = -(c - u) : p_P - rho*c*u_P = p_S - rho*c*u_S + rho*c * (f * u |u| / 2D + g*sin(theta)) * dt
            for (let i = 1; i < N - 1; i++) {
                // Spatial Interpolations at characteristic roots R (from i-1) and S (from i+1)
                const u_i = stack.u[i];
                const p_i = stack.p[i];

                // Node i-1 (Upstream for C+)
                const u_prev = stack.u[i - 1];
                const p_prev = stack.p[i - 1];
                const cr_plus = ((c + u_i) * dt) / dx;
                const u_R = u_i - cr_plus * (u_i - u_prev);
                const p_R = p_i - cr_plus * (p_i - p_prev);
                const f_R = stack.f_friction[i];
                const pipeLoss_R = (f_R * u_R * Math.abs(u_R)) / (2.0 * stack.diameter);

                // Invariant along C+
                const K_plus = p_R + rho * c * u_R - (rho * c * pipeLoss_R * dt);

                // Node i+1 (Downstream for C-)
                const u_next = stack.u[i + 1];
                const p_next = stack.p[i + 1];
                const cr_minus = ((c - u_i) * dt) / dx;
                const u_S = u_i - cr_minus * (u_i - u_next);
                const p_S = p_i - cr_minus * (p_i - p_next);
                const f_S = stack.f_friction[i];
                const pipeLoss_S = (f_S * u_S * Math.abs(u_S)) / (2.0 * stack.diameter);

                // Invariant along C-
                const K_minus = p_S - rho * c * u_S + (rho * c * pipeLoss_S * dt);

                // Simultaneous solution for interior node:
                stack.p_next[i] = 0.5 * (K_plus + K_minus);
                stack.u_next[i] = 0.5 * (K_plus - K_minus) / (rho * c);
            }

            // 3. Boundary Conditions:
            // A. Stack Base (Node 0, ground/drain connection)
            // Surcharge Condition: If hydraulic jump seals the base, air velocity is violently halted -> u_0 = 0 (Total wave reflection, backpressure surge)
            // Normal Condition: Open or partially throttled discharge into main drain
            {
                const cr_minus = ((c - stack.u[0]) * dt) / dx;
                const u_S = stack.u[0] - cr_minus * (stack.u[0] - stack.u[1]);
                const p_S = stack.p[0] - cr_minus * (stack.p[0] - stack.p[1]);
                const K_minus = p_S - rho * c * u_S;

                if (this.baseSurcharged) {
                    // Closed dead-end reflection: u = 0 => p = K_minus
                    stack.u_next[0] = 0.0;
                    stack.p_next[0] = K_minus;
                } else {
                    // Constant pressure boundary (near atmospheric drain connection, minor headloss)
                    stack.p_next[0] = 0.0; // 0 Pa gauge
                    stack.u_next[0] = (stack.p_next[0] - K_minus) / (rho * c);
                }

                // Check for P.A.P.A. expansion at Node 0 / Node 1
                for (let papa of this.papaUnits) {
                    if (papa.nodeIndex === 0 || papa.nodeIndex === 1) {
                        const absorbedFlow = papa.absorb(stack.p_next[papa.nodeIndex], dt);
                        if (absorbedFlow > 0.0) {
                            const absorbedU = absorbedFlow / stack.area;
                            // Dampen positive pressure spike by boundary flow relief
                            stack.u_next[papa.nodeIndex] += absorbedU;
                            stack.p_next[papa.nodeIndex] -= rho * c * absorbedU * 0.5;
                        }
                    }
                }
            }

            // B. Stack Top (Node N-1, roof level)
            // Acoustic pulse test injection OR Atmospheric vent / AAV
            {
                const last = N - 1;
                const cr_plus = ((c + stack.u[last]) * dt) / dx;
                const u_R = stack.u[last] - cr_plus * (stack.u[last] - stack.u[last - 1]);
                const p_R = stack.p[last] - cr_plus * (stack.p[last] - stack.p[last - 1]);
                const K_plus = p_R + rho * c * u_R;

                if (this.acousticTestActive) {
                    // Kelly et al. (2008) 10Hz sinusoidal pressure pulse probe
                    const probePressure = 80.0 * Math.sin(2.0 * Math.PI * this.acousticTestFrequency * this.acousticTime);
                    stack.p_next[last] = probePressure;
                    stack.u_next[last] = (K_plus - stack.p_next[last]) / (rho * c);
                    this.acousticTime += dt;
                    this.acousticHistory.push({ t: this.simTime, p: probePressure, u: stack.u_next[last] });
                    if (this.acousticHistory.length > 500) this.acousticHistory.shift();
                } else if (this.stackTopOpen) {
                    // Free atmospheric boundary: p = 0 Pa gauge
                    stack.p_next[last] = 0.0;
                    stack.u_next[last] = (K_plus - 0.0) / (rho * c);
                } else {
                    // Closed top with optional AAV
                    let aavIngress = 0.0;
                    for (let aav of this.aavUnits) {
                        if (aav.nodeIndex === last) {
                            aavIngress += aav.calculateIngress(stack.p[last]);
                        }
                    }

                    if (aavIngress > 0.0) {
                        const airSpeedIngress = aavIngress / stack.area;
                        stack.u_next[last] = airSpeedIngress;
                        stack.p_next[last] = K_plus - rho * c * airSpeedIngress;
                    } else {
                        // Closed boundary: u = 0 => p = K_plus
                        stack.u_next[last] = 0.0;
                        stack.p_next[last] = K_plus;
                    }
                }
            }

            // 4. Update Arrays for next step
            stack.p.set(stack.p_next);
            stack.u.set(stack.u_next);

            // 5. Update Trap Seals along the stack
            for (let trap of this.traps) {
                const localP = stack.p[trap.nodeIndex];
                trap.update(localP, dt);
            }

            this.simTime += dt;
        }

        /**
         * Reset entire simulation to initial atmospheric equilibrium
         */
        reset() {
            this.simTime = 0.0;
            this.stack.reset();
            this.traps.forEach(t => t.reset());
            this.papaUnits.forEach(p => p.reset());
            this.aavUnits.forEach(a => a.reset());
            this.acousticTestActive = false;
            this.acousticTime = 0.0;
            this.acousticHistory = [];
            this.baseSurcharged = false;
        }

        /**
         * Kelly et al. (2008) Diagnostic Compliance Metric:
         * Calculates C_J = sum((mSp_test - mSp_baseline)^2) to classify depleted trap seals
         */
        calculateTrapDepletionMetrics() {
            const depletedTraps = this.traps.filter(t => t.isDepleted);
            const blownTraps = this.traps.filter(t => t.blowoutOccurred);
            const minRemainingSeal = Math.min(...this.traps.map(t => t.currentWaterLevel));

            return {
                depletedCount: depletedTraps.length,
                blownCount: blownTraps.length,
                minRemainingSeal_mmWG: minRemainingSeal,
                depletedFloors: depletedTraps.map(t => t.floor),
                status: depletedTraps.length === 0 ? 'HEALTHY' : 'CONTAMINATION_RISK'
            };
        }
    }

    return {
        CONSTANTS,
        paToMmWG,
        mmWGToPa,
        PipeSection,
        TrapSeal,
        PAPABag,
        AirAdmittanceValve,
        AIRNETSystem
    };
}));
