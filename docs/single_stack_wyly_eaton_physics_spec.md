# Single Stack Drainage Physics Specification (Wyly-Eaton & BS EN 12056)

**Document Reference:** HULIOT-FLOWLAB-SPEC-003  
**Status:** Architecture Blueprint & Physics Benchmark  
**Standard References:** 
- Wyly, Robert S. & Eaton, Herbert N. (NBS Monograph 31 / BMS 132): *Capacities of Stacks in Sanitary Drainage Systems for Buildings*, Chapter 4: *Analysis of Flow Conditions in Plumbing Stack*.
- BS EN 12056-2:2000 National Annex NC: *Pressure effects and seal losses due to water flow in a discharge stack*.

---

## 1. Physical Foundations of High-Rise Single Stack Drainage

### 1.1 Annular Flow Mechanics
When wastewater enters a vertical drainage stack from branch connections (WC, basins, showers):
1. **Curved Entry & Annular Sheet:** Water hits the opposite wall or wraps around via swept entries, adhering to the internal pipe perimeter to form a hollow cylindrical water sleeve (annular ring flow).
2. **Central Air Core:** The center of the pipe remains open as an uninterrupted air core, allowing continuous atmospheric air intake from the roof vent down through the building.
3. **Equilibrium of Forces:**
   - **Downward Driving Force:** Gravity accelerates the falling water downwards ($g = 9.81\text{ m/s}^2$).
   - **Upward Opposing Forces:**
     1. Pipe-wall frictional shear force ($F_{\text{friction}}$) between the pipe wall and the annular water film.
     2. Interfacial aerodynamic drag ($F_{\text{drag}}$) between the falling water sleeve and the entrained air core.
   - As flow velocity increases, both frictional resistance and aerodynamic drag increase until:
     $$\mathbf{F_{\text{gravity}} = F_{\text{drag}} + F_{\text{friction}}}$$

---

## 2. Core Mathematical Formulations (Wyly & Eaton Monograph)

### 2.1 Terminal Velocity ($V_t$)
When gravitational acceleration is completely balanced by wall friction and air drag, the falling water stops accelerating and reaches its maximum steady-state velocity:
$$V_t = 10.1 \left( \frac{Q}{D} \right)^{2/5}$$

- **$V_t$:** Terminal velocity in meters per second ($\text{m/s}$).
- **$Q$:** Total stack water discharge flow rate in litres per second ($\text{LPS}$ or $\text{L/s}$).
- **$D$:** Internal stack pipe diameter in millimetres ($\text{mm}$).

### 2.2 Terminal Length ($L_t$)
The vertical fall distance required from the point of entry for the water film to reach terminal velocity:
$$L_t = 0.17 \, V_t^2$$

- **$L_t$:** Terminal length in meters ($\text{m}$).
- **$V_t$:** Terminal velocity in $\text{m/s}$.

### 2.3 The High-Rise Invariance Principle
> **"Terminal Velocity in a drainage stack is the same for a 5-floor building and for a 100-floor building."**
- At typical maximum design flows, $V_t \approx 9\text{ m/s}$ ($30\text{ fps}$).
- The corresponding terminal length is:
  $$L_t = 0.17 \times (9)^2 = 13.77\text{ m} \approx 14\text{ m} \quad (\approx 4 \text{ to } 5 \text{ storeys})$$
- **Practical Engineering Consequence:** In a 50-storey or 100-storey building, water does **not** accelerate infinitely down the tower. Past floor 5, velocity stays clamped at $\sim 9\text{ m/s}$. However, because the falling annular sleeve drags air along its entire height, the cumulative air entrainment and base pressure surge escalate drastically unless relieved by a Positive Relief Line (PRL).

---

## 3. Pneumatic Pressure Distribution & Seal Protection (EN 12056 Figure NC.2)

```
        Roof Vent (Open to Atmosphere: 0 mm WG)
              |
              |  [Zone 2: Negative Suction Zone]
              |  Induced siphonage zone pulling water out of upper traps
  Branch Q1 ->|===\
              |    \  Negative Pressure Peak (-25 mm WG limit)
              |     |
  Branch Q2 ->|====/
              |
              |  [Zone 6: Air-Water Annular Terminal Fall]
              |  Velocity constant at Vt, continuous core air drag
              |
              |  [Zero Pressure Inversion Point (Crossover)]
              |
              |  [Zone 5: Positive Backpressure Zone]
              |  Hydraulic jump at base bend converts kinetic energy to backpressure
  Ground F1 ->|====\  Positive Backpressure (+25 mm WG limit)
              |     / Danger of bubbling / trap blowout into living spaces
              +----/
              |====> Base Discharge to Sewer Main
```

### 3.1 Failure Modes Under EN 12056
1. **Negative Pressure Siphonage (Zone 2 & 3):**
   - High velocity annular flow entrains central air, creating a suction depression.
   - If depression exceeds $-25\text{ mm WG}$ ($-250\text{ Pa}$), fixture trap seals are sucked dry into the stack.
2. **Positive Pressure Blowout (Zone 4 & 5):**
   - Near the base bend, water decelerates abruptly (hydraulic jump), obstructing the air core.
   - The trapped air creates positive backpressure.
   - If backpressure exceeds $+25\text{ mm WG}$ ($+250\text{ Pa}$), foul sewer gas bubbles backward through ground floor traps (F1, F2).

---

## 4. Gap Analysis: Current Simulation Code vs. Wyly-Eaton Spec

| Aspect | Current Implementation (`drainage_physics_engine.dart`) | Wyly-Eaton Specific Reference | Analysis & Action Plan |
| :--- | :--- | :--- | :--- |
| **Terminal Velocity Formula** | Navier-Stokes Annular Film: $V_t = \frac{0.75 Q}{\pi D t}$ | Empirical Power Law: $V_t = 10.1 \left(\frac{Q}{D}\right)^{0.4}$ | Both model annular equilibrium; Wyly-Eaton power-law is the plumbing industry benchmark from NBS Monograph 31. |
| **Terminal Length Calculation** | Approximated via wave damping transit | Explicit $L_t = 0.17 V_t^2$ | Can explicitly compute $L_t$ in metres and store in state for display in report. |
| **Velocity Cap Across Height** | Handled via steady terminal velocity | Clamped beyond $L_t \approx 14\text{ m}$ regardless of building height | Matches the principle: 5F vs 100F velocity invariance. |
| **Pressure Profile Shape** | Power weight $s^{1.6}$ from Top Suction to Base Surge | Curve NC.2: Upper negative lobe, neutral crossover, lower positive surge | Matches Figure NC.2 curve geometry with suction top and positive bottom. |

---

## 5. Proposed Implementation Plan (Pending User Approval)

1. **Step 1 (Audit & Align Formulas):**
   - Add Wyly-Eaton empirical relations ($V_t = 10.1 (Q/D)^{0.4}$, $L_t = 0.17 V_t^2$) to physics diagnostics.
2. **Step 2 (Report Technical Enrichment):**
   - In Section 1 of the report, display:
     - Calculated Terminal Velocity $V_t$ ($\text{m/s}$).
     - Calculated Terminal Length $L_t$ ($\text{m}$).
     - Height relative to Terminal Length ($H > L_t$, confirming full annular stabilization).
3. **Step 3 (Zero Simulator Impact During Review):**
   - Keep current simulator code unchanged until explicit approval is granted by user.
