% =========================================================================
% SCRIPT: desenhar_mecanismo_completo.m
% Desenho completo do mecanismo de 6 barras da Prensa de Baru
% Destacando a linha secante que intercepta ambos os pontos B1 e B2
% =========================================================================

clear; clc; close all;

% Diretório de saída
assets_dir = fullfile(pwd, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 1. Parâmetros Cinemáticos do Mecanismo
% -------------------------------------------------------------------------
O4 = [0.0; 0.0];             % Pivô fixo do balancim
L4 = 160.0;                  % Comprimento do balancim (mm)
L5 = 160.0;                  % Comprimento da biela da prensa (mm)
delta_theta = deg2rad(25.0); % Amplitude de oscilação do balancim (25°)

% Posições extremas de alternância (toggle) do nó B
B2 = [0.0; -L4];                                      % [0, -160] mm
B1 = [-L4 * sin(delta_theta); -L4 * cos(delta_theta)]; % [-67.62, -145.01] mm

% Síntese Analítica Colinear com K = 2 (Norton Cap. 5)
M_vec = B1 - B2;
K = 2.0;
O2 = B2 + K * M_vec;         % [-135.24, -130.02] mm

% Distâncias extremas do pivô O2 até o nó B
r2 = norm(B2 - O2); % 138.52 mm = L3 + L2
r1 = norm(B1 - O2); % 69.26 mm = L3 - L2

% Comprimentos da manivela (L2) e do acoplador (L3)
L2 = (r2 - r1) / 2; % 34.63 mm
L3 = (r2 + r1) / 2; % 103.89 mm

% Posições da junta A nas duas posições extremas colineares
% Na posição 2 (estendida): A2 fica entre O2 e B2
u_O2_B2 = (B2 - O2) / r2;
A2 = O2 + L2 * u_O2_B2; % [-150.42, -84.79]

% Na posição 1 (dobrada): A1 fica no sentido oposto a B1 em relação a O2
u_O2_B1 = (B1 - O2) / r1;
A1 = O2 - L2 * u_O2_B1; % [-207.50, -51.64]

% Posições do cursor O5 (pistão da prensa)
% Na posição 2: pistão alinhado verticalmente em X = 0
y_O5_2 = -320.0; % B2(2) - L5 = -160 - 160 = -320 mm
O5_2 = [0.0; y_O5_2];

% Na posição 1: pistão em X = 0 com distância L5 até B1
% (0 - B1x)^2 + (y - B1y)^2 = L5^2 -> y = B1y - sqrt(L5^2 - B1x^2)
y_O5_1 = B1(2) - sqrt(L5^2 - B1(1)^2); % -290.02 mm
O5_1 = [0.0; y_O5_1];

% -------------------------------------------------------------------------
% 2. Linha que intercepta ambos B1 e B2 (Reta Secante Estendida)
% -------------------------------------------------------------------------
% Coeficiente angular da reta que passa por B1 e B2
m_sec = (B2(2) - B1(2)) / (B2(1) - B1(1));
% Equação: y - B2(2) = m_sec * (x - B2(1)) -> y = m_sec * x + B2(2)
% Reta secante estendida que intercepta ambos B1 e B2
x_linha = linspace(-140, 50, 120);
y_linha = m_sec * x_linha + B2(2);

% Comprimento da corda Delta B
Delta_B = norm(B2 - B1); % 69.26 mm

% -------------------------------------------------------------------------
% 3. Criação da Figura CAD Completa
% -------------------------------------------------------------------------
fig = figure('Name', 'Mecanismo Completo com Linha Secante B1-B2', ...
             'NumberTitle', 'off', 'Position', [100, 100, 1100, 850]);
hold on; grid on; axis equal;

% Linha de centro da guia vertical do pistão (X = 0)
plot([0, 0], [20, -360], 'Color', [0.5 0.5 0.5], 'LineStyle', '-.', 'LineWidth', 1.2);

% Arco circular percorrido pelo nó B (raio L4 centrado em O4)
arco_t = linspace(-pi/2 - delta_theta - 0.08, -pi/2 + 0.08, 100);
plot(L4 * cos(arco_t), L4 * sin(arco_t), 'Color', [0.7 0.7 0.7], 'LineStyle', ':', 'LineWidth', 1.5);

% Traçado da base fixa d conectando os mancais O2 e O4
plot([O2(1), O4(1)], [O2(2), O4(2)], 'k--', 'LineWidth', 1.2);

% -------------------------------------------------------------------------
% A LINHA QUE INTERCEPTA AMBOS B1 E B2 (DESTAQUE MÁXIMO)
% -------------------------------------------------------------------------
h_linha = plot(x_linha, y_linha, 'Color', [0.85, 0.40, 0.0], 'LineStyle', '-', 'LineWidth', 2.6);

% Segmento da corda entre B1 e B2 (destaque sobre a linha)
plot([B1(1), B2(1)], [B1(2), B2(2)], 'Color', [0.85, 0.15, 0.0], 'LineWidth', 4.0);

% -------------------------------------------------------------------------
% POSIÇÃO 2: Ponto Morto Inferior (PMI) / Quebra do Baru (LINHA CHEIA FORTE)
% -------------------------------------------------------------------------
% Manivela O2-A2
h_m2 = plot([O2(1), A2(1)], [O2(2), A2(2)], 'Color', [0.1 0.4 0.8], 'LineWidth', 3.2);
% Acoplador A2-B2 (colinear com a manivela, estendida)
h_ac2 = plot([A2(1), B2(1)], [A2(2), B2(2)], 'Color', [0.15 0.65 0.25], 'LineWidth', 3.2);
% Balancim O4-B2 (vertical no eixo Y)
h_bal2 = plot([O4(1), B2(1)], [O4(2), B2(2)], 'Color', [0.85 0.2 0.2], 'LineWidth', 3.5);
% Biela da prensa B2-O5_2 (vertical no eixo Y)
h_bie2 = plot([B2(1), O5_2(1)], [B2(2), O5_2(2)], 'Color', [0.6 0.2 0.7], 'LineWidth', 3.5);

% Pistão deslizante na posição PMI (Y = -320 mm)
fill([-16, 16, 16, -16], [y_O5_2-12, y_O5_2-12, y_O5_2+12, y_O5_2+12], ...
     [0.85 0.75 0.9], 'EdgeColor', [0.5 0.1 0.6], 'LineWidth', 1.8);

% -------------------------------------------------------------------------
% POSIÇÃO 1: Ponto Morto Superior (PMS) / Retorno Máximo (LINHA TRAÇO-PONTO)
% -------------------------------------------------------------------------
% Manivela O2-A1
plot([O2(1), A1(1)], [O2(2), A1(2)], 'Color', [0.3 0.6 0.9], 'LineStyle', '--', 'LineWidth', 2.0);
% Acoplador A1-B1 (colinear dobrado sobre a manivela)
plot([A1(1), B1(1)], [A1(2), B1(2)], 'Color', [0.35 0.8 0.4], 'LineStyle', '--', 'LineWidth', 2.0);
% Balancim O4-B1 (inclinado a 25°)
plot([O4(1), B1(1)], [O4(2), B1(2)], 'Color', [0.95 0.4 0.4], 'LineStyle', '--', 'LineWidth', 2.2);
% Biela da prensa B1-O5_1
plot([B1(1), O5_1(1)], [B1(2), O5_1(2)], 'Color', [0.8 0.4 0.9], 'LineStyle', '--', 'LineWidth', 2.2);

% Pistão deslizante na posição PMS (Y = -290.02 mm)
fill([-14, 14, 14, -14], [y_O5_1-10, y_O5_1-10, y_O5_1+10, y_O5_1+10], ...
     [0.9 0.9 0.95], 'EdgeColor', [0.6 0.6 0.7], 'LineWidth', 1.2, 'LineStyle', '--');

% -------------------------------------------------------------------------
% Representação da Matriz de Esmagamento e Castanha de Baru
% -------------------------------------------------------------------------
% Base da matriz de prensagem
fill([-28, 28, 28, -28], [-345, -345, -332, -332], [0.4 0.4 0.4], 'EdgeColor', 'k', 'LineWidth', 1.5);
% Castanha de Baru esquemática sendo quebrada no PMI
t_baru = linspace(0, 2*pi, 40);
fill(8*cos(t_baru), -326 + 5*sin(t_baru), [0.65 0.40 0.15], 'EdgeColor', [0.4 0.25 0.1], 'LineWidth', 1.2);
text(22, -326, 'Castanha de Baru', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.55 0.3 0.1]);

% Seta da força de esmagamento (5000 N) aplicada no pistão
quiver(0, -360, 0, 22, 0, 'Color', [0.8 0.0 0.0], 'LineWidth', 2.8, 'MaxHeadSize', 0.6);
text(8, -355, 'F_{esmagamento} = 5000 N', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.8 0.0 0.0]);

% -------------------------------------------------------------------------
% Marcadores de Juntas e Pivôs Fixos
% -------------------------------------------------------------------------
% Mancais fixos (triângulos de apoio)
plot(O4(1), O4(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
plot(O2(1), O2(2), 'ks', 'MarkerFaceColor', [0.2 0.2 0.2], 'MarkerSize', 9);

% Juntas móveis
plot(A2(1), A2(2), 'ko', 'MarkerFaceColor', [0.1 0.4 0.8], 'MarkerSize', 7);
plot(A1(1), A1(2), 'ko', 'MarkerFaceColor', [0.3 0.6 0.9], 'MarkerSize', 7);
plot(B2(1), B2(2), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 10);
plot(B1(1), B1(2), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 10);
plot(O5_2(1), O5_2(2), 'ko', 'MarkerFaceColor', [0.6 0.2 0.7], 'MarkerSize', 8);
plot(O5_1(1), O5_1(2), 'ko', 'MarkerFaceColor', [0.8 0.4 0.9], 'MarkerSize', 7);

% -------------------------------------------------------------------------
% Cotas e Rótulos Explicativos
% -------------------------------------------------------------------------
% Rótulos dos Pivôs
text(O4(1) + 8, O4(2) + 6, 'Pivô Fixo O_4 (0, 0)', 'FontSize', 11, 'FontWeight', 'bold');
text(O2(1) - 45, O2(2) + 26, {'Pivô Fixo O_2 (K=2)', '(-135.2, -130.0)'}, 'FontSize', 10, 'FontWeight', 'bold');
text(A1(1) - 15, A1(2) - 14, 'A_1', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.3 0.6 0.9]);
text(A2(1) - 8, A2(2) - 14, 'A_2', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.4 0.8]);

% Rótulos das Juntas B1 e B2
text(B2(1) + 12, B2(2) + 6, 'B_2 (0, -160) [PMI]', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.85 0.15 0.0]);
text(B1(1) - 35, B1(2) + 16, 'B_1 (-67.6, -145.0) [PMS]', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.85 0.15 0.0]);

% Rótulo da Linha que intercepta B1 e B2 na extremidade direita desimpedida
text(15, -192, {'Linha Secante B_1-B_2', 'y = -0.2217 x - 160'}, ...
     'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.85 0.40 0.0]);

% Cota da Corda Delta B
plot([-67.62, 0], [-145.01 - 18, -160 - 18], 'Color', [0.85 0.15 0.0], 'LineWidth', 1.2, 'LineStyle', ':');
text(-62, -202, sprintf('Corda \\Delta B = %.2f mm', Delta_B), ...
     'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.85 0.15 0.0]);

% Indicação do arco Delta theta = 25°
arco_ang = linspace(-pi/2 - delta_theta, -pi/2, 30);
plot(75 * cos(arco_ang), 75 * sin(arco_ang), 'Color', [0.8 0.2 0.2], 'LineWidth', 1.8);
text(18, -70, '\Delta\theta = 25.0°', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.8 0.2 0.2]);

% Cota do curso do pistão de 29.98 mm
plot([28, 28], [y_O5_2, y_O5_1], 'k-', 'LineWidth', 2.0);
plot([22, 34], [y_O5_2, y_O5_2], 'k-', 'LineWidth', 1.5);
plot([22, 34], [y_O5_1, y_O5_1], 'k-', 'LineWidth', 1.5);
text(38, (y_O5_2 + y_O5_1)/2, sprintf('Curso Linear \\Delta y\n= %.2f mm \\approx 30 mm', y_O5_1 - y_O5_2), ...
     'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');

% Identificação dos Elos
text(6, -85, 'Elo 4: Balancim L_4', 'FontSize', 9, 'Color', [0.85 0.2 0.2], 'FontWeight', 'bold');
text(6, -240, 'Elo 5: Biela Prensa L_5', 'FontSize', 9, 'Color', [0.6 0.2 0.7], 'FontWeight', 'bold');
text(-80, -305, 'Elo 6: Pistão O_5', 'FontSize', 9, 'Color', [0.5 0.1 0.6], 'FontWeight', 'bold');

% Título e Eixos
title('Mecanismo Completo da Prensa de Baru (6 Barras) com Linha Secante B_1-B_2', ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Coordenada X (mm)', 'FontSize', 11);
ylabel('Coordenada Y (mm)', 'FontSize', 11);
xlim([-240, 95]);
ylim([-375, 30]);

legend([h_linha, h_m2, h_ac2, h_bal2, h_bie2], ...
       {'Linha que intercepta B_1 e B_2 (Reta Secante da Oscilação)', ...
        sprintf('Elo 2: Manivela L_2 = %.2f mm', L2), ...
        sprintf('Elo 3: Biela L_3 = %.2f mm', L3), ...
        'Elo 4: Balancim L_4 = 160.00 mm', ...
        'Elo 5: Biela da Prensa L_5 = 160.00 mm'}, ...
       'Location', 'northwest', 'FontSize', 9);

% -------------------------------------------------------------------------
% 4. Salvar Figura em Alta Resolução (300 DPI)
% -------------------------------------------------------------------------
caminho_fig = fullfile(assets_dir, 'ex2_mecanismo_completo_linha_B1_B2.png');
print(fig, caminho_fig, '-dpng', '-r300');
fprintf('Figura salva com sucesso em: %s\n', caminho_fig);
