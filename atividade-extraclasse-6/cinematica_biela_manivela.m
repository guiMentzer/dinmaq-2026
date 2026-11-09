% =========================================================================
% Atividade Extraclasse nº 6 - Cinemática da Biela-Manivela
% Resolução Numérica no Octave (Loop Vetorial & Jacobiana de Norton)
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================
clear; close all; clc;

% Diretório para salvar imagens
[script_dir, ~, ~] = fileparts(mfilename('fullpath'));
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 1. Parâmetros Geométricos e Operacionais
% -------------------------------------------------------------------------
C = 77.4e-3;            % Curso total do pistão [m]
a = C / 2;              % Raio da manivela [m] (38.7 mm)
b = 144e-3;             % Comprimento da biela [m] (144.0 mm)

% Condição (a): w = 1600 rpm, alpha = 0.1 rad/s^2
w2_a = 1600 * (2*pi/60); % [rad/s]
alpha2_a = 0.1;          % [rad/s^2]

% Condição (b): w = 5000 rpm, alpha = 0 rad/s^2
w2_b = 5000 * (2*pi/60); % [rad/s]
alpha2_b = 0.0;          % [rad/s^2]

% Vetor de ângulo da manivela (0 a 360 graus)
theta2_deg = 0:0.5:360;
N = length(theta2_deg);
theta2_rad = deg2rad(theta2_deg);

% Pré-alocação dos vetores
theta3     = zeros(1, N);
d_pos      = zeros(1, N);
w3_a       = zeros(1, N);
vB_a       = zeros(1, N);
alpha3_a   = zeros(1, N);
aB_a       = zeros(1, N);
w3_b       = zeros(1, N);
vB_b       = zeros(1, N);
alpha3_b   = zeros(1, N);
aB_b       = zeros(1, N);

% -------------------------------------------------------------------------
% 2. Solução Numérica: Posição, Velocidades e Acelerações
% -------------------------------------------------------------------------
chute_pos = [0; a + b]; % Chute inicial [theta3; d]
options = optimset('Display', 'off');

for k = 1:N
    t2 = theta2_rad(k);

    % --- 2.1. Posição Numérica (fsolve) ---
    sis_pos = @(x) [
        a * cos(t2) + b * cos(x(1)) - x(2);
        a * sin(t2) + b * sin(x(1))
    ];
    sol_pos = fsolve(sis_pos, chute_pos, options);
    theta3(k) = sol_pos(1);
    d_pos(k)  = sol_pos(2);
    chute_pos = sol_pos; % Continuidade numérica

    % Matriz Jacobiana (idêntica para velocidades e acelerações)
    J = [
        -b * sin(theta3(k)), -1;
         b * cos(theta3(k)),  0
    ];

    % --- 2.2. Velocidades Numéricas (J \ b_vel) ---
    % Condição (a)
    b_vel_a = [
        a * w2_a * sin(t2);
       -a * w2_a * cos(t2)
    ];
    sol_vel_a   = J \ b_vel_a;
    w3_a(k)     = sol_vel_a(1);
    vB_a(k)     = sol_vel_a(2);

    % Condição (b)
    b_vel_b = [
        a * w2_b * sin(t2);
       -a * w2_b * cos(t2)
    ];
    sol_vel_b   = J \ b_vel_b;
    w3_b(k)     = sol_vel_b(1);
    vB_b(k)     = sol_vel_b(2);

    % --- 2.3. Acelerações Numéricas (J \ b_acc) ---
    % Condição (a)
    b_acc_a = [
        a * alpha2_a * sin(t2) + a * (w2_a^2) * cos(t2) + b * (w3_a(k)^2) * cos(theta3(k));
       -a * alpha2_a * cos(t2) + a * (w2_a^2) * sin(t2) + b * (w3_a(k)^2) * sin(theta3(k))
    ];
    sol_acc_a   = J \ b_acc_a;
    alpha3_a(k) = sol_acc_a(1);
    aB_a(k)     = sol_acc_a(2);

    % Condição (b)
    b_acc_b = [
        a * alpha2_b * sin(t2) + a * (w2_b^2) * cos(t2) + b * (w3_b(k)^2) * cos(theta3(k));
       -a * alpha2_b * cos(t2) + a * (w2_b^2) * sin(t2) + b * (w3_b(k)^2) * sin(theta3(k))
    ];
    sol_acc_b   = J \ b_acc_b;
    alpha3_b(k) = sol_acc_b(1);
    aB_b(k)     = sol_acc_b(2);
end

theta3_deg = rad2deg(theta3);
d_pos_mm   = d_pos * 1e3;

% Acelerações nos Centros de Gravidade (5000 rpm) com G2 a 3/7 de a e G3 a 1/4 de b
aG2x_b = -(3/7) * a * (alpha2_b * sin(theta2_rad) + (w2_b^2) * cos(theta2_rad));
aG2y_b =  (3/7) * a * (alpha2_b * cos(theta2_rad) - (w2_b^2) * sin(theta2_rad));
aAx_b  = -a * (alpha2_b * sin(theta2_rad) + (w2_b^2) * cos(theta2_rad));
aAy_b  =  a * (alpha2_b * cos(theta2_rad) - (w2_b^2) * sin(theta2_rad));
aG3x_b = aAx_b - (1/4) * b * (alpha3_b .* sin(theta3) + (w3_b.^2) .* cos(theta3));
aG3y_b = aAy_b + (1/4) * b * (alpha3_b .* cos(theta3) - (w3_b.^2) .* sin(theta3));

% -------------------------------------------------------------------------
% 3. Geração dos Gráficos (300 DPI)
% -------------------------------------------------------------------------

% FIGURA 1: Análise Posicional
fig1 = figure('Visible', 'off', 'Position', [100, 100, 900, 650]);
subplot(2, 1, 1);
plot(theta2_deg, theta3_deg, 'b-', 'LineWidth', 2);
grid on;
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
title('Posição Angular da Biela: \theta_3 vs \theta_2', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('\theta_2 (graus)'); ylabel('\theta_3 (graus)');
line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);

subplot(2, 1, 2);
plot(theta2_deg, d_pos_mm, 'r-', 'LineWidth', 2);
grid on;
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
title('Deslocamento Linear do Pistão: d vs \theta_2', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('\theta_2 (graus)'); ylabel('Posição d (mm)');
line(xlim, [(b-a)*1e3, (b-a)*1e3], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 1);
line(xlim, [(b+a)*1e3, (b+a)*1e3], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 1);
print(fig1, fullfile(assets_dir, 'grafico_posicao.png'), '-dpng', '-r300');

% FIGURA 2: Análise de Velocidades
fig2 = figure('Visible', 'off', 'Position', [100, 100, 900, 650]);
subplot(2, 1, 1);
plot(theta2_deg, w3_a, 'b-', 'LineWidth', 2, 'DisplayName', '\omega_3 (1600 rpm)'); hold on;
plot(theta2_deg, w3_b, 'b--', 'LineWidth', 1.5, 'DisplayName', '\omega_3 (5000 rpm)');
grid on;
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
title('Velocidade Angular da Biela: \omega_3 vs \theta_2', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('\theta_2 (graus)'); ylabel('\omega_3 (rad/s)');
legend('Location', 'northeast');
line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '--');

subplot(2, 1, 2);
plot(theta2_deg, vB_a, 'r-', 'LineWidth', 2, 'DisplayName', 'v_B (1600 rpm)'); hold on;
plot(theta2_deg, vB_b, 'r--', 'LineWidth', 1.5, 'DisplayName', 'v_B (5000 rpm)');
grid on;
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
title('Velocidade Linear do Pistão: v_B vs \theta_2', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('\theta_2 (graus)'); ylabel('v_B (m/s)');
legend('Location', 'northeast');
line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '--');
print(fig2, fullfile(assets_dir, 'grafico_velocidades.png'), '-dpng', '-r300');

% FIGURA 3: Análise de Acelerações
fig3 = figure('Visible', 'off', 'Position', [100, 100, 900, 650]);
subplot(2, 1, 1);
plot(theta2_deg, alpha3_a, 'm-', 'LineWidth', 2, 'DisplayName', '\alpha_3 (1600 rpm, \alpha_2=0.1)'); hold on;
plot(theta2_deg, alpha3_b, 'm--', 'LineWidth', 1.5, 'DisplayName', '\alpha_3 (5000 rpm, \alpha_2=0)');
grid on;
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
title('Aceleração Angular da Biela: \alpha_3 vs \theta_2', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('\theta_2 (graus)'); ylabel('\alpha_3 (rad/s^2)');
legend('Location', 'northeast');
line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '--');

subplot(2, 1, 2);
plot(theta2_deg, aB_a, 'k-', 'LineWidth', 2, 'DisplayName', 'a_B (1600 rpm)'); hold on;
plot(theta2_deg, aB_b, 'k--', 'LineWidth', 1.5, 'DisplayName', 'a_B (5000 rpm)');
grid on;
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
title('Aceleração Linear do Pistão: a_B vs \theta_2', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('\theta_2 (graus)'); ylabel('a_B (m/s^2)');
legend('Location', 'northeast');
line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '--');
print(fig3, fullfile(assets_dir, 'grafico_aceleracoes.png'), '-dpng', '-r300');

% FIGURA 4: Hodógrafo de Aceleração dos Centros de Gravidade (5000 rpm)
fig4 = figure('Visible', 'off', 'Position', [100, 100, 900, 650]);
plot(aG2x_b, aG2y_b, 'b-', 'LineWidth', 2, 'DisplayName', 'a_{G2} (Manivela)'); hold on;
plot(aG3x_b, aG3y_b, 'r-', 'LineWidth', 2, 'DisplayName', 'a_{G3} (Biela)');
plot(aB_b, zeros(size(aB_b)), 'k-', 'LineWidth', 2.5, 'DisplayName', 'a_B (Pistão)');
grid on; axis equal;
title('Hodógrafo de Aceleração dos Centros de Gravidade (\omega = 5000 rpm)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('a_x (m/s^2)'); ylabel('a_y (m/s^2)');
legend('Location', 'northeast');
print(fig4, fullfile(assets_dir, 'grafico_hodografo_aceleracoes.png'), '-dpng', '-r300');

fprintf('Execução concluída e imagens salvas em %s com sucesso!\n', assets_dir);
