% =========================================================================
% Análise de Posição - Mecanismo de 4 Barras (Grashof Manivela-Balancim)
% Disciplina: Dinâmica das Máquinas
% =========================================================================

clear; clc; close all;

% 1. Definição dos parâmetros conhecidos (comprimentos em mm)
a = 40.0;          % Comprimento do elo 2 (manivela)
b = 208.0;         % Comprimento do elo 3 (acoplador)
c = 156.0;         % Comprimento do elo 4 (balancim)
d = 200.0;         % Comprimento da base (elo 1)

% -------------------------------------------------------------------------
% 2. Resolução para a posição específica theta2 = 45° (Item b da Atividade 1)
% -------------------------------------------------------------------------
theta2_especifico = deg2rad(45);

% Sistema de equações F(x) = 0:
% x(1) = theta3, x(2) = theta4
sistema_45 = @(x) [
    a * cos(theta2_especifico) + b * cos(x(1)) - c * cos(x(2)) - d;
    a * sin(theta2_especifico) + b * sin(x(1)) - c * sin(x(2))
];

% Chute inicial em radianos para a configuração de montagem
x0 = [deg2rad(20); deg2rad(45)];

options = optimset('Display', 'off');
[x_sol_45, fval_45, info_45] = fsolve(sistema_45, x0, options);

if info_45 > 0
    fprintf("=========================================\n");
    fprintf("Solução para theta2 = 45°:\n");
    fprintf("theta3 = %.4f rad (%.2f°)\n", x_sol_45(1), rad2deg(x_sol_45(1)));
    fprintf("theta4 = %.4f rad (%.2f°)\n", x_sol_45(2), rad2deg(x_sol_45(2)));
    fprintf("Resíduo: [%e, %e]\n", fval_45(1), fval_45(2));
    fprintf("=========================================\n\n");
else
    fprintf("Aviso: Falha na convergência para theta2 = 45°.\n");
end

% -------------------------------------------------------------------------
% 3. Variação de theta2 para uma volta completa (0° a 360°)
% -------------------------------------------------------------------------
theta2_deg = 0:1:360;
theta2_rad = deg2rad(theta2_deg);

theta3_deg = zeros(size(theta2_deg));
theta4_deg = zeros(size(theta2_deg));

% Chute inicial para theta2 = 0
x_atual = [deg2rad(30); deg2rad(90)];

for k = 1:length(theta2_rad)
    t2 = theta2_rad(k);
    
    sistema = @(x) [
        a * cos(t2) + b * cos(x(1)) - c * cos(x(2)) - d;
        a * sin(t2) + b * sin(x(1)) - c * sin(x(2))
    ];
    
    [x_sol, ~, info] = fsolve(sistema, x_atual, options);
    
    if info > 0
        theta3_deg(k) = rad2deg(x_sol(1));
        theta4_deg(k) = rad2deg(x_sol(2));
        % Continuidade: a solução do passo atual vira o chute do próximo passo
        x_atual = x_sol;
    else
        warning("Convergência falhou para theta2 = %d°", theta2_deg(k));
    end
end

% -------------------------------------------------------------------------
% 4. Geração dos Gráficos: theta3 e theta4 em função de theta2
% -------------------------------------------------------------------------
% Identificação dos pontos extremos (mínimo e máximo) do balancim (theta4)
[theta4_min, idx_min] = min(theta4_deg);
theta2_min = theta2_deg(idx_min);

[theta4_max, idx_max] = max(theta4_deg);
theta2_max = theta2_deg(idx_max);

fprintf("Extremos do balancim (theta4):\n");
fprintf("  Mínimo: %.2f° em theta2 = %d°\n", theta4_min, theta2_min);
fprintf("  Máximo: %.2f° em theta2 = %d°\n", theta4_max, theta2_max);
fprintf("  Amplitude de oscilação: %.2f°\n\n", theta4_max - theta4_min);

fig = figure('Name', 'Analise de Posicao Angular', 'NumberTitle', 'off');

% Subplot 1: Ângulo do Acoplador (theta3)
subplot(2, 1, 1);
plot(theta2_deg, theta3_deg, 'b-', 'LineWidth', 1.8);
hold on;
plot(45, rad2deg(x_sol_45(1)), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
grid on;
title('Ângulo do Elo Acoplador (\theta_3) vs Entrada (\theta_2)', 'FontSize', 12);
xlabel('\theta_2 (graus)');
ylabel('\theta_3 (graus)');
xlim([0, 360]);
legend('\theta_3(\theta_2)', '\theta_2 = 45°', 'Location', 'northeast');

% Subplot 2: Ângulo do Balancim (theta4)
subplot(2, 1, 2);
plot(theta2_deg, theta4_deg, 'r-', 'LineWidth', 1.8);
hold on;
plot(45, rad2deg(x_sol_45(2)), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 6);
plot(theta2_min, theta4_min, 'kv', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
plot(theta2_max, theta4_max, 'k^', 'MarkerFaceColor', 'm', 'MarkerSize', 7);
grid on;
title('Ângulo do Elo Balancim (\theta_4) vs Entrada (\theta_2)', 'FontSize', 12);
xlabel('\theta_2 (graus)');
ylabel('\theta_4 (graus)');
xlim([0, 360]);
ylim([85, 135]);

leg_min = sprintf('Mín: %.2f° (\\theta_2 = %d°)', theta4_min, theta2_min);
leg_max = sprintf('Máx: %.2f° (\\theta_2 = %d°)', theta4_max, theta2_max);
legend('\theta_4(\theta_2)', '\theta_2 = 45°', leg_min, leg_max, 'Location', 'northeast');

% Salva a imagem do gráfico gerado na pasta de assets
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end
caminho_imagem = fullfile(script_dir, 'assets', 'grafico_angulos_posicao.png');
print(fig, caminho_imagem, '-dpng', '-r300');
fprintf("Gráfico salvo em: %s\n", caminho_imagem);
