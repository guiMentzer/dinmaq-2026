% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Análise Física Correta: Redutor 4:1 (Pinhão Entrada -> Coroa em O2) vs.
% Multiplicador 1:4 (Alavanca 45° na Coroa -> Pinhão em O2)
% Lei da Conservação de Energia + NBR ISO 11228-3 (OCRA / Borg CR-10) + NR-12
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Parâmetros do Mecanismo Base (K = 1.5, Delta_theta4 = 30°, h = 30 mm)
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

O2     = B2 + 1.5 * M;                 % [-83.97; -89.46] mm
L2     = corda_M / 2.0;                % 28.9778 mm
L3     = corda_M;                      % 57.9555 mm

y_pmi     = -2.0 * L4;                 % -223.923 mm
y_pms     = -2.0 * L4 * cos(dt);       % -193.923 mm
y_contato = y_pmi + delta_q;           % -213.923 mm

% -------------------------------------------------------------------------
% 2. Parâmetros do Estágio de Engrenagens (4:1)
% -------------------------------------------------------------------------
i_red    = 4.0;          % Relação Z_coroa / Z_pinhao = 60 / 15 = 4:1
mod_eng  = 2.0;          % Módulo (mm)
Z_pinhao = 15;
Z_coroa  = 60;
r_pinhao = (mod_eng * Z_pinhao) / 2.0; % 15.0 mm
r_coroa  = (mod_eng * Z_coroa)  / 2.0; % 60.0 mm
C_eixos  = r_pinhao + r_coroa;         % 75.0 mm

ang_eixos = deg2rad(150.0);
O_in      = O2 + C_eixos * [cos(ang_eixos); sin(ang_eixos)];

% Braço de entrada avaliado (mm)
L_braco_mm = 300.0;
L_braco_m  = L_braco_mm * 1e-3;

% Rendimentos mecânicos
mu_guia    = 0.10;
eta_juntas = 0.96;
eta_eng    = 0.96;

% -------------------------------------------------------------------------
% 3. Cinemática e Esforços no Curso de Descida (PMS = 165° -> PMI = 345°)
% -------------------------------------------------------------------------
N = 1800;
th2_deg = linspace(165.0, 345.0, N); % 180° da manivela (PMS -> PMI)
th2_rad = deg2rad(th2_deg);
dth2    = th2_rad(2) - th2_rad(1);

y_p   = zeros(1, N);
beta5 = zeros(1, N);
for k = 1:N
    t2 = th2_rad(k);
    xA = O2(1) + L2 * cos(t2);
    yA = O2(2) + L2 * sin(t2);
    d_A = hypot(xA, yA);
    a_c = (L4^2 - L3^2 + d_A^2) / (2.0 * d_A);
    h_c = sqrt(max(0.0, L4^2 - a_c^2));
    x2_c = a_c * xA / d_A;
    y2_c = a_c * yA / d_A;
    p_plus  = [x2_c + h_c * (-yA)/d_A; y2_c + h_c * (xA)/d_A];
    p_minus = [x2_c - h_c * (-yA)/d_A; y2_c - h_c * (xA)/d_A];
    if p_plus(1) <= 1e-4 && p_plus(2) < 0
        B = p_plus;
    else
        B = p_minus;
    end
    y_p(k)   = B(2) - sqrt(L5^2 - B(1)^2);
    beta5(k) = asin(abs(B(1)) / L5);
end

hp_m = abs(gradient(y_p * 1e-3, dth2));
eta_mec_barras = (1.0 - mu_guia * tan(beta5)) * eta_juntas;

idx_q = find(y_p <= y_contato);
th2_ini_q = th2_deg(idx_q(1));
s_pen = zeros(1, N);
s_pen(idx_q) = (y_contato - y_p(idx_q)) / delta_q;

F_lin = zeros(1, N); F_lin(idx_q) = F_max * s_pen(idx_q);
F_bio = zeros(1, N); F_bio(idx_q) = F_max * (s_pen(idx_q).^0.4);

% Torque na manivela O2 (N.m)
T2_lin = (F_lin .* hp_m) ./ eta_mec_barras;
T2_bio = (F_bio .* hp_m) ./ eta_mec_barras;

% --- CASO A (REDUTOR 4:1): Pinhão na Entrada (720° ou catraca) -> Coroa em O2 ---
% Reduz torque em 4x (divide por i_red * eta_eng), mas entrada gira 4 * 180° = 720°
th_red_deg = (th2_deg - 165.0) * i_red; % 0° a 720° (2 voltas por descida)
T_red_lin  = T2_lin ./ (i_red * eta_eng);
T_red_bio  = T2_bio ./ (i_red * eta_eng);
F_red_lin  = T_red_lin ./ L_braco_m;
F_red_bio  = T_red_bio ./ L_braco_m;

% --- CASO B (ALAVANCA DIRETA EM O2): Sem engrenagens (180° na entrada) ---
F_dir_lin = T2_lin ./ L_braco_m;
F_dir_bio = T2_bio ./ L_braco_m;

% --- CASO C (MULTIPLICADOR 1:4): Alavanca 45° na Coroa -> Pinhão em O2 ---
% Reduz ângulo para 45°, MAS multiplica o torque por 4x!
T_mult_lin = T2_lin .* (i_red / eta_eng);
T_mult_bio = T2_bio .* (i_red / eta_eng);
F_mult_lin = T_mult_lin ./ L_braco_m;
F_mult_bio = T_mult_bio ./ L_braco_m;

% Ganho mecânico global com Redutor 4:1 + Braço 300 mm
MA_red = (eta_mec_barras * i_red * eta_eng * L_braco_m) ./ (hp_m + 1e-6);

fprintf('=================================================================================\n');
fprintf('COMPARATIVO FÍSICO (L_braço = %.0f mm, K=1.5, dt=30°)\n', L_braco_mm);
fprintf('=================================================================================\n');
fprintf('1) Direto em O2 (sem engrenagens, curso 180°):\n');
fprintf('   T2_pico = %.2f (lin) / %.2f (bio) N.m -> F_mao = %.1f N (lin) / %.1f N (bio)\n', ...
    max(T2_lin), max(T2_bio), max(F_dir_lin), max(F_dir_bio));
fprintf('2) Multiplicador 1:4 (Alavanca 45° na Coroa -> Pinhão em O2):\n');
fprintf('   T_alav  = %.2f (lin) / %.2f (bio) N.m -> F_mao = %.1f N (lin) / %.1f N (bio) [REJEITADO]\n', ...
    max(T_mult_lin), max(T_mult_bio), max(F_mult_lin), max(F_mult_bio));
fprintf('   L_alav para F=50 N: %.2f m (lin) / %.2f m (bio)\n', max(T_mult_lin)/50, max(T_mult_bio)/50);
fprintf('3) Redutor 4:1 (Pinhão na Entrada [720° ou catraca 4x45°] -> Coroa em O2):\n');
fprintf('   T_in    = %.2f (lin) / %.2f (bio) N.m -> F_mao = %.1f N (lin) / %.1f N (bio) [APROVADO]\n', ...
    max(T_red_lin), max(T_red_bio), max(F_red_lin), max(F_red_bio));
fprintf('=================================================================================\n\n');

% =========================================================================
% FIGURA 1: Arquitetura Correta do Redutor 4:1 (Pinhão Entrada -> Coroa O2)
% =========================================================================
fig1 = figure('Visible', 'off', 'Position', [40, 40, 1420, 820], 'Color', 'w');

% --- PAINEL ESQUERDO: ESQUEMA MECÂNICO (axis equal) ---
subplot(1, 2, 1);
hold on; grid on; axis equal;

th_c = linspace(0, 2*pi, 100);
% Coroa Z2=60 em O2 (movida, eixo da manivela)
fill(O2(1) + r_coroa*cos(th_c), O2(2) + r_coroa*sin(th_c), [0.88 0.92 0.97], 'EdgeColor', 'none', 'FaceAlpha', 0.45);
plot(O2(1) + r_coroa*cos(th_c), O2(2) + r_coroa*sin(th_c), 'Color', [0.15 0.35 0.65], 'LineStyle', '-.', 'LineWidth', 1.8);
plot(O2(1) + (r_coroa+3)*cos(th_c), O2(2) + (r_coroa+3)*sin(th_c), 'Color', [0.45 0.55 0.70], 'LineWidth', 1.0);

% Pinhão Z1=15 em O_in (motor/entrada)
fill(O_in(1) + r_pinhao*cos(th_c), O_in(2) + r_pinhao*sin(th_c), [0.98 0.89 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.60);
plot(O_in(1) + r_pinhao*cos(th_c), O_in(2) + r_pinhao*sin(th_c), 'Color', [0.80 0.25 0.15], 'LineStyle', '-.', 'LineWidth', 1.8);
plot(O_in(1) + (r_pinhao+3)*cos(th_c), O_in(2) + (r_pinhao+3)*sin(th_c), 'Color', [0.85 0.45 0.35], 'LineWidth', 1.0);

% Dentes esquemáticos
for zd = 0:30:330
    a_d = deg2rad(zd);
    plot(O2(1) + [r_coroa-2.5, r_coroa+2.5]*cos(a_d), O2(2) + [r_coroa-2.5, r_coroa+2.5]*sin(a_d), 'Color', [0.25 0.40 0.65], 'LineWidth', 0.9);
end
for zd = 0:24:336
    a_d = deg2rad(zd);
    plot(O_in(1) + [r_pinhao-2.0, r_pinhao+2.0]*cos(a_d), O_in(2) + [r_pinhao-2.0, r_pinhao+2.0]*sin(a_d), 'Color', [0.75 0.25 0.15], 'LineWidth', 0.9);
end

% Opção de acionamento no Pinhão O_in:
% Círculo de varredura da manivela de entrada r = 200 mm (ou catraca 45° com 300 mm)
r_maniv_in = 220.0; % Raio da manivela contínua de entrada (mm) -> F_bio = 62.8 N / F_lin = 43.5 N
plot(O_in(1) + r_maniv_in*cos(th_c), O_in(2) + r_maniv_in*sin(th_c), 'Color', [0.10 0.60 0.25], 'LineStyle', ':', 'LineWidth', 1.6);

% Braço/Manivela no Pinhão (ilustrada a +60° e setor de catraca 45° alternativo)
th_sec = linspace(deg2rad(65), deg2rad(110), 30);
fill([O_in(1), O_in(1) + L_braco_mm*cos(th_sec), O_in(1)], ...
     [O_in(2), O_in(2) + L_braco_mm*sin(th_sec), O_in(2)], ...
     [0.90, 0.97, 0.90], 'EdgeColor', [0.2 0.65 0.2], 'LineStyle', ':', 'LineWidth', 1.2, 'FaceAlpha', 0.40);

P_in_man = O_in + r_maniv_in * [cosd(35); sind(35)];
h_man_in = plot([O_in(1), P_in_man(1)], [O_in(2), P_in_man(2)], 'Color', [0.10 0.55 0.20], 'LineWidth', 4.5);
plot(P_in_man(1), P_in_man(2), 'o', 'MarkerFaceColor', [0.15 0.15 0.15], 'MarkerEdgeColor', 'k', 'MarkerSize', 11);

% Alavanca catracada alternativa (4 x 45°, L=300 mm) tracejada
P_cat = O_in + L_braco_mm * [cosd(85); sind(85)];
h_cat = plot([O_in(1), P_cat(1)], [O_in(2), P_cat(2)], 'Color', [0.15 0.45 0.20], 'LineStyle', '--', 'LineWidth', 2.8);
plot(P_cat(1), P_cat(2), 'o', 'MarkerFaceColor', [0.6 0.8 0.6], 'MarkerEdgeColor', 'k', 'MarkerSize', 9);

% Seta de força na manivela contínua
dir_f = [sind(35); -cosd(35)];
quiver(P_in_man(1), P_in_man(2), 50*dir_f(1), 50*dir_f(2), 0, 'Color', [0.85 0.10 0.10], 'LineWidth', 2.4, 'MaxHeadSize', 0.45);
text(P_in_man(1) + 52*dir_f(1) + 5, P_in_man(2) + 52*dir_f(2), ...
    sprintf('Manivela r=220 mm\nF \\leq 62.8 N (2 voltas/golpe)\nou r=300 mm \\rightarrow F \\leq 46.1 N'), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.80 0.08 0.08], 'BackgroundColor', [1 1 1]);

text(O_in(1) + 20, O_in(2) + 255, sprintf('Ou Catraca 4x45°\n(L=300 mm, F\\leq46.1 N)'), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.1 0.45 0.15], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

% Trajetórias internas e prensa
plot(O2(1) + L2*cos(th_c), O2(2) + L2*sin(th_c), 'Color', [0.6 0.6 0.65], 'LineStyle', ':', 'LineWidth', 1.3);
ang_arc = linspace(-pi/2 - dt, -pi/2, 60);
plot(L4*cos(ang_arc), L4*sin(ang_arc), 'Color', [0.6 0.7 0.8], 'LineStyle', '--', 'LineWidth', 1.6);
plot([0, 0], [-265, 25], 'Color', [0.3 0.3 0.3], 'LineStyle', '-.', 'LineWidth', 1.1);

% Bigorna, guias lineares e baru
fill([-32, 32, 32, -32], [-248, -248, -240, -240], [0.6 0.6 0.65], 'EdgeColor', 'k', 'LineWidth', 1.2);
plot([-40, 40], [-248, -248], 'k-', 'LineWidth', 1.8);
fill([-18, -13, -13, -18], [-230, -230, -175, -175], [0.85 0.85 0.88], 'EdgeColor', [0.4 0.4 0.45]);
fill([13, 18, 18, 13], [-230, -230, -175, -175], [0.85 0.85 0.88], 'EdgeColor', [0.4 0.4 0.45]);
fill(9.5*cos(th_c), -233 + 7.0*sin(th_c), [0.55 0.28 0.10], 'EdgeColor', [0.30 0.12 0.04], 'LineWidth', 1.5);

v_O2_B2 = (B2 - O2) / norm(B2 - O2);
A_PMI = O2 + L2 * v_O2_B2;
v_O2_B1 = (B1 - O2) / norm(B1 - O2);
A_PMS = O2 - L2 * v_O2_B1;
O5_PMS = [0; y_pms];
O5_PMI = [0; y_pmi];

% PMS (tracejado)
plot([O2(1), A_PMS(1)], [O2(2), A_PMS(2)], 'Color', [0.6 0.6 0.6], 'LineStyle', '--', 'LineWidth', 1.5);
plot([A_PMS(1), B1(1)], [A_PMS(2), B1(2)], 'Color', [0.45 0.65 0.85], 'LineStyle', '--', 'LineWidth', 1.5);
plot([O4(1), B1(1)], [O4(2), B1(2)], 'Color', [0.45 0.70 0.50], 'LineStyle', '--', 'LineWidth', 1.6);
plot([B1(1), O5_PMS(1)], [B1(2), O5_PMS(2)], 'Color', [0.75 0.55 0.75], 'LineStyle', '--', 'LineWidth', 1.6);

% PMI (sólido)
h_l2 = plot([O2(1), A_PMI(1)], [O2(2), A_PMI(2)], 'Color', [0.85 0.15 0.10], 'LineWidth', 3.5);
h_l3 = plot([A_PMI(1), B2(1)], [A_PMI(2), B2(2)], 'Color', [0.00 0.45 0.85], 'LineWidth', 3.5);
h_l4 = plot([O4(1), B2(1)], [O4(2), B2(2)], 'Color', [0.10 0.65 0.25], 'LineWidth', 3.8);
h_l5 = plot([B2(1), O5_PMI(1)], [B2(2), O5_PMI(2)], 'Color', [0.70 0.15 0.75], 'LineWidth', 3.8);

fill([-11, 11, 11, 0, -11], [O5_PMI(2)+14, O5_PMI(2)+14, O5_PMI(2), O5_PMI(2)-7, O5_PMI(2)], ...
    [0.30 0.30 0.35], 'EdgeColor', 'k', 'LineWidth', 1.6);

for pt = [O4, O2, O_in]
    plot(pt(1), pt(2), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
end
text(8, 6, 'O_4 (0, 0)', 'FontSize', 8.5, 'FontWeight', 'bold');
text(120, -165, sprintf('O_2 + Coroa Z_2=%d (r_2=%.0f mm)\n[Eixo Movido: 180°]', Z_coroa, r_coroa), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.15 0.30 0.55], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);
text(O_in(1)-105, O_in(2)+8, sprintf('O_{in} + Pinhão Z_1=%d\n(r_1=%.0f mm)\n[720° ou 4x45°]', Z_pinhao, r_pinhao), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.7 0.2 0.15], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

title('Redutor 4:1 Correto: Pinhão na Entrada (O_{in}) \rightarrow Coroa na Manivela (O_2)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Coordenada X (mm)', 'FontSize', 9.5);
ylabel('Coordenada Y (mm)', 'FontSize', 9.5);
xlim([-390, 240]); ylim([-280, 280]);

legend([h_man_in, h_cat, h_l2, h_l3, h_l4, h_l5], ...
    {'Manivela Entrada (Giro 720° / 2 voltas)', 'Alternativa Catraca 4x45° (L=300 mm)', ...
     'Manivela L_2=29.0 mm (180°)', 'Biela L_3=58.0 mm', 'Balancim L_4=112.0 mm', 'Biela Prensa L_5=112.0 mm'}, ...
    'Location', 'southwest', 'FontSize', 7.4);

% --- PAINEL SUPERIOR DIREITO: REDUTOR vs DIRETO vs MULTIPLICADOR (TORQUE) ---
subplot(2, 2, 2);
hold on; grid on;

% Plotar torque na entrada ao longo do avanço (0% a 100% da descida)
pct_desc = linspace(0, 100, N);
p_mult = plot(pct_desc, T_mult_bio, 'Color', [0.85, 0.10, 0.15], 'LineStyle', '--', 'LineWidth', 2.2);
p_dir  = plot(pct_desc, T2_bio,     'Color', [0.85, 0.45, 0.00], 'LineStyle', '-.', 'LineWidth', 2.2);
p_red  = plot(pct_desc, T_red_bio,  'Color', [0.10, 0.60, 0.20], 'LineStyle', '-',  'LineWidth', 2.6);

text(26, 130, sprintf('Multiplicador 1:4 (Alav. 45° na Coroa)\nPico = %.1f N\\cdotm (4\\times maior!)\nExige L = 4.42 m p/ 50 N \\rightarrow REJEITADO', max(T_mult_bio)), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.75 0.1 0.1], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);
text(74, 30, sprintf('Redutor 4:1 (Pinhão Entrada)\nPico = %.1f N\\cdotm (4\\times menor!)', max(T_red_bio)), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.05 0.45 0.15], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

title('Efeito da Relação de Engrenagens no Torque de Entrada (Carga Biomaterial s^{0.4})', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Progresso da Descida da Navalha (%)  [0% = PMS, 100% = PMI]', 'FontSize', 9.2);
ylabel('Torque na Entrada T_{in} (N\cdotm)', 'FontSize', 9.2);
xlim([0, 100]); ylim([0, 275]);
legend([p_mult, p_dir, p_red], ...
    {'Alavanca 45° na Coroa (Multiplicador 1:4)', ...
     'Direta em O_2 (1:1, 180°)', ...
     'Redutor 4:1 (Pinhão na Entrada, 720°)'}, ...
    'Location', 'northwest', 'FontSize', 7.8);

% --- PAINEL INFERIOR DIREITO: FORÇA NA MÃO (L=300 mm) ---
subplot(2, 2, 4);
hold on; grid on;

fill([0, 720, 720, 0], [0, 0, 50, 50], [0.85, 0.96, 0.85], 'EdgeColor', 'none');
fill([0, 720, 720, 0], [50, 50, 80, 80], [0.97, 0.96, 0.82], 'EdgeColor', 'none');

h_f1 = plot(th_red_deg, F_red_lin, 'Color', [0.00, 0.45, 0.85], 'LineWidth', 2.4);
h_f2 = plot(th_red_deg, F_red_bio, 'Color', [0.85, 0.35, 0.00], 'LineStyle', '-.', 'LineWidth', 2.4);
plot([0, 720], [50, 50], 'Color', [0.1 0.55 0.15], 'LineStyle', '--', 'LineWidth', 1.2);
plot([0, 720], [80, 80], 'Color', [0.75 0.55 0.05], 'LineStyle', '--', 'LineWidth', 1.2);

% Marcar os 4 setores de 180° / bombadas de catraca
for g_x = [180, 360, 540]
    plot([g_x, g_x], [0, 95], 'k:', 'LineWidth', 1.0);
end
text(20, 53, 'Conforto Repetitivo (50 N | Borg \leq 2)', 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.1 0.5 0.1]);
text(20, 83, 'Limite Moderado (80 N | Borg \leq 3)', 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.7 0.45 0.0]);
text(615, 42, sprintf('Zona de Quebra\n(últimos ~348° de giro\nno pinhão)'), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.25], 'HorizontalAlignment', 'center');

title('Força na Mão com Redutor 4:1 (Braço r = 300 mm, Giro 0° a 720°)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Ângulo de Giro do Pinhão de Entrada \theta_{in} (graus) [2 voltas p/ descida]', 'FontSize', 9.2);
ylabel('Força na Empunhadura F_{mão} (N)', 'FontSize', 9.2);
xlim([0, 720]); ylim([0, 100]);
legend([h_f1, h_f2], ...
    {sprintf('Redutor 4:1 | Linear (Pico = %.1f N)', max(F_red_lin)), ...
     sprintf('Redutor 4:1 | Biomaterial s^{0.4} (Pico = %.1f N)', max(F_red_bio))}, ...
    'Location', 'northwest', 'FontSize', 8.0);

out1 = fullfile(assets_dir, 'mecanismo_alavanca_redutor_4_1_esquema.png');
print(fig1, out1, '-dpng', '-r300');
close(fig1);
fprintf('Figura 1 salva em: %s\n', out1);

% =========================================================================
% FIGURA 2: Dimensionamento, Conservação de Energia e Ganho Global
% =========================================================================
fig2 = figure('Visible', 'off', 'Position', [60, 60, 1380, 860], 'Color', 'w');

% --- PAINEL 1 (Superior Esquerdo): F_mao vs Comprimento do Braço ---
subplot(2, 2, 1);
hold on; grid on;

L_vec_mm = linspace(150, 500, 200);
L_vec_m  = L_vec_mm * 1e-3;

fill([150, 500, 500, 150], [15, 15, 50, 50], [0.86, 0.96, 0.86], 'EdgeColor', 'none');
fill([150, 500, 500, 150], [50, 50, 80, 80], [0.98, 0.96, 0.82], 'EdgeColor', 'none');

c1 = plot(L_vec_mm, max(T_red_lin)  ./ L_vec_m, 'Color', [0.00, 0.45, 0.85], 'LineWidth', 2.4);
c2 = plot(L_vec_mm, max(T_red_bio)  ./ L_vec_m, 'Color', [0.85, 0.35, 0.00], 'LineStyle', '-.', 'LineWidth', 2.4);
c3 = plot(L_vec_mm, max(T2_bio)     ./ L_vec_m, 'Color', [0.55, 0.15, 0.65], 'LineStyle', '--', 'LineWidth', 2.0);
c4 = plot(L_vec_mm, max(T_mult_bio) ./ L_vec_m, 'Color', [0.85, 0.10, 0.10], 'LineStyle', ':', 'LineWidth', 2.2);

plot([L_braco_mm, L_braco_mm], [15, 85], 'k--', 'LineWidth', 1.2);
plot(L_braco_mm, max(F_red_lin), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
plot(L_braco_mm, max(F_red_bio), 'rs', 'MarkerFaceColor', [0.85 0.35 0], 'MarkerSize', 8);

text(312, 23, ...
    sprintf('Redutor 4:1 (r = 300 mm):\nLinear: %.1f N | Biomaterial: %.1f N', ...
    max(F_red_lin), max(F_red_bio)), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.1 0.35 0.1], 'BackgroundColor', [1 1 1]);

set(gca, 'YScale', 'log');
title('1. Força de Pico vs. Raio/Comprimento do Braço (Escala Log)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Raio da Manivela ou Comprimento da Alavanca L (mm)', 'FontSize', 9.5);
ylabel('Força Máxima na Mão F_{mão,pico} (N)', 'FontSize', 9.5);
xlim([150, 500]); ylim([15, 2200]);
legend([c4, c3, c2, c1], ...
    {'Alav. 45° na Coroa (Mult. 1:4 | Biomaterial)', ...
     'Direta em O_2 (1:1 | Biomaterial)', ...
     'Redutor 4:1 (Pinhão | Biomaterial s^{0.4})', ...
     'Redutor 4:1 (Pinhão | Linear)'}, ...
    'Location', 'northeast', 'FontSize', 7.6);

% --- PAINEL 2 (Superior Direito): Prova pela Conservação de Energia (F x Arco) ---
subplot(2, 2, 2);
hold on; grid on;

% Para golpe único (sem volante/catraca), o trabalho W_corte ~ 28-36 J nos últimos 10 mm
% impõe F_pico * arco_total >= constante!
L_sweep = linspace(0.20, 4.50, 300);

% 1) Golpe único 45° (Mult 1:4): arco = L * pi/4
arc_45  = L_sweep * (pi / 4.0) * 100;
F_45    = max(T_mult_bio) ./ L_sweep;

% 2) Golpe único 180° (1:1 em O2): arco = L * pi
arc_180 = L_sweep * pi * 100;
F_180   = max(T2_bio) ./ L_sweep;

% 3) Redutor 4:1 (720° = 2 voltas no pinhão): arco = L * 4*pi
L_sw_r  = linspace(0.12, 0.45, 150);
arc_720 = L_sw_r * (4 * pi) * 100;
F_720   = max(T_red_bio) ./ L_sw_r;

fill([0, 450, 450, 0], [0, 0, 50, 50], [0.85, 0.96, 0.85], 'EdgeColor', 'none');
q1 = plot(arc_45,  F_45,  'Color', [0.85, 0.10, 0.15], 'LineStyle', ':',  'LineWidth', 2.3);
q2 = plot(arc_180, F_180, 'Color', [0.85, 0.45, 0.00], 'LineStyle', '--', 'LineWidth', 2.2);
q3 = plot(arc_720, F_720, 'Color', [0.10, 0.60, 0.20], 'LineStyle', '-',  'LineWidth', 2.6);

% Destaque: com 4:1, 1 volta completa são ~138-188 cm distribuídos em giro contínuo!
arc_300_720 = 0.30 * 4 * pi * 100; % 377 cm (2 voltas)
plot(arc_300_720, max(F_red_bio), 'ko', 'MarkerFaceColor', [0.1 0.7 0.2], 'MarkerSize', 9);
text(arc_300_720 - 15, max(F_red_bio) + 28, ...
    sprintf('Redutor 4:1 (r=300 mm)\n2 voltas = 377 cm totais\nF = %.1f N (APROVADO)', max(F_red_bio)), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.05 0.45 0.1], 'HorizontalAlignment', 'right', 'BackgroundColor', [1 1 1]);

text(215, 132, sprintf('Conservação de Energia (F \\cdot \\Deltas = W_{quebra}):\nTodas as configurações sem volante caem\nna mesma hipérbole! Reduzir o ângulo p/ 45°\nNÃO reduz esforço (exige L > 3 m)!'), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.35 0.1 0.1], 'BackgroundColor', [1 1 1]);

title('2. Conservação de Energia (Carga Biomaterial): Força vs. Deslocamento Total da Mão', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Deslocamento Total da Mão no Ciclo \Deltas_{mão} (cm)', 'FontSize', 9.2);
ylabel('Força de Pico na Mão F_{mão} (N)', 'FontSize', 9.2);
xlim([0, 450]); ylim([0, 240]);
legend([q1, q2, q3], ...
    {'Golpe Único 45° (Mult. 1:4 -> exige L gigante)', ...
     'Golpe Único 180° (1:1 em O_2 -> exige L=1.06 m)', ...
     'Redutor 4:1 (720° contínuo -> r=0.22-0.30 m)'}, ...
    'Location', 'northeast', 'FontSize', 7.8);

% --- PAINEL INFERIOR: TORQUE E GANHO GLOBAL NA ZONA DE QUEBRA (REDUTOR 4:1) ---
subplot(2, 2, [3, 4]);
hold on; grid on;

[ax, h_t, h_ma] = plotyy(th_red_deg(idx_q), T_red_bio(idx_q), ...
                         th_red_deg(idx_q), MA_red(idx_q));
hold(ax(1), 'on'); hold(ax(2), 'on');

set(h_t,  'Color', [0.85, 0.35, 0.00], 'LineWidth', 2.5);
plot(ax(1), th_red_deg(idx_q), T_red_lin(idx_q), 'Color', [0.00, 0.45, 0.85], 'LineWidth', 2.4, 'LineStyle', '-');
set(h_ma, 'Color', [0.10, 0.60, 0.25], 'LineWidth', 2.5, 'LineStyle', '--');

set(ax(1), 'YColor', [0.80, 0.25, 0.00], 'XLim', [th_red_deg(idx_q(1)), 720], 'YLim', [0, 18]);
set(ax(2), 'YColor', [0.10, 0.55, 0.20], 'XLim', [th_red_deg(idx_q(1)), 720], 'YLim', [50, 500]);

xlabel(ax(1), 'Ângulo do Pinhão de Entrada na Zona de Quebra \theta_{in} (graus)  [720° = PMI]', 'FontSize', 9.5);
ylabel(ax(1), 'Torque Exigido no Pinhão T_{in} (N\cdotm)', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax(2), 'Ganho Mecânico Global Real (F_{saída} / F_{mão})', 'FontSize', 9.5, 'FontWeight', 'bold');
title('3. Zona de Quebra (10 mm Finais) com Redutor 4:1 + Braço 300 mm: Torque vs. Ganho Global', ...
    'FontSize', 10.5, 'FontWeight', 'bold');

text(ax(1), 635, 11.5, sprintf('Efeito Joelho no PMI (\\theta_{in} = 720°):\nGanho Global > 400\\times (T_{in} \\rightarrow 0)'), ...
    'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.1 0.5 0.2], 'HorizontalAlignment', 'center');

legend([findobj(ax(1), 'Color', [0.00, 0.45, 0.85]); h_t; h_ma], ...
    {'Torque no Pinhão — Carga Linear (Pico = 9.57 N\cdotm)', ...
     'Torque no Pinhão — Biomaterial s^{0.4} (Pico = 13.82 N\cdotm)', ...
     'Ganho Mecânico Global Real F_{saída} / F_{mão} (Eixo Direito)'}, ...
    'Location', 'northwest', 'FontSize', 8.2);

out2 = fullfile(assets_dir, 'mecanismo_alavanca_redutor_4_1_ergonomia.png');
print(fig2, out2, '-dpng', '-r300');
close(fig2);
fprintf('Figura 2 salva em: %s\n', out2);
