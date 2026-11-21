#!/usr/bin/env python3
"""
Extração Exata de Massa, CG e Tensor de Inércia via FreeCAD (OpenCascade),
Dimensionamento Não-Linear (RK45) do Volante de Inércia e Análise Dinâmica de d'Alembert
— Prensa Motorizada de Baru 20 RPM (`prensa_baru_motorizada_v1`, Vertente B / Item 9)

Modos de execução:
  1) FreeCADCmd -c "import sys; sys.path.insert(0,'.'); import calcular_inercia_e_dalembert_motorizada as m; m.extract_from_freecad()"
  2) python3 calcular_inercia_e_dalembert_motorizada.py [--refresh-cad]
"""

from __future__ import annotations

import json
import math
import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CAD_PATH = os.path.join(SCRIPT_DIR, "prensa_baru_motorizada_v1.FCStd")
JSON_INERTIA_PATH = os.path.join(SCRIPT_DIR, "propriedades_inerciais_freecad_motorizada_v1.json")
JSON_RESULTS_PATH = os.path.join(SCRIPT_DIR, "resultados_dalembert_motorizada_v1.json")
ASSETS_REPO = os.path.join(SCRIPT_DIR, "assets")
VAULT_DIR = "/home/guimentzer/vault/Dinâmica das Máquinas/Trabalho Final 1"
ASSETS_VAULT = os.path.join(VAULT_DIR, "assets")

# =========================================================================================
# 1. CONSTANTES FÍSICAS E GEOMÉTRICAS DO PROJETO MOTORIZADO (IDÊNTICAS AO GERADOR CAD)
# =========================================================================================
G_ACCEL = 9.80665  # m/s^2

RHO_MAP = {
    "aco": 7850.0,
    "fofo": 7200.0,
    "bronze": 8930.0,
    "borracha": 1200.0,
    "uhmw": 935.0,
    "pc": 1200.0,
    "baru": 1100.0,
}

# Catálogo dos 55 Part::Feature de prensa_baru_motorizada_v1.FCStd
OBJ_CATALOG = {
    # Sub01 - Estator interno
    "Chapa_Base_Estrutural": ("aco", "Sub01_Estator"),
    "Portico_Estrutural_Traseiro": ("aco", "Sub01_Estator"),
    "Portico_Estrutural_Frontal": ("aco", "Sub01_Estator"),
    "Espacadores_Transversais_Portico": ("aco", "Sub01_Estator"),
    "Suporte_Baru_Cantoneira": ("aco", "Sub01_Estator"),
    "Guia_Pistao_Chapa_U": ("aco", "Sub01_Estator"),
    "Parafusos_Guia_Pistao_M8": ("aco", "Sub01_Estator"),
    "Tiras_Desgaste_UHMW_5mm": ("uhmw", "Sub01_Estator"),
    "Buchas_Catalogo_Estator": ("bronze", "Sub01_Estator"),
    "Pino_Eixo_O4": ("aco", "Sub01_Estator"),
    "Aneis_Retencao_ORing_O4": ("borracha", "Sub01_Estator"),
    # Corpo 2 - Eixo O2 + Manivela L2 + Came Extrator + Pino A
    "Eixo_Principal_O2_20rpm": ("aco", "Corpo2_O2"),
    "Elo2_Manivela_L2": ("aco", "Corpo2_O2"),
    "Came_Extrator_O2": ("aco", "Corpo2_O2"),
    "Buchas_Catalogo_A": ("bronze", "Corpo2_O2"),
    "Pino_Eixo_A": ("aco", "Corpo2_O2"),
    "Aneis_Retencao_ORing_A": ("borracha", "Corpo2_O2"),
    # Corpo 3 - Biela L3
    "Elo3_Biela_L3": ("aco", "Corpo3_L3"),
    "Buchas_Catalogo_L3": ("bronze", "Corpo3_L3"),
    # Corpo 4 - Balancim L4
    "Elo4_Balancim_L4": ("aco", "Corpo4_L4"),
    "Buchas_Catalogo_L4": ("bronze", "Corpo4_L4"),
    # Corpo 5 - Garfo Duplo L5 + Pino B
    "Elo5_Garfo_Duplo_L5": ("aco", "Corpo5_L5"),
    "Buchas_Catalogo_L5": ("bronze", "Corpo5_L5"),
    "Pino_Eixo_B": ("aco", "Corpo5_L5"),
    "Aneis_Retencao_ORing_B": ("borracha", "Corpo5_L5"),
    # Corpo 6 - Pistão + Navalha O5
    "Pistao_Embolo_Quadrado": ("aco", "Corpo6_O5"),
    "Navalha_Corte_SAE5160": ("aco", "Corpo6_O5"),
    "Parafusos_Fixacao_Navalha_M6": ("aco", "Corpo6_O5"),
    "Bucha_Catalogo_O5": ("bronze", "Corpo6_O5"),
    "Pino_Eixo_O5": ("aco", "Corpo6_O5"),
    "Aneis_Retencao_ORing_O5": ("borracha", "Corpo6_O5"),
    # Sub07 - Trem de Potência 20 RPM
    "Motor_Eletrico_WEG_05cv_IEC71": ("fofo", "Sub07_Trem_Potencia"),
    "Polia_Motora_D75": ("fofo", "Sub07_Trem_Potencia"),
    "Polia_Movida_D325": ("fofo", "Sub07_Trem_Potencia"),
    "Correia_V_Perfil_A": ("borracha", "Sub07_Trem_Potencia"),
    "Volante_Inercia_Aco": ("aco", "Sub07_Trem_Potencia"),
    "Eixo_Intermediario_400rpm": ("aco", "Sub07_Trem_Potencia"),
    "Mancais_Rolamento_P204_F204": ("fofo", "Sub07_Trem_Potencia"),
    "Redutor_Helicoidal_20_1": ("fofo", "Sub07_Trem_Potencia"),
    "Base_Tensora_Motor": ("aco", "Sub07_Trem_Potencia"),
    # Sub08 - Cavalete NR-12, Moega, Coletor e Extrator Automático por Came
    "Quadro_Tubular_Metalon_20x20": ("aco", "Sub08_Cavalete_Gabinete"),
    "Sapatas_Ancoragem_Piso": ("aco", "Sub08_Cavalete_Gabinete"),
    "Carenagem_Chapa_Galvanizada": ("aco", "Sub08_Cavalete_Gabinete"),
    "Visor_Policarbonato_NR12": ("pc", "Sub08_Cavalete_Gabinete"),
    "Calha_Alimentacao_Segura_NR12": ("aco", "Sub08_Cavalete_Gabinete"),
    "Reservatorio_Alimentacao_Chapa": ("aco", "Sub08_Cavalete_Gabinete"),
    "Parafusos_Fixacao_Gabinete_M6": ("aco", "Sub08_Cavalete_Gabinete"),
    "Calha_Descarga_Chapa": ("aco", "Sub08_Cavalete_Gabinete"),
    "Reservatorio_Chapa_Coleta": ("aco", "Sub08_Cavalete_Gabinete"),
    "Suporte_Eixo_Ejetor_NR12": ("aco", "Sub08_Cavalete_Gabinete"),
    "Mola_Retorno": ("aco", "Sub08_Cavalete_Gabinete"),
    "Alavanca_Seguidora": ("aco", "Ext_Seguidora"),
    "Tirante_Extracao": ("aco", "Ext_Tirante"),
    "Alavanca_Ejetora": ("aco", "Ext_Ejetora"),
    # Sub09 - Corpo de Prova
    "Baru_Simulado_30x50x40": ("baru", "Sub09_Corpo_Prova"),
}

# Cinemática principal em SI (m, rad)
Z_WORK_DATUM = 0.980
O4_X, O4_Z = 0.0, Z_WORK_DATUM + 0.4675          # (0.0, 1.4475) m
H_CURSO = 0.030
DTH4_RAD = math.radians(30.0)
L4 = H_CURSO / (2.0 * (1.0 - math.cos(DTH4_RAD)))  # 0.111961524227 m
L5 = L4

_B1_X = -L4 * math.sin(DTH4_RAD)
_B1_Z = O4_Z - L4 * math.cos(DTH4_RAD)
_B2_X = 0.0
_B2_Z = O4_Z - L4
_MX, _MZ = _B1_X - _B2_X, _B1_Z - _B2_Z
_M_NORM = math.hypot(_MX, _MZ)

O2_X = _B2_X + 1.5 * _MX                           # -0.08397114317 m
O2_Z = _B2_Z + 1.5 * _MZ                           # 1.35803847577 m
L2 = 0.5 * _M_NORM                                 # 0.02897777479 m
L3 = _M_NORM                                       # 0.05795554958 m

TH2_PMS_DEG = 165.0
TH2_PMI_DEG = 345.0
O5_Z_PMI = O4_Z - 2.0 * L4                         # 1.22357695155 m
Z_TIP_PMI = Z_WORK_DATUM + 0.0575                  # 1.0375 m
H_O5_TO_TIP = O5_Z_PMI - Z_TIP_PMI                 # 0.18607695155 m
Z_BARU_TOP = 1.04225                               # Corte efetivo 3D = 4.75 mm
Z_BARU_CUT_10MM = Z_TIP_PMI + 0.010                # 1.0475 m (corte teórico de 10 mm)
F_QUEBRA_MAX = 5000.0                              # N

# Parâmetros do trem de potência 20 RPM
RPM_NOMINAL = 20.0
W2_NOMINAL = RPM_NOMINAL * 2.0 * math.pi / 60.0    # 2.09439510239 rad/s
T_CICLO = 60.0 / RPM_NOMINAL                       # 3.00 s
N_MOTOR_NOM = 1730.0                               # rpm (WEG W22 0,5 cv 4P)
D_PULLEY_1 = 0.075                                 # m
D_PULLEY_2 = 0.325                                 # m
I1_BELT = D_PULLEY_2 / D_PULLEY_1                  # 4.333333
ETA1_BELT = 0.96
I2_REDUCER = 20.0
ETA2_REDUCER = 0.95
MU_GUIA = 0.10
ETA_JUNTAS = 0.96

# Parâmetros cinemáticos do extrator automático por came (SI: m, rad)
O_EXT_X, O_EXT_Z = 0.034, Z_WORK_DATUM + 0.016     # (0.034, 0.996) m
EXT_CRANK_DX, EXT_CRANK_DZ = 0.038, 0.018          # m
EXT_R_CRANK = math.hypot(EXT_CRANK_DX, EXT_CRANK_DZ)
EXT_PHI0 = math.atan2(EXT_CRANK_DZ, EXT_CRANK_DX)
EXT_ANG_MAX_DEG = 22.0

O_SEG_X, O_SEG_Z = -0.028, O4_Z                    # (-0.028, 1.4475) m
CAM_R_BASE = 0.052
CAM_R_ROLLER = 0.0095
CAM_R_PRIME = CAM_R_BASE + CAM_R_ROLLER
CAM_PHI_R0 = math.radians(107.0)
_C0_X = O2_X + CAM_R_PRIME * math.cos(CAM_PHI_R0)
_C0_Z = O2_Z + CAM_R_PRIME * math.sin(CAM_PHI_R0)
SEG_R_ARM1 = math.hypot(_C0_X - O_SEG_X, _C0_Z - O_SEG_Z)
SEG_TH_ARM1_0 = math.atan2(_C0_Z - O_SEG_Z, _C0_X - O_SEG_X)
SEG_Q0_X, SEG_Q0_Z = 0.092, O_SEG_Z
SEG_R_ARM2 = math.hypot(SEG_Q0_X - O_SEG_X, SEG_Q0_Z - O_SEG_Z)  # 0.120 m
TIR_LEN = math.hypot((O_EXT_X + EXT_CRANK_DX) - SEG_Q0_X,
                     (O_EXT_Z + EXT_CRANK_DZ) - SEG_Q0_Z)        # 0.4339608 m
SPRING_PRELOAD_N = 12.0                            # N pré-carga mola de retorno
SPRING_K_N_M = 800.0                               # 0.80 N/mm


# =========================================================================================
# 2. EXTRAÇÃO DIRETA DO FREECAD (OPENCASCADE + ShapeMaterial)
# =========================================================================================
def extract_from_freecad() -> dict:
    if "/usr/lib/freecad/lib" not in sys.path and os.path.isdir("/usr/lib/freecad/lib"):
        sys.path.append("/usr/lib/freecad/lib")
    import FreeCAD as App

    if "prensa_baru_motorizada_v1" in App.listDocuments():
        doc = App.getDocument("prensa_baru_motorizada_v1")
    else:
        doc = App.openDocument(CAD_PATH)

    def shape_props_local(obj, rho_kg_m3: float) -> dict:
        rho_mm3 = rho_kg_m3 * 1e-9
        inv_m = obj.Placement.inverse().toMatrix()
        loc = obj.Shape.copy()
        loc.transformShape(inv_m)
        sols = loc.Solids if len(loc.Solids) > 0 else [loc]
        v_tot = m_tot = sx = sy = sz = 0.0
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

        # Propriedades no referencial global (para CG global da máquina e eixos paralelos a Y)
        cg_world = obj.Shape.CenterOfGravity
        return {
            "name": obj.Name,
            "label": obj.Label,
            "solids": len(sols),
            "vol_cm3": v_tot * 1e-3,
            "mass_kg": m_tot,
            "cg_local_mm": [cmx, cmy, cmz],
            "cg_world_mm": [float(cg_world.x), float(cg_world.y), float(cg_world.z)],
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

    # Inércias exatas dos componentes girantes em torno de seus eixos reais (400 rpm e 1730 rpm)
    def axis_iyy(part_name: str, ax_x_mm: float, ax_z_mm: float) -> float:
        p = parts[part_name]
        dx = (p["cg_world_mm"][0] - ax_x_mm) * 1e-3
        dz = (p["cg_world_mm"][2] - ax_z_mm) * 1e-3
        return p["Iyy_cg_kg_m2"] + p["mass_kg"] * (dx * dx + dz * dz)

    I_vol_400 = axis_iyy("Volante_Inercia_Aco", 56.0, 1278.0)
    I_polia_mov_400 = axis_iyy("Polia_Movida_D325", 56.0, 1278.0)
    I_eixo_int_400 = axis_iyy("Eixo_Intermediario_400rpm", 56.0, 1278.0)
    I_polia_mot_1730 = axis_iyy("Polia_Motora_D75", 56.0, 896.0)

    machine_parts = [p for nm, p in parts.items() if nm != "Baru_Simulado_30x50x40"]
    total_machine_mass = sum(p["mass_kg"] for p in machine_parts)
    cg_glob = [
        sum(p["mass_kg"] * p["cg_world_mm"][k] for p in machine_parts) / total_machine_mass
        for k in range(3)
    ]
    moving_main_mass = sum(
        groups_summary[g]["mass_kg"]
        for g in ("Corpo2_O2", "Corpo3_L3", "Corpo4_L4", "Corpo5_L5", "Corpo6_O5")
    )
    moving_ext_mass = sum(
        groups_summary[g]["mass_kg"]
        for g in ("Ext_Seguidora", "Ext_Tirante", "Ext_Ejetora")
    )
    drivetrain_mass = groups_summary["Sub07_Trem_Potencia"]["mass_kg"]

    payload = {
        "cad_file": CAD_PATH,
        "densities_kg_m3": RHO_MAP,
        "parts": parts,
        "groups": groups_summary,
        "drivetrain_inertias_kg_m2": {
            "I_volante_400rpm": I_vol_400,
            "I_polia_movida_400rpm": I_polia_mov_400,
            "I_eixo_intermediario_400rpm": I_eixo_int_400,
            "I_polia_motora_1730rpm": I_polia_mot_1730,
            "I_total_eixo_400rpm": I_vol_400 + I_polia_mov_400 + I_eixo_int_400,
            "I_refletida_O2_volante_only": (I2_REDUCER ** 2) * ETA2_REDUCER * I_vol_400,
            "I_refletida_O2_eixo400_e_motor": (
                (I2_REDUCER ** 2) * ETA2_REDUCER * (I_vol_400 + I_polia_mov_400 + I_eixo_int_400)
                + ((I1_BELT * I2_REDUCER) ** 2) * ETA1_BELT * ETA2_REDUCER * I_polia_mot_1730
            ),
        },
        "totals": {
            "total_machine_mass_kg": total_machine_mass,
            "moving_main_mass_kg": moving_main_mass,
            "moving_extractor_mass_kg": moving_ext_mass,
            "drivetrain_mass_kg": drivetrain_mass,
            "static_structure_mass_kg": total_machine_mass - moving_main_mass - moving_ext_mass - drivetrain_mass,
            "machine_global_cg_mm": cg_glob,
        },
    }
    with open(JSON_INERTIA_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
    print(f"[FreeCAD] Propriedades extraidas para {JSON_INERTIA_PATH}")
    print(f"[FreeCAD] Massa total = {total_machine_mass:.4f} kg | I_vol(400rpm) = {I_vol_400:.5f} kg.m^2 | I_eq_O2 = {payload['drivetrain_inertias_kg_m2']['I_refletida_O2_eixo400_e_motor']:.2f} kg.m^2")
    return payload


# =========================================================================================
# 3. SOLVER RK45 (DORMAND-PRINCE) E SIMULAÇÃO DO VOLANTE + COMPARAÇÃO 20 RPM vs 400 RPM
# =========================================================================================
def solve_ivp_rk45(fun, t_span, y0, t_eval, rtol=1e-8, atol=1e-10):
    """Integrador adaptativo Dormand-Prince RK4(5) de alta precisão em NumPy puro."""
    import numpy as np

    a21 = 1 / 5
    a31, a32 = 3 / 40, 9 / 40
    a41, a42, a43 = 44 / 45, -56 / 15, 32 / 9
    a51, a52, a53, a54 = 19372 / 6561, -25360 / 2187, 64448 / 6561, -212 / 729
    a61, a62, a63, a64, a65 = 9017 / 3168, -355 / 33, 46732 / 5247, 49 / 176, -5103 / 18656
    b1, b3, b4, b5, b6 = 35 / 384, 500 / 1113, 125 / 192, -2187 / 6784, 11 / 84
    e1, e3, e4, e5, e6, e7 = (
        71 / 57600, -71 / 16695, 71 / 1920, -17253 / 339200, 22 / 525, -1 / 40
    )

    t0, t_end = float(t_span[0]), float(t_span[1])
    y = np.array(y0, dtype=float)
    t = t0
    h = min(0.01, (t_end - t0) / 100.0)
    ts = [t]
    ys = [y.copy()]

    while t < t_end - 1e-12:
        if t + h > t_end:
            h = t_end - t
        k1 = np.asarray(fun(t, y), dtype=float)
        k2 = np.asarray(fun(t + 0.2 * h, y + h * a21 * k1), dtype=float)
        k3 = np.asarray(fun(t + 0.3 * h, y + h * (a31 * k1 + a32 * k2)), dtype=float)
        k4 = np.asarray(fun(t + 0.8 * h, y + h * (a41 * k1 + a42 * k2 + a43 * k3)), dtype=float)
        k5 = np.asarray(fun(t + 8 / 9 * h, y + h * (a51 * k1 + a52 * k2 + a53 * k3 + a54 * k4)), dtype=float)
        k6 = np.asarray(fun(t + h, y + h * (a61 * k1 + a62 * k2 + a63 * k3 + a64 * k4 + a65 * k5)), dtype=float)
        y_new = y + h * (b1 * k1 + b3 * k3 + b4 * k4 + b5 * k5 + b6 * k6)
        k7 = np.asarray(fun(t + h, y_new), dtype=float)
        err = h * (e1 * k1 + e3 * k3 + e4 * k4 + e5 * k5 + e6 * k6 + e7 * k7)
        scale = atol + rtol * np.maximum(np.abs(y), np.abs(y_new))
        err_norm = float(np.sqrt(np.mean((err / scale) ** 2)))

        if err_norm <= 1.0 or h <= 1e-7:
            t += h
            y = y_new
            ts.append(t)
            ys.append(y.copy())
            fac = 0.9 * (err_norm ** -0.2) if err_norm > 1e-12 else 2.0
            h = min(0.02, h * min(2.0, max(0.2, fac)))
        else:
            fac = 0.9 * (err_norm ** -0.25)
            h = max(1e-7, h * max(0.1, fac))

    ts_arr = np.array(ts)
    ys_arr = np.array(ys)
    out_y = np.column_stack([np.interp(t_eval, ts_arr, ys_arr[:, c]) for c in range(ys_arr.shape[1])])
    return out_y


def solve_main_kinematics_array(th2_rad):
    import numpy as np

    N = len(th2_rad)
    zO5 = np.zeros(N)
    th3 = np.zeros(N)
    th4 = np.zeros(N)
    th5 = np.zeros(N)
    mu = np.zeros(N)
    beta5 = np.zeros(N)
    B_arr = np.zeros((N, 2))
    A_arr = np.zeros((N, 2))

    for i, t2 in enumerate(th2_rad):
        ax, az = O2_X + L2 * math.cos(t2), O2_Z + L2 * math.sin(t2)
        A_arr[i] = (ax, az)
        dx, dz = ax - O4_X, az - O4_Z
        da = math.hypot(dx, dz)
        ac = (L4 * L4 - L3 * L3 + da * da) / (2.0 * da)
        hc = math.sqrt(max(0.0, L4 * L4 - ac * ac))
        x2, z2 = O4_X + ac * dx / da, O4_Z + ac * dz / da
        bp = (x2 + hc * (-dz) / da, z2 + hc * dx / da)
        bm = (x2 - hc * (-dz) / da, z2 - hc * dx / da)
        bx, bz = bp if bp[0] >= bm[0] else bm
        B_arr[i] = (bx, bz)
        zO5[i] = bz - math.sqrt(max(0.0, L5 * L5 - bx * bx))
        th3[i] = math.atan2(bz - az, bx - ax)
        th4[i] = math.atan2(bz - O4_Z, bx - O4_X)
        th5[i] = math.atan2(zO5[i] - bz, -bx)
        da_mu = abs(th4[i] - th3[i]) % (2.0 * math.pi)
        if da_mu > math.pi:
            da_mu = 2.0 * math.pi - da_mu
        mu[i] = math.degrees(da_mu)
        beta5[i] = math.asin(min(1.0, abs(bx) / L5))

    return {
        "A": A_arr, "B": B_arr, "zO5": zO5, "z_tip": zO5 - H_O5_TO_TIP,
        "th3": th3, "th4": th4, "th5": th5, "mu_deg": mu, "beta5": beta5,
    }


def run_flywheel_ode_and_comparison(inertia_data: dict) -> dict:
    import numpy as np

    N = 3600
    th = np.linspace(0.0, 2.0 * math.pi, N, endpoint=False)
    dth = th[1] - th[0]
    th_deg = np.degrees(th)
    kin = solve_main_kinematics_array(th)
    z_tip = kin["z_tip"]
    hp = (np.roll(z_tip, -1) - np.roll(z_tip, 1)) / (2.0 * dth)
    eta_inst = (1.0 - MU_GUIA * np.tan(kin["beta5"])) * ETA_JUNTAS

    # Corte 10 mm antes do PMI (descida theta2 in [165°, 345°])
    mask_10 = (th_deg >= TH2_PMS_DEG) & (th_deg <= TH2_PMI_DEG) & (z_tip <= Z_BARU_CUT_10MM)
    s10 = np.where(mask_10, np.clip((Z_BARU_CUT_10MM - z_tip) / 0.010, 0.0, 1.0), 0.0)
    F_lin_10 = F_QUEBRA_MAX * s10
    F_bio_10 = F_QUEBRA_MAX * (s10 ** 0.4)

    # Corte 4.75 mm (Baru_Simulado_30x50x40 do CAD)
    mask_475 = (th_deg >= TH2_PMS_DEG) & (th_deg <= TH2_PMI_DEG) & (z_tip <= Z_BARU_TOP)
    s475 = np.where(mask_475, np.clip((Z_BARU_TOP - z_tip) / 0.00475, 0.0, 1.0), 0.0)
    F_bio_475 = F_QUEBRA_MAX * (s475 ** 0.4)

    # Torque resistente com rendimento da guia + juntas (modelo detalhado) e eta_mec = 0.90 (ref. anterior)
    T_lin_90 = (-F_lin_10 * hp) / 0.90
    T_bio_90 = (-F_bio_10 * hp) / 0.90
    T_lin_inst = (-F_lin_10 * hp) / eta_inst
    T_bio_inst = (-F_bio_10 * hp) / eta_inst
    T_bio_475 = (-F_bio_475 * hp) / eta_inst

    def energy_metrics(T_arr):
        W = float(np.trapezoid(np.append(T_arr, T_arr[0]), np.append(th, 2.0 * math.pi)))
        Tm = W / (2.0 * math.pi)
        dE = float(np.trapezoid(np.append(np.maximum(0.0, T_arr - Tm), max(0.0, T_arr[0] - Tm)),
                                np.append(th, 2.0 * math.pi)))
        return {
            "W_ciclo_J": W,
            "T_med_Nm": Tm,
            "P_med_W": Tm * W2_NOMINAL,
            "T_pico_Nm": float(np.max(T_arr)),
            "theta_pico_deg": float(th_deg[int(np.argmax(T_arr))]),
            "Delta_E_J": dE,
            "I_req_Cf20_kg_m2": dE / (W2_NOMINAL ** 2 * 0.20),
            "I_req_Cf10_kg_m2": dE / (W2_NOMINAL ** 2 * 0.10),
        }

    m_lin_90 = energy_metrics(T_lin_90)
    m_bio_90 = energy_metrics(T_bio_90)
    m_lin_inst = energy_metrics(T_lin_inst)
    m_bio_inst = energy_metrics(T_bio_inst)
    m_bio_475 = energy_metrics(T_bio_475)

    # Inércia refletida real do trem de potência CAD (volante 400 rpm + polia D325 + eixo + polia D75)
    drv_I = inertia_data["drivetrain_inertias_kg_m2"]
    I_eq_O2_400rpm = drv_I["I_refletida_O2_eixo400_e_motor"]
    I_vol_only = drv_I["I_volante_400rpm"]
    m_vol_cad = inertia_data["parts"]["Volante_Inercia_Aco"]["mass_kg"]

    # Comparação de aro D=800 mm direto em O2 (20 rpm) p/ Cf=20%:
    # Para aro R_int = 0.80 R_ext, R_ext=0.40 m => I = 0.5*m*(0.4^2+0.32^2) = 0.1312*m (ou 1.05x com alma = 0.13776*m)
    m_aro_direct_lin20 = m_lin_90["I_req_Cf20_kg_m2"] / (1.05 * 0.5 * (0.40 ** 2 + 0.32 ** 2))
    m_aro_direct_bio20 = m_bio_90["I_req_Cf20_kg_m2"] / (1.05 * 0.5 * (0.40 ** 2 + 0.32 ** 2))

    # Inércia equivalente variável do mecanismo em O2 (massas reais do CAD)
    groups = inertia_data["groups"]
    m_eq_piston = (groups["Corpo6_O5"]["mass_kg"] + 0.5 * groups["Corpo5_L5"]["mass_kg"]
                   + 0.25 * groups["Corpo4_L4"]["mass_kg"])
    I_O2_crank = groups["Corpo2_O2"]["Iyy_orig_kg_m2"]
    dhp = (np.roll(hp, -1) - np.roll(hp, 1)) / (2.0 * dth)

    def simulate_ode(I_fly_O2: float, T_res_arr, T_motor_const: float):
        # Integra 4 ciclos e guarda os últimos 3 ciclos (regime periódico estacionário)
        t_eval = np.linspace(0.0, 4.0 * T_CICLO, 2401)

        def rhs(_t, y):
            th_mod = y[0] % (2.0 * math.pi)
            w = y[1]
            hp_v = float(np.interp(th_mod, th, hp, period=2.0 * math.pi))
            dhp_v = float(np.interp(th_mod, th, dhp, period=2.0 * math.pi))
            Tres_v = float(np.interp(th_mod, th, T_res_arr, period=2.0 * math.pi))
            I_tot = I_fly_O2 + I_O2_crank + m_eq_piston * (hp_v ** 2)
            al = (T_motor_const - Tres_v - m_eq_piston * hp_v * dhp_v * (w ** 2)) / I_tot
            return [w, al]

        # Inicializa próximo a w_med e ajusta w0 iterativamente para média exata de 20 rpm
        w0 = W2_NOMINAL
        for _ in range(3):
            sol = solve_ivp_rk45(rhs, (0.0, 4.0 * T_CICLO), [TH2_PMI_DEG * math.pi / 180.0, w0], t_eval)
            idx_last = t_eval >= 3.0 * T_CICLO
            w_mean = float(np.mean(sol[idx_last, 1]))
            w0 += (W2_NOMINAL - w_mean)

        idx_3c = t_eval >= T_CICLO
        t_3c = t_eval[idx_3c] - T_CICLO
        th_3c = sol[idx_3c, 0]
        w_3c = sol[idx_3c, 1]
        rpm_3c = w_3c * 60.0 / (2.0 * math.pi)
        idx_1c = t_eval >= 3.0 * T_CICLO
        w_1c = sol[idx_1c, 1]
        cf = (float(np.max(w_1c)) - float(np.min(w_1c))) / W2_NOMINAL
        return {
            "t_3c": t_3c, "th_3c_deg": np.degrees(th_3c % (2.0 * math.pi)),
            "w_3c": w_3c, "rpm_3c": rpm_3c,
            "t_1c": t_eval[idx_1c] - 3.0 * T_CICLO,
            "th_1c_rad": sol[idx_1c, 0] % (2.0 * math.pi),
            "w_1c": w_1c,
            "rpm_min": float(np.min(w_1c) * 60.0 / (2.0 * math.pi)),
            "rpm_max": float(np.max(w_1c) * 60.0 / (2.0 * math.pi)),
            "cf_pct": cf * 100.0,
        }

    # Caso de travamento (stall) sem redutor: volante 1,65 kg.m^2 direto a 20 rpm partindo do PMS (165 deg)
    def simulate_stall_single_cycle(I_fly_O2: float, T_res_arr, T_motor_const: float):
        t_eval = np.linspace(0.0, T_CICLO, 601)
        def rhs(_t, y):
            th_mod = y[0] % (2.0 * math.pi)
            w = y[1]
            if w <= 0.0:
                return [0.0, 0.0]
            hp_v = float(np.interp(th_mod, th, hp, period=2.0 * math.pi))
            dhp_v = float(np.interp(th_mod, th, dhp, period=2.0 * math.pi))
            Tres_v = float(np.interp(th_mod, th, T_res_arr, period=2.0 * math.pi))
            I_tot = I_fly_O2 + I_O2_crank + m_eq_piston * (hp_v ** 2)
            al = (T_motor_const - Tres_v - m_eq_piston * hp_v * dhp_v * (w ** 2)) / I_tot
            return [w, al]
        sol = solve_ivp_rk45(rhs, (0.0, T_CICLO), [math.radians(TH2_PMS_DEG), W2_NOMINAL], t_eval)
        w_out = np.maximum(0.0, sol[:, 1])
        rpm_out = w_out * 60.0 / (2.0 * math.pi)
        return {
            "t_3c": t_eval, "rpm_3c": rpm_out,
            "rpm_min": float(np.min(rpm_out)), "rpm_max": float(np.max(rpm_out)),
            "cf_pct": 100.0 * (float(np.max(rpm_out)) - float(np.min(rpm_out))) / RPM_NOMINAL,
            "stalled": bool(np.min(w_out) < 0.05),
        }

    # Simulações ODE comparativas (usando carga biomaterial s^0.4 10 mm)
    ode_400rpm_bio = simulate_ode(I_eq_O2_400rpm, T_bio_90, m_bio_90["T_med_Nm"])
    ode_400rpm_lin = simulate_ode(I_eq_O2_400rpm, T_lin_90, m_lin_90["T_med_Nm"])
    ode_direct20_bio = simulate_ode(m_bio_90["I_req_Cf20_kg_m2"], T_bio_90, m_bio_90["T_med_Nm"])
    ode_direct_compact = simulate_stall_single_cycle(1.6518, T_bio_90, m_bio_90["T_med_Nm"])

    return {
        "th_deg": th_deg, "z_tip": z_tip,
        "T_lin_90": T_lin_90, "T_bio_90": T_bio_90,
        "T_lin_inst": T_lin_inst, "T_bio_inst": T_bio_inst, "T_bio_475": T_bio_475,
        "metrics": {
            "lin_10mm_eta90": m_lin_90,
            "bio_10mm_eta90": m_bio_90,
            "lin_10mm_etainst": m_lin_inst,
            "bio_10mm_etainst": m_bio_inst,
            "bio_475mm_etainst": m_bio_475,
        },
        "direct_20rpm_D800_mass_kg": {
            "linear_Cf20": m_aro_direct_lin20,
            "bio_Cf20": m_aro_direct_bio20,
        },
        "flywheel_400rpm_cad": {
            "mass_volante_kg": m_vol_cad,
            "I_volante_kg_m2": I_vol_only,
            "I_eq_O2_total_kg_m2": I_eq_O2_400rpm,
            "mass_reduction_vs_direct_bio20": m_aro_direct_bio20 / m_vol_cad,
        },
        "ode_400rpm_bio": ode_400rpm_bio,
        "ode_400rpm_lin": ode_400rpm_lin,
        "ode_direct20_bio": ode_direct20_bio,
        "ode_direct_compact": ode_direct_compact,
    }


# =========================================================================================
# 4. SOLVER D'ALEMBERT 15x15 (MECANISMO PRINCIPAL 360°: CONSTANT w2 + ODE RIPPLE w2(t))
# =========================================================================================
def run_main_mechanism_dalembert_360(inertia_data: dict, ode_res: dict | None = None, N: int = 1441) -> dict:
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

    th2_deg = np.linspace(0.0, 360.0, N)
    th2 = np.radians(th2_deg)
    t = (th2_deg / 360.0) * T_CICLO

    if ode_res is None:
        w2 = np.full(N, W2_NOMINAL)
        al2 = np.zeros(N)
    else:
        # Interpola w2(theta2) da EDO periódica estacionária e calcula alpha2 = w2 * dw2/dtheta2
        th_ode = ode_res["th_1c_rad"]
        w_ode = ode_res["w_1c"]
        idx_sort = np.argsort(th_ode)
        th_s, w_s = th_ode[idx_sort], w_ode[idx_sort]
        # Extensão periódica
        th_ext = np.concatenate(([th_s[-1] - 2.0 * math.pi], th_s, [th_s[0] + 2.0 * math.pi]))
        w_ext = np.concatenate(([w_s[-1]], w_s, [w_s[0]]))
        w2 = np.interp(th2, th_ext, w_ext)
        dth = th2[1] - th2[0]
        dw2_dth = np.gradient(w2, dth)
        al2 = w2 * dw2_dth

    O2 = np.array([O2_X, O2_Z])
    O4 = np.array([O4_X, O4_Z])

    keys = ("th3", "th4", "th5", "w3", "w4", "w5", "al3", "al4", "al5",
            "zO5", "z_tip", "vO5_z", "aO5_z", "mu_deg", "Ek", "dEk_dt",
            "T12_in", "T12_vw", "T12_grav", "T12_cut_bio10", "T12_cut_bio475", "T12_total_bio10")
    out = {k: np.zeros(N) for k in keys}
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
        rp = np.array([-r[1], r[0]])
        return P + r, vP + w * rp, aP + al * rp - (w * w) * r

    for k in range(N):
        t2 = th2[k]
        Ax, Az = O2_X + L2 * math.cos(t2), O2_Z + L2 * math.sin(t2)
        A = np.array([Ax, Az])
        dx, dz = Ax - O4_X, Az - O4_Z
        dA = math.hypot(dx, dz)
        ac = (L4 * L4 - L3 * L3 + dA * dA) / (2.0 * dA)
        hc = math.sqrt(max(0.0, L4 * L4 - ac * ac))
        x2, z2 = O4_X + ac * dx / dA, O4_Z + ac * dz / dA
        bp = (x2 + hc * (-dz) / dA, z2 + hc * dx / dA)
        bm = (x2 - hc * (-dz) / dA, z2 - hc * dx / dA)
        Bx, Bz = bp if bp[0] >= bm[0] else bm
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

        J1 = np.array([[-L3 * math.sin(t3), L4 * math.sin(t4)], [L3 * math.cos(t3), -L4 * math.cos(t4)]])
        w3, w4 = np.linalg.solve(J1, np.array([L2 * w2[k] * math.sin(t2), -L2 * w2[k] * math.cos(t2)]))
        b_acc = np.array([
            L2 * al2[k] * math.sin(t2) + L2 * (w2[k] ** 2) * math.cos(t2) + L3 * (w3 ** 2) * math.cos(t3) - L4 * (w4 ** 2) * math.cos(t4),
            -L2 * al2[k] * math.cos(t2) + L2 * (w2[k] ** 2) * math.sin(t2) + L3 * (w3 ** 2) * math.sin(t3) - L4 * (w4 ** 2) * math.sin(t4),
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

        G2, vG2, aG2 = body_cg_kin(O2, np.zeros(2), np.zeros(2), t2, w2[k], al2[k], cg2_loc)
        G3, vG3, aG3 = body_cg_kin(A, vA, aA, t3, w3, al3, cg3_loc)
        G4, vG4, aG4 = body_cg_kin(O4, np.zeros(2), np.zeros(2), t4, w4, al4, cg4_loc)
        G5, vG5, aG5 = body_cg_kin(B, vB, aB, t5, w5, al5, cg5_loc)
        G6, vG6, aG6 = O5 + cg6_loc, vO5, aO5

        Ek = dEk_dt = 0.0
        for idx_b, (mi, Ii, vi, ai, wi, ali) in enumerate(
            zip((m2, m3, m4, m5, m6), (IG2, IG3, IG4, IG5, IG6), (vG2, vG3, vG4, vG5, vG6),
                (aG2, aG3, aG4, aG5, aG6), (w2[k], w3, w4, w5, 0.0), (al2[k], al3, al4, al5, 0.0)), start=2
        ):
            Ek += 0.5 * mi * float(np.dot(vi, vi)) + 0.5 * Ii * (wi ** 2)
            dEk_dt += mi * float(np.dot(vi, ai)) + Ii * wi * ali
            out[f"aG{idx_b}_mag"][k] = float(np.linalg.norm(ai))
            out[f"Fin{idx_b}_mag"][k] = mi * float(np.linalg.norm(ai))
            out[f"Tin{idx_b}"][k] = -Ii * ali
        out["Ek"][k], out["dEk_dt"][k] = Ek, dEk_dt

        M = np.zeros((15, 15))
        def cr(row_idx, col_fx, col_fz, r_vec, sign=1.0):
            M[row_idx, col_fx] += -sign * r_vec[1]
            M[row_idx, col_fz] += sign * r_vec[0]

        M[0, 0] = 1.0; M[0, 2] = -1.0; M[1, 1] = 1.0; M[1, 3] = -1.0
        cr(2, 0, 1, O2 - G2, +1.0); cr(2, 2, 3, A - G2, -1.0); M[2, 14] = 1.0
        M[3, 2] = 1.0; M[3, 4] = -1.0; M[4, 3] = 1.0; M[4, 5] = -1.0
        cr(5, 2, 3, A - G3, +1.0); cr(5, 4, 5, B - G3, -1.0)
        M[6, 6] = 1.0; M[6, 8] = -1.0; M[7, 7] = 1.0; M[7, 9] = -1.0
        cr(8, 6, 7, O4 - G4, +1.0); cr(8, 8, 9, B - G4, -1.0)
        M[9, 4] = 1.0; M[9, 8] = 1.0; M[9, 10] = -1.0
        M[10, 5] = 1.0; M[10, 9] = 1.0; M[10, 11] = -1.0
        cr(11, 4, 5, B - G5, +1.0); cr(11, 8, 9, B - G5, +1.0); cr(11, 10, 11, O5 - G5, -1.0)
        M[12, 10] = 1.0; M[12, 12] = 1.0; M[13, 11] = 1.0
        cr(14, 10, 11, O5 - G6, +1.0); M[14, 13] = 1.0

        b_in = np.array([
            m2 * aG2[0], m2 * aG2[1], IG2 * al2[k],
            m3 * aG3[0], m3 * aG3[1], IG3 * al3,
            m4 * aG4[0], m4 * aG4[1], IG4 * al4,
            m5 * aG5[0], m5 * aG5[1], IG5 * al5,
            m6 * aG6[0], m6 * aG6[1], 0.0,
        ])
        x_in = np.linalg.solve(M, b_in)

        b_grav = np.array([
            0.0, m2 * G_ACCEL, 0.0, 0.0, m3 * G_ACCEL, 0.0,
            0.0, m4 * G_ACCEL, 0.0, 0.0, m5 * G_ACCEL, 0.0, 0.0, m6 * G_ACCEL, 0.0,
        ])
        x_grav = np.linalg.solve(M, b_grav)

        if TH2_PMS_DEG <= th2_deg[k] <= TH2_PMI_DEG and z_tip < Z_BARU_CUT_10MM:
            s10 = min(1.0, max(0.0, (Z_BARU_CUT_10MM - z_tip) / 0.010))
            F_cut_10 = F_QUEBRA_MAX * (s10 ** 0.4)
        else:
            F_cut_10 = 0.0
        if TH2_PMS_DEG <= th2_deg[k] <= TH2_PMI_DEG and z_tip < Z_BARU_TOP:
            s475 = min(1.0, max(0.0, (Z_BARU_TOP - z_tip) / 0.00475))
            F_cut_475 = F_QUEBRA_MAX * (s475 ** 0.4)
        else:
            F_cut_475 = 0.0

        b_cut10 = np.zeros(15); b_cut10[13] = -F_cut_10
        x_cut10 = np.linalg.solve(M, b_cut10)
        b_cut475 = np.zeros(15); b_cut475[13] = -F_cut_475
        x_cut475 = np.linalg.solve(M, b_cut475)
        x_tot = x_in + x_grav + x_cut10

        out["T12_in"][k] = x_in[14]
        out["T12_vw"][k] = dEk_dt / w2[k]
        out["T12_grav"][k] = x_grav[14]
        out["T12_cut_bio10"][k] = x_cut10[14]
        out["T12_cut_bio475"][k] = x_cut475[14]
        out["T12_total_bio10"][k] = x_tot[14]

        def store(vec, sfx):
            out[f"R_O2_{sfx}"][k] = math.hypot(vec[0], vec[1])
            out[f"R_A_{sfx}"][k] = math.hypot(vec[2], vec[3])
            out[f"R_B3_{sfx}"][k] = math.hypot(vec[4], vec[5])
            out[f"R_B4_{sfx}"][k] = math.hypot(vec[8], vec[9])
            out[f"R_B5_{sfx}"][k] = math.hypot(vec[4] + vec[8], vec[5] + vec[9])
            out[f"R_O4_{sfx}"][k] = math.hypot(vec[6], vec[7])
            out[f"R_O5_{sfx}"][k] = math.hypot(vec[10], vec[11])
            out[f"R_N16_{sfx}"][k] = abs(vec[12])
            out[f"R_M16_{sfx}"][k] = abs(vec[13])

        store(x_in, "in"); store(x_grav, "grav"); store(x_cut10, "cut_bio"); store(x_tot, "tot")

    vw_max_err = float(np.max(np.abs(out["T12_in"] - out["T12_vw"])))
    return {"t": t, "th2_deg": th2_deg, "w2": w2, "al2": al2, "vw_max_err_Nm": vw_max_err, "out": out}


# =========================================================================================
# 5. SOLVER D'ALEMBERT 9x9 DO EXTRATOR AUTOMÁTICO POR CAME (0..360° @ 20 RPM)
# =========================================================================================
def run_cam_extractor_dalembert(inertia_data: dict, N: int = 1441) -> dict:
    import numpy as np

    groups = inertia_data["groups"]
    me = groups["Ext_Ejetora"]["mass_kg"]
    mt = groups["Ext_Tirante"]["mass_kg"]
    ms = groups["Ext_Seguidora"]["mass_kg"]

    IGe = groups["Ext_Ejetora"]["Iyy_cg_kg_m2"]
    IGt = groups["Ext_Tirante"]["Iyy_cg_kg_m2"]
    IGs = groups["Ext_Seguidora"]["Iyy_cg_kg_m2"]

    cge_loc = np.array([groups["Ext_Ejetora"]["cg_local_mm"][0], groups["Ext_Ejetora"]["cg_local_mm"][2]]) * 1e-3
    cgt_loc = np.array([groups["Ext_Tirante"]["cg_local_mm"][0], groups["Ext_Tirante"]["cg_local_mm"][2]]) * 1e-3
    cgs_loc = np.array([groups["Ext_Seguidora"]["cg_local_mm"][0], groups["Ext_Seguidora"]["cg_local_mm"][2]]) * 1e-3

    th2_deg = np.linspace(0.0, 360.0, N)
    th2 = np.radians(th2_deg)
    t = (th2_deg / 360.0) * T_CICLO

    psi = np.zeros(N)
    dpsi = np.zeros(N)
    ddpsi = np.zeros(N)
    psi_max = math.radians(EXT_ANG_MAX_DEG)
    for k, th_d in enumerate(th2_deg):
        th_m = th_d % 360.0
        if 60.0 <= th_m <= 106.0:
            b = math.radians(60.0)
            u = (math.radians(th_m) - b) / math.radians(46.0)
            psi[k] = psi_max * (10 * u**3 - 15 * u**4 + 6 * u**5)
            dpsi[k] = psi_max * (30 * u**2 - 60 * u**3 + 30 * u**4) * (W2_NOMINAL / math.radians(46.0))
            ddpsi[k] = psi_max * (60 * u - 180 * u**2 + 120 * u**3) * ((W2_NOMINAL / math.radians(46.0)) ** 2)
        elif 106.0 < th_m <= 150.0:
            u = (math.radians(th_m) - math.radians(106.0)) / math.radians(44.0)
            psi[k] = psi_max * (1.0 - (10 * u**3 - 15 * u**4 + 6 * u**5))
            dpsi[k] = -psi_max * (30 * u**2 - 60 * u**3 + 30 * u**4) * (W2_NOMINAL / math.radians(44.0))
            ddpsi[k] = -psi_max * (60 * u - 180 * u**2 + 120 * u**3) * ((W2_NOMINAL / math.radians(44.0)) ** 2)

    O_ext = np.array([O_EXT_X, O_EXT_Z])
    O_seg = np.array([O_SEG_X, O_SEG_Z])

    def body_cg_math(P, vP, aP, th, w, al, loc_xz):
        c, s = math.cos(th), math.sin(th)
        r = np.array([loc_xz[0] * c - loc_xz[1] * s, loc_xz[0] * s + loc_xz[1] * c])
        rp = np.array([-r[1], r[0]])
        return P + r, vP + w * rp, aP + al * rp - (w * w) * r

    out = {k: np.zeros(N) for k in (
        "psi_deg", "gamma_deg", "cam_lift_mm", "alpha_p_deg", "z_tip_mm",
        "Fine_mag", "Fint_mag", "Fins_mag", "T_seg_in", "T_seg_vw",
        "F_cam_contact_N", "F_spring_N", "R_Oext_in", "R_Oseg_in", "Ek"
    )}

    # Guarda posição do rolete no referencial do came para calcular normal de contato & ângulo de pressão
    Cx_cam = np.zeros(N)
    Cz_cam = np.zeros(N)
    C_world = np.zeros((N, 2))
    th_arm1_arr = np.zeros(N)
    z_tip_arr = solve_main_kinematics_array(th2)["z_tip"] * 1e3

    for k in range(N):
        th_e = -psi[k]
        w_e = -dpsi[k]
        al_e = -ddpsi[k]
        ang_e_pin = th_e + EXT_PHI0
        P = O_ext + EXT_R_CRANK * np.array([math.cos(ang_e_pin), math.sin(ang_e_pin)])
        vP = EXT_R_CRANK * w_e * np.array([-math.sin(ang_e_pin), math.cos(ang_e_pin)])
        aP = EXT_R_CRANK * al_e * np.array([-math.sin(ang_e_pin), math.cos(ang_e_pin)]) \
             - EXT_R_CRANK * (w_e ** 2) * np.array([math.cos(ang_e_pin), math.sin(ang_e_pin)])

        dx, dz = P[0] - O_seg[0], P[1] - O_seg[1]
        d = math.hypot(dx, dz)
        ac = (SEG_R_ARM2 ** 2 - TIR_LEN ** 2 + d ** 2) / (2.0 * d)
        hc = math.sqrt(max(0.0, SEG_R_ARM2 ** 2 - ac ** 2))
        x2, z2 = O_seg[0] + ac * dx / d, O_seg[1] + ac * dz / d
        bp = (x2 + hc * (-dz) / d, z2 + hc * dx / d)
        bm = (x2 - hc * (-dz) / d, z2 - hc * dx / d)
        Qx, Qz = bp if bp[1] >= bm[1] else bm
        Q = np.array([Qx, Qz])

        th_s = math.atan2(Qz - O_seg[1], Qx - O_seg[0])
        th_t = math.atan2(P[0] - Qx, -(P[1] - Qz))

        # Fecho: P = Q + L_tir * [sin(th_t), -cos(th_t)]
        Js = np.array([
            [-SEG_R_ARM2 * math.sin(th_s), TIR_LEN * math.cos(th_t)],
            [ SEG_R_ARM2 * math.cos(th_s), TIR_LEN * math.sin(th_t)],
        ])
        w_s, w_t = np.linalg.solve(Js, vP)
        rhs_a = aP + SEG_R_ARM2 * (w_s ** 2) * np.array([math.cos(th_s), math.sin(th_s)]) \
                   + TIR_LEN * (w_t ** 2) * np.array([math.sin(th_t), -math.cos(th_t)])
        al_s, al_t = np.linalg.solve(Js, rhs_a)

        vQ = SEG_R_ARM2 * w_s * np.array([-math.sin(th_s), math.cos(th_s)])
        aQ = SEG_R_ARM2 * al_s * np.array([-math.sin(th_s), math.cos(th_s)]) \
             - SEG_R_ARM2 * (w_s ** 2) * np.array([math.cos(th_s), math.sin(th_s)])

        Ge, vGe, aGe = body_cg_math(O_ext, np.zeros(2), np.zeros(2), th_e, w_e, al_e, cge_loc)
        Gt, vGt, aGt = body_cg_math(Q, vQ, aQ, th_t, w_t, al_t, cgt_loc)
        Gs, vGs, aGs = body_cg_math(O_seg, np.zeros(2), np.zeros(2), th_s, w_s, al_s, cgs_loc)

        Ek = 0.5 * me * np.dot(vGe, vGe) + 0.5 * IGe * (w_e ** 2) \
           + 0.5 * mt * np.dot(vGt, vGt) + 0.5 * IGt * (w_t ** 2) \
           + 0.5 * ms * np.dot(vGs, vGs) + 0.5 * IGs * (w_s ** 2)
        dEk = me * np.dot(vGe, aGe) + IGe * w_e * al_e \
            + mt * np.dot(vGt, aGt) + IGt * w_t * al_t \
            + ms * np.dot(vGs, aGs) + IGs * w_s * al_s

        # Sistema 9x9 Newton-Euler: [F_Osx, F_Osz, F_Qtx, F_Qtz, F_Pex, F_Pez, F_Oex, F_Oez, T_seg]
        Ms = np.zeros((9, 9))
        def cr(row, cx, cz, rv, sgn=1.0):
            Ms[row, cx] += -sgn * rv[1]
            Ms[row, cz] += sgn * rv[0]

        Ms[0, 0] = 1.0; Ms[0, 2] = -1.0; Ms[1, 1] = 1.0; Ms[1, 3] = -1.0
        cr(2, 0, 1, O_seg - Gs, +1.0); cr(2, 2, 3, Q - Gs, -1.0); Ms[2, 8] = 1.0
        Ms[3, 2] = 1.0; Ms[3, 4] = -1.0; Ms[4, 3] = 1.0; Ms[4, 5] = -1.0
        cr(5, 2, 3, Q - Gt, +1.0); cr(5, 4, 5, P - Gt, -1.0)
        Ms[6, 4] = 1.0; Ms[6, 6] = 1.0; Ms[7, 5] = 1.0; Ms[7, 7] = 1.0
        cr(8, 4, 5, P - Ge, +1.0); cr(8, 6, 7, O_ext - Ge, +1.0)

        bs_in = np.array([ms * aGs[0], ms * aGs[1], IGs * al_s,
                          mt * aGt[0], mt * aGt[1], IGt * al_t,
                          me * aGe[0], me * aGe[1], IGe * al_e])
        xs_in = np.linalg.solve(Ms, bs_in)

        # Gravidade + Baru (35 g na pá em x_loc=-0.032 m durante a subida)
        m_baru = 0.035 if 60.0 <= (th2_deg[k] % 360.0) <= 110.0 else 0.0
        r_baru = np.array([-0.032 * math.cos(th_e), -0.032 * math.sin(th_e)])
        bs_gr = np.array([
            0.0, ms * G_ACCEL, 0.0,
            0.0, mt * G_ACCEL, 0.0,
            0.0, (me + m_baru) * G_ACCEL, m_baru * G_ACCEL * r_baru[0],
        ])
        xs_gr = np.linalg.solve(Ms, bs_gr)

        # Mola de retorno puxando P_top em +Z: F_spring = F0 + k * (P0_z - P_z)
        F_sp = SPRING_PRELOAD_N + SPRING_K_N_M * max(0.0, (O_EXT_Z + EXT_CRANK_DZ) - P[1])
        bs_sp = np.zeros(9)
        bs_sp[7] = -F_sp
        bs_sp[8] = -(P[0] - Ge[0]) * F_sp
        xs_sp = np.linalg.solve(Ms, bs_sp)

        # Posição do rolete no came
        th_arm1 = SEG_TH_ARM1_0 + th_s
        th_arm1_arr[k] = th_arm1
        C_pt = O_seg + SEG_R_ARM1 * np.array([math.cos(th_arm1), math.sin(th_arm1)])
        C_world[k] = C_pt
        vx, vz = C_pt[0] - O2_X, C_pt[1] - O2_Z
        Cx_cam[k] = vx * math.cos(-th2[k]) - vz * math.sin(-th2[k])
        Cz_cam[k] = vx * math.sin(-th2[k]) + vz * math.cos(-th2[k])

        out["psi_deg"][k] = math.degrees(psi[k])
        out["gamma_deg"][k] = -math.degrees(th_s)
        out["cam_lift_mm"][k] = (math.hypot(vx, vz) - CAM_R_PRIME) * 1e3
        out["z_tip_mm"][k] = z_tip_arr[k]
        out["Fine_mag"][k] = me * float(np.linalg.norm(aGe))
        out["Fint_mag"][k] = mt * float(np.linalg.norm(aGt))
        out["Fins_mag"][k] = ms * float(np.linalg.norm(aGs))
        out["T_seg_in"][k] = xs_in[8]
        out["T_seg_vw"][k] = (dEk / w_s) if abs(w_s) > 1e-6 else 0.0
        out["R_Oext_in"][k] = math.hypot(xs_in[6], xs_in[7])
        out["R_Oseg_in"][k] = math.hypot(xs_in[0], xs_in[1])
        out["Ek"][k] = Ek
        out["F_spring_N"][k] = F_sp
        # Torque líquido que o came precisa fornecer em O_seg (positivo = empurrar rolete para fora)
        out["T_seg_req_tot"] = out.get("T_seg_req_tot", np.zeros(N))
        out["T_seg_req_tot"][k] = xs_in[8] + xs_gr[8] + xs_sp[8]

    # Normal do came e força normal de contato F_cam_n > 0 (comprovando ausência de salto!)
    dth = th2[1] - th2[0]
    dCx = np.gradient(Cx_cam, dth)
    dCz = np.gradient(Cz_cam, dth)
    ds = np.hypot(dCx, dCz)
    nx = dCz / ds
    nz = -dCx / ds
    for k in range(N):
        # Normal externa do came no mundo
        onx = -(nx[k] * math.cos(th2[k]) - nz[k] * math.sin(th2[k]))
        onz = -(nx[k] * math.sin(th2[k]) + nz[k] * math.cos(th2[k]))
        # Direção do movimento do rolete quando gamma aumenta (th_s diminui): (sin th_arm1, -cos th_arm1)
        vx_dir, vz_dir = math.sin(th_arm1_arr[k]), -math.cos(th_arm1_arr[k])
        cos_ap = min(1.0, abs(onx * vx_dir + onz * vz_dir))
        out["alpha_p_deg"][k] = math.degrees(math.acos(cos_ap))
        # Braço de alavanca do contato normal em torno de O_seg: r_OC x n_out (CW positivo -> -k_CCW)
        r_oc = C_world[k] - O_seg
        # T_cam_ccw = F_n * (r_oc_x * onz - r_oc_z * onx); note T_seg_req_tot é CCW positivo!
        lever_ccw = r_oc[0] * onz - r_oc[1] * onx
        out["F_cam_contact_N"][k] = out["T_seg_req_tot"][k] / lever_ccw

    # Validação VW onde |w_s| > 0.01
    mask = np.abs(np.gradient(-np.radians(out["gamma_deg"]), (T_CICLO / (N - 1)))) > 0.01
    vw_err = float(np.max(np.abs(out["T_seg_in"][mask] - out["T_seg_vw"][mask])))
    return {"t": t, "th2_deg": th2_deg, "vw_max_err_Nm": vw_err, "out": out}


# =========================================================================================
# 6. GRÁFICOS 300 DPI (REPO + VAULT) E EXPORTAÇÃO JSON
# =========================================================================================
def generate_plots(fly_res, sim_const, sim_ode, sim_ext):
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

    # --- FIGURA 1: Torque, Volante 400 RPM vs 20 RPM Direto e EDO Não-Linear (RK45) ---
    fig1, axs = plt.subplots(2, 2, figsize=(13.6, 8.8))
    fig1.suptitle(
        "Dimensionamento do Trem de Potência 20 RPM e Volante a 400 RPM (EDO RK45 — Quebra 10 mm @ 5000 N)",
        fontsize=12.2, fontweight="bold", y=0.98
    )

    th_d = fly_res["th_deg"]
    Tm_b = fly_res["metrics"]["bio_10mm_eta90"]["T_med_Nm"]
    Tm_l = fly_res["metrics"]["lin_10mm_eta90"]["T_med_Nm"]

    ax = axs[0, 0]
    ax.axvspan(165.0, 258.0, color="#eef5ff", alpha=0.7, label="Descida em vazio (20 mm)")
    ax.axvspan(258.0, 345.0, color="#fde8e2", alpha=0.8, label="Corte do Baru (10 mm @ 5 kN)")
    ax.plot(th_d, fly_res["T_bio_90"], lw=2.3, color="#d95f02", label=f"Bio s^0.4 (Pico={fly_res['metrics']['bio_10mm_eta90']['T_pico_Nm']:.1f} N·m, ΔE={fly_res['metrics']['bio_10mm_eta90']['Delta_E_J']:.1f} J)")
    ax.plot(th_d, fly_res["T_lin_90"], lw=2.1, color="#b2182b", ls="--", label=f"Linear (Pico={fly_res['metrics']['lin_10mm_eta90']['T_pico_Nm']:.1f} N·m, ΔE={fly_res['metrics']['lin_10mm_eta90']['Delta_E_J']:.1f} J)")
    ax.axhline(Tm_b, color="#2166ac", lw=1.8, ls="-.", label=f"T_méd Bio = {Tm_b:.2f} N·m ({Tm_b*W2_NOMINAL:.1f} W)")
    ax.set_title("1. Torque Resistente na Manivela O2 (165°=PMS, 345°=PMI)", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Torque T_res (N·m)")
    ax.set_xlim(0.0, 360.0)
    ax.grid(True, alpha=0.35)
    ax.legend(fontsize=7.8, loc="upper left")

    ax = axs[0, 1]
    ob = fly_res["ode_400rpm_bio"]
    labels = ["Direto 20 RPM\n(Linear, Cf=20%)", "Direto 20 RPM\n(Bio s^0.4, Cf=20%)", f"Volante 400 RPM\n(CAD Ø300, Cf={ob['cf_pct']:.1f}%)"]
    masses = [
        fly_res["direct_20rpm_D800_mass_kg"]["linear_Cf20"],
        fly_res["direct_20rpm_D800_mass_kg"]["bio_Cf20"],
        fly_res["flywheel_400rpm_cad"]["mass_volante_kg"],
    ]
    bars = ax.bar(labels, masses, color=["#6baed6", "#fc8d59", "#1b9e77"], edgecolor="k", width=0.52)
    for b, mv in zip(bars, masses):
        ax.text(b.get_x() + b.get_width() / 2, mv + 6.0, f"{mv:.1f} kg", ha="center", fontweight="bold", fontsize=9.5)
    ax.set_title("2. Massa de Volante: Eixo Lento 20 RPM (Ø800) vs. Eixo 400 RPM (Ø300)", fontweight="bold")
    ax.set_ylabel("Massa do Volante (kg)")
    ax.set_ylim(0, max(masses) * 1.18)
    ax.grid(True, axis="y", alpha=0.35)

    ax = axs[1, 0]
    ol = fly_res["ode_400rpm_lin"]
    od = fly_res["ode_direct20_bio"]
    oc = fly_res["ode_direct_compact"]
    ax.axhline(20.0, color="k", ls=":", lw=1.2)
    ax.plot(ob["t_3c"], ob["rpm_3c"], lw=2.3, color="#1b9e77", label=f"400 RPM Volante CAD (Bio s^0.4): Cf = {ob['cf_pct']:.2f}%")
    ax.plot(ol["t_3c"], ol["rpm_3c"], lw=2.0, color="#2166ac", ls="--", label=f"400 RPM Volante CAD (Linear): Cf = {ol['cf_pct']:.2f}%")
    ax.plot(od["t_3c"], od["rpm_3c"], lw=1.8, color="#d95f02", ls="-.", label=f"20 RPM Direto 265 kg (Bio): Cf = {od['cf_pct']:.2f}%")
    ax.plot(oc["t_3c"], oc["rpm_3c"], lw=2.0, color="#e7298a", ls=":", label="20 RPM Direto 1,65 kg·m²: Travamento (0 RPM!)")
    ax.set_title("3. Simulação Temporal Não-Linear (RK45): Flutuação de Rotação n2(t)", fontweight="bold")
    ax.set_xlabel("Tempo t (s) — 3 Ciclos Completos (T = 3,00 s)")
    ax.set_ylabel("Rotação em O2 (RPM)")
    ax.set_xlim(0.0, 9.0)
    ax.set_ylim(-0.5, 25.0)
    ax.grid(True, alpha=0.35)
    ax.legend(fontsize=7.8, loc="lower right")

    ax = axs[1, 1]
    idx_s = np.argsort(ob["th_1c_rad"])
    ax.axvspan(258.0, 345.0, color="#fde8e2", alpha=0.8)
    ax.axhline(20.0, color="k", ls=":", lw=1.2)
    ax.plot(np.degrees(ob["th_1c_rad"][idx_s]), ob["w_1c"][idx_s] * 60.0 / (2 * math.pi), lw=2.3, color="#1b9e77", label=f"400 RPM CAD (Bio): [{ob['rpm_min']:.2f}, {ob['rpm_max']:.2f}] RPM")
    idx_sd = np.argsort(od["th_1c_rad"])
    ax.plot(np.degrees(od["th_1c_rad"][idx_sd]), od["w_1c"][idx_sd] * 60.0 / (2 * math.pi), lw=1.9, color="#d95f02", ls="-.", label=f"20 RPM Direto 265 kg: [{od['rpm_min']:.2f}, {od['rpm_max']:.2f}] RPM")
    ax.set_title("4. Retrato de Fase Estacionário n2(θ2) em 1 Ciclo (360°)", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Rotação Instantânea n2 (RPM)")
    ax.set_xlim(0.0, 360.0)
    ax.set_ylim(17.0, 23.0)
    ax.grid(True, alpha=0.35)
    ax.legend(fontsize=8.2, loc="lower left")

    fig1.tight_layout(rect=[0, 0, 1, 0.95])
    save_fig(fig1, "motorizada_volante_torque_ode.png")

    # --- FIGURA 2: D'Alembert 360° (20 RPM Constante vs Flutuação EDO + VW) ---
    fig2, axs2 = plt.subplots(2, 2, figsize=(13.6, 8.8))
    fig2.suptitle(
        "Dinâmica de d'Alembert em 360° a 20 RPM — Massas e Inércias Exatas do FreeCAD (prensa_baru_motorizada_v1)",
        fontsize=12.0, fontweight="bold", y=0.98
    )
    th = sim_const["th2_deg"]
    oc = sim_const["out"]
    oo = sim_ode["out"]

    ax = axs2[0, 0]
    ax.plot(th, oc["Fin6_mag"], lw=2.2, color="#7570b3", label="Corpo 6 (Pistão+Navalha)")
    ax.plot(th, oc["Fin2_mag"], lw=2.2, color="#d95f02", label="Corpo 2 (Eixo O2+L2+Came)")
    ax.plot(th, oc["Fin5_mag"], lw=2.0, color="#e7298a", label="Corpo 5 (Garfo L5+Pino B)")
    ax.plot(th, oc["Fin4_mag"], lw=1.8, color="#1b9e77", label="Corpo 4 (Balancim L4)")
    ax.plot(th, oc["Fin3_mag"], lw=1.8, color="#377eb8", ls="--", label="Corpo 3 (Biela L3)")
    ax.set_title("1. Módulo das Forças Inerciais |F_in,i| = m_i·|a_Gi| (N)", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Força Inercial (N)")
    ax.set_xlim(0, 360); ax.grid(True, alpha=0.35); ax.legend(fontsize=7.8)

    ax = axs2[0, 1]
    ax.plot(th, oc["Tin4"] * 1e3, lw=2.1, color="#1b9e77", label="T_in,4 (Balancim L4)")
    ax.plot(th, oc["Tin5"] * 1e3, lw=2.0, color="#e7298a", ls="--", label="T_in,5 (Garfo L5)")
    ax.plot(th, oc["Tin3"] * 1e3, lw=1.8, color="#377eb8", label="T_in,3 (Biela L3)")
    ax.plot(th, oo["Tin2"] * 1e3, lw=2.0, color="#d95f02", label="T_in,2 c/ EDO α2(t) (Corpo 2)")
    ax.axhline(0.0, color="k", lw=0.8)
    ax.set_title("2. Torques Inerciais Baricêntricos T_in,i = -I_yy,Gi·α_i (mN·m)", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Torque Inercial (mN·m)")
    ax.set_xlim(0, 360); ax.grid(True, alpha=0.35); ax.legend(fontsize=7.8)

    ax = axs2[1, 0]
    ax.plot(th, oc["R_O2_in"], lw=2.1, color="#d95f02", label="Mancal O2")
    ax.plot(th, oc["R_A_in"], lw=2.0, color="#377eb8", label="Pino A")
    ax.plot(th, oc["R_O4_in"], lw=1.9, color="#1b9e77", label="Mancal O4")
    ax.plot(th, oc["R_O5_in"], lw=1.9, color="#7570b3", label="Pino Pistão O5")
    ax.plot(th, oc["R_N16_in"], lw=1.7, color="#555555", ls=":", label="Normal Guia N16")
    ax.set_title("3. Reações Inerciais Puras nas Juntas a 20 RPM (F_corte=0, g=0)", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Força Inercial (N)")
    ax.set_xlim(0, 360); ax.grid(True, alpha=0.35); ax.legend(fontsize=7.8)

    ax = axs2[1, 1]
    ax.plot(th, oc["T12_in"] * 1e3, lw=2.3, color="#b2182b", label=f"ω2=const (NE 15×15, erro VW={sim_const['vw_max_err_Nm']:.1e} N·m)")
    ax.plot(th, oc["T12_vw"] * 1e3, lw=0.0, marker="o", ms=2.8, markevery=36, color="#2166ac", label="Trabalhos Virtuais (ω2=const)")
    ax.plot(th, oo["T12_in"] * 1e3, lw=2.0, color="#1b9e77", ls="--", label=f"c/ Ripple EDO α2(t) (erro VW={sim_ode['vw_max_err_Nm']:.1e} N·m)")
    ax.axhline(0.0, color="k", lw=0.8)
    ax.set_title("4. Torque Inercial Equivalente T_12,in no Eixo O2 (mN·m)", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Torque Inercial em O2 (mN·m)")
    ax.set_xlim(0, 360); ax.grid(True, alpha=0.35); ax.legend(fontsize=7.6)

    fig2.tight_layout(rect=[0, 0, 1, 0.95])
    save_fig(fig2, "motorizada_dalembert_forcas_inerciais.png")

    # --- FIGURA 3: Sincronismo do Came Extrator vs Altura da Navalha e Contato Normal ---
    fig3, axs3 = plt.subplots(2, 2, figsize=(13.6, 8.6))
    fig3.suptitle(
        "Extrator Automático Sincronizado por Came 3-4-5 em O2 (20 RPM — Substituição do Pedal Humano)",
        fontsize=12.0, fontweight="bold", y=0.98
    )
    te = sim_ext["th2_deg"]
    oe = sim_ext["out"]

    ax = axs3[0, 0]
    ax.axvspan(60.0, 106.0, color="#e6f5c9", alpha=0.8, label="Subida Ejeção [60°..106°]")
    ax.axvspan(106.0, 150.0, color="#fff2ae", alpha=0.7, label="Retorno [106°..150°]")
    ax.axvspan(258.0, 345.0, color="#fde8e2", alpha=0.7, label="Corte [258°..345°]")
    l1, = ax.plot(te, oe["z_tip_mm"], lw=2.3, color="#2166ac", label="Altura Ponta Navalha Z_tip (mm)")
    ax.axhline(1042.25, color="#b2182b", ls=":", lw=1.4, label="Topo Baru 30x50x40 (1042,25 mm)")
    ax_r = ax.twinx()
    l2, = ax_r.plot(te, oe["psi_deg"], lw=2.3, color="#d95f02", ls="-.", label="Ângulo Pá Ejetora ψ (°)")
    ax.set_title("1. Sincronismo: Pá Ejetora Só Sobe com Navalha Alta!", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Z_tip (mm)", color="#2166ac")
    ax_r.set_ylabel("Ângulo Ejetor ψ (°)", color="#d95f02")
    ax.set_xlim(0, 360); ax.grid(True, alpha=0.35)
    ax.legend([l1, l2], [l1.get_label(), l2.get_label()], fontsize=7.8, loc="upper right")

    ax = axs3[0, 1]
    ax.plot(te, oe["cam_lift_mm"], lw=2.3, color="#1b9e77", label="Elevação Radial s(θ2) (mm)")
    ax2r = ax.twinx()
    ax2r.plot(te, oe["alpha_p_deg"], lw=2.0, color="#7570b3", ls="--", label="Ângulo de Pressão α_p (°)")
    ax.set_title(f"2. Geometria do Came (s_máx={np.max(oe['cam_lift_mm']):.2f} mm, α_p,máx={np.max(oe['alpha_p_deg']):.1f}°)", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Elevação s (mm)", color="#1b9e77")
    ax2r.set_ylabel("Ângulo de Pressão α_p (°)", color="#7570b3")
    ax.set_xlim(45, 165); ax.grid(True, alpha=0.35)

    ax = axs3[1, 0]
    ax.plot(te, oe["Fins_mag"] * 1e3, lw=2.2, color="#d95f02", label="Alavanca Seguidora (mN)")
    ax.plot(te, oe["Fint_mag"] * 1e3, lw=2.0, color="#377eb8", label="Tirante Extração (mN)")
    ax.plot(te, oe["Fine_mag"] * 1e3, lw=2.0, color="#1b9e77", label="Alavanca Ejetora (mN)")
    ax.set_title(f"3. Forças Inerciais d'Alembert (9×9) — Erro VW = {sim_ext['vw_max_err_Nm']:.2e} N·m", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Força Inercial (mN)")
    ax.set_xlim(45, 165); ax.grid(True, alpha=0.35); ax.legend(fontsize=8.0)

    ax = axs3[1, 1]
    ax.plot(te, oe["F_cam_contact_N"], lw=2.4, color="#b2182b", label="Força Normal Came-Rolete F_n (N)")
    ax.plot(te, oe["F_spring_N"], lw=1.9, color="#2166ac", ls="--", label="Força da Mola de Retorno (N)")
    ax.axhline(0.0, color="k", lw=1.0)
    ax.set_title(f"4. Contato Came-Rolete Positivo (F_n,mín = {np.min(oe['F_cam_contact_N']):.2f} N > 0 -> Zero Salto!)", fontweight="bold")
    ax.set_xlabel("Ângulo da Manivela θ2 (°)")
    ax.set_ylabel("Força (N)")
    ax.set_xlim(0, 360); ax.grid(True, alpha=0.35); ax.legend(fontsize=8.0)

    fig3.tight_layout(rect=[0, 0, 1, 0.95])
    save_fig(fig3, "motorizada_extrator_came_dinamica.png")


def build_summary_report(inertia_data, fly_res, sim_const, sim_ode, sim_ext) -> dict:
    import numpy as np

    oc = sim_const["out"]
    oo = sim_ode["out"]
    oe = sim_ext["out"]

    res = {
        "flywheel_comparison": {
            "torque_metrics": fly_res["metrics"],
            "direct_20rpm_D800_mass_kg": fly_res["direct_20rpm_D800_mass_kg"],
            "flywheel_400rpm_cad": fly_res["flywheel_400rpm_cad"],
            "ode_400rpm_bio": {
                "rpm_min": fly_res["ode_400rpm_bio"]["rpm_min"],
                "rpm_max": fly_res["ode_400rpm_bio"]["rpm_max"],
                "cf_pct": fly_res["ode_400rpm_bio"]["cf_pct"],
            },
            "ode_400rpm_lin": {
                "rpm_min": fly_res["ode_400rpm_lin"]["rpm_min"],
                "rpm_max": fly_res["ode_400rpm_lin"]["rpm_max"],
                "cf_pct": fly_res["ode_400rpm_lin"]["cf_pct"],
            },
            "ode_direct20_bio": {
                "rpm_min": fly_res["ode_direct20_bio"]["rpm_min"],
                "rpm_max": fly_res["ode_direct20_bio"]["rpm_max"],
                "cf_pct": fly_res["ode_direct20_bio"]["cf_pct"],
            },
            "ode_direct_compact_stall": {
                "rpm_min": fly_res["ode_direct_compact"]["rpm_min"],
                "rpm_max": fly_res["ode_direct_compact"]["rpm_max"],
                "cf_pct": fly_res["ode_direct_compact"]["cf_pct"],
            },
        },
        "dalembert_20rpm_const": {
            "vw_max_err_Nm": sim_const["vw_max_err_Nm"],
            "max_w_rad_s": {k: float(np.max(np.abs(oc[k]))) for k in ("w3", "w4", "w5")},
            "max_vO5_mm_s": float(np.max(np.abs(oc["vO5_z"])) * 1e3),
            "max_al_rad_s2": {k: float(np.max(np.abs(oc[k]))) for k in ("al3", "al4", "al5")},
            "max_aO5_m_s2": float(np.max(np.abs(oc["aO5_z"]))),
            "max_Fin_N": {f"Body{i}": float(np.max(oc[f"Fin{i}_mag"])) for i in (2, 3, 4, 5, 6)},
            "max_Tin_Nm": {f"Body{i}": float(np.max(np.abs(oc[f"Tin{i}"]))) for i in (2, 3, 4, 5)},
            "max_T12_in_Nm": float(np.max(np.abs(oc["T12_in"]))),
            "max_T12_grav_Nm": float(np.max(np.abs(oc["T12_grav"]))),
            "max_T12_cut_bio10_Nm": float(np.max(np.abs(oc["T12_cut_bio10"]))),
            "max_T12_cut_bio475_Nm": float(np.max(np.abs(oc["T12_cut_bio475"]))),
            "max_R_in_N": {j: float(np.max(oc[f"R_{j}_in"])) for j in ("O2", "A", "B3", "B4", "B5", "O4", "O5", "N16")},
            "max_R_cut_bio_N": {j: float(np.max(oc[f"R_{j}_cut_bio"])) for j in ("O2", "A", "B3", "B4", "B5", "O4", "O5", "N16")},
            "max_Ek_J": float(np.max(oc["Ek"])),
        },
        "dalembert_20rpm_ode_ripple": {
            "vw_max_err_Nm": sim_ode["vw_max_err_Nm"],
            "max_alpha2_rad_s2": float(np.max(np.abs(sim_ode["al2"]))),
            "max_Fin_N": {f"Body{i}": float(np.max(oo[f"Fin{i}_mag"])) for i in (2, 3, 4, 5, 6)},
            "max_Tin2_Nm": float(np.max(np.abs(oo["Tin2"]))),
            "max_T12_in_Nm": float(np.max(np.abs(oo["T12_in"]))),
            "max_R_in_N": {j: float(np.max(oo[f"R_{j}_in"])) for j in ("O2", "A", "B3", "B4", "B5", "O4", "O5", "N16")},
        },
        "cam_extractor_20rpm": {
            "vw_max_err_Nm": sim_ext["vw_max_err_Nm"],
            "s_max_mm": float(np.max(oe["cam_lift_mm"])),
            "alpha_p_max_deg": float(np.max(oe["alpha_p_deg"])),
            "z_tip_at_60deg_mm": float(oe["z_tip_mm"][int(np.argmin(np.abs(sim_ext["th2_deg"] - 60.0)))]),
            "z_tip_at_83deg_mm": float(oe["z_tip_mm"][int(np.argmin(np.abs(sim_ext["th2_deg"] - 83.0)))]),
            "z_tip_at_106deg_mm": float(oe["z_tip_mm"][int(np.argmin(np.abs(sim_ext["th2_deg"] - 106.0)))]),
            "max_Fin_mN": {
                "Seguidora": float(np.max(oe["Fins_mag"]) * 1e3),
                "Tirante": float(np.max(oe["Fint_mag"]) * 1e3),
                "Ejetora": float(np.max(oe["Fine_mag"]) * 1e3),
            },
            "max_T_seg_in_Nm": float(np.max(np.abs(oe["T_seg_in"]))),
            "min_F_cam_contact_N": float(np.min(oe["F_cam_contact_N"])),
            "max_F_cam_contact_N": float(np.max(oe["F_cam_contact_N"])),
            "max_Ek_J": float(np.max(oe["Ek"])),
        },
    }
    with open(JSON_RESULTS_PATH, "w", encoding="utf-8") as f:
        json.dump(res, f, indent=2, ensure_ascii=False)
    return res


def main():
    if "--extract" in sys.argv or os.environ.get("FREECAD_EXTRACT") == "1":
        extract_from_freecad()
        return

    if "--refresh-cad" in sys.argv or not os.path.exists(JSON_INERTIA_PATH):
        extract_from_freecad()

    with open(JSON_INERTIA_PATH, "r", encoding="utf-8") as f:
        inertia_data = json.load(f)

    fly_res = run_flywheel_ode_and_comparison(inertia_data)
    sim_const = run_main_mechanism_dalembert_360(inertia_data, ode_res=None, N=1441)
    sim_ode = run_main_mechanism_dalembert_360(inertia_data, ode_res=fly_res["ode_400rpm_bio"], N=1441)
    sim_ext = run_cam_extractor_dalembert(inertia_data, N=1441)

    generate_plots(fly_res, sim_const, sim_ode, sim_ext)
    summary = build_summary_report(inertia_data, fly_res, sim_const, sim_ode, sim_ext)

    # Espelha JSONs e script no Vault
    os.makedirs(VAULT_DIR, exist_ok=True)
    for fn in (
        "calcular_inercia_e_dalembert_motorizada.py",
        "propriedades_inerciais_freecad_motorizada_v1.json",
        "resultados_dalembert_motorizada_v1.json",
    ):
        src = os.path.join(SCRIPT_DIR, fn)
        dst = os.path.join(VAULT_DIR, fn)
        if os.path.exists(src) and os.path.abspath(src) != os.path.abspath(dst):
            shutil.copy2(src, dst)

    print("=" * 96)
    print("SOLVER MOTORIZADO 20 RPM CONCLUÍDO COM SUCESSO (prensa_baru_motorizada_v1)")
    print("=" * 96)
    tot = inertia_data["totals"]
    print(f"• Massa total máquina: {tot['total_machine_mass_kg']:.4f} kg | Móvel principal: {tot['moving_main_mass_kg']:.4f} kg | Trem potência: {tot['drivetrain_mass_kg']:.4f} kg")
    print(f"• CG Global (X,Y,Z): {[round(v, 2) for v in tot['machine_global_cg_mm']]} mm")
    fc = summary["flywheel_comparison"]
    print(f"• Volante 400 RPM CAD: m={fc['flywheel_400rpm_cad']['mass_volante_kg']:.2f} kg, I_vol={fc['flywheel_400rpm_cad']['I_volante_kg_m2']:.5f} kg.m², I_eq_O2={fc['flywheel_400rpm_cad']['I_eq_O2_total_kg_m2']:.2f} kg.m²")
    print(f"• ODE RK45 Cf% (400 RPM Volante CAD): Bio s^0.4 = {fc['ode_400rpm_bio']['cf_pct']:.2f}% [{fc['ode_400rpm_bio']['rpm_min']:.2f}..{fc['ode_400rpm_bio']['rpm_max']:.2f} rpm] | Lin = {fc['ode_400rpm_lin']['cf_pct']:.2f}%")
    dc = summary["dalembert_20rpm_const"]
    do = summary["dalembert_20rpm_ode_ripple"]
    ce = summary["cam_extractor_20rpm"]
    print(f"• Erro VW (15x15 const): {dc['vw_max_err_Nm']:.2e} N.m | (15x15 ODE): {do['vw_max_err_Nm']:.2e} N.m | (9x9 Extrator): {ce['vw_max_err_Nm']:.2e} N.m")
    print(f"• Máx Fin (const, N): { {k: round(v, 4) for k, v in dc['max_Fin_N'].items()} } | T12_in_max = {dc['max_T12_in_Nm']:.5f} N.m")
    print(f"• Máx Fin (c/ ODE α2, N): { {k: round(v, 4) for k, v in do['max_Fin_N'].items()} } | T12_in_max = {do['max_T12_in_Nm']:.5f} N.m")
    print(f"• Came Extrator: s_max={ce['s_max_mm']:.2f} mm, alpha_p_max={ce['alpha_p_max_deg']:.2f}°, F_contato=[{ce['min_F_cam_contact_N']:.2f}, {ce['max_F_cam_contact_N']:.2f}] N (>0 OK!)")


if __name__ == "__main__":
    main()
