% =========================================================================
% Atividade Extraclasse nº 6 - Diagramas de Corpo Livre (DCL) dos Elos
% Dinâmica de Mecanismos - Norton (2010)
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

IG2 = (1/12) * mm * a^2;
IG3 = (1/12) * mb * b^2;

% Condição (a): w = 1600 rpm, alpha = 0.1 rad/s^2, theta2 = 60°
theta2_deg = 60;
theta2 = deg2rad(theta2_deg);
w2 = 1600 * (2*pi/60);
alpha2 = 0.1;

% -------------------------------------------------------------------------
% 2. Cinemática em theta2 = 60°
% -------------------------------------------------------------------------
sin_t3 = -lambda * sin(theta2);
theta3 = asin(sin_t3);
cos_t3 = cos(theta3);
theta3_deg = rad2deg(theta3);

w3 = -(a * cos(theta2) / (b * cos_t3)) * w2;
vB = -a * w2 * sin(theta2) - b * w3 * sin_t3;

b_acc_y = -a * alpha2 * cos(theta2) + a * (w2^2) * sin(theta2) + b * (w3^2) * sin_t3;
alpha3 = b_acc_y / (b * cos_t3);
aB = -a * alpha2 * sin(theta2) - a * (w2^2) * cos(theta2) - b * alpha3 * sin_t3 - b * (w3^2) * cos_t3;

% Posições físicas [m]
O2 = [0, 0];
A  = [a * cos(theta2), a * sin(theta2)];
G2 = (3/7) * A;
B  = [A(1) + b * cos(theta3), 0];
G3 = A + (1/4) * (B - A);

% Acelerações lineares dos centros de massa [m/s^2]
aAx = -a * (alpha2 * sin(theta2) + (w2^2) * cos(theta2));
aAy =  a * (alpha2 * cos(theta2) - (w2^2) * sin(theta2));

aG2x = (3/7) * aAx;
aG2y = (3/7) * aAy;

aG3x = aAx - (1/4) * b * (alpha3 * sin_t3 + (w3^2) * cos_t3);
aG3y = aAy + (1/4) * b * (alpha3 * cos_t3 - (w3^2) * sin_t3);

% -------------------------------------------------------------------------
% 3. Matriz Dinâmica de Norton 8x8 (Condição a)
% -------------------------------------------------------------------------
A_mat = zeros(8, 8);
B_vec = zeros(8, 1);

% Elo 2:
A_mat(1, 1) = 1; A_mat(1, 3) = 1; B_vec(1) = mm * aG2x;
A_mat(2, 2) = 1; A_mat(2, 4) = 1; B_vec(2) = mm * aG2y;

R12x = -(3/7) * a * cos(theta2); R12y = -(3/7) * a * sin(theta2);
R32x =  (4/7) * a * cos(theta2); R32y =  (4/7) * a * sin(theta2);

A_mat(3, 1) = -R12y; A_mat(3, 2) = R12x;
A_mat(3, 3) = -R32y; A_mat(3, 4) = R32x;
A_mat(3, 8) = 1;
B_vec(3) = IG2 * alpha2;

% Elo 3:
A_mat(4, 3) = -1; A_mat(4, 5) = 1; B_vec(4) = mb * aG3x;
A_mat(5, 4) = -1; A_mat(5, 6) = 1; B_vec(5) = mb * aG3y;

R23x = -(1/4) * b * cos_t3; R23y = -(1/4) * b * sin_t3;
R43x =  (3/4) * b * cos_t3; R43y =  (3/4) * b * sin_t3;

A_mat(6, 3) = R23y;  A_mat(6, 4) = -R23x;
A_mat(6, 5) = -R43y; A_mat(6, 6) = R43x;
B_vec(6) = IG3 * alpha3;

% Elo 4:
A_mat(7, 5) = -1; B_vec(7) = mp * aB;
A_mat(8, 6) = -1; A_mat(8, 7) = 1; B_vec(8) = 0;

sol = A_mat \ B_vec;

F12 = [sol(1), sol(2)];
F32 = [sol(3), sol(4)];
F23 = -F32;
F43 = [sol(5), sol(6)];
F34 = -F43;
F14 = [0, sol(7)];
T12 = sol(8);

Fin2 = -mm * [aG2x, aG2y];
Fin3 = -mb * [aG3x, aG3y];
Fin4 = -mp * [aB, 0];
Tin3 = -IG3 * alpha3;

% -------------------------------------------------------------------------
% 4. DCL ELO 4 (Pistão - Subseção 4.1)
% -------------------------------------------------------------------------
fig_dcl4 = figure('Visible', 'off', 'Position', [100, 100, 950, 750]);
hold on; grid on; axis equal;

s4 = 0.12; % mm/N

% Bloco do Pistão
w_p = 36; h_p = 24; % [mm]
rectangle('Position', [B(1)*1e3 - w_p/2, -h_p/2, w_p, h_p], 'FaceColor', [0.93 0.93 0.93], 'EdgeColor', 'k', 'LineWidth', 2);
plot(B(1)*1e3, B(2)*1e3, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', [0.85, 0.85, 0.85]);

% Linhas da Guia do Cilindro (Parede)
plot([B(1)*1e3 - 55, B(1)*1e3 + 55], [ h_p/2,  h_p/2], 'k--', 'LineWidth', 1.5);
plot([B(1)*1e3 - 55, B(1)*1e3 + 55], [-h_p/2, -h_p/2], 'k--', 'LineWidth', 1.5);

% Vetores de Força
quiver(B(1)*1e3, B(2)*1e3, F34(1)*s4, F34(2)*s4, 0, 'Color', [0, 0.45, 0.9], 'LineWidth', 2.5, 'MaxHeadSize', 0.35);
quiver(B(1)*1e3, -h_p/2,    F14(1)*s4, F14(2)*s4, 0, 'Color', [0.85, 0.45, 0], 'LineWidth', 2.5, 'MaxHeadSize', 0.35);
quiver(B(1)*1e3, B(2)*1e3, Fin4(1)*s4, Fin4(2)*s4, 0, 'Color', 'r', 'LineWidth', 2.5, 'MaxHeadSize', 0.35);

% Textos explicativos
text(B(1)*1e3 - 3, B(2)*1e3 + 5, 'B', 'FontWeight', 'bold', 'FontSize', 12);

text((B(1)*1e3 + F34(1)*s4) - 20, (B(2)*1e3 + F34(2)*s4) + 10, ...
    sprintf('F_{34} = -F_{43}\n[%.1f, %.1f] N', F34(1), F34(2)), ...
    'Color', [0, 0.45, 0.9], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0, 0.45, 0.9]);

text(B(1)*1e3 + 6, -h_p/2 - 14, ...
    sprintf('F_{14} = [0, %.1f] N\n(Normal da parede)', F14(2)), ...
    'Color', [0.85, 0.45, 0], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0.85, 0.45, 0]);

text((B(1)*1e3 + Fin4(1)*s4) + 4, B(2)*1e3 - 4, ...
    sprintf('F_{in,4} = -m_p a_B = %.1f N', Fin4(1)), ...
    'Color', 'r', 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', 'r');

text(B(1)*1e3 + w_p/2 + 5, 5, 'F_p = 0 N (Sem pressao)', 'Color', [0.4 0.4 0.4], 'FontSize', 10);

title(sprintf('DCL do Elo 4 (Pistão) — \\theta_2 = %d^\\circ, \\omega_2 = 1600 rpm', theta2_deg), 'FontSize', 13, 'FontWeight', 'bold');
xlabel('X (mm)'); ylabel('Y (mm)');
xlim([115, 210]); ylim([-45, 45]);
print(fig_dcl4, fullfile(assets_dir, 'dcl_elo4_pistao.png'), '-dpng', '-r300');

% -------------------------------------------------------------------------
% 5. DCL ELO 3 (Biela - Subseção 4.2)
% -------------------------------------------------------------------------
fig_dcl3 = figure('Visible', 'off', 'Position', [100, 100, 950, 750]);
hold on; grid on; axis equal;

s3 = 0.08; % mm/N

% Barra física
plot([A(1), B(1)]*1e3, [A(2), B(2)]*1e3, 'Color', [0.2 0.2 0.2], 'LineWidth', 8);
plot(A(1)*1e3,  A(2)*1e3,  'ko', 'MarkerSize', 10, 'MarkerFaceColor', [0.85, 0.85, 0.85]);
plot(B(1)*1e3,  B(2)*1e3,  'ko', 'MarkerSize', 10, 'MarkerFaceColor', [0.85, 0.85, 0.85]);
plot(G3(1)*1e3, G3(2)*1e3, 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');

% Vetores de Força
quiver(A(1)*1e3,  A(2)*1e3,  F23(1)*s3, F23(2)*s3, 0, 'Color', [0.75, 0, 0.75], 'LineWidth', 2.5, 'MaxHeadSize', 0.35);
quiver(B(1)*1e3,  B(2)*1e3,  F43(1)*s3, F43(2)*s3, 0, 'Color', [0, 0.45, 0.9], 'LineWidth', 2.5, 'MaxHeadSize', 0.35);
quiver(G3(1)*1e3, G3(2)*1e3, Fin3(1)*s3, Fin3(2)*s3, 0, 'Color', 'r', 'LineWidth', 2.5, 'MaxHeadSize', 0.35);

% Textos explicativos
text(A(1)*1e3 + 2,  A(2)*1e3 + 7,  'A',   'FontWeight', 'bold', 'FontSize', 12);
text(B(1)*1e3 + 2,  B(2)*1e3 + 7,  'B',   'FontWeight', 'bold', 'FontSize', 12);
text(G3(1)*1e3 + 2, G3(2)*1e3 + 7, 'G_3', 'FontWeight', 'bold', 'FontSize', 12, 'Color', [0.6 0.4 0]);

text((A(1)*1e3 + F23(1)*s3) - 15, (A(2)*1e3 + F23(2)*s3) - 16, ...
    sprintf('F_{23} = -F_{32}\n[%.1f, %.1f] N', F23(1), F23(2)), ...
    'Color', [0.7, 0, 0.7], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0.75, 0, 0.75]);

text((B(1)*1e3 + F43(1)*s3) + 4, (B(2)*1e3 + F43(2)*s3) - 5, ...
    sprintf('F_{43} = [%.1f, %.1f] N\n|F_{43}| = %.1f N', F43(1), F43(2), norm(F43)), ...
    'Color', [0, 0.45, 0.9], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0, 0.45, 0.9]);

text((G3(1)*1e3 + Fin3(1)*s3) + 4, (G3(2)*1e3 + Fin3(2)*s3) + 6, ...
    sprintf('F_{in,3} = -m_b a_{G3}\n[%.1f, %.1f] N', Fin3(1), Fin3(2)), ...
    'Color', 'r', 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', 'r');

text(G3(1)*1e3 - 35, G3(2)*1e3 - 22, ...
    sprintf('T_{in,3} = -I_{G3}\\alpha_3 = %.2f N\\cdot m', Tin3), ...
    'Color', [0.8, 0.3, 0], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0.8, 0.3, 0]);

title(sprintf('DCL do Elo 3 (Biela) — \\theta_2 = %d^\\circ, \\theta_3 = %.2f^\\circ, \\omega_2 = 1600 rpm', theta2_deg, theta3_deg), 'FontSize', 13, 'FontWeight', 'bold');
xlabel('X (mm)'); ylabel('Y (mm)');
xlim([-30, 220]); ylim([-40, 70]);
print(fig_dcl3, fullfile(assets_dir, 'dcl_elo3_biela.png'), '-dpng', '-r300');

% -------------------------------------------------------------------------
% 6. DCL ELO 2 (Manivela - Subseção 4.3)
% -------------------------------------------------------------------------
fig_dcl2 = figure('Visible', 'off', 'Position', [100, 100, 950, 750]);
hold on; grid on; axis equal;

s2 = 0.018; % mm/N

% Barra física
plot([O2(1), A(1)]*1e3, [O2(2), A(2)]*1e3, 'Color', [0.2 0.2 0.2], 'LineWidth', 8);
plot(O2(1)*1e3, O2(2)*1e3, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', [0.85, 0.85, 0.85]);
plot(A(1)*1e3,  A(2)*1e3,  'ko', 'MarkerSize', 10, 'MarkerFaceColor', [0.85, 0.85, 0.85]);
plot(G2(1)*1e3, G2(2)*1e3, 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');

% Vetores de Força
quiver(O2(1)*1e3, O2(2)*1e3, F12(1)*s2, F12(2)*s2, 0, 'Color', [0, 0.55, 0], 'LineWidth', 2.5, 'MaxHeadSize', 0.35);
quiver(A(1)*1e3,  A(2)*1e3,  F32(1)*s2, F32(2)*s2, 0, 'Color', [0.75, 0, 0.75], 'LineWidth', 2.5, 'MaxHeadSize', 0.35);
quiver(G2(1)*1e3, G2(2)*1e3, Fin2(1)*s2, Fin2(2)*s2, 0, 'Color', 'r', 'LineWidth', 2.5, 'MaxHeadSize', 0.35);

% Seta de Torque T12 em O2 (arco anti-horário)
th_arc = linspace(deg2rad(20), deg2rad(150), 40);
r_arc = 12;
x_arc = r_arc * cos(th_arc);
y_arc = r_arc * sin(th_arc);
plot(x_arc, y_arc, 'b-', 'LineWidth', 2.5);
quiver(x_arc(end), y_arc(end), -sin(th_arc(end))*4, cos(th_arc(end))*4, 0, 'Color', 'b', 'LineWidth', 2.5, 'MaxHeadSize', 1.5);

% Textos explicativos com fundo branco
text(O2(1)*1e3 - 9, O2(2)*1e3 - 8, 'O_2', 'FontWeight', 'bold', 'FontSize', 12);
text(A(1)*1e3 + 4,  A(2)*1e3 - 4,  'A',   'FontWeight', 'bold', 'FontSize', 12);
text(G2(1)*1e3 + 4, G2(2)*1e3 - 4, 'G_2', 'FontWeight', 'bold', 'FontSize', 12, 'Color', [0.6 0.4 0]);

text((O2(1)*1e3 + F12(1)*s2) - 35, (O2(2)*1e3 + F12(2)*s2) - 8, ...
    sprintf('F_{12} = [%.1f, %.1f] N\n|F_{12}| = %.1f N', F12(1), F12(2), norm(F12)), ...
    'Color', [0, 0.5, 0], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0, 0.55, 0]);

text((A(1)*1e3 + F32(1)*s2) + 2, (A(2)*1e3 + F32(2)*s2) - 10, ...
    sprintf('F_{32} = [%.1f, %.1f] N\n|F_{32}| = %.1f N', F32(1), F32(2), norm(F32)), ...
    'Color', [0.7, 0, 0.7], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0.75, 0, 0.75]);

text((G2(1)*1e3 + Fin2(1)*s2) + 2, (G2(2)*1e3 + Fin2(2)*s2) + 8, ...
    sprintf('F_{in,2} = -m_m a_{G2}\n[%.1f, %.1f] N', Fin2(1), Fin2(2)), ...
    'Color', 'r', 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', 'r');

text(-42, 22, sprintf('T_{12} = +%.2f N\\cdot m', T12), 'FontSize', 11, 'FontWeight', 'bold', ...
    'Color', 'b', 'BackgroundColor', 'w', 'EdgeColor', 'b');

title(sprintf('DCL do Elo 2 (Manivela) — \\theta_2 = %d^\\circ, \\omega_2 = 1600 rpm, \\alpha_2 = 0.1 rad/s^2', theta2_deg), 'FontSize', 13, 'FontWeight', 'bold');
xlabel('X (mm)'); ylabel('Y (mm)');
xlim([-80, 75]); ylim([-70, 75]);
print(fig_dcl2, fullfile(assets_dir, 'dcl_elo2_manivela.png'), '-dpng', '-r300');

% -------------------------------------------------------------------------
% 7. DCL ELO 1 (Terra / Carcaça - Subseção 4.4)
% -------------------------------------------------------------------------
fig_dcl1 = figure('Visible', 'off', 'Position', [100, 100, 950, 650]);
hold on; grid on; axis equal;

s1 = 0.018; % mm/N

% Reações na Terra (Ação e Reação)
F21 = -F12; % Reação no mancal O2
F41 = -F14; % Reação na parede da guia
T21 = -T12; % Torque de rolagem (shaking torque) na carcaça

% Mancal O2 (Suporte Fixo)
plot(O2(1)*1e3, O2(2)*1e3, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', [0.5 0.5 0.5]);
% Desenhar triângulo de apoio fixo e hachuras
plot([-8, 0, 8, -8], [-10, 0, -10, -10], 'k-', 'LineWidth', 2);
line([-12, 12], [-10, -10], 'Color', 'k', 'LineWidth', 2);
for xh = -10:4:10
    line([xh, xh-4], [-10, -14], 'Color', 'k', 'LineWidth', 1.2);
end

% Guia do Cilindro
plot([B(1)*1e3 - 45, B(1)*1e3 + 45], [-h_p/2, -h_p/2], 'k-', 'LineWidth', 2.5);
for xh = (B(1)*1e3 - 40):8:(B(1)*1e3 + 40)
    line([xh, xh-5], [-h_p/2, -h_p/2 - 6], 'Color', 'k', 'LineWidth', 1.2);
end

% Vetores de Força aplicados na carcaça
quiver(O2(1)*1e3, O2(2)*1e3, F21(1)*s1, F21(2)*s1, 0, 'Color', [0, 0.55, 0], 'LineWidth', 2.5, 'MaxHeadSize', 0.35);
quiver(B(1)*1e3, -h_p/2,     F41(1)*0.12, F41(2)*0.12, 0, 'Color', [0.85, 0.45, 0], 'LineWidth', 2.5, 'MaxHeadSize', 0.35);

% Torque de reação T21 no mancal (sentido horário)
th_arc1 = linspace(deg2rad(150), deg2rad(20), 40);
x_arc1 = r_arc * cos(th_arc1);
y_arc1 = r_arc * sin(th_arc1);
plot(x_arc1, y_arc1, 'b-', 'LineWidth', 2.5);
quiver(x_arc1(end), y_arc1(end), sin(th_arc1(end))*4, -cos(th_arc1(end))*4, 0, 'Color', 'b', 'LineWidth', 2.5, 'MaxHeadSize', 1.5);

% Textos explicativos
text(O2(1)*1e3 - 8, O2(2)*1e3 - 18, 'Mancal O_2', 'FontWeight', 'bold', 'FontSize', 11);
text(B(1)*1e3 - 15, -h_p/2 - 12, 'Guia Fixa (Cilindro)', 'FontWeight', 'bold', 'FontSize', 11);

text((O2(1)*1e3 + F21(1)*s1) + 4, (O2(2)*1e3 + F21(2)*s1) - 4, ...
    sprintf('F_{21} = -F_{12}\n[%.1f, %.1f] N\n|F_{21}| = %.1f N', F21(1), F21(2), norm(F21)), ...
    'Color', [0, 0.5, 0], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0, 0.55, 0]);

text(B(1)*1e3 + 5, -h_p/2 + 15, ...
    sprintf('F_{41} = -F_{14} = [0, %.1f] N\n(Empuxo lateral no cilindro)', F41(2)), ...
    'Color', [0.85, 0.45, 0], 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0.85, 0.45, 0]);

text(-65, 30, sprintf('T_{21} = -T_{12} = -%.2f N\\cdot m\n(Torque de reacao na carcaca)', T12), ...
    'FontSize', 10, 'FontWeight', 'bold', 'Color', 'b', 'BackgroundColor', 'w', 'EdgeColor', 'b');

title(sprintf('DCL do Elo 1 (Terra / Carcaça) — \\theta_2 = %d^\\circ, \\omega_2 = 1600 rpm', theta2_deg), 'FontSize', 13, 'FontWeight', 'bold');
xlabel('X (mm)'); ylabel('Y (mm)');
xlim([-65, 220]); ylim([-35, 60]);
print(fig_dcl1, fullfile(assets_dir, 'dcl_elo1_terra.png'), '-dpng', '-r300');

% -------------------------------------------------------------------------
% 8. MECANISMO COMPLETO COM FORÇAS (Item a)
% -------------------------------------------------------------------------
fig_mec = figure('Visible', 'off', 'Position', [100, 100, 1000, 650]);
hold on; grid on; axis equal;

sm = 0.015; % mm/N

plot([O2(1), A(1)]*1e3, [O2(2), A(2)]*1e3, 'b-', 'LineWidth', 5);
plot([A(1), B(1)]*1e3,  [A(2), B(2)]*1e3,  'Color', [0.85 0.3 0], 'LineWidth', 4);
rectangle('Position', [B(1)*1e3 - 16, -11, 32, 22], 'FaceColor', [0.88 0.88 0.88], 'EdgeColor', 'k', 'LineWidth', 1.5);
plot(O2(1)*1e3, O2(2)*1e3, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(A(1)*1e3,  A(2)*1e3,  'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8);
plot(B(1)*1e3,  B(2)*1e3,  'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8);
plot(G2(1)*1e3, G2(2)*1e3, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 11);
plot(G3(1)*1e3, G3(2)*1e3, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 11);

h1 = quiver(O2(1)*1e3, O2(2)*1e3, F12(1)*sm, F12(2)*sm, 0, 'Color', [0, 0.55, 0], 'LineWidth', 2.2, 'MaxHeadSize', 0.35);
h2 = quiver(A(1)*1e3,  A(2)*1e3,  F32(1)*sm, F32(2)*sm, 0, 'Color', [0.75, 0, 0.75], 'LineWidth', 2.2, 'MaxHeadSize', 0.35);
h3 = quiver(B(1)*1e3,  B(2)*1e3,  F43(1)*sm, F43(2)*sm, 0, 'Color', [0, 0.45, 0.9], 'LineWidth', 2.2, 'MaxHeadSize', 0.35);
h4 = quiver(B(1)*1e3,  -11,        F14(1)*sm, F14(2)*sm, 0, 'Color', [0.85, 0.45, 0], 'LineWidth', 2.2, 'MaxHeadSize', 0.35);
h5 = quiver(G2(1)*1e3, G2(2)*1e3, Fin2(1)*sm, Fin2(2)*sm, 0, 'Color', 'r', 'LineWidth', 2, 'MaxHeadSize', 0.35);
h6 = quiver(G3(1)*1e3, G3(2)*1e3, Fin3(1)*sm, Fin3(2)*sm, 0, 'Color', 'm', 'LineWidth', 2, 'MaxHeadSize', 0.35);
h7 = quiver(B(1)*1e3,  B(2)*1e3,  Fin4(1)*sm, Fin4(2)*sm, 0, 'Color', 'k', 'LineWidth', 2, 'MaxHeadSize', 0.35);

title(sprintf('Mecanismo Biela-Manivela e Forças Dinâmicas — \\theta_2 = %d^\\circ, \\omega = 1600 rpm', theta2_deg), 'FontSize', 13, 'FontWeight', 'bold');
xlabel('X (mm)'); ylabel('Y (mm)');
legend([h1, h2, h3, h4, h5, h6, h7], ...
    {'F_{12} (Mancal O_2)', 'F_{32} (Pino A)', 'F_{43} (Pino B)', 'F_{14} (Guia)', ...
     'F_{in,2} (Inércia G_2)', 'F_{in,3} (Inércia G_3)', 'F_{in,4} (Inércia Pistão)'}, ...
    'Location', 'northeast');
xlim([-50, 205]); ylim([-55, 65]);
print(fig_mec, fullfile(assets_dir, 'dcl_mecanismo_completo.png'), '-dpng', '-r300');

% -------------------------------------------------------------------------
% 9. ITEM (b): Forças nas Juntas e Forças Inerciais (w = 5000 rpm, alpha = 0)
% -------------------------------------------------------------------------
w2_b = 5000 * (2*pi/60);
alpha2_b = 0;
theta_b_deg = 0:1:360;
Nb = length(theta_b_deg);

F12_b = zeros(Nb, 2);
F32_b = zeros(Nb, 2);
F43_b = zeros(Nb, 2);
F14_b = zeros(Nb, 1);
Fin2_b = zeros(Nb, 2);
Fin3_b = zeros(Nb, 2);
Fin4_b = zeros(Nb, 1);

for k = 1:Nb
    t2 = deg2rad(theta_b_deg(k));
    st3 = -lambda * sin(t2);
    t3 = asin(st3);
    ct3 = cos(t3);
    
    w3_k = -(a * cos(t2) / (b * ct3)) * w2_b;
    b_acc_y_k = -a * alpha2_b * cos(t2) + a * (w2_b^2) * sin(t2) + b * (w3_k^2) * st3;
    a3_k = b_acc_y_k / (b * ct3);
    aB_k = -a * alpha2_b * sin(t2) - a * (w2_b^2) * cos(t2) - b * a3_k * st3 - b * (w3_k^2) * ct3;
    
    aax = -a * (alpha2_b * sin(t2) + (w2_b^2) * cos(t2));
    aay =  a * (alpha2_b * cos(t2) - (w2_b^2) * sin(t2));

    ag2x = (3/7) * aax;
    ag2y = (3/7) * aay;
    
    ag3x = aax - (1/4) * b * (a3_k * st3 + (w3_k^2) * ct3);
    ag3y = aay + (1/4) * b * (a3_k * ct3 - (w3_k^2) * st3);
    
    Fin2_b(k, :) = -mm * [ag2x, ag2y];
    Fin3_b(k, :) = -mb * [ag3x, ag3y];
    Fin4_b(k)    = -mp * aB_k;
    
    A_k = zeros(8, 8);
    B_k = zeros(8, 1);
    
    A_k(1, 1) = 1; A_k(1, 3) = 1; B_k(1) = mm * ag2x;
    A_k(2, 2) = 1; A_k(2, 4) = 1; B_k(2) = mm * ag2y;
    
    r12x = -(3/7)*a*cos(t2); r12y = -(3/7)*a*sin(t2);
    r32x =  (4/7)*a*cos(t2); r32y =  (4/7)*a*sin(t2);
    A_k(3, 1) = -r12y; A_k(3, 2) = r12x;
    A_k(3, 3) = -r32y; A_k(3, 4) = r32x;
    A_k(3, 8) = 1;
    B_k(3) = IG2 * alpha2_b;
    
    A_k(4, 3) = -1; A_k(4, 5) = 1; B_k(4) = mb * ag3x;
    A_k(5, 4) = -1; A_k(5, 6) = 1; B_k(5) = mb * ag3y;
    
    r23x = -(1/4)*b*ct3; r23y = -(1/4)*b*st3;
    r43x =  (3/4)*b*ct3; r43y =  (3/4)*b*st3;
    A_k(6, 3) = r23y;  A_k(6, 4) = -r23x;
    A_k(6, 5) = -r43y; A_k(6, 6) = r43x;
    B_k(6) = IG3 * a3_k;
    
    A_k(7, 5) = -1; B_k(7) = mp * aB_k;
    A_k(8, 6) = -1; A_k(8, 7) = 1; B_k(8) = 0;
    
    sol_k = A_k \ B_k;
    F12_b(k, :) = [sol_k(1), sol_k(2)];
    F32_b(k, :) = [sol_k(3), sol_k(4)];
    F43_b(k, :) = [sol_k(5), sol_k(6)];
    F14_b(k)    = sol_k(7);
end

fig_fj = figure('Visible', 'off', 'Position', [100, 100, 850, 650]);
plot(F12_b(:, 1), F12_b(:, 2), 'b-', 'LineWidth', 2, 'DisplayName', 'F_{12} (Mancal O_2)'); hold on;
plot(F32_b(:, 1), F32_b(:, 2), 'm-', 'LineWidth', 2, 'DisplayName', 'F_{32} (Pino A)');
plot(F43_b(:, 1), F43_b(:, 2), 'r-', 'LineWidth', 2, 'DisplayName', 'F_{43} (Pino B)');
grid on; axis equal;
title('Item (b): Forças nas Juntas (\omega = 5000 rpm, \alpha = 0)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Componente F_x (N)'); ylabel('Componente F_y (N)');
legend('Location', 'northeast');
print(fig_fj, fullfile(assets_dir, 'grafico_forcas_juntas_5000rpm.png'), '-dpng', '-r300');

fig_fin = figure('Visible', 'off', 'Position', [100, 100, 850, 650]);
plot(Fin2_b(:, 1), Fin2_b(:, 2), 'b-', 'LineWidth', 2, 'DisplayName', 'F_{in,2} (Manivela - G_2)'); hold on;
plot(Fin3_b(:, 1), Fin3_b(:, 2), 'm-', 'LineWidth', 2, 'DisplayName', 'F_{in,3} (Biela - G_3)');
plot(Fin4_b, zeros(size(Fin4_b)), 'r-', 'LineWidth', 2.5, 'DisplayName', 'F_{in,4} (Pistão - B)');
grid on; axis equal;
title('Item (b): Forças Inerciais nos Centros de Gravidade (\omega = 5000 rpm)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('F_{in,x} (N)'); ylabel('F_{in,y} (N)');
legend('Location', 'northeast');
print(fig_fin, fullfile(assets_dir, 'grafico_forcas_inerciais_5000rpm.png'), '-dpng', '-r300');

fprintf('Todos os 5 diagramas DCL e os gráficos dinâmicos foram gerados com sucesso!\n');
