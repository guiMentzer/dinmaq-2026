% =========================================================================
% Análise de Velocidades - Mecanismo de 4 Barras 
% Disciplina: Dinâmica das Máquinas
% =========================================================================

clear; clc; close all;

% 1. Definição dos parâmetros conhecidos (comprimentos em mm)
a = 40.0;          % Comprimento do elo 2 (manivela)
b = 208.81;        % Comprimento do elo 3 (acoplador)
c = 70.0;          % Comprimento do elo 4 (balancim)
d = 200.0;         % Comprimento da base (elo 1)
omega2 = 0.1;      % Velocidade angular da manivela (rad/s)


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
theta2_deg = 0:1:180;
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
% 4. Cálculo das velocidades angulares (omega3 e omega4)
% -------------------------------------------------------------------------
omega3_rad = zeros(size(theta2_rad));
omega4_rad = zeros(size(theta2_rad));

for k = 1:length(theta2_rad)
    t3 = deg2rad(theta3_deg(k));
    t4 = deg2rad(theta4_deg(k));
    t2 = theta2_rad(k);
    
    J = [-b * sin(t3),  c * sin(t4);
          b * cos(t3), -c * cos(t4)];

    A = [ a * omega2 * sin(t2);
         -a * omega2 * cos(t2)];
    
    B = J \ A;

    omega3_rad(k) = B(1);
    omega4_rad(k) = B(2);
end

% -------------------------------------------------------------------------
% 5. Cálculo dos componentes dos vetores velocidade VA e VB
% -------------------------------------------------------------------------
% Ponto A (elo 2 em rotação pura em torno de O2):
% VA = omega2 x rA => VA_x = -a*omega2*sin(theta2), VA_y = a*omega2*cos(theta2)
VA_x = -a * omega2 * sin(theta2_rad);
VA_y =  a * omega2 * cos(theta2_rad);

% Ponto B (elo 4 em rotação pura em torno de O4):
% VB = omega4 x rO4B => VB_x = -c*omega4*sin(theta4), VB_y = c*omega4*cos(theta4)
theta4_rad_vec = deg2rad(theta4_deg);
VB_x = -c * omega4_rad .* sin(theta4_rad_vec);
VB_y =  c * omega4_rad .* cos(theta4_rad_vec);

% Ponto de referência theta2 = 45°
idx_45 = find(theta2_deg == 45, 1);

fprintf("=========================================\n");
fprintf("Velocidades para theta2 = 45°:\n");
fprintf("  omega3 = %.6f rad/s\n", omega3_rad(idx_45));
fprintf("  omega4 = %.6f rad/s\n", omega4_rad(idx_45));
fprintf("  VA: X = %7.4f mm/s | Y = %7.4f mm/s | |VA| = %.4f mm/s\n", ...
        VA_x(idx_45), VA_y(idx_45), hypot(VA_x(idx_45), VA_y(idx_45)));
fprintf("  VB: X = %7.4f mm/s | Y = %7.4f mm/s | |VB| = %.4f mm/s\n", ...
        VB_x(idx_45), VB_y(idx_45), hypot(VB_x(idx_45), VB_y(idx_45)));
fprintf("=========================================\n\n");

% Diretório para salvar as imagens
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 6. Gráfico 2.1: Hodógrafo do Ponto A (VA_x na abcissa e VA_y na ordenada)
% -------------------------------------------------------------------------
fig1 = figure(1, 'Name', 'Item 2.1 - Componentes da Velocidade V_A', 'NumberTitle', 'off');
clf(fig1);

plot(VA_x, VA_y, 'b-', 'LineWidth', 2.0);
hold on;

% Marcadores de pontos de referência ao longo do intervalo [0, pi]
idx_0   = find(theta2_deg == 0, 1);
idx_90  = find(theta2_deg == 90, 1);
idx_180 = find(theta2_deg == 180, 1);

plot(VA_x(idx_45),  VA_y(idx_45),  'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
plot(VA_x(idx_0),   VA_y(idx_0),   'gs', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
plot(VA_x(idx_90),  VA_y(idx_90),  'md', 'MarkerFaceColor', 'm', 'MarkerSize', 7);
plot(VA_x(idx_180), VA_y(idx_180), 'k^', 'MarkerFaceColor', 'k', 'MarkerSize', 7);

% Linhas dos eixos passando pela origem
line([-5.5, 3.5], [0, 0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--', 'LineWidth', 0.8);
line([0, 0], [-5.0, 5.0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--', 'LineWidth', 0.8);

grid on;
axis equal;
xlim([-4.8, 3.0]);
ylim([-4.8, 4.8]);

title('Item 2.1: Hodógrafo da Velocidade do Ponto A (0 \leq \theta_2 \leq \pi)', 'FontSize', 12);
xlabel('Componente V_{Ax} (mm/s)', 'FontSize', 11);
ylabel('Componente V_{Ay} (mm/s)', 'FontSize', 11);

leg_45 = sprintf('\\theta_2 = 45° (-2.83, 2.83) mm/s');
legend('Trajetória V_A(t)', leg_45, '\theta_2 = 0°', '\theta_2 = 90°', '\theta_2 = 180°', ...
       'Location', 'northeast');

caminho_fig1 = fullfile(assets_dir, 'grafico_2_1_VA.png');
print(fig1, caminho_fig1, '-dpng', '-r300');
fprintf("Gráfico 2.1 salvo em: %s\n", caminho_fig1);

% -------------------------------------------------------------------------
% 7. Gráfico 2.2: Hodógrafo do Ponto B (VB_x na abcissa e VB_y na ordenada)
% -------------------------------------------------------------------------
fig2 = figure(2, 'Name', 'Item 2.2 - Componentes da Velocidade V_B', 'NumberTitle', 'off');
clf(fig2);

plot(VB_x, VB_y, 'r-', 'LineWidth', 2.0);
hold on;

plot(VB_x(idx_45),  VB_y(idx_45),  'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
plot(VB_x(idx_0),   VB_y(idx_0),   'gs', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
plot(VB_x(idx_180), VB_y(idx_180), 'k^', 'MarkerFaceColor', 'k', 'MarkerSize', 7);

% Linhas dos eixos passando pela origem
line([-5.0, 3.0], [0, 0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--', 'LineWidth', 0.8);
line([0, 0], [-2.0, 2.5], 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--', 'LineWidth', 0.8);

grid on;
axis equal;
xlim([-4.8, 3.0]);
ylim([-1.8, 2.2]);

title('Item 2.2: Hodógrafo da Velocidade do Ponto B (0 \leq \theta_2 \leq \pi)', 'FontSize', 12);
xlabel('Componente V_{Bx} (mm/s)', 'FontSize', 11);
ylabel('Componente V_{By} (mm/s)', 'FontSize', 11);

leg_b_45 = sprintf('\\theta_2 = 45° (-2.62, 1.48) mm/s');
legend('Trajetória V_B(t)', leg_b_45, '\theta_2 = 0°', '\theta_2 = 180°', ...
       'Location', 'northeast');

caminho_fig2 = fullfile(assets_dir, 'grafico_2_2_VB.png');
print(fig2, caminho_fig2, '-dpng', '-r300');
fprintf("Gráfico 2.2 salvo em: %s\n", caminho_fig2);

% -------------------------------------------------------------------------
% 8. Manter janelas abertas
% -------------------------------------------------------------------------
% Quando executado via terminal, o Octave fecha todas as janelas gráficas 
% assim que o script finaliza o último comando. A instrução pause mantém as
% janelas abertas e interativas até que o usuário pressione ENTER no terminal.
fprintf('\n=========================================================================\n');
fprintf('Os gráficos 2.1 e 2.2 foram gerados e salvos com sucesso na pasta assets/!\n');
fprintf('Pressione <ENTER> no terminal para encerrar o programa e fechar os plots...\n');
fprintf('=========================================================================\n');
pause;
