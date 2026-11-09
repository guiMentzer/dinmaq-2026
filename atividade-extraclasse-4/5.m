% =========================================================================
% Questão 5 - Velocidade do Centro de Massa (Ponto G) do Elo Acoplador
% Disciplina: Dinâmica das Máquinas - Atividade Prática 4
% =========================================================================

clear; clc; close all;

% 1. Parâmetros geométricos do mecanismo (em mm)
a = 40.0;          % Elo 2: Manivela
b = 208.81;        % Elo 3: Acoplador
c = 70.0;          % Elo 4: Balancim
d = 200.0;         % Elo 1: Base fixa
omega2 = 0.1;      % Velocidade angular da manivela (rad/s)

% Parâmetros do elo intermediário expandido (Triângulo ABP)
p = b;                     % |R_PA| = b = 208.81 mm
delta3 = deg2rad(20);      % Ângulo delta3 = 20 graus

% -------------------------------------------------------------------------
% 2. Carregamento do pacote de geometria e configuração de polygonCentroid
% -------------------------------------------------------------------------
try
    pkg load geometry;
catch
    % Pacote geometry pode não estar instalado no sistema
end

% Função de centróide compatível: utiliza polygonCentroid se existir, ou
% a média das coordenadas dos vértices (baricentro geométrico do triângulo)
if exist('polygonCentroid', 'file') || exist('polygonCentroid', 'builtin')
    obter_centroide = @(pts) polygonCentroid(pts);
else
    obter_centroide = @(pts) mean(pts, 1);
end

% -------------------------------------------------------------------------
% 3. Volta completa da manivela: 0 <= theta2 <= 360° (Delta theta2 = 1°)
% -------------------------------------------------------------------------
theta2_deg = 0:1:360;
theta2_rad = deg2rad(theta2_deg);
N = length(theta2_deg);

theta3_rad = zeros(1, N);
theta4_rad = zeros(1, N);
omega3_rad = zeros(1, N);
omega4_rad = zeros(1, N);

xG = zeros(1, N);
yG = zeros(1, N);
VG_x = zeros(1, N);
VG_y = zeros(1, N);
VG_mod = zeros(1, N);

x_atual = [deg2rad(10); deg2rad(60)];
options = optimset('Display', 'off');

for k = 1:N
    t2 = theta2_rad(k);
    
    % Equações de fechamento do circuito
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
        
        % Velocidades angulares
        J = [-b * sin(t3),  c * sin(t4);
              b * cos(t3), -c * cos(t4)];
        A = [ a * omega2 * sin(t2);
             -a * omega2 * cos(t2)];
        w = J \ A;
        w3 = w(1);
        w4 = w(2);
        omega3_rad(k) = w3;
        omega4_rad(k) = w4;
        
        % Coordenadas dos vértices do triângulo acoplador ABP
        rA = [a * cos(t2), a * sin(t2)];
        rB = [d + c * cos(t4), c * sin(t4)];
        rP = rA + p * [cos(t3 + delta3), sin(t3 + delta3)];
        
        % Centróide do triângulo via polygonCentroid
        vertices_triangulo = [rA; rB; rP];
        G = obter_centroide(vertices_triangulo);
        xG(k) = G(1);
        yG(k) = G(2);
        
        % Velocidade do centróide G:
        % VG = VA + omega3 x r_GA
        VA = [-a * omega2 * sin(t2); a * omega2 * cos(t2)];
        rGA = [G(1) - rA(1); G(2) - rA(2)];
        VG = VA + w3 * [-rGA(2); rGA(1)];
        
        VG_x(k) = VG(1);
        VG_y(k) = VG(2);
        VG_mod(k) = hypot(VG(1), VG(2));
    else
        warning("Convergência falhou para theta2 = %d°", theta2_deg(k));
    end
end

% -------------------------------------------------------------------------
% 4. Resolução do Item c: Posição onde a velocidade é máxima
% -------------------------------------------------------------------------
[max_VG, idx_max] = max(VG_mod);
theta2_max_deg = theta2_deg(idx_max);
theta2_max_rad = theta2_rad(idx_max);

fprintf("=========================================================================\n");
fprintf("RESULTADOS DA QUESTÃO 5 (CENTRO DE MASSA DO ELO 3 - PONTO G):\n");
fprintf("-------------------------------------------------------------------------\n");
fprintf("Velocidade MÁXIMA do Ponto G:\n");
fprintf("  |VG|_max     = %.4f mm/s\n", max_VG);
fprintf("  Posição theta2 = %d° (%.4f rad)\n", theta2_max_deg, theta2_max_rad);
fprintf("  Componentes  = VG_x = %+.4f mm/s | VG_y = %+.4f mm/s\n", VG_x(idx_max), VG_y(idx_max));
fprintf("  Coordenadas G= X_G = %7.2f mm | Y_G = %7.2f mm\n", xG(idx_max), yG(idx_max));
fprintf("-------------------------------------------------------------------------\n");
fprintf("Posição de referência theta2 = 45°:\n");
idx_45 = find(theta2_deg == 45, 1);
fprintf("  |VG|(45°)    = %.4f mm/s\n", VG_mod(idx_45));
fprintf("  Componentes  = VG_x = %+.4f mm/s | VG_y = %+.4f mm/s\n", VG_x(idx_45), VG_y(idx_45));
fprintf("  Coordenadas G= X_G = %7.2f mm | Y_G = %7.2f mm\n", xG(idx_45), yG(idx_45));
fprintf("=========================================================================\n\n");

% Diretório para salvar imagens
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% =========================================================================
% 5. Item a: Gráfico do módulo da velocidade |VG| vs theta2
% =========================================================================
fig_a = figure(1, 'Name', 'Item 5.a - Modulo da Velocidade VG vs theta2', 'NumberTitle', 'off', ...
               'Position', [100, 100, 800, 500]);
clf(fig_a);

plot(theta2_deg, VG_mod, 'b-', 'LineWidth', 2.0);
hold on;
plot(theta2_max_deg, max_VG, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
plot(45, VG_mod(idx_45), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8);

line([theta2_max_deg, theta2_max_deg], [0, max_VG], 'Color', 'r', 'LineStyle', ':', 'LineWidth', 1.0);
line([45, 45], [0, VG_mod(idx_45)], 'Color', 'm', 'LineStyle', ':', 'LineWidth', 1.0);

grid on;
xlim([0, 360]);
ylim([1.0, 5.0]);

title('Item 5.a: Módulo da Velocidade do Centro de Massa G (|V_G|) vs. \theta_2', 'FontSize', 12);
xlabel('Posição Angular da Manivela \theta_2 (graus)', 'FontSize', 11);
ylabel('|V_G| (mm/s)', 'FontSize', 11);

leg_max = sprintf('Máximo: |V_G| = %.4f mm/s em \\theta_2 = %d°', max_VG, theta2_max_deg);
leg_45  = sprintf('Referência: |V_G| = %.4f mm/s em \\theta_2 = 45°', VG_mod(idx_45));
legend('|V_G|(\theta_2)', leg_max, leg_45, 'Location', 'north');

caminho_fig_a = fullfile(assets_dir, 'grafico_5_a_modulo_VG.png');
print(fig_a, caminho_fig_a, '-dpng', '-r300');
fprintf("Gráfico 5.a salvo em: %s\n", caminho_fig_a);

% =========================================================================
% 6. Item b: Hodógrafo de VG (VG_x na abscissa e VG_y na ordenada)
% =========================================================================
fig_b = figure(2, 'Name', 'Item 5.b - Hodografo da Velocidade VG', 'NumberTitle', 'off', ...
               'Position', [100, 100, 800, 550]);
clf(fig_b);

plot(VG_x, VG_y, 'b-', 'LineWidth', 2.0);
hold on;

plot(VG_x(idx_max), VG_y(idx_max), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
plot(VG_x(idx_45),  VG_y(idx_45),  'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8);
plot(VG_x(1),       VG_y(1),       'gs', 'MarkerFaceColor', 'g', 'MarkerSize', 7);

% Linhas dos eixos passando pela origem
line([-5.5, 5.5], [0, 0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--', 'LineWidth', 0.8);
line([0, 0], [-3.0, 3.0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--', 'LineWidth', 0.8);

grid on;
axis equal;
xlim([-5.0, 5.5]);
ylim([-2.8, 2.8]);

title('Item 5.b: Hodógrafo da Velocidade do Centro de Massa G (0 \leq \theta_2 \leq 360°)', 'FontSize', 12);
xlabel('Componente V_{Gx} (mm/s)', 'FontSize', 11);
ylabel('Componente V_{Gy} (mm/s)', 'FontSize', 11);

leg_hb_max = sprintf('V_{G,max} (\\theta_2 = %d°): (%+.2f, %+.2f) mm/s', theta2_max_deg, VG_x(idx_max), VG_y(idx_max));
leg_hb_45  = sprintf('V_G(\\theta_2 = 45°): (%+.2f, %+.2f) mm/s', VG_x(idx_45), VG_y(idx_45));
legend('Trajetória V_G(t)', leg_hb_max, leg_hb_45, '\theta_2 = 0° / 360°', 'Location', 'northeast');

caminho_fig_b = fullfile(assets_dir, 'grafico_5_b_hodografo_VG.png');
print(fig_b, caminho_fig_b, '-dpng', '-r300');
fprintf("Gráfico 5.b salvo em: %s\n", caminho_fig_b);

% =========================================================================
% 7. Item d: Trajetória do ponto G com Quiver a cada 30 graus
% =========================================================================
fig_d = figure(3, 'Name', 'Item 5.d - Trajetoria de G com Quiver', 'NumberTitle', 'off', ...
               'Position', [100, 100, 850, 550]);
clf(fig_d);

% Trajetória contínua com incremento de 1 grau
plot(xG, yG, 'Color', [0.2, 0.4, 0.8], 'LineWidth', 2.0);
hold on;

% Amostragem a cada 30 graus para os vetores quiver
idx_quiver = 1:30:360;
escala_quiver = 4.0; % Fator de escala: 1 mm/s -> 4 mm de vetor visual

h_quiver = quiver(xG(idx_quiver), yG(idx_quiver), ...
                  escala_quiver * VG_x(idx_quiver), escala_quiver * VG_y(idx_quiver), 0, ...
                  'Color', [0.85, 0.35, 0.1], 'LineWidth', 1.4, 'MaxHeadSize', 0.15);

% Destaque no ponto de velocidade máxima
h_max_vec = quiver(xG(idx_max), yG(idx_max), ...
                   escala_quiver * VG_x(idx_max), escala_quiver * VG_y(idx_max), 0, ...
                   'Color', 'r', 'LineWidth', 2.5, 'MaxHeadSize', 0.20);
plot(xG(idx_max), yG(idx_max), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

% Destaque em theta2 = 45°
plot(xG(idx_45), yG(idx_45), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 7);

% Ponto inicial
plot(xG(1), yG(1), 'gs', 'MarkerFaceColor', 'g', 'MarkerSize', 7);

grid on;
axis equal;
xlim([70, 185]);
ylim([40, 95]);

title('Item 5.d: Trajetória do Ponto G com Vetores Velocidade Tangenciais (\Delta\theta_2 = 30°)', 'FontSize', 12);
xlabel('Coordenada X_G (mm)', 'FontSize', 11);
ylabel('Coordenada Y_G (mm)', 'FontSize', 11);

leg_d_max = sprintf('V_{G,max} em \\theta_2 = %d° (|V_G| = %.2f mm/s)', theta2_max_deg, max_VG);
legend([plot(NaN,NaN,'Color',[0.2, 0.4, 0.8],'LineWidth',2.0), ...
        h_quiver, h_max_vec, ...
        plot(NaN,NaN,'mo','MarkerFaceColor','m','MarkerSize',7), ...
        plot(NaN,NaN,'gs','MarkerFaceColor','g','MarkerSize',7)], ...
       'Trajetória de G (\Delta\theta_2 = 1°)', ...
       sprintf('Vetores V_G (\\Delta\\theta_2 = 30°, escala = %.0fx)', escala_quiver), ...
       leg_d_max, ...
       '\theta_2 = 45°', ...
       '\theta_2 = 0° / 360°', ...
       'Location', 'north');

caminho_fig_d = fullfile(assets_dir, 'grafico_5_d_trajetoria_quiver_G.png');
print(fig_d, caminho_fig_d, '-dpng', '-r300');
fprintf("Gráfico 5.d salvo em: %s\n", caminho_fig_d);

% -------------------------------------------------------------------------
% 8. Manter as janelas abertas
% -------------------------------------------------------------------------
fprintf('\n=========================================================================\n');
fprintf('Todos os gráficos da Questão 5 foram gerados e salvos com sucesso!\n');
fprintf('Pressione <ENTER> no terminal para encerrar o programa e fechar as janelas...\n');
fprintf('=========================================================================\n');
pause;
