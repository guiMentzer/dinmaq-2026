%% Script para os diagramas de comando de válvulas (Escape e Admissão) com Polinômio 3-4-5
%% Disciplina: Dinâmica das Máquinas - Prof. Sigeo Kitatani Jr.

clear; close all; clc;
graphics_toolkit('qt');

assets_dir = fullfile(fileparts(mfilename('fullpath')), 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 1. PARÂMETROS DO COMANDO DE VÁLVULAS (Came girando de 0 a 360°)
% -------------------------------------------------------------------------
% 1 volta do came (360°) = 2 voltas do virabrequim (720°)
% Elevação máxima típica de válvula h = 10 mm (ou 25 mm normalizado/escala)
h_valvula = 10.0; % mm

% Setores angulares no eixo de comando (came):
% Válvula de Escape (Exaustão):
% - Início da abertura: theta = 45°
% - Subida: beta_sub = 55° (termina em 100°)
% - Descida: beta_desc = 55° (termina em 155°)
% - Permanece fechada (espera inferior): demais ângulos
th_ev_sub_ini  = 45;
beta_ev_sub    = 55;
th_ev_sub_fim  = th_ev_sub_ini + beta_ev_sub; % 100°
beta_ev_desc   = 55;
th_ev_desc_fim = th_ev_sub_fim + beta_ev_desc; % 155°

% Válvula de Admissão (Injeção/Intake):
% - Cruza com o escape perto do PMS do comando (pequeno cruzamento/overlap de válvulas)
% - Início da abertura: theta = 140° (overlap de 15° de 140° a 155°)
% - Subida: beta_sub = 55° (termina em 195°)
% - Descida: beta_desc = 55° (termina em 250°)
% - Permanece fechada: demais ângulos
th_in_sub_ini  = 140;
beta_in_sub    = 55;
th_in_sub_fim  = th_in_sub_ini + beta_in_sub; % 195°
beta_in_desc   = 55;
th_in_desc_fim = th_in_sub_fim + beta_in_desc; % 250°

% Discretização de 0 a 360 graus do came
theta_deg = linspace(0, 360, 721);
s_exaustao = zeros(size(theta_deg));
s_admissao = zeros(size(theta_deg));

% Polinômio 3-4-5 base: S(u) = 10*u^3 - 15*u^4 + 6*u^5
p345 = @(u) 10*u.^3 - 15*u.^4 + 6*u.^5;

for k = 1:length(theta_deg)
    th = theta_deg(k);
    
    % Válvula de Escape
    if th >= th_ev_sub_ini && th < th_ev_sub_fim
        u = (th - th_ev_sub_ini) / beta_ev_sub;
        s_exaustao(k) = h_valvula * p345(u);
    elseif th >= th_ev_sub_fim && th < th_ev_desc_fim
        u = (th - th_ev_sub_fim) / beta_ev_desc;
        s_exaustao(k) = h_valvula * (1 - p345(u));
    else
        s_exaustao(k) = 0;
    end
    
    % Válvula de Admissão
    if th >= th_in_sub_ini && th < th_in_sub_fim
        u = (th - th_in_sub_ini) / beta_in_sub;
        s_admissao(k) = h_valvula * p345(u);
    elseif th >= th_in_sub_fim && th < th_in_desc_fim
        u = (th - th_in_sub_fim) / beta_in_desc;
        s_admissao(k) = h_valvula * (1 - p345(u));
    else
        s_admissao(k) = 0;
    end
end

% -------------------------------------------------------------------------
% 2. GERAÇÃO DO GRÁFICO (300 DPI)
% -------------------------------------------------------------------------
fig = figure('visible', 'off', 'position', [100, 100, 950, 480]);
hold on; box on; grid on;

% Curva de Exaustão (Linha Contínua Vermelha/Laranja Escura Técnica)
p1 = plot(theta_deg, s_exaustao, 'Color', [0.85, 0.15, 0.1], 'LineWidth', 2.4);

% Curva de Admissão (Linha Pontilhada Azul Técnica)
p2 = plot(theta_deg, s_admissao, 'Color', [0.0, 0.35, 0.8], 'LineWidth', 2.2, 'LineStyle', '--');

% Destaque da Região de Cruzamento de Válvulas (Overlap)
area_x = [140, 155, 155, 140];
area_y = [0, 0, 3.5, 3.5];
h_patch = patch(area_x, area_y, [0.8 0.8 0.8], 'FaceAlpha', 0.35, 'EdgeColor', 'none');

% Linhas verticais auxiliares sem entrar na legenda (HandleVisibility = off)
line([th_ev_sub_ini th_ev_sub_ini], [0 h_valvula*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', ':', 'HandleVisibility', 'off');
line([th_ev_sub_fim th_ev_sub_fim], [0 h_valvula*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', ':', 'HandleVisibility', 'off');
line([th_in_sub_fim th_in_sub_fim], [0 h_valvula*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', ':', 'HandleVisibility', 'off');
line([th_in_desc_fim th_in_desc_fim], [0 h_valvula*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', ':', 'HandleVisibility', 'off');

% Anotações nos lóbulos
text(100, h_valvula + 0.6, 'Lóbulo de Escape', 'Color', [0.8, 0.1, 0.1], ...
     'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(195, h_valvula + 0.6, 'Lóbulo de Admissão', 'Color', [0.0, 0.3, 0.75], ...
     'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(147.5, 4.2, {'Cruzamento', 'de Válvulas'}, 'Color', [0.3 0.3 0.3], ...
     'FontSize', 9, 'HorizontalAlignment', 'center');

% Configurações de Eixos
xlim([0, 360]);
ylim([-0.5, 13.5]);
set(gca, 'XTick', 0:30:360, 'FontSize', 11, 'LineWidth', 1.1);
xlabel('\theta_{came} [graus do eixo de comando]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Levantamento da Válvula s(\theta) [mm]', 'FontSize', 12, 'FontWeight', 'bold');
title('Diagrama de Levantamento de Válvulas de Motor 4T: Exaustão vs. Admissão', 'FontSize', 13, 'FontWeight', 'bold');

% Legenda explícita apenas dos elementos relevantes
legend([p1, p2, h_patch], ...
       {'Válvula de Exaustão (Escape) - Polinômio 3-4-5', ...
        'Válvula de Admissão (Injeção) - Pontilhada', ...
        'Cruzamento de Válvulas (Overlap: 15° Came = 30° Motor)'}, ...
       'Location', 'northeast', 'FontSize', 10);

output_img = fullfile(assets_dir, 'grafico_valvulas_exaustao_admissao.png');
print(fig, output_img, '-dpng', '-r300');
fprintf('Gráfico gerado com sucesso em: %s\n', output_img);
