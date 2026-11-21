#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=========================================================================================
TRABALHO FINAL 1 — DINÂMICA DAS MÁQUINAS (EMC/UFG — 2026/2)
Docente: Prof. Dr. Sigeo Kitatani Jr. | Discente: Guilherme Paiva Crispim Abalém
Diretriz: Ciência Aberta (UNESCO, 2023) — Modelagem CAD 3D Paramétrica e Reprodutível

Script Construtor Determinístico — Prensa Articulada Knuckle-Joint Motorizada (Vertente B):
`prensa_baru_motorizada_v1` (20 RPM Contínuo, Item 9 de `instruções.pdf`)

Evolução direta sobre a prensa manual de piso `prensa_baru_manual_v1` (sem alterá-la):
  1. Núcleo de saída knuckle-joint e mesa de quebra invariantes:
     Z_WORK_DATUM = 980,0 mm, O4 = (0,00; 1447,50) mm, L4 = L5 = 111,9615 mm, h = 30,00 mm
     (Z_tip: 1067,50 mm PMS -> 1037,50 mm PMI), Cantoneira V 90° c/ Baru 30x50x40 (corte 4,75 mm).
  2. Acionamento contínuo 360° Classe-I Grashof Manivela-Balancim (K = 1,5):
     O2 = (-83,9711; 1358,0385) mm, L2 = 28,9778 mm, L3 = 57,9555 mm.
     Remoção dos batentes manuais (PMS/PMI) e realocação do espaçador superior esquerdo
     para giro livre 360° com 0,000000 mm³ de interferência.
  3. Trem de potência comercial 20 RPM c/ Volante em Alta Rotação (400 RPM):
     - Motor WEG W22 IR3 0,5 cv (0,37 kW) 4P 1730 rpm Carcaça IEC 71 em base tensora traseira;
     - Estágio 1 Correia em V Perfil A: Polia motora Ø75 mm -> Polia movida Ø325 mm (i1 = 4,333:1);
     - Eixo intermediário a 399,2 rpm (~400 rpm) em 2x mancais UCP204;
     - Volante de Inércia em Aço ABNT 1020 (Ø300/Ø220 x 40 mm, ~14,2 kg) a 400 rpm;
     - Estágio 2 Redutor Helicoidal Comercial 20:1 (eta2 = 0,95) coaxial ao eixo principal O2 (20 rpm)
       com 2x mancais de flange UCF204/F204 no pórtico (inércia refletida I_eq,O2 = 380 * I_vol).
  4. Extrator Automático Sincronizado por Came (substitui o pedal humano):
     - Came de disco 3-4-5 (R_base = 52 mm, R_rolo = 9,5 mm) montado em O2 (Y in [-80, -70] mm);
     - Dwell [145°, 360°] U [0°, 50°] (0°), Rise [50°, 100°] (0°->22°, faca alta Z_tip >= 1043..1059 mm),
       Return [100°, 145°] (22°->0°, antes do PMS 165° para livre alimentação da moega/calha);
     - Alavanca seguidora com rolete comercial + tirante furos redondos + alavanca ejetora + mola.
  5. Gabinete e Cavalete NR-12 ampliados (Metalon 20x20x1,50 + Chapa #18 c/ aletas de ventilação),
     mantendo moega lateral esquerda, visor frontal policarbonato e coletor frontal 12,3 L livres.
=========================================================================================
"""

import sys
import os
import math
import shutil

if "/usr/lib/freecad/lib" not in sys.path and os.path.isdir("/usr/lib/freecad/lib"):
    sys.path.append("/usr/lib/freecad/lib")

import FreeCAD as App
import Part

# =========================================================================================
# 1. CONSTANTES CINEMÁTICAS E DATUMS DE PISO (MOTORIZADA K = 1.5 @ 20 RPM)
# =========================================================================================
DOC_NAME = "prensa_baru_motorizada_v1"

Z_WORK_DATUM = 980.0000

O4_X = 0.0000
O4_Z = Z_WORK_DATUM + 467.5000  # 1447.5000 mm

H_CURSO = 30.0000
DTH4_RAD = math.radians(30.0)
L4 = H_CURSO / (2.0 * (1.0 - math.cos(DTH4_RAD)))  # 111.96152422706632 mm
L5 = L4

# Síntese Grashof Classe-I K = 1.5 (colinear B1-B2)
_B1_X = -L4 * math.sin(DTH4_RAD)                    # -55.980762 mm
_B1_Z = O4_Z - L4 * math.cos(DTH4_RAD)              # 1350.538476 mm
_B2_X = 0.0000
_B2_Z = O4_Z - L4                                   # 1335.538476 mm
_MX = _B1_X - _B2_X
_MZ = _B1_Z - _B2_Z
_M_NORM = math.hypot(_MX, _MZ)                      # 57.955549577344115 mm

O2_X = _B2_X + 1.5 * _MX                            # -83.97114317029977 mm
O2_Z = _B2_Z + 1.5 * _MZ                            # 1358.0384757729337 mm
L2 = 0.5 * _M_NORM                                  # 28.977774788672058 mm
L3 = _M_NORM                                        # 57.955549577344115 mm

TH2_PMS_DEG = 165.0                                 # PMS: Z_tip = 1067.50 mm
TH2_MID_DEG = 255.0                                 # Descida livre antes do corte
TH2_PMI_DEG = 345.0                                 # PMI: Z_tip = 1037.50 mm

O5_Z_PMS = O4_Z - 2.0 * L4 * math.cos(DTH4_RAD)     # 1253.576952 mm
O5_Z_PMI = O4_Z - 2.0 * L4                          # 1223.576952 mm
Z_TIP_PMI = Z_WORK_DATUM + 57.5000                  # 1037.5000 mm
Z_TIP_PMS = Z_WORK_DATUM + 87.5000                  # 1067.5000 mm
H_O5_TO_TIP = O5_Z_PMI - Z_TIP_PMI                  # 186.076952 mm

# Datums estruturais do cavalete de piso (~1,50 m) e mesa de trabalho
Z_FLOOR = 0.00
Z_FOOT_TOP = 4.76                                   # Sapatas Chapa 3/16" (Z in [0.00, 4.76] mm)
Z_BASE_BOT = Z_WORK_DATUM + 2.00                    # 982.00 mm
Z_BASE_TOP = Z_WORK_DATUM + 8.35                    # 988.35 mm (Chapa 1/4" = 6.35 mm)
Z_STRUCT_BOT = Z_WORK_DATUM + 8.37                  # 988.37 mm

# Suporte do Baru em Cantoneira comercial 1.1/2" x 3/16" a 45° (V 90°)
Z_CANTONEIRA_V = Z_WORK_DATUM + 17.25               # 997.25 mm

# Corpo de prova: Baru elipsoidal 50.0 (X) x 30.0 (Y) x 40.0 (Z) mm na Cantoneira 90°
BARU_LEN_X = 50.00
BARU_WID_Y = 30.00
BARU_DEP_Z = 40.00
_M_V90 = 1.0000
_DZ_TANG_90 = math.hypot(0.5 * BARU_WID_Y * _M_V90, 0.5 * BARU_DEP_Z)  # 25.0000 mm
Z_BARU_CENTER = Z_CANTONEIRA_V + _DZ_TANG_90        # 1022.2500 mm
Z_BARU_BOT = Z_BARU_CENTER - 0.5 * BARU_DEP_Z       # 1002.2500 mm
Z_BARU_TOP = Z_BARU_CENTER + 0.5 * BARU_DEP_Z       # 1042.2500 mm -> corte PMI = 4.7500 mm <= 5.00 mm!

# Camadas Y do mecanismo e trem de potência (desacopladas para 0.000000 mm³ colisão)
Y_PORTAL_F_MIN, Y_PORTAL_F_MAX = -43.00, -36.65
Y_L3_MIN, Y_L3_MAX = -33.50, -27.15
Y_L2_MIN, Y_L2_MAX = -24.50, -18.15
Y_PORTAL_R_MIN, Y_PORTAL_R_MAX = 24.00, 30.35
Y_CAM_MIN, Y_CAM_MAX = 59.00, 69.00
Y_CAM_MID = 64.00

# Extrator Automático Sincronizado por Came (substitui pedal humano!)
O_EXT_X = 34.00
O_EXT_Z = Z_WORK_DATUM + 16.00                      # 996.00 mm
EXT_CRANK_DX = 38.00                                # Braço adaptado ao came (P_top0 = (72.0, 1014.0))
EXT_CRANK_DZ = 18.00
EXT_R_CRANK = math.hypot(EXT_CRANK_DX, EXT_CRANK_DZ)  # 42.047592 mm
EXT_PHI0_RAD = math.atan2(EXT_CRANK_DZ, EXT_CRANK_DX)
EXT_ANG_MAX_DEG = 22.0

O_SEG_X = -28.00                                    # Pivô da alavanca seguidora em beam_O4
O_SEG_Z = O4_Z                                      # 1447.50 mm
CAM_R_BASE = 52.00
CAM_R_ROLLER = 9.50                                 # Rolamento seguidor comercial Ø19 mm
CAM_R_PRIME = CAM_R_BASE + CAM_R_ROLLER             # 61.50 mm
CAM_PHI_R0_RAD = math.radians(107.0)                # Ângulo nominal do rolete em repouso
_C0_X = O2_X + CAM_R_PRIME * math.cos(CAM_PHI_R0_RAD)
_C0_Z = O2_Z + CAM_R_PRIME * math.sin(CAM_PHI_R0_RAD)
SEG_R_ARM1 = math.hypot(_C0_X - O_SEG_X, _C0_Z - O_SEG_Z)
SEG_TH_ARM1_0_RAD = math.atan2(_C0_Z - O_SEG_Z, _C0_X - O_SEG_X)
SEG_Q0_X = 92.00                                    # Braço horizontal direito até X = +92 mm
SEG_Q0_Z = O_SEG_Z
SEG_R_ARM2 = math.hypot(SEG_Q0_X - O_SEG_X, SEG_Q0_Z - O_SEG_Z)  # 120.00 mm
TIR_LEN = math.hypot((O_EXT_X + EXT_CRANK_DX) - SEG_Q0_X,
                     (O_EXT_Z + EXT_CRANK_DZ) - SEG_Q0_Z)        # 433.960828 mm

CAM_RISE_START_DEG = 60.0
CAM_RISE_END_DEG = 106.0
CAM_RET_END_DEG = 150.0

# Trem de Potência 20 RPM (Motor WEG 0,5 cv 4P -> Polia Ø75/Ø325 -> Eixo 400 RPM + Volante -> Redutor 20:1)
O_INT_X = 56.00
O_INT_Z = 1278.00                                   # Centro eixo intermediário 400 rpm (P204 = 33.3 mm)
Z_INT_SHELF_TOP = O_INT_Z - 33.30                   # 1244.70 mm (base exata dos mancais UCP204)
O_MOT_X = 56.00
O_MOT_Z = 896.00                                    # Centro eixo motor WEG IEC 71 (H = 71 mm)
Z_MOT_SHELF_TOP = O_MOT_Z - 71.00                   # 825.00 mm (base tensora motor)
Y_BELT_CENTER = 368.00                              # Plano médio da correia V perfil A e polias

VOL_R_EXT = 150.00                                  # Ø300 mm
VOL_R_INT = 110.00                                  # Ø220 mm
VOL_B_ARO = 40.00                                   # Largura axial aro = 40 mm
VOL_Y_MIN = 232.00
VOL_Y_MAX = VOL_Y_MIN + VOL_B_ARO                   # 272.00 mm

# Gabinete NR-12 e Cavalete Ampliados
CAB_X_MIN, CAB_X_MAX = -170.00, 260.00              # Largura externa gabinete superior: 430 mm
CAB_Y_FRONT = -64.00                                # Face frontal livre do portico (-43.0) e sapata cantoneira (-32.5)
CAB_Y_REAR = 435.00                                 # Face traseira alinhada c/ colunas do cavalete (Y[415..435])
CAB_Z_TOP = Z_WORK_DATUM + 517.50                   # 1497.50 mm


# =========================================================================================
# 2. CINEMÁTICA ANALÍTICA EXATA (MECANISMO PRINCIPAL 360° + CAME EXTRATOR)
# =========================================================================================
def _poly345(u: float) -> float:
    return 10.0 * u**3 - 15.0 * u**4 + 6.0 * u**5


def cam_ejector_angle_deg(theta2_deg: float) -> float:
    th = theta2_deg % 360.0
    if CAM_RISE_START_DEG <= th <= CAM_RISE_END_DEG:
        u = (th - CAM_RISE_START_DEG) / (CAM_RISE_END_DEG - CAM_RISE_START_DEG)
        return EXT_ANG_MAX_DEG * _poly345(u)
    if CAM_RISE_END_DEG < th <= CAM_RET_END_DEG:
        u = (th - CAM_RISE_END_DEG) / (CAM_RET_END_DEG - CAM_RISE_END_DEG)
        return EXT_ANG_MAX_DEG * (1.0 - _poly345(u))
    return 0.0


def solve_cam_follower_kinematics(theta2_deg: float) -> dict:
    psi_deg = cam_ejector_angle_deg(theta2_deg)
    psi = math.radians(psi_deg)
    ang_e = EXT_PHI0_RAD - psi
    px = O_EXT_X + EXT_R_CRANK * math.cos(ang_e)
    pz = O_EXT_Z + EXT_R_CRANK * math.sin(ang_e)

    dx, dz = px - O_SEG_X, pz - O_SEG_Z
    d = math.hypot(dx, dz)
    ac = (SEG_R_ARM2**2 - TIR_LEN**2 + d**2) / (2.0 * d)
    hc = math.sqrt(max(0.0, SEG_R_ARM2**2 - ac**2))
    x2, z2 = O_SEG_X + ac * dx / d, O_SEG_Z + ac * dz / d
    bp_x, bp_z = x2 + hc * (-dz) / d, z2 + hc * dx / d
    bm_x, bm_z = x2 - hc * (-dz) / d, z2 - hc * dx / d
    qx, qz = (bp_x, bp_z) if bp_z >= bm_z else (bm_x, bm_z)

    gamma_rad = -math.atan2(qz - O_SEG_Z, qx - O_SEG_X)
    th_arm1 = SEG_TH_ARM1_0_RAD - gamma_rad
    cx = O_SEG_X + SEG_R_ARM1 * math.cos(th_arm1)
    cz = O_SEG_Z + SEG_R_ARM1 * math.sin(th_arm1)
    ang_tir_deg = math.degrees(math.atan2(qx - px, qz - pz))

    return {
        "psi_deg": psi_deg,
        "gamma_deg": math.degrees(gamma_rad),
        "P_top": (px, pz),
        "Q_seg": (qx, qz),
        "C_rol": (cx, cz),
        "ang_tir_deg": ang_tir_deg,
    }


def solve_kinematics(theta2_deg: float) -> dict:
    """Resolve a cinemática analítica exata do mecanismo 360° e do extrator por came."""
    th2 = math.radians(theta2_deg)
    ax = O2_X + L2 * math.cos(th2)
    az = O2_Z + L2 * math.sin(th2)

    dx = ax - O4_X
    dz = az - O4_Z
    da = math.hypot(dx, dz)
    ac = (L4**2 - L3**2 + da**2) / (2.0 * da)
    hc = math.sqrt(max(0.0, L4**2 - ac**2))

    x2 = O4_X + ac * dx / da
    z2 = O4_Z + ac * dz / da
    # Ramo direito/inferior (bx >= bm_x) garantido contínuo em todo 0..360°
    bp_x = x2 + hc * (-dz) / da
    bp_z = z2 + hc * (dx) / da
    bm_x = x2 - hc * (-dz) / da
    bm_z = z2 - hc * (dx) / da
    bx, bz = (bp_x, bp_z) if bp_x >= bm_x else (bm_x, bm_z)

    th3 = math.atan2(bz - az, bx - ax)
    th4 = math.atan2(bz - O4_Z, bx - O4_X)
    o5_x = 0.0
    o5_z = bz - math.sqrt(max(0.0, L5**2 - bx**2))
    th5 = math.atan2(o5_z - bz, o5_x - bx)

    da_mu = abs(th4 - th3) % (2.0 * math.pi)
    if da_mu > math.pi:
        da_mu = 2.0 * math.pi - da_mu

    cam_k = solve_cam_follower_kinematics(theta2_deg)
    return {
        "theta2_deg": theta2_deg % 360.0,
        "A": (ax, az),
        "B": (bx, bz),
        "O5": (o5_x, o5_z),
        "theta3_deg": math.degrees(th3),
        "theta4_deg": math.degrees(th4),
        "theta5_deg": math.degrees(th5),
        "mu_deg": math.degrees(da_mu),
        "z_tip": o5_z - H_O5_TO_TIP,
        "cam_extractor": cam_k,
    }


# =========================================================================================
# 3. PRIMITIVAS GEOMÉTRICAS DE SERRALHERIA E COMPONENTES COMERCIAIS
# =========================================================================================
def make_rounded_bar_xz(length: float, width: float, y_min: float, y_max: float,
                        d_hole1: float = 0.0, d_hole2: float = 0.0) -> Part.Shape:
    r = 0.5 * width
    dy = y_max - y_min
    cyl1 = Part.makeCylinder(r, dy, App.Vector(0.0, y_min, 0.0), App.Vector(0.0, 1.0, 0.0))
    cyl2 = Part.makeCylinder(r, dy, App.Vector(length, y_min, 0.0), App.Vector(0.0, 1.0, 0.0))
    bar = Part.makeBox(length, dy, width, App.Vector(0.0, y_min, -r)).fuse([cyl1, cyl2]).removeSplitter() if length > 1e-4 else cyl1

    cuts = []
    if d_hole1 > 0.0:
        cuts.append(Part.makeCylinder(0.5 * d_hole1, dy + 2.0,
                                      App.Vector(0.0, y_min - 1.0, 0.0), App.Vector(0.0, 1.0, 0.0)))
    if d_hole2 > 0.0:
        cuts.append(Part.makeCylinder(0.5 * d_hole2, dy + 2.0,
                                      App.Vector(length, y_min - 1.0, 0.0), App.Vector(0.0, 1.0, 0.0)))
    return bar.cut(cuts).removeSplitter() if cuts else bar


def make_bushing_y(x: float, z: float, d_in: float, d_out: float, y_min: float, y_max: float) -> Part.Shape:
    dy = y_max - y_min
    outer = Part.makeCylinder(0.5 * d_out, dy, App.Vector(x, y_min, z), App.Vector(0.0, 1.0, 0.0))
    inner = Part.makeCylinder(0.5 * d_in, dy + 1.0, App.Vector(x, y_min - 0.5, z), App.Vector(0.0, 1.0, 0.0))
    return outer.cut(inner).removeSplitter()


def make_oring_pin_y(x: float, z: float, d_pin: float, y_min: float, y_max: float,
                     groove_ys: tuple[float, float]) -> tuple[Part.Shape, Part.Shape]:
    dy = y_max - y_min
    pin = Part.makeCylinder(0.5 * d_pin, dy, App.Vector(x, y_min, z), App.Vector(0, 1, 0))
    d_groove = 10.36
    w_groove = 2.10
    ring_cuts, orings = [], []
    for yg in groove_ys:
        outer_g = Part.makeCylinder(0.5 * d_pin + 1.0, w_groove, App.Vector(x, yg - 0.5 * w_groove, z), App.Vector(0, 1, 0))
        core_g = Part.makeCylinder(0.5 * d_groove, w_groove + 0.2, App.Vector(x, yg - 0.5 * w_groove - 0.1, z), App.Vector(0, 1, 0))
        ring_cuts.append(outer_g.cut(core_g))
        orings.append(Part.makeTorus(6.12, 0.90, App.Vector(x, yg, z), App.Vector(0, 1, 0)))
    return pin.cut(ring_cuts).removeSplitter(), orings[0].fuse(orings[1:]).removeSplitter()


def make_hollow_metalon_box(x0: float, y0: float, z0: float,
                            dx: float, dy: float, dz: float,
                            axis: str, wall: float = 1.50) -> Part.Shape:
    outer = Part.makeBox(dx, dy, dz, App.Vector(x0, y0, z0))
    if axis == "Z":
        inner = Part.makeBox(dx - 2.0 * wall, dy - 2.0 * wall, dz + 2.0,
                             App.Vector(x0 + wall, y0 + wall, z0 - 1.0))
    elif axis == "X":
        inner = Part.makeBox(dx + 2.0, dy - 2.0 * wall, dz - 2.0 * wall,
                             App.Vector(x0 - 1.0, y0 + wall, z0 + wall))
    elif axis == "Y":
        inner = Part.makeBox(dx - 2.0 * wall, dy + 2.0, dz - 2.0 * wall,
                             App.Vector(x0 + wall, y0 - 1.0, z0 + wall))
    else:
        raise ValueError(f"Eixo inválido para Metalon: {axis}")
    return outer.cut(inner).removeSplitter()


# =========================================================================================
# 4. ESTATOR INTERNO, PÓRTICOS REFORMULADOS (GIRO 360°), GUIA U E NAVALHA
# =========================================================================================
def build_base_plate_with_drop_window() -> Part.Shape:
    """Chapa de Mesa Estrutural 1/4" (340 x 100 mm, Z[982.00, 988.35]) sem rasgo traseiro de pedal."""
    base = Part.makeBox(340.0, 100.0, Z_BASE_TOP - Z_BASE_BOT, App.Vector(-170.0, -46.50, Z_BASE_BOT))
    cuts = [
        Part.makeBox(76.0, 39.0, 12.0, App.Vector(30.0, -19.50, Z_BASE_BOT - 2.0)),
    ]
    for xs in (-16.0, 16.0):
        for ys in (-27.5, 27.5):
            cuts.append(Part.makeCylinder(3.15, 12.0, App.Vector(xs, ys, Z_BASE_BOT - 2.0), App.Vector(0, 0, 1)))
    for xk in (-158.0, 158.0):
        for yk in (-36.5, 43.5):
            cuts.append(Part.makeCylinder(4.10, 12.0, App.Vector(xk, yk, Z_BASE_BOT - 2.0), App.Vector(0, 0, 1)))
    return base.cut(cuts).removeSplitter()


def build_structural_portal(y_min: float, y_max: float, is_front: bool) -> Part.Shape:
    """
    Pórticos soldados em Barra Chata 2" x 1/4" adaptados ao K = 1.5 contínuo 360°:
      - Coluna esquerda alargada para X in [-132.0, -69.6] para abrigar O2 = -83.97 e flange F204;
      - Viga O2 centrada em O2_Z = 1358.04 mm (Z in [1332.64, 1383.44]);
      - SEM orelha de batente PMS/PMI; espaçador superior esquerdo movido para (-105.0, 1447.5)
        para folga absoluta do giro 360° da manivela L2 e biela L3!
    """
    dy = y_max - y_min
    z_bot = Z_STRUCT_BOT
    z_top = Z_WORK_DATUM + 492.90  # 1472.90 mm
    h_col = z_top - z_bot

    col_L = Part.makeBox(62.40, dy, h_col, App.Vector(-132.00, y_min, z_bot))
    col_R = Part.makeBox(50.80, dy, h_col, App.Vector(69.60, y_min, z_bot))
    beam_O4 = Part.makeBox(252.40, dy, 50.80, App.Vector(-132.00, y_min, O4_Z - 25.40))
    beam_O2 = Part.makeBox(62.40, dy, 50.80, App.Vector(-132.00, y_min, O2_Z - 25.40))
    beam_O2_R = Part.makeBox(50.80, dy, 50.80, App.Vector(69.60, y_min, O2_Z - 25.40))
    parts = [col_L, col_R, beam_O4, beam_O2, beam_O2_R]

    if not is_front:
        beam_G1 = Part.makeBox(252.40, dy, 46.00, App.Vector(-132.00, y_min, Z_WORK_DATUM + 127.50))
        beam_G2 = Part.makeBox(252.40, dy, 46.00, App.Vector(-132.00, y_min, Z_WORK_DATUM + 175.50))
        parts.extend([beam_G1, beam_G2])

    portal = parts[0].fuse(parts[1:]).removeSplitter()

    holes = [
        Part.makeCylinder(7.02, dy + 2.0, App.Vector(O4_X, y_min - 1.0, O4_Z), App.Vector(0, 1, 0)),
    ]
    if not is_front:
        holes.append(Part.makeCylinder(11.52, dy + 2.0, App.Vector(O2_X, y_min - 1.0, O2_Z), App.Vector(0, 1, 0)))
    # Espacadores transversais M10: esquerdo inferior (-105, 1212.5), esquerdo superior (-105, 1447.5), direitos (+95, 1212.5 e 1372.5)
    for xt, zt in ((-105.0, Z_WORK_DATUM + 232.5), (-105.0, O4_Z),
                   (95.0, Z_WORK_DATUM + 232.5), (95.0, Z_WORK_DATUM + 392.5)):
        holes.append(Part.makeCylinder(5.10, dy + 2.0, App.Vector(xt, y_min - 1.0, zt), App.Vector(0, 1, 0)))

    if not is_front:
        holes.append(Part.makeCylinder(4.10, dy + 2.0, App.Vector(O_SEG_X, y_min - 1.0, O_SEG_Z), App.Vector(0, 1, 0)))
        for zc in (Z_WORK_DATUM + 53.0, Z_WORK_DATUM + 77.0):
            holes.append(Part.makeCylinder(4.10, dy + 2.0, App.Vector(-105.0, y_min - 1.0, zc), App.Vector(0, 1, 0)))
        for xg in (-33.0, 33.0):
            for zg in (Z_WORK_DATUM + 150.50, Z_WORK_DATUM + 198.50):
                holes.append(Part.makeCylinder(4.20, dy + 2.0, App.Vector(xg, y_min - 1.0, zg), App.Vector(0, 1, 0)))

    return portal.cut(holes).removeSplitter()


def build_portal_spacers_motorized() -> Part.Shape:
    """4x Espaçadores transversais M10 realocados para giro livre 360° da manivela K = 1.5."""
    sp_parts = []
    y_in_f = Y_PORTAL_F_MAX + 0.02   # -36.63
    y_in_r = Y_PORTAL_R_MIN - 0.02   # 23.98
    y_out_f = Y_PORTAL_F_MIN - 0.02  # -43.02
    y_out_r = Y_PORTAL_R_MAX + 0.02  # 30.37
    dy_bolt = (y_out_r - y_out_f)
    for xt, zt in ((-105.0, Z_WORK_DATUM + 232.5), (-105.0, O4_Z),
                   (95.0, Z_WORK_DATUM + 232.5), (95.0, Z_WORK_DATUM + 392.5)):
        tube = make_bushing_y(xt, zt, 10.40, 22.00, y_in_f, y_in_r)
        bolt = Part.makeCylinder(4.95, dy_bolt, App.Vector(xt, y_out_f, zt), App.Vector(0, 1, 0))
        head = Part.makeCylinder(8.00, 4.00, App.Vector(xt, y_out_f - 4.00, zt), App.Vector(0, 1, 0))
        nut = Part.makeCylinder(8.00, 5.00, App.Vector(xt, y_out_r, zt), App.Vector(0, 1, 0))
        sp_parts.extend([tube, bolt, head, nut])
    return sp_parts[0].fuse(sp_parts[1:]).removeSplitter()


def build_cantoneira_baru_support() -> Part.Shape:
    zv = Z_CANTONEIRA_V
    inv_sqrt2 = 1.0 / math.sqrt(2.0)
    l_leg = 38.10
    t_leg = 4.7625
    y_in_top = (l_leg - t_leg) * inv_sqrt2
    z_in_top = zv + y_in_top
    z_out_bot = zv - t_leg * math.sqrt(2.0)
    y_out_top = l_leg * inv_sqrt2
    z_out_top = z_out_bot + y_out_top

    pts_v_yz = [
        App.Vector(-26.0, 0.0, z_out_bot),
        App.Vector(-26.0, y_out_top, z_out_top),
        App.Vector(-26.0, y_in_top, z_in_top),
        App.Vector(-26.0, 0.0, zv),
        App.Vector(-26.0, -y_in_top, z_in_top),
        App.Vector(-26.0, -y_out_top, z_out_top),
        App.Vector(-26.0, 0.0, z_out_bot),
    ]
    cantoneira = Part.Face(Part.makePolygon(pts_v_yz)).extrude(App.Vector(52.0, 0.0, 0.0))

    legs = []
    for sgn in (-1.0, 1.0):
        y_fl0 = 20.5 if sgn > 0 else -32.5
        fl_bot = Part.makeBox(44.0, 12.0, 3.00, App.Vector(-22.0, y_fl0, Z_STRUCT_BOT))
        fl_vert = Part.makeBox(44.0, 3.0, 21.50, App.Vector(-22.0, 19.5 if sgn > 0 else -22.5, Z_STRUCT_BOT))
        gus = Part.makeBox(44.0, 6.0, 9.0, App.Vector(-22.0, 13.5 if sgn > 0 else -19.5, zv + 6.0))
        y_tab = 5.5 if sgn > 0 else -11.5
        stop_tab = Part.makeBox(3.50, 6.00, 8.00, App.Vector(22.50, y_tab, zv))
        legs.extend([fl_bot, fl_vert, gus, stop_tab])

    for xs in (-16.0, 16.0):
        for ys in (-27.5, 27.5):
            legs.append(Part.makeCylinder(2.95, 11.0, App.Vector(xs, ys, Z_BASE_BOT + 1.0), App.Vector(0, 0, 1)))
            legs.append(Part.makeCylinder(4.80, 3.2, App.Vector(xs, ys, Z_STRUCT_BOT + 3.02), App.Vector(0, 0, 1)))

    full_v = cantoneira.fuse(legs).removeSplitter()
    slot = Part.makeBox(48.0, 8.0, 30.0, App.Vector(-20.0, -4.0, zv - 15.0))
    return full_v.cut(slot).removeSplitter()


def build_bolted_u_guide_and_uhmw() -> tuple[Part.Shape, Part.Shape, Part.Shape]:
    z0 = Z_WORK_DATUM + 125.50   # 1105.50 mm
    hz = 98.00                   # 1203.50 mm

    pts_u_xy = [
        App.Vector(-46.0, 23.98, z0), App.Vector(-46.0, 20.98, z0),
        App.Vector(-21.0, 20.98, z0), App.Vector(-21.0, -21.00, z0),
        App.Vector(21.0, -21.00, z0), App.Vector(21.0, 20.98, z0),
        App.Vector(46.0, 20.98, z0),  App.Vector(46.0, 23.98, z0),
        App.Vector(18.0, 23.98, z0),  App.Vector(18.0, -18.00, z0),
        App.Vector(-18.0, -18.00, z0), App.Vector(-18.0, 23.98, z0),
        App.Vector(-46.0, 23.98, z0),
    ]
    u_channel = Part.Face(Part.makePolygon(pts_u_xy)).extrude(App.Vector(0.0, 0.0, hz))
    tab_bot = Part.makeBox(42.0, 44.98, 2.0, App.Vector(-21.0, -21.00, z0 - 2.02)).cut(
        Part.makeBox(26.2, 26.2, 6.0, App.Vector(-13.1, -13.1, z0 - 4.0))
    )
    tab_top = Part.makeBox(42.0, 44.98, 2.0, App.Vector(-21.0, -21.00, z0 + hz + 0.02)).cut(
        Part.makeBox(26.2, 26.2, 6.0, App.Vector(-13.1, -13.1, z0 + hz - 2.0))
    )
    housing = u_channel.fuse([tab_bot, tab_top]).removeSplitter()

    u_holes, u_bolts = [], []
    for xg in (-33.0, 33.0):
        for zg in (Z_WORK_DATUM + 150.50, Z_WORK_DATUM + 198.50):
            u_holes.append(Part.makeCylinder(4.20, 12.0, App.Vector(xg, 16.0, zg), App.Vector(0, 1, 0)))
            shank = Part.makeCylinder(3.95, 16.0, App.Vector(xg, 19.0, zg), App.Vector(0, 1, 0))
            head = Part.makeCylinder(6.80, 4.0, App.Vector(xg, 16.95, zg), App.Vector(0, 1, 0))
            nut = Part.makeCylinder(6.80, 5.0, App.Vector(xg, 30.40, zg), App.Vector(0, 1, 0))
            u_bolts.extend([shank, head, nut])
    housing = housing.cut(u_holes).removeSplitter()
    u_bolts_sh = u_bolts[0].fuse(u_bolts[1:]).removeSplitter()

    uhmw_L = Part.makeBox(4.95, 25.96, hz, App.Vector(-17.95, -12.98, z0))
    uhmw_R = Part.makeBox(4.95, 25.96, hz, App.Vector(13.00, -12.98, z0))
    uhmw_F = Part.makeBox(35.80, 4.95, hz, App.Vector(-17.90, -17.95, z0))
    uhmw_B = Part.makeBox(35.80, 10.95, hz, App.Vector(-17.90, 13.00, z0))
    uhmw_all = uhmw_L.fuse([uhmw_R, uhmw_F, uhmw_B]).removeSplitter()
    return housing, uhmw_all, u_bolts_sh


def build_piston_and_blade_local() -> tuple[Part.Shape, Part.Shape, Part.Shape, Part.Shape]:
    z_tip_loc = -H_O5_TO_TIP              # -186.076952 mm
    z_blade_top = z_tip_loc + 26.00       # -160.076952 mm
    z_cap_top = z_blade_top + 6.35
    z_clamp_bot = z_blade_top - 19.00
    z_bolt_m6 = z_blade_top - 9.50

    h_bevel = (3.175 - 0.25) / math.tan(math.radians(15.0))
    z_bevel_top = z_tip_loc + h_bevel
    pts_yz = [
        App.Vector(-25.0, -0.25, z_tip_loc),
        App.Vector(-25.0, 0.25, z_tip_loc),
        App.Vector(-25.0, 3.175, z_bevel_top),
        App.Vector(-25.0, 3.175, z_blade_top),
        App.Vector(-25.0, -3.175, z_blade_top),
        App.Vector(-25.0, -3.175, z_bevel_top),
        App.Vector(-25.0, -0.25, z_tip_loc),
    ]
    blade = Part.Face(Part.makePolygon(pts_yz)).extrude(App.Vector(50.0, 0.0, 0.0))
    bh1 = Part.makeCylinder(3.15, 16.0, App.Vector(-15.0, -8.0, z_bolt_m6), App.Vector(0, 1, 0))
    bh2 = Part.makeCylinder(3.15, 16.0, App.Vector(15.0, -8.0, z_bolt_m6), App.Vector(0, 1, 0))
    blade = blade.cut([bh1, bh2]).removeSplitter()

    shaft = Part.makeBox(25.40, 25.40, -25.00 - z_cap_top, App.Vector(-12.70, -12.70, z_cap_top))
    cap_plate = Part.makeBox(52.00, 25.40, 6.35, App.Vector(-26.00, -12.70, z_blade_top + 0.02))
    clamp_ear = Part.makeBox(50.00, 6.35, 19.02, App.Vector(-25.00, 3.25, z_clamp_bot))
    clevis_base = Part.makeBox(25.40, 12.70, 25.00, App.Vector(-12.70, -6.35, -25.00))
    clevis_top = Part.makeCylinder(12.70, 12.70, App.Vector(0.0, -6.35, 0.0), App.Vector(0, 1, 0))
    ram = shaft.fuse([cap_plate, clamp_ear, clevis_base, clevis_top]).removeSplitter()

    ram_cuts = [
        Part.makeCylinder(7.02, 20.0, App.Vector(0.0, -10.0, 0.0), App.Vector(0, 1, 0)),
        Part.makeCylinder(3.15, 16.0, App.Vector(-15.0, -2.0, z_bolt_m6), App.Vector(0, 1, 0)),
        Part.makeCylinder(3.15, 16.0, App.Vector(15.0, -2.0, z_bolt_m6), App.Vector(0, 1, 0)),
    ]
    ram = ram.cut(ram_cuts).removeSplitter()

    m6_list = []
    for xm in (-15.0, 15.0):
        shank = Part.makeCylinder(2.95, 18.0, App.Vector(xm, -4.50, z_bolt_m6), App.Vector(0, 1, 0))
        head = Part.makeCylinder(5.00, 3.50, App.Vector(xm, -6.70, z_bolt_m6), App.Vector(0, 1, 0))
        nut = Part.makeCylinder(5.00, 4.00, App.Vector(xm, 9.65, z_bolt_m6), App.Vector(0, 1, 0))
        m6_list.append(shank.fuse([head, nut]).removeSplitter())
    m6_bolts = m6_list[0].fuse(m6_list[1:]).removeSplitter()

    bushing_o5 = make_bushing_y(0.0, 0.0, 12.04, 14.00, -6.30, 6.30)
    return ram, blade, m6_bolts, bushing_o5


# =========================================================================================
# 5. CAME 3-4-5, EXTRATOR AUTOMÁTICO SINCRONIZADO E MANIVELA K = 1.5
# =========================================================================================
def build_cam_disc_local() -> Part.Shape:
    """
    Perfil exato do came de disco 3-4-5 (`Came_Extrator_O2`) gerado pela envoltória
    analítica do rolete oscilante Ø19 mm (R_base = 52 mm, R_rolo = 9,5 mm) centrada em O2.
    """
    n_pts = 360
    cx_cam, cz_cam = [], []
    for i in range(n_pts):
        th_deg = i * (360.0 / n_pts)
        k = solve_cam_follower_kinematics(th_deg)
        cx, cz = k["C_rol"]
        vx, vz = cx - O2_X, cz - O2_Z
        t2 = math.radians(-th_deg)
        cx_cam.append(vx * math.cos(t2) - vz * math.sin(t2))
        cz_cam.append(vx * math.sin(t2) + vz * math.cos(t2))

    cam_pts = []
    for i in range(n_pts):
        im = (i - 1) % n_pts
        ip = (i + 1) % n_pts
        dx = cx_cam[ip] - cx_cam[im]
        dz = cz_cam[ip] - cz_cam[im]
        ds = math.hypot(dx, dz)
        nx, nz = dz / ds, -dx / ds
        cam_pts.append(App.Vector(cx_cam[i] + CAM_R_ROLLER * nx, Y_CAM_MIN, cz_cam[i] + CAM_R_ROLLER * nz))
    cam_pts.append(cam_pts[0])

    plate = Part.Face(Part.makePolygon(cam_pts)).extrude(App.Vector(0.0, Y_CAM_MAX - Y_CAM_MIN, 0.0))
    hub = Part.makeCylinder(20.0, 14.0, App.Vector(0.0, Y_CAM_MIN - 2.0, 0.0), App.Vector(0, 1, 0))
    bore = Part.makeCylinder(10.02, 20.0, App.Vector(0.0, Y_CAM_MIN - 4.0, 0.0), App.Vector(0, 1, 0))
    return plate.fuse(hub).cut(bore).removeSplitter()


def build_cam_extractor_system_local() -> dict[str, Part.Shape]:
    """
    Conjunto do Extrator Automático por Came no plano traseiro livre Y in [59, 76] mm:
      - Came_Extrator_O2 (local em O2, gira com Eixo_Principal_O2_20rpm, Y[59..69])
      - Alavanca_Seguidora (local em O_seg = (-28.0, 1447.5), braços em Y[71..77], rolete em Y[59.5..68.5])
      - Tirante_Extracao (local em Q_seg, acoplando Q_seg a P_top em Y[61.5..66.5])
      - Alavanca_Ejetora (local em O_ext = (34.0, 996.0), pá em Y[-3..+3], braço em Y[59.5..65.5])
      - Mola_Retorno (mola helicoidal entre suporte em col_R e pino P_top em Y=74 mm)
    """
    cam_sh = build_cam_disc_local()

    # Suporte estator do extrator (cantoneira O_ext com furos Ø12.2mm + pino O_seg traseiro + ancora mola fora de Tirante)
    ear_F = Part.makeBox(12.0, 4.0, 15.0, App.Vector(O_EXT_X - 6.0, -27.5, Z_BASE_TOP + 0.02))
    ear_B = Part.makeBox(12.0, 4.0, 15.0, App.Vector(O_EXT_X - 6.0, 24.0, Z_BASE_TOP + 0.02))
    shaft_ext = Part.makeCylinder(3.95, 56.0, App.Vector(O_EXT_X, -28.0, O_EXT_Z), App.Vector(0, 1, 0))
    ears = ear_F.fuse(ear_B).cut([
        Part.makeCylinder(4.05, 10.0, App.Vector(O_EXT_X, -30.0, O_EXT_Z), App.Vector(0, 1, 0)),
        Part.makeCylinder(6.10, 10.0, App.Vector(O_EXT_X, 22.0, O_EXT_Z), App.Vector(0, 1, 0)),
    ])
    seg_pin = Part.makeCylinder(3.95, 55.0, App.Vector(O_SEG_X, Y_PORTAL_R_MIN, O_SEG_Z), App.Vector(0, 1, 0))
    seg_spacer = make_bushing_y(O_SEG_X, O_SEG_Z, 8.10, 16.0, Y_PORTAL_R_MAX + 0.05, Y_CAM_MAX + 1.5)
    # Braco ancora da mola contorna Tirante_Extracao pela direita (X=96..114, Y=30..80) e vira p/ X=72..114 em Y=70..80
    sp_arm_y = Part.makeBox(18.0, 49.6, 6.0, App.Vector(96.0, Y_PORTAL_R_MAX + 0.02, 1140.0))
    sp_arm_x = Part.makeBox(42.0, 10.0, 6.0, App.Vector(72.0, 70.0, 1140.0))
    spring_anchor = sp_arm_y.fuse(sp_arm_x)
    stator_ext = ears.fuse([shaft_ext, seg_pin, seg_spacer, spring_anchor]).removeSplitter()

    # Alavanca Seguidora (local em O_seg = (-28.0, 1447.5))
    c0_dx, c0_dz = _C0_X - O_SEG_X, _C0_Z - O_SEG_Z
    q0_dx, q0_dz = SEG_Q0_X - O_SEG_X, SEG_Q0_Z - O_SEG_Z
    hub_seg = Part.makeCylinder(9.5, 8.0, App.Vector(0.0, Y_CAM_MAX + 1.6, 0.0), App.Vector(0, 1, 0))
    arm1_ang = math.degrees(math.atan2(c0_dz, c0_dx))
    arm1_bar = make_rounded_bar_xz(SEG_R_ARM1, 14.0, Y_CAM_MAX + 2.0, Y_CAM_MAX + 8.0)
    arm1_bar.rotate(App.Vector(0, 0, 0), App.Vector(0, 1, 0), -arm1_ang)
    arm2_bar = make_rounded_bar_xz(SEG_R_ARM2, 14.0, Y_CAM_MAX + 2.0, Y_CAM_MAX + 8.0)
    roller_pin = Part.makeCylinder(3.95, 18.0, App.Vector(c0_dx, Y_CAM_MIN + 0.2, c0_dz), App.Vector(0, 1, 0))
    roller_bearing = make_bushing_y(c0_dx, c0_dz, 8.05, 2.0 * CAM_R_ROLLER, Y_CAM_MIN + 0.5, Y_CAM_MAX - 0.5)
    q_pin = Part.makeCylinder(3.95, 18.0, App.Vector(q0_dx, Y_CAM_MIN + 1.0, q0_dz), App.Vector(0, 1, 0))
    follower_sh = hub_seg.fuse([arm1_bar, arm2_bar, roller_pin, roller_bearing, q_pin]).cut(
        Part.makeCylinder(4.05, 30.0, App.Vector(0.0, Y_CAM_MAX - 5.0, 0.0), App.Vector(0, 1, 0))
    ).removeSplitter()

    # Tirante_Extracao (local em Q_seg, Y in [61.5, 66.5])
    tir_bar = Part.makeBox(10.0, 5.0, TIR_LEN + 14.0, App.Vector(-5.0, Y_CAM_MID - 2.5, -TIR_LEN - 7.0))
    tir_eye_t = Part.makeCylinder(7.0, 5.0, App.Vector(0.0, Y_CAM_MID - 2.5, 0.0), App.Vector(0, 1, 0))
    tir_eye_b = Part.makeCylinder(7.0, 5.0, App.Vector(0.0, Y_CAM_MID - 2.5, -TIR_LEN), App.Vector(0, 1, 0))
    tirante_sh = tir_bar.fuse([tir_eye_t, tir_eye_b]).cut([
        Part.makeCylinder(4.10, 12.0, App.Vector(0.0, Y_CAM_MID - 6.0, 0.0), App.Vector(0, 1, 0)),
        Part.makeCylinder(4.10, 12.0, App.Vector(0.0, Y_CAM_MID - 6.0, -TIR_LEN), App.Vector(0, 1, 0)),
    ]).removeSplitter()

    # Alavanca_Ejetora (local em O_ext = (34.0, 0.0, 996.0))
    hub_mid = Part.makeCylinder(6.50, 7.0, App.Vector(0.0, -3.5, 0.0), App.Vector(0, 1, 0))
    paddle = Part.makeBox(51.5, 6.0, 6.5, App.Vector(-51.5, -3.0, -4.5))
    ext_bridge = make_bushing_y(0.0, 0.0, 8.10, 12.00, 3.0, Y_CAM_MAX + 5.0)
    # Anel na ponte que passa pelo ear_B (Y in [24, 28]) tem folga; o furo interno D8.10 veste shaft_ext
    arm_ext_ang = math.degrees(EXT_PHI0_RAD)
    arm_ext = make_rounded_bar_xz(EXT_R_CRANK, 13.0, Y_CAM_MAX + 2.0, Y_CAM_MAX + 8.0)
    arm_ext.rotate(App.Vector(0, 0, 0), App.Vector(0, 1, 0), -arm_ext_ang)
    p_top_pin = Part.makeCylinder(3.95, 17.5, App.Vector(EXT_CRANK_DX, Y_CAM_MID - 2.8, EXT_CRANK_DZ), App.Vector(0, 1, 0))
    ejector_sh = hub_mid.fuse([paddle, ext_bridge, arm_ext, p_top_pin]).cut(
        Part.makeCylinder(4.05, 60.0, App.Vector(0.0, -29.0, 0.0), App.Vector(0, 1, 0))
    ).removeSplitter()

    # Mola de retorno tracionada em Y = 74.0 mm (livre de Tirante Y<=66.5 e Alavanca_Ejetora!)
    y_sp = 74.0
    coils = [Part.makeTorus(4.5, 1.0, App.Vector(78.0, y_sp, 1044.0 + k * 7.2), App.Vector(0, 0, 1)) for k in range(11)]
    hook_t = Part.makeCylinder(1.0, 21.0, App.Vector(78.0, y_sp, 1119.0), App.Vector(0, 0, 1))
    hook_b = Part.makeCylinder(1.0, 24.0, App.Vector(78.0, y_sp, 1020.0), App.Vector(0, 0, 1))
    spring_sh = coils[0].fuse(coils[1:] + [hook_t, hook_b]).removeSplitter()

    return {
        "cam": cam_sh,
        "stator_ext": stator_ext,
        "follower": follower_sh,
        "tirante": tirante_sh,
        "ejector": ejector_sh,
        "spring": spring_sh,
    }


def build_l2_crank_and_shaft_local() -> dict[str, Part.Shape]:
    """
    Corpo 2 motorizado (centrado em O2 = (-83.9711, 1358.0385)):
      - Eixo_Principal_O2_20rpm: Eixo Ø20 mm SAE 1045 (Y in [-24.5, +175.0], SEM cruzar L3!)
      - Elo2_Manivela_L2: Manivela L2 = 28.9778 mm em barra chata 1.1/4"x1/4" (Y in [-24.50, -18.15])
      - Buchas_Catalogo_A + Pino_Eixo_A + Aneis_Retencao_ORing_A
    """
    shaft_o2 = Part.makeCylinder(10.00, 199.5, App.Vector(0.0, Y_L2_MIN, 0.0), App.Vector(0, 1, 0))
    collar_r = make_bushing_y(0.0, 0.0, 20.00, 28.00, Y_PORTAL_R_MAX + 24.5, Y_CAM_MIN - 2.2)
    shaft_all = shaft_o2.fuse([collar_r]).removeSplitter()

    l2_bar = make_rounded_bar_xz(L2, 34.00, Y_L2_MIN, Y_L2_MAX, d_hole1=20.02, d_hole2=14.04)
    bush_l2_a = make_bushing_y(L2, 0.0, 12.04, 14.00, Y_L2_MIN + 0.05, Y_L2_MAX - 0.05)

    # Pino liso Ø12 mm da junta A (Y in [-35.80, -16.00] acoplando L3[-33.5..-27.15] e L2[-24.5..-18.15])
    pin_a_core, oring_a = make_oring_pin_y(L2, 0.0, 11.96, -35.80, -16.00, groove_ys=(-34.60, -17.10))
    pin_a = pin_a_core.fuse([
        make_bushing_y(L2, 0.0, 12.10, 19.00, -27.10, -24.55),
    ]).removeSplitter()

    return {
        "Eixo_Principal_O2_20rpm": shaft_all,
        "Elo2_Manivela_L2": l2_bar,
        "Buchas_Catalogo_A": bush_l2_a,
        "Pino_Eixo_A": pin_a,
        "Aneis_Retencao_ORing_A": oring_a,
    }


# =========================================================================================
# 6. TREM DE POTÊNCIA COMERCIAL 20 RPM (MOTOR WEG, POLIAS, CORREIA A, VOLANTE 400 RPM, REDUTOR 20:1)
# =========================================================================================
def build_drivetrain_components() -> dict[str, Part.Shape]:
    """Modela todos os componentes comerciais do trem de potência no plano traseiro (+Y)."""
    # 1. Mancais comerciais: 1x F204 traseiro (O2 no pórtico traseiro) + 2x UCP204 (eixo 400 rpm)
    bearings = []
    yb = Y_PORTAL_R_MAX + 0.05
    fl = Part.makeBox(84.0, 12.0, 84.0, App.Vector(O2_X - 42.0, yb, O2_Z - 42.0))
    boss = Part.makeCylinder(22.0, 12.0, App.Vector(O2_X, yb + 12.0, O2_Z), App.Vector(0, 1, 0))
    f204_r = fl.fuse(boss).cut(
        Part.makeCylinder(10.10, 40.0, App.Vector(O2_X, yb - 5.0, O2_Z), App.Vector(0, 1, 0))
    ).removeSplitter()
    bearings.append(f204_r)

    # 2x UCP204 em Y = [175..211] e [300..336], base em Z_INT_SHELF_TOP = 1244.70
    for yp in (193.0, 318.0):
        foot = Part.makeBox(127.0, 36.0, 14.0, App.Vector(O_INT_X - 63.5, yp - 18.0, Z_INT_SHELF_TOP + 0.02))
        arch = Part.makeBox(64.0, 34.0, 33.3, App.Vector(O_INT_X - 32.0, yp - 17.0, Z_INT_SHELF_TOP + 0.02))
        ring = Part.makeCylinder(27.0, 34.0, App.Vector(O_INT_X, yp - 17.0, O_INT_Z), App.Vector(0, 1, 0))
        p204 = foot.fuse([arch, ring]).cut(
            Part.makeCylinder(10.10, 42.0, App.Vector(O_INT_X, yp - 21.0, O_INT_Z), App.Vector(0, 1, 0))
        ).removeSplitter()
        bearings.append(p204)
    mancais_sh = bearings[0].fuse(bearings[1:]).removeSplitter()

    # 2. Redutor Helicoidal Comercial 20:1 (Y in [82, 168], entre came traseiro Y<=77 e UCP204 Y>=175)
    y_red0, dy_red = 82.0, 86.0
    c_o2 = Part.makeCylinder(48.0, dy_red, App.Vector(O2_X, y_red0, O2_Z), App.Vector(0, 1, 0))
    c_int = Part.makeCylinder(32.5, dy_red, App.Vector(O_INT_X, y_red0, O_INT_Z), App.Vector(0, 1, 0))
    ang_r = math.atan2(O_INT_Z - O2_Z, O_INT_X - O2_X)
    dist_r = math.hypot(O_INT_X - O2_X, O_INT_Z - O2_Z)
    bridge = Part.makeBox(dist_r, dy_red, 64.0, App.Vector(0.0, y_red0, -32.0))
    bridge.rotate(App.Vector(0, 0, 0), App.Vector(0, 1, 0), -math.degrees(ang_r))
    bridge.translate(App.Vector(O2_X, 0.0, O2_Z))
    foot_r = Part.makeBox(110.0, 82.0, 14.0, App.Vector(O_INT_X - 55.0, y_red0 + 2.0, Z_INT_SHELF_TOP + 0.02))
    red_body = c_o2.fuse([c_int, bridge, foot_r]).cut([
        Part.makeCylinder(10.10, dy_red + 10.0, App.Vector(O2_X, y_red0 - 5.0, O2_Z), App.Vector(0, 1, 0)),
        Part.makeCylinder(10.10, dy_red + 10.0, App.Vector(O_INT_X, y_red0 - 5.0, O_INT_Z), App.Vector(0, 1, 0)),
    ]).removeSplitter()

    # 3. Eixo intermediário 400 RPM (Ø20 mm SAE 1045, Y in [165, 384])
    eixo_int_sh = Part.makeCylinder(10.00, 219.0, App.Vector(O_INT_X, 165.0, O_INT_Z), App.Vector(0, 1, 0))

    # 4. Volante de Inércia em Aço (D_ext=300, D_int=220, b_aro=40 mm, alma 10 mm, cubo Ø65x50 mm)
    rim = make_bushing_y(O_INT_X, O_INT_Z, 2.0 * VOL_R_INT, 2.0 * VOL_R_EXT, VOL_Y_MIN, VOL_Y_MAX)
    web = make_bushing_y(O_INT_X, O_INT_Z, 65.0, 2.0 * VOL_R_INT + 0.4, VOL_Y_MIN + 15.0, VOL_Y_MIN + 25.0)
    hub = make_bushing_y(O_INT_X, O_INT_Z, 20.04, 65.4, VOL_Y_MIN - 5.0, VOL_Y_MAX + 5.0)
    volante_sh = rim.fuse([web, hub]).removeSplitter()

    # 5. Polias comerciais perfil A c/ canal de encaixe da correia (Y = 368.0 mm): Movida Ø325 e Motora Ø75
    y_p0, dy_p = Y_BELT_CENTER - 11.0, 22.0
    pol_mov_rim = make_bushing_y(O_INT_X, O_INT_Z, 303.0, 329.0, y_p0, y_p0 + dy_p)
    pol_mov_web = make_bushing_y(O_INT_X, O_INT_Z, 50.0, 303.5, Y_BELT_CENTER - 5.0, Y_BELT_CENTER + 5.0)
    pol_mov_hub = make_bushing_y(O_INT_X, O_INT_Z, 20.04, 50.4, y_p0 - 4.0, y_p0 + dy_p + 4.0)
    groove_mov = make_bushing_y(O_INT_X, O_INT_Z, 316.0, 332.0, Y_BELT_CENTER - 7.0, Y_BELT_CENTER + 7.0)
    relief_holes = [
        Part.makeCylinder(28.0, 20.0, App.Vector(
            O_INT_X + 100.0 * math.cos(math.radians(60 * k)),
            Y_BELT_CENTER - 10.0,
            O_INT_Z + 100.0 * math.sin(math.radians(60 * k))), App.Vector(0, 1, 0))
        for k in range(6)
    ]
    polia_movida_sh = pol_mov_rim.fuse([pol_mov_web, pol_mov_hub]).cut(relief_holes + [groove_mov]).removeSplitter()

    pol_mot_raw = make_bushing_y(O_MOT_X, O_MOT_Z, 14.04, 79.0, y_p0, y_p0 + dy_p)
    groove_mot = make_bushing_y(O_MOT_X, O_MOT_Z, 66.0, 82.0, Y_BELT_CENTER - 7.0, Y_BELT_CENTER + 7.0)
    polia_motora_sh = pol_mot_raw.cut(groove_mot).removeSplitter()

    # 6. Correia em V Perfil A (13x8 mm) assentada no canal com folga 0.5 mm (0.000000 mm³ colisão!)
    r1, r2 = 37.5, 162.5
    d_c = O_INT_Z - O_MOT_Z  # 382.0 mm
    sin_beta = (r2 - r1) / d_c
    belt_pts_out, belt_pts_in = [], []
    ang1_start = -math.asin(sin_beta)
    ang1_end = math.pi + math.asin(sin_beta)
    for k in range(41):
        a = ang1_start + (ang1_end - ang1_start) * k / 40.0
        belt_pts_out.append(App.Vector(O_INT_X + (r2 + 4.0) * math.cos(a), Y_BELT_CENTER - 6.5, O_INT_Z + (r2 + 4.0) * math.sin(a)))
        belt_pts_in.append(App.Vector(O_INT_X + (r2 - 3.5) * math.cos(a), Y_BELT_CENTER - 6.5, O_INT_Z + (r2 - 3.5) * math.sin(a)))
    ang2_start = ang1_end
    ang2_end = 2.0 * math.pi + ang1_start
    for k in range(31):
        a = ang2_start + (ang2_end - ang2_start) * k / 30.0
        belt_pts_out.append(App.Vector(O_MOT_X + (r1 + 4.0) * math.cos(a), Y_BELT_CENTER - 6.5, O_MOT_Z + (r1 + 4.0) * math.sin(a)))
        belt_pts_in.append(App.Vector(O_MOT_X + (r1 - 3.5) * math.cos(a), Y_BELT_CENTER - 6.5, O_MOT_Z + (r1 - 3.5) * math.sin(a)))
    belt_pts_out.append(belt_pts_out[0])
    belt_pts_in.append(belt_pts_in[0])
    belt_outer = Part.Face(Part.makePolygon(belt_pts_out)).extrude(App.Vector(0, 13.0, 0))
    belt_inner = Part.Face(Part.makePolygon(belt_pts_in)).extrude(App.Vector(0, 13.0, 0))
    correia_sh = belt_outer.cut(belt_inner).removeSplitter()

    # 7. Motor Elétrico WEG W22 IR3 0,5 cv (0,37 kW) 4P IEC Frame 71 (carcaça oca realista ~10 kg, Y in [150..382])
    mot_housing = make_bushing_y(O_MOT_X, O_MOT_Z, 123.0, 136.0, 180.0, 345.0)
    mot_end_f = make_bushing_y(O_MOT_X, O_MOT_Z, 15.0, 136.0, 337.0, 345.0)
    mot_end_r = make_bushing_y(O_MOT_X, O_MOT_Z, 15.0, 136.0, 180.0, 188.0)
    mot_cowl_shell = make_bushing_y(O_MOT_X, O_MOT_Z, 128.0, 136.0, 150.0, 180.0)
    mot_cowl_cap = make_bushing_y(O_MOT_X, O_MOT_Z, 28.0, 136.0, 150.0, 153.5)
    mot_rotor = make_bushing_y(O_MOT_X, O_MOT_Z, 14.0, 68.0, 208.0, 318.0)
    mot_foot_L = Part.makeBox(22.0, 115.0, 16.0, App.Vector(O_MOT_X - 56.0, 205.0, Z_MOT_SHELF_TOP + 0.02))
    mot_foot_R = Part.makeBox(22.0, 115.0, 16.0, App.Vector(O_MOT_X + 34.0, 205.0, Z_MOT_SHELF_TOP + 0.02))
    mot_foot_bar = Part.makeBox(112.0, 115.0, 5.0, App.Vector(O_MOT_X - 56.0, 205.0, Z_MOT_SHELF_TOP + 0.02))
    mot_term_outer = Part.makeBox(74.0, 74.0, 34.0, App.Vector(O_MOT_X - 37.0, 225.0, O_MOT_Z + 56.0))
    mot_term_inner = Part.makeBox(66.0, 66.0, 26.0, App.Vector(O_MOT_X - 33.0, 229.0, O_MOT_Z + 58.0))
    mot_term = mot_term_outer.cut(mot_term_inner)
    mot_shaft = Part.makeCylinder(7.00, 207.0, App.Vector(O_MOT_X, 175.0, O_MOT_Z), App.Vector(0, 1, 0))
    motor_sh = mot_housing.fuse([
        mot_end_f, mot_end_r, mot_cowl_shell, mot_cowl_cap, mot_rotor,
        mot_foot_L, mot_foot_R, mot_foot_bar, mot_term, mot_shaft
    ]).removeSplitter()

    # 8. Base_Tensora_Motor (chapa 6.35 mm apoiada nas travessas Y=[185..205] e Y=[320..340])
    shelf_plate = Part.makeBox(180.0, 160.0, 6.35, App.Vector(O_MOT_X - 90.0, 185.0, Z_MOT_SHELF_TOP - 6.35))
    guide_L = Part.makeBox(12.0, 160.0, 14.0, App.Vector(O_MOT_X - 90.0, 185.0, Z_MOT_SHELF_TOP))
    guide_R = Part.makeBox(12.0, 160.0, 14.0, App.Vector(O_MOT_X + 78.0, 185.0, Z_MOT_SHELF_TOP))
    base_tensora_sh = shelf_plate.fuse([guide_L, guide_R]).removeSplitter()

    return {
        "mancais": mancais_sh,
        "redutor": red_body,
        "eixo_int": eixo_int_sh,
        "volante": volante_sh,
        "polia_movida": polia_movida_sh,
        "polia_motora": polia_motora_sh,
        "correia": correia_sh,
        "motor": motor_sh,
        "base_tensora": base_tensora_sh,
    }


# =========================================================================================
# 7. CAVALETE 1,50 m E GABINETE NR-12 AMPLIADOS (METALON + CHAPA #18 + COLETOR 12,3 L)
# =========================================================================================
def build_enlarged_stand_and_nr12_cabinet() -> tuple[Part.Shape, Part.Shape, Part.Shape, Part.Shape, Part.Shape, Part.Shape]:
    """
    Cavalete 1,50 m e Gabinete NR-12 ampliados para enclausurar motor WEG, correia V,
    volante 400 RPM, redutor 20:1 e came extrator frontal:
      - X externo: [-190, +280] mm (cavalete) | [-170, +260] mm (gabinete superior)
      - Y externo: [-135, +435] mm (cavalete) | [-94, +415] mm (gabinete superior)
      - Mantém vão dianteiro inferior livre para Reservatório 12,3 L (Y in [-115, +115])
      - Mantém lado esquerdo X = -170 mm compatível com Calha e Moega de Alimentação NR-12!
    """
    m, w = 20.0, 1.50
    tubes = []

    # 4 Colunas principais do cavalete + 2 colunas traseiras da baia do motor
    h_stand = Z_BASE_BOT - Z_FOOT_TOP  # 977.24 mm
    for xs in (-190.0, 260.0):
        for ys in (-135.0, 415.0):
            tubes.append(make_hollow_metalon_box(xs, ys, Z_FOOT_TOP, m, m, h_stand, axis="Z", wall=w))
    # Colunas médias em Y = +115 (suportam o reservatório frontal e a frente da baia do motor)
    for xs in (-190.0, 260.0):
        tubes.append(make_hollow_metalon_box(xs, 115.0, Z_FOOT_TOP, m, m, h_stand, axis="Z", wall=w))

    # Travessas inferiores de piso (Z = 30.0)
    for ys in (-135.0, 115.0, 415.0):
        tubes.append(make_hollow_metalon_box(-170.0, ys, 30.0, 430.0, m, m, axis="X", wall=w))
    for xs in (-190.0, 260.0):
        tubes.append(make_hollow_metalon_box(xs, -115.0, 30.0, m, 230.0, m, axis="Y", wall=w))
        tubes.append(make_hollow_metalon_box(xs, 135.0, 30.0, m, 280.0, m, axis="Y", wall=w))

    # Prateleira do Reservatório 12,3 L (Z in [520, 540], Y in [-115, +115] -> frente 100% livre!)
    tubes.append(make_hollow_metalon_box(-170.0, 115.0, 520.0, 430.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-190.0, -115.0, 520.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(260.0, -115.0, 520.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(-162.0, -115.0, 520.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(92.0, -115.0, 520.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(-170.0, -135.0, 500.0, 430.0, m, m, axis="X", wall=w))

    # Sub-quadro da Base Tensora do Motor (Z in [798.65, 818.65], Y in [185, 340])
    z_mframe = Z_MOT_SHELF_TOP - 6.35 - m  # 798.65 mm
    tubes.append(make_hollow_metalon_box(-170.0, 185.0, z_mframe, 430.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-170.0, 320.0, z_mframe, 430.0, m, m, axis="X", wall=w))
    for xs in (-190.0, 260.0):
        tubes.append(make_hollow_metalon_box(xs, 135.0, z_mframe, m, 280.0, m, axis="Y", wall=w))

    # Quadro superior da mesa (Z = 962.0 mm)
    z_top_stand = Z_BASE_BOT - m
    for xs in (-190.0, 260.0):
        tubes.append(make_hollow_metalon_box(xs, -115.0, z_top_stand, m, 230.0, m, axis="Y", wall=w))
        tubes.append(make_hollow_metalon_box(xs, 135.0, z_top_stand, m, 280.0, m, axis="Y", wall=w))
    for ys in (-135.0, -46.50, 33.55, 115.0, 415.0):
        tubes.append(make_hollow_metalon_box(-170.0, ys, z_top_stand, 430.0, m, m, axis="X", wall=w))

    # Quadro Superior NR-12 (Z in [988.37, 1497.50], X in [-170, +260], Y in [-52, +435])
    z_bot_cab, z_top_cab = Z_STRUCT_BOT, CAB_Z_TOP
    h_post = z_top_cab - z_bot_cab
    z_mid_rail = Z_WORK_DATUM + 263.30

    for xp in (CAB_X_MIN, CAB_X_MAX - m):
        for yp in (CAB_Y_FRONT, CAB_Y_REAR - m):
            tubes.append(make_hollow_metalon_box(xp, yp, z_bot_cab, m, m, h_post, axis="Z", wall=w))
    for yp in (33.55,):
        tubes.append(make_hollow_metalon_box(CAB_X_MIN, yp, z_bot_cab, m, m, h_post, axis="Z", wall=w))
    for xp in (CAB_X_MIN, CAB_X_MAX - m):
        for yp in (183.0, 308.0):
            tubes.append(make_hollow_metalon_box(xp, yp, z_bot_cab, m, m, Z_INT_SHELF_TOP - z_bot_cab, axis="Z", wall=w))

    tubes.append(make_hollow_metalon_box(CAB_X_MIN + m, CAB_Y_FRONT, z_top_cab - m, 390.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(CAB_X_MIN + m, CAB_Y_FRONT, z_bot_cab, 390.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(CAB_X_MIN + m, CAB_Y_REAR - m, z_top_cab - m, 390.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(CAB_X_MIN + m, CAB_Y_REAR - m, z_bot_cab, 390.0, m, m, axis="X", wall=w))

    len_y_long = (CAB_Y_REAR - m) - (CAB_Y_FRONT + m)
    for xp in (CAB_X_MIN, CAB_X_MAX - m):
        tubes.append(make_hollow_metalon_box(xp, CAB_Y_FRONT + m, z_top_cab - m, m, len_y_long, m, axis="Y", wall=w))
        tubes.append(make_hollow_metalon_box(xp, CAB_Y_FRONT + m, z_bot_cab, m, len_y_long, m, axis="Y", wall=w))

    # Travessas suporte dos mancais UCP204 e Redutor (Z_INT_SHELF_TOP = 1244.70)
    z_u_beam = Z_INT_SHELF_TOP - m  # 1224.70 mm
    for yp in (105.0, 183.0, 308.0):
        tubes.append(make_hollow_metalon_box(CAB_X_MIN + m, yp, z_u_beam, 390.0, m, m, axis="X", wall=w))

    # Travessa esquerda para fechamento da boca da calha (Y in [-44.0, +33.55])
    tubes.append(make_hollow_metalon_box(CAB_X_MIN, -44.0, Z_WORK_DATUM + 131.0, m, 77.55, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(CAB_X_MIN, -44.0, z_mid_rail, m, 77.55, m, axis="Y", wall=w))

    metalon_frame = tubes[0].fuse(tubes[1:]).removeSplitter()

    # Furos M6 p/ Visor frontal, Calha e Moega
    m_holes = []
    for xb in (-160.0, 250.0):
        for zb in (Z_WORK_DATUM + 45.0, Z_WORK_DATUM + 155.0, Z_WORK_DATUM + 257.5,
                   Z_WORK_DATUM + 292.5, Z_WORK_DATUM + 397.5, Z_WORK_DATUM + 505.5):
            m_holes.append(Part.makeCylinder(3.05, 12.0, App.Vector(xb, CAB_Y_FRONT - 3.0, zb), App.Vector(0, 1, 0)))
    for ym in (-54.0, 41.0):
        m_holes.append(Part.makeCylinder(3.05, 12.0, App.Vector(-174.0, ym, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0)))
    for ym in (-54.0, 43.55):
        for zm in (1155.0, 1253.3):
            m_holes.append(Part.makeCylinder(3.05, 28.0, App.Vector(-174.0, ym, zm), App.Vector(1, 0, 0)))
    metalon_frame = metalon_frame.cut(m_holes).removeSplitter()

    # 4x Sapatas de piso ampliadas (80x80x4.76 mm, 8 furos Ø10.5 mm)
    feet_plates = []
    foot_specs = [
        (-215.0, -160.0, [(-202.0, -147.0), (-158.0, -103.0)]),
        (230.0,  -160.0, [(288.0,  -147.0), (244.0,  -103.0)]),
        (-215.0,  390.0, [(-202.0,  447.0), (-158.0,  403.0)]),
        (230.0,   390.0, [(288.0,   447.0), (244.0,   403.0)]),
    ]
    for x0p, y0p, hole_xy in foot_specs:
        pl = Part.makeBox(80.0, 80.0, Z_FOOT_TOP, App.Vector(x0p, y0p, Z_FLOOR))
        h_cuts = [Part.makeCylinder(5.25, 10.0, App.Vector(hx, hy, -2.0), App.Vector(0, 0, 1)) for hx, hy in hole_xy]
        feet_plates.append(pl.cut(h_cuts).removeSplitter())
    feet_shape = feet_plates[0].fuse(feet_plates[1:]).removeSplitter()

    # Carenagem NR-12 Chapa #18 (1.20 mm) 100% fechada (sem frestas ou pinch points na baia motor/correia!)
    panels = []
    w_cab = CAB_X_MAX - CAB_X_MIN  # 430.0 mm
    d_cab = CAB_Y_REAR - CAB_Y_FRONT  # 499.0 mm
    p_front_top = Part.makeBox(w_cab, 1.20, 244.0, App.Vector(CAB_X_MIN, CAB_Y_FRONT - 1.22, Z_WORK_DATUM + 273.50))
    p_front_cuts = [
        Part.makeCylinder(3.05, 6.0, App.Vector(xb, CAB_Y_FRONT - 3.0, zb), App.Vector(0, 1, 0))
        for xb in (-160.0, 250.0) for zb in (Z_WORK_DATUM + 292.5, Z_WORK_DATUM + 397.5, Z_WORK_DATUM + 505.5)
    ]
    panels.append(p_front_top.cut(p_front_cuts).removeSplitter())

    # Painel traseiro superior (Z>=988.37, X[-170..260]) + inferior alargado (Z[790..989.57], X[-191.22..281.22]) c/ grelha <= 6 mm
    p_rear_up = Part.makeBox(w_cab, 1.20, z_top_cab - z_bot_cab, App.Vector(CAB_X_MIN, CAB_Y_REAR + 0.05, z_bot_cab))
    p_rear_low = Part.makeBox(472.44, 1.20, z_bot_cab - 790.0 + 1.20, App.Vector(-191.22, CAB_Y_REAR + 0.05, 790.0))
    vent_slots = [
        Part.makeBox(140.0, 6.0, 6.0, App.Vector(O_MOT_X - 70.0, CAB_Y_REAR - 2.0, 845.0 + k * 14.0))
        for k in range(10)
    ]
    panels.append(p_rear_up)
    panels.append(p_rear_low.cut(vent_slots).removeSplitter())

    # Lateral direita superior (X=260.02) + inferior estendida até Z=989.57 (X=280.02) + aba de degrau horizontal
    panels.append(Part.makeBox(1.20, d_cab, h_post, App.Vector(CAB_X_MAX + 0.02, CAB_Y_FRONT, z_bot_cab)))
    panels.append(Part.makeBox(1.20, 299.55, 199.57, App.Vector(280.02, 135.50, 790.0)))
    panels.append(Part.makeBox(21.20, 299.55, 1.20, App.Vector(CAB_X_MAX + 0.02, 135.50, z_bot_cab)))
    # Lateral esquerda superior + inferior estendida até Z=989.57 (X=-191.22) + aba de degrau horizontal
    p_left_top = Part.makeBox(1.20, d_cab, 386.50, App.Vector(CAB_X_MIN - 1.22, CAB_Y_FRONT, Z_WORK_DATUM + 131.0))
    p_left_cuts = [
        Part.makeCylinder(3.05, 8.0, App.Vector(-174.0, ym, zm), App.Vector(1, 0, 0))
        for ym in (-54.0, 43.55) for zm in (1155.0, 1253.3)
    ]
    panels.append(p_left_top.cut(p_left_cuts).removeSplitter())
    panels.append(Part.makeBox(1.20, d_cab, 51.63, App.Vector(CAB_X_MIN - 1.22, CAB_Y_FRONT, z_bot_cab)))
    panels.append(Part.makeBox(1.20, 299.55, 199.57, App.Vector(-191.22, 135.50, 790.0)))
    panels.append(Part.makeBox(21.20, 299.55, 1.20, App.Vector(-191.22, 135.50, z_bot_cab)))
    # Teto fechado
    panels.append(Part.makeBox(w_cab, d_cab, 1.20, App.Vector(CAB_X_MIN, CAB_Y_FRONT, z_top_cab + 0.02)))
    # Antepara frontal da baia do motor (Y=135.50, fechada até Z=988.35) + tiras sobre colunas (Z[982.05..988.35])
    panels.append(Part.makeBox(429.90, 1.20, 198.35, App.Vector(-169.95, 135.50, 790.0)))
    panels.append(Part.makeBox(20.00, 1.20, 6.30, App.Vector(-190.00, 135.50, 982.05)))
    panels.append(Part.makeBox(20.00, 1.20, 6.30, App.Vector(260.00, 135.50, 982.05)))
    # Fechamento frontal vertical das laterais inferiores sobre Y=135.5 (entre X[-191.2,-190] / [280,281.2] e Z[790..989.57])
    # Bandeja inferior fechada sob motor e polia motora (Z=790.00 mm) c/ rasgos ISO 13857 <= 7.0 mm!
    pan_raw = Part.makeBox(472.44, 299.55, 1.20, App.Vector(-191.22, 135.50, 790.0))
    pan_cuts = [
        Part.makeBox(20.20, 20.50, 4.0, App.Vector(-190.10, 414.90, 788.5)),
        Part.makeBox(20.20, 20.50, 4.0, App.Vector(259.90, 414.90, 788.5)),
    ]
    for ks in range(10):
        pan_cuts.append(Part.makeBox(7.0, 120.0, 4.0, App.Vector(-60.0 + ks * 24.0, 180.0, 788.5)))
    panels.append(pan_raw.cut(pan_cuts).removeSplitter())
    sheet_panels = panels[0].fuse(panels[1:]).removeSplitter()

    # Visor Policarbonato NR-12 (Z in [1008.4, 1253.45], em Y = CAB_Y_FRONT - 1.22)
    poly_window = Part.makeBox(w_cab, 1.20, 245.05, App.Vector(CAB_X_MIN, CAB_Y_FRONT - 1.22, Z_WORK_DATUM + 28.40))
    v_cuts = [
        Part.makeCylinder(3.05, 6.0, App.Vector(xb, CAB_Y_FRONT - 3.0, zb), App.Vector(0, 1, 0))
        for xb in (-160.0, 250.0) for zb in (Z_WORK_DATUM + 45.0, Z_WORK_DATUM + 155.0, Z_WORK_DATUM + 257.5)
    ]
    poly_window = poly_window.cut(v_cuts).removeSplitter()

    # Calha de Alimentação Segura NR-12 (42x48 mm em Y=0) — idêntica ao modelo manual!
    pts_chute_out = [
        App.Vector(-215.0, -22.50, Z_WORK_DATUM + 78.50),
        App.Vector(-27.0,  -22.50, Z_WORK_DATUM + 21.00),
        App.Vector(-27.0,  -22.50, Z_WORK_DATUM + 72.00),
        App.Vector(-215.0, -22.50, Z_WORK_DATUM + 129.50),
        App.Vector(-215.0, -22.50, Z_WORK_DATUM + 78.50),
    ]
    chute_outer = Part.Face(Part.makePolygon(pts_chute_out)).extrude(App.Vector(0.0, 45.0, 0.0))
    k_bot = (80.00 - 22.50) / 188.0
    k_top = (128.00 - 70.50) / 188.0
    x_in_L, x_in_R = -216.0, -26.0
    pts_tunnel_in = [
        App.Vector(x_in_L, -21.00, Z_WORK_DATUM + 22.50 + k_bot * (-27.0 - x_in_L)),
        App.Vector(x_in_R, -21.00, Z_WORK_DATUM + 22.50 + k_bot * (-27.0 - x_in_R)),
        App.Vector(x_in_R, -21.00, Z_WORK_DATUM + 70.50 + k_top * (-27.0 - x_in_R)),
        App.Vector(x_in_L, -21.00, Z_WORK_DATUM + 70.50 + k_top * (-27.0 - x_in_L)),
        App.Vector(x_in_L, -21.00, Z_WORK_DATUM + 22.50 + k_bot * (-27.0 - x_in_L)),
    ]
    chute = chute_outer.cut(Part.Face(Part.makePolygon(pts_tunnel_in)).extrude(App.Vector(0.0, 42.0, 0.0))).removeSplitter()
    fl_portal = Part.makeBox(34.0, 1.48, 44.0, App.Vector(-122.0, 22.50, Z_WORK_DATUM + 43.0))
    fl_metalon_F = Part.makeBox(3.0, 41.5, 50.0, App.Vector(-173.02, -64.0, Z_WORK_DATUM + 65.0))
    fl_metalon_R = Part.makeBox(3.0, 24.0, 50.0, App.Vector(-173.02, 22.5, Z_WORK_DATUM + 65.0))
    chute = chute.fuse([fl_portal, fl_metalon_F, fl_metalon_R]).removeSplitter()
    c_holes = [
        Part.makeCylinder(4.10, 6.0, App.Vector(-105.0, 20.0, Z_WORK_DATUM + 53.0), App.Vector(0, 1, 0)),
        Part.makeCylinder(4.10, 6.0, App.Vector(-105.0, 20.0, Z_WORK_DATUM + 77.0), App.Vector(0, 1, 0)),
        Part.makeCylinder(3.05, 8.0, App.Vector(-175.0, -54.0, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0)),
        Part.makeCylinder(3.05, 8.0, App.Vector(-175.0, 41.0, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0)),
    ]
    chute = chute.cut(c_holes).removeSplitter()

    cab_bolts = []
    for xb in (-160.0, 250.0):
        for zb in (Z_WORK_DATUM + 45.0, Z_WORK_DATUM + 155.0, Z_WORK_DATUM + 257.5,
                   Z_WORK_DATUM + 292.5, Z_WORK_DATUM + 397.5, Z_WORK_DATUM + 505.5):
            head_b = Part.makeCylinder(4.50, 1.80, App.Vector(xb, CAB_Y_FRONT - 3.05, zb), App.Vector(0, 1, 0))
            shank_b = Part.makeCylinder(2.95, 7.50, App.Vector(xb, CAB_Y_FRONT - 1.25, zb), App.Vector(0, 1, 0))
            cab_bolts.append(head_b.fuse(shank_b).removeSplitter())
    for zc in (Z_WORK_DATUM + 53.0, Z_WORK_DATUM + 77.0):
        cab_bolts.append(Part.makeCylinder(3.95, 15.0, App.Vector(-105.0, 21.0, zc), App.Vector(0, 1, 0)))
        cab_bolts.append(Part.makeCylinder(6.50, 4.5, App.Vector(-105.0, 30.38, zc), App.Vector(0, 1, 0)))
    for ym in (-54.0, 41.0):
        hm_b = Part.makeCylinder(4.50, 1.80, App.Vector(-174.85, ym, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0))
        sm_b = Part.makeCylinder(2.95, 6.50, App.Vector(-173.05, ym, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0))
        cab_bolts.append(hm_b.fuse(sm_b).removeSplitter())
    for ym in (-54.0, 43.55):
        for zm in (1155.0, 1253.3):
            hm_r = Part.makeCylinder(4.80, 3.00, App.Vector(-175.46, ym, zm), App.Vector(1, 0, 0))
            sm_r = Part.makeCylinder(2.95, 25.50, App.Vector(-172.46, ym, zm), App.Vector(1, 0, 0))
            nm_r = Part.makeCylinder(4.80, 4.00, App.Vector(-149.95, ym, zm), App.Vector(1, 0, 0))
            cab_bolts.append(hm_r.fuse([sm_r, nm_r]).removeSplitter())
    cab_bolts_shape = cab_bolts[0].fuse(cab_bolts[1:]).removeSplitter()

    return metalon_frame, sheet_panels, poly_window, chute, feet_shape, cab_bolts_shape


def build_sheet_metal_chute_and_reservoir() -> tuple[Part.Shape, Part.Shape]:
    pts_left = [
        App.Vector(104.0, -20.5, 980.0), App.Vector(105.5, -20.5, 980.0),
        App.Vector(42.0,  -20.5, 758.0), App.Vector(40.5,  -20.5, 758.0),
        App.Vector(104.0, -20.5, 980.0),
    ]
    slope_bot = Part.Face(Part.makePolygon(pts_left)).extrude(App.Vector(0.0, 41.0, 0.0))
    pts_side = [
        App.Vector(105.5, -21.70, 981.5), App.Vector(42.0, -21.70, 758.0),
        App.Vector(-25.0, -21.70, 758.0), App.Vector(28.0, -21.70, 981.5),
        App.Vector(105.5, -21.70, 981.5),
    ]
    side_f = Part.Face(Part.makePolygon(pts_side)).extrude(App.Vector(0.0, 1.20, 0.0))
    side_b = Part.Face(Part.makePolygon(pts_side)).extrude(App.Vector(0.0, 1.20, 0.0))
    side_b.translate(App.Vector(0.0, 42.20, 0.0))
    discharge_chute = slope_bot.fuse([side_f, side_b]).removeSplitter()

    res_outer = Part.makeBox(268.0, 230.0, 200.0, App.Vector(-162.0, -115.0, 540.5))
    res_inner = Part.makeBox(265.6, 227.6, 200.0, App.Vector(-160.8, -113.8, 541.7))
    reservoir = res_outer.cut(res_inner).removeSplitter()
    rim_front = Part.makeBox(278.0, 8.0, 1.5, App.Vector(-167.0, -123.0, 739.0))
    rim_left = Part.makeBox(8.0, 230.0, 1.5, App.Vector(-170.0, -115.0, 739.0))
    rim_right = Part.makeBox(8.0, 230.0, 1.5, App.Vector(106.0, -115.0, 739.0))
    handle_bar = Part.makeBox(110.0, 18.0, 14.0, App.Vector(-83.0, -133.0, 665.0)).cut(
        Part.makeBox(102.0, 14.0, 16.0, App.Vector(-79.0, -130.0, 664.0))
    )
    reservoir = reservoir.fuse([rim_front, rim_left, rim_right, handle_bar]).removeSplitter()
    return discharge_chute, reservoir


def build_feeding_hopper_reservoir() -> Part.Shape:
    def rect_yz(x: float, y0: float, y1: float, z0: float, z1: float):
        return Part.makePolygon([
            App.Vector(x, y0, z0), App.Vector(x, y1, z0),
            App.Vector(x, y1, z1), App.Vector(x, y0, z1),
            App.Vector(x, y0, z0),
        ])

    outer_loft = Part.makeLoft([
        rect_yz(-365.00, -70.00, 70.00, 1135.00, 1280.00),
        rect_yz(-215.05, -22.50, 22.50, 1058.50, 1280.00),
    ], True, True)
    inner_loft = Part.makeLoft([
        rect_yz(-363.80, -68.80, 68.80, 1136.20, 1282.00),
        rect_yz(-213.50, -21.30, 21.30, 1060.00, 1282.00),
    ], True, True)
    arm_f_side = Part.makeBox(120.56, 1.20, 135.0, App.Vector(-293.00, -46.50, 1135.0))
    arm_f_bot = Part.makeBox(120.56, 20.00, 1.20, App.Vector(-293.00, -46.50, 1135.0))
    fl_f = Part.makeBox(1.20, 38.00, 135.0, App.Vector(-172.44, -64.50, 1135.0))
    arm_r_side = Part.makeBox(142.56, 1.20, 135.0, App.Vector(-315.00, 52.35, 1135.0))
    arm_r_bot = Part.makeBox(142.56, 20.00, 1.20, App.Vector(-315.00, 33.55, 1135.0))
    fl_r = Part.makeBox(1.20, 20.00, 135.0, App.Vector(-172.44, 33.55, 1135.0))
    front_cap = Part.makeBox(1.20, 45.0, 170.40, App.Vector(-216.25, -22.50, 1109.60))
    lip_back = Part.makeBox(10.0, 140.0, 1.20, App.Vector(-375.00, -70.00, 1278.80))
    lip_front = Part.makeBox(10.0, 45.0, 1.20, App.Vector(-215.05, -22.50, 1278.80))

    hopper = outer_loft.fuse([
        arm_f_side, arm_f_bot, fl_f, arm_r_side, arm_r_bot, fl_r
    ]).cut(inner_loft).fuse([front_cap, lip_back, lip_front]).removeSplitter()

    h_cuts = [
        Part.makeCylinder(3.05, 8.0, App.Vector(-175.0, ym, zm), App.Vector(1, 0, 0))
        for ym in (-54.0, 43.55) for zm in (1155.0, 1253.3)
    ]
    return hopper.cut(h_cuts).removeSplitter()


# =========================================================================================
# 8. CONTROLADOR CINEMÁTICO NATIVO (EXPRESSION ENGINE C++ PARA 360° + CAME EXTRATOR)
# =========================================================================================
MOVING_GROUPS = {
    "O2": ("Eixo_Principal_O2_20rpm", "Elo2_Manivela_L2", "Came_Extrator_O2",
           "Buchas_Catalogo_A", "Pino_Eixo_A", "Aneis_Retencao_ORing_A"),
    "L3": ("Elo3_Biela_L3", "Buchas_Catalogo_L3"),
    "L4": ("Elo4_Balancim_L4", "Buchas_Catalogo_L4"),
    "L5": ("Elo5_Garfo_Duplo_L5", "Buchas_Catalogo_L5", "Pino_Eixo_B", "Aneis_Retencao_ORing_B"),
    "O5": ("Pistao_Embolo_Quadrado", "Navalha_Corte_SAE5160", "Parafusos_Fixacao_Navalha_M6",
           "Bucha_Catalogo_O5", "Pino_Eixo_O5", "Aneis_Retencao_ORing_O5"),
}


def bind_native_kinematic_expressions(doc: App.Document, ctrl) -> None:
    """Vincula mecanismo 360° K=1.5 e came extrator sincronizado ao ExpressionEngine C++."""
    ctrl.setExpression("Ax_mm", f"{O2_X:.8f} + {L2:.8f} * cos(Angulo_Manivela_Graus * 1 deg)")
    ctrl.setExpression("Az_mm", f"{O2_Z:.8f} + {L2:.8f} * sin(Angulo_Manivela_Graus * 1 deg)")
    ctrl.setExpression("dA_mm", f"sqrt(Ax_mm^2 + (Az_mm - {O4_Z:.8f})^2)")
    ctrl.setExpression("ac_mm", f"({L4:.10f}^2 - {L3:.10f}^2 + dA_mm^2) / (2.0 * dA_mm)")
    ctrl.setExpression("hc_mm", f"sqrt(max(0.0; {L4:.10f}^2 - ac_mm^2))")
    ctrl.setExpression("Bx_mm", f"ac_mm * Ax_mm / dA_mm - hc_mm * (Az_mm - {O4_Z:.8f}) / dA_mm")
    ctrl.setExpression("Bz_mm", f"{O4_Z:.8f} + ac_mm * (Az_mm - {O4_Z:.8f}) / dA_mm + hc_mm * Ax_mm / dA_mm")
    ctrl.setExpression("Posicao_Pistao_O5_Z_mm", f"Bz_mm - sqrt(max(0.0; {L5:.10f}^2 - Bx_mm^2))")
    ctrl.setExpression("Posicao_Navalha_Z_tip_mm", f"Posicao_Pistao_O5_Z_mm - {H_O5_TO_TIP:.10f}")
    ctrl.setExpression("Angulo_Biela_L3_Graus", "atan2(Bz_mm - Az_mm; Bx_mm - Ax_mm) / 1 deg")
    ctrl.setExpression("Angulo_Balancim_L4_Graus", f"atan2(Bz_mm - {O4_Z:.8f}; Bx_mm) / 1 deg")
    ctrl.setExpression("Angulo_Garfo_L5_Graus", "atan2(Posicao_Pistao_O5_Z_mm - Bz_mm; -Bx_mm) / 1 deg")
    ctrl.setExpression(
        "Angulo_Transmissao_Mu_Graus",
        "abs(Angulo_Balancim_L4_Graus - Angulo_Biela_L3_Graus) > 180 ? "
        "360 - abs(Angulo_Balancim_L4_Graus - Angulo_Biela_L3_Graus) : "
        "abs(Angulo_Balancim_L4_Graus - Angulo_Biela_L3_Graus)",
    )

    # Sincronismo do Extrator por Came (Dwell-Rise-Return 3-4-5 em função de Angulo_Manivela_Graus)
    ctrl.setExpression("Theta_Mod_Graus", "Angulo_Manivela_Graus - 360 * floor(Angulo_Manivela_Graus / 360)")
    ctrl.setExpression("u_subida", f"(Theta_Mod_Graus - {CAM_RISE_START_DEG:.1f}) / {CAM_RISE_END_DEG - CAM_RISE_START_DEG:.1f}")
    ctrl.setExpression("u_retorno", f"(Theta_Mod_Graus - {CAM_RISE_END_DEG:.1f}) / {CAM_RET_END_DEG - CAM_RISE_END_DEG:.1f}")
    ctrl.setExpression(
        "Angulo_Ejetor_Graus",
        f"(Theta_Mod_Graus >= {CAM_RISE_START_DEG:.1f} ? "
        f"(Theta_Mod_Graus <= {CAM_RISE_END_DEG:.1f} ? "
        f"({EXT_ANG_MAX_DEG:.2f} * (10*u_subida^3 - 15*u_subida^4 + 6*u_subida^5)) : "
        f"(Theta_Mod_Graus <= {CAM_RET_END_DEG:.1f} ? "
        f"({EXT_ANG_MAX_DEG:.2f} * (1.0 - (10*u_retorno^3 - 15*u_retorno^4 + 6*u_retorno^5))) : 0.0)) : 0.0)"
    )

    ctrl.setExpression(
        "P_top_X_mm",
        f"{O_EXT_X:.6f} + {EXT_CRANK_DX:.6f} * cos(Angulo_Ejetor_Graus * 1 deg) "
        f"+ {EXT_CRANK_DZ:.6f} * sin(Angulo_Ejetor_Graus * 1 deg)",
    )
    ctrl.setExpression(
        "P_top_Z_mm",
        f"{O_EXT_Z:.6f} - {EXT_CRANK_DX:.6f} * sin(Angulo_Ejetor_Graus * 1 deg) "
        f"+ {EXT_CRANK_DZ:.6f} * cos(Angulo_Ejetor_Graus * 1 deg)",
    )
    ctrl.setExpression("Seg_d_mm", f"sqrt((P_top_X_mm - {O_SEG_X:.6f})^2 + (P_top_Z_mm - {O_SEG_Z:.6f})^2)")
    ctrl.setExpression("Seg_ac_mm", f"({SEG_R_ARM2:.10f}^2 - {TIR_LEN:.10f}^2 + Seg_d_mm^2) / (2.0 * Seg_d_mm)")
    ctrl.setExpression("Seg_hc_mm", f"sqrt(max(0.0; {SEG_R_ARM2:.10f}^2 - Seg_ac_mm^2))")
    ctrl.setExpression(
        "Q_seg_X_mm",
        f"{O_SEG_X:.6f} + Seg_ac_mm * (P_top_X_mm - {O_SEG_X:.6f}) / Seg_d_mm "
        f"- Seg_hc_mm * (P_top_Z_mm - {O_SEG_Z:.6f}) / Seg_d_mm",
    )
    ctrl.setExpression(
        "Q_seg_Z_mm",
        f"{O_SEG_Z:.6f} + Seg_ac_mm * (P_top_Z_mm - {O_SEG_Z:.6f}) / Seg_d_mm "
        f"+ Seg_hc_mm * (P_top_X_mm - {O_SEG_X:.6f}) / Seg_d_mm",
    )
    ctrl.setExpression("Angulo_Seguidor_Graus", f"-atan2(Q_seg_Z_mm - {O_SEG_Z:.6f}; Q_seg_X_mm - {O_SEG_X:.6f}) / 1 deg")
    ctrl.setExpression("Angulo_Tirante_Graus", "atan2(Q_seg_X_mm - P_top_X_mm; Q_seg_Z_mm - P_top_Z_mm) / 1 deg")

    for name in MOVING_GROUPS["O2"]:
        obj = doc.getObject(name)
        if obj:
            obj.Placement = App.Placement(App.Vector(O2_X, 0.0, O2_Z), App.Rotation(App.Vector(0, 1, 0), 10.0))
            obj.setExpression(".Placement.Rotation.Angle", "-Controlador_Cinematico.Angulo_Manivela_Graus * 1 deg")

    for name in MOVING_GROUPS["L3"]:
        obj = doc.getObject(name)
        if obj:
            obj.Placement = App.Placement(App.Vector(0.0, 0.0, 0.0), App.Rotation(App.Vector(0, 1, 0), 10.0))
            obj.setExpression(".Placement.Base.x", "Controlador_Cinematico.Ax_mm * 1 mm")
            obj.setExpression(".Placement.Base.z", "Controlador_Cinematico.Az_mm * 1 mm")
            obj.setExpression(".Placement.Rotation.Angle", "-Controlador_Cinematico.Angulo_Biela_L3_Graus * 1 deg")

    for name in MOVING_GROUPS["L4"]:
        obj = doc.getObject(name)
        if obj:
            obj.Placement = App.Placement(App.Vector(O4_X, 0.0, O4_Z), App.Rotation(App.Vector(0, 1, 0), 10.0))
            obj.setExpression(".Placement.Rotation.Angle", "-Controlador_Cinematico.Angulo_Balancim_L4_Graus * 1 deg")

    for name in MOVING_GROUPS["L5"]:
        obj = doc.getObject(name)
        if obj:
            obj.Placement = App.Placement(App.Vector(0.0, 0.0, 0.0), App.Rotation(App.Vector(0, 1, 0), 10.0))
            obj.setExpression(".Placement.Base.x", "Controlador_Cinematico.Bx_mm * 1 mm")
            obj.setExpression(".Placement.Base.z", "Controlador_Cinematico.Bz_mm * 1 mm")
            obj.setExpression(".Placement.Rotation.Angle", "-Controlador_Cinematico.Angulo_Garfo_L5_Graus * 1 deg")

    for name in MOVING_GROUPS["O5"]:
        obj = doc.getObject(name)
        if obj:
            obj.Placement = App.Placement(App.Vector(0.0, 0.0, 0.0), App.Rotation(App.Vector(0, 1, 0), 0.0))
            obj.setExpression(".Placement.Base.z", "Controlador_Cinematico.Posicao_Pistao_O5_Z_mm * 1 mm")

    obj_ej = doc.getObject("Alavanca_Ejetora")
    if obj_ej:
        obj_ej.Placement = App.Placement(App.Vector(O_EXT_X, 0.0, O_EXT_Z), App.Rotation(App.Vector(0, 1, 0), 1.0))
        obj_ej.setExpression(".Placement.Rotation.Angle", "Controlador_Cinematico.Angulo_Ejetor_Graus * 1 deg")

    obj_seg = doc.getObject("Alavanca_Seguidora")
    if obj_seg:
        obj_seg.Placement = App.Placement(App.Vector(O_SEG_X, 0.0, O_SEG_Z), App.Rotation(App.Vector(0, 1, 0), 1.0))
        obj_seg.setExpression(".Placement.Rotation.Angle", "Controlador_Cinematico.Angulo_Seguidor_Graus * 1 deg")

    obj_rod = doc.getObject("Tirante_Extracao")
    if obj_rod:
        obj_rod.Placement = App.Placement(App.Vector(SEG_Q0_X, 0.0, SEG_Q0_Z), App.Rotation(App.Vector(0, 1, 0), 0.0))
        obj_rod.setExpression(".Placement.Base.x", "Controlador_Cinematico.Q_seg_X_mm * 1 mm")
        obj_rod.setExpression(".Placement.Base.z", "Controlador_Cinematico.Q_seg_Z_mm * 1 mm")
        obj_rod.setExpression(".Placement.Rotation.Angle", "Controlador_Cinematico.Angulo_Tirante_Graus * 1 deg")


def set_pose(doc: App.Document, theta2_deg: float, recompute: bool = True) -> dict:
    ang = float(theta2_deg) % 360.0
    k = solve_kinematics(ang)
    ctrl = doc.getObject("Controlador_Cinematico")
    if ctrl and hasattr(ctrl, "Angulo_Manivela_Graus"):
        ctrl.Angulo_Manivela_Graus = ang
        if recompute:
            doc.recompute()
    return k


# =========================================================================================
# 9. MATERIAIS NATIVOS (.FCMat) E ESTILO VISUAL
# =========================================================================================
LINEAR_ELASTIC_MODEL_UUID = "7b561d1d-fb9b-44f6-9da9-56a4f74d7536"
BASIC_RENDERING_MODEL_UUID = "f006c7e4-35b7-43d5-bbf9-c5d572309e6e"

ENGINEERING_MATERIALS = {
    "Aco_ABNT_1020": {
        "desc": "Aco carbono estrutural ABNT 1020 (barras chatas, chapas #18/#11, Metalon, volante)",
        "Density": "7850 kg/m^3",
        "YoungsModulus": "205000 MPa",
        "PoissonRatio": "0.30",
        "YieldStrength": "250 MPa",
        "UltimateTensileStrength": "420 MPa",
        "AmbientColor": "(0.22, 0.24, 0.27, 1.0)",
        "DiffuseColor": "(0.62, 0.66, 0.70, 1.0)",
        "SpecularColor": "(0.82, 0.85, 0.90, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.70",
        "Transparency": "0.00",
    },
    "Aco_SAE_1045": {
        "desc": "Aco medio carbono SAE 1045 (eixos O2 e 400rpm, L4, came, pistao, pinos e parafusos 8.8)",
        "Density": "7850 kg/m^3",
        "YoungsModulus": "210000 MPa",
        "PoissonRatio": "0.30",
        "YieldStrength": "450 MPa",
        "UltimateTensileStrength": "620 MPa",
        "AmbientColor": "(0.25, 0.27, 0.30, 1.0)",
        "DiffuseColor": "(0.72, 0.75, 0.80, 1.0)",
        "SpecularColor": "(0.92, 0.94, 0.98, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.86",
        "Transparency": "0.00",
    },
    "Aco_Mola_SAE_5160": {
        "desc": "Aco mola temperado/revenido SAE 5160 (navalha de corte 54-58 HRC e mola de retorno)",
        "Density": "7850 kg/m^3",
        "YoungsModulus": "210000 MPa",
        "PoissonRatio": "0.30",
        "YieldStrength": "1100 MPa",
        "UltimateTensileStrength": "1400 MPa",
        "AmbientColor": "(0.26, 0.14, 0.14, 1.0)",
        "DiffuseColor": "(0.78, 0.20, 0.20, 1.0)",
        "SpecularColor": "(0.94, 0.88, 0.88, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.88",
        "Transparency": "0.00",
    },
    "Ferro_Fundido_GG20": {
        "desc": "Ferro fundido cinzento GG-20 (carcaca motor/redutor comercial, mancais P204/F204, polias)",
        "Density": "7200 kg/m^3",
        "YoungsModulus": "105000 MPa",
        "PoissonRatio": "0.26",
        "YieldStrength": "180 MPa",
        "UltimateTensileStrength": "220 MPa",
        "AmbientColor": "(0.14, 0.16, 0.18, 1.0)",
        "DiffuseColor": "(0.36, 0.40, 0.44, 1.0)",
        "SpecularColor": "(0.42, 0.44, 0.46, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.32",
        "Transparency": "0.00",
    },
    "Bronze_TM23_SAE_660": {
        "desc": "Bronze mancais TM-23 / SAE 660 grafitado (buchas padronizadas de catalogo)",
        "Density": "8930 kg/m^3",
        "YoungsModulus": "100000 MPa",
        "PoissonRatio": "0.34",
        "YieldStrength": "140 MPa",
        "UltimateTensileStrength": "240 MPa",
        "AmbientColor": "(0.32, 0.24, 0.09, 1.0)",
        "DiffuseColor": "(0.82, 0.62, 0.24, 1.0)",
        "SpecularColor": "(0.96, 0.84, 0.46, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.82",
        "Transparency": "0.00",
    },
    "UHMW_PE": {
        "desc": "Polietileno de Ultra-Alto Peso Molecular (tiras de desgaste autolubrificantes da guia)",
        "Density": "935 kg/m^3",
        "YoungsModulus": "750 MPa",
        "PoissonRatio": "0.46",
        "YieldStrength": "22 MPa",
        "UltimateTensileStrength": "40 MPa",
        "AmbientColor": "(0.42, 0.44, 0.41, 1.0)",
        "DiffuseColor": "(0.94, 0.96, 0.92, 1.0)",
        "SpecularColor": "(0.42, 0.44, 0.42, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.30",
        "Transparency": "0.00",
    },
    "Borracha_NBR_70": {
        "desc": "Elastomero NBR 70 Shore A (correia em V perfil A e aneis O-ring 10x1,8 mm)",
        "Density": "1200 kg/m^3",
        "YoungsModulus": "10 MPa",
        "PoissonRatio": "0.49",
        "YieldStrength": "12 MPa",
        "UltimateTensileStrength": "18 MPa",
        "AmbientColor": "(0.05, 0.05, 0.06, 1.0)",
        "DiffuseColor": "(0.14, 0.14, 0.16, 1.0)",
        "SpecularColor": "(0.10, 0.10, 0.10, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.08",
        "Transparency": "0.00",
    },
    "Policarbonato_NR12": {
        "desc": "Policarbonato compacto transparente 2,0 mm (visor frontal NR-12)",
        "Density": "1200 kg/m^3",
        "YoungsModulus": "2350 MPa",
        "PoissonRatio": "0.37",
        "YieldStrength": "60 MPa",
        "UltimateTensileStrength": "65 MPa",
        "AmbientColor": "(0.24, 0.38, 0.44, 1.0)",
        "DiffuseColor": "(0.55, 0.82, 0.95, 1.0)",
        "SpecularColor": "(0.96, 0.98, 1.00, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.92",
        "Transparency": "0.75",
    },
    "Endocarpo_Baru_Simulado": {
        "desc": "Corpo de prova ilustrativo de endocarpo lenhoso de baru (30x50x40 mm)",
        "Density": "1100 kg/m^3",
        "YoungsModulus": "3500 MPa",
        "PoissonRatio": "0.35",
        "YieldStrength": "45 MPa",
        "UltimateTensileStrength": "60 MPa",
        "AmbientColor": "(0.22, 0.14, 0.07, 1.0)",
        "DiffuseColor": "(0.55, 0.35, 0.18, 1.0)",
        "SpecularColor": "(0.22, 0.16, 0.10, 1.0)",
        "EmissiveColor": "(0.00, 0.00, 0.00, 1.0)",
        "Shininess": "0.18",
        "Transparency": "0.35",
    },
}

PART_MATERIAL_ASSIGNMENTS = {
    "Chapa_Base_Estrutural": "Aco_ABNT_1020",
    "Portico_Estrutural_Traseiro": "Aco_ABNT_1020",
    "Portico_Estrutural_Frontal": "Aco_ABNT_1020",
    "Espacadores_Transversais_Portico": "Aco_SAE_1045",
    "Suporte_Baru_Cantoneira": "Aco_ABNT_1020",
    "Guia_Pistao_Chapa_U": "Aco_ABNT_1020",
    "Parafusos_Guia_Pistao_M8": "Aco_SAE_1045",
    "Tiras_Desgaste_UHMW_5mm": "UHMW_PE",
    "Buchas_Catalogo_Estator": "Bronze_TM23_SAE_660",
    "Pino_Eixo_O4": "Aco_SAE_1045",
    "Aneis_Retencao_ORing_O4": "Borracha_NBR_70",
    "Eixo_Principal_O2_20rpm": "Aco_SAE_1045",
    "Elo2_Manivela_L2": "Aco_SAE_1045",
    "Came_Extrator_O2": "Aco_SAE_1045",
    "Buchas_Catalogo_A": "Bronze_TM23_SAE_660",
    "Pino_Eixo_A": "Aco_SAE_1045",
    "Aneis_Retencao_ORing_A": "Borracha_NBR_70",
    "Elo3_Biela_L3": "Aco_ABNT_1020",
    "Buchas_Catalogo_L3": "Bronze_TM23_SAE_660",
    "Elo4_Balancim_L4": "Aco_SAE_1045",
    "Buchas_Catalogo_L4": "Bronze_TM23_SAE_660",
    "Elo5_Garfo_Duplo_L5": "Aco_ABNT_1020",
    "Buchas_Catalogo_L5": "Bronze_TM23_SAE_660",
    "Pino_Eixo_B": "Aco_SAE_1045",
    "Aneis_Retencao_ORing_B": "Borracha_NBR_70",
    "Pistao_Embolo_Quadrado": "Aco_SAE_1045",
    "Navalha_Corte_SAE5160": "Aco_Mola_SAE_5160",
    "Parafusos_Fixacao_Navalha_M6": "Aco_SAE_1045",
    "Bucha_Catalogo_O5": "Bronze_TM23_SAE_660",
    "Pino_Eixo_O5": "Aco_SAE_1045",
    "Aneis_Retencao_ORing_O5": "Borracha_NBR_70",
    "Motor_Eletrico_WEG_05cv_IEC71": "Ferro_Fundido_GG20",
    "Polia_Motora_D75": "Ferro_Fundido_GG20",
    "Polia_Movida_D325": "Ferro_Fundido_GG20",
    "Correia_V_Perfil_A": "Borracha_NBR_70",
    "Volante_Inercia_Aco": "Aco_ABNT_1020",
    "Eixo_Intermediario_400rpm": "Aco_SAE_1045",
    "Mancais_Rolamento_P204_F204": "Ferro_Fundido_GG20",
    "Redutor_Helicoidal_20_1": "Ferro_Fundido_GG20",
    "Base_Tensora_Motor": "Aco_ABNT_1020",
    "Quadro_Tubular_Metalon_20x20": "Aco_ABNT_1020",
    "Sapatas_Ancoragem_Piso": "Aco_ABNT_1020",
    "Carenagem_Chapa_Galvanizada": "Aco_ABNT_1020",
    "Visor_Policarbonato_NR12": "Policarbonato_NR12",
    "Calha_Alimentacao_Segura_NR12": "Aco_ABNT_1020",
    "Reservatorio_Alimentacao_Chapa": "Aco_ABNT_1020",
    "Parafusos_Fixacao_Gabinete_M6": "Aco_SAE_1045",
    "Calha_Descarga_Chapa": "Aco_ABNT_1020",
    "Reservatorio_Chapa_Coleta": "Aco_ABNT_1020",
    "Suporte_Eixo_Ejetor_NR12": "Aco_ABNT_1020",
    "Alavanca_Seguidora": "Aco_SAE_1045",
    "Tirante_Extracao": "Aco_ABNT_1020",
    "Alavanca_Ejetora": "Aco_ABNT_1020",
    "Mola_Retorno": "Aco_Mola_SAE_5160",
    "Baru_Simulado_30x50x40": "Endocarpo_Baru_Simulado",
}


def assign_native_freecad_materials(doc: App.Document) -> dict[str, str]:
    import Materials
    mgr = Materials.MaterialManager()
    by_name = {m.Name: m for m in mgr.Materials.values()}
    resolved = {}
    for mat_name, spec in ENGINEERING_MATERIALS.items():
        existing = by_name.get(mat_name)
        if existing and (BASIC_RENDERING_MODEL_UUID in existing.AppearanceModels):
            mat_obj = existing
        else:
            mat_obj = Materials.Material()
            mat_obj.Name = mat_name
            mat_obj.Description = spec["desc"]
            mat_obj.addPhysicalModel(LINEAR_ELASTIC_MODEL_UUID)
            for k in ("Density", "YoungsModulus", "PoissonRatio", "YieldStrength", "UltimateTensileStrength"):
                mat_obj.setPhysicalValue(k, spec[k])
            mat_obj.addAppearanceModel(BASIC_RENDERING_MODEL_UUID)
            for ak in ("AmbientColor", "DiffuseColor", "SpecularColor", "EmissiveColor", "Shininess", "Transparency"):
                mat_obj.setAppearanceValue(ak, spec[ak])
            card_path = os.path.expanduser(f"~/.local/share/FreeCAD/v1-1/Material/Prensa_Baru/{mat_name}.FCMat")
            if os.path.exists(card_path):
                os.remove(card_path)
            mgr.save("User", mat_obj, f"Prensa_Baru/{mat_name}.FCMat")
            mgr.refresh()
            mat_obj = mgr.Materials[mat_obj.UUID]
            by_name[mat_name] = mat_obj
        resolved[mat_name] = mat_obj

    assigned = {}
    for obj in doc.Objects:
        if obj.TypeId == "Part::Feature" and hasattr(obj, "ShapeMaterial"):
            mat_name = PART_MATERIAL_ASSIGNMENTS[obj.Name]
            obj.ShapeMaterial = resolved[mat_name]
            assigned[obj.Name] = mat_name

    user_cards_dir = os.path.expanduser("~/.local/share/FreeCAD/v1-1/Material/Prensa_Baru")
    if os.path.isdir(user_cards_dir):
        for dst_root in (
            "/home/guimentzer/Repos/dinmaq-2026/trabalho-final/materiais_freecad",
            "/home/guimentzer/vault/Dinâmica das Máquinas/Trabalho Final 1/materiais_freecad",
        ):
            os.makedirs(dst_root, exist_ok=True)
            for fname in os.listdir(user_cards_dir):
                if fname.endswith(".FCMat"):
                    shutil.copy2(os.path.join(user_cards_dir, fname), os.path.join(dst_root, fname))
    return assigned


FINISH_PRESETS = {
    "machined_steel": ((0.92, 0.94, 0.98), 0.86, 0.34),
    "bronze":         ((0.96, 0.84, 0.46), 0.82, 0.38),
    "satin_paint":    ((0.64, 0.68, 0.72), 0.58, 0.36),
    "cast_iron":      ((0.40, 0.42, 0.46), 0.30, 0.36),
    "galvanized":     ((0.78, 0.82, 0.86), 0.68, 0.42),
    "polycarbonate":  ((0.96, 0.98, 1.00), 0.92, 0.45),
    "uhmw":           ((0.42, 0.44, 0.42), 0.30, 0.44),
    "rubber":         ((0.10, 0.10, 0.10), 0.08, 0.30),
    "wood_baru":      ((0.24, 0.18, 0.10), 0.18, 0.40),
}

VISUAL_STYLE_REGISTRY: dict[str, tuple[tuple[float, float, float], int, str]] = {}


def infer_finish_preset(name: str) -> str:
    mat_name = PART_MATERIAL_ASSIGNMENTS.get(name, "Aco_ABNT_1020")
    if mat_name == "Bronze_TM23_SAE_660":
        return "bronze"
    if mat_name == "Ferro_Fundido_GG20":
        return "satin_paint" if "Motor" in name else "cast_iron"
    if mat_name == "Borracha_NBR_70":
        return "rubber"
    if mat_name == "Policarbonato_NR12":
        return "polycarbonate"
    if mat_name == "UHMW_PE":
        return "uhmw"
    if mat_name == "Endocarpo_Baru_Simulado":
        return "wood_baru"
    if "Carenagem" in name or "Calha_Descarga" in name:
        return "galvanized"
    if any(k in name for k in ("Eixo_", "Pino_", "Pistao", "Navalha", "Volante", "Parafusos", "Espacadores", "Tirante", "Mola")):
        return "machined_steel"
    return "satin_paint"


def apply_visual_style(obj, rgb: tuple[float, float, float], transparency: int = 0, finish: str | None = None) -> None:
    if finish is None:
        finish = infer_finish_preset(obj.Name)
    VISUAL_STYLE_REGISTRY[obj.Name] = (rgb, int(transparency), finish)
    try:
        if App.GuiUp and hasattr(obj, "ViewObject") and obj.ViewObject:
            vo = obj.ViewObject
            vo.Visibility = True
            spec, shin, amb_k = FINISH_PRESETS.get(finish, FINISH_PRESETS["satin_paint"])
            if hasattr(vo, "ShapeAppearance"):
                m = App.Material()
                m.DiffuseColor = (float(rgb[0]), float(rgb[1]), float(rgb[2]), 1.0)
                m.AmbientColor = (float(rgb[0] * amb_k), float(rgb[1] * amb_k), float(rgb[2] * amb_k), 1.0)
                m.SpecularColor = (float(spec[0]), float(spec[1]), float(spec[2]), 1.0)
                m.Shininess = float(shin)
                m.Transparency = float(transparency) / 100.0
                vo.ShapeAppearance = (m,)
            vo.ShapeColor = rgb
            vo.Transparency = int(transparency)
            if hasattr(vo, "DisplayMode") and "Flat Lines" in vo.listDisplayModes():
                vo.DisplayMode = "Flat Lines"
            if hasattr(vo, "LineColor"):
                vo.LineColor = (0.12, 0.14, 0.16)
            if hasattr(vo, "LineWidth"):
                vo.LineWidth = 1.5
    except Exception:
        pass


def reapply_all_visual_styles(doc: App.Document) -> None:
    for name, (rgb, transp, finish) in VISUAL_STYLE_REGISTRY.items():
        obj = doc.getObject(name)
        if obj:
            apply_visual_style(obj, rgb, transp, finish)


def configure_all_gui_view_providers(doc: App.Document) -> None:
    if not App.GuiUp:
        return
    try:
        import FreeCADGui as Gui
        for o in doc.Objects:
            vo = getattr(o, "ViewObject", None)
            if not vo:
                continue
            if o.TypeId in ("App::Origin", "App::Line", "App::Plane", "App::Point"):
                vo.Visibility = False
            elif o.TypeId in ("App::Part", "Part::Feature"):
                vo.Visibility = True
        gdoc = Gui.getDocument(doc.Name)
        if gdoc and gdoc.ActiveView:
            gdoc.ActiveView.viewIsometric()
            Gui.SendMsgToMainWindow("ViewFit")
    except Exception:
        pass


def add_part_feature(doc: App.Document, parent_part, name: str, label: str,
                     shape: Part.Shape, rgb: tuple[float, float, float], transparency: int = 0):
    obj = doc.addObject("Part::Feature", name)
    obj.Label = label
    obj.Shape = shape
    parent_part.addObject(obj)
    apply_visual_style(obj, rgb, transparency)
    return obj


def build_simulated_baru_nut(x_c: float = 0.0, y_c: float = 0.0, z_c: float = Z_BARU_CENTER) -> Part.Shape:
    sph = Part.makeSphere(1.0)
    mat = App.Matrix()
    mat.A11 = 0.5 * BARU_LEN_X
    mat.A22 = 0.5 * BARU_WID_Y
    mat.A33 = 0.5 * BARU_DEP_Z
    mat.A14, mat.A24, mat.A34 = x_c, y_c, z_c
    return sph.transformGeometry(mat)


# =========================================================================================
# 10. MONTAGEM COMPLETA DO DOCUMENTO FREECAD (prensa_baru_motorizada_v1)
# =========================================================================================
def build_prensa_baru_motorizada_v1(initial_theta2_deg: float = 75.0) -> App.Document:
    if DOC_NAME in App.listDocuments():
        App.closeDocument(DOC_NAME)

    doc = App.newDocument(DOC_NAME)
    doc.Label = "Prensa de Baru Motorizada 20 RPM - K=1.5 + Volante 400 RPM + Came Extrator (Vertente B)"

    C_STEEL_STRUCT = (0.28, 0.32, 0.38)
    C_BASE_PLATE   = (0.22, 0.25, 0.30)
    C_CANTONEIRA   = (0.42, 0.46, 0.52)
    C_RESERVOIR    = (0.24, 0.62, 0.44)
    C_EXT_NR12     = (0.92, 0.55, 0.12)
    C_UHMW         = (0.94, 0.96, 0.92)
    C_BRONZE       = (0.82, 0.62, 0.24)
    C_PIN_1045     = (0.72, 0.75, 0.78)
    C_CIRCLIP      = (0.20, 0.22, 0.25)
    C_L4_ROCKER    = (0.16, 0.55, 0.32)
    C_L5_FORK      = (0.78, 0.22, 0.20)
    C_L3_COUPLER   = (0.18, 0.48, 0.82)
    C_L2_CRANK     = (0.88, 0.52, 0.14)
    C_CAM_STEEL    = (0.80, 0.32, 0.18)
    C_GRIP_RUBBER  = (0.15, 0.15, 0.16)
    C_RAM_1045     = (0.58, 0.62, 0.68)
    C_BLADE_5160   = (0.85, 0.18, 0.18)
    C_METALON      = (0.62, 0.66, 0.70)
    C_CAB_SHEET    = (0.78, 0.80, 0.83)
    C_POLYCARB     = (0.55, 0.82, 0.95)
    C_CHUTE_NR12   = (0.90, 0.72, 0.15)
    C_BARU_NUT     = (0.55, 0.35, 0.18)
    C_WEG_BLUE     = (0.05, 0.32, 0.62)
    C_CAST_GREY    = (0.36, 0.40, 0.44)
    C_FLYWHEEL     = (0.26, 0.46, 0.62)

    # SUBCONJUNTO 01: Estator interno
    sub01 = doc.addObject("App::Part", "Subconjunto_01_Estrutura_Interna")
    sub01.Label = "01_Porticos_360deg_Guia_U_e_Cantoneira"
    base_sh = build_base_plate_with_drop_window()
    portal_rear_sh = build_structural_portal(Y_PORTAL_R_MIN, Y_PORTAL_R_MAX, is_front=False)
    portal_front_sh = build_structural_portal(Y_PORTAL_F_MIN, Y_PORTAL_F_MAX, is_front=True)
    spacers_sh = build_portal_spacers_motorized()
    cantoneira_sh = build_cantoneira_baru_support()
    guide_u_sh, uhmw_guide_sh, u_bolts_sh = build_bolted_u_guide_and_uhmw()

    b_o4_r = make_bushing_y(O4_X, O4_Z, 12.04, 14.00, Y_PORTAL_R_MIN, Y_PORTAL_R_MAX)
    b_o4_f = make_bushing_y(O4_X, O4_Z, 12.04, 14.00, Y_PORTAL_F_MIN, Y_PORTAL_F_MAX)
    b_o2_r = make_bushing_y(O2_X, O2_Z, 20.04, 23.00, Y_PORTAL_R_MIN, Y_PORTAL_R_MAX)
    bushings_stator_sh = b_o4_r.fuse([b_o4_f, b_o2_r]).removeSplitter()

    pin_o4_core, oring_o4_sh = make_oring_pin_y(O4_X, O4_Z, 11.96, -47.80, 35.10, groove_ys=(-45.95, 33.25))
    pin_o4_sh = pin_o4_core.fuse([
        make_bushing_y(O4_X, O4_Z, 12.10, 19.00, -44.70, -43.10),
        make_bushing_y(O4_X, O4_Z, 12.10, 19.00, 30.40, 32.00),
    ]).removeSplitter()

    add_part_feature(doc, sub01, "Chapa_Base_Estrutural", "Chapa de Mesa Estrutural 1/4 pol (340x100 mm)", base_sh, C_BASE_PLATE)
    add_part_feature(doc, sub01, "Portico_Estrutural_Traseiro", "Portico Traseiro Soldado (2x1/4 pol)", portal_rear_sh, C_STEEL_STRUCT)
    add_part_feature(doc, sub01, "Portico_Estrutural_Frontal", "Portico Frontal Soldado (360 deg livre, s/ batentes)", portal_front_sh, C_STEEL_STRUCT)
    add_part_feature(doc, sub01, "Espacadores_Transversais_Portico", "4x Espacadores Tubulares M10 Realocados", spacers_sh, C_PIN_1045)
    add_part_feature(doc, sub01, "Suporte_Baru_Cantoneira", "Suporte Cantoneira V 90 graus + Pes Dobrados", cantoneira_sh, C_CANTONEIRA)
    add_part_feature(doc, sub01, "Guia_Pistao_Chapa_U", "Guia Linear Chapa U Parafusavel 4x M8", guide_u_sh, C_STEEL_STRUCT)
    add_part_feature(doc, sub01, "Parafusos_Guia_Pistao_M8", "4x Parafusos Sextavados M8x20 + Porcas", u_bolts_sh, C_PIN_1045)
    add_part_feature(doc, sub01, "Tiras_Desgaste_UHMW_5mm", "4x Tiras Planas Substituiveis de UHMW", uhmw_guide_sh, C_UHMW)
    add_part_feature(doc, sub01, "Buchas_Catalogo_Estator", "4x Buchas de Catalogo O4 (12x14) e O2 (20x23)", bushings_stator_sh, C_BRONZE)
    add_part_feature(doc, sub01, "Pino_Eixo_O4", "Pino Liso D12 mm c/ Canaletas O-Ring de O4", pin_o4_sh, C_PIN_1045)
    add_part_feature(doc, sub01, "Aneis_Retencao_ORing_O4", "2x Aneis O-Ring NBR 70 (10x1.8 mm) de O4", oring_o4_sh, C_GRIP_RUBBER)

    # SUBCONJUNTO 02: Eixo O2 (20 RPM) + Manivela L2 (K=1.5) + Came Extrator 3-4-5
    sub02 = doc.addObject("App::Part", "Subconjunto_02_Manivela_O2_e_Came")
    sub02.Label = "02_Eixo_O2_20rpm_Manivela_L2_e_Came_Extrator"
    l2_parts = build_l2_crank_and_shaft_local()
    ext_parts = build_cam_extractor_system_local()
    add_part_feature(doc, sub02, "Eixo_Principal_O2_20rpm", "Eixo Principal O2 D20 mm (20 RPM, SAE 1045)", l2_parts["Eixo_Principal_O2_20rpm"], C_PIN_1045)
    add_part_feature(doc, sub02, "Elo2_Manivela_L2", "Manivela L2 = 28.98 mm (K = 1.5 Grashof Classe I)", l2_parts["Elo2_Manivela_L2"], C_L2_CRANK)
    add_part_feature(doc, sub02, "Came_Extrator_O2", "Came de Disco 3-4-5 do Extrator Automatico (R_base=52 mm)", ext_parts["cam"], C_CAM_STEEL)
    add_part_feature(doc, sub02, "Buchas_Catalogo_A", "Bucha Padrao 12x14 mm da Junta A", l2_parts["Buchas_Catalogo_A"], C_BRONZE)
    add_part_feature(doc, sub02, "Pino_Eixo_A", "Pino Liso D12 mm c/ Canaletas O-Ring da Junta A", l2_parts["Pino_Eixo_A"], C_PIN_1045)
    add_part_feature(doc, sub02, "Aneis_Retencao_ORing_A", "2x Aneis O-Ring NBR 70 (10x1.8 mm) da Junta A", l2_parts["Aneis_Retencao_ORing_A"], C_GRIP_RUBBER)

    # SUBCONJUNTO 03: Biela L3 (57.9555 mm)
    sub03 = doc.addObject("App::Part", "Subconjunto_03_Biela_Acopladora_L3")
    sub03.Label = "03_Elo3_Biela_Acopladora_L3 (57.96 mm)"
    l3_bar_sh = make_rounded_bar_xz(L3, 24.00, Y_L3_MIN, Y_L3_MAX, d_hole1=14.04, d_hole2=14.04)
    bushings_l3_sh = make_bushing_y(0.0, 0.0, 12.04, 14.00, Y_L3_MIN + 0.05, Y_L3_MAX - 0.05).fuse(
        make_bushing_y(L3, 0.0, 12.04, 14.00, Y_L3_MIN + 0.05, Y_L3_MAX - 0.05)
    ).removeSplitter()
    add_part_feature(doc, sub03, "Elo3_Biela_L3", "Biela L3 = 57.96 mm (Barra Chata 1x1/4 pol)", l3_bar_sh, C_L3_COUPLER)
    add_part_feature(doc, sub03, "Buchas_Catalogo_L3", "2x Buchas Padrao 12x14 mm da Biela L3", bushings_l3_sh, C_BRONZE)

    # SUBCONJUNTO 04: Balancim L4 (111.9615 mm)
    sub04 = doc.addObject("App::Part", "Subconjunto_04_Balancim_Superior_L4")
    sub04.Label = "04_Elo4_Balancim_Principal_L4 (111.96 mm)"
    l4_bar_sh = make_rounded_bar_xz(L4, 31.75, -6.35, 6.35, d_hole1=14.04, d_hole2=14.04)
    bushings_l4_sh = make_bushing_y(0.0, 0.0, 12.04, 14.00, -6.30, 6.30).fuse(
        make_bushing_y(L4, 0.0, 12.04, 14.00, -6.30, 6.30)
    ).removeSplitter()
    add_part_feature(doc, sub04, "Elo4_Balancim_L4", "Balancim L4 = 111.96 mm (Barra Chata 1.1/2x1/2 pol)", l4_bar_sh, C_L4_ROCKER)
    add_part_feature(doc, sub04, "Buchas_Catalogo_L4", "2x Buchas Padrao 12x14 mm do Balancim L4", bushings_l4_sh, C_BRONZE)

    # SUBCONJUNTO 05: Garfo Duplo L5 e Pino B
    sub05 = doc.addObject("App::Part", "Subconjunto_05_Garfo_Prensa_L5")
    sub05.Label = "05_Elo5_Garfo_Duplo_L5 (111.96 mm)"
    l5_fork_sh = make_rounded_bar_xz(L5, 31.75, -13.70, -7.35, d_hole1=14.04, d_hole2=14.04).fuse(
        make_rounded_bar_xz(L5, 31.75, 7.35, 13.70, d_hole1=14.04, d_hole2=14.04)
    ).removeSplitter()
    bushings_l5_sh = make_bushing_y(0.0, 0.0, 12.04, 14.00, -13.65, -7.40).fuse([
        make_bushing_y(0.0, 0.0, 12.04, 14.00, 7.40, 13.65),
        make_bushing_y(L5, 0.0, 12.04, 14.00, -13.65, -7.40),
        make_bushing_y(L5, 0.0, 12.04, 14.00, 7.40, 13.65),
    ]).removeSplitter()
    pin_b_core, oring_b_sh = make_oring_pin_y(0.0, 0.0, 11.96, -36.40, 18.50, groove_ys=(-35.20, 16.65))
    pin_b_sh = pin_b_core.fuse([
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -7.30, -6.40),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, 6.40, 7.30),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -27.10, -13.75),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, 13.75, 15.60),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -34.05, -33.55),
    ]).removeSplitter()
    add_part_feature(doc, sub05, "Elo5_Garfo_Duplo_L5", "Garfo Duplo L5 = 111.96 mm", l5_fork_sh, C_L5_FORK)
    add_part_feature(doc, sub05, "Buchas_Catalogo_L5", "4x Buchas 12x14 mm do Garfo L5", bushings_l5_sh, C_BRONZE)
    add_part_feature(doc, sub05, "Pino_Eixo_B", "Pino Liso D12 mm c/ Canaletas O-Ring da Junta B", pin_b_sh, C_PIN_1045)
    add_part_feature(doc, sub05, "Aneis_Retencao_ORing_B", "2x Aneis O-Ring NBR 70 (10x1.8 mm) da Junta B", oring_b_sh, C_GRIP_RUBBER)

    # SUBCONJUNTO 06: Pistão + Navalha SAE 5160
    sub06 = doc.addObject("App::Part", "Subconjunto_06_Pistao_e_Navalha")
    sub06.Label = "06_Pistao_Soldado_1pol_e_Navalha_SAE5160"
    ram_sh, blade_sh, m6_sh, bush_o5_sh = build_piston_and_blade_local()
    pin_o5_core, oring_o5_sh = make_oring_pin_y(0.0, 0.0, 11.96, -18.50, 18.50, groove_ys=(-16.65, 16.65))
    pin_o5_sh = pin_o5_core.fuse([
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -7.30, -6.40),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, 6.40, 7.30),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -15.60, -13.75),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, 13.75, 15.60),
    ]).removeSplitter()
    add_part_feature(doc, sub06, "Pistao_Embolo_Quadrado", "Embolo Barra Quadrada 1x1 pol Soldado", ram_sh, C_RAM_1045)
    add_part_feature(doc, sub06, "Navalha_Corte_SAE5160", "Navalha Reta Cunha 30 graus (SAE 5160)", blade_sh, C_BLADE_5160)
    add_part_feature(doc, sub06, "Parafusos_Fixacao_Navalha_M6", "2x Parafusos Sextavados M6x20 + Porcas", m6_sh, C_PIN_1045)
    add_part_feature(doc, sub06, "Bucha_Catalogo_O5", "Bucha 12x14 mm do Olhal O5", bush_o5_sh, C_BRONZE)
    add_part_feature(doc, sub06, "Pino_Eixo_O5", "Pino Liso D12 mm c/ Canaletas O-Ring de O5", pin_o5_sh, C_PIN_1045)
    add_part_feature(doc, sub06, "Aneis_Retencao_ORing_O5", "2x Aneis O-Ring NBR 70 de O5", oring_o5_sh, C_GRIP_RUBBER)

    # SUBCONJUNTO 07: Trem de Potência Motorizado (Motor WEG, Correia A, Volante 400 RPM, Redutor 20:1)
    sub07_drv = doc.addObject("App::Part", "Subconjunto_07_Trem_Potencia_20rpm")
    sub07_drv.Label = "07_Motor_WEG_05cv_Polias_Volante_400rpm_e_Redutor_20_1"
    drv = build_drivetrain_components()
    add_part_feature(doc, sub07_drv, "Motor_Eletrico_WEG_05cv_IEC71", "Motor Eletrico WEG W22 0.5 cv 4P 1730 rpm IEC 71", drv["motor"], C_WEG_BLUE)
    add_part_feature(doc, sub07_drv, "Polia_Motora_D75", "Polia Motora Comercial Perfil A D75 mm (1730 rpm)", drv["polia_motora"], C_CAST_GREY)
    add_part_feature(doc, sub07_drv, "Polia_Movida_D325", "Polia Movida Comercial Perfil A D325 mm (399.2 rpm)", drv["polia_movida"], C_CAST_GREY)
    add_part_feature(doc, sub07_drv, "Correia_V_Perfil_A", "Correia Trapezoidal em V Perfil A (A-56)", drv["correia"], C_GRIP_RUBBER)
    add_part_feature(doc, sub07_drv, "Volante_Inercia_Aco", "Volante de Inercia em Aro Aco ABNT 1020 (D300/220x40 mm @ 400 rpm)", drv["volante"], C_FLYWHEEL)
    add_part_feature(doc, sub07_drv, "Eixo_Intermediario_400rpm", "Eixo Intermediario D20 mm SAE 1045 (400 rpm)", drv["eixo_int"], C_PIN_1045)
    add_part_feature(doc, sub07_drv, "Mancais_Rolamento_P204_F204", "2x Mancais F204 (O2) + 2x Mancais UCP204 (Eixo 400 rpm)", drv["mancais"], C_CAST_GREY)
    add_part_feature(doc, sub07_drv, "Redutor_Helicoidal_20_1", "Redutor Helicoidal Comercial 20:1 (eta=0.95)", drv["redutor"], C_CAST_GREY)
    add_part_feature(doc, sub07_drv, "Base_Tensora_Motor", "Base Tensora Deslizante do Motor (Chapa 1/4 pol)", drv["base_tensora"], C_STEEL_STRUCT)

    # SUBCONJUNTO 08: Cavalete 1,5 m Ampliado, NR-12, Moega, Coletor 12,3 L e Extrator Sincronizado
    sub08_cab = doc.addObject("App::Part", "Subconjunto_08_Cavalete_NR12_e_Extrator_Came")
    sub08_cab.Label = "08_Cavalete_NR12_Ampliado_Moega_Coletor_e_Extrator_Sincronizado"
    metalon_sh, panels_sh, poly_sh, chute_sh, feet_sh, cab_bolts_sh = build_enlarged_stand_and_nr12_cabinet()
    discharge_sh, reservoir_sh = build_sheet_metal_chute_and_reservoir()
    feed_hopper_sh = build_feeding_hopper_reservoir()

    add_part_feature(doc, sub08_cab, "Quadro_Tubular_Metalon_20x20", "Cavalete 1.50 m + Gabinete NR-12 Ampliado (Metalon 20x20)", metalon_sh, C_METALON)
    add_part_feature(doc, sub08_cab, "Sapatas_Ancoragem_Piso", "4x Sapatas de Piso 80x80x4.76 mm c/ 8 Furos D10.5 mm", feet_sh, C_BASE_PLATE)
    add_part_feature(doc, sub08_cab, "Carenagem_Chapa_Galvanizada", "Fechamento NR-12 c/ Aletas Ventilacao Motor (#18)", panels_sh, C_CAB_SHEET, transparency=55)
    add_part_feature(doc, sub08_cab, "Visor_Policarbonato_NR12", "Visor Frontal Transparente NR-12 (Policarbonato 2.0 mm)", poly_sh, C_POLYCARB, transparency=75)
    add_part_feature(doc, sub08_cab, "Calha_Alimentacao_Segura_NR12", "Calha Alimentacao Segura Y=0 (42x48 mm)", chute_sh, C_CHUTE_NR12)
    add_part_feature(doc, sub08_cab, "Reservatorio_Alimentacao_Chapa", "Moega Dedicada de Alimentacao (#18, 4x M6)", feed_hopper_sh, C_RESERVOIR)
    add_part_feature(doc, sub08_cab, "Parafusos_Fixacao_Gabinete_M6", "Parafusos M6/M8 do Visor, Calha e Moega", cab_bolts_sh, C_PIN_1045)
    add_part_feature(doc, sub08_cab, "Calha_Descarga_Chapa", "Calha Inclinada de Descarga Sob a Mesa (#18)", discharge_sh, C_CAB_SHEET)
    add_part_feature(doc, sub08_cab, "Reservatorio_Chapa_Coleta", "Reservatorio Frontal Removivel 12.3 L (#18)", reservoir_sh, C_RESERVOIR)
    add_part_feature(doc, sub08_cab, "Suporte_Eixo_Ejetor_NR12", "Mancais Eixo Ejetor + Pivo O_seg + Ancora Mola", ext_parts["stator_ext"], C_STEEL_STRUCT)
    add_part_feature(doc, sub08_cab, "Alavanca_Seguidora", "Alavanca Seguidora do Came c/ Rolete Ø19 mm", ext_parts["follower"], C_EXT_NR12)
    add_part_feature(doc, sub08_cab, "Tirante_Extracao", "Tirante Extrator c/ Furos Redondos Simples", ext_parts["tirante"], C_PIN_1045)
    add_part_feature(doc, sub08_cab, "Alavanca_Ejetora", "Alavanca Basculante Ejetora no Rasgo da Cantoneira (0..22 deg)", ext_parts["ejector"], C_EXT_NR12)
    add_part_feature(doc, sub08_cab, "Mola_Retorno", "Mola Helicoidal de Retorno do Seguidor do Came", ext_parts["spring"], C_CIRCLIP)

    # SUBCONJUNTO 09: Corpo de Prova Baru 30x50x40 mm
    sub09 = doc.addObject("App::Part", "Subconjunto_09_Simulacao_Baru")
    sub09.Label = "09_Corpo_Prova_Baru_Simulado_30x50x40 (Corte PMI = 4.75 mm)"
    baru_sh = build_simulated_baru_nut(0.0, 0.0, Z_BARU_CENTER)
    add_part_feature(doc, sub09, "Baru_Simulado_30x50x40", "Baru Simulado 30x50x40 mm na Cantoneira V 90 graus", baru_sh, C_BARU_NUT, transparency=35)

    # CONTROLADOR CINEMÁTICO PARAMÉTRICO
    ctrl = doc.addObject("App::FeaturePython", "Controlador_Cinematico")
    ctrl.Label = "00_CONTROLADOR_CINEMATICO (360 deg continuo + Came Extrator)"
    ctrl.addProperty("App::PropertyFloat", "Angulo_Manivela_Graus", "Cinematica", "Angulo da manivela theta2 (0..360 deg)").Angulo_Manivela_Graus = initial_theta2_deg
    ctrl.addProperty("App::PropertyFloat", "Theta_Mod_Graus", "Cinematica", "theta2 mod 360")
    ctrl.addProperty("App::PropertyFloat", "u_subida", "Extracao_Came", "Parametro normalizado subida 3-4-5")
    ctrl.addProperty("App::PropertyFloat", "u_retorno", "Extracao_Came", "Parametro normalizado retorno 3-4-5")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Ejetor_Graus", "Extracao_Came", "Angulo da pa ejetora (0..22 deg)")
    ctrl.addProperty("App::PropertyFloat", "P_top_X_mm", "Extracao_Came", "X pino P_top ejetor")
    ctrl.addProperty("App::PropertyFloat", "P_top_Z_mm", "Extracao_Came", "Z pino P_top ejetor")
    ctrl.addProperty("App::PropertyFloat", "Seg_d_mm", "Extracao_Came", "Distancia O_seg -> P_top")
    ctrl.addProperty("App::PropertyFloat", "Seg_ac_mm", "Extracao_Came", "Projecao cordal seguidor")
    ctrl.addProperty("App::PropertyFloat", "Seg_hc_mm", "Extracao_Came", "Altura cordal seguidor")
    ctrl.addProperty("App::PropertyFloat", "Q_seg_X_mm", "Extracao_Came", "X pino Q_seg seguidor")
    ctrl.addProperty("App::PropertyFloat", "Q_seg_Z_mm", "Extracao_Came", "Z pino Q_seg seguidor")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Seguidor_Graus", "Extracao_Came", "Rotacao alavanca seguidora")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Tirante_Graus", "Extracao_Came", "Rotacao tirante")
    ctrl.addProperty("App::PropertyFloat", "Ax_mm", "Cinematica_Interna", "X pino A")
    ctrl.addProperty("App::PropertyFloat", "Az_mm", "Cinematica_Interna", "Z pino A")
    ctrl.addProperty("App::PropertyFloat", "dA_mm", "Cinematica_Interna", "Distancia O4-A")
    ctrl.addProperty("App::PropertyFloat", "ac_mm", "Cinematica_Interna", "Projecao cordal")
    ctrl.addProperty("App::PropertyFloat", "hc_mm", "Cinematica_Interna", "Altura cordal")
    ctrl.addProperty("App::PropertyFloat", "Bx_mm", "Cinematica_Interna", "X joelho B")
    ctrl.addProperty("App::PropertyFloat", "Bz_mm", "Cinematica_Interna", "Z joelho B")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Biela_L3_Graus", "Cinematica", "Angulo L3")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Balancim_L4_Graus", "Cinematica", "Angulo L4")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Garfo_L5_Graus", "Cinematica", "Angulo L5")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Transmissao_Mu_Graus", "Cinematica", "Angulo mu")
    ctrl.addProperty("App::PropertyFloat", "Posicao_Pistao_O5_Z_mm", "Cinematica", "Z pino O5")
    ctrl.addProperty("App::PropertyFloat", "Posicao_Navalha_Z_tip_mm", "Cinematica", "Z ponta navalha")

    bind_native_freecad_materials_flag = True
    bind_native_kinematic_expressions(doc, ctrl)
    set_pose(doc, initial_theta2_deg, recompute=True)
    if bind_native_freecad_materials_flag:
        assign_native_freecad_materials(doc)
    reapply_all_visual_styles(doc)
    configure_all_gui_view_providers(doc)
    return doc


# =========================================================================================
# 11. VERIFICAÇÃO DE INTERFERÊNCIA BOOLEANA 360° + EXPORTAÇÃO (.FCStd & .step)
# =========================================================================================
def check_boolean_interference_all_pairs(
    doc: App.Document,
    tol_mm3: float = 1e-4,
    exclude_names: tuple[str, ...] = ("Baru_Simulado_30x50x40",),
) -> list[tuple[str, str, float]]:
    features = [
        o for o in doc.Objects
        if o.TypeId == "Part::Feature" and o.Name not in exclude_names
        and hasattr(o, "Shape") and not o.Shape.isNull()
    ]
    collisions = []
    n = len(features)
    for i in range(n):
        s1, bb1 = features[i].Shape, features[i].Shape.BoundBox
        for j in range(i + 1, n):
            s2 = features[j].Shape
            if not bb1.intersect(s2.BoundBox):
                continue
            vol = s1.common(s2).Volume
            if vol > tol_mm3:
                collisions.append((features[i].Name, features[j].Name, vol))
    return collisions


def check_baru_simulation_poses(doc: App.Document, tol_mm3: float = 1e-4) -> dict:
    baru_sh = doc.getObject("Baru_Simulado_30x50x40").Shape
    blade_sh_obj = doc.getObject("Navalha_Corte_SAE5160")
    machine_features = [
        o for o in doc.Objects
        if o.TypeId == "Part::Feature" and o.Name != "Baru_Simulado_30x50x40"
        and hasattr(o, "Shape") and not o.Shape.isNull()
    ]
    set_pose(doc, TH2_PMS_DEG, recompute=True)
    pms_cols = [(o.Name, baru_sh.common(o.Shape).Volume) for o in machine_features
                if baru_sh.BoundBox.intersect(o.Shape.BoundBox) and baru_sh.common(o.Shape).Volume > tol_mm3]

    set_pose(doc, TH2_PMI_DEG, recompute=True)
    pmi_other_cols = [(o.Name, baru_sh.common(o.Shape).Volume) for o in machine_features
                      if o.Name != "Navalha_Corte_SAE5160" and baru_sh.BoundBox.intersect(o.Shape.BoundBox)
                      and baru_sh.common(o.Shape).Volume > tol_mm3]

    cut_common = blade_sh_obj.Shape.common(baru_sh)
    verts_pts, _ = cut_common.tessellate(0.02)
    zs = [p.z for p in verts_pts] if verts_pts else [0.0]
    cut_depth = (max(zs) - min(zs)) if cut_common.Volume > 0.0 else 0.0
    return {
        "pms_clash_mm3": max((c[1] for c in pms_cols), default=0.0),
        "pms_collisions": pms_cols,
        "pmi_non_blade_clash_mm3": max((c[1] for c in pmi_other_cols), default=0.0),
        "pmi_non_blade_collisions": pmi_other_cols,
        "pmi_blade_cut_volume_mm3": cut_common.Volume,
        "pmi_blade_cut_depth_mm": cut_depth,
    }


def verify_and_export(doc: App.Document, primary_fcstd: str, primary_step: str,
                      mirror_fcstd: list[str], mirror_step: list[str]) -> dict:
    # Verifica colisao booleana completa ao longo de 360° (incluindo rampa do came 60°..150°)
    test_angles = [0.0, 60.0, 83.0, 106.0, 128.0, 150.0, 165.0, 220.0, 280.0, 345.0]
    poses_report = {}
    for ang in test_angles:
        k = set_pose(doc, ang, recompute=True)
        cols = check_boolean_interference_all_pairs(doc)
        poses_report[f"{ang:05.1f}deg"] = {
            "kinematics": k,
            "collisions": cols,
            "max_interference_mm3": max((c[2] for c in cols), default=0.0),
        }

    baru_rep = check_baru_simulation_poses(doc)
    set_pose(doc, 83.0, recompute=True)  # Pose ilustrativa com came no meio da subida e faca alta
    reapply_all_visual_styles(doc)
    configure_all_gui_view_providers(doc)

    features = [o for o in doc.Objects if o.TypeId == "Part::Feature"]
    subparts = [o for o in doc.Objects if o.TypeId == "App::Part"]
    mat_missing = [o.Name for o in features if not getattr(o, "ShapeMaterial", None)]

    os.makedirs(os.path.dirname(primary_fcstd), exist_ok=True)
    doc.saveAs(primary_fcstd)
    for dst in mirror_fcstd:
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(primary_fcstd, dst)

    os.makedirs(os.path.dirname(primary_step), exist_ok=True)
    Part.export(features, primary_step)
    for dst in mirror_step:
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(primary_step, dst)

    return {
        "subassembly_count": len(subparts),
        "part_count": len(features),
        "machine_part_count": len(features) - 1,
        "mat_missing": mat_missing,
        "poses": poses_report,
        "baru_3d_simulation": baru_rep,
        "machine_total_height_mm": max(o.Shape.BoundBox.ZMax for o in features),
        "feet_zmin_mm": doc.getObject("Sapatas_Ancoragem_Piso").Shape.BoundBox.ZMin,
        "solids_below_z0": [o.Name for o in features if o.Shape.BoundBox.ZMin < -1e-6],
    }


def run_full_build_and_export() -> dict:
    repo_dir = "/home/guimentzer/Repos/dinmaq-2026/trabalho-final"
    vault_dir = "/home/guimentzer/vault/Dinâmica das Máquinas/Trabalho Final 1"

    p_fcstd = os.path.join(repo_dir, "prensa_baru_motorizada_v1.FCStd")
    p_step = os.path.join(repo_dir, "prensa_baru_motorizada_v1.step")
    m_fcstd = [os.path.join(vault_dir, "prensa_baru_motorizada_v1.FCStd")]
    m_step = [os.path.join(vault_dir, "prensa_baru_motorizada_v1.step")]

    doc_built = build_prensa_baru_motorizada_v1(initial_theta2_deg=75.0)
    rep = verify_and_export(doc_built, p_fcstd, p_step, m_fcstd, m_step)

    src_py = os.path.join(repo_dir, "gerar_prensa_baru_motorizada_cad.py")
    dst_py = os.path.join(vault_dir, "gerar_prensa_baru_motorizada_cad.py")
    if os.path.exists(src_py) and os.path.abspath(src_py) != os.path.abspath(dst_py):
        shutil.copy2(src_py, dst_py)
    return rep


if __name__ == "__main__":
    rep = run_full_build_and_export()
    print("=" * 100)
    print(f"RELATÓRIO CAD 3D — {DOC_NAME}")
    print("=" * 100)
    print(f"• Subconjuntos: {rep['subassembly_count']} | Peças Máquina: {rep['machine_part_count']} (+1 Baru = {rep['part_count']})")
    print(f"• ShapeMaterial pendentes: {len(rep['mat_missing'])} {rep['mat_missing']}")
    print(f"• Altura Total: {rep['machine_total_height_mm']:.2f} mm | Sapatas ZMin={rep['feet_zmin_mm']:.2f} | <Z=0: {len(rep['solids_below_z0'])}")
    b = rep["baru_3d_simulation"]
    print(f"• Baru 30x50x40 PMS clash: {b['pms_clash_mm3']:.6f} mm³ | PMI non-blade clash: {b['pmi_non_blade_clash_mm3']:.6f} mm³ | Corte PMI: {b['pmi_blade_cut_depth_mm']:.4f} mm ({b['pmi_blade_cut_volume_mm3']:.2f} mm³)")
    for pname, pdata in rep["poses"].items():
        k = pdata["kinematics"]
        ce = k["cam_extractor"]
        print(f"  - {pname:8s}: Z_tip={k['z_tip']:7.2f} mm | mu={k['mu_deg']:5.2f}° | psi_ej={ce['psi_deg']:5.2f}° | Colisões={pdata['max_interference_mm3']:.6f} mm³ {pdata['collisions']}")
    print("=" * 100)
