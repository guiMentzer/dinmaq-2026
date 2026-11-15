% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Projeto para Garantir mu = 90° na Quebra do Baru (Delta_theta4 = 30°)
% Comparativo: Síntese Colinear vs Síntese de mu = 90° Exato no PMI
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% 1. Parâmetros do mecanismo para Delta_theta4 = 30°
h = 30.0; % Curso (mm)
dt = deg2rad(30.0);
L4 = h / (2.0 * (1.0 - cos(dt))); % 111.96 mm
L5 = L4;

B2 = [0.0; -L4]; % PMI (0, -111.96) mm
B1 = [-L4 * sin(dt); -L4 * cos(dt)]; % PMS (-55.98, -96.96) mm
M = B1 - B2;

% --- CONFIGURAÇÃO A: Síntese Colinear Simétrica (K = 2, Máxima Compacidade) ---
O2_A = B2 + 2.0 * M; % [-111.96, -81.96] mm
r1_A = norm(B1 - O2_A); r2_A = norm(B2 - O2_A);
L2_A = (r2_A - r1_A) / 2.0; % 28.98 mm
L3_A = (r2_A + r1_A) / 2.0; % 86.93 mm
d_A  = norm(O2_A);          % 138.76 mm

% --- CONFIGURAÇÃO B: Síntese com mu = 90° EXATO no PMI (y_O2 = -L4) ---
% Para que em B2 (balancim vertical) a biela seja perpendicular (horizontal), y_O2 deve ser -L4:
O2_B = [-160.00; -L4];      % [-160.00, -111.96] mm
r1_B = norm(B1 - O2_B); r2_B = norm(B2 - O2_B);
L2_B = (r2_B - r1_B) / 2.0; % 27.45 mm
L3_B = (r2_B + r1_B) / 2.0; % 132.55 mm
d_B  = norm(O2_B);          % 195.28 mm

% 2. Simulação da Cinemática da Volta Completa (360°)
N = 360;
th2 = linspace(0, 360, N);
opt = optimset('Display', 'off');

y_A = zeros(1, N); mu_A = zeros(1, N);
x_currA = [atan2(B2(2)-O2_A(2), B2(1)-O2_A(1)); -pi/2];

y_B = zeros(1, N); mu_B = zeros(1, N);
x_currB = [0; -pi/2];

for k = 1:N
    t2 = deg2rad(th2(k));
    
    % Config A
    sisA = @(x) [O2_A(1) + L2_A*cos(t2) + L3_A*cos(x(1)) - L4*cos(x(2));
                 O2_A(2) + L2_A*sin(t2) + L3_A*sin(x(1)) - L4*sin(x(2))];
    [xA, ~, ~] = fsolve(sisA, x_currA, opt); x_currA = xA;
    diffA = abs(xA(2) - xA(1)); diffA = mod(diffA, 2*pi);
    if diffA > pi, diffA = 2*pi - diffA; end
    mu_A(k) = rad2deg(diffA);
    xBA = L4*cos(xA(2)); yBA = L4*sin(xA(2));
    y_A(k) = yBA - sqrt(L5^2 - xBA^2);
    
    % Config B
    sisB = @(x) [O2_B(1) + L2_B*cos(t2) + L3_B*cos(x(1)) - L4*cos(x(2));
                 O2_B(2) + L2_B*sin(t2) + L3_B*sin(x(1)) - L4*sin(x(2))];
    [xB, ~, ~] = fsolve(sisB, x_currB, opt); x_currB = xB;
    diffB = abs(xB(2) - xB(1)); diffB = mod(diffB, 2*pi);
    if diffB > pi, diffB = 2*pi - diffB; end
    mu_B(k) = rad2deg(diffB);
    xBB = L4*cos(xB(2)); yBB = L4*sin(xB(2));
    y_B(k) = yBB - sqrt(L5^2 - xBB^2);
end

% -------------------------------------------------------------------------
% CRIAÇÃO DA FIGURA TÉCNICA COMPOSTA (300 DPI)
% -------------------------------------------------------------------------
fig = figure('Name', 'Analise mu = 90 graus Quebra Baru', 'NumberTitle', 'off', 'Position', [100, 100, 1100, 750]);

% --- SUBPLOT 1: Sensibilidade de Torque Util (sen(mu)) ---
subplot(2, 2, 1);
mu_vec = linspace(30, 150, 300);
sin_eff = sin(deg2rad(mu_vec));
plot(mu_vec, sin_eff * 100, 'Color', [0.15 0.55 0.2], 'LineWidth', 2.3); hold on; grid on;

% Zona de altíssima eficiência [75°, 105°] >= 96.6%
fill([75, 105, 105, 75], [0, 0, 105, 105], [0.85 0.96 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
plot(mu_vec, sin_eff * 100, 'Color', [0.15 0.55 0.2], 'LineWidth', 2.3); % replot
plot([90, 90], [0, 100], 'r--', 'LineWidth', 1.4);
plot(90, 100, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

% Linha de 96.6% (sen(75°))
plot([30, 150], [sin(deg2rad(75))*100, sin(deg2rad(75))*100], 'b--', 'LineWidth', 1.1);

text(92, 101, 'Ponto Ótimo: \mu = 90° (100% Torque)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'r');
text(76, 50, {'Platô de Alta Eficiência:', '75° \leq \mu \leq 105° (\geq 96.6%)'}, 'FontSize', 9, 'Color', [0.1 0.5 0.1], 'FontWeight', 'bold');
text(35, 93, 'sen(75°) = 96.6%', 'FontSize', 8.5, 'Color', 'b', 'FontWeight', 'bold');

title('Curva de Sensibilidade: Fração de Força Útil \tau_{útil} \propto sen(\mu)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Ângulo de Transmissão \mu (graus)', 'FontSize', 10);
ylabel('Eficiência de Transmissão de Torque (%)', 'FontSize', 10);
xlim([30, 150]); ylim([40, 105]);

% --- SUBPLOT 2: Esquema Geométrico das Duas Sínteses no PMI ---
subplot(2, 2, 2);
hold on; grid on; axis equal;

% Balancim vertical no PMI (comum a ambas)
plot([0, 0], [0, -L4], 'k-', 'LineWidth', 3.0);
plot(0, 0, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(0, -L4, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);

% Config A: Colinear (Verde)
plot([O2_A(1), 0], [O2_A(2), -L4], 'Color', [0.1 0.65 0.25], 'LineWidth', 2.2, 'LineStyle', '--');
plot(O2_A(1), O2_A(2), 's', 'MarkerFaceColor', [0.1 0.65 0.25], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

% Config B: mu = 90° Exato (Azul, biela estritamente horizontal)
plot([O2_B(1), 0], [O2_B(2), -L4], 'Color', [0.0 0.45 0.85], 'LineWidth', 2.6);
plot(O2_B(1), O2_B(2), 's', 'MarkerFaceColor', [0.0 0.45 0.85], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

% Indicação do ângulo reto na Config B
plot([-15, -15, 0], [-L4, -L4+15, -L4+15], 'Color', [0.0 0.45 0.85], 'LineWidth', 1.5);
text(-28, -L4+22, '\mu = 90°', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.0 0.45 0.85]);

% Indicação de mu = 75° na Config A
text(10, -L4+30, '\mu \approx 75°', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.65 0.25]);

text(6, 6, 'Pivô O_4 (0, 0)', 'FontSize', 9, 'FontWeight', 'bold');
text(6, -L4, sprintf('B_2 (0, -%.1f)', L4), 'FontSize', 9, 'FontWeight', 'bold');
text(O2_A(1)-40, O2_A(2)+12, sprintf('O_{2, colinear}\n[-112, -82]'), 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.1 0.65 0.25]);
text(O2_B(1)-45, O2_B(2)-14, sprintf('O_{2, \\mu=90°}\n[-160, -112]'), 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.0 0.45 0.85]);

title('Geometria da Biela no PMI: Biela Horizontal Garante \mu = 90°', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('X (mm)', 'FontSize', 10); ylabel('Y (mm)', 'FontSize', 10);
xlim([-210, 50]); ylim([-145, 25]);
legend({'Balancim L_4 (Vertical)', 'Pivô O_4', 'Junta B_2', ...
        'Config A: Colinear (\mu = 75.0°, L_3=86.9 mm)', ...
        'Config B: Horizontal (\mu = 90.0°, L_3=132.6 mm)'}, ...
        'Location', 'northwest', 'FontSize', 8);

% --- SUBPLOT 3: mu(theta2) vs Curso da Navalha ---
subplot(2, 1, 2);
hold on; grid on;

% Faixa aceitável de Norton
fill([0, 360, 360, 0], [40, 40, 140, 140], [0.92, 0.97, 0.92], 'EdgeColor', 'none');
plot([0, 360], [90, 90], 'k--', 'LineWidth', 1.3);
plot([0, 360], [40, 40], 'r--', 'LineWidth', 1.0);

h_A = plot(th2, mu_A, 'Color', [0.1 0.65 0.25], 'LineWidth', 2.3);
h_B = plot(th2, mu_B, 'Color', [0.0 0.45 0.85], 'LineWidth', 2.3);

% Destacar a região de esmagamento (próximo a theta2 = 180° / descida da faca)
plot([180, 180], [35, 140], 'm:', 'LineWidth', 1.5);
text(182, 48, 'Descida Máxima (PMI / Esmagamento)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'm');

title('Variação de \mu(\theta_2): Configuração A (Colinear Mais Compacta) vs Configuração B (\mu = 90° no Fundo)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Posição da Manivela \theta_2 (graus)', 'FontSize', 10);
ylabel('Ângulo de Transmissão \mu (graus)', 'FontSize', 10);
xlim([0, 360]); ylim([35, 145]);

legend([h_A, h_B], ...
    {sprintf('Config A (Colinear K=2): \\mu \\in [%.1f°, %.1f°] | \\mu_{PMI} = 75.0° (sen=96.6%%) | L_3=86.9 mm, d=138.8 mm', min(mu_A), max(mu_A)), ...
     sprintf('Config B (Síntese \\mu=90°): \\mu \\in [%.1f°, %.1f°] | \\mu_{PMI} = 90.0° (sen=100%%) | L_3=132.6 mm, d=195.3 mm', min(mu_B), max(mu_B))}, ...
    'Location', 'south', 'FontSize', 9);

caminho_fig = fullfile(assets_dir, 'analise_mu_90_quebra.png');
print(fig, caminho_fig, '-dpng', '-r300');
fprintf('Figura salva com sucesso em: %s\n', caminho_fig);
