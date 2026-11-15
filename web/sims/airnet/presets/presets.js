/**
 * presets.js - Realistic Engineering Scenarios for AIRNET
 * Formulated from real-world experimental investigations:
 * 1. BS EN 12056-2 Standard Flush Capacity Test
 * 2. High-Rise Stack Base Hydraulic Jump Surcharge (Backpressure Disaster)
 * 3. 2003 Amoy Gardens SARS-CoV Cross-Infection Outbreak Reproduction (Swaffield 2010 Ch. 8)
 * 4. Active Transients Suppression: P.A.P.A.™ + AAV Hybrid Retrofit
 * 5. Kelly et al. (2008) Acoustic Pulse 10Hz Reflection Diagnostic Test
 */

(function(root, factory) {
    if (typeof define === 'function' && define.amd) {
        define([], factory);
    } else if (typeof module === 'object' && module.exports) {
        module.exports = factory();
    } else {
        root.AIRNETPresets = factory();
    }
}(typeof self !== 'undefined' ? self : this, function() {
    'use strict';

    const PRESETS = {
        standard_flush: {
            id: 'standard_flush',
            title: 'EN 12056 Standard Multi-Appliance Flush',
            badge: 'Standard Code Test',
            badgeColor: '#10b981',
            description: 'Realistic domestic peak load with 2.5 L/s WC discharge on Floor 12, open roof vent, and normal base drainage.',
            floors: 15,
            dischargeFloor: 12,
            dischargeRate: 2.5,
            baseSurcharge: false,
            enableAAV: false,
            enablePAPA: false,
            acousticTest: false,
            guidance: 'Watch the annular water downflow accelerate down the stack, drawing an air core suction (negative pressure ~ -15 to -25 mm WG). The trap seals fluctuate safely within the 25 mm allowable limit.'
        },

        stack_surcharge: {
            id: 'stack_surcharge',
            title: 'High-Rise Stack Base Surcharge (Positive Backpressure)',
            badge: 'Danger: Trap Blow-Out',
            badgeColor: '#ef4444',
            description: 'Heavy discharge into undersized or backed-up horizontal drain. The hydraulic jump seals the base, producing dangerous positive pressure transients.',
            floors: 15,
            dischargeFloor: 14,
            dischargeRate: 4.0,
            baseSurcharge: true,
            enableAAV: false,
            enablePAPA: false,
            acousticTest: false,
            guidance: 'Without base pressure relief, the entrained airflow violently decelerates at ground level. Joukowsky surge (+40 mm to +90 mm WG) blows sewer air, pathogens, and water droplets out through low-floor floor drains!'
        },

        active_papa_protection: {
            id: 'active_papa_protection',
            title: 'Active Transient Control: P.A.P.A.™ + AAV Solution',
            badge: 'Engineered Protection',
            badgeColor: '#0ea5e9',
            description: 'Identical heavy surcharge load as Scenario 2, but protected by Studor P.A.P.A.™ variable-volume bladder and high-capacity AAVs.',
            floors: 15,
            dischargeFloor: 14,
            dischargeRate: 4.0,
            baseSurcharge: true,
            enableAAV: true,
            enablePAPA: true,
            papaCapacity: 24.0,
            acousticTest: false,
            guidance: 'As the positive pressure pulse reaches Floor 1-2, the P.A.P.A.™ bag rapidly expands at near-zero resistance, absorbing airflow and blunting the spike to safe levels (< +20 mm WG). All trap seals remain 100% intact!'
        },

        amoy_gardens_sars: {
            id: 'amoy_gardens_sars',
            title: 'Amoy Gardens SARS-CoV Cross-Infection Reproduction',
            badge: 'Historical Forensic Study',
            badgeColor: '#f59e0b',
            description: 'Swaffield (2010) Chapter 8 forensic case: Depleted U-traps on dried bathroom floor drains combined with bathroom exhaust fan depression (-3 to -5 Pa).',
            floors: 15,
            dischargeFloor: 15,
            dischargeRate: 3.5,
            baseSurcharge: false,
            enableAAV: false,
            enablePAPA: false,
            depleteFloors: [7, 8, 9, 10], // Pre-depleted dry floor drains
            acousticTest: false,
            guidance: 'When upper floor apartments flushed, contaminated aerosol plumes were drawn from the drainage stack through dry floor waste traps directly into apartments, causing 321 infections and 42 deaths.'
        },

        acoustic_pulse_diagnostic: {
            id: 'acoustic_pulse_diagnostic',
            title: 'Kelly et al. (2008) Acoustic Pulse Trap Diagnostic',
            badge: 'Non-Invasive NDT',
            badgeColor: '#8b5cf6',
            description: '10 Hz low-amplitude pressure wave probe injected from stack roof to detect depleted appliance traps via wave reflection coefficients.',
            floors: 15,
            dischargeFloor: 0,
            dischargeRate: 0.0,
            baseSurcharge: false,
            enableAAV: false,
            enablePAPA: false,
            depleteFloors: [4, 8],
            acousticTest: true,
            guidance: 'Intact water trap seals produce closed-end wave reflection (C_R = +1.0). Depleted/dry traps create open-pipe reflection (C_R = -1.0) and phase shift, pinpointing compromised barriers without entering apartments!'
        }
    };

    return PRESETS;
}));
