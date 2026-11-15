% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Mecanismo Ultra-Compacto (K = 1.5, Delta_theta4 = 30°)
% Geração da Figura Técnica Refinada e Corrigida (300 DPI)
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Parâmetros Físicos e Geométricos
% -------------------------------------------------------------------------
h = 30.0; % Curso útil (mm)
dt_deg = 30.0;
dt = deg2rad(dt_deg);

L4 = h / (2.0 * (1.0 - cos(dt))); % 111.9615 mm
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4];                     % PMI (alinhado com o pistão vertical)
B1 = [-L4 * sin(dt); -L4 * cos(dt)]; % PMS (defletido de 30°)
M = B1 - B2;
corda_M = norm(M);                   % 57.9555 mm

% Pivô O2 ultra-compacto K = 1.5
O2 = B2 + 1.5 * M;                   % [-83.97; -89.46] mm
L2 = corda_M / 2.0;                  % 28.98 mm
L3 = corda_M;                        % 57.96 mm
d_base = norm(O2);                   % 122.70 mm

% Posições EXATAS das juntas nos extremos pela cinemática colinear:
% No PMI (B2): Manivela estendida apontando de O2 para B2
v_O2_B2 = (B2 - O2) / norm(B2 - O2);
A_PMI = O2 + L2 * v_O2_B2;           % A fica entre O2 e B2 (colinear)
O5_PMI = [0.0; -2 * L4];             % y = -223.92 mm

% No PMS (B1): Manivela dobrada para trás na linha de B1
% B1 - O2 tem comprimento r1 = L3 - L2 = 28.98 mm
% A manivela aponta no sentido oposto de B1 em relação a O2
v_O2_B1 = (B1 - O2) / norm(B1 - O2);
A_PMS = O2 - L2 * v_O2_B1;
O5_PMS = [0.0; -2 * L4 * cos(dt)];   % y = -193.92 mm

% -------------------------------------------------------------------------
% 2. Construção da Figura com Estética Refinada
% -------------------------------------------------------------------------
fig = figure('Name', 'Mecanismo Ultra-Compacto K=1.5 Refinado', 'NumberTitle', 'off', 'Position', [50, 50, 1200, 780]);

% === PAINEL ESQUERDO: ESQUEMA TÉCNICO CINEMÁTICO ===
subplot(1, 2, 1);
hold on; grid on; axis equal;

% Trajetória circular da manivela (pino A)
ang_circ = linspace(0, 2*pi, 150);
circ_Ax = O2(1) + L2 * cos(ang_circ);
circ_Ay = O2(2) + L2 * sin(ang_circ);
plot(circ_Ax, circ_Ay, 'Color', [0.70 0.70 0.75], 'LineStyle', ':', 'LineWidth', 1.5);

% Trajetória em arco do balancim (pino B)
ang_arc = linspace(-pi/2 - dt, -pi/2, 80);
arc_Bx = L4 * cos(ang_arc);
arc_By = L4 * sin(ang_arc);
plot(arc_Bx, arc_By, 'Color', [0.65 0.75 0.85], 'LineStyle', '--', 'LineWidth', 2.0);

% Linha de centro da guia vertical do pistão (X = 0)
plot([0, 0], [-270, 25], 'Color', [0.2 0.2 0.2], 'LineStyle', '-.', 'LineWidth', 1.2);

% Bigorna e Base de Apoio
fill([-32, 32, 32, -32], [-248, -248, -240, -240], [0.6 0.6 0.65], 'EdgeColor', 'k', 'LineWidth', 1.3);
plot([-40, 40], [-248, -248], 'k-', 'LineWidth', 2.0);
for hx = -36:8:32
    plot([hx, hx + 7], [-248, -256], 'Color', [0.3 0.3 0.3], 'LineWidth', 1.2);
end
text(-38, -263, 'Base Rígida / Bigorna', 'FontSize', 8.5, 'Color', [0.3 0.3 0.3]);

% Guias prismáticas verticais (paredes laterais com buchas)
fill([-18, -13, -13, -18], [-230, -230, -175, -175], [0.85 0.85 0.88], 'EdgeColor', [0.35 0.35 0.40], 'LineWidth', 1.2);
fill([13, 18, 18, 13], [-230, -230, -175, -175], [0.85 0.85 0.88], 'EdgeColor', [0.35 0.35 0.40], 'LineWidth', 1.2);
text(21, -182, 'Guia Linear', 'FontSize', 8, 'Color', [0.4 0.4 0.4]);

% Fruto do Baru sobre a bigorna (elipse com casca)
baru_t = linspace(0, 2*pi, 60);
baru_x = 9.5 * cos(baru_t);
baru_y = -233 + 7.0 * sin(baru_t);
fill(baru_x, baru_y, [0.55 0.28 0.10], 'EdgeColor', [0.30 0.12 0.04], 'LineWidth', 1.6);
text(14, -236, 'Baru (Carga: 5 kN)', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.50 0.20 0.05]);

% ------------------- POSIÇÃO PMS (Abertura Máxima para Recarga) -------------------
% Manivela PMS
plot([O2(1), A_PMS(1)], [O2(2), A_PMS(2)], 'Color', [0.6 0.6 0.6], 'LineStyle', '--', 'LineWidth', 1.8);
% Biela 3 PMS
plot([A_PMS(1), B1(1)], [A_PMS(2), B1(2)], 'Color', [0.4 0.6 0.8], 'LineStyle', '--', 'LineWidth', 1.8);
% Balancim 4 PMS
plot([O4(1), B1(1)], [O4(2), B1(2)], 'Color', [0.4 0.7 0.5], 'LineStyle', '--', 'LineWidth', 2.0);
% Biela Prensa 5 PMS
plot([B1(1), O5_PMS(1)], [B1(2), O5_PMS(2)], 'Color', [0.75 0.5 0.75], 'LineStyle', '--', 'LineWidth', 2.0);

% Navalha / Pistão no PMS (transparente tracejado)
fill([-11, 11, 11, 0, -11], ...
     [O5_PMS(2)+14, O5_PMS(2)+14, O5_PMS(2), O5_PMS(2)-7, O5_PMS(2)], ...
     [0.93 0.93 0.95], 'EdgeColor', [0.55 0.55 0.60], 'LineStyle', '--');
plot(O5_PMS(1), O5_PMS(2), 'o', 'MarkerFaceColor', [0.8 0.8 0.85], 'MarkerEdgeColor', [0.4 0.4 0.4], 'MarkerSize', 6);
text(14, O5_PMS(2) + 4, 'PMS: y = -193.9 mm', 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.35 0.45 0.55]);

% Juntas no PMS
plot(A_PMS(1), A_PMS(2), 'o', 'MarkerFaceColor', [0.85 0.85 0.85], 'MarkerEdgeColor', [0.4 0.4 0.4], 'MarkerSize', 5);
text(A_PMS(1) - 16, A_PMS(2) - 8, 'A_{PMS}', 'FontSize', 7.5, 'Color', [0.4 0.4 0.4]);

plot(B1(1), B1(2), 's', 'MarkerFaceColor', [0.85 0.85 0.85], 'MarkerEdgeColor', [0.4 0.4 0.4], 'MarkerSize', 6);
text(B1(1) - 24, B1(2) + 5, 'B_{PMS}', 'FontSize', 8, 'Color', [0.3 0.3 0.3]);

% ------------------- POSIÇÃO PMI (Cisalhamento no Efeito Joelho) -------------------
% Manivela 2 (Vermelho Técnico)
h_l2 = plot([O2(1), A_PMI(1)], [O2(2), A_PMI(2)], 'Color', [0.85 0.15 0.10], 'LineWidth', 3.8);
% Biela 3 (Azul Real)
h_l3 = plot([A_PMI(1), B2(1)], [A_PMI(2), B2(2)], 'Color', [0.00 0.45 0.85], 'LineWidth', 3.8);
% Balancim 4 (Verde Técnico Alinhado na Vertical)
h_l4 = plot([O4(1), B2(1)], [O4(2), B2(2)], 'Color', [0.10 0.65 0.25], 'LineWidth', 4.2);
% Biela Prensa 5 (Púrpura Alinhada na Vertical)
h_l5 = plot([B2(1), O5_PMI(1)], [B2(2), O5_PMI(2)], 'Color', [0.70 0.15 0.75], 'LineWidth', 4.2);

% Pistão / Navalha de Aço Temperado no PMI
fill([-11, 11, 11, 0, -11], ...
     [O5_PMI(2)+14, O5_PMI(2)+14, O5_PMI(2), O5_PMI(2)-7, O5_PMI(2)], ...
     [0.30 0.30 0.35], 'EdgeColor', 'k', 'LineWidth', 1.8);
plot(O5_PMI(1), O5_PMI(2), 'o', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 7);

% Cota do Curso Útil h = 30 mm
plot([-24, -24], [O5_PMS(2), O5_PMI(2)], 'k-', 'LineWidth', 1.4);
plot([-27, -21], [O5_PMS(2), O5_PMS(2)], 'k-', 'LineWidth', 1.4);
plot([-27, -21], [O5_PMI(2), O5_PMI(2)], 'k-', 'LineWidth', 1.4);
text(-31, (O5_PMS(2) + O5_PMI(2))/2, 'h = 30 mm', 'FontSize', 8.5, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');

% Rótulo do PMI posicionado sem sobreposição
text(14, O5_PMI(2) - 2, 'PMI: y = -223.9 mm', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.8 0.1 0.1]);

% Juntas no PMI
plot(A_PMI(1), A_PMI(2), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'MarkerSize', 7, 'LineWidth', 1.5);
text(A_PMI(1) - 4, A_PMI(2) + 9, 'A_{PMI}', 'FontSize', 8.5, 'FontWeight', 'bold');

plot(B2(1), B2(2), 's', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 9, 'LineWidth', 1.5);
text(B2(1) - 24, B2(2), 'B_{PMI}', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.5 0.1]);

% Mancais Fixos O4 e O2
% O4
plot(0, 0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 9);
fill([-8, 8, 0], [-10, -10, 0], [0.55 0.55 0.60], 'EdgeColor', 'k');
plot([-12, 12], [-10, -10], 'k-', 'LineWidth', 1.5);
text(6, 6, 'O_4 (0, 0)', 'FontSize', 9.5, 'FontWeight', 'bold');

% O2
plot(O2(1), O2(2), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 9);
fill([O2(1)-8, O2(1)+8, O2(1)], [O2(2)-10, O2(2)-10, O2(2)], [0.55 0.55 0.60], 'EdgeColor', 'k');
plot([O2(1)-12, O2(1)+12], [O2(2)-10, O2(2)-10], 'k-', 'LineWidth', 1.5);
text(O2(1) - 52, O2(2) - 13, sprintf('O_2 [%.1f; %.1f]', O2(1), O2(2)), 'FontSize', 8.5, 'FontWeight', 'bold');

% Linha da Base d entre O2 e O4
plot([O2(1), O4(1)], [O2(2), O4(2)], 'Color', [0.35 0.35 0.35], 'LineStyle', ':', 'LineWidth', 1.3);
text(-42, -40, sprintf('Base d = %.1f mm', d_base), 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);

title('Mecanismo Ultra-Compacto da Prensa (K = 1.5, \Delta\theta_4 = 30°)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Coordenada X (mm)', 'FontSize', 9.5);
ylabel('Coordenada Y (mm)', 'FontSize', 9.5);
xlim([-140, 50]); ylim([-275, 30]);

legend([h_l2, h_l3, h_l4, h_l5], ...
       {'Manivela L_2 = 29.0 mm', 'Biela L_3 = 58.0 mm', 'Balancim L_4 = 112.0 mm', 'Biela Prensa L_5 = 112.0 mm'}, ...
       'Location', 'northwest', 'FontSize', 8.5);

% === PAINEL DIREITO: CURVAS CINEMÁTICAS SINCRONIZADAS ===
subplot(2, 2, 2);
hold on; grid on;

N = 360;
t2_deg = linspace(0, 360, N);
y_pist = zeros(1, N);
mu_ang = zeros(1, N);

for i = 1:N
    t2 = deg2rad(t2_deg(i));
    xA = O2(1) + L2 * cos(t2);
    yA = O2(2) + L2 * sin(t2);
    d_A = sqrt(xA^2 + yA^2);
    a_circ = (L4^2 - L3^2 + d_A^2) / (2 * d_A);
    h_c = sqrt(max(0, L4^2 - a_circ^2));
    x2_c = a_circ * xA / d_A;
    y2_c = a_circ * yA / d_A;
    
    p_plus = [x2_c + h_c * (-yA)/d_A; y2_c + h_c * (xA)/d_A];
    p_minus = [x2_c - h_c * (-yA)/d_A; y2_c - h_c * (xA)/d_A];
    if p_plus(1) <= 0.01 && p_plus(2) < 0
        B_pt = p_plus;
    else
        B_pt = p_minus;
    end
    
    y_pist(i) = B_pt(2) - sqrt(L5^2 - B_pt(1)^2);
    
    v_biela = B_pt - [xA; yA];
    v_bal = B_pt - O4;
    cos_m = dot(v_biela, v_bal) / (norm(v_biela) * norm(v_bal));
    ang_m = rad2deg(acos(max(-1, min(1, cos_m))));
    if ang_m > 90, ang_m = 180 - ang_m; end
    mu_ang(i) = ang_m;
end

plot(t2_deg, y_pist, 'Color', [0.70 0.15 0.75], 'LineWidth', 2.4);
plot([0, 360], [O5_PMI(2), O5_PMI(2)], 'r--', 'LineWidth', 1.2);
plot([0, 360], [O5_PMS(2), O5_PMS(2)], 'b--', 'LineWidth', 1.2);

plot(180, O5_PMI(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
text(190, O5_PMI(2) + 2.5, 'PMI (Quebra: v_{pistão} = 0)', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', 'r');

title('Deslocamento do Pistão y_{O5}(\theta_2) [Curso h = 30.0 mm]', 'FontSize', 10, 'FontWeight', 'bold');
xlabel('Rotação da Manivela \theta_2 (graus)', 'FontSize', 8.5);
ylabel('Posição Vertical y (mm)', 'FontSize', 8.5);
xlim([0, 360]); ylim([-228, -190]);

% Subplot Inferior Direito: Ângulo de Transmissão mu
subplot(2, 2, 4);
hold on; grid on;

fill([0, 360, 360, 0], [40, 40, 90, 90], [0.88, 0.96, 0.88], 'EdgeColor', 'none');
plot([0, 360], [40, 40], 'r--', 'LineWidth', 1.2);
plot([0, 360], [90, 90], 'k:', 'LineWidth', 1.2);

plot(t2_deg, mu_ang, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.4);

plot(180, 75.0, 's', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 7);
text(190, 77.0, '\mu_{PMI} = 75.0° (96.6% torque útil)', 'FontSize', 8.5, 'FontWeight', 'bold');

text(15, 60.0, '\mu_{mín} = 56.8° (Folga de 16.8° sobre limite)', 'FontSize', 8.5, 'Color', [0.1 0.4 0.1], 'FontWeight', 'bold');
text(15, 43.0, 'Limite Mínimo de Norton (\mu \geq 40°)', 'FontSize', 8, 'Color', 'r', 'FontWeight', 'bold');

title('Ângulo de Transmissão \mu(\theta_2) [Zona Segura Norton]', 'FontSize', 10, 'FontWeight', 'bold');
xlabel('Rotação da Manivela \theta_2 (graus)', 'FontSize', 8.5);
ylabel('Ângulo \mu (graus)', 'FontSize', 8.5);
xlim([0, 360]); ylim([35, 95]);

caminho_fig = fullfile(assets_dir, 'mecanismo_ultracompacto_k15_posicoes.png');
print(fig, caminho_fig, '-dpng', '-r300');
fprintf('Figura estática refinada salva em: %s\n', caminho_fig);
