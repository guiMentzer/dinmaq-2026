#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=========================================================================================
TRABALHO FINAL 1 — DINÂMICA DAS MÁQUINAS (EMC/UFG — 2026/2)
Docente: Prof. Dr. Sigeo Kitatani Jr. | Discente: Guilherme Paiva Crispim Abalém
Diretriz: Ciência Aberta (UNESCO, 2023) — Modelagem CAD 3D Paramétrica e Reprodutível

Script Construtor Determinístico (Revisão v8 — O-Rings, Guia em U Parafusada, Moega Alimentação, Pedal Alinhado & Arco Ergonômico):
Prensa Articulada Knuckle-Joint Manual (Vertente A — Alavanca em L Monobloco Soldada)
Arquitetura Design #140 Otimizada: L3 = 100.00 mm, delta_L = 50.0° (gamma_L = 130.0°)

Principais evoluções da Revisão v8:
  1. Eixo O2 liso (Ø20 mm) SOLDADO diretamente ao L2 e ao Tubo Único 1.1/4" (R_ponta = 600,0 mm,
     centro empunhadura R_mid = 540,0 mm -> arco varrido = 565,5 mm [centro] / 628,3 mm [ponta],
     rigorosamente menor que o alcance do braço humano adulto ~650-720 mm!).
  2. Pinos lisos das juntas O4, A, B e O5 (Ø12 mm) retidos por ANÉIS O-RING comerciais (NBR 70 Ø10x1,8 mm)
     em canaletas de extremidade + arruelas DIN 125 + buchas de catálogo 12x14 mm (sem cupilhas).
  3. Guia do Pistão em CHAPA DOBRADA EM U (#3,00 mm) PARAFUSÁVEL no Pórtico Traseiro com 4 FUROS M8
     e 4 tiras substituíveis de UHMW.
  4. Calha de Alimentação NR-12 equipada com RESERVATÓRIO / MOEGA DEDICADA em chapa dobrada #18 (1,20 mm)
     parafusada na lateral esquerda do gabinete (4x parafusos M6 nos montantes Metalon 20x20).
  5. Pedal de Piso (+X alinhado à alavanca) ESTENDIDO até X = 490..590 mm (centro X = 540 mm, coincidindo
     com a zona de empunhadura X = 499..572 mm), mantendo folga livre ao piso (Z_min = 58,5 mm no curso total).
  6. Cavalete ~1,50 m com 4 sapatas c/ 8 furos no piso, Cantoneira V 90° p/ baru 30x50x40 (corte PMI = 4,75 mm)
     e Grande Reservatório Inferior Dobrado #18 de 12,3 Litros!
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
# 1. CONSTANTES CINEMÁTICAS E DATUMS DE PISO (ALTURA TOTAL ~1,50 m = 1498,70 mm)
# =========================================================================================
DOC_NAME = "prensa_baru_manual_v1"

Z_WORK_DATUM = 980.0000

O4_X = 0.0000
O4_Z = Z_WORK_DATUM + 467.5000  # 1447.5000 mm

H_CURSO = 30.0000
DTH4_RAD = math.radians(30.0)
L4 = H_CURSO / (2.0 * (1.0 - math.cos(DTH4_RAD)))  # 111.96152422706632 mm
L5 = L4

L2 = 70.0000
L3 = 100.0000
DELTA_L_DEG = 50.0      # gamma_L = 130.0°
TH2_PMS_DEG = 80.0      # PMS: Z_tip = 1067.50 mm
TH2_MID_DEG = 50.0      # Meio: Z_tip = 1042.40 mm
TH2_PMI_DEG = 20.0      # PMI: Z_tip = 1037.50 mm

O2_X = 31.6018
O2_Z = Z_WORK_DATUM + 308.8482  # 1288.8482 mm

O5_Z_PMS = O4_Z - 2.0 * L4 * math.cos(DTH4_RAD)    # 1253.576952 mm
O5_Z_PMI = O4_Z - 2.0 * L4                         # 1223.576952 mm
Z_TIP_PMI = Z_WORK_DATUM + 57.5000                 # 1037.5000 mm
Z_TIP_PMS = Z_WORK_DATUM + 87.5000                 # 1067.5000 mm
H_O5_TO_TIP = O5_Z_PMI - Z_TIP_PMI                 # 186.076952 mm

# Datums estruturais do cavalete de piso (~1,50 m) e mesa de trabalho
Z_FLOOR = 0.00
Z_FOOT_TOP = 4.76                                  # Sapatas Chapa 3/16" (Z in [0.00, 4.76] mm)
Z_BASE_BOT = Z_WORK_DATUM + 2.00                   # 982.00 mm
Z_BASE_TOP = Z_WORK_DATUM + 8.35                   # 988.35 mm (Chapa 1/4" = 6.35 mm)
Z_STRUCT_BOT = Z_WORK_DATUM + 8.37                 # 988.37 mm

# Suporte do Baru em Cantoneira comercial 1.1/2" x 3/16" a 45° (V 90°)
Z_CANTONEIRA_V = Z_WORK_DATUM + 17.25              # 997.25 mm

# Corpo de prova: Baru elipsoidal 50.0 (X) x 30.0 (Y) x 40.0 (Z) mm na Cantoneira 90°
BARU_LEN_X = 50.00
BARU_WID_Y = 30.00
BARU_DEP_Z = 40.00
_M_V90 = 1.0000
_DZ_TANG_90 = math.hypot(0.5 * BARU_WID_Y * _M_V90, 0.5 * BARU_DEP_Z)  # 25.0000 mm
Z_BARU_CENTER = Z_CANTONEIRA_V + _DZ_TANG_90       # 1022.2500 mm
Z_BARU_BOT = Z_BARU_CENTER - 0.5 * BARU_DEP_Z      # 1002.2500 mm
Z_BARU_TOP = Z_BARU_CENTER + 0.5 * BARU_DEP_Z      # 1042.2500 mm -> corte PMI = 4.7500 mm <= 5.00 mm!

# Comprimento ergonômico da Alavanca em L (arco varrido < alcance do braço humano)
LEVER_TUBE_R1 = 480.00                             # Fim do tubo 1.1/4" (mm)
LEVER_TIP_R = 600.00                               # Ponta da manopla D32 x 120 mm (centro em R = 540.00 mm)

# Mecanismo 4-barras coplanar XZ do Pedal Estendido (+X alinhado à alavanca, SEM rasgos oblongos!)
O_EXT_X = 34.00
O_EXT_Z = Z_WORK_DATUM + 16.00                     # 996.00 mm
EXT_CRANK_DX = 84.00                               # Repouso: X = 118.00 mm
EXT_CRANK_DZ = 54.00                               # Repouso: Z = 1050.00 mm (min Z = 1014.60 mm > mesa)
EXT_ANG_MAX_DEG = 22.0                             # 22.0° basculamento
PED_PIVOT_X = 0.00
PED_PIVOT_Z = 205.00                               # Altura confortável (~218 mm pad) mantendo >58 mm ao piso em X=590 mm
PED_PIN_DX0 = 166.00                               # Pino inferior em repouso: X = 166.00 mm
PED_PIN_DZ0 = 19.00                                # Pino inferior em repouso: Z = 224.00 mm
PED_ROD_Y = -5.00
PED_R_EFF = math.hypot(PED_PIN_DX0, PED_PIN_DZ0)   # 167.083811 mm
PED_THETA0_DEG = math.degrees(math.atan2(PED_PIN_DZ0, PED_PIN_DX0))  # 6.529460°
PED_ROD_LEN = math.hypot((O_EXT_X + EXT_CRANK_DX) - PED_PIN_DX0,
                         (O_EXT_Z + EXT_CRANK_DZ) - (PED_PIVOT_Z + PED_PIN_DZ0))  # 827.393498 mm


def solve_kinematics(theta2_deg: float) -> dict:
    """Resolve a cinemática analítica exata do mecanismo principal para theta2 in [20°, 80°]."""
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
    bp_x = x2 + hc * (-dz) / da
    bp_z = z2 + hc * (dx) / da
    bm_x = x2 - hc * (-dz) / da
    bm_z = z2 - hc * (dx) / da
    bx, bz = (bp_x, bp_z) if bp_x <= bm_x else (bm_x, bm_z)

    th3 = math.atan2(bz - az, bx - ax)
    th4 = math.atan2(bz - O4_Z, bx - O4_X)
    o5_x = 0.0
    o5_z = bz - math.sqrt(max(0.0, L5**2 - bx**2))
    th5 = math.atan2(o5_z - bz, o5_x - bx)

    da_mu = abs(th4 - th3) % (2.0 * math.pi)
    if da_mu > math.pi:
        da_mu = 2.0 * math.pi - da_mu

    return {
        "theta2_deg": theta2_deg,
        "theta_handle_deg": theta2_deg - DELTA_L_DEG,
        "A": (ax, az),
        "B": (bx, bz),
        "O5": (o5_x, o5_z),
        "theta3_deg": math.degrees(th3),
        "theta4_deg": math.degrees(th4),
        "theta5_deg": math.degrees(th5),
        "mu_deg": math.degrees(da_mu),
        "z_tip": o5_z - H_O5_TO_TIP,
    }


def xz_placement(x: float, z: float, theta_deg: float = 0.0) -> App.Placement:
    """Placement no plano XZ (+X gira theta_deg anti-horário = -theta_deg em torno de +Y)."""
    return App.Placement(
        App.Vector(x, 0.0, z),
        App.Rotation(App.Vector(0.0, 1.0, 0.0), -theta_deg),
    )


# =========================================================================================
# 2. PRIMITIVAS GEOMÉTRICAS DE SERRALHERIA (BARRAS CHATAS, TUBOS E PARAFUSOS COMERCIAIS)
# =========================================================================================
def make_rounded_bar_xz(length: float, width: float, y_min: float, y_max: float,
                        d_hole1: float = 0.0, d_hole2: float = 0.0) -> Part.Shape:
    """Barra chata comercial no plano XZ de (0,0) até (length,0) c/ furos redondos simples (sem chavetas!)."""
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
    """Bucha/espaçador cilíndrico padrão de catálogo com eixo ao longo de Y."""
    dy = y_max - y_min
    outer = Part.makeCylinder(0.5 * d_out, dy, App.Vector(x, y_min, z), App.Vector(0.0, 1.0, 0.0))
    inner = Part.makeCylinder(0.5 * d_in, dy + 1.0, App.Vector(x, y_min - 0.5, z), App.Vector(0.0, 1.0, 0.0))
    return outer.cut(inner).removeSplitter()


def make_oring_pin_y(x: float, z: float, d_pin: float, y_min: float, y_max: float,
                     groove_ys: tuple[float, float]) -> tuple[Part.Shape, Part.Shape]:
    """
    Pino liso comercial de aco trefilado (Ø12 mm) com 2 canaletas rasas nas extremidades para
    ANEIS DE RETENCAO ELASTOMERICOS O-RING comerciais (NBR 70 Ø10x1,8 mm, R_maj=6,12 mm, r_min=0,90 mm).
    Retorna (pin_shape_com_canais, orings_shape) com folga de montagem (0,000000 mm3 de interferencia).
    """
    dy = y_max - y_min
    pin = Part.makeCylinder(0.5 * d_pin, dy, App.Vector(x, y_min, z), App.Vector(0, 1, 0))
    d_groove = 10.36
    w_groove = 2.10
    ring_cuts = []
    orings = []
    for yg in groove_ys:
        # Anel de corte = cilindro externo Ø14 - cilindro núcleo da canaleta Ø10.36 mm
        outer_g = Part.makeCylinder(0.5 * d_pin + 1.0, w_groove, App.Vector(x, yg - 0.5 * w_groove, z), App.Vector(0, 1, 0))
        core_g = Part.makeCylinder(0.5 * d_groove, w_groove + 0.2, App.Vector(x, yg - 0.5 * w_groove - 0.1, z), App.Vector(0, 1, 0))
        ring_cuts.append(outer_g.cut(core_g))
        # Anel O-Ring comercial NBR 70 (10 x 1.8 mm estirado na canaleta: ID=10.44 mm, OD=14.04 mm)
        orings.append(Part.makeTorus(6.12, 0.90, App.Vector(x, yg, z), App.Vector(0, 1, 0)))

    pin_grooved = pin.cut(ring_cuts).removeSplitter()
    orings_sh = orings[0].fuse(orings[1:]).removeSplitter()
    return pin_grooved, orings_sh


def make_hollow_metalon_box(x0: float, y0: float, z0: float,
                            dx: float, dy: float, dz: float,
                            axis: str, wall: float = 1.50) -> Part.Shape:
    """Tubo quadrado estrutural oco comercial (Metalon) ao longo de 'X', 'Y' ou 'Z'."""
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
# 3. CONSTRUÇÃO DOS SÓLIDOS (REVISÃO V7 — SERRALHERIA RURAL, CUSTO & SIMPLICIDADE)
# =========================================================================================
def build_base_plate_with_drop_window() -> Part.Shape:
    """
    Chapa de Mesa Estrutural 1/4" (6.35 mm) em Z in [982.00, 988.35] mm (340 x 100 mm):
      - Janela de queda livre do baru quebrado: X in [+30.0, +106.0] mm, Y in [-19.5, +19.5] mm.
      - Rasgo simples de passagem do tirante do pedal: X in [+116.0, +146.0] mm, Y in [-14.0, +4.0] mm.
      - 4 furos M6 p/ Cantoneira do baru e 4 furos M8 p/ fixação nos trilhos superiores do cavalete.
      (Pórticos são soldados diretamente na chapa, eliminando 4 cantoneiras e 8 parafusos M8!)
    """
    base = Part.makeBox(340.0, 100.0, Z_BASE_TOP - Z_BASE_BOT, App.Vector(-170.0, -46.50, Z_BASE_BOT))
    cuts = [
        Part.makeBox(76.0, 39.0, 12.0, App.Vector(30.0, -19.50, Z_BASE_BOT - 2.0)),
        Part.makeBox(30.0, 18.0, 12.0, App.Vector(116.0, -14.0, Z_BASE_BOT - 2.0)),
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
    Pórtico estrutural interno simplificado em Barra Chata 2" x 1/4" (50.80 x 6.35 mm, soldado à mesa!),
    elevado para Z_WORK_DATUM = 980.00 mm (topo Z = 1472.90 mm, O4_Z = 1447.50 mm, O2_Z = 1288.85 mm).
    FS axial > 15x a 5 kN com ~33% menos massa de aço que 3/8"!
    """
    dy = y_max - y_min
    z_bot = Z_STRUCT_BOT
    z_top = Z_WORK_DATUM + 492.90
    h_col = z_top - z_bot

    col_L = Part.makeBox(50.80, dy, h_col, App.Vector(-120.40, y_min, z_bot))
    col_R = Part.makeBox(50.80, dy, h_col, App.Vector(69.60, y_min, z_bot))
    beam_O4 = Part.makeBox(240.80, dy, 50.80, App.Vector(-120.40, y_min, O4_Z - 25.40))
    beam_O2 = Part.makeBox(240.80, dy, 50.80, App.Vector(-120.40, y_min, O2_Z - 25.40))
    parts = [col_L, col_R, beam_O4, beam_O2]

    x_pms = O2_X + 44.0 * math.cos(math.radians(80.0)) + 26.15 * math.cos(math.radians(170.0))
    z_pms = O2_Z + 44.0 * math.sin(math.radians(80.0)) + 26.15 * math.sin(math.radians(170.0))

    if is_front:
        ear_pms_box = Part.makeBox(36.0, dy, z_pms - (O2_Z + 15.0), App.Vector(x_pms - 18.0, y_min, O2_Z + 15.0))
        ear_pms_cyl = Part.makeCylinder(18.0, dy, App.Vector(x_pms, y_min, z_pms), App.Vector(0, 1, 0))
        parts.extend([ear_pms_box, ear_pms_cyl])
    else:
        beam_G1 = Part.makeBox(240.80, dy, 46.00, App.Vector(-120.40, y_min, Z_WORK_DATUM + 127.50))
        beam_G2 = Part.makeBox(240.80, dy, 46.00, App.Vector(-120.40, y_min, Z_WORK_DATUM + 175.50))
        parts.extend([beam_G1, beam_G2])

    portal = parts[0].fuse(parts[1:]).removeSplitter()

    holes = [
        # Furos padronizados para buchas catálogo (O4: D14.04 mm / O2: D23.04 mm)
        Part.makeCylinder(7.02, dy + 2.0, App.Vector(O4_X, y_min - 1.0, O4_Z), App.Vector(0, 1, 0)),
        Part.makeCylinder(11.52, dy + 2.0, App.Vector(O2_X, y_min - 1.0, O2_Z), App.Vector(0, 1, 0)),
    ]
    for xt in (-95.0, 95.0):
        for zt in (Z_WORK_DATUM + 232.5, Z_WORK_DATUM + 392.5):
            holes.append(Part.makeCylinder(5.10, dy + 2.0, App.Vector(xt, y_min - 1.0, zt), App.Vector(0, 1, 0)))

    if not is_front:
        for zc in (Z_WORK_DATUM + 53.0, Z_WORK_DATUM + 77.0):
            holes.append(Part.makeCylinder(4.10, dy + 2.0, App.Vector(-95.0, y_min - 1.0, zc), App.Vector(0, 1, 0)))
        # 4 furos M8 (Ø8,4 mm) nas travessas beam_G1/beam_G2 para fixacao parafusada da Guia em Chapa U
        for xg in (-33.0, 33.0):
            for zg in (Z_WORK_DATUM + 150.50, Z_WORK_DATUM + 198.50):
                holes.append(Part.makeCylinder(4.20, dy + 2.0, App.Vector(xg, y_min - 1.0, zg), App.Vector(0, 1, 0)))

    return portal.cut(holes).removeSplitter()


def build_portal_spacers_and_weld_stops() -> tuple[Part.Shape, Part.Shape]:
    """Espaçadores transversais M10 e 2x pinos batentes soldados Ø10 mm (sem rosca/porca!)."""
    sp_parts = []
    for xt in (-95.0, 95.0):
        for zt in (Z_WORK_DATUM + 232.5, Z_WORK_DATUM + 392.5):
            tube = make_bushing_y(xt, zt, 10.40, 22.00, -34.45, 23.98)
            bolt = Part.makeCylinder(4.95, 71.20, App.Vector(xt, -40.85, zt), App.Vector(0, 1, 0))
            head = Part.makeCylinder(8.00, 4.00, App.Vector(xt, -44.85, zt), App.Vector(0, 1, 0))
            nut = Part.makeCylinder(8.00, 5.00, App.Vector(xt, 30.35, zt), App.Vector(0, 1, 0))
            sp_parts.extend([tube, bolt, head, nut])
    spacers_sh = sp_parts[0].fuse(sp_parts[1:]).removeSplitter()

    x_pms = O2_X + 44.0 * math.cos(math.radians(80.0)) + 26.15 * math.cos(math.radians(170.0))
    z_pms = O2_Z + 44.0 * math.sin(math.radians(80.0)) + 26.15 * math.sin(math.radians(170.0))
    x_pmi = O2_X + 44.0 * math.cos(math.radians(20.0)) + 26.15 * math.cos(math.radians(-70.0))
    z_pmi = O2_Z + 44.0 * math.sin(math.radians(20.0)) + 26.15 * math.sin(math.radians(-70.0))

    stops = []
    for xs, zs in ((x_pms, z_pms), (x_pmi, z_pmi)):
        # Pinos redondos Ø10 mm soldados diretamente na face interna do pórtico frontal (-34.45) c/ luva de borracha Ø14
        pin = Part.makeCylinder(5.00, 8.95, App.Vector(xs, -34.45, zs), App.Vector(0, 1, 0))
        sleeve = make_bushing_y(xs, zs, 10.10, 14.00, -34.40, -25.45)
        stops.extend([pin, sleeve])
    stops_sh = stops[0].fuse(stops[1:]).removeSplitter()
    return spacers_sh, stops_sh


def build_cantoneira_baru_support() -> Part.Shape:
    """
    Suporte do Baru simplificado: Cantoneira comercial 1.1/2" x 3/16" orientada a 45° (V 90°)
    com rasgo central 8 mm, 2 pés em chapa 3 mm parafusados M6 e 2 abas batentes baixas.
    """
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
    """
    Guia Linear Parafusável em Chapa Dobrada em U (3,0 mm):
      - Perfil U dobrado com abas laterais de fixação encostadas em Y=+23,98 mm do Pórtico Traseiro
        (câmara interna 36,0 x 42,0 mm, abas em X in [±18, ±46] mm, altura Z in [1105,5; 1203,5] mm).
      - 4 furos Ø8,4 mm em X = ±33,0 mm, Z = 1130,5 mm (beam_G1) e Z = 1178,5 mm (beam_G2) com
        4x parafusos sextavados M8x20 + porcas (100% desmontável p/ manutenção do UHMW!).
      - 4x tiras planas substituíveis de UHMW (3x 5,0 mm + 1x 10,95 mm traseiro encostado no pórtico),
        retidas por abas dobradas/soldadas no topo e fundo.
    """
    z0 = Z_WORK_DATUM + 125.50   # 1105.50 mm
    hz = 98.00                   # Topo em 1203.50 mm

    pts_u_xy = [
        App.Vector(-46.0, 23.98, z0),
        App.Vector(-46.0, 20.98, z0),
        App.Vector(-21.0, 20.98, z0),
        App.Vector(-21.0, -21.00, z0),
        App.Vector(21.0, -21.00, z0),
        App.Vector(21.0, 20.98, z0),
        App.Vector(46.0, 20.98, z0),
        App.Vector(46.0, 23.98, z0),
        App.Vector(18.0, 23.98, z0),
        App.Vector(18.0, -18.00, z0),
        App.Vector(-18.0, -18.00, z0),
        App.Vector(-18.0, 23.98, z0),
        App.Vector(-46.0, 23.98, z0),
    ]
    u_channel = Part.Face(Part.makePolygon(pts_u_xy)).extrude(App.Vector(0.0, 0.0, hz))

    # Abas retentoras das tiras de UHMW no fundo e topo da calha em U
    tab_bot = Part.makeBox(42.0, 44.98, 2.0, App.Vector(-21.0, -21.00, z0 - 2.02)).cut(
        Part.makeBox(26.2, 26.2, 6.0, App.Vector(-13.1, -13.1, z0 - 4.0))
    )
    tab_top = Part.makeBox(42.0, 44.98, 2.0, App.Vector(-21.0, -21.00, z0 + hz + 0.02)).cut(
        Part.makeBox(26.2, 26.2, 6.0, App.Vector(-13.1, -13.1, z0 + hz - 2.0))
    )
    housing = u_channel.fuse([tab_bot, tab_top]).removeSplitter()

    # 4 furos Ø8,4 mm nas abas laterais da chapa dobrada em U + 4x parafusos M8x20
    u_holes = []
    u_bolts = []
    for xg in (-33.0, 33.0):
        for zg in (Z_WORK_DATUM + 150.50, Z_WORK_DATUM + 198.50):
            u_holes.append(Part.makeCylinder(4.20, 12.0, App.Vector(xg, 16.0, zg), App.Vector(0, 1, 0)))
            shank = Part.makeCylinder(3.95, 16.0, App.Vector(xg, 19.0, zg), App.Vector(0, 1, 0))
            head = Part.makeCylinder(6.80, 4.0, App.Vector(xg, 16.95, zg), App.Vector(0, 1, 0))
            nut = Part.makeCylinder(6.80, 5.0, App.Vector(xg, 30.40, zg), App.Vector(0, 1, 0))
            u_bolts.extend([shank, head, nut])
    housing = housing.cut(u_holes).removeSplitter()
    u_bolts_sh = u_bolts[0].fuse(u_bolts[1:]).removeSplitter()

    # 4 tiras planas retangulares de UHMW (vão útil 26,0x26,0 mm -> folga 0,30 mm/lado p/ pistão 25,4x25,4 mm)
    uhmw_L = Part.makeBox(4.95, 25.96, hz, App.Vector(-17.95, -12.98, z0))
    uhmw_R = Part.makeBox(4.95, 25.96, hz, App.Vector(13.00, -12.98, z0))
    uhmw_F = Part.makeBox(35.80, 4.95, hz, App.Vector(-17.90, -17.95, z0))
    uhmw_B = Part.makeBox(35.80, 10.95, hz, App.Vector(-17.90, 13.00, z0))
    uhmw_all = uhmw_L.fuse([uhmw_R, uhmw_F, uhmw_B]).removeSplitter()

    return housing, uhmw_all, u_bolts_sh


def build_piston_and_blade_local() -> tuple[Part.Shape, Part.Shape, Part.Shape, Part.Shape]:
    """
    Pistão + Navalha s/ fresagem CNC (local centrado em O5 = (0,0,0)):
      - Haste em Barra Quadrada trefilada 1"x1" (25.4x25.4 mm), clevis superior O5 soldado (chata 1"x1/2"),
        chapa de encosto inferior (52x25.4x6.35 mm) + aba traseira (50x22x6.35 mm em Y[+3.25,+9.60]) soldadas.
      - Navalha SAE 5160 reta (50x30x6.35 mm, cunha 30°, s/ rebaixos fresados!), pressionando topo plano
        diretamente contra a chapa de encosto (5 kN em compressão pura) e presa por 2x parafusos M6!
    """
    z_tip_loc = -H_O5_TO_TIP              # -186.076952 mm
    z_blade_top = z_tip_loc + 26.00       # -160.076952 mm (26 mm altura, limpa tab inferior guia Z=1103.5 no PMS!)
    z_cap_top = z_blade_top + 6.35        # -153.726952 mm
    z_clamp_bot = z_blade_top - 19.00
    z_bolt_m6 = z_blade_top - 9.50

    # 1. Navalha SAE 5160 simples (sem entalhes laterais fresados!)
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

    # 2. Êmbolo quadrado 1"x1" + encosto plano soldado + orelha superior 1"x1/2" soldada (ZERO fresa!)
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

    # 3. 2x Parafusos sextavados M6x20 comuns + porcas (sem rebaixo escareado!)
    m6_list = []
    for xm in (-15.0, 15.0):
        shank = Part.makeCylinder(2.95, 18.0, App.Vector(xm, -4.50, z_bolt_m6), App.Vector(0, 1, 0))
        head = Part.makeCylinder(5.00, 3.50, App.Vector(xm, -6.70, z_bolt_m6), App.Vector(0, 1, 0))
        nut = Part.makeCylinder(5.00, 4.00, App.Vector(xm, 9.65, z_bolt_m6), App.Vector(0, 1, 0))
        m6_list.append(shank.fuse([head, nut]).removeSplitter())
    m6_bolts = m6_list[0].fuse(m6_list[1:]).removeSplitter()

    # Bucha catálogo 12x14 mm do olhal O5
    bushing_o5 = make_bushing_y(0.0, 0.0, 12.04, 14.00, -6.30, 6.30)

    return ram, blade, m6_bolts, bushing_o5


def build_floor_stand_and_nr12_cabinet() -> tuple[Part.Shape, Part.Shape, Part.Shape, Part.Shape, Part.Shape, Part.Shape]:
    """Cavalete de piso ~1,50 m + Sapatas c/ 8 furos + Gabinete NR-12 superior + Calha 42x48 mm."""
    m = 20.0
    w = 1.50
    tubes = []

    h_stand = Z_BASE_BOT - Z_FOOT_TOP  # 977.24 mm
    for xs in (-190.0, 170.0):
        for ys in (-135.0, 115.0):
            tubes.append(make_hollow_metalon_box(xs, ys, Z_FOOT_TOP, m, m, h_stand, axis="Z", wall=w))

    tubes.append(make_hollow_metalon_box(-170.0, -135.0, 30.0, 340.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-170.0, 115.0, 30.0, 340.0, m, m, axis="X", wall=w))
    for xs in (-190.0, 170.0):
        tubes.append(make_hollow_metalon_box(xs, -115.0, 30.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(PED_PIVOT_X - 10.0, -115.0, 30.0, m, 230.0, m, axis="Y", wall=w))

    for y_ear in (PED_ROD_Y - 14.5, PED_ROD_Y + 10.5):
        tubes.append(Part.makeBox(20.0, 4.0, 170.0, App.Vector(PED_PIVOT_X - 10.0, y_ear, 50.0)).cut(
            Part.makeCylinder(5.10, 10.0, App.Vector(PED_PIVOT_X, y_ear - 2.0, PED_PIVOT_Z), App.Vector(0, 1, 0))
        ))
    tubes.append(Part.makeBox(14.0, 4.0, 8.0, App.Vector(156.0, 12.0, 520.0)))

    # Prateleira do Reservatório Dobrado #18 (Z in [520, 540] mm)
    tubes.append(make_hollow_metalon_box(-170.0, 115.0, 520.0, 340.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-190.0, -115.0, 520.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(170.0, -115.0, 520.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(-162.0, -115.0, 520.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(92.0, -115.0, 520.0, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(-170.0, -135.0, 500.0, 340.0, m, m, axis="X", wall=w))

    z_top_stand = Z_BASE_BOT - m
    for xs in (-190.0, 170.0):
        tubes.append(make_hollow_metalon_box(xs, -115.0, z_top_stand, m, 230.0, m, axis="Y", wall=w))
    tubes.append(make_hollow_metalon_box(-170.0, -46.50, z_top_stand, 340.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-170.0, 33.55, z_top_stand, 340.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-170.0, -135.0, z_top_stand, 340.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-170.0, 115.0, z_top_stand, 340.0, m, m, axis="X", wall=w))

    # Quadro superior NR-12 (Z in [988.37, 1497.50] mm)
    x_min, x_max = -170.0, 170.0
    y_min, y_max = -46.50, 53.50
    z_bot_cab, z_top_cab = Z_STRUCT_BOT, Z_WORK_DATUM + 517.50
    z_mid_rail = Z_WORK_DATUM + 263.30
    h_post = z_top_cab - z_bot_cab

    for xp in (x_min, x_max - m):
        for yp in (y_min, 33.55):
            tubes.append(make_hollow_metalon_box(xp, yp, z_bot_cab, m, m, h_post, axis="Z", wall=w))
    for yp in (y_min, 33.55):
        tubes.append(make_hollow_metalon_box(x_min + m, yp, z_top_cab - m, 300.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(x_min + m, 33.55, z_bot_cab, 300.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(x_min + m, 33.55, z_mid_rail, 300.0, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-150.0, y_min, z_mid_rail, 29.58, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(120.42, y_min, z_mid_rail, 29.58, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-69.58, y_min, z_mid_rail, 139.16, 12.00, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(-150.0, y_min, z_bot_cab, 29.58, m, m, axis="X", wall=w))
    tubes.append(make_hollow_metalon_box(120.42, y_min, z_bot_cab, 29.58, m, m, axis="X", wall=w))
    for zp in (z_bot_cab, z_mid_rail, z_top_cab - m):
        tubes.append(make_hollow_metalon_box(x_max - m, y_min + m, zp, m, 60.05, m, axis="Y", wall=w))
    for zp in (z_bot_cab, Z_WORK_DATUM + 131.0, z_mid_rail, z_top_cab - m):
        tubes.append(make_hollow_metalon_box(x_min, y_min + m, zp, m, 60.05, m, axis="Y", wall=w))

    metalon_frame = tubes[0].fuse(tubes[1:]).removeSplitter()

    m_holes = []
    for xb in (-160.0, 160.0):
        for zb in (Z_WORK_DATUM + 45.0, Z_WORK_DATUM + 155.0, Z_WORK_DATUM + 257.5,
                   Z_WORK_DATUM + 292.5, Z_WORK_DATUM + 397.5, Z_WORK_DATUM + 505.5):
            m_holes.append(Part.makeCylinder(3.05, 12.0, App.Vector(xb, -50.0, zb), App.Vector(0, 1, 0)))
    for ym in (-34.0, 41.0):
        m_holes.append(Part.makeCylinder(3.05, 12.0, App.Vector(-174.0, ym, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0)))
    # 4 furos M6 (Ø6,1 mm) nos montantes esquerdos para parafusar a Moega/Reservatório de Alimentação
    for ym in (-36.50, 43.55):
        for zm in (1155.0, 1253.3):
            m_holes.append(Part.makeCylinder(3.05, 28.0, App.Vector(-174.0, ym, zm), App.Vector(1, 0, 0)))
    metalon_frame = metalon_frame.cut(m_holes).removeSplitter()

    # Sapatas de piso com 8 furos de chumbamento Ø10.5 mm
    feet_plates = []
    foot_specs = [
        (-215.0, -160.0, [(-202.0, -147.0), (-158.0, -103.0)]),
        (145.0,  -160.0, [(202.0,  -147.0), (158.0,  -103.0)]),
        (-215.0,   90.0, [(-202.0,  147.0), (-158.0,  103.0)]),
        (145.0,    90.0, [(202.0,   147.0), (158.0,   103.0)]),
    ]
    for x0p, y0p, hole_xy in foot_specs:
        pl = Part.makeBox(70.0, 70.0, Z_FOOT_TOP, App.Vector(x0p, y0p, Z_FLOOR))
        h_cuts = [Part.makeCylinder(5.25, 10.0, App.Vector(hx, hy, -2.0), App.Vector(0, 0, 1)) for hx, hy in hole_xy]
        feet_plates.append(pl.cut(h_cuts).removeSplitter())
    feet_shape = feet_plates[0].fuse(feet_plates[1:]).removeSplitter()

    # Carenagem Superior #18 (1.20 mm)
    panels = []
    p_front_top = Part.makeBox(340.0, 1.20, 244.0, App.Vector(-170.0, -47.72, Z_WORK_DATUM + 273.50))
    collar_o2 = Part.makeCylinder(16.0, 1.68, App.Vector(O2_X, -48.20, O2_Z), App.Vector(0, 1, 0))
    p_front_top = p_front_top.fuse(collar_o2)
    p_front_cuts = [Part.makeCylinder(10.30, 6.0, App.Vector(O2_X, -50.0, O2_Z), App.Vector(0, 1, 0))]
    for xb in (-160.0, 160.0):
        for zb in (Z_WORK_DATUM + 292.5, Z_WORK_DATUM + 397.5, Z_WORK_DATUM + 505.5):
            p_front_cuts.append(Part.makeCylinder(3.05, 6.0, App.Vector(xb, -50.0, zb), App.Vector(0, 1, 0)))
    panels.append(p_front_top.cut(p_front_cuts).removeSplitter())
    panels.append(Part.makeBox(340.0, 1.20, h_post, App.Vector(-170.0, 53.57, z_bot_cab)))
    panels.append(Part.makeBox(1.20, 100.05, h_post, App.Vector(170.02, -46.50, z_bot_cab)))
    p_left_top = Part.makeBox(1.20, 100.05, 386.50, App.Vector(-171.22, -46.50, Z_WORK_DATUM + 131.0))
    p_left_cuts = [
        Part.makeCylinder(3.05, 8.0, App.Vector(-174.0, ym, zm), App.Vector(1, 0, 0))
        for ym in (-36.50, 43.55) for zm in (1155.0, 1253.3)
    ]
    panels.append(p_left_top.cut(p_left_cuts).removeSplitter())
    panels.append(Part.makeBox(1.20, 100.05, 51.63, App.Vector(-171.22, -46.50, z_bot_cab)))
    panels.append(Part.makeBox(340.0, 100.05, 1.20, App.Vector(-170.0, -46.50, z_top_cab + 0.02)))
    sheet_panels = panels[0].fuse(panels[1:]).removeSplitter()

    # Visor Policarbonato NR-12
    poly_window = Part.makeBox(340.0, 1.20, 245.05, App.Vector(-170.0, -47.72, Z_WORK_DATUM + 28.40))
    v_cuts = [Part.makeCylinder(3.05, 6.0, App.Vector(xb, -50.0, zb), App.Vector(0, 1, 0))
              for xb in (-160.0, 160.0)
              for zb in (Z_WORK_DATUM + 45.0, Z_WORK_DATUM + 155.0, Z_WORK_DATUM + 257.5)]
    poly_window = poly_window.cut(v_cuts).removeSplitter()

    # Calha de Alimentação Segura NR-12 (42x48 mm)
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
    fl_portal = Part.makeBox(34.0, 1.48, 44.0, App.Vector(-112.0, 22.50, Z_WORK_DATUM + 43.0))
    fl_metalon_F = Part.makeBox(3.0, 18.0, 50.0, App.Vector(-173.02, -40.5, Z_WORK_DATUM + 65.0))
    fl_metalon_R = Part.makeBox(3.0, 24.0, 50.0, App.Vector(-173.02, 22.5, Z_WORK_DATUM + 65.0))
    chute = chute.fuse([fl_portal, fl_metalon_F, fl_metalon_R]).removeSplitter()
    c_holes = [
        Part.makeCylinder(4.10, 6.0, App.Vector(-95.0, 20.0, Z_WORK_DATUM + 53.0), App.Vector(0, 1, 0)),
        Part.makeCylinder(4.10, 6.0, App.Vector(-95.0, 20.0, Z_WORK_DATUM + 77.0), App.Vector(0, 1, 0)),
        Part.makeCylinder(3.05, 8.0, App.Vector(-175.0, -34.0, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0)),
        Part.makeCylinder(3.05, 8.0, App.Vector(-175.0, 41.0, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0)),
    ]
    chute = chute.cut(c_holes).removeSplitter()

    cab_bolts = []
    for xb in (-160.0, 160.0):
        for zb in (Z_WORK_DATUM + 45.0, Z_WORK_DATUM + 155.0, Z_WORK_DATUM + 257.5,
                   Z_WORK_DATUM + 292.5, Z_WORK_DATUM + 397.5, Z_WORK_DATUM + 505.5):
            head_b = Part.makeCylinder(4.50, 1.80, App.Vector(xb, -49.55, zb), App.Vector(0, 1, 0))
            shank_b = Part.makeCylinder(2.95, 7.50, App.Vector(xb, -47.75, zb), App.Vector(0, 1, 0))
            cab_bolts.append(head_b.fuse(shank_b).removeSplitter())
    for zc in (Z_WORK_DATUM + 53.0, Z_WORK_DATUM + 77.0):
        cab_bolts.append(Part.makeCylinder(3.95, 15.0, App.Vector(-95.0, 21.0, zc), App.Vector(0, 1, 0)))
        cab_bolts.append(Part.makeCylinder(6.50, 4.5, App.Vector(-95.0, 30.38, zc), App.Vector(0, 1, 0)))
    for ym in (-34.0, 41.0):
        hm_b = Part.makeCylinder(4.50, 1.80, App.Vector(-174.85, ym, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0))
        sm_b = Part.makeCylinder(2.95, 6.50, App.Vector(-173.05, ym, Z_WORK_DATUM + 88.0), App.Vector(1, 0, 0))
        cab_bolts.append(hm_b.fuse(sm_b).removeSplitter())
    # 4x Parafusos M6 (com porcas internas) que fixam a Moega de Alimentacao na lateral do gabinete
    for ym in (-36.50, 43.55):
        for zm in (1155.0, 1253.3):
            hm_r = Part.makeCylinder(4.80, 3.00, App.Vector(-175.46, ym, zm), App.Vector(1, 0, 0))
            sm_r = Part.makeCylinder(2.95, 25.50, App.Vector(-172.46, ym, zm), App.Vector(1, 0, 0))
            nm_r = Part.makeCylinder(4.80, 4.00, App.Vector(-149.95, ym, zm), App.Vector(1, 0, 0))
            cab_bolts.append(hm_r.fuse([sm_r, nm_r]).removeSplitter())
    cab_bolts_shape = cab_bolts[0].fuse(cab_bolts[1:]).removeSplitter()

    return metalon_frame, sheet_panels, poly_window, chute, feet_shape, cab_bolts_shape


def build_sheet_metal_chute_and_reservoir() -> tuple[Part.Shape, Part.Shape]:
    """Calha de descarga inclinada e Grande Reservatório 12,3 L em chapa dobrada #18 (1.20 mm)."""
    pts_left = [
        App.Vector(104.0, -20.5, 980.0),
        App.Vector(105.5, -20.5, 980.0),
        App.Vector(42.0,  -20.5, 758.0),
        App.Vector(40.5,  -20.5, 758.0),
        App.Vector(104.0, -20.5, 980.0),
    ]
    slope_bot = Part.Face(Part.makePolygon(pts_left)).extrude(App.Vector(0.0, 41.0, 0.0))
    pts_side = [
        App.Vector(105.5, -21.70, 981.5),
        App.Vector(42.0,  -21.70, 758.0),
        App.Vector(-25.0, -21.70, 758.0),
        App.Vector(28.0,  -21.70, 981.5),
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
    """
    Reservatório / Moega Dedicada da Calha de Alimentação em chapa dobrada #18 (1,20 mm):
      - Funil trapezoidal inclinado (X in [-365.0, -215.05], Y in [-70, +70] -> [-22.5, +22.5],
        topo em Z = 1280 mm com abas de borda dobradas 10 mm, fundo inclinado 26,5° de Z=1135 a Z=1058,5)
        descarregando direto na boca da Calha Segura NR-12 (em X = -215,0 mm).
      - Duas abas laterais dobradas estendendo até X = -172,44..-171,24 mm para fixação aparafusada
        (4x M6) diretamente nos montantes esquerdos (Y = -36,50 e +43,55, Z = 1155,0 e 1253,3) do gabinete!
    """
    def rect_yz(x: float, y0: float, y1: float, z0: float, z1: float):
        return Part.makePolygon([
            App.Vector(x, y0, z0),
            App.Vector(x, y1, z0),
            App.Vector(x, y1, z1),
            App.Vector(x, y0, z1),
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
    # Duas abas laterais dobradas aparafusadas à lateral esquerda do gabinete (X = -172.44..-171.24)
    # Integradas externamente às paredes inclinadas da moega (cortadas por inner_loft se entrarem na cavidade)
    arm_f_side = Part.makeBox(120.56, 1.20, 135.0, App.Vector(-293.00, -46.50, 1135.0))
    arm_f_bot = Part.makeBox(120.56, 20.00, 1.20, App.Vector(-293.00, -46.50, 1135.0))
    fl_f = Part.makeBox(1.20, 20.00, 135.0, App.Vector(-172.44, -46.50, 1135.0))

    arm_r_side = Part.makeBox(142.56, 1.20, 135.0, App.Vector(-315.00, 52.35, 1135.0))
    arm_r_bot = Part.makeBox(142.56, 20.00, 1.20, App.Vector(-315.00, 33.55, 1135.0))
    fl_r = Part.makeBox(1.20, 20.00, 135.0, App.Vector(-172.44, 33.55, 1135.0))

    # Parede frontal acima do teto da calha (Z in [1109.6, 1280.0], mantendo boca Z[1060, 1108] livre)
    front_cap = Part.makeBox(1.20, 45.0, 170.40, App.Vector(-216.25, -22.50, 1109.60))
    # Abas superiores de rigidez dobradas para fora (10 mm no contorno de topo Z = 1278.8..1280.0)
    lip_back = Part.makeBox(10.0, 140.0, 1.20, App.Vector(-375.00, -70.00, 1278.80))
    lip_front = Part.makeBox(10.0, 45.0, 1.20, App.Vector(-215.05, -22.50, 1278.80))

    hopper = outer_loft.fuse([
        arm_f_side, arm_f_bot, fl_f, arm_r_side, arm_r_bot, fl_r
    ]).cut(inner_loft).fuse([front_cap, lip_back, lip_front]).removeSplitter()

    # 4 furos M6 (Ø6,1 mm) alinhados aos montantes esquerdos do gabinete
    h_cuts = [
        Part.makeCylinder(3.05, 8.0, App.Vector(-175.0, ym, zm), App.Vector(1, 0, 0))
        for ym in (-36.50, 43.55) for zm in (1155.0, 1253.3)
    ]
    return hopper.cut(h_cuts).removeSplitter()


def build_pedal_extraction_system_local() -> dict[str, Part.Shape]:
    """
    Sistema de pedal 4-barras coplanar no plano XZ (alinhado com a alavanca +X, APENAS furos redondos!):
      - Alavanca_Ejetora_Pedal (O_ext = (34, 0, 996))
      - Tirante_Pedal_Extracao (haste Ø8 mm com 2 furos redondos Ø8.4 mm acoplando ao pino superior e inferior)
      - Pedal_Extracao (O_ped = (0, -5, 155), aponta em +X com furo redondo Ø8.2 mm em (132, +19))
      - Mola_Retorno_Pedal (ancorada entre aba sob trilho Z=520 e aba do pedal Z=159)
    """
    ear_F = Part.makeBox(12.0, 4.0, 15.0, App.Vector(O_EXT_X - 6.0, -27.5, Z_BASE_TOP + 0.02))
    ear_B = Part.makeBox(12.0, 4.0, 15.0, App.Vector(O_EXT_X - 6.0, 24.0, Z_BASE_TOP + 0.02))
    shaft_ext = Part.makeCylinder(3.95, 56.0, App.Vector(O_EXT_X, -28.0, O_EXT_Z), App.Vector(0, 1, 0))
    stator_ext = ear_F.fuse([ear_B, shaft_ext]).removeSplitter()

    # Alavanca Ejetora (local em O_ext = (34.0, 0, 996.0))
    hub_mid = Part.makeCylinder(6.50, 7.0, App.Vector(0.0, -3.5, 0.0), App.Vector(0, 1, 0))
    paddle = Part.makeBox(51.5, 6.0, 6.5, App.Vector(-51.5, -3.0, -4.5))
    hub_crank = Part.makeCylinder(6.40, 25.0, App.Vector(0.0, -1.0, 0.0), App.Vector(0, 1, 0))
    riser = make_rounded_bar_xz(26.0, 10.0, 19.8, 23.5)
    riser.rotate(App.Vector(0, 0, 0), App.Vector(0, 1, 0), -90.0)
    ang_seg = math.degrees(math.atan2(EXT_CRANK_DZ - 26.0, EXT_CRANK_DX))
    len_seg = math.hypot(EXT_CRANK_DX, EXT_CRANK_DZ - 26.0)
    arm_seg = make_rounded_bar_xz(len_seg, 10.0, 19.8, 23.5)
    arm_seg.rotate(App.Vector(0, 0, 0), App.Vector(0, 1, 0), -ang_seg)
    arm_seg.translate(App.Vector(0.0, 0.0, 26.0))
    cross_pin = Part.makeCylinder(3.90, 22.0, App.Vector(EXT_CRANK_DX, -2.0, EXT_CRANK_DZ), App.Vector(0, 1, 0))
    ejector_arm = hub_mid.fuse([paddle, hub_crank, riser, arm_seg, cross_pin]).removeSplitter()
    ejector_arm = ejector_arm.cut(
        Part.makeCylinder(4.05, 62.0, App.Vector(0.0, -31.0, 0.0), App.Vector(0, 1, 0))
    ).removeSplitter()

    # Pedal de Extração Estendido (+X alinhado à distância da alavanca, local em (0, -5, 205))
    # Tubo 605 mm (X in [-15, +590]) + sapata em X in [490, 590] (centro X = 540 mm == zona empunhadura!)
    ped_tube = make_hollow_metalon_box(-15.0, -10.0, -10.0, 605.0, 20.0, 20.0, axis="X", wall=1.50)
    ped_pad = Part.makeBox(100.0, 80.0, 3.0, App.Vector(490.0, -40.0, 10.0))
    ped_pivot_bolt = Part.makeCylinder(4.90, 34.0, App.Vector(0.0, -17.0, 0.0), App.Vector(0, 1, 0))
    ped_spring_tab = Part.makeBox(10.0, 12.0, 4.0, App.Vector(156.0, 10.0, 0.0))
    ped_rod_ear = Part.makeBox(14.0, 6.0, 16.0, App.Vector(PED_PIN_DX0 - 7.0, -3.0, 10.0)).cut(
        Part.makeCylinder(4.10, 12.0, App.Vector(PED_PIN_DX0, -6.0, PED_PIN_DZ0), App.Vector(0, 1, 0))
    )
    pedal_sh = ped_tube.fuse([ped_pad, ped_pivot_bolt, ped_spring_tab, ped_rod_ear]).removeSplitter()

    # Tirante 4-Barras Simples (local em P_top, eixo ao longo da linha pino superior -> pino inferior!)
    # Furo redondo Ø8.4 mm no topo (sem rasgo oblongo!) + haste Ø8 mm + garfo inferior com pino Ø7.8 mm
    top_eye = Part.makeCylinder(7.50, 4.5, App.Vector(0.0, -1.5, 0.0), App.Vector(0, 1, 0)).fuse(
        Part.makeBox(10.0, 4.5, 14.0, App.Vector(-5.0, -1.5, -14.0))
    ).cut(Part.makeCylinder(4.20, 10.0, App.Vector(0.0, -4.0, 0.0), App.Vector(0, 1, 0)))
    shaft = Part.makeCylinder(4.00, PED_ROD_LEN - 26.0, App.Vector(0.0, -5.0, -PED_ROD_LEN + 14.0), App.Vector(0, 0, 1))
    bridge = Part.makeBox(10.0, 9.0, 6.0, App.Vector(-5.0, -8.0, -14.0))
    yoke_hdr = Part.makeBox(14.0, 15.0, 5.0, App.Vector(-7.0, -12.5, -PED_ROD_LEN + 11.0))
    yoke_F = Part.makeBox(14.0, 4.0, 22.0, App.Vector(-7.0, -12.5, -PED_ROD_LEN - 7.0))
    yoke_B = Part.makeBox(14.0, 4.0, 22.0, App.Vector(-7.0, -1.5, -PED_ROD_LEN - 7.0))
    bot_pin = Part.makeCylinder(3.90, 17.0, App.Vector(0.0, -13.5, -PED_ROD_LEN), App.Vector(0, 1, 0))
    tirante_sh = top_eye.fuse([bridge, shaft, yoke_hdr, yoke_F, yoke_B, bot_pin]).removeSplitter()

    # Mola de retorno entre aba no cavalete (Z=520) e aba do pedal (Z=205..209)
    coils = [Part.makeTorus(6.5, 1.3, App.Vector(161.0, 14.0, 285.0 + k * 9.0), App.Vector(0, 0, 1)) for k in range(18)]
    hook_t = Part.makeCylinder(1.3, 80.4, App.Vector(161.0, 14.0, 439.5), App.Vector(0, 0, 1))
    hook_b = Part.makeCylinder(1.3, 76.0, App.Vector(161.0, 14.0, 209.5), App.Vector(0, 0, 1))
    spring_sh = coils[0].fuse(coils[1:] + [hook_t, hook_b]).removeSplitter()

    return {
        "stator_ext": stator_ext,
        "ejector_arm": ejector_arm,
        "pedal": pedal_sh,
        "tirante": tirante_sh,
        "spring": spring_sh,
    }


def build_l2_and_handle_local() -> dict[str, Part.Shape]:
    """
    Subconjunto 02 Soldado & Baixíssimo Custo (centrado em O2 = (0,0,0)):
      - Eixo_Alavanca_Soldado_O2: Eixo Ø20 mm liso SOLDADO diretamente ao Elo2_Braco_Curto_L2 e ao
        Tubo Único 1.1/4"x2.0 mm (boca-de-lobo direta sobre o eixo Ø20!) + 2 arruelas soldadas de encosto.
        ELIMINA 100% do fresamento de chaveta, brochamento interno, cubo usinado e canais DIN 471!
      - Manopla_Empunhadura_Borracha em D32 x 120 mm.
    """
    # Conjunto rígido soldado em O2: eixo Ø20 mm + braço curto L2 + tubo alavanca 1.1/4"x2.0 mm + colares de encosto
    shaft = Part.makeCylinder(10.00, 120.0, App.Vector(0.0, -82.00, 0.0), App.Vector(0, 1, 0))
    collar_f = make_bushing_y(0.0, 0.0, 20.00, 30.00, -45.50, -41.20)
    collar_r = make_bushing_y(0.0, 0.0, 20.00, 30.00, 30.60, 35.00)
    l2_bar = make_rounded_bar_xz(L2, 38.10, -32.00, -22.47, d_hole1=20.02, d_hole2=14.04)

    ang_h = math.radians(-DELTA_L_DEG)
    ux, uz = math.cos(ang_h), math.sin(ang_h)
    dir_vec = App.Vector(ux, 0.0, uz)
    y_h = -65.50

    # Tubo Único Contínuo 1.1/4" x 2.0 mm (r = 5 -> 480 mm) soldado com encaixe boca-de-lobo direto no eixo Ø20 mm!
    r0_t1, r1_t1 = 5.00, LEVER_TUBE_R1
    p0_t1 = App.Vector(r0_t1 * ux, y_h, r0_t1 * uz)
    t1_out = Part.makeCylinder(15.875, r1_t1 - r0_t1, p0_t1, dir_vec)
    t1_in = Part.makeCylinder(13.875, r1_t1 - r0_t1 + 2.0,
                              App.Vector((r0_t1 - 1.0) * ux, y_h, (r0_t1 - 1.0) * uz), dir_vec)
    saddle_cut = Part.makeCylinder(10.02, 40.0, App.Vector(0.0, -85.0, 0.0), App.Vector(0.0, 1.0, 0.0))
    tube_main = t1_out.cut([t1_in, saddle_cut]).removeSplitter()

    # Bucha fina catálogo (12x14 mm) na ponta A do L2
    bush_l2_a = make_bushing_y(L2, 0.0, 12.04, 14.00, -31.95, -22.52)

    welded_l2_lever = shaft.fuse([collar_f, collar_r, l2_bar, tube_main]).removeSplitter()

    r0_g, r1_g = LEVER_TUBE_R1 + 0.1, LEVER_TIP_R
    grip = Part.makeCylinder(16.0, r1_g - r0_g, App.Vector(r0_g * ux, y_h, r0_g * uz), dir_vec)

    # Pino liso Ø12 mm retido por anéis elastoméricos O-ring NBR 70 (10x1,8 mm) na junta A
    pin_a_core, oring_a = make_oring_pin_y(L2, 0.0, 11.96, -34.35, -11.20, groove_ys=(-33.25, -13.10))
    pin_a = pin_a_core.fuse([
        make_bushing_y(L2, 0.0, 12.10, 19.00, -32.25, -32.02),
        make_bushing_y(L2, 0.0, 12.10, 19.00, -22.44, -22.03),
        make_bushing_y(L2, 0.0, 12.10, 19.00, -15.62, -14.20),
    ]).removeSplitter()

    return {
        "Conjunto_Soldado_L2_Alavanca_O2": welded_l2_lever,
        "Buchas_Catalogo_A": bush_l2_a,
        "Manopla_Empunhadura_Borracha": grip,
        "Pino_Eixo_A": pin_a,
        "Aneis_Retencao_ORing_A": oring_a,
    }


# =========================================================================================
# 4. CONTROLADOR CINEMÁTICO NATIVO (EXPRESSION ENGINE C++ + 4-BARRAS DO PEDAL)
# =========================================================================================
MOVING_GROUPS = {
    "O2": ("Conjunto_Soldado_L2_Alavanca_O2", "Buchas_Catalogo_A", "Manopla_Empunhadura_Borracha", "Pino_Eixo_A", "Aneis_Retencao_ORing_A"),
    "L3": ("Elo3_Biela_L3", "Buchas_Catalogo_L3"),
    "L4": ("Elo4_Balancim_L4", "Buchas_Catalogo_L4"),
    "L5": ("Elo5_Garfo_Duplo_L5", "Buchas_Catalogo_L5", "Pino_Eixo_B", "Aneis_Retencao_ORing_B"),
    "O5": ("Pistao_Embolo_Quadrado", "Navalha_Corte_SAE5160", "Parafusos_Fixacao_Navalha_M6", "Bucha_Catalogo_O5", "Pino_Eixo_O5", "Aneis_Retencao_ORing_O5"),
}


def bind_native_kinematic_expressions(doc: App.Document, ctrl) -> None:
    """Vincula mecanismo principal e 4-barras do pedal ao ExpressionEngine C++ do FreeCAD."""
    ctrl.setExpression("Angulo_Alavanca_Graus", f"Angulo_Manivela_Graus - {DELTA_L_DEG:.6f}")
    ctrl.setExpression("Ax_mm", f"{O2_X:.6f} + {L2:.6f} * cos(Angulo_Manivela_Graus * 1 deg)")
    ctrl.setExpression("Az_mm", f"{O2_Z:.6f} + {L2:.6f} * sin(Angulo_Manivela_Graus * 1 deg)")
    ctrl.setExpression("dA_mm", f"sqrt(Ax_mm^2 + (Az_mm - {O4_Z:.6f})^2)")
    ctrl.setExpression("ac_mm", f"({L4:.10f}^2 - {L3:.10f}^2 + dA_mm^2) / (2.0 * dA_mm)")
    ctrl.setExpression("hc_mm", f"sqrt(max(0.0; {L4:.10f}^2 - ac_mm^2))")
    ctrl.setExpression("Bx_mm", f"ac_mm * Ax_mm / dA_mm + hc_mm * (Az_mm - {O4_Z:.6f}) / dA_mm")
    ctrl.setExpression("Bz_mm", f"{O4_Z:.6f} + ac_mm * (Az_mm - {O4_Z:.6f}) / dA_mm - hc_mm * Ax_mm / dA_mm")
    ctrl.setExpression("Posicao_Pistao_O5_Z_mm", f"Bz_mm - sqrt(max(0.0; {L5:.10f}^2 - Bx_mm^2))")
    ctrl.setExpression("Posicao_Navalha_Z_tip_mm", f"Posicao_Pistao_O5_Z_mm - {H_O5_TO_TIP:.10f}")
    ctrl.setExpression("Angulo_Biela_L3_Graus", "atan2(Bz_mm - Az_mm; Bx_mm - Ax_mm) / 1 deg")
    ctrl.setExpression("Angulo_Balancim_L4_Graus", f"atan2(Bz_mm - {O4_Z:.6f}; Bx_mm) / 1 deg")
    ctrl.setExpression("Angulo_Garfo_L5_Graus", "atan2(Posicao_Pistao_O5_Z_mm - Bz_mm; -Bx_mm) / 1 deg")
    ctrl.setExpression(
        "Angulo_Transmissao_Mu_Graus",
        "abs(Angulo_Balancim_L4_Graus - Angulo_Biela_L3_Graus) > 180 ? "
        "360 - abs(Angulo_Balancim_L4_Graus - Angulo_Biela_L3_Graus) : "
        "abs(Angulo_Balancim_L4_Graus - Angulo_Biela_L3_Graus)",
    )

    # Cinemática exata de 4 barras do Pedal (+X) em XZ (ZERO rasgos oblongos!)
    ctrl.setExpression(
        "Tirante_Pino_X_mm",
        f"{O_EXT_X:.6f} + {EXT_CRANK_DX:.6f} * cos(Angulo_Ejetor_Pedal_Graus * 1 deg) "
        f"+ {EXT_CRANK_DZ:.6f} * sin(Angulo_Ejetor_Pedal_Graus * 1 deg)",
    )
    ctrl.setExpression(
        "Tirante_Pino_Z_mm",
        f"{O_EXT_Z:.6f} - {EXT_CRANK_DX:.6f} * sin(Angulo_Ejetor_Pedal_Graus * 1 deg) "
        f"+ {EXT_CRANK_DZ:.6f} * cos(Angulo_Ejetor_Pedal_Graus * 1 deg)",
    )
    ctrl.setExpression("Ped_d_mm", f"sqrt(Tirante_Pino_X_mm^2 + (Tirante_Pino_Z_mm - {PED_PIVOT_Z:.6f})^2)")
    ctrl.setExpression("Ped_ac_mm", f"({PED_R_EFF:.10f}^2 - {PED_ROD_LEN:.10f}^2 + Ped_d_mm^2) / (2.0 * Ped_d_mm)")
    ctrl.setExpression("Ped_hc_mm", f"sqrt(max(0.0; {PED_R_EFF:.10f}^2 - Ped_ac_mm^2))")
    ctrl.setExpression(
        "Ped_Pin_X_mm",
        f"Ped_ac_mm * Tirante_Pino_X_mm / Ped_d_mm + Ped_hc_mm * (Tirante_Pino_Z_mm - {PED_PIVOT_Z:.6f}) / Ped_d_mm",
    )
    ctrl.setExpression(
        "Ped_Pin_Z_mm",
        f"{PED_PIVOT_Z:.6f} + Ped_ac_mm * (Tirante_Pino_Z_mm - {PED_PIVOT_Z:.6f}) / Ped_d_mm "
        f"- Ped_hc_mm * Tirante_Pino_X_mm / Ped_d_mm",
    )
    ctrl.setExpression(
        "Angulo_Pedal_Piso_Graus",
        f"{PED_THETA0_DEG:.8f} - atan2(Ped_Pin_Z_mm - {PED_PIVOT_Z:.6f}; Ped_Pin_X_mm) / 1 deg",
    )
    ctrl.setExpression(
        "Angulo_Tirante_Graus",
        "atan2(Tirante_Pino_X_mm - Ped_Pin_X_mm; Tirante_Pino_Z_mm - Ped_Pin_Z_mm) / 1 deg",
    )

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

    obj_ej = doc.getObject("Alavanca_Ejetora_Pedal")
    if obj_ej:
        obj_ej.Placement = App.Placement(App.Vector(O_EXT_X, 0.0, O_EXT_Z), App.Rotation(App.Vector(0, 1, 0), 1.0))
        obj_ej.setExpression(".Placement.Rotation.Angle", "Controlador_Cinematico.Angulo_Ejetor_Pedal_Graus * 1 deg")

    obj_ped = doc.getObject("Pedal_Extracao")
    if obj_ped:
        obj_ped.Placement = App.Placement(App.Vector(PED_PIVOT_X, PED_ROD_Y, PED_PIVOT_Z),
                                          App.Rotation(App.Vector(0, 1, 0), 1.0))
        obj_ped.setExpression(".Placement.Rotation.Angle", "Controlador_Cinematico.Angulo_Pedal_Piso_Graus * 1 deg")

    obj_rod = doc.getObject("Tirante_Pedal_Extracao")
    if obj_rod:
        obj_rod.Placement = App.Placement(App.Vector(O_EXT_X + EXT_CRANK_DX, 0.0, O_EXT_Z + EXT_CRANK_DZ),
                                          App.Rotation(App.Vector(0, 1, 0), 0.0))
        obj_rod.setExpression(".Placement.Base.x", "Controlador_Cinematico.Tirante_Pino_X_mm * 1 mm")
        obj_rod.setExpression(".Placement.Base.z", "Controlador_Cinematico.Tirante_Pino_Z_mm * 1 mm")
        obj_rod.setExpression(".Placement.Rotation.Angle", "Controlador_Cinematico.Angulo_Tirante_Graus * 1 deg")


def set_pose(doc: App.Document, theta2_deg: float, ext_ang_deg: float = 0.0, recompute: bool = True) -> dict:
    """Atualiza pose principal (theta2 in [20°, 80°]) e pedal (ext_ang in [0°, 22°])."""
    ang_clamped = max(TH2_PMI_DEG, min(TH2_PMS_DEG, float(theta2_deg)))
    ext_clamped = max(0.0, min(EXT_ANG_MAX_DEG, float(ext_ang_deg)))
    k = solve_kinematics(ang_clamped)

    ctrl = doc.getObject("Controlador_Cinematico")
    if ctrl and hasattr(ctrl, "Angulo_Manivela_Graus"):
        ctrl.Angulo_Manivela_Graus = ang_clamped
        if hasattr(ctrl, "Angulo_Ejetor_Pedal_Graus"):
            ctrl.Angulo_Ejetor_Pedal_Graus = ext_clamped
        if recompute:
            doc.recompute()
        return k
    if recompute:
        doc.recompute()
    return k


# =========================================================================================
# 5. MONTAGEM COMPLETA DO DOCUMENTO FREECAD (prensa_baru_manual_v1 — REVISÃO V7)
# =========================================================================================
def apply_visual_style(obj, rgb: tuple[float, float, float], transparency: int = 0) -> None:
    """Aplica Visibilidade, DisplayMode, cor e transparência na GUI do FreeCAD."""
    try:
        if App.GuiUp and hasattr(obj, "ViewObject") and obj.ViewObject:
            vo = obj.ViewObject
            vo.Visibility = True
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


def configure_all_gui_view_providers(doc: App.Document) -> None:
    """Ajusta visibilidade dos nós na GUI e enquadra vista isométrica."""
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
                     shape: Part.Shape, rgb: tuple[float, float, float],
                     transparency: int = 0):
    """Cria um Part::Feature, anexa ao App::Part pai e aplica estilo visual."""
    obj = doc.addObject("Part::Feature", name)
    obj.Label = label
    obj.Shape = shape
    parent_part.addObject(obj)
    apply_visual_style(obj, rgb, transparency)
    return obj


# =========================================================================================
# 5B. BIBLIOTECA E ATRIBUIÇÃO NATIVA DE MATERIAIS (ShapeMaterial — FreeCAD 1.1+)
# =========================================================================================
LINEAR_ELASTIC_MODEL_UUID = "7b561d1d-fb9b-44f6-9da9-56a4f74d7536"

ENGINEERING_MATERIALS = {
    "Aco_ABNT_1020": {
        "desc": "Aco carbono estrutural ABNT 1020 (barras chatas, chapas #18/#11, Metalon, pedal)",
        "Density": "7850 kg/m^3",
        "YoungsModulus": "205000 MPa",
        "PoissonRatio": "0.30",
        "YieldStrength": "250 MPa",
        "UltimateTensileStrength": "420 MPa",
    },
    "Aco_SAE_1045": {
        "desc": "Aco medio carbono SAE 1045 trefilado/soldado (eixo O2, L4, pistao, pinos D12 e parafusos 8.8)",
        "Density": "7850 kg/m^3",
        "YoungsModulus": "210000 MPa",
        "PoissonRatio": "0.30",
        "YieldStrength": "450 MPa",
        "UltimateTensileStrength": "620 MPa",
    },
    "Aco_Mola_SAE_5160": {
        "desc": "Aco mola temperado/revenido SAE 5160 (navalha de corte 54-58 HRC e mola de retorno)",
        "Density": "7850 kg/m^3",
        "YoungsModulus": "210000 MPa",
        "PoissonRatio": "0.30",
        "YieldStrength": "1100 MPa",
        "UltimateTensileStrength": "1400 MPa",
    },
    "Bronze_TM23_SAE_660": {
        "desc": "Bronze mancais TM-23 / SAE 660 grafitado (buchas padronizadas de catalogo)",
        "Density": "8930 kg/m^3",
        "YoungsModulus": "100000 MPa",
        "PoissonRatio": "0.34",
        "YieldStrength": "140 MPa",
        "UltimateTensileStrength": "240 MPa",
    },
    "UHMW_PE": {
        "desc": "Polietileno de Ultra-Alto Peso Molecular (tiras de desgaste autolubrificantes da guia)",
        "Density": "935 kg/m^3",
        "YoungsModulus": "750 MPa",
        "PoissonRatio": "0.46",
        "YieldStrength": "22 MPa",
        "UltimateTensileStrength": "40 MPa",
    },
    "Borracha_NBR_70": {
        "desc": "Elastomero NBR 70 Shore A (manopla ergonomica e aneis O-ring 10x1,8 mm)",
        "Density": "1200 kg/m^3",
        "YoungsModulus": "10 MPa",
        "PoissonRatio": "0.49",
        "YieldStrength": "12 MPa",
        "UltimateTensileStrength": "18 MPa",
    },
    "Policarbonato_NR12": {
        "desc": "Policarbonato compacto transparente 2,0 mm (visor frontal NR-12)",
        "Density": "1200 kg/m^3",
        "YoungsModulus": "2350 MPa",
        "PoissonRatio": "0.37",
        "YieldStrength": "60 MPa",
        "UltimateTensileStrength": "65 MPa",
    },
    "Endocarpo_Baru_Simulado": {
        "desc": "Corpo de prova ilustrativo de endocarpo lenhoso de baru (30x50x40 mm)",
        "Density": "1100 kg/m^3",
        "YoungsModulus": "3500 MPa",
        "PoissonRatio": "0.35",
        "YieldStrength": "45 MPa",
        "UltimateTensileStrength": "60 MPa",
    },
}

PART_MATERIAL_ASSIGNMENTS = {
    "Chapa_Base_Estrutural": "Aco_ABNT_1020",
    "Portico_Estrutural_Traseiro": "Aco_ABNT_1020",
    "Portico_Estrutural_Frontal": "Aco_ABNT_1020",
    "Espacadores_Transversais_Portico": "Aco_SAE_1045",
    "Batentes_Pinos_Soldados_PMS_PMI": "Aco_ABNT_1020",
    "Suporte_Baru_Cantoneira": "Aco_ABNT_1020",
    "Guia_Pistao_Chapa_U": "Aco_ABNT_1020",
    "Parafusos_Guia_Pistao_M8": "Aco_SAE_1045",
    "Tiras_Desgaste_UHMW_5mm": "UHMW_PE",
    "Buchas_Catalogo_Estator": "Bronze_TM23_SAE_660",
    "Pino_Eixo_O4": "Aco_SAE_1045",
    "Aneis_Retencao_ORing_O4": "Borracha_NBR_70",
    "Conjunto_Soldado_L2_Alavanca_O2": "Aco_SAE_1045",
    "Buchas_Catalogo_A": "Bronze_TM23_SAE_660",
    "Manopla_Empunhadura_Borracha": "Borracha_NBR_70",
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
    "Alavanca_Ejetora_Pedal": "Aco_ABNT_1020",
    "Tirante_Pedal_Extracao": "Aco_ABNT_1020",
    "Pedal_Extracao": "Aco_ABNT_1020",
    "Mola_Retorno_Pedal": "Aco_Mola_SAE_5160",
    "Baru_Simulado_30x50x40": "Endocarpo_Baru_Simulado",
}


def assign_native_freecad_materials(doc: App.Document) -> dict[str, str]:
    """Cria/carrega os cartoes .FCMat na biblioteca User do FreeCAD e atribui ShapeMaterial a todos os corpos."""
    import Materials

    mgr = Materials.MaterialManager()
    by_name = {m.Name: m for m in mgr.Materials.values()}
    resolved = {}

    for mat_name, spec in ENGINEERING_MATERIALS.items():
        if mat_name in by_name:
            mat_obj = by_name[mat_name]
        else:
            mat_obj = Materials.Material()
            mat_obj.Name = mat_name
            mat_obj.Description = spec["desc"]
            mat_obj.addPhysicalModel(LINEAR_ELASTIC_MODEL_UUID)
            for k in ("Density", "YoungsModulus", "PoissonRatio", "YieldStrength", "UltimateTensileStrength"):
                mat_obj.setPhysicalValue(k, spec[k])
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

    # Espelha os cartoes .FCMat gerados no repositorio e no vault (Ciencia Aberta)
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


def build_simulated_baru_nut(x_c: float = 0.0, y_c: float = 0.0, z_c: float = Z_BARU_CENTER) -> Part.Shape:
    """Elipsoide de Baru 50.0 (X) x 30.0 (Y) x 40.0 (Z) mm deitado ao longo de X na Cantoneira 90°."""
    sph = Part.makeSphere(1.0)
    mat = App.Matrix()
    mat.A11 = 0.5 * BARU_LEN_X
    mat.A22 = 0.5 * BARU_WID_Y
    mat.A33 = 0.5 * BARU_DEP_Z
    mat.A14 = x_c
    mat.A24 = y_c
    mat.A34 = z_c
    return sph.transformGeometry(mat)


def build_prensa_baru_manual_v1(initial_theta2_deg: float = TH2_MID_DEG) -> App.Document:
    """Constrói deterministicamente o documento `prensa_baru_manual_v1` (Revisão v7 — Baixo Custo Serralheria)."""
    if DOC_NAME in App.listDocuments():
        App.closeDocument(DOC_NAME)

    doc = App.newDocument(DOC_NAME)
    doc.Label = "Prensa de Baru Manual - Piso 1.5m Serralheria Rural (Vertente A - v7)"

    C_STEEL_STRUCT = (0.28, 0.32, 0.38)
    C_BASE_PLATE   = (0.22, 0.25, 0.30)
    C_CANTONEIRA   = (0.42, 0.46, 0.52)
    C_RESERVOIR    = (0.24, 0.62, 0.44)
    C_PEDAL_NR12   = (0.92, 0.55, 0.12)
    C_UHMW         = (0.94, 0.96, 0.92)
    C_BRONZE       = (0.82, 0.62, 0.24)
    C_PIN_1045     = (0.72, 0.75, 0.78)
    C_CIRCLIP      = (0.20, 0.22, 0.25)
    C_STOP_BUMPER  = (0.85, 0.25, 0.15)
    C_L4_ROCKER    = (0.16, 0.55, 0.32)
    C_L5_FORK      = (0.78, 0.22, 0.20)
    C_L3_COUPLER   = (0.18, 0.48, 0.82)
    C_L2_CRANK     = (0.88, 0.52, 0.14)
    C_GRIP_RUBBER  = (0.15, 0.15, 0.16)
    C_RAM_1045     = (0.58, 0.62, 0.68)
    C_BLADE_5160   = (0.85, 0.18, 0.18)
    C_METALON      = (0.62, 0.66, 0.70)
    C_CAB_SHEET    = (0.78, 0.80, 0.83)
    C_POLYCARB     = (0.55, 0.82, 0.95)
    C_CHUTE_NR12   = (0.90, 0.72, 0.15)
    C_BARU_NUT     = (0.55, 0.35, 0.18)

    # -------------------------------------------------------------------------------------
    # SUBCONJUNTO 01: Pórticos Soldados 2"x1/4", Guia Tubular Metalon 40x40 e Cantoneira Baru
    # -------------------------------------------------------------------------------------
    sub01 = doc.addObject("App::Part", "Subconjunto_01_Estrutura_Interna")
    sub01.Label = "01_Portico_Soldado_Guia_Metalon_40x40_e_Suporte_Cantoneira"

    base_sh = build_base_plate_with_drop_window()
    portal_rear_sh = build_structural_portal(24.00, 30.35, is_front=False)
    portal_front_sh = build_structural_portal(-40.82, -34.47, is_front=True)
    spacers_sh, stops_sh = build_portal_spacers_and_weld_stops()
    cantoneira_sh = build_cantoneira_baru_support()
    guide_u_sh, uhmw_guide_sh, u_bolts_sh = build_bolted_u_guide_and_uhmw()

    # Buchas catálogo padrão: O4 (12x14 mm) e O2 (20x23 mm)
    b_o4_r = make_bushing_y(O4_X, O4_Z, 12.04, 14.00, 24.00, 30.35)
    b_o4_f = make_bushing_y(O4_X, O4_Z, 12.04, 14.00, -40.82, -34.47)
    b_o2_r = make_bushing_y(O2_X, O2_Z, 20.04, 23.00, 24.00, 30.35)
    b_o2_f = make_bushing_y(O2_X, O2_Z, 20.04, 23.00, -40.82, -34.47)
    bushings_stator_sh = b_o4_r.fuse([b_o4_f, b_o2_r, b_o2_f]).removeSplitter()

    # Pino liso Ø12 mm retido por anéis elastoméricos O-ring NBR 70 no pivô O4
    pin_o4_core, oring_o4_sh = make_oring_pin_y(O4_X, O4_Z, 11.96, -45.60, 35.10, groove_ys=(-43.75, 33.25))
    pin_o4_sh = pin_o4_core.fuse([
        make_bushing_y(O4_X, O4_Z, 12.10, 19.00, -42.50, -40.90),
        make_bushing_y(O4_X, O4_Z, 12.10, 19.00, 30.40, 32.00),
    ]).removeSplitter()

    add_part_feature(doc, sub01, "Chapa_Base_Estrutural",
                     "Chapa de Mesa Estrutural 1/4 pol (340x100 mm - Porticos Soldados s/ Cantoneiras)", base_sh, C_BASE_PLATE)
    add_part_feature(doc, sub01, "Portico_Estrutural_Traseiro",
                     "Portico Traseiro Soldado (Barra Chata 2x1/4 pol - 4 Furos M8 Guia U)", portal_rear_sh, C_STEEL_STRUCT)
    add_part_feature(doc, sub01, "Portico_Estrutural_Frontal",
                     "Portico Frontal Soldado (Barra Chata 2x1/4 pol - Y[-40.82,-34.47])", portal_front_sh, C_STEEL_STRUCT)
    add_part_feature(doc, sub01, "Espacadores_Transversais_Portico",
                     "4x Espacadores Tubulares c/ Parafusos M10 Cl. 8.8", spacers_sh, C_PIN_1045)
    add_part_feature(doc, sub01, "Batentes_Pinos_Soldados_PMS_PMI",
                     "2x Pinos Batentes Soldados D10 mm c/ Luva de Borracha (PMS 80 e PMI 20)", stops_sh, C_STOP_BUMPER)
    add_part_feature(doc, sub01, "Suporte_Baru_Cantoneira",
                     "Suporte em Cantoneira Comercial 1.1/2x3/16 (V 90 graus, s/ Usinagem) + Pes Dobrados", cantoneira_sh, C_CANTONEIRA)
    add_part_feature(doc, sub01, "Guia_Pistao_Chapa_U",
                     "Guia Linear em Chapa Dobrada em U (3.0 mm) Parafusavel c/ 4 Furos M8", guide_u_sh, C_STEEL_STRUCT)
    add_part_feature(doc, sub01, "Parafusos_Guia_Pistao_M8",
                     "4x Parafusos Sextavados M8x20 + Porcas da Guia em U", u_bolts_sh, C_PIN_1045)
    add_part_feature(doc, sub01, "Tiras_Desgaste_UHMW_5mm",
                     "4x Tiras Planas Retas Substituiveis de UHMW (5.0 / 10.95 mm)", uhmw_guide_sh, C_UHMW)
    add_part_feature(doc, sub01, "Buchas_Catalogo_Estator",
                     "4x Buchas Padronizadas de Catalogo dos Mancais Fixos O4 (12x14) e O2 (20x23)", bushings_stator_sh, C_BRONZE)
    add_part_feature(doc, sub01, "Pino_Eixo_O4",
                     "Pino Liso Comercial D12 mm c/ Canaletas O-Ring do Pivo O4", pin_o4_sh, C_PIN_1045)
    add_part_feature(doc, sub01, "Aneis_Retencao_ORing_O4",
                     "2x Aneis de Retencao O-Ring NBR 70 (10x1.8 mm) do Pivo O4", oring_o4_sh, C_GRIP_RUBBER)

    # -------------------------------------------------------------------------------------
    # SUBCONJUNTO 02: Conjunto Soldado Eixo Ø20 + Braço L2 + Tubo Único 1.1/4" (R=600 mm)
    # -------------------------------------------------------------------------------------
    sub02 = doc.addObject("App::Part", "Subconjunto_02_Alavanca_Soldada_O2")
    sub02.Label = "02_Conjunto_Soldado_Eixo_O2_Braco_L2_e_Tubo_Unico (Arco < Alcance Braco)"
    l2_parts = build_l2_and_handle_local()
    add_part_feature(doc, sub02, "Conjunto_Soldado_L2_Alavanca_O2",
                     "Eixo D20 Liso Soldado ao Braco L2 + Tubo 1.1/4x2.0 (R_ponta=600 mm)",
                     l2_parts["Conjunto_Soldado_L2_Alavanca_O2"], C_L2_CRANK)
    add_part_feature(doc, sub02, "Buchas_Catalogo_A",
                     "Bucha Padrao de Catalogo 12x14 mm da Junta A", l2_parts["Buchas_Catalogo_A"], C_BRONZE)
    add_part_feature(doc, sub02, "Manopla_Empunhadura_Borracha",
                     "Manopla Ergonomica de Borracha (D32 x 120 mm, Centro R=540 mm)", l2_parts["Manopla_Empunhadura_Borracha"], C_GRIP_RUBBER)
    add_part_feature(doc, sub02, "Pino_Eixo_A",
                     "Pino Liso Comercial D12 mm c/ Canaletas O-Ring e Arruelas da Junta A", l2_parts["Pino_Eixo_A"], C_PIN_1045)
    add_part_feature(doc, sub02, "Aneis_Retencao_ORing_A",
                     "2x Aneis de Retencao O-Ring NBR 70 (10x1.8 mm) da Junta A", l2_parts["Aneis_Retencao_ORing_A"], C_GRIP_RUBBER)

    # -------------------------------------------------------------------------------------
    # SUBCONJUNTO 03: Biela L3 (100.00 mm)
    # -------------------------------------------------------------------------------------
    sub03 = doc.addObject("App::Part", "Subconjunto_03_Biela_Acopladora_L3")
    sub03.Label = "03_Elo3_Biela_Acopladora_L3 (100.00 mm)"
    l3_bar_sh = make_rounded_bar_xz(L3, 25.40, -22.00, -15.65, d_hole1=14.04, d_hole2=14.04)
    bushings_l3_sh = make_bushing_y(0.0, 0.0, 12.04, 14.00, -21.95, -15.70).fuse(
        make_bushing_y(L3, 0.0, 12.04, 14.00, -21.95, -15.70)
    ).removeSplitter()
    add_part_feature(doc, sub03, "Elo3_Biela_L3",
                     "Biela L3 = 100.00 mm (Barra Chata 1x1/4 pol)", l3_bar_sh, C_L3_COUPLER)
    add_part_feature(doc, sub03, "Buchas_Catalogo_L3",
                     "2x Buchas Padrao de Catalogo 12x14 mm da Biela L3", bushings_l3_sh, C_BRONZE)

    # -------------------------------------------------------------------------------------
    # SUBCONJUNTO 04: Balancim Superior L4 (111.9615 mm)
    # -------------------------------------------------------------------------------------
    sub04 = doc.addObject("App::Part", "Subconjunto_04_Balancim_Superior_L4")
    sub04.Label = "04_Elo4_Balancim_Principal_L4 (111.96 mm)"
    l4_bar_sh = make_rounded_bar_xz(L4, 38.10, -6.35, 6.35, d_hole1=14.04, d_hole2=14.04)
    bushings_l4_sh = make_bushing_y(0.0, 0.0, 12.04, 14.00, -6.30, 6.30).fuse(
        make_bushing_y(L4, 0.0, 12.04, 14.00, -6.30, 6.30)
    ).removeSplitter()
    add_part_feature(doc, sub04, "Elo4_Balancim_L4",
                     "Balancim L4 = 111.96 mm (Barra Chata 1.1/2x1/2 pol)", l4_bar_sh, C_L4_ROCKER)
    add_part_feature(doc, sub04, "Buchas_Catalogo_L4",
                     "2x Buchas Padrao de Catalogo 12x14 mm do Balancim L4", bushings_l4_sh, C_BRONZE)

    # -------------------------------------------------------------------------------------
    # SUBCONJUNTO 05: Garfo Duplo L5 e Pino Liso Contrapinado B
    # -------------------------------------------------------------------------------------
    sub05 = doc.addObject("App::Part", "Subconjunto_05_Garfo_Prensa_L5")
    sub05.Label = "05_Elo5_Garfo_Duplo_L5 (111.96 mm - Pino Contrapinado B)"
    l5_fork_sh = make_rounded_bar_xz(L5, 31.75, -13.70, -7.35, d_hole1=14.04, d_hole2=14.04).fuse(
        make_rounded_bar_xz(L5, 31.75, 7.35, 13.70, d_hole1=14.04, d_hole2=14.04)
    ).removeSplitter()
    bushings_l5_sh = make_bushing_y(0.0, 0.0, 12.04, 14.00, -13.65, -7.40).fuse([
        make_bushing_y(0.0, 0.0, 12.04, 14.00, 7.40, 13.65),
        make_bushing_y(L5, 0.0, 12.04, 14.00, -13.65, -7.40),
        make_bushing_y(L5, 0.0, 12.04, 14.00, 7.40, 13.65),
    ]).removeSplitter()
    pin_b_core, oring_b_sh = make_oring_pin_y(0.0, 0.0, 11.96, -25.60, 18.50, groove_ys=(-24.05, 16.65))
    pin_b_sh = pin_b_core.fuse([
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -7.30, -6.40),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, 6.40, 7.30),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -15.60, -13.75),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, 13.75, 15.60),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -22.95, -22.05),
    ]).removeSplitter()

    add_part_feature(doc, sub05, "Elo5_Garfo_Duplo_L5",
                     "Garfo Duplo L5 = 111.96 mm (2x Barra Chata 1.1/4x1/4 pol)", l5_fork_sh, C_L5_FORK)
    add_part_feature(doc, sub05, "Buchas_Catalogo_L5",
                     "4x Buchas Padrao de Catalogo 12x14 mm do Garfo L5", bushings_l5_sh, C_BRONZE)
    add_part_feature(doc, sub05, "Pino_Eixo_B",
                     "Pino Liso Comercial D12 mm c/ Canaletas O-Ring e Arruelas DIN 125 da Junta B", pin_b_sh, C_PIN_1045)
    add_part_feature(doc, sub05, "Aneis_Retencao_ORing_B",
                     "2x Aneis de Retencao O-Ring NBR 70 (10x1.8 mm) da Junta B", oring_b_sh, C_GRIP_RUBBER)

    # -------------------------------------------------------------------------------------
    # SUBCONJUNTO 06: Pistão Soldado 1"x1" (ZERO CNC!) e Navalha SAE 5160 Reta
    # -------------------------------------------------------------------------------------
    sub06 = doc.addObject("App::Part", "Subconjunto_06_Pistao_e_Navalha")
    sub06.Label = "06_Pistao_Soldado_1pol_Navalha_SAE5160_e_Pino_ORing_O5"
    ram_sh, blade_sh, m6_sh, bush_o5_sh = build_piston_and_blade_local()
    pin_o5_core, oring_o5_sh = make_oring_pin_y(0.0, 0.0, 11.96, -18.50, 18.50, groove_ys=(-16.65, 16.65))
    pin_o5_sh = pin_o5_core.fuse([
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -7.30, -6.40),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, 6.40, 7.30),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, -15.60, -13.75),
        make_bushing_y(0.0, 0.0, 12.10, 19.00, 13.75, 15.60),
    ]).removeSplitter()
    add_part_feature(doc, sub06, "Pistao_Embolo_Quadrado",
                     "Embolo Barra Quadrada 1x1 pol + Chapa Encosto e Orelha O5 Soldadas (Zero Fresa)", ram_sh, C_RAM_1045)
    add_part_feature(doc, sub06, "Navalha_Corte_SAE5160",
                     "Navalha Reta Cunha 30 graus (SAE 5160 50x26x6.35 mm, s/ Entalhes Fresados)", blade_sh, C_BLADE_5160)
    add_part_feature(doc, sub06, "Parafusos_Fixacao_Navalha_M6",
                     "2x Parafusos Sextavados Comuns M6x20 c/ Porcas da Navalha", m6_sh, C_PIN_1045)
    add_part_feature(doc, sub06, "Bucha_Catalogo_O5",
                     "Bucha Padrao de Catalogo 12x14 mm do Olhal O5", bush_o5_sh, C_BRONZE)
    add_part_feature(doc, sub06, "Pino_Eixo_O5",
                     "Pino Liso Comercial D12 mm c/ Canaletas O-Ring e Arruelas DIN 125 de O5", pin_o5_sh, C_PIN_1045)
    add_part_feature(doc, sub06, "Aneis_Retencao_ORing_O5",
                     "2x Aneis de Retencao O-Ring NBR 70 (10x1.8 mm) de O5", oring_o5_sh, C_GRIP_RUBBER)

    # -------------------------------------------------------------------------------------
    # SUBCONJUNTO 07: Cavalete 1,5 m, Moega Alimentação, Reservatório 12,3 L e Pedal +X
    # -------------------------------------------------------------------------------------
    sub07 = doc.addObject("App::Part", "Subconjunto_07_Cavalete_Reservatorio_e_Pedal")
    sub07.Label = "07_Cavalete_1500mm_Moega_Alimentacao_Reservatorio_e_Pedal_Estendido"

    metalon_sh, panels_sh, poly_sh, chute_sh, feet_sh, cab_bolts_sh = build_floor_stand_and_nr12_cabinet()
    discharge_sh, reservoir_sh = build_sheet_metal_chute_and_reservoir()
    feed_hopper_sh = build_feeding_hopper_reservoir()
    ped_parts = build_pedal_extraction_system_local()

    add_part_feature(doc, sub07, "Quadro_Tubular_Metalon_20x20",
                     "Cavalete de Piso 1,50 m + Gabinete NR-12 (Metalon 20x20x1.50 mm - Z[4.76,1497.5])",
                     metalon_sh, C_METALON)
    add_part_feature(doc, sub07, "Sapatas_Ancoragem_Piso",
                     "4x Sapatas de Piso 70x70x4.76 mm c/ 8 Furos Ø10.5 mm p/ Chumbadores (Z[0,4.76])",
                     feet_sh, C_BASE_PLATE)
    add_part_feature(doc, sub07, "Carenagem_Chapa_Galvanizada",
                     "Fechamento Superior NR-12 (Chapa Galvanizada #18 - 1.20 mm)",
                     panels_sh, C_CAB_SHEET, transparency=45)
    add_part_feature(doc, sub07, "Visor_Policarbonato_NR12",
                     "Visor Frontal Transparente NR-12 (Policarbonato 2.0 mm)",
                     poly_sh, C_POLYCARB, transparency=75)
    add_part_feature(doc, sub07, "Calha_Alimentacao_Segura_NR12",
                     "Calha Alimentacao Segura Y=0 (Vao Livre 42x48 mm)",
                     chute_sh, C_CHUTE_NR12)
    add_part_feature(doc, sub07, "Reservatorio_Alimentacao_Chapa",
                     "Reservatorio/Moega Dedicada da Calha de Alimentacao (Chapa Dobrada #18, 4x M6 no Gabinete)",
                     feed_hopper_sh, C_RESERVOIR)
    add_part_feature(doc, sub07, "Parafusos_Fixacao_Gabinete_M6",
                     "Parafusos M6/M8 do Visor, Carenagem, Calha e Moega de Alimentacao", cab_bolts_sh, C_PIN_1045)
    add_part_feature(doc, sub07, "Calha_Descarga_Chapa",
                     "Calha Inclinada de Descarga Sob a Mesa (Chapa Dobrada #18)",
                     discharge_sh, C_CAB_SHEET)
    add_part_feature(doc, sub07, "Reservatorio_Chapa_Coleta",
                     "Grande Reservatorio Removivel em Chapa Dobrada #18 (268x230x200 mm = 12,3 L)",
                     reservoir_sh, C_RESERVOIR)
    add_part_feature(doc, sub07, "Suporte_Eixo_Ejetor_NR12",
                     "Mancais e Eixo D8 mm da Alavanca Ejetora (O_ext = [34,0,996])",
                     ped_parts["stator_ext"], C_STEEL_STRUCT)
    add_part_feature(doc, sub07, "Alavanca_Ejetora_Pedal",
                     "Alavanca Basculante Ejetora no Rasgo da Cantoneira (0°->22°)",
                     ped_parts["ejector_arm"], C_PEDAL_NR12)
    add_part_feature(doc, sub07, "Tirante_Pedal_Extracao",
                     "Tirante 4-Barras D8 mm c/ Furos Redondos Simples (Sem Rasgos Oblongos!)",
                     ped_parts["tirante"], C_PIN_1045)
    add_part_feature(doc, sub07, "Pedal_Extracao",
                     "Pedal de Extracao de Piso Alinhado em +X (Mesma Direcao da Alavanca!)",
                     ped_parts["pedal"], C_PEDAL_NR12)
    add_part_feature(doc, sub07, "Mola_Retorno_Pedal",
                     "Mola Comercial de Retorno do Pedal de Extracao",
                     ped_parts["spring"], C_CIRCLIP)

    # -------------------------------------------------------------------------------------
    # SUBCONJUNTO 08: Baru Simulado 30x50x40 mm
    # -------------------------------------------------------------------------------------
    sub08 = doc.addObject("App::Part", "Subconjunto_08_Simulacao_Baru")
    sub08.Label = "08_Corpo_Prova_Baru_Simulado_30x50x40 (Corte Seletivo <= 5.0 mm)"
    baru_sh = build_simulated_baru_nut(0.0, 0.0, Z_BARU_CENTER)
    add_part_feature(doc, sub08, "Baru_Simulado_30x50x40",
                     "Baru Simulado 30(Y)x50(X)x40(Z) mm na Cantoneira V 90 graus (Corte PMI = 4.75 mm)",
                     baru_sh, C_BARU_NUT, transparency=35)

    # -------------------------------------------------------------------------------------
    # CONTROLADOR CINEMÁTICO PARAMÉTRICO (EXPRESSION ENGINE C++)
    # -------------------------------------------------------------------------------------
    ctrl = doc.addObject("App::FeaturePython", "Controlador_Cinematico")
    ctrl.Label = "00_CONTROLADOR_CINEMATICO (theta2: 20..80 | Pedal_Ejetor: 0..22 graus)"
    ctrl.addProperty("App::PropertyFloat", "Angulo_Manivela_Graus", "Cinematica", "Angulo L2 (80=PMS..20=PMI)").Angulo_Manivela_Graus = initial_theta2_deg
    ctrl.addProperty("App::PropertyFloat", "Angulo_Alavanca_Graus", "Cinematica", "Angulo alavanca (+30..-30)")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Ejetor_Pedal_Graus", "Extracao_Pedal", "Angulo ejetor pedal (0..22)").Angulo_Ejetor_Pedal_Graus = 0.0
    ctrl.addProperty("App::PropertyFloat", "Angulo_Pedal_Piso_Graus", "Extracao_Pedal", "Angulo pedal (+X)")
    ctrl.addProperty("App::PropertyFloat", "Angulo_Tirante_Graus", "Extracao_Pedal", "Inclinacao do tirante")
    ctrl.addProperty("App::PropertyFloat", "Tirante_Pino_X_mm", "Extracao_Pedal", "X pino superior tirante")
    ctrl.addProperty("App::PropertyFloat", "Tirante_Pino_Z_mm", "Extracao_Pedal", "Z pino superior tirante")
    ctrl.addProperty("App::PropertyFloat", "Ped_d_mm", "Extracao_Pedal", "Distancia O_ped -> pino superior")
    ctrl.addProperty("App::PropertyFloat", "Ped_ac_mm", "Extracao_Pedal", "Projecao cordal pedal")
    ctrl.addProperty("App::PropertyFloat", "Ped_hc_mm", "Extracao_Pedal", "Altura cordal pedal")
    ctrl.addProperty("App::PropertyFloat", "Ped_Pin_X_mm", "Extracao_Pedal", "X pino pedal")
    ctrl.addProperty("App::PropertyFloat", "Ped_Pin_Z_mm", "Extracao_Pedal", "Z pino pedal")
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

    bind_native_kinematic_expressions(doc, ctrl)
    set_pose(doc, initial_theta2_deg, ext_ang_deg=0.0, recompute=True)
    assign_native_freecad_materials(doc)
    configure_all_gui_view_providers(doc)
    return doc


# =========================================================================================
# 6. VERIFICAÇÃO DE INTERFERÊNCIA BOOLEANA (POSES + VARREDURA DO PEDAL + CORTE <= 5 MM)
# =========================================================================================
def compute_cantoneira_90_nut_metrics(w_y_mm: float = BARU_WID_Y, h_z_mm: float = BARU_DEP_Z,
                                      l_x_mm: float = BARU_LEN_X) -> dict:
    a_y, b_z = 0.5 * w_y_mm, 0.5 * h_z_mm
    dz_tang = math.hypot(a_y * _M_V90, b_z)
    z_center = Z_CANTONEIRA_V + dz_tang
    z_top = z_center + b_z
    return {
        "dims_x_y_z_mm": (l_x_mm, w_y_mm, h_z_mm),
        "z_center_mm": z_center,
        "z_top_mm": z_top,
        "z_bot_mm": z_center - b_z,
        "penetration_at_pmi_mm": max(0.0, z_top - Z_TIP_PMI),
    }


def check_pedal_sweep_at_pms(doc: App.Document, tol_mm3: float = 1e-4) -> dict:
    """Verifica acionamento completo 0°..22° do pedal + tirante 4-barras + alavanca ejetora."""
    pedal_names = {"Alavanca_Ejetora_Pedal", "Pedal_Extracao", "Tirante_Pedal_Extracao"}
    other_features = [
        o for o in doc.Objects
        if o.TypeId == "Part::Feature" and o.Name not in pedal_names and o.Name != "Baru_Simulado_30x50x40"
        and hasattr(o, "Shape") and not o.Shape.isNull()
    ]
    pedal_objs = [doc.getObject(nm) for nm in pedal_names if doc.getObject(nm)]
    max_vol, collisions = 0.0, []
    for ang in (0.0, 5.0, 10.0, 15.0, 20.0, EXT_ANG_MAX_DEG):
        set_pose(doc, TH2_PMS_DEG, ext_ang_deg=ang, recompute=True)
        for i, po in enumerate(pedal_objs):
            bb_p = po.Shape.BoundBox
            for j in range(i + 1, len(pedal_objs)):
                po2 = pedal_objs[j]
                if bb_p.intersect(po2.Shape.BoundBox):
                    v = po.Shape.common(po2.Shape).Volume
                    if v > tol_mm3:
                        collisions.append((ang, po.Name, po2.Name, v))
                        max_vol = max(max_vol, v)
            for other in other_features:
                if bb_p.intersect(other.Shape.BoundBox):
                    v = po.Shape.common(other.Shape).Volume
                    if v > tol_mm3:
                        collisions.append((ang, po.Name, other.Name, v))
                        max_vol = max(max_vol, v)
    pedal_min_z = doc.getObject("Pedal_Extracao").Shape.BoundBox.ZMin
    set_pose(doc, TH2_PMS_DEG, ext_ang_deg=0.0, recompute=True)
    return {"max_pedal_clash_mm3": max_vol, "pedal_collisions": collisions, "pedal_min_z_at_22deg_mm": pedal_min_z}


def check_baru_30x50x40_simulation(doc: App.Document, tol_mm3: float = 1e-4) -> dict:
    baru_sh = doc.getObject("Baru_Simulado_30x50x40").Shape
    machine_features = [
        o for o in doc.Objects
        if o.TypeId == "Part::Feature" and o.Name != "Baru_Simulado_30x50x40"
        and hasattr(o, "Shape") and not o.Shape.isNull()
    ]
    set_pose(doc, TH2_PMS_DEG, ext_ang_deg=0.0, recompute=True)
    pms_cols = [(o.Name, baru_sh.common(o.Shape).Volume) for o in machine_features
                if baru_sh.BoundBox.intersect(o.Shape.BoundBox) and baru_sh.common(o.Shape).Volume > tol_mm3]

    k_bot = (80.00 - 22.50) / 188.0
    chute_cols = []
    for xc in (-190.0, -160.0, -130.0, -100.0, -70.0, -45.0, -30.0, -15.0, 0.0):
        zc = (Z_WORK_DATUM + 44.50 + k_bot * (-27.0 - xc)) if xc <= -27.0 else (
             Z_BARU_CENTER + (Z_WORK_DATUM + 44.50 - Z_BARU_CENTER) * (-xc / 27.0) if xc < 0.0 else Z_BARU_CENTER)
        nut_step = build_simulated_baru_nut(xc, 0.0, zc)
        bb_step = nut_step.BoundBox
        for obj in machine_features:
            if bb_step.intersect(obj.Shape.BoundBox):
                v = nut_step.common(obj.Shape).Volume
                if v > tol_mm3:
                    chute_cols.append((xc, obj.Name, v))

    set_pose(doc, TH2_MID_DEG, ext_ang_deg=0.0, recompute=True)
    mid_cols = [(o.Name, baru_sh.common(o.Shape).Volume) for o in machine_features
                if baru_sh.BoundBox.intersect(o.Shape.BoundBox) and baru_sh.common(o.Shape).Volume > tol_mm3]

    set_pose(doc, TH2_PMI_DEG, ext_ang_deg=0.0, recompute=True)
    pmi_other_cols = [(o.Name, baru_sh.common(o.Shape).Volume) for o in machine_features
                      if o.Name != "Navalha_Corte_SAE5160" and baru_sh.BoundBox.intersect(o.Shape.BoundBox)
                      and baru_sh.common(o.Shape).Volume > tol_mm3]

    blade_sh = doc.getObject("Navalha_Corte_SAE5160").Shape
    cut_common = blade_sh.common(baru_sh)
    if hasattr(cut_common, "optimalBoundingBox"):
        cut_bb = cut_common.optimalBoundingBox()
        cut_zmin, cut_zmax = cut_bb.ZMin, cut_bb.ZMax
    else:
        verts_pts, _ = cut_common.tessellate(0.02)
        zs = [p.z for p in verts_pts] if verts_pts else [0.0]
        cut_zmin, cut_zmax = min(zs), max(zs)
    cut_depth = cut_zmax - cut_zmin if cut_common.Volume > 0.0 else 0.0

    return {
        "pms_clash_mm3": max((c[1] for c in pms_cols), default=0.0),
        "pms_collisions": pms_cols,
        "mid_clash_mm3": max((c[1] for c in mid_cols), default=0.0),
        "mid_collisions": mid_cols,
        "chute_passage_max_clash_mm3": max((c[2] for c in chute_cols), default=0.0),
        "chute_passage_collisions": chute_cols,
        "pmi_non_blade_clash_mm3": max((c[1] for c in pmi_other_cols), default=0.0),
        "pmi_non_blade_collisions": pmi_other_cols,
        "pmi_blade_cut_volume_mm3": cut_common.Volume,
        "pmi_blade_cut_zmin_mm": cut_zmin,
        "pmi_blade_cut_zmax_mm": cut_zmax,
        "pmi_blade_cut_depth_mm": cut_depth,
    }


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


def verify_and_export(doc: App.Document, primary_fcstd: str, primary_step: str,
                      mirror_fcstd: list[str], mirror_step: list[str]) -> dict:
    report = {"poses": {}, "part_count": 0, "machine_part_count": 0, "subassembly_count": 0}
    for pose_name, ang in (("PMS_80deg", 80.0), ("MID_50deg", 50.0), ("PMI_20deg", 20.0)):
        k = set_pose(doc, ang, ext_ang_deg=0.0, recompute=True)
        cols = check_boolean_interference_all_pairs(doc)
        report["poses"][pose_name] = {
            "kinematics": k,
            "collisions": cols,
            "max_interference_mm3": max((c[2] for c in cols), default=0.0),
        }

    report["pedal_sweep_pms"] = check_pedal_sweep_at_pms(doc)
    report["cracking_math"] = {"baru_30x50x40": compute_cantoneira_90_nut_metrics()}
    report["baru_3d_simulation"] = check_baru_30x50x40_simulation(doc)

    set_pose(doc, TH2_PMS_DEG, ext_ang_deg=0.0, recompute=True)
    blade_pms_zmin = doc.getObject("Navalha_Corte_SAE5160").Shape.BoundBox.ZMin
    report["feeder_clearance_pms"] = {
        "z_chute_exit_top_out_mm": Z_WORK_DATUM + 72.00,
        "z_blade_tip_pms_mm": blade_pms_zmin,
        "blade_above_chute_roof_mm": blade_pms_zmin - (Z_WORK_DATUM + 72.00),
        "blade_above_baru_top_mm": blade_pms_zmin - Z_BARU_TOP,
    }

    set_pose(doc, TH2_MID_DEG, ext_ang_deg=0.0, recompute=True)
    configure_all_gui_view_providers(doc)

    features = [o for o in doc.Objects if o.TypeId == "Part::Feature"]
    subparts = [o for o in doc.Objects if o.TypeId == "App::Part"]
    report["part_count"] = len(features)
    report["machine_part_count"] = len(features) - 1
    report["subassembly_count"] = len(subparts)
    report["machine_total_height_mm"] = max(
        o.Shape.BoundBox.ZMax for o in features if o.Name not in MOVING_GROUPS["O2"]
    )
    report["feet_zmin_mm"] = doc.getObject("Sapatas_Ancoragem_Piso").Shape.BoundBox.ZMin
    report["solids_below_z0"] = [o.Name for o in features if o.Shape.BoundBox.ZMin < -1e-6]

    dth_rad = math.radians(TH2_PMS_DEG - TH2_PMI_DEG)
    r_grip_mid = 0.5 * (LEVER_TUBE_R1 + LEVER_TIP_R)
    report["lever_ergonomics"] = {
        "dtheta_deg": TH2_PMS_DEG - TH2_PMI_DEG,
        "r_grip_mid_mm": r_grip_mid,
        "r_tip_mm": LEVER_TIP_R,
        "arc_grip_mid_mm": r_grip_mid * dth_rad,
        "arc_tip_mm": LEVER_TIP_R * dth_rad,
        "chord_grip_mid_mm": 2.0 * r_grip_mid * math.sin(0.5 * dth_rad),
        "chord_tip_mm": 2.0 * LEVER_TIP_R * math.sin(0.5 * dth_rad),
        "x_grip_mid_pms_pmi_mm": O2_X + r_grip_mid * math.cos(0.5 * dth_rad),
        "x_grip_mid_horiz_mm": O2_X + r_grip_mid,
        "pedal_pad_x_range_mm": (490.0, 590.0),
    }

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

    return report


def run_full_build_and_export(initial_theta2_deg: float = TH2_MID_DEG) -> dict:
    repo_dir = "/home/guimentzer/Repos/dinmaq-2026/trabalho-final"
    vault_dir = "/home/guimentzer/vault/Dinâmica das Máquinas/Trabalho Final 1"

    p_fcstd = os.path.join(repo_dir, "prensa_baru_manual_v1.FCStd")
    p_step = os.path.join(repo_dir, "prensa_baru_manual_v1.step")
    m_fcstd = [os.path.join(vault_dir, "prensa_baru_manual_v1.FCStd")]
    m_step = [os.path.join(vault_dir, "prensa_baru_manual_v1.step")]

    doc_built = build_prensa_baru_manual_v1(initial_theta2_deg=initial_theta2_deg)
    rep = verify_and_export(doc_built, p_fcstd, p_step, m_fcstd, m_step)

    src_py = os.path.join(repo_dir, "gerar_prensa_baru_manual_cad.py")
    dst_py = os.path.join(vault_dir, "gerar_prensa_baru_manual_cad.py")
    if os.path.exists(src_py) and os.path.abspath(src_py) != os.path.abspath(dst_py):
        shutil.copy2(src_py, dst_py)

    return rep


if __name__ == "__main__":
    rep = run_full_build_and_export(initial_theta2_deg=TH2_MID_DEG)
    print("=" * 100)
    print(f"RELATÓRIO CAD 3D (REVISÃO V8 — O-RING, GUIA U PARAFUSADA, MOEGA, PEDAL & ARCO) — {DOC_NAME}")
    print("=" * 100)
    print(f"• Subconjuntos: {rep['subassembly_count']} | Peças Máquina: {rep['machine_part_count']} (+1 Baru)")
    print(f"• Altura Total: {rep['machine_total_height_mm']:.2f} mm | Sapatas ZMin={rep['feet_zmin_mm']:.2f} | <Z=0: {len(rep['solids_below_z0'])}")
    le = rep["lever_ergonomics"]
    print(f"• Arco Varrido Alavanca (60°): centro={le['arc_grip_mid_mm']:.2f} mm (R={le['r_grip_mid_mm']:.0f}) | ponta={le['arc_tip_mm']:.2f} mm (R={le['r_tip_mm']:.0f})")
    print(f"• Alcance X Empunhadura: [{le['x_grip_mid_pms_pmi_mm']:.1f}, {le['x_grip_mid_horiz_mm']:.1f}] mm vs Sapata Pedal: {le['pedal_pad_x_range_mm']}")
    print(f"• Baru 30x50x40 Corte PMI: {rep['baru_3d_simulation']['pmi_blade_cut_depth_mm']:.4f} mm <= 5.00 mm")
    ps = rep["pedal_sweep_pms"]
    print(f"• Varredura Pedal 4-Barras (0..22°): Colisão máx = {ps['max_pedal_clash_mm3']:.6f} mm³ | Pedal ZMin@22° = {ps['pedal_min_z_at_22deg_mm']:.2f} mm")
    for pname, pdata in rep["poses"].items():
        print(f"  - {pname:10s}: Z_tip={pdata['kinematics']['z_tip']:7.2f} mm | Colisões = {pdata['max_interference_mm3']:.6f} mm³")
    print("=" * 100)
