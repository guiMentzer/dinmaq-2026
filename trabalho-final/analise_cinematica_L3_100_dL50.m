% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Análise Cinemática Analítica Completa (Posição, Velocidade e Aceleração)
% Configuração Selecionada: Biela L3 = 100.00 mm, Ângulo entre Braços delta_L = 50°
% Regime Temporal Manual: Curva Senoidal Simples (Harmônica)
%   - Descida (PMS -> PMI): T1 = 1.0 s
%   - Subida  (PMI -> PMS): T2 = 2.0 s  (Ciclo total T = 3.0 s | 20 ciclos/min)
%
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

if isempty(available_graphics_toolkits())
    try
        register_graphics_toolkit('qt');
        graphics_toolkit('qt');
    catch
    end
end

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Síntese Dimensional Exata para L3 = 100.00 mm e delta_L = 50.0°
% -------------------------------------------------------------------------
h_curso    = 30.0;        % Curso útil total da navalha (mm)
delta_q    = 10.0;        % Curso efetivo de cisalhamento do baru (mm)
F_max      = 5000.0;      % Força máxima de corte por cisalhamento (N)
dt_deg     = 30.0;        % Oscilação do balancim L4 (graus)
dt         = deg2rad(dt_deg);

L4 = h_curso / (2.0 * (1.0 - cos(dt))); % 111.9615 mm
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4];                       % PMI (x = 0)
B1 = [-L4 * sin(dt); -L4 * cos(dt)];   % PMS (defletido 30° à esquerda)

y_pmi     = -2.0 * L4;                 % -223.9230 mm
y_pms     = -2.0 * L4 * cos(dt);       % -193.9230 mm
y_contato = y_pmi + delta_q;           % -213.9230 mm

L2         = 70.0;                     % Braço curto da alavanca em L (mm)
L3_alvo    = 100.0;                    % Tamanho fixado da biela AB (mm)
delta_L    = 50.0;                     % Ângulo entre braços (gamma_L = 130°)
dth_alav   = 60.0;                     % Arco ergonômico da empunhadura (+30° -> -30°)
th_pms_deg = 0.5 * dth_alav + delta_L; % 80.0°
th_pmi_deg = th_pms_deg - dth_alav;    % 20.0°
th_pms     = deg2rad(th_pms_deg);
th_pmi     = deg2rad(th_pmi_deg);

P1 = B1 - L2 * [cos(th_pms); sin(th_pms)];
P2 = B2 - L2 * [cos(th_pmi); sin(th_pmi)];
dP = P2 - P1;
half_dP = 0.5 * norm(dP);
midP = 0.5 * (P1 + P2);
nP = [-dP(2); dP(1)] / norm(dP);
if nP(1) < 0, nP = -nP; end

% s_offset exato que produz L3 = 100.00 mm
s_offset = sqrt(L3_alvo^2 - half_dP^2);
O2 = midP + s_offset * nP;
L3 = norm(P2 - O2);                    % 100.0000 mm
d_base = norm(O2 - O4);

mu_guia    = 0.10;
eta_juntas = 0.96;

% -------------------------------------------------------------------------
% 2. Lei Temporal Senoidal Simples (1 s descida + 2 s subida = 3 s/ciclo)
% -------------------------------------------------------------------------
T1 = 1.0;                              % Descida PMS -> PMI (s)
T2 = 2.0;                              % Subida  PMI -> PMS (s)
T_ciclo = T1 + T2;                     % 3.0 s (20 ciclos/min)
N = 901;
t = linspace(0.0, T_ciclo, N);

th2_rad = zeros(1, N);
w2      = zeros(1, N);
al2     = zeros(1, N);

dth_rad = deg2rad(dth_alav);
for k = 1:N
    tk = t(k);
    if tk <= T1
        % Descida harmônica: theta2 varia de th_pms -> th_pmi
        th2_rad(k) = th_pms - 0.5 * dth_rad * (1.0 - cos(pi * tk / T1));
        w2(k)      = -0.5 * dth_rad * (pi / T1) * sin(pi * tk / T1);
        al2(k)     = -0.5 * dth_rad * (pi / T1)^2 * cos(pi * tk / T1);
    else
        % Subida harmônica: theta2 varia de th_pmi -> th_pms
        tau = tk - T1;
        th2_rad(k) = th_pmi + 0.5 * dth_rad * (1.0 - cos(pi * tau / T2));
        w2(k)      =  0.5 * dth_rad * (pi / T2) * sin(pi * tau / T2);
        al2(k)     =  0.5 * dth_rad * (pi / T2)^2 * cos(pi * tau / T2);
    end
end
th2_deg = rad2deg(th2_rad);

% -------------------------------------------------------------------------
% 3. Cinemática Analítica Exata (Posição, Velocidade e Aceleração)
% -------------------------------------------------------------------------
Ax = O2(1) + L2 * cos(th2_rad);
Ay = O2(2) + L2 * sin(th2_rad);
dA = hypot(Ax, Ay);

a_c = (L4^2 - L3^2 + dA.^2) ./ (2.0 * dA);
h_c = sqrt(max(0.0, L4^2 - a_c.^2));

x2_1 = a_c(1) * Ax(1) / dA(1);
y2_1 = a_c(1) * Ay(1) / dA(1);
Bp = [x2_1 + h_c(1)*(-Ay(1))/dA(1); y2_1 + h_c(1)*(Ax(1))/dA(1)];
Bm = [x2_1 - h_c(1)*(-Ay(1))/dA(1); y2_1 - h_c(1)*(Ax(1))/dA(1)];
sgn = (norm(Bp - B1) < norm(Bm - B1)) * 2 - 1;

Bx = a_c .* Ax ./ dA + sgn * h_c .* (-Ay) ./ dA;
By = a_c .* Ay ./ dA + sgn * h_c .* (Ax)  ./ dA;

th3_rad = atan2(By - Ay, Bx - Ax);
th4_rad = atan2(By, Bx);
y_O5    = By - sqrt(max(0.0, L5^2 - Bx.^2));
th5_rad = atan2(y_O5 - By, -Bx);
beta5   = asin(min(1.0, abs(Bx) / L5));

da = mod(abs(th4_rad - th3_rad), 2*pi);
da(da > pi) = 2*pi - da(da > pi);
mu_deg = rad2deg(da);

% Vetores de estado cinemático (em mm, mm/s, mm/s^2 e depois convertidos p/ SI)
w3 = zeros(1, N); w4 = zeros(1, N); w5 = zeros(1, N);
al3 = zeros(1, N); al4 = zeros(1, N); al5 = zeros(1, N);

vO5_y = zeros(1, N); aO5_y = zeros(1, N);
vG2_mag = zeros(1, N); vG3_mag = zeros(1, N); vG4_mag = zeros(1, N); vG5_mag = zeros(1, N);
aG2_mag = zeros(1, N); aG3_mag = zeros(1, N); aG4_mag = zeros(1, N); aG5_mag = zeros(1, N);

for k = 1:N
    t2 = th2_rad(k); t3 = th3_rad(k); t4 = th4_rad(k); t5 = th5_rad(k);

    % Malha 1: Velocidades angulares [w3; w4]
    J1 = [-L3 * sin(t3),  L4 * sin(t4);
           L3 * cos(t3), -L4 * cos(t4)];
    b_vel = [ L2 * w2(k) * sin(t2);
             -L2 * w2(k) * cos(t2)];
    w_sol = J1 \ b_vel;
    w3(k) = w_sol(1);
    w4(k) = w_sol(2);

    % Malha 1: Acelerações angulares [al3; al4]
    b_acc = [ L2 * al2(k) * sin(t2) + L2 * w2(k)^2 * cos(t2) + L3 * w3(k)^2 * cos(t3) - L4 * w4(k)^2 * cos(t4);
             -L2 * al2(k) * cos(t2) + L2 * w2(k)^2 * sin(t2) + L3 * w3(k)^2 * sin(t3) - L4 * w4(k)^2 * sin(t4)];
    al_sol = J1 \ b_acc;
    al3(k) = al_sol(1);
    al4(k) = al_sol(2);

    % Cinemática dos pinos A e B (mm/s e mm/s^2)
    vA = L2 * w2(k) * [-sin(t2); cos(t2)];
    aA = L2 * al2(k) * [-sin(t2); cos(t2)] - L2 * w2(k)^2 * [cos(t2); sin(t2)];

    vB = L4 * w4(k) * [-sin(t4); cos(t4)];
    aB = L4 * al4(k) * [-sin(t4); cos(t4)] - L4 * w4(k)^2 * [cos(t4); sin(t4)];

    % Malha 2: Biela da prensa L5 e pistão O5 (x_O5 = 0)
    w5(k)  = vB(1) / (L5 * sin(t5));
    al5(k) = (aB(1) - L5 * w5(k)^2 * cos(t5)) / (L5 * sin(t5));

    vO5 = [0.0; vB(2) + L5 * w5(k) * cos(t5)];
    aO5 = [0.0; aB(2) + L5 * al5(k) * cos(t5) - L5 * w5(k)^2 * sin(t5)];

    vO5_y(k) = vO5(2) * 1e-3; % m/s
    aO5_y(k) = aO5(2) * 1e-3; % m/s^2

    % Centros de gravidade (pontos médios das barras 2, 3, 4 e 5) em m/s e m/s^2
    vG2 = 0.5 * vA;
    vG3 = 0.5 * (vA + vB);
    vG4 = 0.5 * vB;
    vG5 = 0.5 * (vB + vO5);

    aG2 = 0.5 * aA;
    aG3 = 0.5 * (aA + aB);
    aG4 = 0.5 * aB;
    aG5 = 0.5 * (aB + aO5);

    vG2_mag(k) = norm(vG2) * 1e-3;
    vG3_mag(k) = norm(vG3) * 1e-3;
    vG4_mag(k) = norm(vG4) * 1e-3;
    vG5_mag(k) = norm(vG5) * 1e-3;

    aG2_mag(k) = norm(aG2) * 1e-3;
    aG3_mag(k) = norm(aG3) * 1e-3;
    aG4_mag(k) = norm(aG4) * 1e-3;
    aG5_mag(k) = norm(aG5) * 1e-3;
end

% Torque quase-estático na descida (t <= 1.0 s) para referência da alavanca
idx_desc = find(t <= T1);
idx_q_desc = find((t <= T1) & (y_O5 <= y_contato));
hp_desc = abs(vO5_y(idx_desc)) ./ (abs(w2(idx_desc)) + 1e-12);
eta_desc = (1.0 - mu_guia * tan(beta5(idx_desc))) * eta_juntas;
s_pen_desc = max(0.0, (y_contato - y_O5(idx_desc)) / delta_q);
T_lin_desc = (F_max * s_pen_desc .* hp_desc) ./ eta_desc;
T_bio_desc = (F_max * (s_pen_desc.^0.4) .* hp_desc) ./ eta_desc;

% -------------------------------------------------------------------------
% 4. Impressão do Relatório Numérico no Terminal
% -------------------------------------------------------------------------
fprintf('====================================================================================\n');
fprintf('ANÁLISE CINEMÁTICA COMPLETA: L3 = %.2f mm | delta_L = %.1f° (gamma_L = %.1f°)\n', L3, delta_L, 180-delta_L);
fprintf('====================================================================================\n');
fprintf('Geometria Sintetizada:\n');
fprintf('  O4 = [0.00, 0.00] mm | L4 = L5 = %.4f mm | Dtheta4 = %.1f°\n', L4, dt_deg);
fprintf('  P1 = [%.2f, %.2f] mm | P2 = [%.2f, %.2f] mm | ||P2-P1||/2 = %.4f mm\n', P1(1), P1(2), P2(1), P2(2), half_dP);
fprintf('  s_offset = %.4f mm | O2 = [%.2f, %.2f] mm | d(O2,O4) = %.2f mm\n', s_offset, O2(1), O2(2), d_base);
fprintf('  L2 = %.2f mm (theta2: %.1f° -> %.1f°) | L3 = %.4f mm\n', L2, th_pms_deg, th_pmi_deg, L3);
fprintf('  Curso y_O5: %.2f mm (PMS) -> %.2f mm (PMI) | h = %.2f mm\n', max(y_O5), min(y_O5), max(y_O5)-min(y_O5));
fprintf('  Transmissão mu: min = %.2f° | med = %.2f° | quebra_med = %.2f° | PMI = %.2f°\n', ...
    min(mu_deg), mean(mu_deg), mean(mu_deg(idx_q_desc)), mu_deg(idx_desc(end)));
fprintf('\nRegime Senoidal (1.0 s descida + 2.0 s subida = 3.0 s/ciclo):\n');
fprintf('  Entrada: |w2|_max = %.4f rad/s (desc) / %.4f rad/s (sub) | |al2|_max = %.4f rad/s^2\n', ...
    max(abs(w2(idx_desc))), max(abs(w2(t > T1))), max(abs(al2)));
fprintf('  Velocidades angulares max (rad/s): |w3|=%.4f, |w4|=%.4f, |w5|=%.4f\n', max(abs(w3)), max(abs(w4)), max(abs(w5)));
fprintf('  Acelerações angulares max (rad/s^2): |al3|=%.4f, |al4|=%.4f, |al5|=%.4f\n', max(abs(al3)), max(abs(al4)), max(abs(al5)));
fprintf('  Pistão O5: |v_O5|_max = %.4f m/s (%.1f mm/s) | |a_O5|_max = %.4f m/s^2\n', max(abs(vO5_y)), max(abs(vO5_y))*1e3, max(abs(aO5_y)));
fprintf('  CGs v_max (m/s):   G2=%.4f | G3=%.4f | G4=%.4f | G5=%.4f\n', max(vG2_mag), max(vG3_mag), max(vG4_mag), max(vG5_mag));
fprintf('  CGs a_max (m/s^2): G2=%.4f | G3=%.4f | G4=%.4f | G5=%.4f\n', max(aG2_mag), max(aG3_mag), max(aG4_mag), max(aG5_mag));
fprintf('  Torque pico (descida): T_lin = %.2f N.m (L60N = %.2f m) | T_bio = %.2f N.m (L60N = %.2f m)\n', ...
    max(T_lin_desc), max(T_lin_desc)/60.0, max(T_bio_desc), max(T_bio_desc)/60.0);
fprintf('====================================================================================\n');

th3_deg = rad2deg(unwrap(th3_rad));
th4_deg = rad2deg(unwrap(th4_rad));
th5_deg = rad2deg(unwrap(th5_rad));

% Pontos-chave temporais para tabela do relatório
t_chk = [0.00, 0.25, 0.50, 0.75, 1.00, 1.50, 2.00, 2.50, 3.00];
fprintf('\nTabela Temporal (Instantes-Chave do Ciclo Senoidal):\n');
fprintf('  t(s) | th2(°) | th3(°) | th4(°) | y_O5(mm) | mu(°)  | v_O5(mm/s) | a_O5(mm/s^2) | |vG3|(mm/s) | |aG3|(mm/s^2)\n');
for tc = t_chk
    [~, ic] = min(abs(t - tc));
    fprintf('  %4.2f | %6.2f | %6.2f | %6.2f | %8.2f | %6.2f | %10.2f | %12.2f | %10.2f | %10.2f\n', ...
        t(ic), th2_deg(ic), th3_deg(ic), th4_deg(ic), y_O5(ic), mu_deg(ic), ...
        vO5_y(ic)*1e3, aO5_y(ic)*1e3, vG3_mag(ic)*1e3, aG3_mag(ic)*1e3);
end

% -------------------------------------------------------------------------
% 5. Geração dos Gráficos no Octave (300 DPI)
% -------------------------------------------------------------------------
if isempty(available_graphics_toolkits())
    error('Nenhum toolkit gráfico Octave disponível neste ambiente headless.');
end

% FIGURA 1: Posição e Ângulos (O5, theta3/theta4/theta5, mu)
fig1 = figure('Visible', 'off', 'Position', [40, 40, 1440, 860], 'Color', 'w');

subplot(2, 2, 1);
hold on; grid on;
fill([0, T1, T1, 0], [-228, -228, -190, -190], [0.92 0.96 1.00], 'EdgeColor', 'none');
fill([T1, T_ciclo, T_ciclo, T1], [-228, -228, -190, -190], [0.95 0.98 0.94], 'EdgeColor', 'none');
plot(t, y_O5, 'Color', [0.00 0.40 0.85], 'LineWidth', 2.4);
plot([0, T_ciclo], [y_contato, y_contato], 'r--', 'LineWidth', 1.4);
plot([T1, T1], [-228, -190], 'k:', 'LineWidth', 1.3);
title('1. Posição Vertical da Navalha y_{O5}(t)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('y_{O5} (mm)', 'FontSize', 9.2);
xlim([0, T_ciclo]); ylim([-228, -190]);
legend({'Descida (1,0 s)', 'Subida (2,0 s)', 'y_{O5}(t)', 'Início Corte (-213,9 mm)'}, 'Location', 'southeast', 'FontSize', 7.8);

subplot(2, 2, 2);
hold on; grid on;
plot(t, th2_deg, 'Color', [0.80 0.15 0.15], 'LineWidth', 2.2);
plot(t, th3_deg, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.2);
plot(t, th4_deg, 'Color', [0.10 0.60 0.25], 'LineWidth', 2.2);
plot(t, th5_deg, 'Color', [0.55 0.25 0.70], 'LineWidth', 2.0, 'LineStyle', '--');
plot([T1, T1], [-210, 110], 'k:', 'LineWidth', 1.2);
title('2. Posições Angulares dos Elos \theta_2, \theta_3, \theta_4, \theta_5', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('Ângulo (graus)', 'FontSize', 9.2);
xlim([0, T_ciclo]); ylim([-210, 110]);
legend({'\theta_2 (Alavanca)', '\theta_3 (Biela L_3)', '\theta_4 (Balancim L_4)', '\theta_5 (Biela Prensa)'}, 'Location', 'east', 'FontSize', 7.8);

subplot(2, 2, 3);
hold on; grid on;
fill([0, T_ciclo, T_ciclo, 0], [40, 40, 140, 140], [0.88 0.96 0.88], 'EdgeColor', 'none');
plot(t, mu_deg, 'Color', [0.05 0.50 0.20], 'LineWidth', 2.5);
plot(t(idx_q_desc), mu_deg(idx_q_desc), 'Color', [0.85 0.15 0.10], 'LineWidth', 3.2);
plot([0, T_ciclo], [40, 40], 'r--', 'LineWidth', 1.3);
plot([0, T_ciclo], [90, 90], 'k:', 'LineWidth', 1.2);
title(sprintf('3. Ângulo de Transmissão \\mu(t)  [mín=%.1f°, quebra=%.1f°, PMI=%.1f°]', min(mu_deg), mean(mu_deg(idx_q_desc)), mu_deg(idx_desc(end))), 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('\mu (graus)', 'FontSize', 9.2);
xlim([0, T_ciclo]); ylim([30, 145]);
legend({'Faixa Norton [40°, 140°]', '\mu(t) Ciclo', 'Zona de Quebra (10 mm)'}, 'Location', 'northeast', 'FontSize', 7.8);

subplot(2, 2, 4);
hold on; grid on; axis equal;
ang_h_pms = th_pms - deg2rad(delta_L);
ang_h_pmi = th_pmi - deg2rad(delta_L);
P_h_pms = O2 + 120.0 * [cos(ang_h_pms); sin(ang_h_pms)];
P_h_pmi = O2 + 120.0 * [cos(ang_h_pmi); sin(ang_h_pmi)];
plot([O4(1), B1(1)], [O4(2), B1(2)], 'Color', [0.45 0.75 0.50], 'LineStyle', '--', 'LineWidth', 2.0);
plot([O4(1), B2(1)], [O4(2), B2(2)], 'Color', [0.10 0.60 0.25], 'LineWidth', 3.5);
plot([B1(1), 0], [B1(2), y_pms], 'Color', [0.85 0.45 0.45], 'LineStyle', '--', 'LineWidth', 2.0);
plot([B2(1), 0], [B2(2), y_pmi], 'Color', [0.78 0.15 0.15], 'LineWidth', 3.2);
plot([P_h_pms(1), O2(1), Ax(1), B1(1)], [P_h_pms(2), O2(2), Ay(1), B1(2)], 'Color', [0.45 0.55 0.80], 'LineStyle', '--', 'LineWidth', 2.0);
plot([P_h_pmi(1), O2(1), Ax(idx_desc(end)), B2(1)], [P_h_pmi(2), O2(2), Ay(idx_desc(end)), B2(2)], 'Color', [0.10 0.30 0.80], 'LineWidth', 3.2);
plot(O4(1), O4(2), 'ko', 'MarkerFaceColor', [0.1 0.6 0.25], 'MarkerSize', 8);
plot(O2(1), O2(2), 'ko', 'MarkerFaceColor', [0.85 0.12 0.12], 'MarkerSize', 8);
text(6, 4, 'O_4', 'FontSize', 8.5, 'FontWeight', 'bold');
text(O2(1)+6, O2(2)-12, sprintf('O_2 (%.1f, %.1f)', O2(1), O2(2)), 'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.7 0.1 0.1]);
title(sprintf('4. Geometria Sintetizada (L_3=%.1f mm, \\delta_L=50°, s=%.1f mm)', L3, s_offset), 'FontSize', 10.2, 'FontWeight', 'bold');
xlabel('X (mm)', 'FontSize', 9.2); ylabel('Y (mm)', 'FontSize', 9.2);
xlim([-85, 165]); ylim([-245, 20]);

out1 = fullfile(assets_dir, 'analise_L3_100_dL50_posicoes.png');
print(fig1, out1, '-dpng', '-r300');
close(fig1);

% FIGURA 2: Velocidades (Angulares, Pistão O5 e CGs)
fig2 = figure('Visible', 'off', 'Position', [50, 50, 1440, 860], 'Color', 'w');

subplot(2, 2, 1);
hold on; grid on;
plot(t, w2, 'Color', [0.80 0.15 0.15], 'LineWidth', 2.4);
plot(t, w3, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.2);
plot(t, w4, 'Color', [0.10 0.60 0.25], 'LineWidth', 2.2);
plot(t, w5, 'Color', [0.55 0.25 0.70], 'LineWidth', 2.0, 'LineStyle', '--');
plot([T1, T1], [-3, 3], 'k:', 'LineWidth', 1.2);
title('1. Velocidades Angulares dos Elos \omega_2, \omega_3, \omega_4, \omega_5', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('\omega (rad/s)', 'FontSize', 9.2);
xlim([0, T_ciclo]);
legend({'\omega_2 (Entrada)', '\omega_3 (Biela L_3)', '\omega_4 (Balancim)', '\omega_5 (Biela Prensa)'}, 'Location', 'northeast', 'FontSize', 7.8);

subplot(2, 2, 2);
hold on; grid on;
plot(t, vO5_y * 1e3, 'Color', [0.00 0.40 0.85], 'LineWidth', 2.5);
plot([0, T_ciclo], [0, 0], 'k--', 'LineWidth', 1.1);
plot([T1, T1], [-90, 50], 'k:', 'LineWidth', 1.2);
title('2. Velocidade Linear Vertical do Pistão v_{O5,y}(t)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('v_{O5,y} (mm/s)', 'FontSize', 9.2);
xlim([0, T_ciclo]);

subplot(2, 2, 3);
hold on; grid on;
plot(t, vG2_mag * 1e3, 'Color', [0.80 0.15 0.15], 'LineWidth', 2.2);
plot(t, vG3_mag * 1e3, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.2);
plot(t, vG4_mag * 1e3, 'Color', [0.10 0.60 0.25], 'LineWidth', 2.2);
plot(t, vG5_mag * 1e3, 'Color', [0.55 0.25 0.70], 'LineWidth', 2.0, 'LineStyle', '--');
title('3. Módulo da Velocidade dos Centros de Gravidade |v_{Gi}|', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('|v_G| (mm/s)', 'FontSize', 9.2);
xlim([0, T_ciclo]);
legend({'|v_{G2}|', '|v_{G3}|', '|v_{G4}|', '|v_{G5}|'}, 'Location', 'northeast', 'FontSize', 7.8);

subplot(2, 2, 4);
hold on; grid on;
plot(y_O5(idx_desc), vO5_y(idx_desc) * 1e3, 'Color', [0.85 0.20 0.15], 'LineWidth', 2.4);
plot(y_O5(t > T1), vO5_y(t > T1) * 1e3, 'Color', [0.10 0.55 0.25], 'LineWidth', 2.4);
title('4. Plano de Fase do Pistão: v_{O5,y} vs. Posição y_{O5}', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('y_{O5} (mm)', 'FontSize', 9.2); ylabel('v_{O5,y} (mm/s)', 'FontSize', 9.2);
legend({'Descida (1,0 s)', 'Subida (2,0 s)'}, 'Location', 'southeast', 'FontSize', 8.0);

out2 = fullfile(assets_dir, 'analise_L3_100_dL50_velocidades.png');
print(fig2, out2, '-dpng', '-r300');
close(fig2);

% FIGURA 3: Acelerações (Angulares, Pistão O5 e CGs)
fig3 = figure('Visible', 'off', 'Position', [60, 60, 1440, 860], 'Color', 'w');

subplot(2, 2, 1);
hold on; grid on;
plot(t, al2, 'Color', [0.80 0.15 0.15], 'LineWidth', 2.4);
plot(t, al3, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.2);
plot(t, al4, 'Color', [0.10 0.60 0.25], 'LineWidth', 2.2);
plot(t, al5, 'Color', [0.55 0.25 0.70], 'LineWidth', 2.0, 'LineStyle', '--');
plot([T1, T1], [-10, 10], 'k:', 'LineWidth', 1.2);
title('1. Acelerações Angulares dos Elos \alpha_2, \alpha_3, \alpha_4, \alpha_5', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('\alpha (rad/s^2)', 'FontSize', 9.2);
xlim([0, T_ciclo]);
legend({'\alpha_2 (Entrada)', '\alpha_3 (Biela L_3)', '\alpha_4 (Balancim)', '\alpha_5 (Biela Prensa)'}, 'Location', 'southeast', 'FontSize', 7.8);

subplot(2, 2, 2);
hold on; grid on;
plot(t, aO5_y * 1e3, 'Color', [0.80 0.15 0.15], 'LineWidth', 2.5);
plot([0, T_ciclo], [0, 0], 'k--', 'LineWidth', 1.1);
plot([T1, T1], [-500, 500], 'k:', 'LineWidth', 1.2);
title('2. Aceleração Linear Vertical do Pistão a_{O5,y}(t)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('a_{O5,y} (mm/s^2)', 'FontSize', 9.2);
xlim([0, T_ciclo]);

subplot(2, 2, 3);
hold on; grid on;
plot(t, aG2_mag * 1e3, 'Color', [0.80 0.15 0.15], 'LineWidth', 2.2);
plot(t, aG3_mag * 1e3, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.2);
plot(t, aG4_mag * 1e3, 'Color', [0.10 0.60 0.25], 'LineWidth', 2.2);
plot(t, aG5_mag * 1e3, 'Color', [0.55 0.25 0.70], 'LineWidth', 2.0, 'LineStyle', '--');
title('3. Módulo da Aceleração dos Centros de Gravidade |a_{Gi}|', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('|a_G| (mm/s^2)', 'FontSize', 9.2);
xlim([0, T_ciclo]);
legend({'|a_{G2}|', '|a_{G3}|', '|a_{G4}|', '|a_{G5}|'}, 'Location', 'northeast', 'FontSize', 7.8);

subplot(2, 2, 4);
hold on; grid on;
plot(t(idx_desc), T_lin_desc, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.4);
plot(t(idx_desc), T_bio_desc, 'Color', [0.85 0.35 0.00], 'LineStyle', '-.', 'LineWidth', 2.4);
title('4. Torque Quase-Estático na Alavanca Durante a Descida (0 \rightarrow 1 s)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (s)', 'FontSize', 9.2); ylabel('Torque T_{alav} (N\cdotm)', 'FontSize', 9.2);
xlim([0, T1]);
legend({sprintf('Linear (Pico = %.1f N\\cdotm)', max(T_lin_desc)), ...
        sprintf('Biomaterial s^{0.4} (Pico = %.1f N\\cdotm)', max(T_bio_desc))}, 'Location', 'northwest', 'FontSize', 8.0);

out3 = fullfile(assets_dir, 'analise_L3_100_dL50_aceleracoes.png');
print(fig3, out3, '-dpng', '-r300');
close(fig3);

fprintf('Figuras salvas em:\n  %s\n  %s\n  %s\n', out1, out2, out3);
