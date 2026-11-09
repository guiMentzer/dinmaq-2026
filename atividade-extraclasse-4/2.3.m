% =========================================================================
% Item 2.3 - Velocidades Angulares omega3 e omega4 em função de theta2
% Disciplina: Dinâmica das Máquinas - Atividade Prática 4
% =========================================================================

clear; clc; close all;

% 1. Parâmetros geométricos conhecidos (comprimentos em mm)
a = 40.0;          % Elo 2: Manivela
b = 208.81;        % Elo 3: Acoplador
c = 70.0;          % Elo 4: Balancim
d = 200.0;         % Elo 1: Base fixa

% Parâmetro cinemático de entrada
omega2 = 0.1;      % Velocidade angular da manivela (rad/s)

% -------------------------------------------------------------------------
% 2. Resolução para a posição de referência theta2 = 45°
% -------------------------------------------------------------------------
theta2_especifico = deg2rad(45);

sistema_45 = @(x) [
    a * cos(theta2_especifico) + b * cos(x(1)) - c * cos(x(2)) - d;
    a * sin(theta2_especifico) + b * sin(x(1)) - c * sin(x(2))
];

x0 = [deg2rad(20); deg2rad(45)];
options = optimset('Display', 'off');
[x_sol_45, fval_45, info_45] = fsolve(sistema_45, x0, options);

if info_45 <= 0
    error("Falha na convergência para theta2 = 45°.");
end

theta3_45 = x_sol_45(1);
theta4_45 = x_sol_45(2);

% Velocidades angulares em 45°
J_45 = [-b * sin(theta3_45),  c * sin(theta4_45);
         b * cos(theta3_45), -c * cos(theta4_45)];
A_45 = [ a * omega2 * sin(theta2_especifico);
        -a * omega2 * cos(theta2_especifico)];
w_45 = J_45 \ A_45;
omega3_45 = w_45(1);
omega4_45 = w_45(2);

fprintf("=====================================================\n");
fprintf("Resultados para theta2 = 45°:\n");
fprintf("  theta3 = %.4f rad (%.2f°)\n", theta3_45, rad2deg(theta3_45));
fprintf("  theta4 = %.4f rad (%.2f°)\n", theta4_45, rad2deg(theta4_45));
fprintf("  omega3 = %+.6f rad/s\n", omega3_45);
fprintf("  omega4 = %+.6f rad/s\n", omega4_45);
fprintf("=====================================================\n\n");

% -------------------------------------------------------------------------
% 3. Variação de theta2 no intervalo [0, pi] (0° a 180°)
% -------------------------------------------------------------------------
theta2_deg = 0:1:180;
theta2_rad = deg2rad(theta2_deg);
N = length(theta2_deg);

theta3_rad = zeros(1, N);
theta4_rad = zeros(1, N);
omega3_rad = zeros(1, N);
omega4_rad = zeros(1, N);

x_atual = [deg2rad(10); deg2rad(60)];

for k = 1:N
    t2 = theta2_rad(k);
    
    sistema = @(x) [
        a * cos(t2) + b * cos(x(1)) - c * cos(x(2)) - d;
        a * sin(t2) + b * sin(x(1)) - c * sin(x(2))
    ];
    
    [x_sol, ~, info] = fsolve(sistema, x_atual, options);
    
    if info > 0
        t3 = x_sol(1);
        t4 = x_sol(2);
        theta3_rad(k) = t3;
        theta4_rad(k) = t4;
        x_atual = x_sol;
        
        % Matriz Jacobiana e vetor de velocidades
        J = [-b * sin(t3),  c * sin(t4);
              b * cos(t3), -c * cos(t4)];
        A = [ a * omega2 * sin(t2);
             -a * omega2 * cos(t2)];
         
        w = J \ A;
        omega3_rad(k) = w(1);
        omega4_rad(k) = w(2);
    else
        warning("Convergência falhou para theta2 = %d°", theta2_deg(k));
    end
end

% -------------------------------------------------------------------------
% 4. Geração do Gráfico do Item 2.3
% -------------------------------------------------------------------------
fig = figure(1, 'Name', 'Item 2.3 - Velocidades Angulares', 'NumberTitle', 'off');
clf(fig);

% Plotagem das curvas das velocidades angulares
plot(theta2_deg, omega3_rad, 'b-', 'LineWidth', 2.0);
hold on;
plot(theta2_deg, omega4_rad, 'r-', 'LineWidth', 2.0);

% Linha de referência no zero
line([0, 180], [0, 0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--', 'LineWidth', 0.8);

% Destaque para o ponto theta2 = 45°
plot(45, omega3_45, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
plot(45, omega4_45, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

% Linha vertical tracejada em theta2 = 45°
line([45, 45], [-0.035, 0.07], 'Color', [0.3, 0.3, 0.3], 'LineStyle', ':', 'LineWidth', 1.0);

grid on;
xlim([0, 180]);
ylim([-0.035, 0.070]);

title('Item 2.3: Velocidades Angulares \omega_3 e \omega_4 vs. \theta_2 (0 \leq \theta_2 \leq \pi)', 'FontSize', 12);
xlabel('Posição Angular da Manivela \theta_2 (graus)', 'FontSize', 11);
ylabel('Velocidade Angular (rad/s)', 'FontSize', 11);

leg_w3_45 = sprintf('\\omega_3(45°) = %+.4f rad/s', omega3_45);
leg_w4_45 = sprintf('\\omega_4(45°) = %+.4f rad/s', omega4_45);

legend('\omega_3(\theta_2) - Elo 3 (Acoplador)', ...
       '\omega_4(\theta_2) - Elo 4 (Balancim)', ...
       '\omega = 0 rad/s', ...
       leg_w3_45, ...
       leg_w4_45, ...
       'Location', 'southeast');

% -------------------------------------------------------------------------
% 5. Salvar a imagem do gráfico na pasta assets
% -------------------------------------------------------------------------
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

caminho_imagem = fullfile(assets_dir, 'grafico_2_3_velocidades_angulares.png');
print(fig, caminho_imagem, '-dpng', '-r300');
fprintf("Gráfico salvo com sucesso em: %s\n", caminho_imagem);

% -------------------------------------------------------------------------
% 6. Manter a janela aberta
% -------------------------------------------------------------------------
fprintf('\n=========================================================================\n');
fprintf('Gráfico 2.3 gerado com sucesso!\n');
fprintf('Pressione <ENTER> no terminal para encerrar o programa e fechar a janela...\n');
fprintf('=========================================================================\n');
pause;
