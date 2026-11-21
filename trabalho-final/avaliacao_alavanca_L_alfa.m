% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Avaliação da Inserção de Alavanca em Formato de L (Força ~ 50 N, Curso <= 60°)
% no Mecanismo de Prensa K = 1.5, Delta_theta4 = 30° com Posição (alfa != 0)
%
% Análises realizadas:
%   1) Mecanismo Base K = 1.5, Delta_theta4 = 30° (PMS -> PMI)
%   2) Estágio em Série com Alavanca em L (O6-C-D-O2, alfa_in != 0, Giro = 60°)
%   3) Variação Direta de alfa != 0 em O2 (k = 1.5 estrito vs. alfa = 120°)
%   4) Prova pela Conservação de Energia + Comparativo c/ Catraca/Redutor 4:1
%
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

if isempty(available_graphics_toolkits())
    try
        register_graphics_toolkit('qt');
        graphics_toolkit('qt');
    catch
    end
end

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

opt = optimset('Display', 'off');

% -------------------------------------------------------------------------
% 1. Mecanismo Base (K = 1.5, Delta_theta4 = 30°, h = 30 mm)
% -------------------------------------------------------------------------
h_curso = 30.0;        % Curso útil total da navalha (mm)
delta_q = 10.0;        % Curso efetivo de cisalhamento do baru (mm)
F_max   = 5000.0;      % Força máxima de corte por cisalhamento (N)
dt_deg  = 30.0;
dt      = deg2rad(dt_deg);

L4 = h_curso / (2.0 * (1.0 - cos(dt))); % 111.9615 mm
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4];                       % PMI (x = 0, y = -111.96 mm)
B1 = [-L4 * sin(dt); -L4 * cos(dt)];   % PMS (x = -55.98, y = -96.96 mm)
M  = B1 - B2;
corda_M = norm(M);                     % 57.9555 mm

O2 = B2 + 1.5 * M;                     % [-83.97; -89.46] mm
L2 = corda_M / 2.0;                    % 28.9778 mm
L3 = corda_M;                          % 57.9555 mm
d_base = norm(O2);                     % 122.70 mm

y_pmi     = -2.0 * L4;                 % -223.923 mm
y_pms     = -2.0 * L4 * cos(dt);       % -193.923 mm
y_contato = y_pmi + delta_q;           % -213.923 mm

mu_guia    = 0.10;
eta_juntas = 0.96;                     % Rendimento do estágio base de barras
eta_est    = 0.96;                     % Rendimento do estágio de entrada

% Cinemática do mecanismo base no curso de descida (th2: 165° -> 345°)
Nb = 720;
th2_base_deg = linspace(165.0, 345.0, Nb);
th2_base_rad = deg2rad(th2_base_deg);
dth2_b = th2_base_rad(2) - th2_base_rad(1);

yp_base  = zeros(1, Nb);
b5_base  = zeros(1, Nb);
mu_base  = zeros(1, Nb);
x_curr = [atan2(B1(2)-O2(2), B1(1)-O2(1)); -pi/2 - dt];
for k = 1:Nb
    t2 = th2_base_rad(k);
    sis = @(x) [O2(1) + L2*cos(t2) + L3*cos(x(1)) - L4*cos(x(2)); ...
                O2(2) + L2*sin(t2) + L3*sin(x(1)) - L4*sin(x(2))];
    x_sol = fsolve(sis, x_curr, opt);
    x_curr = x_sol;
    xB = L4 * cos(x_sol(2));
    yB = L4 * sin(x_sol(2));
    yp_base(k) = yB - sqrt(max(0.0, L5^2 - xB^2));
    b5_base(k) = asin(min(1.0, abs(xB) / L5));
    da = mod(abs(x_sol(2) - x_sol(1)), 2*pi);
    if da > pi, da = 2*pi - da; end
    mu_base(k) = rad2deg(da);
end

hp_base = abs(gradient(yp_base * 1e-3, dth2_b));
eta_bar_b = (1.0 - mu_guia * tan(b5_base)) * eta_juntas;
s_pen_b = max(0.0, (y_contato - yp_base) / delta_q);
F_lin_b = F_max * s_pen_b;
F_bio_b = F_max * (s_pen_b.^0.4);
T2_lin_b = (F_lin_b .* hp_base) ./ eta_bar_b;
T2_bio_b = (F_bio_b .* hp_base) ./ eta_bar_b;

W_in_lin = trapz(th2_base_rad, T2_lin_b); % ~26.47 J
W_in_bio = trapz(th2_base_rad, T2_bio_b); % ~37.90 J

% -------------------------------------------------------------------------
% 2. ANÁLISE A: Alavanca em Formato de L em Série (O6 - C - D - O2)
%    Mapeamento 60° na Alavanca -> 180° na Manivela O2 (com alfa_est != 0)
% -------------------------------------------------------------------------
% Parâmetros sintetizados no referencial local (D1 = [rc;0], D2 = [-rc;0]):
rc_drv   = 30.0;   % Braço acoplado no eixo de O2 (mm)
ox_loc   = -50.0;  % Posição local de O6 em relação a O2 (mm)
oy_loc   = -50.0;
th_mid_d = 25.0;   % Ângulo médio do braço de saída da alavanca (graus)
t1_loc   = deg2rad(th_mid_d - 30.0);
t2_loc   = deg2rad(th_mid_d + 30.0);

u1 = [cos(t1_loc); sin(t1_loc)];
u2 = [cos(t2_loc); sin(t2_loc)];
num_r6 = norm([ox_loc; oy_loc] - [-rc_drv; 0])^2 - norm([ox_loc; oy_loc] - [rc_drv; 0])^2;
den_r6 = 2.0 * (dot([ox_loc; oy_loc] - [rc_drv; 0], u1) - dot([ox_loc; oy_loc] - [-rc_drv; 0], u2));
r6_drv = num_r6 / den_r6; % 130.95 mm
C1_loc = [ox_loc; oy_loc] + r6_drv * u1;
L_rod  = norm(C1_loc - [rc_drv; 0]); % 79.48 mm

% Rotação de montagem em torno de O2 para posicionamento ergonômico livre de colisão
% phi_rot = 210° coloca O6 acima/esquerda de O2; chaveta da manivela L2 defasada de -45°
phi_rot = deg2rad(210.0);
R_drv   = [cos(phi_rot), -sin(phi_rot); sin(phi_rot), cos(phi_rot)];
O6_glob = O2 + R_drv * [ox_loc; oy_loc];

% Ângulo de retorno rápido / assimetria alfa_estágio do driver (entre O6-D1 e O6-D2)
v_o6_d1 = [rc_drv; 0] - [ox_loc; oy_loc];
v_o6_d2 = [-rc_drv; 0] - [ox_loc; oy_loc];
alpha_drv = rad2deg(acos(max(-1, min(1, dot(v_o6_d1, v_o6_d2) / (norm(v_o6_d1)*norm(v_o6_d2))))));

% Varredura de 0° a 60° na alavanca em L
Ns = 601;
th6_loc = linspace(t1_loc, t2_loc, Ns);
dth6    = th6_loc(2) - th6_loc(1);
th6_sweep_deg = linspace(0.0, 60.0, Ns);

th_o2_loc = zeros(1, Ns);
mu_drv    = zeros(1, Ns);
C_glob    = zeros(2, Ns);
D_glob    = zeros(2, Ns);

for j = 1:Ns
    Cj_loc = [ox_loc; oy_loc] + r6_drv * [cos(th6_loc(j)); sin(th6_loc(j))];
    dC = norm(Cj_loc);
    cos_mu = (rc_drv^2 + L_rod^2 - dC^2) / (2.0 * rc_drv * L_rod);
    mu_d = rad2deg(acos(max(-1, min(1, cos_mu))));
    if mu_d > 90.0, mu_d = 180.0 - mu_d; end
    mu_drv(j) = mu_d;

    angC = atan2(Cj_loc(2), Cj_loc(1));
    cos_gam = (dC^2 + rc_drv^2 - L_rod^2) / (2.0 * dC * rc_drv);
    gam = acos(max(-1, min(1, cos_gam)));
    if j == 1
        if abs(mod(angC + gam + pi, 2*pi) - pi) < 1e-2
            sgn_b = +1;
        else
            sgn_b = -1;
        end
    end
    th_o2_loc(j) = angC + sgn_b * gam;
    Dj_loc = rc_drv * [cos(th_o2_loc(j)); sin(th_o2_loc(j))];
    C_glob(:, j) = O2 + R_drv * Cj_loc;
    D_glob(:, j) = O2 + R_drv * Dj_loc;
end

th_o2_u_deg = rad2deg(unwrap(th_o2_loc));
th2_drv_deg = 165.0 + (th_o2_u_deg - th_o2_u_deg(1)); % 165° (PMS) -> 345° (PMI)

% Cinemática acoplada completa (alavanca em L -> O2 -> B -> O5)
yp_drv  = interp1(th2_base_deg, yp_base, th2_drv_deg);
b5_drv  = interp1(th2_base_deg, b5_base, th2_drv_deg);
mu_p_drv = interp1(th2_base_deg, mu_base, th2_drv_deg);

hp_drv_th6 = abs(gradient(yp_drv * 1e-3, dth6));
eta_tot_drv = (1.0 - mu_guia * tan(b5_drv)) * eta_juntas * eta_est;
s_pen_drv = max(0.0, (y_contato - yp_drv) / delta_q);
F_lin_drv = F_max * s_pen_drv;
F_bio_drv = F_max * (s_pen_drv.^0.4);

T6_lin = (F_lin_drv .* hp_drv_th6) ./ eta_tot_drv;
T6_bio = (F_bio_drv .* hp_drv_th6) ./ eta_tot_drv;

idx_cut_drv = find(s_pen_drv > 0);
span_cut_th6 = th6_sweep_deg(idx_cut_drv(end)) - th6_sweep_deg(idx_cut_drv(1));

L_req_lin_50N = max(T6_lin) / 50.0;
L_req_bio_50N = max(T6_bio) / 50.0;

% Braço ergonômico da alavanca em L (90° horário em relação a O6->C)
% Se L_visual = 400 mm apenas para desenho técnico em escala com a prensa
L_L_draw = 350.0;
ang_C1 = atan2(C_glob(2,1) - O6_glob(2), C_glob(1,1) - O6_glob(1));
ang_C2 = atan2(C_glob(2,end) - O6_glob(2), C_glob(1,end) - O6_glob(1));
P_L_pms = O6_glob + L_L_draw * [cos(ang_C1 - pi/2); sin(ang_C1 - pi/2)];
P_L_pmi = O6_glob + L_L_draw * [cos(ang_C2 - pi/2); sin(ang_C2 - pi/2)];

% -------------------------------------------------------------------------
% 3. ANÁLISE B: Variação de alfa != 0 Diretamente em O2 (Síntese de Norton)
%    Mantendo r2 = 1.5 * corda_M (k = 1.5) para psi in [-45°, +55°]
% -------------------------------------------------------------------------
uM = M / corda_M;
nM_out = [-uM(2); uM(1)]; % Normal apontando para longe de O4

psi_vec_deg = linspace(-45.0, 55.0, 41);
n_psi = length(psi_vec_deg);
alp_arr     = zeros(1, n_psi);
dth_desc_arr = NaN(1, n_psi);
mu_min_arr  = zeros(1, n_psi);
h_util_arr  = NaN(1, n_psi);
L_50_lin_a  = NaN(1, n_psi);
L_50_bio_a  = NaN(1, n_psi);
O2_locus    = zeros(2, n_psi);

for p = 1:n_psi
    psi = deg2rad(psi_vec_deg(p));
    O2t = B2 + 1.5 * corda_M * (cos(psi)*uM + sin(psi)*nM_out);
    O2_locus(:, p) = O2t;
    r1t = norm(B1 - O2t); r2t = norm(B2 - O2t);
    L2t = (r2t - r1t) / 2.0; L3t = (r2t + r1t) / 2.0; dt_b = norm(O2t);
    alp_arr(p) = rad2deg(acos(max(-1, min(1, dot(B1-O2t, B2-O2t)/(r1t*r2t)))));

    c1 = (L3t^2 + L4^2 - (dt_b - L2t)^2) / (2.0*L3t*L4);
    c2 = (L3t^2 + L4^2 - (dt_b + L2t)^2) / (2.0*L3t*L4);
    mu1 = rad2deg(acos(max(-1, min(1, c1))));
    mu2 = rad2deg(acos(max(-1, min(1, c2))));
    mu_min_arr(p) = min([mu1, mu2, 180-mu1, 180-mu2]);

    th2_pmi_t = atan2(B2(2)-O2t(2), B2(1)-O2t(1));
    Nt = 360;
    th_f = linspace(th2_pmi_t, th2_pmi_t + 2*pi, Nt+1); th_f = th_f(1:Nt);
    dth_t = th_f(2) - th_f(1);
    ypt = zeros(1, Nt); b5t = zeros(1, Nt);
    x_c = [th2_pmi_t; -pi/2];
    ok_t = true;
    for k = 1:Nt
        t2 = th_f(k);
        sis = @(x) [O2t(1)+L2t*cos(t2)+L3t*cos(x(1))-L4*cos(x(2)); ...
                    O2t(2)+L2t*sin(t2)+L3t*sin(x(1))-L4*sin(x(2))];
        [xs, ~, info] = fsolve(sis, x_c, opt);
        if info <= 0, ok_t = false; break; end
        x_c = xs;
        xB = L4*cos(xs(2)); yB = L4*sin(xs(2));
        ypt(k) = yB - sqrt(max(0.0, L5^2 - xB^2));
        b5t(k) = asin(min(1.0, abs(xB)/L5));
    end
    if ok_t
        [ymax_t, ipms] = max(ypt);
        [ymin_t, ~]    = min(ypt);
        h_util_arr(p)  = ymax_t - ymin_t;
        dth_desc_arr(p) = 360.0 - (ipms - 1);
        idx_d = ipms:Nt;
        hpt = abs(gradient(ypt(idx_d)*1e-3, dth_t));
        etat = (1.0 - mu_guia*tan(b5t(idx_d))) * eta_juntas;
        spt = max(0.0, (ymin_t + delta_q - ypt(idx_d)) / delta_q);
        Tt_lin = (F_max * spt .* hpt) ./ etat;
        Tt_bio = (F_max * (spt.^0.4) .* hpt) ./ etat;
        L_50_lin_a(p) = max(Tt_lin) / 50.0;
        L_50_bio_a(p) = max(Tt_bio) / 50.0;
    end
end

% Caso limite k=1.5 com alavanca em L direta limitada a 60° antes do PMI (th2: 285° -> 345°)
idx_60_base = find(th2_base_deg >= 285.0);
h_60_base = max(yp_base(idx_60_base)) - min(yp_base(idx_60_base));

% -------------------------------------------------------------------------
% 4. Cota pela Conservação de Energia e Comparativo c/ Catraca + Redutor 4:1
% -------------------------------------------------------------------------
% Cota teórica absoluta para giro único de 60° (F_mao = 50 N constante):
L_min_energia_lin = W_in_lin / (50.0 * deg2rad(60.0)); % 0.506 m
L_min_energia_bio = W_in_bio / (50.0 * deg2rad(60.0)); % 0.724 m

% Redutor 4:1 com alavanca em L catracada (golpes de até 60° no pinhão):
i_red = 4.0; eta_eng = 0.96;
T_red_lin = T2_lin_b ./ (i_red * eta_eng);
T_red_bio = T2_bio_b ./ (i_red * eta_eng);
L_red_50N_lin = max(T_red_lin) / 50.0;
L_red_50N_bio = max(T_red_bio) / 50.0;
L_alav_pratica = 0.300; % 300 mm

fprintf('====================================================================================\n');
fprintf('AVALIAÇÃO: ALAVANCA EM FORMATO DE L (F ~ 50 N, GIRO <= 60°, K=1.5, Dtheta4=30°)\n');
fprintf('====================================================================================\n');
fprintf('1. Mecanismo Base K=1.5, Dtheta4=30°:\n');
fprintf('   L4=L5 = %.2f mm | L2 = %.2f mm | L3 = %.2f mm | O2 = [%.2f, %.2f] mm\n', L4, L2, L3, O2(1), O2(2));
fprintf('   Giro da manivela (PMS->PMI): 180.0° | mu_prensa = [%.1f°, %.1f°]\n', min(mu_base), max(mu_base));
fprintf('   T2_pico = %.2f N.m (linear) / %.2f N.m (bio s^0.4) | W_in = %.2f J (lin) / %.2f J (bio)\n', ...
    max(T2_lin_b), max(T2_bio_b), W_in_lin, W_in_bio);
fprintf('   Se limitada a apenas 60° antes do PMI em O2: curso cai para h = %.2f mm (INVIÁVEL)\n\n', h_60_base);

fprintf('2. Variação direta de alfa != 0 em O2 mantendo r2 = 1.5*M (K=1.5):\n');
fprintf('   alpha_max = arcsin(1/1.5) = %.2f° -> dth_descida_min = %.2f° (IMPOSSÍVEL <= 60°)\n\n', ...
    rad2deg(asin(1/1.5)), 180 - rad2deg(asin(1/1.5)));

fprintf('3. Estágio em Série com Alavanca em L (O6-C-D-O2, alfa_in = %.1f°, 60° -> 180°):\n', alpha_drv);
fprintf('   O6 = [%.2f, %.2f] mm | r6 = %.2f mm | L_biela = %.2f mm | rc = %.2f mm\n', ...
    O6_glob(1), O6_glob(2), r6_drv, L_rod, rc_drv);
fprintf('   mu_estágio = [%.1f°, %.1f°] (> 40° OK!) | Zona de corte = %.1f° dos 60°\n', ...
    min(mu_drv), max(mu_drv), span_cut_th6);
fprintf('   T6_pico = %.2f N.m (linear) / %.2f N.m (bio s^0.4)\n', max(T6_lin), max(T6_bio));
fprintf('   Comprimento p/ F = 50 N: L = %.2f m (linear) / %.2f m (bio) -> INVIÁVEL EM GOLPE ÚNICO!\n', ...
    L_req_lin_50N, L_req_bio_50N);
fprintf('   Para L = 0.50 m: F_mao_pico = %.1f N (linear) / %.1f N (bio)\n\n', ...
    max(T6_lin)/0.50, max(T6_bio)/0.50);

fprintf('4. Prova Universal pela Conservação de Energia (giro único <= 60° = 1.0472 rad):\n');
fprintf('   L_min_teorico (F=50 N constante): %.3f m (linear) / %.3f m (bio s^0.4)\n\n', ...
    L_min_energia_lin, L_min_energia_bio);

fprintf('5. Alternativa Aprovada (Alavanca em L 60°/golpe + Catraca + Redutor 4:1):\n');
fprintf('   T_pinhao_pico = %.2f N.m (lin) / %.2f N.m (bio)\n', max(T_red_lin), max(T_red_bio));
fprintf('   Com L = 300 mm: F_mao_pico = %.1f N (lin) / %.1f N (bio) | L p/ 50 N = %.0f mm\n', ...
    max(T_red_lin)/L_alav_pratica, max(T_red_bio)/L_alav_pratica, L_red_50N_bio*1000);
fprintf('====================================================================================\n');

% =========================================================================
% FIGURA 1: Esquema Cinemático da Alavanca em L (O6-C-D-O2) e Lugar de O2
% =========================================================================
fig1 = figure('Visible', 'off', 'Position', [40, 40, 1460, 840], 'Color', 'w');

% --- PAINEL ESQUERDO: ESQUEMA COMPLETO (axis equal) ---
subplot(1, 2, 1);
hold on; grid on; axis equal;

th_c = linspace(0, 2*pi, 120);
% Trajetória manivela O2 (A), pino D e balancim B
plot(O2(1) + L2*cos(th_c), O2(2) + L2*sin(th_c), 'Color', [0.7 0.7 0.75], 'LineStyle', ':', 'LineWidth', 1.3);
plot(O2(1) + rc_drv*cos(th_c), O2(2) + rc_drv*sin(th_c), 'Color', [0.55 0.65 0.75], 'LineStyle', ':', 'LineWidth', 1.1);
ang_arc_b = linspace(-pi/2 - dt, -pi/2, 60);
plot(L4*cos(ang_arc_b), L4*sin(ang_arc_b), 'Color', [0.6 0.75 0.65], 'LineStyle', '--', 'LineWidth', 1.5);

% Setor de 60° da alavanca em L (braço de saída O6-C e braço da mão O6-P)
ang_C_arc = linspace(ang_C1, ang_C2, 40);
plot(O6_glob(1) + r6_drv*cos(ang_C_arc), O6_glob(2) + r6_drv*sin(ang_C_arc), 'Color', [0.15 0.55 0.25], 'LineStyle', ':', 'LineWidth', 1.4);

ang_P_arc = linspace(ang_C1 - pi/2, ang_C2 - pi/2, 40);
fill([O6_glob(1), O6_glob(1) + L_L_draw*cos(ang_P_arc), O6_glob(1)], ...
     [O6_glob(2), O6_glob(2) + L_L_draw*sin(ang_P_arc), O6_glob(2)], ...
     [0.88 0.96 0.89], 'EdgeColor', [0.2 0.6 0.25], 'LineStyle', ':', 'LineWidth', 1.2, 'FaceAlpha', 0.45);

% Guia vertical, bigorna, buchas e baru
plot([0, 0], [-265, 25], 'Color', [0.3 0.3 0.3], 'LineStyle', '-.', 'LineWidth', 1.0);
fill([-32, 32, 32, -32], [-248, -248, -240, -240], [0.6 0.6 0.65], 'EdgeColor', 'k', 'LineWidth', 1.2);
plot([-40, 40], [-248, -248], 'k-', 'LineWidth', 1.8);
fill([-18, -13, -13, -18], [-230, -230, -175, -175], [0.85 0.85 0.88], 'EdgeColor', [0.4 0.4 0.45]);
fill([13, 18, 18, 13], [-230, -230, -175, -175], [0.85 0.85 0.88], 'EdgeColor', [0.4 0.4 0.45]);
fill(9.5*cos(th_c), -233 + 7.0*sin(th_c), [0.55 0.28 0.10], 'EdgeColor', [0.30 0.12 0.04], 'LineWidth', 1.5);

% Posições da prensa base: PMS (tracejado) e PMI (sólido)
v_O2_B2 = (B2 - O2) / norm(B2 - O2);
A_PMI   = O2 + L2 * v_O2_B2;
v_O2_B1 = (B1 - O2) / norm(B1 - O2);
A_PMS   = O2 - L2 * v_O2_B1;
O5_PMS  = [0; y_pms];
O5_PMI  = [0; y_pmi];

% Prensa no PMS (tracejado)
plot([O2(1), A_PMS(1)], [O2(2), A_PMS(2)], 'Color', [0.65 0.65 0.65], 'LineStyle', '--', 'LineWidth', 1.4);
plot([A_PMS(1), B1(1)], [A_PMS(2), B1(2)], 'Color', [0.45 0.65 0.85], 'LineStyle', '--', 'LineWidth', 1.4);
plot([O4(1), B1(1)], [O4(2), B1(2)], 'Color', [0.45 0.70 0.50], 'LineStyle', '--', 'LineWidth', 1.5);
plot([B1(1), O5_PMS(1)], [B1(2), O5_PMS(2)], 'Color', [0.75 0.55 0.75], 'LineStyle', '--', 'LineWidth', 1.5);

% Prensa no PMI (sólido)
h_l2 = plot([O2(1), A_PMI(1)], [O2(2), A_PMI(2)], 'Color', [0.85 0.15 0.10], 'LineWidth', 3.4);
h_l3 = plot([A_PMI(1), B2(1)], [A_PMI(2), B2(2)], 'Color', [0.00 0.45 0.85], 'LineWidth', 3.4);
h_l4 = plot([O4(1), B2(1)], [O4(2), B2(2)], 'Color', [0.10 0.65 0.25], 'LineWidth', 3.6);
h_l5 = plot([B2(1), O5_PMI(1)], [B2(2), O5_PMI(2)], 'Color', [0.70 0.15 0.75], 'LineWidth', 3.6);
fill([-11, 11, 11, 0, -11], [O5_PMI(2)+14, O5_PMI(2)+14, O5_PMI(2), O5_PMI(2)-7, O5_PMI(2)], ...
    [0.30 0.30 0.35], 'EdgeColor', 'k', 'LineWidth', 1.5);

% Estágio acionador + Alavanca em L no PMS (tracejado)
plot([O6_glob(1), P_L_pms(1)], [O6_glob(2), P_L_pms(2)], 'Color', [0.45 0.65 0.45], 'LineStyle', '--', 'LineWidth', 2.6);
plot([O6_glob(1), C_glob(1,1)], [O6_glob(2), C_glob(2,1)], 'Color', [0.45 0.65 0.45], 'LineStyle', '--', 'LineWidth', 2.2);
plot([C_glob(1,1), D_glob(1,1)], [C_glob(2,1), D_glob(2,1)], 'Color', [0.65 0.50 0.30], 'LineStyle', '--', 'LineWidth', 1.8);
plot([O2(1), D_glob(1,1)], [O2(2), D_glob(2,1)], 'Color', [0.60 0.45 0.45], 'LineStyle', '--', 'LineWidth', 1.8);
plot(P_L_pms(1), P_L_pms(2), 'o', 'MarkerFaceColor', [0.75 0.88 0.75], 'MarkerEdgeColor', [0.2 0.5 0.2], 'MarkerSize', 8);

% Estágio acionador + Alavanca em L no PMI (sólido destaque)
h_alav = plot([P_L_pmi(1), O6_glob(1), C_glob(1,end)], [P_L_pmi(2), O6_glob(2), C_glob(2,end)], ...
    'Color', [0.05 0.50 0.15], 'LineWidth', 4.4);
h_biela_in = plot([C_glob(1,end), D_glob(1,end)], [C_glob(2,end), D_glob(2,end)], ...
    'Color', [0.85 0.45 0.00], 'LineWidth', 3.0);
h_rc = plot([O2(1), D_glob(1,end)], [O2(2), D_glob(2,end)], 'Color', [0.45 0.25 0.15], 'LineWidth', 2.8);
plot(P_L_pmi(1), P_L_pmi(2), 'o', 'MarkerFaceColor', [0.10 0.65 0.20], 'MarkerEdgeColor', 'k', 'MarkerSize', 10);

% Seta de força tangencial na empunhadura (PMS e PMI)
u_f_pms = [sin(ang_C1 - pi/2); -cos(ang_C1 - pi/2)]; % sentido CCW (+theta6) -> [-sin; cos]
u_f_pms = [-sin(ang_C1 - pi/2); cos(ang_C1 - pi/2)];
quiver(P_L_pms(1), P_L_pms(2), 55*u_f_pms(1), 55*u_f_pms(2), 0, 'Color', [0.85 0.1 0.1], 'LineWidth', 2.4, 'MaxHeadSize', 0.45);
text(P_L_pms(1) - 18, P_L_pms(2) + 52, ...
    sprintf('F_{mão} (Giro = 60°)\n(Escala desenho L=350 mm)'), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.80 0.08 0.08], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

% Pivôs fixos
for pt = [O4, O2, O6_glob]
    plot(pt(1), pt(2), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
end
text(6, 12, 'O_4 (0, 0)', 'FontSize', 8.5, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1]);
text(O2(1)-14, O2(2)+14, 'O_2 (-84, -89)', 'FontSize', 8.0, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'BackgroundColor', [1 1 1]);
text(O6_glob(1)+12, O6_glob(2)-4, sprintf('O_6 (-66, -21)\n(\\alpha_{est} = %.1f°)', alpha_drv), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.05 0.40 0.10], 'BackgroundColor', [1 1 1]);
text(-295, 165, 'Alavanca em L (PMS)', 'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.30 0.48 0.30]);
text(-365, -25, 'Alavanca em L (PMI)', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.05 0.45 0.15]);

title('Esquema Cinemático: Prensa K=1.5 (\Delta\theta_4=30°) + Alavanca em L (60° \rightarrow 180°)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Coordenada X (mm)', 'FontSize', 9.2);
ylabel('Coordenada Y (mm)', 'FontSize', 9.2);
xlim([-460, 110]); ylim([-275, 385]);

legend([h_alav, h_biela_in, h_rc, h_l2, h_l3, h_l4, h_l5], ...
    {'Alavanca em L (Giro 60°, r_6=131 mm)', 'Biela de Entrada CD (79.5 mm)', 'Braço r_c=30 mm em O_2 (180°)', ...
     'Manivela L_2=29.0 mm', 'Biela L_3=58.0 mm', 'Balancim L_4=112.0 mm', 'Biela Prensa L_5=112.0 mm'}, ...
    'Location', 'southwest', 'FontSize', 7.3);

% --- PAINEL SUPERIOR DIREITO: LUGAR GEOMÉTRICO DE O2 PARA ALFA != 0 ---
subplot(2, 2, 2);
hold on; grid on; axis equal;

% Arco de O2 mantendo r2 = 1.5*M (psi in -45..55)
plot(O2_locus(1,:), O2_locus(2,:), 'Color', [0.85 0.35 0.00], 'LineWidth', 2.4);
% Reta colinear K (alfa = 0)
k_line = linspace(1.0, 2.5, 50);
plot(B2(1) + k_line*M(1), B2(2) + k_line*M(2), 'k--', 'LineWidth', 1.4);

% Arco capaz alfa = 120° (onde dth2 seria 60°)
alp120 = deg2rad(120.0);
R_120 = (corda_M/2) / sin(alp120);
d_120 = (corda_M/2) / tan(alp120);
C_120 = (B1+B2)/2 + d_120 * nM_out;
ang1 = atan2(B1(2)-C_120(2), B1(1)-C_120(1));
ang2 = atan2(B2(2)-C_120(2), B2(1)-C_120(1));
th_a120 = linspace(ang1, ang2, 60);
plot(C_120(1) + R_120*cos(th_a120), C_120(2) + R_120*sin(th_a120), 'r:', 'LineWidth', 2.2);

% Pontos B1, B2, O4, O2(K=1.5), O6
plot([O4(1), B2(1)], [O4(2), B2(2)], 'k-', 'LineWidth', 2.0);
plot([O4(1), B1(1)], [O4(2), B1(2)], 'k--', 'LineWidth', 1.6);
plot(B1(1), B1(2), 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 7);
plot(B2(1), B2(2), 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 7);
plot(O2(1), O2(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
plot(O6_glob(1), O6_glob(2), 'gd', 'MarkerFaceColor', [0.1 0.65 0.2], 'MarkerSize', 8);

text(O2(1)-6, O2(2)+14, 'O_2 (K=1.5, \alpha=0°)', 'FontSize', 7.6, 'FontWeight', 'bold', 'Color', 'r', 'HorizontalAlignment', 'right', 'BackgroundColor', [1 1 1]);
text(O6_glob(1)+8, O6_glob(2)+8, 'O_6 (Estágio Série)', 'FontSize', 7.6, 'FontWeight', 'bold', 'Color', [0.05 0.5 0.15], 'BackgroundColor', [1 1 1]);
text(-62, -143, sprintf('Lugar r_2=1.5 M (\\alpha_{máx}=41.8°)\nImpossível \\Delta\\theta_2 \\leq 60°!'), ...
    'FontSize', 7.4, 'FontWeight', 'bold', 'Color', [0.75 0.3 0], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);
text(-32, -124, '\alpha=120° (Defeito Ramo)', 'FontSize', 7.3, 'FontWeight', 'bold', 'Color', 'r', 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

title('Análise de Posição (\alpha \neq 0): Lugar de O_2 (k=1.5) vs. Arco \alpha=120° vs. O_6', 'FontSize', 9.8, 'FontWeight', 'bold');
xlabel('X (mm)', 'FontSize', 9.0); ylabel('Y (mm)', 'FontSize', 9.0);
xlim([-165, 35]); ylim([-160, 15]);

% --- PAINEL INFERIOR DIREITO: CINEMÁTICA DO ESTÁGIO 60° -> 180° ---
subplot(2, 2, 4);
hold on; grid on;

[ax1, h_y, h_mu] = plotyy(th6_sweep_deg, yp_drv, th6_sweep_deg, mu_drv);
hold(ax1(1), 'on'); hold(ax1(2), 'on');

set(h_y, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.4);
set(h_mu, 'Color', [0.10 0.60 0.25], 'LineWidth', 2.2, 'LineStyle', '--');
plot(ax1(1), [0, 60], [y_contato, y_contato], 'r:', 'LineWidth', 1.4);
plot(ax1(2), [0, 60], [40, 40], 'k:', 'LineWidth', 1.2);

set(ax1(1), 'YColor', [0.00 0.40 0.80], 'XLim', [0, 60], 'YLim', [-228, -190]);
set(ax1(2), 'YColor', [0.05 0.50 0.20], 'XLim', [0, 60], 'YLim', [20, 100]);

xlabel(ax1(1), 'Rotação da Alavanca em L \Delta\theta_{alav} (graus)  [Máx = 60°]', 'FontSize', 9.2);
ylabel(ax1(1), 'Posição Vertical da Navalha y_{O5} (mm)', 'FontSize', 9.2, 'FontWeight', 'bold');
ylabel(ax1(2), 'Ângulo de Transmissão \mu_{estágio} (graus)', 'FontSize', 9.2, 'FontWeight', 'bold');
title('Cinemática do Estágio O_6-C-D-O_2: Curso 30 mm e \mu \geq 41.2° em 60°', 'FontSize', 9.8, 'FontWeight', 'bold');

text(ax1(1), 2, y_contato + 2.5, 'Início Contato c/ Baru (10 mm)', 'FontSize', 7.6, 'FontWeight', 'bold', 'Color', 'r');
text(ax1(2), 41, 33, '\mu_{min} = 41.2° (> 40°)', 'FontSize', 7.6, 'FontWeight', 'bold', 'Color', [0.05 0.5 0.15]);

legend([h_y; h_mu], {'Posição da Navalha y_{O5} (30.0 mm)', '\mu do Estágio O_6-C-D-O_2 (Eixo Dir.)'}, ...
    'Location', 'southwest', 'FontSize', 7.8);

out1 = fullfile(assets_dir, 'alavanca_L_esquema_cinematico.png');
print(fig1, out1, '-dpng', '-r300');
close(fig1);
fprintf('Figura 1 salva em: %s\n', out1);

% =========================================================================
% FIGURA 2: Dimensionamento L para ~50 N, Conservação de Energia e Alfa
% =========================================================================
fig2 = figure('Visible', 'off', 'Position', [50, 50, 1440, 880], 'Color', 'w');

% --- PAINEL 1: Torque T6(th6) ao longo dos 60° da Alavanca em L ---
subplot(2, 2, 1);
hold on; grid on;

fill([th6_sweep_deg(idx_cut_drv(1)), 60, 60, th6_sweep_deg(idx_cut_drv(1))], [0, 0, 235, 235], ...
    [0.98 0.92 0.88], 'EdgeColor', 'none', 'FaceAlpha', 0.35);

p_tlin = plot(th6_sweep_deg, T6_lin, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.4);
p_tbio = plot(th6_sweep_deg, T6_bio, 'Color', [0.85 0.35 0.00], 'LineStyle', '-.', 'LineWidth', 2.4);
p_t2   = plot(th6_sweep_deg, interp1(th2_base_deg, T2_bio_b, th2_drv_deg), 'Color', [0.5 0.5 0.55], 'LineStyle', ':', 'LineWidth', 1.8);

text(40.5, 132, ...
    sprintf('Zona de Quebra (10 mm)\nocupa %.1f° dos 60°\nT_{pico} = %.1f N\\cdotm (bio)', span_cut_th6, max(T6_bio)), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.75 0.25 0.0], 'BackgroundColor', [1 1 1]);

title('1. Torque Exigido na Alavanca em L (O_6-C-D-O_2: 60° \rightarrow 180°)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Rotação da Alavanca em L \theta_{alav} (graus)', 'FontSize', 9.2);
ylabel('Torque na Entrada T_6 (N\cdotm)', 'FontSize', 9.2);
xlim([0, 60]); ylim([0, 235]);
legend([p_tbio, p_tlin, p_t2], ...
    {sprintf('Alavanca O_6 | Biomaterial s^{0.4} (Pico=%.1f N\\cdotm)', max(T6_bio)), ...
     sprintf('Alavanca O_6 | Linear (Pico=%.1f N\\cdotm)', max(T6_lin)), ...
     sprintf('Ref.: Direta em O_2 180° (Pico=%.1f N\\cdotm)', max(T2_bio_b))}, ...
    'Location', 'northwest', 'FontSize', 7.6);

% --- PAINEL 2: Força na Mão F_mao vs Comprimento L_alav (Escala Log) ---
subplot(2, 2, 2);
hold on; grid on;

L_mm = linspace(200, 4000, 300);
L_m  = L_mm * 1e-3;
fill([200, 4000, 4000, 200], [15, 15, 50, 50], [0.85 0.96 0.85], 'EdgeColor', 'none');
fill([200, 4000, 4000, 200], [50, 50, 80, 80], [0.98 0.96 0.82], 'EdgeColor', 'none');

f_s_bio = plot(L_mm, max(T6_bio) ./ L_m, 'Color', [0.85 0.35 0.00], 'LineStyle', '-.', 'LineWidth', 2.4);
f_s_lin = plot(L_mm, max(T6_lin) ./ L_m, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.4);
f_o2_bio = plot(L_mm, max(T2_bio_b) ./ L_m, 'Color', [0.55 0.15 0.65], 'LineStyle', '--', 'LineWidth', 1.9);
f_red_bio = plot(L_mm, max(T_red_bio) ./ L_m, 'Color', [0.10 0.60 0.20], 'LineWidth', 2.5);

plot([L_req_lin_50N*1000, L_req_bio_50N*1000], [50, 50], 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
plot(300, max(T_red_bio)/0.30, 'gs', 'MarkerFaceColor', [0.1 0.65 0.2], 'MarkerSize', 8);

text(2570, 72, sprintf('Série 60°\\rightarrow180° p/ 50 N:\nL = %.2f m (lin) / %.2f m (bio)', L_req_lin_50N, L_req_bio_50N), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.75 0.15 0.0], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);
text(650, 26, sprintf('Catraca 60° + Red. 4:1:\nL = 300 mm \\rightarrow F = %.1f N', max(T_red_bio)/0.30), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.05 0.45 0.15], 'BackgroundColor', [1 1 1]);

set(gca, 'YScale', 'log');
title('2. Dimensionamento do Comprimento L para F_{mão} \approx 50 N', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Comprimento do Braço da Alavanca em L (mm)', 'FontSize', 9.2);
ylabel('Força de Pico na Mão F_{mão} (N)', 'FontSize', 9.2);
xlim([200, 4000]); ylim([15, 1100]);
legend([f_s_bio, f_s_lin, f_o2_bio, f_red_bio], ...
    {'Série 60°\rightarrow180° (Biomaterial s^{0.4})', ...
     'Série 60°\rightarrow180° (Linear)', ...
     'Direta em O_2 180° (Biomaterial)', ...
     'Alav. L (60°/golpe) + Catraca + Red. 4:1'}, ...
    'Location', 'northeast', 'FontSize', 7.4);

% --- PAINEL 3: Efeito da Posição alfa != 0 em O2 (r2 = 1.5*M) ---
subplot(2, 2, 3);
hold on; grid on;

[ax3, h_ang, h_mu3] = plotyy(psi_vec_deg, dth_desc_arr, psi_vec_deg, mu_min_arr);
hold(ax3(1), 'on'); hold(ax3(2), 'on');

set(h_ang, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.4);
set(h_mu3, 'Color', [0.85 0.35 0.00], 'LineStyle', '-.', 'LineWidth', 2.2);
plot(ax3(1), [-45, 55], [60, 60], 'r--', 'LineWidth', 1.5);
plot(ax3(2), [-45, 55], [40, 40], 'k:', 'LineWidth', 1.2);

set(ax3(1), 'YColor', [0.00 0.40 0.80], 'XLim', [-45, 55], 'YLim', [40, 240]);
set(ax3(2), 'YColor', [0.80 0.30 0.00], 'XLim', [-45, 55], 'YLim', [0, 80]);

xlabel(ax3(1), 'Desvio Angular \psi de O_2 em Torno da Reta Colinear (graus)', 'FontSize', 9.2);
ylabel(ax3(1), 'Giro da Manivela na Descida \Delta\theta_2 (graus)', 'FontSize', 9.2, 'FontWeight', 'bold');
ylabel(ax3(2), 'Ângulo de Transmissão Mínimo \mu_{min} (graus)', 'FontSize', 9.2, 'FontWeight', 'bold');
title('3. Variação Direta \alpha \neq 0 em O_2 (r_2=1.5 M): Impossibilidade de \Delta\theta_2 \leq 60°', 'FontSize', 9.8, 'FontWeight', 'bold');

text(ax3(1), -42, 73, 'Meta \Delta\theta_2 \leq 60° (Inatingível c/ k=1.5! \Delta\theta_{2,min} = 142°)', ...
    'FontSize', 7.4, 'FontWeight', 'bold', 'Color', 'r', 'BackgroundColor', [1 1 1]);
text(ax3(2), 18, 25, '\mu < 40° ou perda de curso (>35°)', 'FontSize', 7.4, 'FontWeight', 'bold', 'Color', [0.7 0.2 0], 'HorizontalAlignment', 'right', 'BackgroundColor', [1 1 1]);

legend([h_ang; h_mu3], {'Giro da Manivela \Delta\theta_2 (Descida)', '\mu_{min} da Prensa (Eixo Dir.)'}, ...
    'Location', 'northeast', 'FontSize', 7.6);

% --- PAINEL 4: Prova pela Conservação de Energia (F x Deslocamento da Mão) ---
subplot(2, 2, 4);
hold on; grid on;

L_sw = linspace(0.25, 4.20, 250);
arc_60_m  = L_sw * deg2rad(60.0) * 100.0; % cm
F_60_ideal_lin = W_in_lin ./ (L_sw * deg2rad(60.0));
F_60_ideal_bio = W_in_bio ./ (L_sw * deg2rad(60.0));
F_60_serie_bio = max(T6_bio) ./ L_sw;

L_sw_r = linspace(0.15, 0.50, 100);
arc_cat_4_1 = L_sw_r * (12 * deg2rad(60.0)) * 100.0; % 12 bombeadas de 60° = 720° no pinhão
F_cat_4_1 = max(T_red_bio) ./ L_sw_r;

fill([0, 450, 450, 0], [0, 0, 50, 50], [0.85 0.96 0.85], 'EdgeColor', 'none');
e1 = plot(arc_60_m, F_60_serie_bio, 'Color', [0.85 0.15 0.10], 'LineWidth', 2.4);
e2 = plot(arc_60_m, F_60_ideal_bio, 'Color', [0.85 0.45 0.00], 'LineStyle', '--', 'LineWidth', 2.0);
e3 = plot(arc_60_m, F_60_ideal_lin, 'Color', [0.00 0.45 0.85], 'LineStyle', ':', 'LineWidth', 2.0);
e4 = plot(arc_cat_4_1, F_cat_4_1, 'Color', [0.10 0.60 0.20], 'LineWidth', 2.6);

% Pontos de destaque
plot(50 * deg2rad(60), max(T6_bio)/0.50, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
text(60, 290, sprintf('L=0.50 m, 60° único:\nF=%.0f N (Reprovado)', max(T6_bio)/0.50), ...
    'FontSize', 7.6, 'FontWeight', 'bold', 'Color', [0.75 0.1 0.1], 'BackgroundColor', [1 1 1]);

arc_300_cat = 30.0 * (12 * deg2rad(60));
plot(arc_300_cat, max(T_red_bio)/0.30, 'gs', 'MarkerFaceColor', [0.1 0.65 0.2], 'MarkerSize', 8);
text(arc_300_cat - 20, 118, ...
    sprintf('Alav. L (L=300 mm, 60°/golpe)\n+ Catraca Red. 4:1: F=%.1f N', max(T_red_bio)/0.30), ...
    'FontSize', 7.6, 'FontWeight', 'bold', 'Color', [0.05 0.45 0.15], 'HorizontalAlignment', 'right', 'BackgroundColor', [1 1 1]);

text(225, 175, sprintf('Cota Mínima Absoluta (60° único, 50 N):\nL \\geq %.2f m (linear) | L \\geq %.2f m (bio s^{0.4})', ...
    L_min_energia_lin, L_min_energia_bio), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.25 0.15 0.1], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

title('4. Conservação de Energia: Força na Mão vs. Deslocamento Total (\Deltas_{mão})', 'FontSize', 10.0, 'FontWeight', 'bold');
xlabel('Deslocamento Total da Mão por Ciclo \Deltas_{mão} (cm)', 'FontSize', 9.2);
ylabel('Força de Pico na Mão F_{mão} (N)', 'FontSize', 9.2);
xlim([0, 450]); ylim([0, 380]);
legend([e1, e2, e3, e4], ...
    {'Golpe Único 60° (Série O_6-C-D-O_2 | Bio)', ...
     'Cota Ideal 60° (W_{in}=37.9 J | Bio)', ...
     'Cota Ideal 60° (W_{in}=26.5 J | Linear)', ...
     'Catraca 60°/golpe + Red. 4:1 (Bio)'}, ...
    'Location', 'northeast', 'FontSize', 7.4);

out2 = fullfile(assets_dir, 'alavanca_L_forca_energia_50N.png');
print(fig2, out2, '-dpng', '-r300');
close(fig2);
fprintf('Figura 2 salva em: %s\n', out2);
