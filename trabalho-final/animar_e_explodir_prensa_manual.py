# =========================================================================
# Macro FreeCAD: Animador 3D (Alavanca + Pedal +X) + Vista Explodida
# Prensa Manual de Baru de Piso 1,5 m (Vertente A v8 — O-Ring, Guia U, Moega & Pedal)
# Trabalho Final 1 - Dinâmica das Máquinas (UFG - Ciência Aberta)
# =========================================================================
# COMO USAR NO FREECAD:
#   Opção 1: Menu superior -> Macro -> Macros... -> selecione
#            "Animador_e_Explodido_Prensa_Baru.FCMacro" -> Executar.
#   Opção 2: No Console Python do FreeCAD (apenas 1 linha!):
#            exec(open("/home/guimentzer/Repos/dinmaq-2026/trabalho-final/animar_e_explodir_prensa_manual.py").read())
# =========================================================================

import math
import FreeCAD as App
import FreeCADGui as Gui

try:
    from PySide6 import QtCore, QtWidgets
except ImportError:
    try:
        from PySide2 import QtCore, QtWidgets
    except ImportError:
        from PySide import QtCore, QtGui as QtWidgets


Z_BARU_TOP = 1042.2500

# Vetores de explosão (dx, dy, dz) em mm a 100%.
# Regra: peças móveis controladas no plano XZ pelo ExpressionEngine (O2, L3, L4, L5, O5,
# Alavanca_Ejetora_Pedal, Tirante_Pedal_Extracao, Pedal_Extracao) recebem deslocamento
# puramente axial em Y (dy), permitindo animar alavanca e pedal MESMO com vista explodida!
EXPLODE_VECTORS = {
    # Subconjunto 07 - Cavalete 1,5 m, Carenagem, Reservatório 12,3 L & Pedal +X
    "Sapatas_Ancoragem_Piso":           (0.0,    0.0,  -85.0),
    "Quadro_Tubular_Metalon_20x20":     (0.0,  160.0,    0.0),
    "Carenagem_Chapa_Galvanizada":      (0.0,  260.0,   45.0),
    "Visor_Policarbonato_NR12":         (0.0, -280.0,  -15.0),
    "Parafusos_Fixacao_Gabinete_M6":    (0.0, -320.0,  -15.0),
    "Calha_Alimentacao_Segura_NR12":   (-150.0,  0.0,   25.0),
    "Reservatorio_Alimentacao_Chapa":  (-255.0,  0.0,   45.0),
    "Calha_Descarga_Chapa":             (0.0,  -90.0,  -45.0),
    "Reservatorio_Chapa_Coleta":        (0.0, -260.0,  -60.0),
    "Suporte_Eixo_Ejetor_NR12":         (45.0,   0.0,   15.0),
    "Alavanca_Ejetora_Pedal":           (0.0,  -45.0,    0.0),
    "Tirante_Pedal_Extracao":           (0.0,  -80.0,    0.0),
    "Pedal_Extracao":                   (0.0, -110.0,    0.0),
    "Mola_Retorno_Pedal":               (55.0,  40.0,    0.0),

    # Subconjunto 01 - Pórticos 2"x1/4", Guia U Parafusada e Cantoneira V 90°
    "Chapa_Base_Estrutural":            (0.0,    0.0,  -45.0),
    "Portico_Estrutural_Traseiro":      (0.0,   75.0,    0.0),
    "Espacadores_Transversais_Portico": (0.0,   42.0,    0.0),
    "Buchas_Catalogo_Estator":          (0.0,   58.0,    0.0),
    "Pino_Eixo_O4":                     (0.0,  -55.0,    0.0),
    "Aneis_Retencao_ORing_O4":          (0.0,  -72.0,    0.0),
    "Portico_Estrutural_Frontal":       (0.0, -145.0,    0.0),
    "Batentes_Pinos_Soldados_PMS_PMI":  (0.0, -165.0,    0.0),
    "Guia_Pistao_Chapa_U":              (0.0,  -22.0,    0.0),
    "Parafusos_Guia_Pistao_M8":         (0.0,  -48.0,    0.0),
    "Tiras_Desgaste_UHMW_5mm":          (0.0,   18.0,    0.0),
    "Suporte_Baru_Cantoneira":          (0.0,    0.0,  -22.0),

    # Subconjunto 08 - Baru Simulado
    "Baru_Simulado_30x50x40":           (0.0,    0.0,   15.0),

    # Subconjunto 04 - Balancim L4 (plano central)
    "Elo4_Balancim_L4":                 (0.0,    0.0,    0.0),
    "Buchas_Catalogo_L4":               (0.0,   18.0,    0.0),

    # Subconjunto 05 - Garfo Duplo L5
    "Elo5_Garfo_Duplo_L5":              (0.0,  -18.0,    0.0),
    "Buchas_Catalogo_L5":               (0.0,  -32.0,    0.0),
    "Pino_Eixo_B":                      (0.0,  -56.0,    0.0),
    "Aneis_Retencao_ORing_B":           (0.0,  -72.0,    0.0),

    # Subconjunto 06 - Pistão Soldado e Navalha
    "Pistao_Embolo_Quadrado":           (0.0,    0.0,    0.0),
    "Bucha_Catalogo_O5":                (0.0,  -16.0,    0.0),
    "Navalha_Corte_SAE5160":            (0.0,  -30.0,    0.0),
    "Parafusos_Fixacao_Navalha_M6":     (0.0,  -52.0,    0.0),
    "Pino_Eixo_O5":                     (0.0,  -44.0,    0.0),
    "Aneis_Retencao_ORing_O5":          (0.0,  -60.0,    0.0),

    # Subconjunto 03 - Biela L3
    "Elo3_Biela_L3":                    (0.0,  -62.0,    0.0),
    "Buchas_Catalogo_L3":               (0.0,  -78.0,    0.0),

    # Subconjunto 02 - Conjunto Soldado O2 + L2 + Tubo Único
    "Conjunto_Soldado_L2_Alavanca_O2":  (0.0, -105.0,    0.0),
    "Buchas_Catalogo_A":                (0.0, -120.0,    0.0),
    "Pino_Eixo_A":                      (0.0, -135.0,    0.0),
    "Aneis_Retencao_ORing_A":           (0.0, -150.0,    0.0),
    "Manopla_Empunhadura_Borracha":     (0.0, -145.0,    0.0),
}


class PainelAnimacaoExplodidaBaru(QtWidgets.QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.doc = App.getDocument("prensa_baru_manual_v1") or App.ActiveDocument
        if not self.doc:
            raise RuntimeError("Abra o documento 'prensa_baru_manual_v1.FCStd' antes de iniciar.")
        self.ctrl = self.doc.getObject("Controlador_Cinematico")

        self.base_xyz = {}
        for name in EXPLODE_VECTORS:
            obj = self.doc.getObject(name)
            if obj:
                b = obj.Placement.Base
                self.base_xyz[name] = (float(b.x), float(b.y), float(b.z))

        self.fps = 30
        self.speed = 1.0
        self.t_cycle = 0.0
        self.explode_frac = 0.0
        self.include_pedal = True

        self.timer = QtCore.QTimer(self)
        self.timer.timeout.connect(self._tick)
        self._init_ui()
        self._sync_from_doc()

    def _init_ui(self):
        self.setWindowTitle("Prensa de Baru v8 — O-Rings, Guia U, Moega & Pedal +X")
        self.resize(430, 480)
        self.setWindowFlags(QtCore.Qt.WindowStaysOnTopHint | QtCore.Qt.Tool)

        lay = QtWidgets.QVBoxLayout(self)

        self.lbl_info = QtWidgets.QLabel()
        self.lbl_info.setAlignment(QtCore.Qt.AlignCenter)
        self.lbl_info.setStyleSheet(
            "font-weight: bold; font-size: 12px; padding: 6px; "
            "background: #1e293b; color: #f8fafc; border-radius: 5px;"
        )
        lay.addWidget(self.lbl_info)

        # ---- Seção 1: Ciclo Cinemático (Alavanca + Pedal) ----
        grp_anim = QtWidgets.QGroupBox("1. Ciclo Senoidal (1,0 s Descida + 2,0 s Subida) & Pedal +X")
        la = QtWidgets.QVBoxLayout(grp_anim)

        la.addWidget(QtWidgets.QLabel("Ângulo Manivela / Alavanca (θ₂: 20° PMI → 80° PMS):"))
        self.slider_th2 = QtWidgets.QSlider(QtCore.Qt.Horizontal)
        self.slider_th2.setRange(200, 800)
        self.slider_th2.valueChanged.connect(self._on_th2_slider)
        la.addWidget(self.slider_th2)

        la.addWidget(QtWidgets.QLabel("Pedal de Extração (+X) no PMS (0° Repouso → 22° Ejeção):"))
        self.slider_ped = QtWidgets.QSlider(QtCore.Qt.Horizontal)
        self.slider_ped.setRange(0, 220)
        self.slider_ped.valueChanged.connect(self._on_ped_slider)
        la.addWidget(self.slider_ped)

        row_btn = QtWidgets.QHBoxLayout()
        self.btn_play = QtWidgets.QPushButton("▶ Play Ciclo")
        self.btn_play.setStyleSheet("font-weight: bold; background: #2e7d32; color: white; padding: 6px;")
        self.btn_play.clicked.connect(self._toggle_play)
        row_btn.addWidget(self.btn_play)

        btn_pms = QtWidgets.QPushButton("PMS (80°)")
        btn_pms.clicked.connect(lambda: self._jump_angle(80.0, 0.0))
        row_btn.addWidget(btn_pms)

        btn_mid = QtWidgets.QPushButton("Meio (50°)")
        btn_mid.clicked.connect(lambda: self._jump_angle(50.0, 0.0))
        row_btn.addWidget(btn_mid)

        btn_pmi = QtWidgets.QPushButton("PMI (20°)")
        btn_pmi.clicked.connect(lambda: self._jump_angle(20.0, 0.0))
        row_btn.addWidget(btn_pmi)

        btn_ped = QtWidgets.QPushButton("Pisar Pedal")
        btn_ped.clicked.connect(lambda: self._jump_angle(80.0, 22.0))
        row_btn.addWidget(btn_ped)
        la.addLayout(row_btn)

        row_spd = QtWidgets.QHBoxLayout()
        row_spd.addWidget(QtWidgets.QLabel("Velocidade:"))
        self.spin_speed = QtWidgets.QDoubleSpinBox()
        self.spin_speed.setRange(0.25, 3.0)
        self.spin_speed.setSingleStep(0.25)
        self.spin_speed.setValue(1.0)
        self.spin_speed.setSuffix("x")
        self.spin_speed.valueChanged.connect(lambda v: setattr(self, "speed", float(v)))
        row_spd.addWidget(self.spin_speed)

        self.chk_pedal = QtWidgets.QCheckBox("Acionar Pedal (+X) após subida ao PMS")
        self.chk_pedal.setChecked(True)
        self.chk_pedal.stateChanged.connect(self._on_pedal_toggled)
        row_spd.addWidget(self.chk_pedal)
        la.addLayout(row_spd)
        lay.addWidget(grp_anim)

        # ---- Seção 2: Vista Explodida ----
        grp_exp = QtWidgets.QGroupBox("2. Vista Explodida Interativa (0% → 100%)")
        le = QtWidgets.QVBoxLayout(grp_exp)

        self.lbl_exp = QtWidgets.QLabel("Fator de Explosão: 0%")
        le.addWidget(self.lbl_exp)

        self.slider_exp = QtWidgets.QSlider(QtCore.Qt.Horizontal)
        self.slider_exp.setRange(0, 100)
        self.slider_exp.setValue(0)
        self.slider_exp.valueChanged.connect(self._on_explode_slider)
        le.addWidget(self.slider_exp)

        row_exp = QtWidgets.QHBoxLayout()
        b_asm = QtWidgets.QPushButton("Montada (0%)")
        b_asm.clicked.connect(lambda: self.slider_exp.setValue(0))
        b_half = QtWidgets.QPushButton("Semi (50%)")
        b_half.clicked.connect(lambda: self.slider_exp.setValue(50))
        b_full = QtWidgets.QPushButton("Explodida (100%)")
        b_full.clicked.connect(lambda: self.slider_exp.setValue(100))
        row_exp.addWidget(b_asm)
        row_exp.addWidget(b_half)
        row_exp.addWidget(b_full)
        le.addLayout(row_exp)
        lay.addWidget(grp_exp)

        # ---- Seção 3: Visualização / Câmera ----
        row_vis = QtWidgets.QHBoxLayout()
        self.chk_shroud = QtWidgets.QCheckBox("Mostrar Carenagem/Visor")
        self.chk_shroud.setChecked(True)
        self.chk_shroud.stateChanged.connect(self._toggle_shroud)
        row_vis.addWidget(self.chk_shroud)

        btn_fit = QtWidgets.QPushButton("Enquadrar (Fit All)")
        btn_fit.clicked.connect(self._fit_view)
        row_vis.addWidget(btn_fit)
        lay.addLayout(row_vis)

    def _fit_view(self):
        v = Gui.getDocument(self.doc.Name).ActiveView
        if v:
            v.fitAll()
            Gui.updateGui()

    def _toggle_shroud(self, state):
        vis = bool(state)
        for name in ("Carenagem_Chapa_Galvanizada", "Visor_Policarbonato_NR12", "Parafusos_Fixacao_Gabinete_M6"):
            o = self.doc.getObject(name)
            if o and hasattr(o, "ViewObject") and o.ViewObject:
                o.ViewObject.Visibility = vis
        Gui.updateGui()

    def _on_pedal_toggled(self, state):
        self.include_pedal = bool(state)
        if not self.include_pedal and self.ctrl and hasattr(self.ctrl, "Angulo_Ejetor_Pedal_Graus"):
            self.ctrl.Angulo_Ejetor_Pedal_Graus = 0.0
            self.doc.recompute()
            self._sync_from_doc()
            Gui.updateGui()

    def _apply_explode(self, frac):
        self.explode_frac = frac
        for name, (dx, dy, dz) in EXPLODE_VECTORS.items():
            obj = self.doc.getObject(name)
            if not obj or name not in self.base_xyz:
                continue
            bx, by, bz = self.base_xyz[name]
            has_expr = bool(getattr(obj, "ExpressionEngine", []))
            if has_expr:
                cur = obj.Placement.Base
                obj.Placement.Base = App.Vector(cur.x, by + frac * dy, cur.z)
            else:
                obj.Placement.Base = App.Vector(bx + frac * dx, by + frac * dy, bz + frac * dz)
        self.doc.recompute()
        Gui.updateGui()

    def _on_explode_slider(self, val):
        self.lbl_exp.setText(f"Fator de Explosão: {val}%")
        self._apply_explode(val / 100.0)

    def _jump_angle(self, th2_deg, ped_ang=0.0):
        if self.timer.isActive():
            self._toggle_play()
        self._set_pose(th2_deg, ped_ang)

    def _on_th2_slider(self, val):
        ped = float(self.ctrl.Angulo_Ejetor_Pedal_Graus) if self.ctrl and hasattr(self.ctrl, "Angulo_Ejetor_Pedal_Graus") else 0.0
        self._set_pose(val / 10.0, ped)

    def _on_ped_slider(self, val):
        th2 = float(self.ctrl.Angulo_Manivela_Graus) if self.ctrl else 80.0
        self._set_pose(th2, val / 10.0)

    def _set_pose(self, th2_deg, ext_ang_deg):
        th2_deg = max(20.0, min(80.0, float(th2_deg)))
        ext_ang_deg = max(0.0, min(22.0, float(ext_ang_deg)))
        if self.ctrl:
            self.ctrl.Angulo_Manivela_Graus = th2_deg
            if hasattr(self.ctrl, "Angulo_Ejetor_Pedal_Graus"):
                self.ctrl.Angulo_Ejetor_Pedal_Graus = ext_ang_deg
        self.doc.recompute()
        self._sync_from_doc()
        Gui.updateGui()

    def _sync_from_doc(self):
        if not self.ctrl:
            return
        th2 = float(self.ctrl.Angulo_Manivela_Graus)
        alav = float(self.ctrl.Angulo_Alavanca_Graus)
        mu = float(self.ctrl.Angulo_Transmissao_Mu_Graus)
        ztip = float(self.ctrl.Posicao_Navalha_Z_tip_mm)
        ped = float(self.ctrl.Angulo_Ejetor_Pedal_Graus) if hasattr(self.ctrl, "Angulo_Ejetor_Pedal_Graus") else 0.0
        ped_piso = float(self.ctrl.Angulo_Pedal_Piso_Graus) if hasattr(self.ctrl, "Angulo_Pedal_Piso_Graus") else 0.0
        cut = max(0.0, Z_BARU_TOP - ztip)

        self.slider_th2.blockSignals(True)
        self.slider_th2.setValue(int(round(th2 * 10.0)))
        self.slider_th2.blockSignals(False)

        self.slider_ped.blockSignals(True)
        self.slider_ped.setValue(int(round(ped * 10.0)))
        self.slider_ped.blockSignals(False)

        self.lbl_info.setText(
            f"θ₂: {th2:.1f}° (Alavanca: {alav:+.1f}°) | μ: {mu:.1f}° | Pedal +X: {ped_piso:.1f}° (Ejetor: {ped:.1f}°)\n"
            f"Navalha Z_tip: {ztip:.2f} mm | Corte na casca (30×50×40): {cut:.2f} mm"
        )

    def _toggle_play(self):
        if self.timer.isActive():
            self.timer.stop()
            self.btn_play.setText("▶ Play Ciclo")
            self.btn_play.setStyleSheet("font-weight: bold; background: #2e7d32; color: white; padding: 6px;")
        else:
            self.timer.start(int(1000.0 / self.fps))
            self.btn_play.setText("⏸ Pause")
            self.btn_play.setStyleSheet("font-weight: bold; background: #c62828; color: white; padding: 6px;")

    def _tick(self):
        dt = (1.0 / self.fps) * self.speed
        total_T = 4.4 if self.include_pedal else 3.0
        self.t_cycle = (self.t_cycle + dt) % total_T
        t = self.t_cycle

        ext_ang = 0.0
        if t <= 1.0:
            th2 = 80.0 - 30.0 * (1.0 - math.cos(math.pi * t / 1.0))
        elif t <= 3.0:
            th2 = 20.0 + 30.0 * (1.0 - math.cos(math.pi * (t - 1.0) / 2.0))
        else:
            th2 = 80.0
            tau = t - 3.0  # 0..1.4 s: pisada no pedal +X e retorno por mola
            ext_ang = 22.0 * math.sin(math.pi * tau / 1.4)

        self._set_pose(th2, ext_ang)

    def closeEvent(self, event):
        if self.timer.isActive():
            self.timer.stop()
        self._set_pose(50.0, 0.0)
        self.slider_exp.setValue(0)
        super().closeEvent(event)


def launch():
    global _G_PAINEL_PRENSA_MANUAL
    try:
        if "_G_PAINEL_PRENSA_MANUAL" in globals() and _G_PAINEL_PRENSA_MANUAL is not None:
            _G_PAINEL_PRENSA_MANUAL.close()
    except Exception:
        pass
    _G_PAINEL_PRENSA_MANUAL = PainelAnimacaoExplodidaBaru(Gui.getMainWindow())
    _G_PAINEL_PRENSA_MANUAL.show()
    print("Painel de Animação & Vista Explodida da Prensa Manual v7 iniciado!")
    return _G_PAINEL_PRENSA_MANUAL


if __name__ == "__main__":
    launch()
