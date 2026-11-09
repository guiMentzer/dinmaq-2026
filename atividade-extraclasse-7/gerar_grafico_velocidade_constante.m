%% Script para plotar diagramas SVAJ com velocidade constante (infringindo a Lei Fundamental)
%% Réplica fiel da Figura 8.12 do livro Robert L. Norton (2010)

clear; close all; clc;
graphics_toolkit('qt');

assets_dir = fullfile(fileparts(mfilename('fullpath')), 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% Função para desenhar flechas proporcionais nítidas
function desenhar_seta(x0, y0, dx, dy, tam_x, tam_y, cor, lw)
    line([x0, x0 + dx], [y0, y0 + dy], 'Color', cor, 'LineWidth', lw);
    px = x0 + dx;
    py = y0 + dy;
    
    if dx > 0 && dy == 0 % Horizontal para a direita
        patch([px, px - tam_x, px - tam_x], [py, py + tam_y, py - tam_y], cor, 'EdgeColor', cor);
    elseif dx == 0 && dy > 0 % Vertical para cima
        patch([px, px - tam_x, px + tam_x], [py, py - tam_y, py - tam_y], cor, 'EdgeColor', cor);
    elseif dx == 0 && dy < 0 % Vertical para baixo
        patch([px, px - tam_x, px + tam_x], [py, py + tam_y, py + tam_y], cor, 'EdgeColor', cor);
    end
end

fig = figure('visible', 'off', 'position', [100, 100, 950, 1080]);

h = 1;
cor_linha = [0.15, 0.15, 0.15];
cor_guia  = [0.65, 0.65, 0.65];
lw_linha  = 1.8;
lw_guia   = 0.9;

% =========================================================================
% 1. DESLOCAMENTO (s)
% =========================================================================
ax1 = subplot(4, 1, 1);
hold on; box off;

plot([0, 90, 180, 270, 360], [0, 0, h, h, 0], 'Color', cor_linha, 'LineWidth', lw_linha);

for th = [90, 180, 270, 360]
    line([th, th], [-0.1, 1.25], 'Color', cor_guia, 'LineStyle', ':', 'LineWidth', lw_guia);
end
line([0, 370], [h, h], 'Color', cor_guia, 'LineStyle', ':', 'LineWidth', lw_guia);

text(45, 0.45*h, {'Espera', 'inferior'}, 'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.35 0.35 0.35]);
text(135, 1.12*h, 'Subida', 'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.35 0.35 0.35]);
text(225, 1.15*h, {'Espera', 'superior'}, 'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.35 0.35 0.35]);
text(315, 1.12*h, 'Descida', 'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.35 0.35 0.35]);

text(-40, 0.5*h, '(a)', 'FontSize', 13, 'Color', [0.3 0.3 0.3]);

desenhar_seta(0, 0, 385, 0, 5, 0.05, 'k', 1.2);
desenhar_seta(0, 0, 0, 1.35, 4, 0.07, 'k', 1.2);

text(392, 0, '\theta graus', 'FontSize', 11, 'VerticalAlignment', 'middle');
text(-8, 1.35, 's', 'FontSize', 13, 'FontAngle', 'italic', 'HorizontalAlignment', 'right');
text(-8, h, 'h', 'FontSize', 11, 'HorizontalAlignment', 'right');
text(-8, 0, '0', 'FontSize', 11, 'HorizontalAlignment', 'right');

xlim([-15, 435]);
ylim([-0.2, 1.45]);
axis off;

% =========================================================================
% 2. VELOCIDADE (v)
% =========================================================================
ax2 = subplot(4, 1, 2);
hold on; box off;

v_val = 0.65;

desenhar_seta(0, 0, 385, 0, 5, 0.06, 'k', 1.2);
desenhar_seta(0, -0.9, 0, 2.05, 4, 0.08, 'k', 1.2);

line([0, 90], [0, 0], 'Color', cor_linha, 'LineWidth', lw_linha);
line([90, 90], [0, v_val], 'Color', cor_linha, 'LineWidth', 1.2, 'LineStyle', '-');
line([90, 180], [v_val, v_val], 'Color', cor_linha, 'LineWidth', lw_linha);
line([180, 180], [v_val, 0], 'Color', cor_linha, 'LineWidth', 1.2, 'LineStyle', '-');
line([180, 270], [0, 0], 'Color', cor_linha, 'LineWidth', lw_linha);
line([270, 270], [0, -v_val], 'Color', cor_linha, 'LineWidth', 1.2, 'LineStyle', '-');
line([270, 360], [-v_val, -v_val], 'Color', cor_linha, 'LineWidth', lw_linha);
line([360, 360], [-v_val, 0], 'Color', cor_linha, 'LineWidth', 1.2, 'LineStyle', '-');

for th = [90, 180, 270, 360]
    line([th, th], [-0.95, 1.05], 'Color', cor_guia, 'LineStyle', ':', 'LineWidth', lw_guia);
end

text(-40, 0, '(b)', 'FontSize', 13, 'Color', [0.3 0.3 0.3]);
text(392, 0, '\theta graus', 'FontSize', 11, 'VerticalAlignment', 'middle');
text(-8, 1.15, 'v', 'FontSize', 13, 'FontAngle', 'italic', 'HorizontalAlignment', 'right');
text(-8, 0, '0', 'FontSize', 11, 'HorizontalAlignment', 'right');

xlim([-15, 435]);
ylim([-1.1, 1.25]);
axis off;

% =========================================================================
% 3. ACELERAÇÃO (a) - IMPULSOS DE DIRAC
% =========================================================================
ax3 = subplot(4, 1, 3);
hold on; box off;

desenhar_seta(0, 0, 385, 0, 5, 0.06, 'k', 1.2);
desenhar_seta(0, -0.9, 0, 2.05, 4, 0.08, 'k', 1.2);

line([0, 360], [0, 0], 'Color', cor_linha, 'LineWidth', lw_linha);

for th = [90, 180, 270, 360]
    line([th, th], [-0.95, 1.05], 'Color', cor_guia, 'LineStyle', ':', 'LineWidth', lw_guia);
end

% Flechas de impulso de aceleração (posicionando o símbolo \infty exatamente ao lado da ponta)
% 90°: +inf
desenhar_seta(90, 0, 0, 0.75, 3.5, 0.07, 'k', 1.3);
text(82, 0.72, '\infty', 'FontSize', 13, 'Color', [0.35 0.35 0.35], 'HorizontalAlignment', 'right');

% 180°: -inf
desenhar_seta(180, 0, 0, -0.75, 3.5, 0.07, 'k', 1.3);
text(172, -0.72, '\infty', 'FontSize', 13, 'Color', [0.35 0.35 0.35], 'HorizontalAlignment', 'right');

% 270°: -inf
desenhar_seta(270, 0, 0, -0.75, 3.5, 0.07, 'k', 1.3);
text(262, -0.72, '\infty', 'FontSize', 13, 'Color', [0.35 0.35 0.35], 'HorizontalAlignment', 'right');

% 360°: +inf
desenhar_seta(360, 0, 0, 0.75, 3.5, 0.07, 'k', 1.3);
text(352, 0.72, '\infty', 'FontSize', 13, 'Color', [0.35 0.35 0.35], 'HorizontalAlignment', 'right');

text(-40, 0, '(c)', 'FontSize', 13, 'Color', [0.3 0.3 0.3]);
text(392, 0, '\theta graus', 'FontSize', 11, 'VerticalAlignment', 'middle');
text(-8, 1.15, 'a', 'FontSize', 13, 'FontAngle', 'italic', 'HorizontalAlignment', 'right');
text(-8, 0, '0', 'FontSize', 11, 'HorizontalAlignment', 'right');

xlim([-15, 435]);
ylim([-1.1, 1.25]);
axis off;

% =========================================================================
% 4. JERK (j) - DOUBLETS DE DIRAC
% =========================================================================
ax4 = subplot(4, 1, 4);
hold on; box off;

desenhar_seta(0, 0, 385, 0, 5, 0.06, 'k', 1.2);
desenhar_seta(0, -0.9, 0, 2.05, 4, 0.08, 'k', 1.2);

line([0, 360], [0, 0], 'Color', cor_linha, 'LineWidth', lw_linha);

for th = [90, 180, 270, 360]
    line([th, th], [-0.95, 1.05], 'Color', cor_guia, 'LineStyle', ':', 'LineWidth', lw_guia);
    
    % Flechas duplas
    desenhar_seta(th, 0, 0, 0.75, 3.5, 0.07, 'k', 1.3);
    desenhar_seta(th, 0, 0, -0.75, 3.5, 0.07, 'k', 1.3);
    text(th - 8, 0.72, '\infty', 'FontSize', 13, 'Color', [0.35 0.35 0.35], 'HorizontalAlignment', 'right');
    text(th - 8, -0.72, '\infty', 'FontSize', 13, 'Color', [0.35 0.35 0.35], 'HorizontalAlignment', 'right');
end

text(-40, 0, '(d)', 'FontSize', 13, 'Color', [0.3 0.3 0.3]);
text(-8, 1.15, 'j', 'FontSize', 13, 'FontAngle', 'italic', 'HorizontalAlignment', 'right');

% Rótulos no eixo das abscissas bem ajustados
text(0, -0.22, '0', 'FontSize', 11, 'HorizontalAlignment', 'right');
text(90, -0.22, '90', 'FontSize', 11, 'HorizontalAlignment', 'center');
text(180, -0.22, '180', 'FontSize', 11, 'HorizontalAlignment', 'center');
text(270, -0.22, '270', 'FontSize', 11, 'HorizontalAlignment', 'center');
text(360, -0.22, '360', 'FontSize', 11, 'HorizontalAlignment', 'center');

xlim([-15, 435]);
ylim([-1.1, 1.25]);
axis off;

% Salvar figura em alta resolução 300 DPI
output_img = fullfile(assets_dir, 'grafico_velocidade_constante_svaj.png');
print(fig, output_img, '-dpng', '-r300');
fprintf('Gráfico gerado com sucesso em: %s\n', output_img);
