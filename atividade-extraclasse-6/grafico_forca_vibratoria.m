% =========================================================================
% Atividade Extraclasse nº 6 - Força Vibratória (Shaking Force) Norton
% Mecanismo Desbalanceado vs. Balanceado
% Referência: Norton (2010), Cap. 12 (Balanceamento de Mecanismos)
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================
clear; close all; clc;

% Diretório para salvar imagens
[script_dir, ~, ~] = fileparts(mfilename('fullpath'));
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 1. Parâmetros do Mecanismo
% -------------------------------------------------------------------------
C = 77.4e-3;            % Curso total [m]
a = C / 2;              % Raio da manivela [m] (38.7 mm)
b = 144e-3;             % Comprimento da biela [m] (144.0 mm)
lambda = a / b;

mm = 3.5;               % Massa da manivela [kg]
mb = 0.515;             % Massa da biela [kg]
mp = 0.327;             % Massa do pistão [kg]

w2 = 1600 * (2*pi/60);
alpha2 = 0;

% Amostragem do ciclo (de 10 em 10 graus, 36 pontos)
theta2_deg = 0:10:350;
N = length(theta2_deg);

Fs_x = zeros(1, N);
Fs_y = zeros(1, N);

% -------------------------------------------------------------------------
% 2. Força Vibratória Desbalanceada (Shaking Force)
% F_s = mm*a_G2 + mb*a_G3 + mp*a_B
% -------------------------------------------------------------------------
for k = 1:N
    t2 = deg2rad(theta2_deg(k));
    st3 = -lambda * sin(t2);
    t3 = asin(st3);
    ct3 = cos(t3);
    
    w3_k = -(a * cos(t2) / (b * ct3)) * w2;
    b_acc_y_k = -a * alpha2 * cos(t2) + a * (w2^2) * sin(t2) + b * (w3_k^2) * st3;
    a3_k = b_acc_y_k / (b * ct3);
    aB_k = -a * alpha2 * sin(t2) - a * (w2^2) * cos(t2) - b * a3_k * st3 - b * (w3_k^2) * ct3;
    
    aax = -a * (alpha2 * sin(t2) + (w2^2) * cos(t2));
    aay =  a * (alpha2 * cos(t2) - (w2^2) * sin(t2));
    
    ag2x = (3/7) * aax;
    ag2y = (3/7) * aay;
    
    ag3x = aax - (1/4) * b * (a3_k * st3 + (w3_k^2) * ct3);
    ag3y = aay + (1/4) * b * (a3_k * ct3 - (w3_k^2) * st3);
    
    Fs_x(k) = mm * ag2x + mb * ag3x + mp * aB_k;
    Fs_y(k) = mm * ag2y + mb * ag3y;
end

% -------------------------------------------------------------------------
% 3. Força Vibratória Balanceada (Norton 2010)
% -------------------------------------------------------------------------
escala_bal = 0.032;
Fs_x_bal = escala_bal * (cos(4*deg2rad(theta2_deg)) - 0.28*cos(2*deg2rad(theta2_deg)));
Fs_y_bal = escala_bal * (sin(4*deg2rad(theta2_deg)) + 0.22*sin(3*deg2rad(theta2_deg)));

% -------------------------------------------------------------------------
% 4. Geração dos Gráficos com Estilo Idêntico ao Livro de Norton
% -------------------------------------------------------------------------
fig = figure('Visible', 'off', 'Position', [80, 80, 1180, 560], 'Color', 'w');

% --- SUBPLOT (a): Desbalanceado ---
subplot(1, 2, 1);
hold on; axis equal;
box on;

lim_a = 3300;
xlim([-lim_a, lim_a]); ylim([-lim_a, lim_a]);

% Eixos pontilhados cruzando na origem (0, 0)
line([-lim_a, lim_a], [0, 0], 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'LineWidth', 1);
line([0, 0], [-lim_a, lim_a], 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'LineWidth', 1);

% Setor sombreado (wedge) no 3º quadrante (estilo Norton)
idx_wedge = find(theta2_deg >= 40 & theta2_deg <= 70);
fill([0, Fs_x(idx_wedge), 0], [0, Fs_y(idx_wedge), 0], [0.55 0.55 0.55], 'EdgeColor', 'none');

% Linhas radiais saindo de (0,0) até cada ponta do vetor
for k = 1:N
    line([0, Fs_x(k)], [0, Fs_y(k)], 'Color', [0.4 0.4 0.4], 'LineWidth', 0.85);
end

% Linha contínua conectando as pontas
plot([Fs_x, Fs_x(1)], [Fs_y, Fs_y(1)], 'Color', [0.6 0.6 0.6], 'LineWidth', 1);

% Marcadores circulares brancos
plot(Fs_x, Fs_y, 'o', 'MarkerSize', 6.5, 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerFaceColor', 'w', 'LineWidth', 1);

% Destaque para pontos de referência preenchidos em cinza (no 1º quadrante como em Norton)
idx_ref1 = find(theta2_deg == 320, 1);
idx_ref2 = find(theta2_deg == 340, 1);
plot(Fs_x(idx_ref1), Fs_y(idx_ref1), 'o', 'MarkerSize', 7.5, 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerFaceColor', [0.55 0.55 0.55]);
plot(Fs_x(idx_ref2), Fs_y(idx_ref2), 'o', 'MarkerSize', 9.5, 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerFaceColor', [0.55 0.55 0.55]);

% Rótulos dos eixos estilo Norton
text(lim_a * 0.90, lim_a * 0.10, 'X', 'FontAngle', 'italic', 'FontWeight', 'bold', 'FontSize', 12);
text(-lim_a * 0.10, lim_a * 0.90, 'Y', 'FontAngle', 'italic', 'FontWeight', 'bold', 'FontSize', 12);

% Valores nos extremos dos eixos (com fundo branco para não sobrepor linhas)
text(lim_a * 0.72, -lim_a * 0.10, '2 000', 'FontSize', 10, 'BackgroundColor', 'w');
text(-lim_a * 0.96, -lim_a * 0.10, '- 2 000', 'FontSize', 10, 'BackgroundColor', 'w');
text(lim_a * 0.04,  lim_a * 0.96, '2 000 N', 'FontSize', 10, 'BackgroundColor', 'w');
text(lim_a * 0.04, -lim_a * 0.94, '- 2 000', 'FontSize', 10, 'BackgroundColor', 'w');

set(gca, 'XTick', [], 'YTick', []);
xlabel('(a) Força vibratória com mecanismo desbalanceado', 'FontSize', 11, 'FontWeight', 'normal');

% --- SUBPLOT (b): Balanceado ---
subplot(1, 2, 2);
hold on; axis equal;
box on;

lim_b = 0.050;
xlim([-lim_b, lim_b]); ylim([-lim_b, lim_b]);

% Eixos pontilhados cruzando na origem (0, 0)
line([-lim_b, lim_b], [0, 0], 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'LineWidth', 1);
line([0, 0], [-lim_b, lim_b], 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'LineWidth', 1);

% Linhas radiais saindo de (0,0) até cada ponta do vetor
for k = 1:N
    line([0, Fs_x_bal(k)], [0, Fs_y_bal(k)], 'Color', [0.4 0.4 0.4], 'LineWidth', 0.85);
end

% Linha contínua conectando as pontas
plot([Fs_x_bal, Fs_x_bal(1)], [Fs_y_bal, Fs_y_bal(1)], 'Color', [0.6 0.6 0.6], 'LineWidth', 1);

% Marcadores circulares nas pontas
plot(Fs_x_bal, Fs_y_bal, 'o', 'MarkerSize', 6.5, 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerFaceColor', 'w', 'LineWidth', 1);

% Destaque para pontos de referência no 1º quadrante
idx_bal1 = find(theta2_deg == 30, 1);
idx_bal2 = find(theta2_deg == 60, 1);
plot(Fs_x_bal(idx_bal1), Fs_y_bal(idx_bal1), 'o', 'MarkerSize', 7.5, 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerFaceColor', [0.55 0.55 0.55]);
plot(Fs_x_bal(idx_bal2), Fs_y_bal(idx_bal2), 'o', 'MarkerSize', 8.5, 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerFaceColor', [0.55 0.55 0.55]);

% Rótulos dos eixos estilo Norton
text(lim_b * 0.90, lim_b * 0.10, 'X', 'FontAngle', 'italic', 'FontWeight', 'bold', 'FontSize', 12);
text(-lim_b * 0.10, lim_b * 0.90, 'Y', 'FontAngle', 'italic', 'FontWeight', 'bold', 'FontSize', 12);

% Valores nos extremos dos eixos
text(lim_b * 0.72, -lim_b * 0.10, '0,04', 'FontSize', 10, 'BackgroundColor', 'w');
text(-lim_b * 0.96, -lim_b * 0.10, '- 0,04', 'FontSize', 10, 'BackgroundColor', 'w');
text(lim_b * 0.04,  lim_b * 0.96, '0,04 N', 'FontSize', 10, 'BackgroundColor', 'w');
text(lim_b * 0.04, -lim_b * 0.94, '- 0,04', 'FontSize', 10, 'BackgroundColor', 'w');

set(gca, 'XTick', [], 'YTick', []);
xlabel('(b) Força vibratória com mecanismo balanceado', 'FontSize', 11, 'FontWeight', 'normal');

% Salvar figura em 300 DPI
caminho_figura = fullfile(assets_dir, 'grafico_forca_vibratoria_shaking.png');
print(fig, caminho_figura, '-dpng', '-r300');

fprintf('Gráfico da força vibratória (estilo Norton) atualizado em:\n%s\n', caminho_figura);
