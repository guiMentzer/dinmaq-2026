% =========================================================================
% Abordagem 2: Análise Diferencial Espacial (Trajetória XY e Vetores Tangentes)
% Disciplina: Dinâmica das Máquinas - Atividade Prática 4
% =========================================================================

clear; clc; close all;

% 1. Parâmetros geométricos e cinemáticos
a = 40.0;          % Elo 2: Manivela (mm)
b = 208.81;        % Elo 3: Acoplador (mm)
c = 70.0;          % Elo 4: Balancim (mm)
d = 200.0;         % Elo 1: Base fixa (mm)
omega2 = 0.1;      % Velocidade angular da manivela (rad/s)

% Pivôs fixos no referencial inercial
O2 = [0; 0];
O4 = [d; 0];

% -------------------------------------------------------------------------
% 2. Resolução da posição e velocidades para 0 <= theta2 <= pi (0° a 180°)
% -------------------------------------------------------------------------
theta2_deg = 0:1:180;
theta2_rad = deg2rad(theta2_deg);
N = length(theta2_deg);

theta3_rad = zeros(1, N);
theta4_rad = zeros(1, N);
omega3_rad = zeros(1, N);
omega4_rad = zeros(1, N);

x_atual = [deg2rad(10); deg2rad(60)];
options = optimset('Display', 'off');

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
% 3. Trajetórias espaciais (coordenadas cartesianas dos pinos A e B)
% -------------------------------------------------------------------------
xA = a * cos(theta2_rad);
yA = a * sin(theta2_rad);

xB = d + c * cos(theta4_rad);
yB = c * sin(theta4_rad);

% Vetores de velocidade linear (em mm/s)
VA_x = -a * omega2 * sin(theta2_rad);
VA_y =  a * omega2 * cos(theta2_rad);

VB_x = -c * omega4_rad .* sin(theta4_rad);
VB_y =  c * omega4_rad .* cos(theta4_rad);

% Posição de referência: theta2 = 45°
idx_45 = find(theta2_deg == 45, 1);
A_45 = [xA(idx_45); yA(idx_45)];
B_45 = [xB(idx_45); yB(idx_45)];
VA_45 = [VA_x(idx_45); VA_y(idx_45)];
VB_45 = [VB_x(idx_45); VB_y(idx_45)];

% -------------------------------------------------------------------------
% 4. Configuração da amostragem e escala dos vetores tangenciais
% -------------------------------------------------------------------------
% Fator de escala visual: 1 mm/s -> 6 mm de comprimento na tela
fator_escala = 6.0; 

passo_amostra = 30;
idx_amostras = 1:passo_amostra:N;
if idx_amostras(end) ~= N
    idx_amostras = [idx_amostras, N];
end
if ~ismember(idx_45, idx_amostras)
    idx_amostras = sort([idx_amostras, idx_45]);
end
idx_regulares = idx_amostras(idx_amostras ~= idx_45);

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
% FIGURA 1: Mecanismo Completo com Vetores Tangenciais às Trajetórias
% =========================================================================
fig1 = figure(1, 'Name', 'Abordagem Espacial - Mecanismo Completo', 'NumberTitle', 'off', ...
              'Position', [100, 100, 900, 500]);
clf(fig1);

% 1. Mancais fixos e linha de base O2-O4
plot([O2(1), O4(1)], [O2(2), O4(2)], 'k--', 'LineWidth', 1.2);
hold on;
plot(O2(1), O2(2), 'ks', 'MarkerFaceColor', [0.2 0.2 0.2], 'MarkerSize', 8);
plot(O4(1), O4(2), 'ks', 'MarkerFaceColor', [0.2 0.2 0.2], 'MarkerSize', 8);
text(O2(1)-12, O2(2)-12, 'O_2(0,0)', 'FontSize', 10, 'FontWeight', 'bold');
text(O4(1)-10, O4(2)-12, 'O_4(200,0)', 'FontSize', 10, 'FontWeight', 'bold');

% 2. Configuração física dos elos em theta2 = 45°
plot([O2(1), A_45(1)], [O2(2), A_45(2)], 'Color', [0.1, 0.7, 0.2], 'LineWidth', 2.5); % Elo 2
plot([A_45(1), B_45(1)], [A_45(2), B_45(2)], 'Color', [0.3, 0.3, 0.3], 'LineWidth', 2.0); % Elo 3
plot([O4(1), B_45(1)], [O4(2), B_45(2)], 'm-', 'LineWidth', 2.5); % Elo 4

% 3. Trajetórias contínuas descritas pelos nós A e B
plot(xA, yA, 'b--', 'LineWidth', 1.3);
plot(xB, yB, 'r--', 'LineWidth', 1.3);

% 4. Vetores velocidade VA tangenciais à circunferência do nó A
h_va_reg = quiver(xA(idx_regulares), yA(idx_regulares), ...
                  fator_escala * VA_x(idx_regulares), fator_escala * VA_y(idx_regulares), 0, ...
                  'Color', [0.15, 0.45, 0.85], 'LineWidth', 1.3, 'MaxHeadSize', 0.15);

% Vetor VA em destaque em 45°
h_va_45 = quiver(A_45(1), A_45(2), fator_escala * VA_45(1), fator_escala * VA_45(2), 0, ...
                 'Color', 'b', 'LineWidth', 2.5, 'MaxHeadSize', 0.20);
plot(A_45(1), A_45(2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 7);
text(A_45(1)+6, A_45(2)-4, 'A(\theta_2=45°)', 'FontSize', 9, 'Color', 'b', 'FontWeight', 'bold');

% 5. Vetores velocidade VB tangenciais ao arco do nó B
h_vb_reg = quiver(xB(idx_regulares), yB(idx_regulares), ...
                  fator_escala * VB_x(idx_regulares), fator_escala * VB_y(idx_regulares), 0, ...
                  'Color', [0.85, 0.35, 0.1], 'LineWidth', 1.3, 'MaxHeadSize', 0.15);

% Vetor VB em destaque em 45°
h_vb_45 = quiver(B_45(1), B_45(2), fator_escala * VB_45(1), fator_escala * VB_45(2), 0, ...
                 'Color', 'r', 'LineWidth', 2.5, 'MaxHeadSize', 0.20);
plot(B_45(1), B_45(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
text(B_45(1)-5, B_45(2)+12, 'B(\theta_2=45°)', 'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');

grid on;
axis equal;
xlim([-65, 275]);
ylim([-30, 115]);

title('Mecanismo de 4 Barras: Trajetórias e Vetores Tangentes (0 \leq \theta_2 \leq \pi)', 'FontSize', 12);
xlabel('Coordenada X (mm)', 'FontSize', 11);
ylabel('Coordenada Y (mm)', 'FontSize', 11);

legend([plot(NaN,NaN,'Color',[0.1, 0.7, 0.2],'LineWidth',2.5), ...
        plot(NaN,NaN,'Color',[0.3, 0.3, 0.3],'LineWidth',2.0), ...
        plot(NaN,NaN,'m-','LineWidth',2.5), ...
        plot(NaN,NaN,'b--','LineWidth',1.3), ...
        plot(NaN,NaN,'r--','LineWidth',1.3), ...
        h_va_reg, h_vb_reg], ...
       'Elo 2 (Manivela)', ...
       'Elo 3 (Acoplador)', ...
       'Elo 4 (Balancim)', ...
       'Trajetória de A (Raio 40 mm)', ...
       'Trajetória de B (Raio 70 mm)', ...
       'V_A tangencial (\Delta\theta_2 = 30°)', ...
       'V_B tangencial (\Delta\theta_2 = 30°)', ...
       'Location', 'north', 'FontSize', 8);

caminho_fig1 = fullfile(assets_dir, 'grafico_2_espacial_mecanismo.png');
print(fig1, caminho_fig1, '-dpng', '-r300');
fprintf("Figura 1 (Mecanismo completo) salva em: %s\n", caminho_fig1);

% =========================================================================
% FIGURA 2: Detalhes das Trajetórias e Tangência de VA e VB
% =========================================================================
fig2 = figure(2, 'Name', 'Abordagem Espacial - Detalhes dos Nós A e B', 'NumberTitle', 'off', ...
              'Position', [100, 100, 950, 450]);
clf(fig2);

% Subplot 1: Detalhe do Nó A
subplot(1, 2, 1);
plot(xA, yA, 'b--', 'LineWidth', 1.5);
hold on;
plot(O2(1), O2(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot([O2(1), A_45(1)], [O2(2), A_45(2)], 'Color', [0.1 0.7 0.2], 'LineWidth', 2.0);

h_a1 = quiver(xA(idx_regulares), yA(idx_regulares), ...
              fator_escala * VA_x(idx_regulares), fator_escala * VA_y(idx_regulares), 0, ...
              'Color', [0.15, 0.45, 0.85], 'LineWidth', 1.4, 'MaxHeadSize', 0.15);
h_a2 = quiver(A_45(1), A_45(2), fator_escala * VA_45(1), fator_escala * VA_45(2), 0, ...
              'Color', 'b', 'LineWidth', 2.5, 'MaxHeadSize', 0.20);
plot(A_45(1), A_45(2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 7);

grid on;
axis equal;
xlim([-100, 100]);
ylim([-15, 150]);
title('Nó A: V_A Tangente à Circunferência (Raio a = 40 mm)', 'FontSize', 10);
xlabel('X (mm)', 'FontSize', 10);
ylabel('Y (mm)', 'FontSize', 10);
legend([plot(NaN,NaN,'b--','LineWidth',1.5), ...
        plot(NaN,NaN,'ks','MarkerFaceColor','k','MarkerSize',6), ...
        plot(NaN,NaN,'Color',[0.1 0.7 0.2],'LineWidth',2.0), ...
        h_a1, h_a2], ...
       'Trajetória de A', 'Mancal O_2(0,0)', 'Elo 2 (\theta_2 = 45°)', ...
       'V_A tangencial (\Delta\theta_2 = 30°)', 'V_A em 45°', ...
       'Location', 'northwest', 'FontSize', 7.5);

% Subplot 2: Detalhe do Nó B
subplot(1, 2, 2);
plot(xB, yB, 'r--', 'LineWidth', 1.5);
hold on;
plot(O4(1), O4(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot([O4(1), B_45(1)], [O4(2), B_45(2)], 'm-', 'LineWidth', 2.0);

h_b1 = quiver(xB(idx_regulares), yB(idx_regulares), ...
              fator_escala * VB_x(idx_regulares), fator_escala * VB_y(idx_regulares), 0, ...
              'Color', [0.85, 0.35, 0.1], 'LineWidth', 1.4, 'MaxHeadSize', 0.15);
h_b2 = quiver(B_45(1), B_45(2), fator_escala * VB_45(1), fator_escala * VB_45(2), 0, ...
              'Color', 'r', 'LineWidth', 2.5, 'MaxHeadSize', 0.20);
plot(B_45(1), B_45(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);

grid on;
axis equal;
xlim([155, 255]);
ylim([-10, 85]);
title('Nó B: V_B Tangente ao Arco de Oscilação (Raio c = 70 mm)', 'FontSize', 10);
xlabel('X (mm)', 'FontSize', 10);
ylabel('Y (mm)', 'FontSize', 10);
legend([plot(NaN,NaN,'r--','LineWidth',1.5), ...
        plot(NaN,NaN,'ks','MarkerFaceColor','k','MarkerSize',6), ...
        plot(NaN,NaN,'m-','LineWidth',2.0), ...
        h_b1, h_b2], ...
       'Trajetória de B', 'Mancal O_4(200,0)', 'Elo 4 (\theta_2 = 45°)', ...
       'V_B tangencial (\Delta\theta_2 = 30°)', 'V_B em 45°', ...
       'Location', 'southwest', 'FontSize', 7.5);

caminho_fig2 = fullfile(assets_dir, 'grafico_2_espacial_detalhes.png');
print(fig2, caminho_fig2, '-dpng', '-r300');
fprintf("Figura 2 (Detalhes dos nós) salva em: %s\n", caminho_fig2);

% -------------------------------------------------------------------------
% 6. Manter as janelas abertas
% -------------------------------------------------------------------------
fprintf('\n=========================================================================\n');
fprintf('Gráficos espaciais gerados com sucesso!\n');
fprintf('Pressione <ENTER> no terminal para encerrar o programa e fechar as janelas...\n');
fprintf('=========================================================================\n');
pause;
