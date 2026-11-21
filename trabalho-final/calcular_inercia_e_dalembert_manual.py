#!/usr/bin/env python3
"""
Extração Exata de Massa, CG e Tensor de Inércia via FreeCAD (OpenCascade)
e Análise Dinâmica Completa por D'Alembert — Prensa Manual de Baru (Vertente A - v8)

Modos de execução:
  1) FreeCADCmd calcular_inercia_e_dalembert_manual.py --extract
     (Extrai as propriedades geométricas/inerciais diretamente de prensa_baru_manual_v1.FCStd)
  2) python3 calcular_inercia_e_dalembert_manual.py [--refresh-cad]
     (Executa o solver analítico completo 15x15 Newton-Euler/d'Alembert do mecanismo principal,
      o solver 9x9 do pedal de extração, valida pelo Princípio dos Trabalhos Virtuais e gera
      os gráficos 300 DPI + resumo JSON.)
"""

from __future__ import annotations

import json
import math
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CAD_PATH = os.path.join(SCRIPT_DIR, "prensa_baru_manual_v1.FCStd")
JSON_INERTIA_PATH = os.path.join(SCRIPT_DIR, "propriedades_inerciais_freecad_manual_v1.json")
JSON_RESULTS_PATH = os.path.join(SCRIPT_DIR, "resultados_dalembert_manual_v1.json")
ASSETS_REPO = os.path.join(SCRIPT_DIR, "assets")
VAULT_DIR = "/home/guimentzer/vault/Dinâmica das Máquinas/Trabalho Final 1"
ASSETS_VAULT = os.path.join(VAULT_DIR, "assets")

# =========================================================================================
# 1. CONSTANTES FÍSICAS E GEOMÉTRICAS DO PROJETO (IDÊNTICAS AO GERADOR CAD v8)
# =========================================================================================
G_ACCEL = 9.80665  # m/s^2

RHO_MAP = {
    "aco": 7850.0,       # kg/m^3 — Aço ABNT 1020 / SAE 1045 / SAE 5160 / Chapa Galv.
    "bronze": 8930.0,    # kg/m^3 — Bronze TM-23 / SAE 660 (buchas)
    "borracha": 1200.0,  # kg/m^3 — Elastômero NBR 70 / Manopla
    "uhmw": 935.0,       # kg/m^3 — Polietileno de Ultra-Alto Peso Molecular
    "pc": 1200.0,        # kg/m^3 — Policarbonato compacto (visor NR-12)
    "baru": 1100.0,      # kg/m^3 — Endocarpo lenhoso simulado (apenas referência visual)
}

# Tabela material -> objeto CAD (46 Part::Feature de prensa_baru_manual_v1.FCStd)
OBJ_CATALOG = {
    # Subconjunto 01 - Estator interno & Guia
    "Chapa_Base_Estrutural": ("aco", "Sub01_Estator"),
    "Portico_Estrutural_Traseiro": ("aco", "Sub01_Estator"),
    "Portico_Estrutural_Frontal": ("aco", "Sub01_Estator"),
    "Espacadores_Transversais_Portico": ("aco", "Sub01_Estator"),
    "Batentes_Pinos_Soldados_PMS_PMI": ("aco", "Sub01_Estator"),
    "Suporte_Baru_Cantoneira": ("aco", "Sub01_Estator"),
    "Guia_Pistao_Chapa_U": ("aco", "Sub01_Estator"),
    "Parafusos_Guia_Pistao_M8": ("aco", "Sub01_Estator"),
    "Tiras_Desgaste_UHMW_5mm": ("uhmw", "Sub01_Estator"),
    "Buchas_Catalogo_Estator": ("bronze", "Sub01_Estator"),
    "Pino_Eixo_O4": ("aco", "Sub01_Estator"),
    "Aneis_Retencao_ORing_O4": ("borracha", "Sub01_Estator"),
    # Subconjunto 02 - Alavanca em L + Eixo O2
    "Conjunto_Soldado_L2_Alavanca_O2": ("aco", "Corpo2_O2"),
    "Buchas_Catalogo_A": ("bronze", "Corpo2_O2"),
    "Manopla_Empunhadura_Borracha": ("borracha", "Corpo2_O2"),
    "Pino_Eixo_A": ("aco", "Corpo2_O2"),
    "Aneis_Retencao_ORing_A": ("borracha", "Corpo2_O2"),
    # Subconjunto 03 - Biela Acopladora L3
    "Elo3_Biela_L3": ("aco", "Corpo3_L3"),
    "Buchas_Catalogo_L3": ("bronze", "Corpo3_L3"),
    # Subconjunto 04 - Balancim Principal L4
    "Elo4_Balancim_L4": ("aco", "Corpo4_L4"),
    "Buchas_Catalogo_L4": ("bronze", "Corpo4_L4"),
    # Subconjunto 05 - Garfo Duplo L5 + Pino B
    "Elo5_Garfo_Duplo_L5": ("aco", "Corpo5_L5"),
    "Buchas_Catalogo_L5": ("bronze", "Corpo5_L5"),
    "Pino_Eixo_B": ("aco", "Corpo5_L5"),
    "Aneis_Retencao_ORing_B": ("borracha", "Corpo5_L5"),
    # Subconjunto 06 - Pistão-Navalha O5 (translação Z)
    "Pistao_Embolo_Quadrado": ("aco", "Corpo6_O5"),
    "Navalha_Corte_SAE5160": ("aco", "Corpo6_O5"),
    "Parafusos_Fixacao_Navalha_M6": ("aco", "Corpo6_O5"),
    "Bucha_Catalogo_O5": ("bronze", "Corpo6_O5"),
    "Pino_Eixo_O5": ("aco", "Corpo6_O5"),
    "Aneis_Retencao_ORing_O5": ("borracha", "Corpo6_O5"),
    # Subconjunto 07 - Cavalete 1,5m, Moega, Reservatório e Pedal
    "Quadro_Tubular_Metalon_20x20": ("aco", "Sub07_Cavalete_Gabinete"),
    "Sapatas_Ancoragem_Piso": ("aco", "Sub07_Cavalete_Gabinete"),
    "Carenagem_Chapa_Galvanizada": ("aco", "Sub07_Cavalete_Gabinete"),
    "Visor_Policarbonato_NR12": ("pc", "Sub07_Cavalete_Gabinete"),
    "Calha_Alimentacao_Segura_NR12": ("aco", "Sub07_Cavalete_Gabinete"),
    "Reservatorio_Alimentacao_Chapa": ("aco", "Sub07_Cavalete_Gabinete"),
    "Parafusos_Fixacao_Gabinete_M6": ("aco", "Sub07_Cavalete_Gabinete"),
    "Calha_Descarga_Chapa": ("aco", "Sub07_Cavalete_Gabinete"),
    "Reservatorio_Chapa_Coleta": ("aco", "Sub07_Cavalete_Gabinete"),
    "Suporte_Eixo_Ejetor_NR12": ("aco", "Sub07_Cavalete_Gabinete"),
    "Mola_Retorno_Pedal": ("aco", "Sub07_Cavalete_Gabinete"),
    "Alavanca_Ejetora_Pedal": ("aco", "Pedal_Alavanca_Ejetora"),
    "Tirante_Pedal_Extracao": ("aco", "Pedal_Tirante"),
    "Pedal_Extracao": ("aco", "Pedal_Piso"),
    # Subconjunto 08 - Corpo de Prova
    "Baru_Simulado_30x50x40": ("baru", "Sub08_Corpo_Prova"),
}

# Parâmetros cinemáticos do mecanismo principal (em SI: metros, radianos)
Z_WORK_DATUM = 0.980
O4_X, O4_Z = 0.0, Z_WORK_DATUM + 0.4675          # (0.0, 1.4475) m
O2_X, O2_Z = 0.0316018, Z_WORK_DATUM + 0.3088482 # (0.0316018, 1.2888482) m
H_CURSO = 0.030
DTH4_RAD = math.radians(30.0)
L4 = H_CURSO / (2.0 * (1.0 - math.cos(DTH4_RAD)))  # 0.1119615242 m
L5 = L4
L2 = 0.070
L3 = 0.100
DELTA_L_DEG = 50.0
TH2_PMS_DEG = 80.0
TH2_PMI_DEG = 20.0
DTH2_RAD = math.radians(TH2_PMS_DEG - TH2_PMI_DEG)  # 60 deg = pi/3 rad
R_GRIP_MID = 0.540  # Centro da manopla D32x120 (m)
R_GRIP_TIP = 0.600  # Ponta externa da alavanca (m)

O5_Z_PMI = O4_Z - 2.0 * L4                         # 1.223576952 m
Z_TIP_PMI = Z_WORK_DATUM + 0.0575                  # 1.0375 m
H_O5_TO_TIP = O5_Z_PMI - Z_TIP_PMI                 # 0.186076952 m
Z_BARU_TOP = 1.04225                               # Corte efetivo = 4.75 mm
Z_CANTONEIRA_CUT = 4.75e-3                         # m
F_QUEBRA_MAX = 5000.0                              # N

# Parâmetros cinemáticos do sistema 4-barras de extração por pedal (SI: metros)
O_EXT_X, O_EXT_Z = 0.034, Z_WORK_DATUM + 0.016     # (0.034, 0.996) m
EXT_CRANK_DX, EXT_CRANK_DZ = 0.084, 0.054          # m
EXT_R_CRANK = math.hypot(EXT_CRANK_DX, EXT_CRANK_DZ)
EXT_PHI0 = math.atan2(EXT_CRANK_DZ, EXT_CRANK_DX)  # ângulo no repouso (psi=0)
PED_PIVOT_X, PED_PIVOT_Z = 0.0, 0.205              # m
PED_PIN_DX0, PED_PIN_DZ0 = 0.166, 0.019            # m
PED_R_EFF = math.hypot(PED_PIN_DX0, PED_PIN_DZ0)   # 0.1670838 m
PED_THETA0 = math.atan2(PED_PIN_DZ0, PED_PIN_DX0)  # +6.5295 deg
PED_ROD_LEN = math.hypot(
    (O_EXT_X + EXT_CRANK_DX) - (PED_PIVOT_X + PED_PIN_DX0),
    (O_EXT_Z + EXT_CRANK_DZ) - (PED_PIVOT_Z + PED_PIN_DZ0),
)  # 0.8273935 m
PED_PAD_CENTER_X = 0.540  # Centro da sapata do pedal (X in [490, 590] mm)


# =========================================================================================
# 2. EXTRAÇÃO DIRETA DO FREECAD (OPENCASCADE)
# =========================================================================================
def extract_from_freecad() -> dict:
    import FreeCAD as App

    if "prensa_baru_manual_v1" in App.listDocuments():
        doc = App.getDocument("prensa_baru_manual_v1")
    else:
        doc = App.openDocument(CAD_PATH)

    def shape_props_local(obj, rho_kg_m3: float) -> dict:
        rho_mm3 = rho_kg_m3 * 1e-9
        inv_m = obj.Placement.inverse().toMatrix()
        loc = obj.Shape.copy()
        loc.transformShape(inv_m)
        sols = loc.Solids if len(loc.Solids) > 0 else [loc]
        v_tot = 0.0
        m_tot = 0.0
        sx = sy = sz = 0.0
        sol_data = []
        for s in sols:
            v = float(s.Volume)
            m = v * rho_mm3
            cg = s.CenterOfGravity
            mat = s.MatrixOfInertia
            v_tot += v
            m_tot += m
            sx += m * cg.x
            sy += m * cg.y
            sz += m * cg.z
            sol_data.append((m, cg, mat))
        cmx, cmy, cmz = sx / m_tot, sy / m_tot, sz / m_tot

        Ixx = Iyy = Izz = 0.0
        for m, cg, mat in sol_data:
            dx = (cg.x - cmx) * 1e-3
            dy = (cg.y - cmy) * 1e-3
            dz = (cg.z - cmz) * 1e-3
            Ixx += float(mat.A11) * rho_kg_m3 * 1e-15 + m * (dy * dy + dz * dz)
            Iyy += float(mat.A22) * rho_kg_m3 * 1e-15 + m * (dx * dx + dz * dz)
            Izz += float(mat.A33) * rho_kg_m3 * 1e-15 + m * (dx * dx + dy * dy)
        Iyy_orig = Iyy + m_tot * ((cmx * 1e-3) ** 2 + (cmz * 1e-3) ** 2)
        return {
            "name": obj.Name,
            "label": obj.Label,
            "solids": len(sols),
            "vol_cm3": v_tot * 1e-3,
            "mass_kg": m_tot,
            "cg_local_mm": [cmx, cmy, cmz],
            "Ixx_cg_kg_m2": Ixx,
            "Iyy_cg_kg_m2": Iyy,
            "Izz_cg_kg_m2": Izz,
            "Iyy_orig_kg_m2": Iyy_orig,
        }

    parts = {}
    groups_items = {}
    for obj in doc.Objects:
        if obj.TypeId != "Part::Feature":
            continue
        if obj.Name not in OBJ_CATALOG:
            raise KeyError(f"Objeto inesperado no CAD: {obj.Name}")
        mat_key, grp = OBJ_CATALOG[obj.Name]
        rho_val = RHO_MAP[mat_key]
        fc_mat_name = mat_key
        if hasattr(obj, "ShapeMaterial") and obj.ShapeMaterial and obj.ShapeMaterial.Name != "Default":
            fc_mat_name = obj.ShapeMaterial.Name
            if obj.ShapeMaterial.hasPhysicalProperty("Density"):
                rho_val = float(obj.ShapeMaterial.getPhysicalValue("Density").getValueAs("kg/m^3"))
        props = shape_props_local(obj, rho_val)
        props["material"] = mat_key
        props["freecad_material"] = fc_mat_name
        props["density_kg_m3"] = rho_val
        props["group"] = grp
        parts[obj.Name] = props
        groups_items.setdefault(grp, []).append(props)

    groups_summary = {}
    for grp, items in groups_items.items():
        m_g = sum(p["mass_kg"] for p in items)
        v_g = sum(p["vol_cm3"] for p in items)
        cmx = sum(p["mass_kg"] * p["cg_local_mm"][0] for p in items) / m_g
        cmy = sum(p["mass_kg"] * p["cg_local_mm"][1] for p in items) / m_g
        cmz = sum(p["mass_kg"] * p["cg_local_mm"][2] for p in items) / m_g
        Ixx_g = Iyy_g = Izz_g = 0.0
        for p in items:
            dx = (p["cg_local_mm"][0] - cmx) * 1e-3
            dy = (p["cg_local_mm"][1] - cmy) * 1e-3
            dz = (p["cg_local_mm"][2] - cmz) * 1e-3
            Ixx_g += p["Ixx_cg_kg_m2"] + p["mass_kg"] * (dy * dy + dz * dz)
            Iyy_g += p["Iyy_cg_kg_m2"] + p["mass_kg"] * (dx * dx + dz * dz)
            Izz_g += p["Izz_cg_kg_m2"] + p["mass_kg"] * (dx * dx + dy * dy)
        Iyy_orig = Iyy_g + m_g * ((cmx * 1e-3) ** 2 + (cmz * 1e-3) ** 2)
        groups_summary[grp] = {
            "parts": [p["name"] for p in items],
            "vol_cm3": v_g,
            "mass_kg": m_g,
            "cg_local_mm": [cmx, cmy, cmz],
            "Ixx_cg_kg_m2": Ixx_g,
            "Iyy_cg_kg_m2": Iyy_g,
            "Izz_cg_kg_m2": Izz_g,
            "Iyy_orig_kg_m2": Iyy_orig,
        }

    total_machine_mass = sum(
        p["mass_kg"] for nm, p in parts.items() if nm != "Baru_Simulado_30x50x40"
    )
    moving_main_mass = sum(
        groups_summary[g]["mass_kg"]
        for g in ("Corpo2_O2", "Corpo3_L3", "Corpo4_L4", "Corpo5_L5", "Corpo6_O5")
    )
    moving_pedal_mass = sum(
        groups_summary[g]["mass_kg"]
        for g in ("Pedal_Alavanca_Ejetora", "Pedal_Tirante", "Pedal_Piso")
    )

    payload = {
        "cad_file": CAD_PATH,
        "densities_kg_m3": RHO_MAP,
        "parts": parts,
        "groups": groups_summary,
        "totals": {
            "total_machine_mass_kg": total_machine_mass,
            "moving_main_mass_kg": moving_main_mass,
            "moving_pedal_mass_kg": moving_pedal_mass,
            "static_structure_mass_kg": total_machine_mass - moving_main_mass - moving_pedal_mass,
        },
    }
    with open(JSON_INERTIA_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
    print(f"[FreeCAD] Propriedades extraídas para {JSON_INERTIA_PATH}")
    print(f"[FreeCAD] Massa total máquina = {total_machine_mass:.4f} kg | Móvel principal = {moving_main_mass:.4f} kg | Móvel pedal = {moving_pedal_mass:.4f} kg")
    return payload


# =========================================================================================
# 3. SOLVER CINEMÁTICO + D'ALEMBERT 15x15 (MECANISMO PRINCIPAL)
# =========================================================================================
def run_main_mechanism_dalembert(inertia_data: dict, T1: float = 1.0, T2: float = 2.0, N: int = 1201):
    import numpy as np

    groups = inertia_data["groups"]
    m2 = groups["Corpo2_O2"]["mass_kg"]
    m3 = groups["Corpo3_L3"]["mass_kg"]
    m4 = groups["Corpo4_L4"]["mass_kg"]
    m5 = groups["Corpo5_L5"]["mass_kg"]
    m6 = groups["Corpo6_O5"]["mass_kg"]

    IG2 = groups["Corpo2_O2"]["Iyy_cg_kg_m2"]
    IG3 = groups["Corpo3_L3"]["Iyy_cg_kg_m2"]
    IG4 = groups["Corpo4_L4"]["Iyy_cg_kg_m2"]
    IG5 = groups["Corpo5_L5"]["Iyy_cg_kg_m2"]
    IG6 = groups["Corpo6_O5"]["Iyy_cg_kg_m2"]

    cg2_loc = np.array([groups["Corpo2_O2"]["cg_local_mm"][0], groups["Corpo2_O2"]["cg_local_mm"][2]]) * 1e-3
    cg3_loc = np.array([groups["Corpo3_L3"]["cg_local_mm"][0], groups["Corpo3_L3"]["cg_local_mm"][2]]) * 1e-3
    cg4_loc = np.array([groups["Corpo4_L4"]["cg_local_mm"][0], groups["Corpo4_L4"]["cg_local_mm"][2]]) * 1e-3
    cg5_loc = np.array([groups["Corpo5_L5"]["cg_local_mm"][0], groups["Corpo5_L5"]["cg_local_mm"][2]]) * 1e-3
    cg6_loc = np.array([groups["Corpo6_O5"]["cg_local_mm"][0], groups["Corpo6_O5"]["cg_local_mm"][2]]) * 1e-3

    th_pms = math.radians(TH2_PMS_DEG)
    th_pmi = math.radians(TH2_PMI_DEG)
    T_tot = T1 + T2
    t = np.linspace(0.0, T_tot, N)

    # Lei harmônica suave (descida T1 + subida T2)
    th2 = np.zeros(N)
    w2 = np.zeros(N)
    al2 = np.zeros(N)
    for k, tk in enumerate(t):
        if tk <= T1:
            th2[k] = th_pms - 0.5 * DTH2_RAD * (1.0 - math.cos(math.pi * tk / T1))
            w2[k] = -0.5 * DTH2_RAD * (math.pi / T1) * math.sin(math.pi * tk / T1)
            al2[k] = -0.5 * DTH2_RAD * ((math.pi / T1) ** 2) * math.cos(math.pi * tk / T1)
        else:
            tau = tk - T1
            th2[k] = th_pmi + 0.5 * DTH2_RAD * (1.0 - math.cos(math.pi * tau / T2))
            w2[k] = 0.5 * DTH2_RAD * (math.pi / T2) * math.sin(math.pi * tau / T2)
            al2[k] = 0.5 * DTH2_RAD * ((math.pi / T2) ** 2) * math.cos(math.pi * tau / T2)

    O2 = np.array([O2_X, O2_Z])
    O4 = np.array([O4_X, O4_Z])

    # Matrizes de resultados temporais
    keys_vec2 = ("th3", "th4", "th5", "w3", "w4", "w5", "al3", "al4", "al5",
                 "zO5", "z_tip", "vO5_z", "aO5_z", "mu_deg", "Ek", "dEk_dt",
                 "T12_in", "T12_vw", "T12_grav", "T12_cut_bio", "T12_cut_lin",
                 "T12_total_bio", "F_hand_in", "F_hand_grav", "F_hand_bio", "F_hand_total_bio")
    out = {k: np.zeros(N) for k in keys_vec2}
    for i in (2, 3, 4, 5, 6):
        out[f"aG{i}_mag"] = np.zeros(N)
        out[f"Fin{i}_mag"] = np.zeros(N)
        out[f"Tin{i}"] = np.zeros(N)
    for j in ("O2", "A", "B3", "B4", "B5", "O4", "O5", "N16", "M16"):
        out[f"R_{j}_in"] = np.zeros(N)
        out[f"R_{j}_cut_bio"] = np.zeros(N)
        out[f"R_{j}_grav"] = np.zeros(N)
        out[f"R_{j}_tot"] = np.zeros(N)

    def body_cg_kin(P, vP, aP, theta, w, al, loc_xz):
        c, s = math.cos(theta), math.sin(theta)
        r = np.array([loc_xz[0] * c - loc_xz[1] * s, loc_xz[0] * s + loc_xz[1] * c])
        r_perp = np.array([-r[1], r[0]])
        G = P + r
        vG = vP + w * r_perp
        aG = aP + al * r_perp - (w * w) * r
        return G, vG, aG

    for k in range(N):
        t2 = th2[k]
        Ax = O2_X + L2 * math.cos(t2)
        Az = O2_Z + L2 * math.sin(t2)
        A = np.array([Ax, Az])
        dx, dz = Ax - O4_X, Az - O4_Z
        dA = math.hypot(dx, dz)
        ac = (L4 * L4 - L3 * L3 + dA * dA) / (2.0 * dA)
        hc = math.sqrt(max(0.0, L4 * L4 - ac * ac))
        Bx = O4_X + ac * dx / dA + hc * dz / dA
        Bz = O4_Z + ac * dz / dA - hc * dx / dA
        B = np.array([Bx, Bz])

        t3 = math.atan2(Bz - Az, Bx - Ax)
        t4 = math.atan2(Bz - O4_Z, Bx - O4_X)
        zO5 = Bz - math.sqrt(max(0.0, L5 * L5 - Bx * Bx))
        O5 = np.array([0.0, zO5])
        t5 = math.atan2(zO5 - Bz, -Bx)

        da = abs(t4 - t3) % (2.0 * math.pi)
        if da > math.pi:
            da = 2.0 * math.pi - da
        out["mu_deg"][k] = math.degrees(da)
        out["th3"][k], out["th4"][k], out["th5"][k] = t3, t4, t5
        out["zO5"][k] = zO5
        z_tip = zO5 - H_O5_TO_TIP
        out["z_tip"][k] = z_tip

        # Velocidades e acelerações angulares analíticas
        J1 = np.array([
            [-L3 * math.sin(t3), L4 * math.sin(t4)],
            [ L3 * math.cos(t3), -L4 * math.cos(t4)],
        ])
        b_vel = np.array([L2 * w2[k] * math.sin(t2), -L2 * w2[k] * math.cos(t2)])
        w3, w4 = np.linalg.solve(J1, b_vel)

        b_acc = np.array([
            L2 * al2[k] * math.sin(t2) + L2 * (w2[k] ** 2) * math.cos(t2)
            + L3 * (w3 ** 2) * math.cos(t3) - L4 * (w4 ** 2) * math.cos(t4),
            -L2 * al2[k] * math.cos(t2) + L2 * (w2[k] ** 2) * math.sin(t2)
            + L3 * (w3 ** 2) * math.sin(t3) - L4 * (w4 ** 2) * math.sin(t4),
        ])
        al3, al4 = np.linalg.solve(J1, b_acc)

        vA = L2 * w2[k] * np.array([-math.sin(t2), math.cos(t2)])
        aA = L2 * al2[k] * np.array([-math.sin(t2), math.cos(t2)]) - L2 * (w2[k] ** 2) * np.array([math.cos(t2), math.sin(t2)])
        vB = L4 * w4 * np.array([-math.sin(t4), math.cos(t4)])
        aB = L4 * al4 * np.array([-math.sin(t4), math.cos(t4)]) - L4 * (w4 ** 2) * np.array([math.cos(t4), math.sin(t4)])

        w5 = vB[0] / (L5 * math.sin(t5))
        al5 = (aB[0] - L5 * (w5 ** 2) * math.cos(t5)) / (L5 * math.sin(t5))

        vO5 = np.array([0.0, vB[1] + L5 * w5 * math.cos(t5)])
        aO5 = np.array([0.0, aB[1] + L5 * al5 * math.cos(t5) - L5 * (w5 ** 2) * math.sin(t5)])

        out["w3"][k], out["w4"][k], out["w5"][k] = w3, w4, w5
        out["al3"][k], out["al4"][k], out["al5"][k] = al3, al4, al5
        out["vO5_z"][k], out["aO5_z"][k] = vO5[1], aO5[1]

        # Cinemática exata dos CGs (usando os vetores CG 3D do FreeCAD)
        G2, vG2, aG2 = body_cg_kin(O2, np.zeros(2), np.zeros(2), t2, w2[k], al2[k], cg2_loc)
        G3, vG3, aG3 = body_cg_kin(A, vA, aA, t3, w3, al3, cg3_loc)
        G4, vG4, aG4 = body_cg_kin(O4, np.zeros(2), np.zeros(2), t4, w4, al4, cg4_loc)
        G5, vG5, aG5 = body_cg_kin(B, vB, aB, t5, w5, al5, cg5_loc)
        G6, vG6, aG6 = O5 + cg6_loc, vO5, aO5

        masses = (m2, m3, m4, m5, m6)
        inertias = (IG2, IG3, IG4, IG5, IG6)
        vs = (vG2, vG3, vG4, vG5, vG6)
        acs = (aG2, aG3, aG4, aG5, aG6)
        ws = (w2[k], w3, w4, w5, 0.0)
        als = (al2[k], al3, al4, al5, 0.0)

        Ek = 0.0
        dEk_dt = 0.0
        for idx_b, (mi, Ii, vi, ai, wi, ali) in enumerate(zip(masses, inertias, vs, acs, ws, als), start=2):
            Ek += 0.5 * mi * float(np.dot(vi, vi)) + 0.5 * Ii * (wi ** 2)
            dEk_dt += mi * float(np.dot(vi, ai)) + Ii * wi * ali
            out[f"aG{idx_b}_mag"][k] = float(np.linalg.norm(ai))
            out[f"Fin{idx_b}_mag"][k] = mi * float(np.linalg.norm(ai))
            out[f"Tin{idx_b}"][k] = -Ii * ali

        out["Ek"][k] = Ek
        out["dEk_dt"][k] = dEk_dt

        # Matriz 15x15 Newton-Euler A(theta2) * x = b
        # Incógnitas x:
        # 0:F12x, 1:F12z, 2:F23x, 3:F23z, 4:F3Bx, 5:F3Bz, 6:F14x, 7:F14z,
        # 8:F4Bx, 9:F4Bz, 10:F56x, 11:F56z, 12:N16x, 13:M16, 14:T12
        M = np.zeros((15, 15))

        def cross_2d_row(row_idx, col_fx, col_fz, r_vec, sign=1.0):
            # sign * (r_x * F_z - r_z * F_x)
            M[row_idx, col_fx] += -sign * r_vec[1]
            M[row_idx, col_fz] += sign * r_vec[0]

        # Corpo 2
        M[0, 0] = 1.0; M[0, 2] = -1.0
        M[1, 1] = 1.0; M[1, 3] = -1.0
        cross_2d_row(2, 0, 1, O2 - G2, +1.0)
        cross_2d_row(2, 2, 3, A - G2, -1.0)
        M[2, 14] = 1.0

        # Corpo 3
        M[3, 2] = 1.0; M[3, 4] = -1.0
        M[4, 3] = 1.0; M[4, 5] = -1.0
        cross_2d_row(5, 2, 3, A - G3, +1.0)
        cross_2d_row(5, 4, 5, B - G3, -1.0)

        # Corpo 4
        M[6, 6] = 1.0; M[6, 8] = -1.0
        M[7, 7] = 1.0; M[7, 9] = -1.0
        cross_2d_row(8, 6, 7, O4 - G4, +1.0)
        cross_2d_row(8, 8, 9, B - G4, -1.0)

        # Corpo 5 (-F5B = F3B + F4B)
        M[9, 4] = 1.0; M[9, 8] = 1.0; M[9, 10] = -1.0
        M[10, 5] = 1.0; M[10, 9] = 1.0; M[10, 11] = -1.0
        cross_2d_row(11, 4, 5, B - G5, +1.0)
        cross_2d_row(11, 8, 9, B - G5, +1.0)
        cross_2d_row(11, 10, 11, O5 - G5, -1.0)

        # Corpo 6 (Translação em Z; guia absorve N16x e momento M16)
        M[12, 10] = 1.0; M[12, 12] = 1.0
        M[13, 11] = 1.0
        cross_2d_row(14, 10, 11, O5 - G6, +1.0)
        M[14, 13] = 1.0

        # 1) Carga puramente inercial (d'Alembert)
        b_in = np.array([
            m2 * aG2[0], m2 * aG2[1], IG2 * al2[k],
            m3 * aG3[0], m3 * aG3[1], IG3 * al3,
            m4 * aG4[0], m4 * aG4[1], IG4 * al4,
            m5 * aG5[0], m5 * aG5[1], IG5 * al5,
            m6 * aG6[0], m6 * aG6[1], IG6 * 0.0,
        ])
        x_in = np.linalg.solve(M, b_in)

        # 2) Carga gravitacional pura (m_i * g em -Z => lado esquerdo tem -m_i*g, logo b = +m_i*g)
        b_grav = np.array([
            0.0, m2 * G_ACCEL, 0.0,
            0.0, m3 * G_ACCEL, 0.0,
            0.0, m4 * G_ACCEL, 0.0,
            0.0, m5 * G_ACCEL, 0.0,
            0.0, m6 * G_ACCEL, 0.0,
        ])
        x_grav = np.linalg.solve(M, b_grav)

        # 3) Carga de corte do baru na descida (t <= T1 e z_tip <= Z_BARU_TOP)
        # Baru exerce reação para CIMA (+Z) sobre a navalha: R_baru_z = +F_corte -> no LHS aparece +F_corte -> RHS = -F_corte
        if t[k] <= T1 and z_tip < Z_BARU_TOP:
            s_pen = min(1.0, max(0.0, (Z_BARU_TOP - z_tip) / Z_CANTONEIRA_CUT))
            F_cut_bio = F_QUEBRA_MAX * (s_pen ** 0.4)
            F_cut_lin = F_QUEBRA_MAX * s_pen
        else:
            F_cut_bio = 0.0
            F_cut_lin = 0.0

        b_cut_bio = np.zeros(15)
        b_cut_bio[13] = -F_cut_bio
        x_cut_bio = np.linalg.solve(M, b_cut_bio)

        b_cut_lin = np.zeros(15)
        b_cut_lin[13] = -F_cut_lin
        x_cut_lin = np.linalg.solve(M, b_cut_lin)

        x_tot = x_in + x_grav + x_cut_bio

        out["T12_in"][k] = x_in[14]
        out["T12_vw"][k] = (dEk_dt / w2[k]) if abs(w2[k]) > 1e-6 else 0.0
        out["T12_grav"][k] = x_grav[14]
        out["T12_cut_bio"][k] = x_cut_bio[14]
        out["T12_cut_lin"][k] = x_cut_lin[14]
        out["T12_total_bio"][k] = x_tot[14]

        out["F_hand_in"][k] = abs(x_in[14]) / R_GRIP_MID
        out["F_hand_grav"][k] = abs(x_grav[14]) / R_GRIP_MID
        out["F_hand_bio"][k] = abs(x_cut_bio[14]) / R_GRIP_MID
        out["F_hand_total_bio"][k] = abs(x_tot[14]) / R_GRIP_MID

        def store_reac(vec, suffix):
            out[f"R_O2_{suffix}"][k] = math.hypot(vec[0], vec[1])
            out[f"R_A_{suffix}"][k] = math.hypot(vec[2], vec[3])
            out[f"R_B3_{suffix}"][k] = math.hypot(vec[4], vec[5])
            out[f"R_B4_{suffix}"][k] = math.hypot(vec[8], vec[9])
            out[f"R_B5_{suffix}"][k] = math.hypot(vec[4] + vec[8], vec[5] + vec[9])
            out[f"R_O4_{suffix}"][k] = math.hypot(vec[6], vec[7])
            out[f"R_O5_{suffix}"][k] = math.hypot(vec[10], vec[11])
            out[f"R_N16_{suffix}"][k] = abs(vec[12])
            out[f"R_M16_{suffix}"][k] = abs(vec[13])

        store_reac(x_in, "in")
        store_reac(x_grav, "grav")
        store_reac(x_cut_bio, "cut_bio")
        store_reac(x_tot, "tot")

    # Validação Trabalhos Virtuais onde |w2| > 0.05 rad/s
    mask_vw = np.abs(w2) > 0.05
    vw_max_err = float(np.max(np.abs(out["T12_in"][mask_vw] - out["T12_vw"][mask_vw])))

    return {
        "t": t, "th2_deg": np.degrees(th2), "w2": w2, "al2": al2,
        "vw_max_err_Nm": vw_max_err, "out": out,
        "masses": (m2, m3, m4, m5, m6), "inertias": (IG2, IG3, IG4, IG5, IG6),
        "cg_locs": (cg2_loc, cg3_loc, cg4_loc, cg5_loc, cg6_loc),
    }


# =========================================================================================
# 4. SOLVER CINEMÁTICO + D'ALEMBERT 9x9 (MECANISMO 4-BARRAS DO PEDAL DE EXTRAÇÃO)
# =========================================================================================
def run_pedal_dalembert(inertia_data: dict, T_ped: float = 0.30, N: int = 301):
    import numpy as np

    groups = inertia_data["groups"]
    me = groups["Pedal_Alavanca_Ejetora"]["mass_kg"]
    mt = groups["Pedal_Tirante"]["mass_kg"]
    mp = groups["Pedal_Piso"]["mass_kg"]

    IGe = groups["Pedal_Alavanca_Ejetora"]["Iyy_cg_kg_m2"]
    IGt = groups["Pedal_Tirante"]["Iyy_cg_kg_m2"]
    IGp = groups["Pedal_Piso"]["Iyy_cg_kg_m2"]

    cge_loc = np.array([groups["Pedal_Alavanca_Ejetora"]["cg_local_mm"][0], groups["Pedal_Alavanca_Ejetora"]["cg_local_mm"][2]]) * 1e-3
    cgt_loc = np.array([groups["Pedal_Tirante"]["cg_local_mm"][0], groups["Pedal_Tirante"]["cg_local_mm"][2]]) * 1e-3
    cgp_loc = np.array([groups["Pedal_Piso"]["cg_local_mm"][0], groups["Pedal_Piso"]["cg_local_mm"][2]]) * 1e-3

    t = np.linspace(0.0, T_ped, N)
    psi_max = math.radians(22.0)

    # No CAD, Placement.Rotation.Angle em torno de +Y gira horário no XZ (ângulo matemático = -psi)
    psi = 0.5 * psi_max * (1.0 - np.cos(math.pi * t / T_ped))
    dpsi = 0.5 * psi_max * (math.pi / T_ped) * np.sin(math.pi * t / T_ped)
    ddpsi = 0.5 * psi_max * ((math.pi / T_ped) ** 2) * np.cos(math.pi * t / T_ped)

    O_ext = np.array([O_EXT_X, O_EXT_Z])
    O_ped = np.array([PED_PIVOT_X, PED_PIVOT_Z])

    out = {k: np.zeros(N) for k in (
        "psi_deg", "th_ped_deg", "th_tir_deg", "w_ped", "al_ped", "w_tir", "al_tir",
        "Fine_mag", "Fint_mag", "Finp_mag", "Tine", "Tint", "Tinp",
        "F_foot_in", "F_foot_grav", "R_Oped_in", "R_Oext_in", "Ek", "T_ped_in", "T_ped_vw"
    )}

    # Posição local em ângulo phi=0 -> ângulo matemático th = -cad_ang (CCW positivo no XZ)
    def body_cg_math(P, vP, aP, th, w, al, loc_xz):
        c, s = math.cos(th), math.sin(th)
        r = np.array([loc_xz[0] * c - loc_xz[1] * s, loc_xz[0] * s + loc_xz[1] * c])
        rp = np.array([-r[1], r[0]])
        return P + r, vP + w * rp, aP + al * rp - (w * w) * r

    # Em th_ped_math = -cad_ang_ped, o pino inferior no frame local do pedal está no ângulo PED_THETA0
    # Logo em coordenadas matemáticas CCW: Q = O_ped + PED_R_EFF * [cos(th_p + PED_THETA0), sin(th_p + PED_THETA0)]
    # E P_top no quadro local da alavanca ejetora está em (EXT_CRANK_DX, EXT_CRANK_DZ) no ângulo EXT_PHI0
    # Logo P_top = O_ext + EXT_R_CRANK * [cos(th_e + EXT_PHI0), sin(th_e + EXT_PHI0)], onde th_e = -psi
    # E no tirante local, o pino inferior está em (0, -PED_ROD_LEN) => ângulo -90°;
    # Rotacionado por th_t = -Ang_Tirante, Q - P_top = PED_ROD_LEN * [cos(th_t - pi/2), sin(th_t - pi/2)] = PED_ROD_LEN * [sin(th_t), -cos(th_t)]
    for k in range(N):
        th_e = -psi[k]
        w_e = -dpsi[k]
        al_e = -ddpsi[k]

        ang_e_pin = th_e + EXT_PHI0
        P_top = O_ext + EXT_R_CRANK * np.array([math.cos(ang_e_pin), math.sin(ang_e_pin)])
        vP_top = EXT_R_CRANK * w_e * np.array([-math.sin(ang_e_pin), math.cos(ang_e_pin)])
        aP_top = EXT_R_CRANK * al_e * np.array([-math.sin(ang_e_pin), math.cos(ang_e_pin)]) \
                 - EXT_R_CRANK * (w_e ** 2) * np.array([math.cos(ang_e_pin), math.sin(ang_e_pin)])

        dx, dz = P_top[0] - O_ped[0], P_top[1] - O_ped[1]
        d = math.hypot(dx, dz)
        ac = (PED_R_EFF ** 2 - PED_ROD_LEN ** 2 + d ** 2) / (2.0 * d)
        hc = math.sqrt(max(0.0, PED_R_EFF ** 2 - ac ** 2))
        Qx = O_ped[0] + ac * dx / d + hc * dz / d
        Qz = O_ped[1] + ac * dz / d - hc * dx / d
        Q = np.array([Qx, Qz])

        th_p = math.atan2(Qz - O_ped[1], Qx - O_ped[0]) - PED_THETA0
        # Q - P_top = L_rod * [sin(th_t), -cos(th_t)] => sin(th_t) = (Qx-Px)/L, -cos(th_t) = (Qz-Pz)/L
        th_t = math.atan2(Qx - P_top[0], -(Qz - P_top[1]))

        ang_p_pin = th_p + PED_THETA0
        # Fecho: P_top - Q = L_rod * [-sin(th_t), cos(th_t)]
        # Derivando: vP_top = PED_R_EFF*w_p*[-sin(ang_p_pin), cos(ang_p_pin)] + L_rod*w_t*[-cos(th_t), -sin(th_t)]
        Jp = np.array([
            [-PED_R_EFF * math.sin(ang_p_pin), -PED_ROD_LEN * math.cos(th_t)],
            [ PED_R_EFF * math.cos(ang_p_pin), -PED_ROD_LEN * math.sin(th_t)],
        ])
        w_p, w_t = np.linalg.solve(Jp, vP_top)

        rhs_acc = aP_top \
                  + PED_R_EFF * (w_p ** 2) * np.array([math.cos(ang_p_pin), math.sin(ang_p_pin)]) \
                  - PED_ROD_LEN * (w_t ** 2) * np.array([math.sin(th_t), -math.cos(th_t)])
        al_p, al_t = np.linalg.solve(Jp, rhs_acc)

        vQ = PED_R_EFF * w_p * np.array([-math.sin(ang_p_pin), math.cos(ang_p_pin)])
        aQ = PED_R_EFF * al_p * np.array([-math.sin(ang_p_pin), math.cos(ang_p_pin)]) \
             - PED_R_EFF * (w_p ** 2) * np.array([math.cos(ang_p_pin), math.sin(ang_p_pin)])

        Ge, vGe, aGe = body_cg_math(O_ext, np.zeros(2), np.zeros(2), th_e, w_e, al_e, cge_loc)
        Gt, vGt, aGt = body_cg_math(P_top, vP_top, aP_top, th_t, w_t, al_t, cgt_loc)
        Gp, vGp, aGp = body_cg_math(O_ped, np.zeros(2), np.zeros(2), th_p, w_p, al_p, cgp_loc)

        Ek = 0.5 * me * np.dot(vGe, vGe) + 0.5 * IGe * (w_e ** 2) \
           + 0.5 * mt * np.dot(vGt, vGt) + 0.5 * IGt * (w_t ** 2) \
           + 0.5 * mp * np.dot(vGp, vGp) + 0.5 * IGp * (w_p ** 2)
        dEk = me * np.dot(vGe, aGe) + IGe * w_e * al_e \
            + mt * np.dot(vGt, aGt) + IGt * w_t * al_t \
            + mp * np.dot(vGp, aGp) + IGp * w_p * al_p

        # Sistema 9x9: [F_Opx, F_Opz, F_Qpx, F_Qpz, F_Ttx, F_Ttz, F_Oex, F_Oez, T_ped]
        Mp = np.zeros((9, 9))
        def cr(row, cx, cz, rv, sgn=1.0):
            Mp[row, cx] += -sgn * rv[1]
            Mp[row, cz] += sgn * rv[0]

        # Pedal (p): F_Op em O_ped, -F_Qp em Q, + T_ped
        Mp[0, 0] = 1.0; Mp[0, 2] = -1.0
        Mp[1, 1] = 1.0; Mp[1, 3] = -1.0
        cr(2, 0, 1, O_ped - Gp, +1.0); cr(2, 2, 3, Q - Gp, -1.0); Mp[2, 8] = 1.0

        # Tirante (t): +F_Qp em Q, -F_Tt em P_top
        Mp[3, 2] = 1.0; Mp[3, 4] = -1.0
        Mp[4, 3] = 1.0; Mp[4, 5] = -1.0
        cr(5, 2, 3, Q - Gt, +1.0); cr(5, 4, 5, P_top - Gt, -1.0)

        # Alavanca Ejetora (e): +F_Tt em P_top, +F_Oe em O_ext
        Mp[6, 4] = 1.0; Mp[6, 6] = 1.0
        Mp[7, 5] = 1.0; Mp[7, 7] = 1.0
        cr(8, 4, 5, P_top - Ge, +1.0); cr(8, 6, 7, O_ext - Ge, +1.0)

        bp_in = np.array([
            mp * aGp[0], mp * aGp[1], IGp * al_p,
            mt * aGt[0], mt * aGt[1], IGt * al_t,
            me * aGe[0], me * aGe[1], IGe * al_e,
        ])
        xp_in = np.linalg.solve(Mp, bp_in)

        bp_gr = np.array([
            0.0, mp * G_ACCEL, 0.0,
            0.0, mt * G_ACCEL, 0.0,
            0.0, me * G_ACCEL, 0.0,
        ])
        xp_gr = np.linalg.solve(Mp, bp_gr)

        out["psi_deg"][k] = math.degrees(psi[k])
        out["th_ped_deg"][k] = -math.degrees(th_p)
        out["th_tir_deg"][k] = -math.degrees(th_t)
        out["w_ped"][k], out["al_ped"][k] = w_p, al_p
        out["w_tir"][k], out["al_tir"][k] = w_t, al_t
        out["Fine_mag"][k] = me * float(np.linalg.norm(aGe))
        out["Fint_mag"][k] = mt * float(np.linalg.norm(aGt))
        out["Finp_mag"][k] = mp * float(np.linalg.norm(aGp))
        out["Tine"][k] = -IGe * al_e
        out["Tint"][k] = -IGt * al_t
        out["Tinp"][k] = -IGp * al_p
        out["T_ped_in"][k] = xp_in[8]
        out["T_ped_vw"][k] = (dEk / w_p) if abs(w_p) > 1e-6 else 0.0
        out["F_foot_in"][k] = abs(xp_in[8]) / PED_PAD_CENTER_X
        out["F_foot_grav"][k] = abs(xp_gr[8]) / PED_PAD_CENTER_X
        out["R_Oped_in"][k] = math.hypot(xp_in[0], xp_in[1])
        out["R_Oext_in"][k] = math.hypot(xp_in[6], xp_in[7])
        out["Ek"][k] = Ek

    mask = np.abs(out["w_ped"]) > 0.02
    vw_err = float(np.max(np.abs(out["T_ped_in"][mask] - out["T_ped_vw"][mask])))
    return {"t": t, "vw_max_err_Nm": vw_err, "out": out}


# =========================================================================================
# 5. GERAÇÃO DOS GRÁFICOS 300 DPI E EXPORTAÇÃO DE RESULTADOS
# =========================================================================================
def generate_plots(sim_nom, sim_fast, sim_ped):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import numpy as np

    os.makedirs(ASSETS_REPO, exist_ok=True)
    os.makedirs(ASSETS_VAULT, exist_ok=True)

    def save_fig(fig, fname):
        for folder in (ASSETS_REPO, ASSETS_VAULT):
            fig.savefig(os.path.join(folder, fname), dpi=300, bbox_inches="tight")
        plt.close(fig)

    t = sim_nom["t"]
    o = sim_nom["out"]

    # --- FIGURA 1: Forças Inerciais, Torques Inerciais, Reações nos Pinos e Validação VW ---
    fig1, axs = plt.subplots(2, 2, figsize=(13.5, 8.8))
    fig1.suptitle(
        "Análise Dinâmica de d'Alembert (Massas e Inércias Exatas do FreeCAD — Ciclo 1,0 s Descida + 2,0 s Subida)",
        fontsize=12.5, fontweight="bold", y=0.98
    )

    ax = axs[0, 0]
    ax.axvspan(0.0, 1.0, color="#eef5ff", alpha=0.8)
    ax.axvspan(1.0, 3.0, color="#f2faef", alpha=0.8)
    ax.plot(t, o["Fin2_mag"], label="Corpo 2 (Alavanca+Eixo O2: 1,409 kg)", lw=2.2, color="#d95f02")
    ax.plot(t, o["Fin6_mag"], label="Corpo 6 (Pistão+Navalha O5: 0,943 kg)", lw=2.2, color="#7570b3")
    ax.plot(t, o["Fin5_mag"], label="Corpo 5 (Garfo L5+Pino B: 0,458 kg)", lw=2.0, color="#e7298a")
    ax.plot(t, o["Fin4_mag"], label="Corpo 4 (Balancim L4: 0,517 kg)", lw=1.8, color="#1b9e77")
    ax.plot(t, o["Fin3_mag"], label="Corpo 3 (Biela L3: 0,141 kg)", lw=1.8, color="#377eb8", ls="--")
    ax.axvline(1.0, color="k", ls=":", lw=1.1)
    ax.set_title("1. Módulo das Forças Inerciais |F_in,i| = m_i · |a_Gi| (N)", fontweight="bold")
    ax.set_xlabel("Tempo t (s)")
    ax.set_ylabel("Força Inercial (N)")
    ax.set_xlim(0.0, 3.0)
    ax.grid(True, alpha=0.35)
    ax.legend(fontsize=8.2, loc="upper right")

    ax = axs[0, 1]
    ax.plot(t, o["Tin2"] * 1e3, label="T_in,2 = -I_G2·α2 (Alavanca)", lw=2.2, color="#d95f02")
    ax.plot(t, o["Tin4"] * 1e3, label="T_in,4 = -I_G4·α4 (Balancim L4)", lw=2.0, color="#1b9e77")
    ax.plot(t, o["Tin5"] * 1e3, label="T_in,5 = -I_G5·α5 (Garfo L5)", lw=1.9, color="#e7298a", ls="--")
    ax.plot(t, o["Tin3"] * 1e3, label="T_in,3 = -I_G3·α3 (Biela L3)", lw=1.8, color="#377eb8")
    ax.axvline(1.0, color="k", ls=":", lw=1.1)
    ax.axhline(0.0, color="k", lw=0.8)
    ax.set_title("2. Torques Inerciais Baricêntricos T_in,i = -I_yy,Gi · α_i (mN·m)", fontweight="bold")
    ax.set_xlabel("Tempo t (s)")
    ax.set_ylabel("Torque Inercial (mN·m)")
    ax.set_xlim(0.0, 3.0)
    ax.grid(True, alpha=0.35)
    ax.legend(fontsize=8.2, loc="upper right")

    ax = axs[1, 0]
    ax.plot(t, o["R_O2_in"], label="Mancal O2 (|R_12,in|)", lw=2.2, color="#d95f02")
    ax.plot(t, o["R_A_in"], label="Pino A (|R_23,in|)", lw=2.0, color="#377eb8")
    ax.plot(t, o["R_O4_in"], label="Mancal O4 (|R_14,in|)", lw=2.0, color="#1b9e77")
    ax.plot(t, o["R_B5_in"], label="Junta B->L5 (|R_5B,in|)", lw=1.8, color="#e7298a", ls="--")
    ax.plot(t, o["R_O5_in"], label="Pino Pistão O5 (|R_56,in|)", lw=1.8, color="#7570b3")
    ax.plot(t, o["R_N16_in"], label="Guia Normal (|N_16,in|)", lw=1.6, color="#666666", ls=":")
    ax.axvline(1.0, color="k", ls=":", lw=1.1)
    ax.set_title("3. Reações Inerciais Puras nas Juntas (F_corte = 0, g = 0)", fontweight="bold")
    ax.set_xlabel("Tempo t (s)")
    ax.set_ylabel("Força Inercial na Junta (N)")
    ax.set_xlim(0.0, 3.0)
    ax.grid(True, alpha=0.35)
    ax.legend(fontsize=8.0, loc="upper right")

    ax = axs[1, 1]
    mask = np.abs(sim_nom["w2"]) > 0.05
    ax.plot(t, o["T12_in"], label="Solver 15×15 Newton-Euler (T_12,in)", lw=2.4, color="#b2182b")
    ax.plot(t[mask], o["T12_vw"][mask], label="Trab. Virtuais (dEk/dt / ω2)", lw=0.0, marker="o", ms=2.6, markevery=18, color="#2166ac")
    ax.axvline(1.0, color="k", ls=":", lw=1.1)
    ax.axhline(0.0, color="k", lw=0.8)
    ax.set_title(
        f"4. Torque Inercial Equivalente no Eixo O2 (Erro máx. VW = {sim_nom['vw_max_err_Nm']:.2e} N·m)",
        fontweight="bold",
    )
    ax.set_xlabel("Tempo t (s)")
    ax.set_ylabel("Torque em O2 (N·m)")
    ax.set_xlim(0.0, 3.0)
    ax.grid(True, alpha=0.35)
    ax.legend(fontsize=8.5, loc="upper right")

    fig1.tight_layout(rect=[0, 0, 1, 0.95])
    save_fig(fig1, "dalembert_manual_forcas_inerciais.png")

    # --- FIGURA 2: Inercial vs Gravidade vs Carga de Corte do Baru (5000 N) + Sensibilidade ---
    fig2, (ax1, ax2) = plt.subplots(1, 2, figsize=(13.5, 5.2))
    fig2.suptitle(
        "Comparação Dinâmica: Inércia (d'Alembert) vs. Gravidade vs. Quebra do Baru (5000 N em 4,75 mm)",
        fontsize=12.0, fontweight="bold", y=0.98
    )

    ax1.plot(t, o["F_hand_total_bio"], label="Total na Mão (Corte + Grav. + Inércia)", lw=2.5, color="#b2182b")
    ax1.plot(t, o["F_hand_bio"], label="Corte Biomaterial s^0.4 (5000 N)", lw=2.0, color="#ef8a62", ls="--")
    ax1.plot(t, o["F_hand_grav"], label="Peso Próprio (Gravidade)", lw=1.9, color="#1b9e77")
    ax1.plot(t, o["F_hand_in"], label="Inercial d'Alembert (T1=1,0 s)", lw=2.0, color="#2166ac")
    ax1.axhline(80.0, color="#555555", ls=":", lw=1.2, label="Referência Ergonômica (80 N)")
    ax1.set_title("1. Esforço Equivalente na Empunhadura (R = 540 mm)", fontweight="bold")
    ax1.set_xlabel("Tempo t (s)")
    ax1.set_ylabel("Força na Mão |F_mão| (N)")
    ax1.set_xlim(0.0, 3.0)
    ax1.grid(True, alpha=0.35)
    ax1.legend(fontsize=8.2, loc="upper right")

    # Comparação em escala logarítmica para enxergar as ordens de grandeza
    tf = sim_fast["t"]
    of = sim_fast["out"]
    ax2.semilogy(t, np.maximum(o["F_hand_total_bio"], 1e-4), label="Quebra Total (T1=1,0 s)", lw=2.4, color="#b2182b")
    ax2.semilogy(t, np.maximum(o["F_hand_grav"], 1e-4), label="Peso Próprio (Gravidade)", lw=1.9, color="#1b9e77")
    ax2.semilogy(t, np.maximum(o["F_hand_in"], 1e-4), label="d'Alembert Nominal (T1=1,0 s)", lw=2.1, color="#2166ac")
    ax2.semilogy(tf * (3.0 / (tf[-1])), np.maximum(of["F_hand_in"], 1e-4),
                 label="d'Alembert Puxada Rápida (T1=0,4 s, eixo t norm.)", lw=1.9, color="#7570b3", ls="--")
    ax2.set_title("2. Razão de Escala Logarítmica & Sensibilidade à Velocidade", fontweight="bold")
    ax2.set_xlabel("Tempo Normalizado / Ciclo Nominal (s)")
    ax2.set_ylabel("|F_mão| (N) — Escala Log")
    ax2.set_xlim(0.0, 3.0)
    ax2.set_ylim(1e-3, 3e2)
    ax2.grid(True, which="both", alpha=0.30)
    ax2.legend(fontsize=8.2, loc="lower right")

    fig2.tight_layout(rect=[0, 0, 1, 0.94])
    save_fig(fig2, "dalembert_manual_comparacao_corte_gravidade.png")

    # --- FIGURA 3: Dinâmica de d'Alembert do Pedal de Extração (0 -> 22 graus em 0,30 s) ---
    tp = sim_ped["t"]
    op = sim_ped["out"]
    fig3, (pa1, pa2) = plt.subplots(1, 2, figsize=(13.0, 4.8))
    fig3.suptitle(
        "Dinâmica de d'Alembert do Sistema 4-Barras do Pedal de Extração (+X, Acionamento Rápido T_ped = 0,30 s)",
        fontsize=11.5, fontweight="bold", y=0.98
    )

    pa1.plot(tp, op["Finp_mag"], label="Pedal de Piso (0,746 kg)", lw=2.2, color="#d95f02")
    pa1.plot(tp, op["Fint_mag"], label="Tirante 4-Barras (0,352 kg)", lw=2.0, color="#377eb8")
    pa1.plot(tp, op["Fine_mag"], label="Alavanca Ejetora (0,072 kg)", lw=2.0, color="#1b9e77")
    pa1.plot(tp, op["R_Oped_in"], label="Reação Inercial no Pivô do Pedal", lw=1.8, color="#7570b3", ls="--")
    pa1.set_title("1. Forças Inerciais dos Corpos do Pedal (N)", fontweight="bold")
    pa1.set_xlabel("Tempo t (s)")
    pa1.set_ylabel("Força (N)")
    pa1.grid(True, alpha=0.35)
    pa1.legend(fontsize=8.2)

    mp = np.abs(op["w_ped"]) > 0.02
    pa2.plot(tp, op["F_foot_in"], label="Força Inercial no Pé (X=540 mm)", lw=2.2, color="#b2182b")
    pa2.plot(tp[mp], np.abs(op["T_ped_vw"][mp]) / PED_PAD_CENTER_X, lw=0.0, marker="o", ms=3.0, markevery=12, color="#2166ac", label="Trab. Virtuais (dEk/dt / ω_ped)")
    pa2.plot(tp, op["F_foot_grav"], label="Parcela Estática de Peso Próprio no Pé", lw=1.9, color="#1b9e77", ls="--")
    pa2.set_title(f"2. Esforço no Pé (Erro máx. VW = {sim_ped['vw_max_err_Nm']:.2e} N·m)", fontweight="bold")
    pa2.set_xlabel("Tempo t (s)")
    pa2.set_ylabel("Força Equivalente na Sapata (N)")
    pa2.grid(True, alpha=0.35)
    pa2.legend(fontsize=8.2)

    fig3.tight_layout(rect=[0, 0, 1, 0.94])
    save_fig(fig3, "dalembert_manual_pedal_extracao.png")


def build_summary_report(inertia_data, sim_nom, sim_fast, sim_ped) -> dict:
    import numpy as np

    o = sim_nom["out"]
    of = sim_fast["out"]
    op = sim_ped["out"]
    t = sim_nom["t"]

    # Instantes-chave para tabela
    t_chks = [0.00, 0.25, 0.50, 0.75, 0.90, 1.00, 1.50, 2.00, 2.50, 3.00]
    table_rows = []
    for tc in t_chks:
        idx = int(np.argmin(np.abs(t - tc)))
        table_rows.append({
            "t_s": float(t[idx]),
            "th2_deg": float(sim_nom["th2_deg"][idx]),
            "z_tip_mm": float(o["z_tip"][idx] * 1e3),
            "mu_deg": float(o["mu_deg"][idx]),
            "Fin2_N": float(o["Fin2_mag"][idx]),
            "Fin3_N": float(o["Fin3_mag"][idx]),
            "Fin4_N": float(o["Fin4_mag"][idx]),
            "Fin5_N": float(o["Fin5_mag"][idx]),
            "Fin6_N": float(o["Fin6_mag"][idx]),
            "Tin2_mNm": float(o["Tin2"][idx] * 1e3),
            "T12_in_Nm": float(o["T12_in"][idx]),
            "T12_grav_Nm": float(o["T12_grav"][idx]),
            "T12_cut_bio_Nm": float(o["T12_cut_bio"][idx]),
            "R_O2_in_N": float(o["R_O2_in"][idx]),
            "R_O4_in_N": float(o["R_O4_in"][idx]),
            "R_O5_in_N": float(o["R_O5_in"][idx]),
            "R_N16_in_N": float(o["R_N16_in"][idx]),
        })

    # Índices descida vs subida
    idx_desc = t <= 1.0
    res = {
        "nominal_T1_1s_T2_2s": {
            "vw_max_err_Nm": sim_nom["vw_max_err_Nm"],
            "max_w_rad_s": {
                "w2_desc": float(np.max(np.abs(sim_nom["w2"][idx_desc]))),
                "w3": float(np.max(np.abs(o["w3"]))),
                "w4": float(np.max(np.abs(o["w4"]))),
                "w5": float(np.max(np.abs(o["w5"]))),
                "vO5_mm_s": float(np.max(np.abs(o["vO5_z"])) * 1e3),
            },
            "max_al_rad_s2": {
                "al2": float(np.max(np.abs(sim_nom["al2"]))),
                "al3": float(np.max(np.abs(o["al3"]))),
                "al4": float(np.max(np.abs(o["al4"]))),
                "al5": float(np.max(np.abs(o["al5"]))),
                "aO5_m_s2": float(np.max(np.abs(o["aO5_z"]))),
            },
            "max_aG_m_s2": {f"G{i}": float(np.max(o[f"aG{i}_mag"])) for i in (2, 3, 4, 5, 6)},
            "max_Fin_N": {f"Body{i}": float(np.max(o[f"Fin{i}_mag"])) for i in (2, 3, 4, 5, 6)},
            "max_Tin_Nm": {f"Body{i}": float(np.max(np.abs(o[f"Tin{i}"]))) for i in (2, 3, 4, 5)},
            "max_R_in_N": {j: float(np.max(o[f"R_{j}_in"])) for j in ("O2", "A", "B3", "B4", "B5", "O4", "O5", "N16")},
            "max_M16_in_Nm": float(np.max(o["R_M16_in"])),
            "max_T12_in_Nm": float(np.max(np.abs(o["T12_in"]))),
            "max_F_hand_in_N": float(np.max(o["F_hand_in"])),
            "max_T12_grav_Nm": float(np.max(np.abs(o["T12_grav"]))),
            "max_F_hand_grav_N": float(np.max(o["F_hand_grav"])),
            "max_T12_cut_lin_Nm": float(np.max(np.abs(o["T12_cut_lin"]))),
            "max_T12_cut_bio_Nm": float(np.max(np.abs(o["T12_cut_bio"]))),
            "max_F_hand_bio_N": float(np.max(o["F_hand_bio"])),
            "max_R_cut_bio_N": {j: float(np.max(o[f"R_{j}_cut_bio"])) for j in ("O2", "A", "B3", "B4", "B5", "O4", "O5", "N16")},
            "max_Ek_J": float(np.max(o["Ek"])),
        },
        "fast_pull_T1_0p4s": {
            "vw_max_err_Nm": sim_fast["vw_max_err_Nm"],
            "max_Fin_N": {f"Body{i}": float(np.max(of[f"Fin{i}_mag"])) for i in (2, 3, 4, 5, 6)},
            "max_T12_in_Nm": float(np.max(np.abs(of["T12_in"]))),
            "max_F_hand_in_N": float(np.max(of["F_hand_in"])),
            "max_Ek_J": float(np.max(of["Ek"])),
        },
        "pedal_T_0p30s": {
            "vw_max_err_Nm": sim_ped["vw_max_err_Nm"],
            "max_Fine_N": float(np.max(op["Fine_mag"])),
            "max_Fint_N": float(np.max(op["Fint_mag"])),
            "max_Finp_N": float(np.max(op["Finp_mag"])),
            "max_T_ped_in_Nm": float(np.max(np.abs(op["T_ped_in"]))),
            "max_F_foot_in_N": float(np.max(op["F_foot_in"])),
            "max_F_foot_grav_N": float(np.max(op["F_foot_grav"])),
            "max_R_Oped_in_N": float(np.max(op["R_Oped_in"])),
            "max_R_Oext_in_N": float(np.max(op["R_Oext_in"])),
            "max_Ek_J": float(np.max(op["Ek"])),
        },
        "table_rows": table_rows,
    }
    with open(JSON_RESULTS_PATH, "w", encoding="utf-8") as f:
        json.dump(res, f, indent=2, ensure_ascii=False)
    return res


def main():
    if "--extract" in sys.argv or os.environ.get("FREECAD_EXTRACT") == "1":
        extract_from_freecad()
        return

    if "--refresh-cad" in sys.argv or not os.path.exists(JSON_INERTIA_PATH):
        env = os.environ.copy()
        env["FREECAD_EXTRACT"] = "1"
        cmd = ["FreeCADCmd", os.path.abspath(__file__)]
        subprocess.run(cmd, check=True, env=env)

    with open(JSON_INERTIA_PATH, "r", encoding="utf-8") as f:
        inertia_data = json.load(f)

    sim_nom = run_main_mechanism_dalembert(inertia_data, T1=1.0, T2=2.0, N=1201)
    sim_fast = run_main_mechanism_dalembert(inertia_data, T1=0.40, T2=0.80, N=601)
    sim_ped = run_pedal_dalembert(inertia_data, T_ped=0.30, N=301)

    generate_plots(sim_nom, sim_fast, sim_ped)
    summary = build_summary_report(inertia_data, sim_nom, sim_fast, sim_ped)

    print("=" * 88)
    print("ANALISE DE D'ALEMBERT CONCLUIDA COM SUCESSO (prensa_baru_manual_v1)")
    print("=" * 88)
    print("Massa total maquina:", round(inertia_data["totals"]["total_machine_mass_kg"], 4), "kg")
    print("Massa movel principal:", round(inertia_data["totals"]["moving_main_mass_kg"], 4), "kg")
    print("Massa movel pedal:", round(inertia_data["totals"]["moving_pedal_mass_kg"], 4), "kg")
    nom = summary["nominal_T1_1s_T2_2s"]
    print(f"VW error (Nominal): {nom['vw_max_err_Nm']:.3e} N.m | (Fast): {summary['fast_pull_T1_0p4s']['vw_max_err_Nm']:.3e} N.m | (Pedal): {summary['pedal_T_0p30s']['vw_max_err_Nm']:.3e} N.m")
    print("Nominal max Fin (N):", {k: round(v, 4) for k, v in nom["max_Fin_N"].items()})
    print("Nominal max T12_in:", round(nom["max_T12_in_Nm"], 5), "N.m | F_mao_in:", round(nom["max_F_hand_in_N"], 5), "N")
    print("Nominal max T12_grav:", round(nom["max_T12_grav_Nm"], 4), "N.m | F_mao_grav:", round(nom["max_F_hand_grav_N"], 4), "N")
    print("Cut Bio s^0.4 max T12:", round(nom["max_T12_cut_bio_Nm"], 3), "N.m | F_mao_bio:", round(nom["max_F_hand_bio_N"], 3), "N")
    print("Cut Lin s     max T12:", round(nom["max_T12_cut_lin_Nm"], 3), "N.m | F_mao_lin:", round(nom["max_T12_cut_lin_Nm"]/R_GRIP_MID, 3), "N")
    print("Nominal max Reacoes Inerciais (N):", {k: round(v, 4) for k, v in nom["max_R_in_N"].items()})
    print("Cut Bio max Reacoes (N):", {k: round(v, 2) for k, v in nom["max_R_cut_bio_N"].items()})
    print("Fast Pull (0.4s) max T12_in:", round(summary["fast_pull_T1_0p4s"]["max_T12_in_Nm"], 4), "N.m | F_mao_in:", round(summary["fast_pull_T1_0p4s"]["max_F_hand_in_N"], 4), "N")
    print("Pedal (0.30s) max F_foot_in:", round(summary["pedal_T_0p30s"]["max_F_foot_in_N"], 4), "N | max R_Oped_in:", round(summary["pedal_T_0p30s"]["max_R_Oped_in_N"], 4), "N")


if __name__ == "__main__" or os.environ.get("FREECAD_EXTRACT") == "1":
    main()
