%% gerar_capa_e_diagramas.m
%% Projeto de Mecanismos Came-Seguidor - Curvas EVAP (SVAJ) e Perfil Polar da Came
%% Dinâmica das Máquinas - UFG - Prof. Sigeo Kitatani Jr.

clear; clc; close all;
graphics_toolkit('qt');

% Diretório de saída
assets_dir = fullfile(fileparts(mfilename('fullpath')), 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

%% 1. Parâmetros de Projeto
h  = 25;           % Elevação máxima do seguidor [mm]
Rb = 50;           % Raio do círculo de base escolhido [mm]
n  = 1.0;          % Velocidade de rotação [rev/s]
omega = 2 * pi * n; % Velocidade angular [rad/s] (aprox. 6.2832 rad/s)

% Definição dos intervalos angulares (em graus e radianos)
% Intervalo 1: Subida (0° a 90°)
% Intervalo 2: Espera alta (90° a 180°)
% Intervalo 3: Descida (180° a 270°)
% Intervalo 4: Espera baixa (270° a 360°)
beta1 = 90 * pi / 180;
beta2 = 90 * pi / 180;
beta3 = 90 * pi / 180;
beta4 = 90 * pi / 180;

% Vetor de ângulos de grau em grau (360 pontos exatos de 0° a 359°, mais o fechamento em 360°)
theta_deg = 0:1:360;
N = length(theta_deg);
theta_rad = theta_deg * pi / 180;

% Pré-alocação dos vetores de movimento (EVAP / SVAJ)
s = zeros(1, N); % Espaço / Deslocamento [mm]
v = zeros(1, N); % Velocidade [mm/s]
a = zeros(1, N); % Aceleração [mm/s^2]
j = zeros(1, N); % Pulso / Jerk [mm/s^3]

%% 2. Equacionamento Polinomial 3-4-5
for k = 1:N
    th = theta_deg(k);
    
    if th >= 0 && th < 90
        % --- 1) SUBIDA (0° a 90°) ---
        u = (th - 0) / 90; % Parâmetro normalizado [0, 1]
        
        s(k) = h * (10*u^3 - 15*u^4 + 6*u^5);
        v(k) = (h * omega / beta1) * (30*u^2 - 60*u^3 + 30*u^4);
        a(k) = (h * omega^2 / (beta1^2)) * (60*u - 180*u^2 + 120*u^3);
        j(k) = (h * omega^3 / (beta1^3)) * (60 - 360*u + 360*u^2);
        
    elseif th >= 90 && th < 180
        % --- 2) ESPERA SUPERIOR (90° a 180°) ---
        s(k) = h;
        v(k) = 0;
        a(k) = 0;
        j(k) = 0;
        
    elseif th >= 180 && th < 270
        % --- 3) DESCIDA (180° a 270°) ---
        u = (th - 180) / 90; % Parâmetro normalizado [0, 1]
        
        s(k) = h * (1 - (10*u^3 - 15*u^4 + 6*u^5));
        v(k) = -(h * omega / beta3) * (30*u^2 - 60*u^3 + 30*u^4);
        a(k) = -(h * omega^2 / (beta3^2)) * (60*u - 180*u^2 + 120*u^3);
        j(k) = -(h * omega^3 / (beta3^3)) * (60 - 360*u + 360*u^2);
        
    else
        % --- 4) ESPERA INFERIOR (270° a 360°) ---
        s(k) = 0;
        v(k) = 0;
        a(k) = 0;
        j(k) = 0;
    end
end

% Ajuste no ponto 360° para coincidir com 0°
s(end) = s(1);
v(end) = v(1);
a(end) = a(1);
j(end) = j(1);

%% 3. Geometria Polar da Came (A Técnica Circular: r = Rb + s)
% Raio em função do ângulo
r = Rb + s;

% Coordenadas cartesianas dos 360 pontos
xc = r .* cos(theta_rad);
yc = r .* sin(theta_rad);

% Coordenadas do Círculo Base
xb = Rb * cos(theta_rad);
yb = Rb * sin(theta_rad);

% Cores temáticas (Modern Palette)
c_subida  = [0.12, 0.53, 0.90]; % Azul vibrante
c_espera1 = [0.95, 0.60, 0.07]; % Âmbar / Laranja
c_descida = [0.85, 0.22, 0.22]; % Vermelho / Carmim
c_espera2 = [0.20, 0.68, 0.38]; % Verde esmeralda
c_base    = [0.55, 0.55, 0.58]; % Cinza técnico
c_came    = [0.10, 0.12, 0.18]; % Azul marinho escuro / Grafite

%% -------------------------------------------------------------
%% FIGURA 1: Diagramas EVAP (SVAJ) - 4 Subplots Técnicos
%% -------------------------------------------------------------
fig1 = figure('visible', 'off', 'position', [100, 100, 1100, 900]);

% 1.1 Espaço / Deslocamento s(θ)
subplot(4, 1, 1);
plot(theta_deg, s, 'Color', c_subida, 'LineWidth', 2.5);
hold on;
grid on; grid minor;
xlim([0 360]);
set(gca, 'XTick', 0:45:360, 'FontSize', 10);
ylabel('s [mm]', 'FontSize', 11, 'FontWeight', 'bold');
title('Diagramas Cinemáticos de Movimento (EVAP / SVAJ) - Polinômio 3-4-5 (h = 25 mm, \omega = 2\pi rad/s)', ...
      'FontSize', 12, 'FontWeight', 'bold');
% Linhas divisórias das regiões
for div = [90 180 270]
    line([div div], ylim, 'Color', [0.7 0.7 0.7], 'LineStyle', '--', 'LineWidth', 1);
end
text(45, h*0.5, 'Subida (90°)', 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', c_subida, 'FontWeight', 'bold');
text(135, h*0.9, 'Espera Alta (90°)', 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', c_espera1, 'FontWeight', 'bold');
text(225, h*0.5, 'Descida (90°)', 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', c_descida, 'FontWeight', 'bold');
text(315, h*0.2, 'Espera Baixa (90°)', 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', c_espera2, 'FontWeight', 'bold');

% 1.2 Velocidade v(θ)
subplot(4, 1, 2);
plot(theta_deg, v, 'Color', [0.55, 0.20, 0.80], 'LineWidth', 2.2);
hold on; grid on; grid minor;
line([0 360], [0 0], 'Color', 'k', 'LineWidth', 0.8);
for div = [90 180 270]
    line([div div], ylim, 'Color', [0.7 0.7 0.7], 'LineStyle', '--', 'LineWidth', 1);
end
xlim([0 360]);
set(gca, 'XTick', 0:45:360, 'FontSize', 10);
ylabel('v [mm/s]', 'FontSize', 11, 'FontWeight', 'bold');

% 1.3 Aceleração a(θ)
subplot(4, 1, 3);
plot(theta_deg, a / 1000, 'Color', [0.85, 0.22, 0.22], 'LineWidth', 2.2); % em m/s^2
hold on; grid on; grid minor;
line([0 360], [0 0], 'Color', 'k', 'LineWidth', 0.8);
for div = [90 180 270]
    line([div div], ylim, 'Color', [0.7 0.7 0.7], 'LineStyle', '--', 'LineWidth', 1);
end
xlim([0 360]);
set(gca, 'XTick', 0:45:360, 'FontSize', 10);
ylabel('a [m/s^2]', 'FontSize', 11, 'FontWeight', 'bold');

% 1.4 Pulso / Jerk j(θ)
subplot(4, 1, 4);
plot(theta_deg, j / 1000, 'Color', [0.15, 0.65, 0.35], 'LineWidth', 2.0); % em m/s^3
hold on; grid on; grid minor;
line([0 360], [0 0], 'Color', 'k', 'LineWidth', 0.8);
for div = [90 180 270]
    line([div div], ylim, 'Color', [0.7 0.7 0.7], 'LineStyle', '--', 'LineWidth', 1);
end
xlim([0 360]);
set(gca, 'XTick', 0:45:360, 'FontSize', 10);
xlabel('\theta [graus]', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Jerk [m/s^3]', 'FontSize', 11, 'FontWeight', 'bold');

print(fig1, fullfile(assets_dir, 'grafico_evap_svaj_345.png'), '-dpng', '-r300');
close(fig1);
fprintf('-> Gráfico EVAP salvo em assets/grafico_evap_svaj_345.png\n');

%% -------------------------------------------------------------
%% FIGURA 2: Construção Circular Grau a Grau (Técnica do Usuário)
%% -------------------------------------------------------------
fig2 = figure('visible', 'off', 'position', [100, 100, 1050, 1050]);
hold on;

% 2.1 Eixos cartesianos principais e círculo base
line([-85 85], [0 0], 'Color', [0.82 0.82 0.85], 'LineStyle', ':', 'LineWidth', 1, 'HandleVisibility', 'off');
line([0 0], [-85 85], 'Color', [0.82 0.82 0.85], 'LineStyle', ':', 'LineWidth', 1, 'HandleVisibility', 'off');

% Círculo Base (tracejado elegante)
plot(xb, yb, 'Color', c_base, 'LineWidth', 2.0, 'LineStyle', '--', 'DisplayName', sprintf('Círculo Base (R_b = %d mm)', Rb));

% 2.2 Segmentos radiais de deslocamento desenhados a cada 5 graus (para evidenciar o raio r = Rb + s)
for deg_idx = 1:5:360
    plot([xb(deg_idx) xc(deg_idx)], [yb(deg_idx) yc(deg_idx)], ...
         'Color', [0.75, 0.82, 0.92], 'LineWidth', 1.0, 'HandleVisibility', 'off');
end

% 2.3 Curva contínua do perfil da Came
plot(xc, yc, 'Color', c_came, 'LineWidth', 3.0, 'DisplayName', 'Perfil da Came r(\theta) = R_b + s(\theta)');

% 2.4 Os 360 pontos gerados de grau em grau (coloridos por setor)
idx_subida  = 1:91;          % 0° a 90°
idx_espera1 = 91:181;        % 90° a 180°
idx_descida = 181:271;       % 180° a 270°
idx_espera2 = 271:361;       % 270° a 360°

scatter(xc(idx_subida), yc(idx_subida), 28, c_subida, 'filled', ...
        'DisplayName', 'Subida Polinomial 3-4-5 (0° a 90°)');
scatter(xc(idx_espera1), yc(idx_espera1), 28, c_espera1, 'filled', ...
        'DisplayName', 'Espera Superior s = 25 mm (90° a 180°)');
scatter(xc(idx_descida), yc(idx_descida), 28, c_descida, 'filled', ...
        'DisplayName', 'Descida Polinomial 3-4-5 (180° a 270°)');
scatter(xc(idx_espera2), yc(idx_espera2), 28, c_espera2, 'filled', ...
        'DisplayName', 'Espera Inferior s = 0 mm (270° a 360°)');

% Centro de rotação O
plot(0, 0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7, 'DisplayName', 'Centro de Rotação O');

% Anotações visuais dos marcos angulares e raios
plot([0 Rb], [0 0], 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
text(Rb/2, -3.5, sprintf('R_b = %d mm', Rb), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);

plot([0 0], [0 (Rb+h)], 'Color', c_espera1, 'LineWidth', 1.5, 'LineStyle', '-.', 'HandleVisibility', 'off');
text(3, (Rb + h/2), sprintf('R_{max} = %d mm', Rb+h), 'FontSize', 10, 'FontWeight', 'bold', 'Color', c_espera1);

% Seta circular indicando sentido de rotação omega
ang_s = linspace(25, 60, 25) * pi / 180;
r_s = 28;
xs = r_s * cos(ang_s);
ys = r_s * sin(ang_s);
plot(xs, ys, 'k-', 'LineWidth', 1.8, 'HandleVisibility', 'off');
% Ponta da seta
tip_x = xs(end); tip_y = ys(end);
tang_ang = ang_s(end) + pi/2;
arrow_len = 3.5;
ah1_x = tip_x + arrow_len * cos(tang_ang - 2.6);
ah1_y = tip_y + arrow_len * sin(tang_ang - 2.6);
ah2_x = tip_x + arrow_len * cos(tang_ang + 2.6);
ah2_y = tip_y + arrow_len * sin(tang_ang + 2.6);
fill([tip_x ah1_x ah2_x], [tip_y ah1_y ah2_y], 'k', 'EdgeColor', 'k', 'HandleVisibility', 'off');
text(r_s*cos(42*pi/180)+3, r_s*sin(42*pi/180)+3, '\omega (1 rev/s)', 'FontSize', 10, 'FontWeight', 'bold');

% Ajuste explícito da área de plotagem para dar espaço elegante à legenda inferior
set(gca, 'Position', [0.12, 0.19, 0.76, 0.72]);
axis equal;
grid on;
xlim([-90 90]);
ylim([-90 90]);
xlabel('X [mm]', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Y [mm]', 'FontSize', 11, 'FontWeight', 'bold');
title({'Geração Circular do Perfil da Came (360 Pontos Grau a Grau)', ...
       sprintf('R_b = %d mm | Elevação h = %d mm | Polinômio 3-4-5', Rb, h)}, ...
       'FontSize', 12, 'FontWeight', 'bold');

% Posicionamento refinado da legenda abaixo do eixo X
lgd = legend('Location', 'southoutside', 'FontSize', 9.5, 'NumColumns', 2);
set(lgd, 'Box', 'on', 'Color', [0.98 0.98 0.98]);

print(fig2, fullfile(assets_dir, 'grafico_perfil_came_polar_360pontos.png'), '-dpng', '-r300');
close(fig2);
fprintf('-> Gráfico do Perfil Polar salvo em assets/grafico_perfil_came_polar_360pontos.png\n');

%% -------------------------------------------------------------
%% FIGURA 3: PÔSTER / CAPA COMPLETA INTEGRADA (Layout Refinado)
%% -------------------------------------------------------------
fig3 = figure('visible', 'off', 'position', [50, 50, 1650, 1000]);

% Banner do cabeçalho superior (sem sobreposição)
annotation('textbox', [0.05, 0.93, 0.90, 0.05], 'String', ...
           'PROJETO DE MECANISMOS CAME-SEGUIDOR — DINÂMICA DAS MÁQUINAS (UFG)', ...
           'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
           'FontSize', 15, 'FontWeight', 'bold', 'Color', [0.10 0.15 0.28]);

annotation('textbox', [0.05, 0.90, 0.90, 0.03], 'String', ...
           'Síntese Cinemática: Curvas EVAP (SVAJ) & Mapeamento Polar r(\theta) = R_b + s(\theta)', ...
           'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
           'FontSize', 11, 'Color', [0.40 0.45 0.50]);

% --- PAINEL ESQUERDO: DIAGRAMAS SVAJ (posicionamento explícito) ---
% 1) Deslocamento
ax1 = axes('Position', [0.07, 0.64, 0.38, 0.22]);
plot(theta_deg, s, 'Color', c_subida, 'LineWidth', 2.6);
hold on; grid on; grid minor;
xlim([0 360]); set(gca, 'XTick', 0:45:360, 'FontSize', 9);
ylabel('s [mm]', 'FontSize', 10, 'FontWeight', 'bold');
title('(a) Deslocamento do Seguidor s(\theta)', 'FontSize', 10.5, 'FontWeight', 'bold');
for div = [90 180 270]
    line([div div], ylim, 'Color', [0.75 0.75 0.75], 'LineStyle', '--', 'HandleVisibility', 'off');
end

% 2) Velocidade
ax2 = axes('Position', [0.07, 0.38, 0.38, 0.20]);
plot(theta_deg, v, 'Color', [0.55 0.20 0.80], 'LineWidth', 2.2);
hold on; grid on; grid minor;
line([0 360], [0 0], 'Color', 'k', 'LineWidth', 0.8, 'HandleVisibility', 'off');
xlim([0 360]); set(gca, 'XTick', 0:45:360, 'FontSize', 9);
ylabel('v [mm/s]', 'FontSize', 10, 'FontWeight', 'bold');
title('(b) Velocidade v(\theta)', 'FontSize', 10.5, 'FontWeight', 'bold');
for div = [90 180 270]
    line([div div], ylim, 'Color', [0.75 0.75 0.75], 'LineStyle', '--', 'HandleVisibility', 'off');
end

% 3) Aceleração
ax3 = axes('Position', [0.07, 0.11, 0.38, 0.20]);
plot(theta_deg, a/1000, 'Color', c_descida, 'LineWidth', 2.2);
hold on; grid on; grid minor;
line([0 360], [0 0], 'Color', 'k', 'LineWidth', 0.8, 'HandleVisibility', 'off');
xlim([0 360]); set(gca, 'XTick', 0:45:360, 'FontSize', 9);
xlabel('\theta [graus]', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('a [m/s^2]', 'FontSize', 10, 'FontWeight', 'bold');
title('(c) Aceleração a(\theta)', 'FontSize', 10.5, 'FontWeight', 'bold');
for div = [90 180 270]
    line([div div], ylim, 'Color', [0.75 0.75 0.75], 'LineStyle', '--', 'HandleVisibility', 'off');
end

% --- PAINEL DIREITO: O PERFIL POLAR DA CAME (CAPA PRINCIPAL) ---
ax_polar = axes('Position', [0.52, 0.18, 0.44, 0.70]);
hold on;

% Eixos auxiliares
line([-88 88], [0 0], 'Color', [0.85 0.85 0.88], 'LineStyle', ':', 'LineWidth', 1, 'HandleVisibility', 'off');
line([0 0], [-88 88], 'Color', [0.85 0.85 0.88], 'LineStyle', ':', 'LineWidth', 1, 'HandleVisibility', 'off');

% Círculo base
plot(xb, yb, 'Color', c_base, 'LineWidth', 2.0, 'LineStyle', '--', 'DisplayName', sprintf('Círculo Base (R_b = %d mm)', Rb));

% Raios de grau em grau (amostragem a cada 10 graus para não poluir)
for deg_idx = 1:10:360
    plot([xb(deg_idx) xc(deg_idx)], [yb(deg_idx) yc(deg_idx)], ...
         'Color', [0.80 0.85 0.95], 'LineWidth', 1.1, 'HandleVisibility', 'off');
end

% Perfil contínuo
plot(xc, yc, 'Color', c_came, 'LineWidth', 3.0, 'DisplayName', 'Perfil da Came r(\theta)');

% Pontos grau a grau
scatter(xc(idx_subida), yc(idx_subida), 24, c_subida, 'filled', 'DisplayName', 'Subida (0°-90°)');
scatter(xc(idx_espera1), yc(idx_espera1), 24, c_espera1, 'filled', 'DisplayName', 'Espera Alta (90°-180°)');
scatter(xc(idx_descida), yc(idx_descida), 24, c_descida, 'filled', 'DisplayName', 'Descida (180°-270°)');
scatter(xc(idx_espera2), yc(idx_espera2), 24, c_espera2, 'filled', 'DisplayName', 'Espera Baixa (270°-360°)');

plot(0, 0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7, 'DisplayName', 'Centro O');

% Indicação de raio base e máximo
text(Rb/2, -4, sprintf('R_b = %d mm', Rb), 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);
text(3, (Rb + h/2), sprintf('R_{max} = %d mm', Rb+h), 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', c_espera1);

axis equal;
grid on;
xlim([-90 90]);
ylim([-90 90]);
xlabel('X [mm]', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Y [mm]', 'FontSize', 11, 'FontWeight', 'bold');
title({'Geração Polar do Perfil da Came (360 Pontos Grau a Grau)', ...
       sprintf('R_b = %d mm | h = %d mm | Polinomial 3-4-5', Rb, h)}, ...
       'FontSize', 11.5, 'FontWeight', 'bold');

lgd3 = legend('Location', 'southoutside', 'FontSize', 9, 'NumColumns', 2);
set(lgd3, 'Box', 'on', 'Color', [0.98 0.98 0.98]);

print(fig3, fullfile(assets_dir, 'capa_projeto_cames.png'), '-dpng', '-r300');
close(fig3);
fprintf('-> Capa do projeto salva em assets/capa_projeto_cames.png\n');

fprintf('\nExecução concluída com sucesso!\n');
