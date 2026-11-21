% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Adaptação da Prensa de Baru ao Design de Alavanca em L (Estilo Mecanismo #140)
% Mecanismo Balancim-Balancim com Curso Completo h = 30 mm em Giro de 60°
%
% Geometria sintetizada (2 posições exatas PMS -> PMI, Dtheta_4 = 30°):
%   - O4 = [0; 0] mm, L4 = L5 = 111.9615 mm
%   - O2 posicionado à direita do pistão (alpha != 0), com alavanca em L
%     oscilando 60° no sentido horário (85° -> 25°) puxando B do PMS ao PMI
%
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Parâmetros da Prensa Base (h = 30 mm, Delta_theta4 = 30°)
% -------------------------------------------------------------------------
h_curso = 30.0;        % Curso útil total da navalha (mm)
delta_q = 10.0;        % Curso efetivo de cisalhamento do baru (mm)
F_max   = 5000.0;      % Força máxima de corte por cisalhamento (N)
dt_deg  = 30.0;
dt      = deg2rad(dt_deg);

L4 = h_curso / (2.0 * (1.0 - cos(dt))); % 111.9615 mm
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4];                       % PMI (alinhamento vertical x = 0)
B1 = [-L4 * sin(dt); -L4 * cos(dt)];   % PMS (defletido de 30° à esquerda)
M  = B1 - B2;
corda_M = norm(M);                     % 57.9555 mm

y_pmi     = -2.0 * L4;                 % -223.923 mm
y_pms     = -2.0 * L4 * cos(dt);       % -193.923 mm
y_contato = y_pmi + delta_q;           % -213.923 mm

mu_guia    = 0.10;
eta_juntas = 0.96;

% -------------------------------------------------------------------------
% 2. Síntese Analítica do Mecanismo Adaptado ao Design #140 (60° -> 30 mm)
% -------------------------------------------------------------------------
% Braço curto da alavanca em L: L2 = 70.0 mm
% Oscilação de 60° no sentido horário: th_pms = 85° -> th_pmi = 25°
L2 = 70.0;
th_pms_deg = 85.0;
th_pmi_deg = 25.0;
th_pms = deg2rad(th_pms_deg);
th_pmi = deg2rad(th_pmi_deg);

% Síntese exata de 2 posições para O2 e L3:
% ||B1 - (O2 + L2*u(th_pms))|| = ||B2 - (O2 + L2*u(th_pmi))|| = L3
P1 = B1 - L2 * [cos(th_pms); sin(th_pms)];
P2 = B2 - L2 * [cos(th_pmi); sin(th_pmi)];
midP = 0.5 * (P1 + P2);
dP   = P2 - P1;
nP   = [-dP(2); dP(1)] / norm(dP);
if nP(1) < 0, nP = -nP; end  % Garantir O2 à direita do pistão (+X)

s_offset = 135.0;            % Deslocamento na mediatriz (proporções estilo #140)
O2 = midP + s_offset * nP;   % Pivô fixo da alavanca em L (à direita)
L3 = norm(P2 - O2);          % Comprimento exato da biela horizontal AB
d_base = norm(O2 - O4);

% Braço longo da empunhadura em formato de L (defasado -55° em relação a O2->A,
% formando um L obtuso ergonômico de 125°: +30° no PMS -> -30° no PMI)
ang_L_offset = deg2rad(-55.0);
L_cabo_compacto = 0.450;     % 450 mm (alavanca compacta de bancada)

% -------------------------------------------------------------------------
% 3. Simulação Cinemática Analítica ao Longo dos 60° da Alavanca
% -------------------------------------------------------------------------
N = 601;
th2_rad = linspace(th_pms, th_pmi, N);
th2_deg = rad2deg(th2_rad);
phi_alav_deg = th_pms_deg - th2_deg; % Progresso da puxada: 0° (PMS) -> 60° (PMI)
dphi = deg2rad(phi_alav_deg(2) - phi_alav_deg(1));

Ax = O2(1) + L2 * cos(th2_rad);
Ay = O2(2) + L2 * sin(th2_rad);
dA = hypot(Ax, Ay);

a_c = (L4^2 - L3^2 + dA.^2) ./ (2.0 * dA);
h_c = sqrt(max(0.0, L4^2 - a_c.^2));

% Seleção do ramo contínuo coincidindo com B1 no PMS (k = 1)
x2_1 = a_c(1) * Ax(1) / dA(1);
y2_1 = a_c(1) * Ay(1) / dA(1);
Bp = [x2_1 + h_c(1) * (-Ay(1)) / dA(1); y2_1 + h_c(1) * (Ax(1)) / dA(1)];
Bm = [x2_1 - h_c(1) * (-Ay(1)) / dA(1); y2_1 - h_c(1) * (Ax(1)) / dA(1)];
sgn = (norm(Bp - B1) < norm(Bm - B1)) * 2 - 1;

Bx = a_c .* Ax ./ dA + sgn * h_c .* (-Ay) ./ dA;
By = a_c .* Ay ./ dA + sgn * h_c .* (Ax) ./ dA;

th3_rad = atan2(By - Ay, Bx - Ax);
th4_rad = atan2(By, Bx);

y_p   = By - sqrt(max(0.0, L5^2 - Bx.^2));
beta5 = asin(min(1.0, abs(Bx) / L5));

% Ângulo de transmissão mu entre biela 3 (AB) e balancim 4 (O4B)
da = mod(abs(th4_rad - th3_rad), 2*pi);
da(da > pi) = 2*pi - da(da > pi);
mu_deg = rad2deg(da);

% Variação de velocidade geométrica |dy_p / dphi| (m/rad) e rendimento
hp_m = abs(gradient(y_p * 1e-3, dphi));
eta_mec = (1.0 - mu_guia * tan(beta5)) * eta_juntas;

% Zona de corte (10 mm finais)
s_pen = max(0.0, (y_contato - y_p) / delta_q);
idx_q = find(s_pen > 0);
phi_ini_q = phi_alav_deg(idx_q(1));
span_q_deg = 60.0 - phi_ini_q;

F_lin = F_max * s_pen;
F_bio = F_max * (s_pen.^0.4);

% Torque exigido na alavanca em L (N.m)
T_lin = (F_lin .* hp_m) ./ eta_mec;
T_bio = (F_bio .* hp_m) ./ eta_mec;

W_lin = trapz(deg2rad(phi_alav_deg), T_lin);
W_bio = trapz(deg2rad(phi_alav_deg), T_bio);

L_50N_lin = max(T_lin) / 50.0;
L_50N_bio = max(T_bio) / 50.0;

F_mao_450_lin = T_lin ./ L_cabo_compacto;
F_mao_450_bio = T_bio ./ L_cabo_compacto;

% Ganho mecânico global (F_saída / F_mão) para L = 450 mm e para L = L_50N_lin
MA_450 = (eta_mec * L_cabo_compacto) ./ (hp_m + 1e-6);
MA_50N = (eta_mec * L_50N_lin) ./ (hp_m + 1e-6);

% Forças internas nos elos (equilíbrio quase-estático na zona de carga, carga bio s^0.4)
F_axial_5 = F_bio ./ cos(beta5);                        % Biela da prensa L5
F_guia_N  = F_bio .* tan(beta5);                        % Reação normal na guia linear
% Equilíbrio no nó B: F3*u3 - F4*u4 - F5*u5 = 0 (vetor unitário apontando para nós)
F3_biela  = zeros(1, N);
F4_balanc = zeros(1, N);
for k = 1:N
    if F_bio(k) > 0
        u3_v = [cos(th3_rad(k)); sin(th3_rad(k))];      % A -> B
        u4_v = [cos(th4_rad(k)); sin(th4_rad(k))];      % O4 -> B
        u5_v = [-Bx(k); -(y_p(k) - By(k))] / L5;        % O5 -> B (sustentando pistão)
        % Matriz [u3_v, -u4_v] * [F3; F4] = -F_axial_5(k) * [Bx(k)/L5; (By(k)-y_p(k))/L5]
        u_pist_B = [Bx(k); By(k) - y_p(k)] / L5;        % B -> O5
        Mat_B = [u3_v, u4_v];
        rhs_B = F_axial_5(k) * u_pist_B;                % Força que O5 exerce em B para cima
        sol_F = Mat_B \ rhs_B;
        F3_biela(k)  = abs(sol_F(1));
        F4_balanc(k) = abs(sol_F(2));
    end
end

% Referências comparativas (Mecanismo K=1.5 e Série O6)
L_K15 = 0.0579555 / 2.0; L3_K15 = 0.0579555;
T2_K15_bio_pico = 53.08; % N.m (para comparação direta no gráfico)
T6_serie_bio_pico = 190.04; % N.m (estágio O6 60°->180°)

fprintf('====================================================================================\n');
fprintf('PRENSA ADAPTADA AO DESIGN #140 (ALAVANCA EM L, GIRO = 60°, CURSO h = 30 mm)\n');
fprintf('====================================================================================\n');
fprintf('Geometria Sintetizada:\n');
fprintf('  O4 = [0.00, 0.00] mm | L4 = L5 = %.2f mm | Dtheta4 = 30.0°\n', L4);
fprintf('  O2 = [%.2f, %.2f] mm (entre-eixos d = %.2f mm)\n', O2(1), O2(2), d_base);
fprintf('  Braço curto L2 = %.2f mm (gira de %.0f° [PMS] a %.0f° [PMI] = 60° horário)\n', L2, th_pms_deg, th_pmi_deg);
fprintf('  Biela AB    L3 = %.2f mm | Ângulo de transmissão mu = [%.1f°, %.1f°]\n', L3, min(mu_deg), max(mu_deg));
fprintf('  Curso do pistão: y_PMS = %.2f mm -> y_PMI = %.2f mm (h = %.2f mm)\n', max(y_p), min(y_p), max(y_p)-min(y_p));
fprintf('  Zona de corte (10 mm): inicia em phi = %.1f° (ocupa %.1f° dos 60°!)\n\n', phi_ini_q, span_q_deg);
fprintf('Esforços e Dimensionamento da Alavanca:\n');
fprintf('  Torque de pico: T_lin = %.2f N.m (W = %.2f J) | T_bio = %.2f N.m (W = %.2f J)\n', ...
    max(T_lin), W_lin, max(T_bio), W_bio);
fprintf('  Comprimento p/ F_mao = 50 N: L_lin = %.2f m | L_bio = %.2f m\n', L_50N_lin, L_50N_bio);
fprintf('  Com cabo compacto L = 450 mm: F_mao = %.1f N (lin) / %.1f N (bio)\n', ...
    max(F_mao_450_lin), max(F_mao_450_bio));
fprintf('  Esforços nos elos (bio 5 kN): F3_max = %.0f N | F4_max = %.0f N | F_guia_max = %.0f N\n', ...
    max(F3_biela), max(F4_balanc), max(F_guia_N));
fprintf('====================================================================================\n');

% =========================================================================
% FIGURA 1: Esquema Técnico Adaptado ao Design #140 + Cinemática e VM
% =========================================================================
fig1 = figure('Visible', 'off', 'Position', [40, 40, 1460, 840], 'Color', 'w');

% --- PAINEL ESQUERDO: ESQUEMA MECÂNICO ESTILO #140 (axis equal) ---
subplot(1, 2, 1);
hold on; grid on; axis equal;

th_c = linspace(0, 2*pi, 100);

% Estrutura / Base esquemática estilo #140 (coluna atrás do pistão + apoio em O2)
fill([-28, 35, 35, -28], [-248, -248, -238, -238], [0.65 0.65 0.70], 'EdgeColor', 'k', 'LineWidth', 1.2);
plot([-55, 160], [-248, -248], 'k-', 'LineWidth', 1.8);
fill([-18, -13, -13, -18], [-230, -230, -172, -172], [0.85 0.85 0.88], 'EdgeColor', [0.35 0.35 0.40]);
fill([13, 18, 18, 13], [-230, -230, -172, -172], [0.85 0.85 0.88], 'EdgeColor', [0.35 0.35 0.40]);
fill(9.5*cos(th_c), -232 + 6.5*sin(th_c), [0.55 0.28 0.10], 'EdgeColor', [0.30 0.12 0.04], 'LineWidth', 1.5);
plot([0, 0], [-260, 20], 'Color', [0.3 0.3 0.3], 'LineStyle', '-.', 'LineWidth', 1.0);

% Trajetórias dos pinos A (arco 60°) e B (arco 30°)
plot(O2(1) + L2*cos(th2_rad), O2(2) + L2*sin(th2_rad), 'Color', [0.85 0.35 0.35], 'LineStyle', ':', 'LineWidth', 1.6);
ang_b = linspace(-pi/2 - dt, -pi/2, 60);
plot(L4*cos(ang_b), L4*sin(ang_b), 'Color', [0.45 0.70 0.50], 'LineStyle', '--', 'LineWidth', 1.6);

% Setor varrido pela empunhadura da alavanca em L (desenhada com L_vis = 320 mm)
L_vis = 320.0;
ang_P_pms = th_pms + ang_L_offset; % +30°
ang_P_pmi = th_pmi + ang_L_offset; % -30°
ang_P_sec = linspace(ang_P_pmi, ang_P_pms, 50);
fill([O2(1), O2(1) + L_vis*cos(ang_P_sec), O2(1)], ...
     [O2(2), O2(2) + L_vis*sin(ang_P_sec), O2(2)], ...
     [0.98 0.91 0.91], 'EdgeColor', [0.80 0.25 0.25], 'LineStyle', ':', 'LineWidth', 1.2, 'FaceAlpha', 0.45);

% Posições PMS (tracejado)
A_PMS = [Ax(1); Ay(1)]; O5_PMS = [0; y_pms];
P_PMS = O2 + L_vis * [cos(ang_P_pms); sin(ang_P_pms)];
plot([O4(1), B1(1)], [O4(2), B1(2)], 'Color', [0.45 0.75 0.50], 'LineStyle', '--', 'LineWidth', 2.0);
plot([B1(1), O5_PMS(1)], [B1(2), O5_PMS(2)], 'Color', [0.85 0.45 0.45], 'LineStyle', '--', 'LineWidth', 2.0);
plot([A_PMS(1), B1(1)], [A_PMS(2), B1(2)], 'Color', [0.40 0.55 0.85], 'LineStyle', '--', 'LineWidth', 2.0);
plot([P_PMS(1), O2(1), A_PMS(1)], [P_PMS(2), O2(2), A_PMS(2)], 'Color', [0.85 0.45 0.45], 'LineStyle', '--', 'LineWidth', 2.6);
fill([-11, 11, 11, 0, -11], [O5_PMS(2)+14, O5_PMS(2)+14, O5_PMS(2), O5_PMS(2)-7, O5_PMS(2)], ...
    [0.88 0.90 0.96], 'EdgeColor', [0.4 0.5 0.75], 'LineStyle', '--');

% Posições PMI (sólido — cores idênticas ao diagrama #140!)
A_PMI = [Ax(end); Ay(end)]; O5_PMI = [0; y_pmi];
P_PMI = O2 + L_vis * [cos(ang_P_pmi); sin(ang_P_pmi)];
h_l4 = plot([O4(1), B2(1)], [O4(2), B2(2)], 'Color', [0.10 0.60 0.25], 'LineWidth', 4.0);
h_l5 = plot([B2(1), O5_PMI(1)], [B2(2), O5_PMI(2)], 'Color', [0.78 0.15 0.15], 'LineWidth', 3.8);
h_l3 = plot([A_PMI(1), B2(1)], [A_PMI(2), B2(2)], 'Color', [0.10 0.30 0.80], 'LineWidth', 3.8);
h_l2 = plot([P_PMI(1), O2(1), A_PMI(1)], [P_PMI(2), O2(2), A_PMI(2)], 'Color', [0.82 0.12 0.12], 'LineWidth', 4.5);

% Punção azul no PMI
fill([-11, 11, 11, 0, -11], [O5_PMI(2)+14, O5_PMI(2)+14, O5_PMI(2), O5_PMI(2)-7, O5_PMI(2)], ...
    [0.15 0.30 0.75], 'EdgeColor', 'k', 'LineWidth', 1.5);

% Manopla na ponta da alavanca (PMS e PMI) e seta de força
plot(P_PMS(1), P_PMS(2), 'o', 'MarkerFaceColor', [0.95 0.75 0.75], 'MarkerEdgeColor', [0.7 0.2 0.2], 'MarkerSize', 9);
plot(P_PMI(1), P_PMI(2), 'o', 'MarkerFaceColor', [0.85 0.12 0.12], 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
u_f = [sin(ang_P_pms); -cos(ang_P_pms)]; % Puxada horária para baixo
quiver(P_PMS(1), P_PMS(2), 55*u_f(1), 55*u_f(2), 0, 'Color', [0.85 0.05 0.05], 'LineWidth', 2.4, 'MaxHeadSize', 0.45);
text(P_PMS(1) - 10, P_PMS(2) + 28, sprintf('Puxada Horária (\\Delta\\theta_{alav} = 60°)\nPMS (+30°) \\rightarrow PMI (-30°)'), ...
    'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.75 0.05 0.05], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

% Juntas
for pt = [O4, O2, B1, B2, A_PMS, A_PMI]
    plot(pt(1), pt(2), 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 6, 'LineWidth', 1.5);
end
plot(O4(1), O4(2), 'ko', 'MarkerFaceColor', [0.1 0.6 0.25], 'MarkerSize', 8);
plot(O2(1), O2(2), 'ko', 'MarkerFaceColor', [0.85 0.12 0.12], 'MarkerSize', 8);

text(10, 4, 'O_4 (0, 0)', 'FontSize', 8.5, 'FontWeight', 'bold');
text(O2(1)+10, O2(2)-20, sprintf('O_2 (%.1f, %.1f)\n[L_2=%.0f mm]', O2(1), O2(2), L2), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.7 0.1 0.1], 'BackgroundColor', [1 1 1]);
text(-62, -90, 'B_{PMS}', 'FontSize', 8.0, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
text(A_PMS(1)+6, A_PMS(2)+10, 'A_{PMS}', 'FontSize', 8.0, 'FontWeight', 'bold');
text(A_PMI(1)+6, A_PMI(2)+10, 'A_{PMI}', 'FontSize', 8.0, 'FontWeight', 'bold');

title('Design #140 Adaptado à Prensa de Baru (h = 30 mm em Giro Único de 60°)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Coordenada X (mm)', 'FontSize', 9.2);
ylabel('Coordenada Y (mm)', 'FontSize', 9.2);
xlim([-95, 440]); ylim([-375, 115]);

legend([h_l4, h_l3, h_l2, h_l5], ...
    {'Balancim L_4 = 112.0 mm (\Delta\theta_4 = 30°)', ...
     'Biela L_3 = 135.6 mm', ...
     'Alavanca em L: Braço L_2 = 70.0 mm (60°)', ...
     'Biela Prensa L_5 = 112.0 mm'}, ...
    'Location', 'southwest', 'FontSize', 7.5);

% --- PAINEL SUPERIOR DIREITO: CURSO DA NAVALHA & ÂNGULO DE TRANSMISSÃO ---
subplot(2, 2, 2);
hold on; grid on;

[ax1, h_y, h_mu] = plotyy(phi_alav_deg, y_p, phi_alav_deg, mu_deg);
hold(ax1(1), 'on'); hold(ax1(2), 'on');
set(h_y,  'Color', [0.00 0.40 0.85], 'LineWidth', 2.4);
set(h_mu, 'Color', [0.10 0.60 0.25], 'LineStyle', '--', 'LineWidth', 2.2);

plot(ax1(1), [0, 60], [y_contato, y_contato], 'r:', 'LineWidth', 1.4);
plot(ax1(2), [0, 60], [40, 40], 'k:', 'LineWidth', 1.2);

set(ax1(1), 'YColor', [0.00 0.40 0.85], 'XLim', [0, 60], 'YLim', [-228, -190]);
set(ax1(2), 'YColor', [0.05 0.50 0.20], 'XLim', [0, 60], 'YLim', [30, 105]);

xlabel(ax1(1), 'Ângulo de Acionamento da Alavanca \phi_{alav} (graus)  [0°=PMS, 60°=PMI]', 'FontSize', 9.0);
ylabel(ax1(1), 'Posição Vertical da Navalha y_{O5} (mm)', 'FontSize', 9.0, 'FontWeight', 'bold');
ylabel(ax1(2), 'Ângulo de Transmissão \mu (graus)', 'FontSize', 9.0, 'FontWeight', 'bold');
title(sprintf('Cinemática em 60°: Curso Útil de 30,0 mm e \\mu \\geq %.1f°', min(mu_deg)), 'FontSize', 10.0, 'FontWeight', 'bold');

text(ax1(1), 24, y_contato + 2.5, sprintf('Início Corte 10 mm (\\phi = %.1f°)', phi_ini_q), 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', 'r');
text(ax1(2), 36, 44, sprintf('\\mu_{min} = %.1f° (> 40°)', min(mu_deg)), 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.05 0.5 0.15]);

legend([h_y; h_mu], {'Posição da Navalha y_{O5}', 'Ângulo de Transmissão \mu (Eixo Dir.)'}, 'Location', 'southwest', 'FontSize', 7.6);

% --- PAINEL INFERIOR DIREITO: VANTAGEM MECÂNICA GLOBAL & DERIVADA ---
subplot(2, 2, 4);
hold on; grid on;

[ax2, h_ma, h_hp] = plotyy(phi_alav_deg, MA_450, phi_alav_deg, hp_m * 1e3);
hold(ax2(1), 'on'); hold(ax2(2), 'on');
set(h_ma, 'Color', [0.78 0.15 0.15], 'LineWidth', 2.4);
set(h_hp, 'Color', [0.35 0.35 0.45], 'LineStyle', '-.', 'LineWidth', 2.0);
plot(ax2(1), phi_alav_deg, MA_50N, 'Color', [0.05 0.55 0.20], 'LineStyle', '--', 'LineWidth', 2.2);

set(ax2(1), 'YColor', [0.75 0.12 0.12], 'XLim', [0, 60], 'YLim', [0, 260]);
set(ax2(2), 'YColor', [0.30 0.30 0.40], 'XLim', [0, 60], 'YLim', [0, 50]);

xlabel(ax2(1), 'Ângulo de Acionamento da Alavanca \phi_{alav} (graus)', 'FontSize', 9.0);
ylabel(ax2(1), 'Ganho Mecânico Global (F_{saída} / F_{mão})', 'FontSize', 9.0, 'FontWeight', 'bold');
ylabel(ax2(2), 'Velocidade Geométrica |dy/d\phi| (mm/rad)', 'FontSize', 9.0, 'FontWeight', 'bold');
title('Efeito Joelho: Ganho Mecânico Global e Desaceleração no PMI', 'FontSize', 10.0, 'FontWeight', 'bold');

text(ax2(1), 46, 155, sprintf('No PMI (\\phi \\rightarrow 60°):\n|dy/d\\phi| \\rightarrow 0\nVM \\rightarrow \\infty'), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.75 0.1 0.1], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

legend([h_ma; findobj(ax2(1), 'Color', [0.05 0.55 0.20]); h_hp], ...
    {'VM Global (L = 450 mm)', 'VM Global (L = 1.29 m p/ 50 N)', '|dy/d\phi| em mm/rad (Eixo Dir.)'}, ...
    'Location', 'northwest', 'FontSize', 7.4);

out1 = fullfile(assets_dir, 'prensa_design140_esquema_cinematico.png');
print(fig1, out1, '-dpng', '-r300');
close(fig1);
fprintf('Figura 1 salva em: %s\n', out1);

% =========================================================================
% FIGURA 2: Torque, Força na Mão, Dimensionamento de L e Esforços nos Elos
% =========================================================================
fig2 = figure('Visible', 'off', 'Position', [50, 50, 1440, 880], 'Color', 'w');

% --- PAINEL 1: Torque na Alavanca vs. Estágio em Série O6 ---
subplot(2, 2, 1);
hold on; grid on;

fill([phi_ini_q, 60, 60, phi_ini_q], [0, 0, 130, 130], [0.98 0.92 0.88], 'EdgeColor', 'none', 'FaceAlpha', 0.35);
p1 = plot(phi_alav_deg, T_bio, 'Color', [0.85 0.35 0.00], 'LineStyle', '-.', 'LineWidth', 2.5);
p2 = plot(phi_alav_deg, T_lin, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.5);

text(37.5, 82, sprintf('Zona de Quebra (10 mm):\n%.1f° dos 60° da alavanca\n(Redução de ~48%% no torque\nfrente ao estágio série O_6!)', span_q_deg), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.1 0.45 0.15], 'BackgroundColor', [1 1 1]);

title('1. Torque na Alavanca em L (Design #140: 60° Direto)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Ângulo de Acionamento \phi_{alav} (graus)', 'FontSize', 9.2);
ylabel('Torque na Alavanca T_{alav} (N\cdotm)', 'FontSize', 9.2);
xlim([0, 60]); ylim([0, 125]);
legend([p1, p2], ...
    {sprintf('Biomaterial s^{0.4} (Pico = %.1f N\\cdotm)', max(T_bio)), ...
     sprintf('Carga Linear (Pico = %.1f N\\cdotm)', max(T_lin))}, ...
    'Location', 'northwest', 'FontSize', 7.8);

% --- PAINEL 2: Força na Mão ao longo dos 60° (L = 450 mm vs L para 50 N) ---
subplot(2, 2, 2);
hold on; grid on;

fill([0, 60, 60, 0], [0, 0, 50, 50], [0.85 0.96 0.85], 'EdgeColor', 'none');
fill([0, 60, 60, 0], [50, 50, 80, 80], [0.98 0.96 0.82], 'EdgeColor', 'none');

f1 = plot(phi_alav_deg, F_mao_450_bio, 'Color', [0.85 0.15 0.10], 'LineStyle', '-.', 'LineWidth', 2.3);
f2 = plot(phi_alav_deg, F_mao_450_lin, 'Color', [0.85 0.45 0.00], 'LineWidth', 2.3);
f3 = plot(phi_alav_deg, T_bio ./ L_50N_bio, 'Color', [0.10 0.60 0.20], 'LineStyle', '--', 'LineWidth', 2.3);
f4 = plot(phi_alav_deg, T_lin ./ L_50N_lin, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.3);

plot([0, 60], [50, 50], 'Color', [0.1 0.55 0.15], 'LineStyle', ':', 'LineWidth', 1.4);
text(2, 55, 'Meta: 50 N (Borg \leq 2)', 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.05 0.45 0.1]);

title('2. Força na Mão ao Longo dos 60° (L = 450 mm vs. Meta 50 N)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Ângulo de Acionamento \phi_{alav} (graus)', 'FontSize', 9.2);
ylabel('Força na Empunhadura F_{mão} (N)', 'FontSize', 9.2);
xlim([0, 60]); ylim([0, 245]);
legend([f1, f2, f3, f4], ...
    {sprintf('L=450 mm | Bio (Pico=%.0f N)', max(F_mao_450_bio)), ...
     sprintf('L=450 mm | Linear (Pico=%.0f N)', max(F_mao_450_lin)), ...
     sprintf('L=%.2f m | Bio (Pico=50 N)', L_50N_bio), ...
     sprintf('L=%.2f m | Linear (Pico=50 N)', L_50N_lin)}, ...
    'Location', 'northwest', 'FontSize', 7.5);

% --- PAINEL 3: Dimensionamento Paramétrico L vs F_pico (Escala Log) ---
subplot(2, 2, 3);
hold on; grid on;

L_mm = linspace(250, 4000, 300);
L_m  = L_mm * 1e-3;
fill([250, 4000, 4000, 250], [15, 15, 50, 50], [0.85 0.96 0.85], 'EdgeColor', 'none');
fill([250, 4000, 4000, 250], [50, 50, 80, 80], [0.98 0.96 0.82], 'EdgeColor', 'none');

c_ser = plot(L_mm, T6_serie_bio_pico ./ L_m, 'Color', [0.65 0.25 0.70], 'LineStyle', ':', 'LineWidth', 2.1);
c_bio = plot(L_mm, max(T_bio) ./ L_m, 'Color', [0.85 0.35 0.00], 'LineStyle', '-.', 'LineWidth', 2.4);
c_lin = plot(L_mm, max(T_lin) ./ L_m, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.4);
c_k15 = plot(L_mm, T2_K15_bio_pico ./ L_m, 'Color', [0.10 0.60 0.20], 'LineStyle', '--', 'LineWidth', 2.0);

plot([L_50N_lin*1000, L_50N_bio*1000], [50, 50], 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
plot(450, max(F_mao_450_lin), 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 7);
plot(450, max(F_mao_450_bio), 'rs', 'MarkerFaceColor', [0.85 0.35 0], 'MarkerSize', 7);

text(1980, 74, sprintf('Design #140 p/ 50 N:\nL=%.2f m (lin) / %.2f m (bio)', L_50N_lin, L_50N_bio), ...
    'FontSize', 7.6, 'FontWeight', 'bold', 'Color', [0.75 0.15 0.0], 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);
text(520, 290, sprintf('L=450 mm:\n%.0f N (lin) / %.0f N (bio)', max(F_mao_450_lin), max(F_mao_450_bio)), ...
    'FontSize', 7.5, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.5], 'BackgroundColor', [1 1 1]);

set(gca, 'YScale', 'log');
title('3. Curva de Dimensionamento: Comprimento L vs. Força de Pico', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Comprimento da Alavanca em L (mm)', 'FontSize', 9.2);
ylabel('Força de Pico na Mão F_{mão} (N)', 'FontSize', 9.2);
xlim([250, 4000]); ylim([15, 900]);
legend([c_ser, c_bio, c_lin, c_k15], ...
    {'Série O_6 (60°\rightarrow180° | Bio)', ...
     'Design #140 (60° Direto | Bio)', ...
     'Design #140 (60° Direto | Linear)', ...
     'Ref.: K=1.5 Direto (180° | Bio)'}, ...
    'Location', 'northeast', 'FontSize', 7.4);

% --- PAINEL 4: Esforços Estruturais nos Elos (Carga Biomaterial 5 kN) ---
subplot(2, 2, 4);
hold on; grid on;

s1 = plot(phi_alav_deg, F_axial_5, 'Color', [0.75 0.15 0.15], 'LineWidth', 2.3);
s2 = plot(phi_alav_deg, F4_balanc, 'Color', [0.10 0.60 0.25], 'LineStyle', '--', 'LineWidth', 2.2);
s3 = plot(phi_alav_deg, F3_biela,  'Color', [0.00 0.45 0.85], 'LineStyle', '-.', 'LineWidth', 2.2);
s4 = plot(phi_alav_deg, F_guia_N,  'Color', [0.45 0.30 0.65], 'LineWidth', 2.0);

text(34, 2650, sprintf('Efeito Joelho no PMI:\nBiela AB (F_3) e Guia (F_{guia})\nreduzem a zero no alinhamento!'), ...
    'FontSize', 7.6, 'FontWeight', 'bold', 'Color', [0.1 0.35 0.65], 'BackgroundColor', [1 1 1]);

title('4. Esforços Estruturais nos Elos ao Longo dos 60° (Carga s^{0.4})', 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Ângulo de Acionamento \phi_{alav} (graus)', 'FontSize', 9.2);
ylabel('Força nos Elos e Guia (N)', 'FontSize', 9.2);
xlim([0, 60]); ylim([0, 5600]);
legend([s1, s2, s3, s4], ...
    {sprintf('Biela Prensa L_5 (Máx = %.0f N)', max(F_axial_5)), ...
     sprintf('Balancim L_4 (Máx = %.0f N)', max(F4_balanc)), ...
     sprintf('Biela Horizontal L_3 (Máx = %.0f N)', max(F3_biela)), ...
     sprintf('Normal na Guia Linear (Máx = %.0f N)', max(F_guia_N))}, ...
    'Location', 'northwest', 'FontSize', 7.4);

out2 = fullfile(assets_dir, 'prensa_design140_forcas_ergonomia.png');
print(fig2, out2, '-dpng', '-r300');
close(fig2);
fprintf('Figura 2 salva em: %s\n', out2);
