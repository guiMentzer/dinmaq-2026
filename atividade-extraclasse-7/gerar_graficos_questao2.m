%% Script da Questão 2: Diagramas Cinemáticos (s, v, a, j) e Perfis de Cames Polinomial 3-4-5 vs Uniforme
%% Disciplina: Dinâmica das Máquinas - Prof. Sigeo Kitatani Jr.

clear; close all; clc;
graphics_toolkit('qt');

assets_dir = fullfile(fileparts(mfilename('fullpath')), 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------
% 1. DADOS DE PROJETO
% -------------------------------------------------------------
h = 25.0;            % Elevação do seguidor em mm
n_rpm = 60.0;        % Rotação da came: 1 rev/s = 60 rpm
omega = 2 * pi * 1;  % Velocidade angular (rad/s) = 2*pi rad/s ~ 6.2832 rad/s
Rb = 50.0;           % Raio do círculo de base escolhido (mm)

% Intervalos de cada estágio (90 graus cada = pi/2 radianos)
% Nota: 90 graus = pi/2 rad (um quarto de volta)
beta1 = pi / 2; % 0 a 90: espera inferior
beta2 = pi / 2; % 90 a 180: subida
beta3 = pi / 2; % 180 a 270: espera superior
beta4 = pi / 2; % 270 a 360: descida

% Discretização de 360 pontos (1 ponto por grau)
theta_deg = linspace(0, 360, 721); % 0.5 grau de resolução para gráficos perfeitamente suaves
theta_rad = deg2rad(theta_deg);
N = length(theta_rad);

% Vetores para Polinomial 3-4-5
s_poly = zeros(1, N);
v_poly = zeros(1, N);
a_poly = zeros(1, N);
j_poly = zeros(1, N);

% Vetores para Movimento Uniforme (velocidade constante)
s_uni = zeros(1, N);

% -------------------------------------------------------------
% 2. CÁLCULO CINEMÁTICO COMPLETO AO LONGO DE 360°
% -------------------------------------------------------------
for i = 1:N
    th = theta_rad(i);
    
    % --- POLINOMIAL 3-4-5 ---
    if th <= pi/2
        % Estágio 1: Espera Inferior (0 a 90°)
        s_poly(i) = 0;
        v_poly(i) = 0;
        a_poly(i) = 0;
        j_poly(i) = 0;
        
        s_uni(i)  = 0;
        
    elseif th <= pi
        % Estágio 2: Subida Polinomial 3-4-5 (90° a 180°)
        phi = th - pi/2;
        u = phi / beta2;
        
        s_poly(i) = h * (10*u^3 - 15*u^4 + 6*u^5);
        v_poly(i) = (h * omega / beta2) * (30*u^2 - 60*u^3 + 30*u^4);
        a_poly(i) = (h * omega^2 / (beta2^2)) * (60*u - 180*u^2 + 120*u^3);
        j_poly(i) = (h * omega^3 / (beta2^3)) * (60 - 360*u + 360*u^2);
        
        % Uniforme correspondente
        s_uni(i)  = h * u;
        
    elseif th <= 3*pi/2
        % Estágio 3: Espera Superior (180° a 270°)
        s_poly(i) = h;
        v_poly(i) = 0;
        a_poly(i) = 0;
        j_poly(i) = 0;
        
        s_uni(i)  = h;
        
    else
        % Estágio 4: Descida Polinomial 3-4-5 (270° a 360°)
        phi = th - 3*pi/2;
        u = phi / beta4;
        
        % Norton Eq. Descida 3-4-5: s = h * [1 - (10u^3 - 15u^4 + 6u^5)]
        s_poly(i) = h * (1 - (10*u^3 - 15*u^4 + 6*u^5));
        v_poly(i) = - (h * omega / beta4) * (30*u^2 - 60*u^3 + 30*u^4);
        a_poly(i) = - (h * omega^2 / (beta4^2)) * (60*u - 180*u^2 + 120*u^3);
        j_poly(i) = - (h * omega^3 / (beta4^3)) * (60 - 360*u + 360*u^2);
        
        s_uni(i)  = h * (1 - u);
    end
end

% -------------------------------------------------------------
% 3. GERAÇÃO DOS GRÁFICOS INDIVIDUAIS (ITEM C)
% -------------------------------------------------------------
cor_primaria = [0.0, 0.35, 0.75]; % Azul técnico

% 3.1 Gráfico de Deslocamento
fig_s = figure('visible', 'off', 'position', [100, 100, 750, 420]);
plot(theta_deg, s_poly, 'Color', cor_primaria, 'LineWidth', 2.2);
grid on; set(gca, 'FontSize', 11, 'LineWidth', 1.1);
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
ylim([-2, 28]);
xlabel('\theta [graus]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('s(\theta) [mm]', 'FontSize', 12, 'FontWeight', 'bold');
title('Deslocamento do Seguidor - Polinômio 3-4-5 (h = 25 mm)', 'FontSize', 13, 'FontWeight', 'bold');
line([90 90], [-2 28], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
line([180 180], [-2 28], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
line([270 270], [-2 28], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
text(45, 2, 'Espera Inf.', 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0.4 0.4 0.4]);
text(135, 26, 'Subida 3-4-5', 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0.4 0.4 0.4]);
text(225, 26, 'Espera Sup.', 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0.4 0.4 0.4]);
text(315, 2, 'Descida 3-4-5', 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0.4 0.4 0.4]);
print(fig_s, fullfile(assets_dir, 'grafico_q2_deslocamento.png'), '-dpng', '-r300');

% 3.2 Gráfico de Velocidade
fig_v = figure('visible', 'off', 'position', [100, 100, 750, 420]);
plot(theta_deg, v_poly, 'Color', [0.1, 0.65, 0.25], 'LineWidth', 2.2);
grid on; set(gca, 'FontSize', 11, 'LineWidth', 1.1);
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
xlabel('\theta [graus]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('v(\theta) [mm/s]', 'FontSize', 12, 'FontWeight', 'bold');
title('Velocidade do Seguidor - Polinômio 3-4-5 (\omega = 2\pi rad/s)', 'FontSize', 13, 'FontWeight', 'bold');
line([0 360], [0 0], 'Color', 'k', 'LineWidth', 0.8);
line([90 90], [min(v_poly)*1.1 max(v_poly)*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
line([180 180], [min(v_poly)*1.1 max(v_poly)*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
line([270 270], [min(v_poly)*1.1 max(v_poly)*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
print(fig_v, fullfile(assets_dir, 'grafico_q2_velocidade.png'), '-dpng', '-r300');

% 3.3 Gráfico de Aceleração
fig_a = figure('visible', 'off', 'position', [100, 100, 750, 420]);
plot(theta_deg, a_poly, 'Color', [0.85, 0.2, 0.1], 'LineWidth', 2.2);
grid on; set(gca, 'FontSize', 11, 'LineWidth', 1.1);
xlim([0, 360]); set(gca, 'XTick', 0:45:360);
xlabel('\theta [graus]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('a(\theta) [mm/s^2]', 'FontSize', 12, 'FontWeight', 'bold');
title('Aceleração do Seguidor - Polinômio 3-4-5 (Contínua C^0)', 'FontSize', 13, 'FontWeight', 'bold');
line([0 360], [0 0], 'Color', 'k', 'LineWidth', 0.8);
line([90 90], [min(a_poly)*1.1 max(a_poly)*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
line([180 180], [min(a_poly)*1.1 max(a_poly)*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
line([270 270], [min(a_poly)*1.1 max(a_poly)*1.1], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
print(fig_a, fullfile(assets_dir, 'grafico_q2_aceleracao.png'), '-dpng', '-r300');

% -------------------------------------------------------------
% 4. COMPARATIVO POLAR DE PERFIL: 3-4-5 vs UNIFORME (ITEM D)
% -------------------------------------------------------------
% Para seguidor de face plana (translating flat-faced follower):
% Coordenadas de contato do came com face plana perfeitamente radial (Norton Seção 8.7):
% Raio r(theta) = Rb + s(theta)
% Parâmetro de contato lateral: l = v(theta) / omega = ds/dtheta
% No entanto, para traçado do perfil geométrico polar base direto:
% r_poly = Rb + s_poly
% r_uni  = Rb + s_uni

r_poly = Rb + s_poly;
r_uni  = Rb + s_uni;

% Conversão cartesiana para plotagem clara
x_poly = r_poly .* cos(theta_rad);
y_poly = r_poly .* sin(theta_rad);

x_uni = r_uni .* cos(theta_rad);
y_uni = r_uni .* sin(theta_rad);

% Círculo de base (Rb = 50 mm)
x_base = Rb * cos(theta_rad);
y_base = Rb * sin(theta_rad);

% Configuração da figura polar
fig_cam = figure('visible', 'off', 'position', [100, 100, 850, 750]);
hold on; box on; grid on; axis equal;

plot(x_base, y_base, 'Color', [0.55, 0.55, 0.55], 'LineStyle', ':', 'LineWidth', 1.5, 'DisplayName', sprintf('Círculo de Base (R_b = %d mm)', Rb));
plot(x_uni, y_uni, 'Color', [0.85, 0.15, 0.15], 'LineStyle', '--', 'LineWidth', 1.8, 'DisplayName', 'Perfil Uniforme (v = cte, Cúspides)');
plot(x_poly, y_poly, 'Color', [0.0, 0.35, 0.8], 'LineWidth', 2.3, 'DisplayName', 'Perfil Polinomial 3-4-5 (Suave)');

% Centro do came
plot(0, 0, 'k+', 'MarkerSize', 12, 'LineWidth', 1.8, 'DisplayName', 'Centro de Rotação (Eixo)');

legend('Location', 'northeast', 'FontSize', 10);
title('Comparativo Geométrico do Perfil da Came: 3-4-5 vs. Velocidade Constante', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('X [mm]', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Y [mm]', 'FontSize', 11, 'FontWeight', 'bold');
xlim([-90, 90]);
ylim([-90, 90]);

print(fig_cam, fullfile(assets_dir, 'grafico_q2_comparativo_came.png'), '-dpng', '-r300');

fprintf('Todos os gráficos da Questão 2 gerados com sucesso em 300 DPI!\n');
