# Huliot FlowLab: EN 12056-2 & Huliot Advanced Flow Systems Standards Specification

> **Document Type:** Comprehensive Regulatory Engineering Specification & Technical Reference  
> **Source Documents:** 
> 1. British / European Standard **BS EN 12056-2:2000** (Pages 11, 16, 25)
> 2. **HULIOT Advanced Flow Systems Technical Manual** (Section 5: Calculation of Flowrate)
> **Date:** 2026-11-11  
> **Status:** Official Master Engineering Reference Document

---

## 1. Waste Water Flowrate Calculation ($Q_{ww}$)

According to **EN 12056-2 Clause 6.3.1**:
$$Q_{ww} = K \cdot \sqrt{\sum DU}$$

Where:
- $Q_{ww}$ = Expected waste water flowrate ($\text{L/s}$)
- $K$ = Frequency factor based on building usage (Clause 6.3.2, Table 3)
- $\sum DU$ = Cumulative sum of discharge units for all connected appliances (Table 2)

### Frequency Factor ($K$) Matrix (Table 3):
| Building Occupancy & Usage Category | $K$ Factor | Description & Application |
|:---|:---:|:---|
| **Intermittent use** | **$0.5$** | Dwellings, Residential Apartments, Guesthouses, Offices |
| **Frequent use** | **$0.7$** | Hospitals, Schools, Restaurants, Hotels |
| **Congested use** | **$1.0$** | Toilets and/or Showers open to Public, Airports, Shopping Malls |
| **Special use** | **$1.2$** | Commercial Laboratories, Heavy Industrial |

---

## 2. Discharge Units ($DU$) & Pipe Diameters Schedule

Comparison of **EN 12056-2 Table 2** (System I) and **Huliot Technical Manual Table 1**:

| Appliance / Fixture | DU (EN 12056-2) | DU (Huliot Manual) | Required Branch DN (mm) | Typical Flow ($q_i$) | Duration |
|:---|:---:|:---:|:---:|:---:|:---:|
| **Wash basin, bidet** | **0.5** | **0.5** | $40\text{ / }50\text{ mm}$ | $0.5\text{ L/s}$ | $15\text{ s}$ |
| **Shower without plug** | **0.6** | **0.6** | $50\text{ mm}$ | $0.6\text{ L/s}$ | $30\text{ s}$ |
| **Shower with plug** | **0.8** | **0.8** | $50\text{ mm}$ | $0.8\text{ L/s}$ | $45\text{ s}$ |
| **Single urinal with cistern** | **0.8** | **0.8** | $50\text{ mm}$ | $0.8\text{ L/s}$ | $10\text{ s}$ |
| **Urinal with flushing valve** | **0.5** | **0.5** | $50\text{ mm}$ | $0.5\text{ L/s}$ | $6\text{ s}$ |
| **Slab urinal** | 0.2 (per person) | 0.2 | $50\text{ mm}$ | $0.2\text{ L/s}$ | - |
| **Bath** | **0.8** | **0.8** | $50\text{ mm}$ | $0.8\text{ L/s}$ | $60\text{ s}$ |
| **Kitchen sink** | **0.8** | **0.8** | $50\text{ mm}$ | $0.8\text{ L/s}$ | $20\text{ s}$ |
| **Dishwasher (household)** | **0.8** | **0.8** | $50\text{ mm}$ | $0.8\text{ L/s}$ | $90\text{ s}$ |
| **Washing machine up to 6 kg** | **0.8** | **0.8** | $50\text{ mm}$ | $0.8\text{ L/s}$ | $120\text{ s}$ |
| **Washing machine up to 12 kg** | **1.5** | **1.5** | $75\text{ mm}$ | $1.5\text{ L/s}$ | $120\text{ s}$ |
| **WC with 6.0 L cistern** | **2.0** | **2.0** | **$110\text{ mm}$** | **$1.8\text{ L/s}$** | **$6.5\text{ s}$** |
| **WC with 7.5 L cistern** | **2.0** | **2.0** | **$110\text{ mm}$** | **$1.9\text{ L/s}$** | **$7.0\text{ s}$** |
| **WC with 9.0 L cistern** | **2.5** | **2.5** | **$110\text{ mm}$** | **$2.2\text{ L/s}$** | **$8.0\text{ s}$** |
| **Floor gully DN 50** | **0.8** | **0.8** | $75\text{ mm}$ | $0.8\text{ L/s}$ | - |
| **Floor gully DN 70** | **1.5** | **1.5** | $75\text{ mm}$ | $1.5\text{ L/s}$ | - |
| **Floor gully DN 100** | **2.0** | **2.0** | $110\text{ mm}$ | $2.0\text{ L/s}$ | - |

---

## 3. Stack Hydraulic Capacity ($Q_{max}$) Limitations

According to **EN 12056-2 Clause 6.5.2, Table 12**:

### Hydraulic Capacity ($Q_{max}$) of Secondary Ventilated Stacks:
| Main Stack & Stack Vent (DN) | Secondary Vent / PRL (DN) | Square Entries ($Q_{max}\text{ L/s}$) | **Huliot Swept Entries ($Q_{max}\text{ L/s}$)** | Capacity Increase with Swept Tee |
|:---:|:---:|:---:|:---:|:---:|
| DN 60 | DN 50 | $0.7\text{ L/s}$ | **$0.9\text{ L/s}$** | **+28.6%** |
| DN 70 | DN 50 | $2.0\text{ L/s}$ | **$2.6\text{ L/s}$** | **+30.0%** |
| DN 80* | DN 50 | $2.6\text{ L/s}$ | **$3.4\text{ L/s}$** | **+30.8%** |
| DN 90 | DN 50 | $3.5\text{ L/s}$ | **$4.6\text{ L/s}$** | **+31.4%** |
| **DN 100 / 110\*\*** | **DN 50** | **$5.6\text{ L/s}$** | **$7.3\text{ L/s}$** | **+30.4%** |
| **DN 125** | **DN 70** | **$7.6\text{ L/s}$** | **$10.0\text{ L/s}$** | **+31.6%** |
| **DN 150** | **DN 80** | **$12.4\text{ L/s}$** | **$18.3\text{ L/s}$** | **+47.6%** |
| **DN 200** | **DN 100** | **$21.0\text{ L/s}$** | **$27.3\text{ L/s}$** | **+30.0%** |

> **Key Standard Constraints:**
> - `*` DN 80 is the minimum size where WCs are connected in System II.
> - `**` **DN 100 (110 mm OD)** is the **mandatory minimum size** where WCs are connected in Systems I, III, and IV.
> - Huliot Swept Tees provide an immediate **+30% to +48% higher hydraulic capacity** across every standard pipe diameter compared to square tee entries!

---

## 4. Air Admittance Valve (AAV) Sizing Rule

According to **EN 12056-2 Clause 6.5.3**:
> *"Where air admittance valves are used to ventilate stacks they shall comply with prEN 12380 and shall be sized with $Q_a$ not less than $8 \times Q_{ww}$."*

$$\mathbf{Q_a \ge 8 \cdot Q_{ww}}$$

Where:
- $Q_a$ = Air flowrate intake of the AAV ($\text{L/s}$)
- $Q_{ww}$ = Waste water flowrate in the stack ($\text{L/s}$)
