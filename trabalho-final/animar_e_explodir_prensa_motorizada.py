# =========================================================================
# Macro FreeCAD: Animador 3D Contínuo (20 RPM + Came Extrator) + Vista Explodida
# Prensa Motorizada de Baru de Piso 1,5 m (Vertente B — Item 9)
# Trabalho Final 1 - Dinâmica das Máquinas (UFG - Ciência Aberta)
# =========================================================================
# COMO USAR NO FREECAD:
#   Opção 1: Menu superior -> Macro -> Macros... -> selecione
#            "Animador_e_Explodido_Prensa_Motorizada.FCMacro" -> Executar.
#   Opção 2: No Console Python do FreeCAD (apenas 1 linha!):
#            exec(open("/home/guimentzer/Repos/dinmaq-2026/trabalho-final/animar_e_explodir_prensa_motorizada.py").read())
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


Z_BARU_TOP = 1043.3000
O_INT_X, O_INT_Z = 56.00, 1278.00
O_MOT_X, O_MOT_Z = 56.00, 896.00

EXPRESSION_DRIVEN_EXTRACTOR_AND_MAIN = {
    "Eixo_Principal_O2_20rpm",
    "Elo2_Manivela_L2",
    "Parafuso_Fixacao_Manivela_M6",
    "Came_Extrator_O2",
    "Contrapeso_Balanceamento_O2",
    "Parafusos_Contrapeso_M6",
    "Buchas_Catalogo_A",
    "Pino_Eixo_A",
    "Aneis_Retencao_ORing_A",
    "Elo3_Biela_L3",
    "Buchas_Catalogo_L3",
    "Elo4_Balancim_L4",
    "Buchas_Catalogo_L4",
    "Elo5_Garfo_Duplo_L5",
    "Buchas_Catalogo_L5",
    "Pino_Eixo_B",
    "Aneis_Retencao_ORing_B",
    "Pistao_Embolo_Quadrado",
    "Navalha_Corte_SAE5160",
    "Parafusos_Fixacao_Navalha_M6",
    "Bucha_Catalogo_O5",
    "Pino_Eixo_O5",
    "Aneis_Retencao_ORing_O5",
    "Alavanca_Seguidora",
    "Tirante_Extracao",
    "Alavanca_Ejetora",
}

# Vetores de explosão (dx, dy, dz) em mm a 100%.
# Regra: peças com ExpressionEngine em XZ (mecanismo principal + came extrator) recebem
# deslocamento puramente axial em Y (dy), permitindo animar os 360° + extração MESMO explodida!
EXPLODE_VECTORS = {
    # Subconjunto 08 - Cavalete 1,5 m, Carenagem NR-12, Moega, Coletor 12,3 L & Extrator
    "Sapatas_Ancoragem_Piso":           (0.0,    0.0,  -95.0),
    "Quadro_Tubular_Metalon_20x20":     (0.0,  220.0,    0.0),
    "Cantoneiras_Maos_Francesas_Uniao": (0.0,  255.0,   20.0),
    "Parafusos_Uniao_Gabinete_M8":      (0.0,  285.0,   35.0),
    "Carenagem_Chapa_Galvanizada":      (120.0, 320.0,  60.0),
    "Visor_Policarbonato_NR12":         (0.0, -300.0,  -15.0),
    "Parafusos_Fixacao_Gabinete_M6":    (0.0, -345.0,  -15.0),
    "Calha_Alimentacao_Segura_NR12":   (-150.0,  0.0,   25.0),
    "Reservatorio_Alimentacao_Chapa":  (-265.0,  0.0,   45.0),
    "Calha_Descarga_Chapa":             (0.0, -100.0,  -45.0),
    "Reservatorio_Chapa_Coleta":        (0.0, -280.0,  -65.0),
    "Suporte_Eixo_Ejetor_NR12":         (48.0,  45.0,   15.0),
    "Alavanca_Ejetora":                 (0.0,  -42.0,    0.0),
    "Tirante_Extracao":                 (0.0,   95.0,    0.0),
    "Alavanca_Seguidora":               (0.0,  125.0,    0.0),
    "Mola_Retorno":                     (65.0, 110.0,    0.0),

    # Subconjunto 07 - Trem de Potência (Redutor 20:1, Volante 400 RPM, Polias, Correia A, Motor WEG)
    "Redutor_Helicoidal_20_1":          (0.0,  155.0,    0.0),
    "Mancais_Rolamento_P204_F204":      (0.0,  210.0,   35.0),
    "Eixo_Intermediario_400rpm":        (0.0,  255.0,    0.0),
    "Volante_Inercia_Aco":              (0.0,  295.0,    0.0),
    "Polia_Movida_D325":                (0.0,  390.0,    0.0),
    "Correia_V_Perfil_A":               (0.0,  445.0,    0.0),
    "Polia_Motora_D75":                 (0.0,  390.0,  -20.0),
    "Motor_Eletrico_WEG_05cv_IEC71":    (0.0,  250.0,  -90.0),
    "Base_Tensora_Motor":               (0.0,  250.0, -135.0),

    # Subconjunto 01 - Pórticos 2"x1/4", Guia U Parafusada e Cantoneira V 90°
    "Chapa_Base_Estrutural":            (0.0,    0.0,  -45.0),
    "Portico_Estrutural_Traseiro":      (0.0,   72.0,    0.0),
    "Espacadores_Transversais_Portico": (0.0,   42.0,    0.0),
    "Buchas_Catalogo_Estator":          (0.0,   58.0,    0.0),
    "Pino_Eixo_O4":                     (0.0,  -55.0,    0.0),
    "Aneis_Retencao_ORing_O4":          (0.0,  -72.0,    0.0),
    "Portico_Estrutural_Frontal":       (0.0, -155.0,    0.0),
    "Guia_Pistao_Chapa_U":              (0.0,  -22.0,    0.0),
    "Parafusos_Guia_Pistao_M8":         (0.0,  -48.0,    0.0),
    "Tiras_Desgaste_UHMW_5mm":          (0.0,   18.0,    0.0),
    "Suporte_Baru_Cantoneira":          (0.0,    0.0,  -22.0),

    # Subconjunto 09 - Baru Simulado
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
    "Elo3_Biela_L3":                    (0.0,  -68.0,    0.0),
    "Buchas_Catalogo_L3":               (0.0,  -84.0,    0.0),

    # Subconjunto 02 - Eixo O2, Manivela L2 Parafusada, Came Aliviado & Contrapeso O2
    "Eixo_Principal_O2_20rpm":          (0.0,  -95.0,    0.0),
    "Elo2_Manivela_L2":                 (0.0, -110.0,    0.0),
    "Parafuso_Fixacao_Manivela_M6":     (0.0, -124.0,    0.0),
    "Contrapeso_Balanceamento_O2":      (0.0,   52.0,    0.0),
    "Came_Extrator_O2":                 (0.0,   72.0,    0.0),
    "Parafusos_Contrapeso_M6":          (0.0,   92.0,    0.0),
    "Buchas_Catalogo_A":                (0.0, -138.0,    0.0),
    "Pino_Eixo_A":                      (0.0, -154.0,    0.0),
    "Aneis_Retencao_ORing_A":           (0.0, -170.0,    0.0),
}


class PainelAnimacaoExplodidaMotorizada(QtWidgets.QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.doc = App.getDocument("prensa_baru_motorizada_v1") or App.ActiveDocument
        if not self.doc:
            raise RuntimeError("Abra o documento 'prensa_baru_motorizada_v1.FCStd' antes de iniciar.")
        self.ctrl = self.doc.getObject("Controlador_Cinematico")

        self.base_xyz = {}
        spin_set = {"Volante_Inercia_Aco", "Eixo_Intermediario_400rpm", "Polia_Movida_D325", "Polia_Motora_D75"}
        for name in EXPLODE_VECTORS:
            obj = self.doc.getObject(name)
            if obj:
                if name in spin_set:
                    self.base_xyz[name] = (0.0, 0.0, 0.0)
                else:
                    b = obj.Placement.Base
                    self.base_xyz[name] = (float(b.x), float(b.y), float(b.z))

        self.fps = 30
        self.speed = 1.0
        self.theta2_deg = float(self.ctrl.Angulo_Manivela_Graus) if self.ctrl else 83.0
        self.explode_frac = 0.0
        self.spin_flywheel = True

        self.timer = QtCore.QTimer(self)
        self.timer.timeout.connect(self._tick)
        self._init_ui()
        self._sync_from_doc()

    def _init_ui(self):
        self.setWindowTitle("Prensa Motorizada 20 RPM — K=1.5, Volante 400 RPM & Came")
        self.resize(470, 500)
        self.setWindowFlags(QtCore.Qt.WindowStaysOnTopHint | QtCore.Qt.Tool)

        lay = QtWidgets.QVBoxLayout(self)

        self.lbl_info = QtWidgets.QLabel()
        self.lbl_info.setAlignment(QtCore.Qt.AlignCenter)
        self.lbl_info.setStyleSheet(
            "font-weight: bold; font-size: 12px; padding: 8px; "
            "background: #0f172a; color: #f8fafc; border-radius: 6px;"
        )
        lay.addWidget(self.lbl_info)

        # ---- Seção 1: Ciclo Motorizado 360° a 20 RPM + Came Extrator ----
        grp_anim = QtWidgets.QGroupBox("1. Giro Contínuo 360° @ 20 RPM (T = 3,00 s) + Came Extrator")
        la = QtWidgets.QVBoxLayout(grp_anim)

        la.addWidget(QtWidgets.QLabel("Ângulo da Manivela θ₂ (0° → 360° contínuo; 165° PMS | 345° PMI):"))
        self.slider_th2 = QtWidgets.QSlider(QtCore.Qt.Horizontal)
        self.slider_th2.setRange(0, 3600)
        self.slider_th2.valueChanged.connect(self._on_th2_slider)
        la.addWidget(self.slider_th2)

        row_btn = QtWidgets.QHBoxLayout()
        self.btn_play = QtWidgets.QPushButton("▶ Play 20 RPM")
        self.btn_play.setStyleSheet("font-weight: bold; background: #15803d; color: white; padding: 6px;")
        self.btn_play.clicked.connect(self._toggle_play)
        row_btn.addWidget(self.btn_play)

        btn_pms = QtWidgets.QPushButton("PMS (165°)")
        btn_pms.clicked.connect(lambda: self._jump_angle(165.0))
        row_btn.addWidget(btn_pms)

        btn_desc = QtWidgets.QPushButton("Descida (255°)")
        btn_desc.clicked.connect(lambda: self._jump_angle(255.0))
        row_btn.addWidget(btn_desc)

        btn_pmi = QtWidgets.QPushButton("PMI (345°)")
        btn_pmi.clicked.connect(lambda: self._jump_angle(345.0))
        row_btn.addWidget(btn_pmi)

        btn_cam = QtWidgets.QPushButton("Pico Came (106°)")
        btn_cam.clicked.connect(lambda: self._jump_angle(106.0))
        row_btn.addWidget(btn_cam)
        la.addLayout(row_btn)

        row_spd = QtWidgets.QHBoxLayout()
        row_spd.addWidget(QtWidgets.QLabel("Velocidade:"))
        self.spin_speed = QtWidgets.QDoubleSpinBox()
        self.spin_speed.setRange(0.10, 4.0)
        self.spin_speed.setSingleStep(0.25)
        self.spin_speed.setValue(1.0)
        self.spin_speed.setSuffix("x")
        self.spin_speed.valueChanged.connect(lambda v: setattr(self, "speed", float(v)))
        row_spd.addWidget(self.spin_speed)

        self.chk_flywheel = QtWidgets.QCheckBox("Girar Volante (400 rpm) & Polias (20× / 86,5×)")
        self.chk_flywheel.setChecked(True)
        self.chk_flywheel.stateChanged.connect(self._on_flywheel_toggled)
        row_spd.addWidget(self.chk_flywheel)
        la.addLayout(row_spd)
        lay.addWidget(grp_anim)

        # ---- Seção 2: Vista Explodida ----
        grp_exp = QtWidgets.QGroupBox("2. Vista Explodida Interativa (60 Peças: 0% → 100%)")
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

        # ---- Seção 3: Visibilidade NR-12 / Câmera ----
        row_vis = QtWidgets.QHBoxLayout()
        self.chk_shroud = QtWidgets.QCheckBox("Mostrar Carenagem/Visor NR-12")
        self.chk_shroud.setChecked(True)
        self.chk_shroud.stateChanged.connect(self._toggle_shroud)
        row_vis.addWidget(self.chk_shroud)

        self.chk_cab = QtWidgets.QCheckBox("Mostrar Gabinete (Sub08)")
        self.chk_cab.setChecked(True)
        self.chk_cab.stateChanged.connect(self._toggle_sub08)
        row_vis.addWidget(self.chk_cab)

        btn_fit = QtWidgets.QPushButton("Enquadrar")
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

    def _toggle_sub08(self, state):
        o = self.doc.getObject("Subconjunto_08_Cavalete_NR12_e_Extrator_Came")
        if o and hasattr(o, "ViewObject") and o.ViewObject:
            o.ViewObject.Visibility = bool(state)
        Gui.updateGui()

    def _on_flywheel_toggled(self, state):
        self.spin_flywheel = bool(state)
        self._apply_spin_and_explode_drivetrain()
        self.doc.recompute()
        Gui.updateGui()

    def _place_spinning_part(self, name: str, cx: float, cz: float, angle_deg: float):
        obj = self.doc.getObject(name)
        if not obj or name not in self.base_xyz:
            return
        bx, by, bz = self.base_xyz[name]
        dx, dy, dz = EXPLODE_VECTORS[name]
        ex = self.explode_frac * dx
        ey = self.explode_frac * dy
        ez = self.explode_frac * dz
        if abs(angle_deg) < 1e-6:
            obj.Placement = App.Placement(App.Vector(bx + ex, by + ey, bz + ez), App.Rotation())
            return
        rot = App.Rotation(App.Vector(0.0, 1.0, 0.0), -angle_deg)
        offset = App.Vector(cx, 0.0, cz) - rot.multVec(App.Vector(cx, 0.0, cz))
        obj.Placement = App.Placement(
            App.Vector(bx + ex + offset.x, by + ey, bz + ez + offset.z),
            rot,
        )

    def _apply_spin_and_explode_drivetrain(self):
        ang_400 = (20.0 * self.theta2_deg) % 360.0 if self.spin_flywheel else 0.0
        ang_1730 = (86.5 * self.theta2_deg) % 360.0 if self.spin_flywheel else 0.0
        for name in ("Volante_Inercia_Aco", "Eixo_Intermediario_400rpm", "Polia_Movida_D325"):
            self._place_spinning_part(name, O_INT_X, O_INT_Z, ang_400)
        self._place_spinning_part("Polia_Motora_D75", O_MOT_X, O_MOT_Z, ang_1730)

    def _apply_explode(self, frac):
        self.explode_frac = frac
        spin_set = {"Volante_Inercia_Aco", "Eixo_Intermediario_400rpm", "Polia_Movida_D325", "Polia_Motora_D75"}
        for name, (dx, dy, dz) in EXPLODE_VECTORS.items():
            if name in spin_set:
                continue
            obj = self.doc.getObject(name)
            if not obj or name not in self.base_xyz:
                continue
            bx, by, bz = self.base_xyz[name]
            has_expr = bool(getattr(obj, "ExpressionEngine", []))
            if has_expr or name in EXPRESSION_DRIVEN_EXTRACTOR_AND_MAIN:
                cur = obj.Placement.Base
                obj.Placement.Base = App.Vector(cur.x, by + frac * dy, cur.z)
            else:
                obj.Placement.Base = App.Vector(bx + frac * dx, by + frac * dy, bz + frac * dz)
        self._apply_spin_and_explode_drivetrain()
        self.doc.recompute()
        Gui.updateGui()

    def _on_explode_slider(self, val):
        self.lbl_exp.setText(f"Fator de Explosão: {val}%")
        self._apply_explode(val / 100.0)

    def _jump_angle(self, th2_deg):
        if self.timer.isActive():
            self._toggle_play()
        self._set_pose(th2_deg)

    def _on_th2_slider(self, val):
        self._set_pose(val / 10.0)

    def _set_pose(self, th2_deg):
        self.theta2_deg = float(th2_deg) % 360.0
        if self.ctrl and hasattr(self.ctrl, "Angulo_Manivela_Graus"):
            self.ctrl.Angulo_Manivela_Graus = self.theta2_deg
        self._apply_spin_and_explode_drivetrain()
        self.doc.recompute()
        self._sync_from_doc()
        Gui.updateGui()

    def _phase_label(self, th2: float) -> str:
        if 60.0 <= th2 < 106.0:
            return "EXTRAÇÃO CAME (Subida 0°→22°, Navalha Alta)"
        if 106.0 <= th2 <= 150.0:
            return "RETORNO CAME (22°→0° antes do PMS)"
        if 150.0 < th2 < 165.0 or th2 < 60.0:
            return "RETORNO LIVRE / RECARGA NO PMS"
        if 165.0 <= th2 < 258.0:
            return "DESCIDA EM VAZIO (20 mm)"
        return "QUEBRA DO BARU (Últimos 10 mm → PMI)"

    def _sync_from_doc(self):
        if not self.ctrl:
            return
        th2 = float(self.ctrl.Angulo_Manivela_Graus)
        mu = float(self.ctrl.Angulo_Transmissao_Mu_Graus)
        ztip = float(self.ctrl.Posicao_Navalha_Z_tip_mm)
        psi = float(self.ctrl.Angulo_Ejetor_Graus) if hasattr(self.ctrl, "Angulo_Ejetor_Graus") else 0.0
        cut = max(0.0, Z_BARU_TOP - ztip) if (165.0 <= th2 <= 355.0) else 0.0
        fase = self._phase_label(th2)

        self.slider_th2.blockSignals(True)
        self.slider_th2.setValue(int(round(th2 * 10.0)))
        self.slider_th2.blockSignals(False)

        self.lbl_info.setText(
            f"θ₂: {th2:5.1f}° (20 RPM) | μ: {mu:5.1f}° | Ejetor Came: {psi:4.1f}°\n"
            f"Navalha Z_tip: {ztip:7.2f} mm | Penetração casca: {cut:4.2f} mm\n"
            f"Fase: {fase}"
        )

    def _toggle_play(self):
        if self.timer.isActive():
            self.timer.stop()
            self.btn_play.setText("▶ Play 20 RPM")
            self.btn_play.setStyleSheet("font-weight: bold; background: #15803d; color: white; padding: 6px;")
        else:
            self.timer.start(int(1000.0 / self.fps))
            self.btn_play.setText("⏸ Pause")
            self.btn_play.setStyleSheet("font-weight: bold; background: #c62828; color: white; padding: 6px;")

    def _tick(self):
        # 20 RPM = 120 deg/s
        dt = (1.0 / self.fps) * self.speed
        self._set_pose((self.theta2_deg + 120.0 * dt) % 360.0)

    def closeEvent(self, event):
        if self.timer.isActive():
            self.timer.stop()
        self.spin_flywheel = False
        self.slider_exp.setValue(0)
        self._set_pose(83.0)
        super().closeEvent(event)


def launch():
    global _G_PAINEL_PRENSA_MOTORIZADA
    try:
        if "_G_PAINEL_PRENSA_MOTORIZADA" in globals() and _G_PAINEL_PRENSA_MOTORIZADA is not None:
            _G_PAINEL_PRENSA_MOTORIZADA.close()
    except Exception:
        pass
    _G_PAINEL_PRENSA_MOTORIZADA = PainelAnimacaoExplodidaMotorizada(Gui.getMainWindow())
    _G_PAINEL_PRENSA_MOTORIZADA.show()
    print("Painel de Animação Contínua 20 RPM & Vista Explodida da Prensa Motorizada iniciado!")
    return _G_PAINEL_PRENSA_MOTORIZADA


if __name__ == "__main__":
    launch()
