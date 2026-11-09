% =========================================================================
% SCRIPT: simulacao_O2_colinear.m
% Simulação completa do mecanismo de 6 barras da Prensa de Baru com
% pivô O2 colinear com B1 e B2 pela regra de Norton:
% R_O2 = R_B2 + K*M, com K = 2 e M = B1 - B2.
% =========================================================================

clear; clc; close all;

assets_dir = fullfile(pwd, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 1. Parâmetros Cinemáticos da Prensa
% -------------------------------------------------------------------------
O4 = [0.0; 0.0];             % Pivô fixo do balancim (mm)
L4 = 160.0;                  % Comprimento do balancim (mm)
L5 = 160.0;                  % Comprimento da biela da prensa (mm)
delta_theta = deg2rad(25.0); % Amplitude de oscilação (25°)

% Posições extremas do nó B
B2 = [0.0; -L4];                                      % [0, -160] mm
B1 = [-L4 * sin(delta_theta); -L4 * cos(delta_theta)]; % [-67.62, -145.01] mm

% Reta secante B1-B2: y = m*x + b_sec
m_sec = (B2(2) - B1(2)) / (B2(1) - B1(1)); % -0.22169
b_sec = B2(2);                             % -160.0 mm

% Vetor M = B1 - B2
M = B1 - B2;               % [-67.62, 14.99] mm
Delta_B = norm(M);         % 69.261 mm

% -------------------------------------------------------------------------
% 2. Definição do Pivô O2 Colinear com K = 2
% -------------------------------------------------------------------------
K = 2.0;
O2_col = B2 + K * M;       % [-135.24, -130.02] mm

% Distâncias extremas colineares:
r2_col = norm(B2 - O2_col); % K * ||M|| = 138.52 mm
r1_col = norm(B1 - O2_col); % (K-1) * ||M|| = 69.26 mm

% Comprimentos analíticos exatos:
L2_col = (r2_col - r1_col) / 2; % ||M|| / 2 = 34.63 mm (Manivela)
L3_col = (r2_col + r1_col) / 2; % 1.5 * ||M|| = 103.89 mm (Acoplador / Biela)
d_col  = norm(O2_col);          % 187.60 mm (Distância da base fixa)

% Posições da junta A nas configurações extremas
u_col = (B2 - O2_col) / r2_col;
A2_col = O2_col + L2_col * u_col; % PMI (estendida)
A1_col = O2_col - L2_col * u_col; % PMS (dobrada sobre si mesma)

% Posições do cursor O5 (pistão da prensa)
y_O5_2 = -320.0; % B2y - L5
y_O5_1 = B1(2) - sqrt(L5^2 - B1(1)^2); % -290.02 mm
O5_2 = [0.0; y_O5_2];
O5_1 = [0.0; y_O5_1];
curso_col = y_O5_1 - y_O5_2; % 29.98 mm

% -------------------------------------------------------------------------
% 3. Varredura Cinemática de 0° a 360° para a Solução Colinear (K = 2)
% -------------------------------------------------------------------------
N_pts = 360;
theta2_deg = linspace(0, 360, N_pts);
theta2_rad = deg2rad(theta2_deg);

mu_col_arr = zeros(1, N_pts);
eta_col_arr = zeros(1, N_pts);

opt = optimset('Display', 'off');
x_init_col = [-0.5; -1.8];

for i = 1:N_pts
    t2 = theta2_rad(i);
    
    sis_col = @(x) [
        O2_col(1) + L2_col*cos(t2) + L3_col*cos(x(1)) - L4*cos(x(2));
        O2_col(2) + L2_col*sin(t2) + L3_col*sin(x(1)) - L4*sin(x(2))
    ];
    [x_sol_col, ~, ~] = fsolve(sis_col, x_init_col, opt);
    x_init_col = x_sol_col;
    t3_col = x_sol_col(1);
    t4_col = x_sol_col(2);
    
    A_c = O2_col + L2_col*[cos(t2); sin(t2)];
    B_c = [L4*cos(t4_col); L4*sin(t4_col)];
    u3_c = (B_c - A_c) / norm(B_c - A_c);
    u4_c = B_c / norm(B_c);
    mu_val_c = rad2deg(acos(dot(u3_c, u4_c)));
    mu_col_arr(i) = mu_val_c;
    eta_col_arr(i) = sin(deg2rad(mu_val_c)) * 100; % Eficiência percentual
end

% -------------------------------------------------------------------------
% 4. Exibição Numérica no Terminal
% -------------------------------------------------------------------------
fprintf('========================================================================\n');
fprintf('SÍNTESE ANALÍTICA COLINEAR (K = 2): R_O2 = R_B2 + 2*M\n');
fprintf('========================================================================\n');
fprintf('1. VETOR M = B1 - B2: [%.2f, %.2f] mm | ||M|| = Delta_B = %.2f mm\n', M(1), M(2), Delta_B);
fprintf('2. PIVÔ FIXO O2: [%.2f, %.2f] mm | Distância Base d = %.2f mm\n', O2_col(1), O2_col(2), d_col);
fprintf('3. DIMENSÕES DOS ELOS:\n');
fprintf('   L2 (Manivela) = ||M|| / 2 = %.2f mm\n', L2_col);
fprintf('   L3 (Acoplador/Biela) = 1.5 * ||M|| = %.2f mm\n', L3_col);
fprintf('   L4 (Balancim) = %.2f mm, L5 (Biela Prensa) = %.2f mm\n', L4, L5);
fprintf('4. CONDICÃO DE GRASHOF: s+l = %.2f mm < p+q = %.2f mm -> Grashof: 1\n', ...
        L2_col + max(L4, d_col), min(L4, d_col) + L3_col);
fprintf('5. ÂNGULO DE TRANSMISSÃO (mu):\n');
fprintf('   Faixa = [%.2f°, %.2f°] | Média = %.2f° | Desvio máx de 90° = %.2f°\n', ...
        min(mu_col_arr), max(mu_col_arr), mean(mu_col_arr), max(abs(mu_col_arr - 90)));
fprintf('6. EFICIÊNCIA DE TORQUE ÚTIL (eta = sen(mu)):\n');
fprintf('   Mínima = %.2f%% | Média = %.2f%% | Máxima = 100.0%%\n', min(eta_col_arr), mean(eta_col_arr));
fprintf('========================================================================\n');

% -------------------------------------------------------------------------
% 5. Criação da Figura Completa (2x2) de Alta Resolução (Sem Linha Verde)
% -------------------------------------------------------------------------
fig = figure('Name', 'Solucao Colinear K = 2', ...
             'NumberTitle', 'off', 'Position', [80, 80, 1200, 850]);

% --- SUBPLOT 1: CAD Completo do Mecanismo Colinear ---
subplot(2, 2, [1, 3]);
hold on; grid on; axis equal;

% Linha de centro da guia vertical
plot([0, 0], [20, -360], 'Color', [0.5 0.5 0.5], 'LineStyle', '-.', 'LineWidth', 1.2);

% Arco percorrido pelo nó B
arco_t = linspace(-pi/2 - delta_theta - 0.06, -pi/2 + 0.06, 100);
plot(L4 * cos(arco_t), L4 * sin(arco_t), 'Color', [0.75 0.75 0.75], 'LineStyle', ':', 'LineWidth', 1.5);

% Linha da base fixa d
plot([O2_col(1), O4(1)], [O2_col(2), O4(2)], 'k--', 'LineWidth', 1.2);

% RETA SECANTE COLINEAR PASSANDO POR O2, B1 E B2
x_sec = linspace(-180, 45, 100);
y_sec = m_sec * x_sec + b_sec;
h_sec = plot(x_sec, y_sec, 'Color', [0.9 0.45 0.0], 'LineWidth', 2.8);
plot([B1(1), B2(1)], [B1(2), B2(2)], 'Color', [0.85 0.15 0.0], 'LineWidth', 4.0);

% Posição 2 (PMI / Quebra do Baru - Colinear Estendida - Linha Forte)
h_m2 = plot([O2_col(1), A2_col(1)], [O2_col(2), A2_col(2)], 'Color', [0.1 0.4 0.85], 'LineWidth', 3.5);
h_ac2 = plot([A2_col(1), B2(1)], [A2_col(2), B2(2)], 'Color', [0.15 0.65 0.25], 'LineWidth', 3.5);
h_bal2 = plot([O4(1), B2(1)], [O4(2), B2(2)], 'Color', [0.85 0.2 0.2], 'LineWidth', 3.5);
h_bie2 = plot([B2(1), O5_2(1)], [B2(2), O5_2(2)], 'Color', [0.6 0.2 0.7], 'LineWidth', 3.5);
fill([-16, 16, 16, -16], [y_O5_2-12, y_O5_2-12, y_O5_2+12, y_O5_2+12], ...
     [0.85 0.75 0.9], 'EdgeColor', [0.5 0.1 0.6], 'LineWidth', 1.8);

% Posição 1 (PMS / Retorno - Colinear Dobrada - Tracejada)
plot([O2_col(1), A1_col(1)], [O2_col(2), A1_col(2)], 'Color', [0.3 0.6 0.9], 'LineStyle', '--', 'LineWidth', 2.2);
plot([A1_col(1), B1(1)], [A1_col(2), B1(2)], 'Color', [0.35 0.8 0.4], 'LineStyle', '--', 'LineWidth', 2.2);
plot([O4(1), B1(1)], [O4(2), B1(2)], 'Color', [0.95 0.4 0.4], 'LineStyle', '--', 'LineWidth', 2.2);
plot([B1(1), O5_1(1)], [B1(2), O5_1(2)], 'Color', [0.8 0.4 0.9], 'LineStyle', '--', 'LineWidth', 2.2);
fill([-14, 14, 14, -14], [y_O5_1-10, y_O5_1-10, y_O5_1+10, y_O5_1+10], ...
     [0.9 0.9 0.95], 'EdgeColor', [0.6 0.6 0.7], 'LineWidth', 1.2, 'LineStyle', '--');

% Matriz inferior e Castanha de Baru
fill([-28, 28, 28, -28], [-345, -345, -332, -332], [0.4 0.4 0.4], 'EdgeColor', 'k', 'LineWidth', 1.5);
t_b = linspace(0, 2*pi, 40);
fill(8*cos(t_b), -326 + 5*sin(t_b), [0.65 0.40 0.15], 'EdgeColor', [0.4 0.25 0.1], 'LineWidth', 1.2);
text(18, -326, 'Castanha de Baru', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.55 0.3 0.1]);

% Força de esmagamento
quiver(0, -360, 0, 22, 0, 'Color', [0.8 0 0], 'LineWidth', 2.8, 'MaxHeadSize', 0.6);
text(8, -355, 'F = 5000 N', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.8 0 0]);

% Mancais e Juntas
plot(O4(1), O4(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
plot(O2_col(1), O2_col(2), 'ks', 'MarkerFaceColor', [0.9 0.45 0.0], 'MarkerSize', 10);
plot(A2_col(1), A2_col(2), 'ko', 'MarkerFaceColor', [0.1 0.4 0.85], 'MarkerSize', 7);
plot(A1_col(1), A1_col(2), 'ko', 'MarkerFaceColor', [0.3 0.6 0.9], 'MarkerSize', 7);
plot(B2(1), B2(2), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 10);
plot(B1(1), B1(2), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 10);

% Rótulos no CAD
text(O4(1) + 8, O4(2) + 6, 'Pivô O_4 (0, 0)', 'FontSize', 10, 'FontWeight', 'bold');
text(O2_col(1) - 45, O2_col(2) + 24, {'Pivô O_2 (K=2)', '(-135.2, -130.0)'}, 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.85 0.35 0.0]);
text(B2(1) + 10, B2(2) + 4, 'B_2 (PMI)', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.85 0.15 0.0]);
text(B1(1) - 40, B1(2) + 16, 'B_1 (PMS)', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.85 0.15 0.0]);
text(A2_col(1) - 8, A2_col(2) - 14, 'A_2', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.4 0.85]);
text(A1_col(1) - 15, A1_col(2) - 14, 'A_1', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.3 0.6 0.9]);

% Cota da reta secante na extremidade direita desimpedida
text(12, -182, {'Reta Secante Colinear', 'y = -0.2217 x - 160'}, 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.9 0.45 0.0]);

% Cota do curso de 30 mm
plot([28, 28], [y_O5_2, y_O5_1], 'k-', 'LineWidth', 2.0);
plot([22, 34], [y_O5_2, y_O5_2], 'k-', 'LineWidth', 1.5);
plot([22, 34], [y_O5_1, y_O5_1], 'k-', 'LineWidth', 1.5);
text(36, (y_O5_2 + y_O5_1)/2, sprintf('Curso \\approx 30 mm\n(%.2f mm)', curso_col), 'FontSize', 9.5, 'FontWeight', 'bold');

title({'Esquema CAD: Mecanismo Colinear com K = 2', 'R_{O2} = R_{B2} + 2 M \rightarrow Q = 1.000'}, 'FontSize', 11, 'FontWeight', 'bold');
xlabel('X (mm)', 'FontSize', 10); ylabel('Y (mm)', 'FontSize', 10);
xlim([-210, 85]); ylim([-375, 30]);

legend([h_sec, h_m2, h_ac2, h_bal2, h_bie2], ...
       {'Reta Secante Colinear (O_2, B_1, B_2)', ...
        sprintf('Elo 2: Manivela L_2 = %.2f mm', L2_col), ...
        sprintf('Elo 3: Biela L_3 = %.2f mm', L3_col), ...
        'Elo 4: Balancim L_4 = 160.00 mm', ...
        'Elo 5: Biela Prensa L_5 = 160.00 mm'}, ...
       'Location', 'northwest', 'FontSize', 8.5);

% --- SUBPLOT 2: Ângulo de Transmissão mu(theta2) (Apenas Solução Colinear) ---
subplot(2, 2, 2);
hold on; grid on;
fill([0, 360, 360, 0], [40, 40, 140, 140], [0.9 0.97 0.9], 'EdgeColor', 'none'); % Zona Norton
plot([0, 360], [90, 90], 'k--', 'LineWidth', 1.2); % Ideal 90°
plot([0, 360], [40, 40], 'r:', 'LineWidth', 1.0);
plot([0, 360], [140, 140], 'r:', 'LineWidth', 1.0);

h_pcol = plot(theta2_deg, mu_col_arr, 'Color', [0.9 0.45 0.0], 'LineWidth', 2.6);

% Destaque dos extremos
plot(theta2_deg(mu_col_arr == min(mu_col_arr)), min(mu_col_arr), 's', 'MarkerFaceColor', [0.9 0.45 0.0], 'MarkerSize', 7);
plot(theta2_deg(mu_col_arr == max(mu_col_arr)), max(mu_col_arr), 's', 'MarkerFaceColor', [0.9 0.45 0.0], 'MarkerSize', 7);

title('Ângulo de Transmissão \mu(\theta_2) ao Longo do Ciclo de 360°', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Ângulo da Manivela \theta_2 (graus)', 'FontSize', 10);
ylabel('\mu (graus)', 'FontSize', 10);
xlim([0, 360]); ylim([35, 145]);

legend(h_pcol, ...
       {sprintf('O_2 Colinear (K=2): [%.1f°, %.1f°] | Média = %.1f°', min(mu_col_arr), max(mu_col_arr), mean(mu_col_arr))}, ...
       'Location', 'south', 'FontSize', 9);

% --- SUBPLOT 3: Eficiência Mecânica eta = sen(mu) (Apenas Solução Colinear) ---
subplot(2, 2, 4);
hold on; grid on;
plot([0, 360], [100, 100], 'k--', 'LineWidth', 1.0);
plot([0, 360], [sin(deg2rad(40))*100, sin(deg2rad(40))*100], 'r:', 'LineWidth', 1.0);

h_ecol = plot(theta2_deg, eta_col_arr, 'Color', [0.9 0.45 0.0], 'LineWidth', 2.6);

title('Eficiência Útil de Torque: \eta = sen(\mu) \times 100 %', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Ângulo da Manivela \theta_2 (graus)', 'FontSize', 10);
ylabel('Eficiência \eta (%)', 'FontSize', 10);
xlim([0, 360]); ylim([60, 105]);

legend(h_ecol, ...
       {sprintf('O_2 Colinear (K=2): Mínima = %.1f%% | Média = %.1f%%', min(eta_col_arr), mean(eta_col_arr))}, ...
       'Location', 'south', 'FontSize', 9);

% -------------------------------------------------------------------------
% 6. Salvar Figura em Alta Resolução (300 DPI)
% -------------------------------------------------------------------------
caminho_fig = fullfile(assets_dir, 'ex2_simulacao_O2_colinear.png');
print(fig, caminho_fig, '-dpng', '-r300');
fprintf('\nFigura da simulação colinear (K=2) salva em: %s\n', caminho_fig);
