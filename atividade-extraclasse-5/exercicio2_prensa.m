% =========================================================================
% Atividade Extraclasse nº 5 - Exercício 2
% Projeto Cinemático e Dinâmico de Prensa Mecânica para Quebra de Baru
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

% -------------------------------------------------------------------------
% 1. Parâmetros e Síntese Dimensional do Mecanismo (Baseado na Atividade 3)
% -------------------------------------------------------------------------
% Pivôs fixos
O4 = [0.0; 0.0];            % Origem das coordenadas no pivô do balancim (mm)

% Comprimentos das barras da prensa (segundo dedução geométrica para curso h = 30 mm)
% Com delta_theta = 25°, 2*L4*(1 - cos(25°)) = 30 mm -> L4 = L5 = 160 mm
L4 = 160.0;                 % Elo 4: Balancim (mm)
L5 = 160.0;                 % Elo 5: Biela da prensa (mm)
delta_theta = deg2rad(25.0);

% Posições extremas do nó B (balancim):
% B2: limite direito no eixo Y (X = 0), theta4 = -90° = 270°
B2 = [0.0; -L4];
% B1: limite esquerdo defletido de delta_theta = 25°
B1 = [-L4 * sin(delta_theta); -L4 * cos(delta_theta)];

% Síntese Analítica Colinear de Norton (Cap. 5) com K = 2:
M_vec = B1 - B2;            % Vetor da corda de alternância
K = 2.0;
O2 = B2 + K * M_vec;        % [-135.24; -130.02] mm

% Síntese de duas posições para o quadrilátero de entrada (Manivela-Balancim):
r1 = norm(B1 - O2);         % Distância O2 até B1
r2 = norm(B2 - O2);         % Distância O2 até B2
L2 = abs(r2 - r1) / 2.0;    % Elo 2: Manivela (mm)
L3 = (r2 + r1) / 2.0;       % Elo 3: Acoplador (mm)
d_base = norm(O2 - O4);     % Elo 1: Distância entre mancais fixos (mm)

% Verificação da Condição de Grashof (Manivela-Balancim de Classe 1)
elos = sort([L2, L3, L4, d_base]);
s = elos(1); l = elos(4); p = elos(2); q = elos(3);
is_grashof = (s + l < p + q) && (s == L2);

% Propriedades de massa das barras (densidade linear constante mu = 2.0 kg/m)
% Seção de aço 16 mm x 16 mm, rho = 7850 kg/m^3 -> mu = 0.002 kg/mm
mu = 0.002;                 % kg/mm
m2 = mu * L2;               % kg
m3 = mu * L3;               % kg
m4 = mu * L4;               % kg
m5 = mu * L5;               % kg

% -------------------------------------------------------------------------
% 2. Condição Operacional: 50 castanhas por minuto (Item c)
% -------------------------------------------------------------------------
rpm = 50.0;
omega2 = (rpm * 2.0 * pi) / 60.0; % rad/s (aprox 5.236 rad/s)
alpha2 = 0.0;                     % rad/s^2 (velocidade constante de rotação)
T_ciclo = 60.0 / rpm;             % período de um ciclo (s)

fprintf('========================================================================\n');
fprintf('PROJETO CINEMÁTICO E DINÂMICO DA PRENSA MECÂNICA (BARU)\n');
fprintf('========================================================================\n');
fprintf('DIMENSÕES DAS BARRAS:\n');
fprintf('  L2 (Manivela):      %7.2f mm\n', L2);
fprintf('  L3 (Acoplador):     %7.2f mm\n', L3);
fprintf('  L4 (Balancim):      %7.2f mm\n', L4);
fprintf('  L5 (Biela Prensa):  %7.2f mm\n', L5);
fprintf('  d  (Distância base):%7.2f mm\n', d_base);
fprintf('POSIÇÃO DOS PIVÔS FIXOS:\n');
fprintf('  O2 = [%.2f, %.2f] mm | O4 = [%.2f, %.2f] mm\n', O2(1), O2(2), O4(1), O4(2));
fprintf('MASSAS DAS BARRAS (mu = %.3f kg/m):\n', mu*1e3);
fprintf('  m2 = %.4f kg (%.1f g)\n', m2, m2*1e3);
fprintf('  m3 = %.4f kg (%.1f g)\n', m3, m3*1e3);
fprintf('  m4 = %.4f kg (%.1f g)\n', m4, m4*1e3);
fprintf('  m5 = %.4f kg (%.1f g)\n', m5, m5*1e3);
fprintf('CLASSIFICAÇÃO DE GRASHOF: s+l = %.2f mm < p+q = %.2f mm -> Grashof: %d\n', s+l, p+q, is_grashof);
fprintf('VELOCIDADE DE ENTRADA:\n');
fprintf('  Produção = %.1f castanhas/min -> omega2 = %.4f rad/s (T = %.2f s)\n', rpm, omega2, T_ciclo);
fprintf('========================================================================\n\n');

% Diretório de salvamento
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 3. Varredura para Volta Completa da Manivela (0° a 360°)
% -------------------------------------------------------------------------
N = 360;
theta2_deg = linspace(0, 360, N);
theta3_arr = zeros(1, N);
theta4_arr = zeros(1, N);
theta5_arr = zeros(1, N);
y_O5_arr   = zeros(1, N);

% Acelerações angulares
alpha3_arr = zeros(1, N);
alpha4_arr = zeros(1, N);
alpha5_arr = zeros(1, N);

% Módulos das acelerações lineares dos CGs (em m/s^2)
aG2_mag = zeros(1, N);
aG3_mag = zeros(1, N);
aG4_mag = zeros(1, N);
aG5_mag = zeros(1, N);

% Forças inerciais (em Newtons)
Fin2 = zeros(1, N);
Fin3 = zeros(1, N);
Fin4 = zeros(1, N);
Fin5 = zeros(1, N);

% Chute inicial: alinhamento na posição estendida B2
phi2 = atan2(B2(2) - O2(2), B2(1) - O2(1));
x_curr = [phi2; -pi/2];
opt = optimset('Display', 'off');

for k = 1:N
    t2 = deg2rad(theta2_deg(k));
    
    % --- MALHA 1: MANIVELA-BALANCIM (POSIÇÃO) ---
    sis1 = @(x) [
        O2(1) + L2 * cos(t2) + L3 * cos(x(1)) - L4 * cos(x(2));
        O2(2) + L2 * sin(t2) + L3 * sin(x(1)) - L4 * sin(x(2))
    ];
    [x_sol, ~, info] = fsolve(sis1, x_curr, opt);
    x_curr = x_sol;
    t3 = x_sol(1);
    t4 = x_sol(2);
    
    theta3_arr(k) = t3;
    theta4_arr(k) = t4;
    
    % --- MALHA 1: VELOCIDADES ---
    J1 = [
       -L3 * sin(t3),  L4 * sin(t4);
        L3 * cos(t3), -L4 * cos(t4)
    ];
    b1_vel = [
        L2 * omega2 * sin(t2);
       -L2 * omega2 * cos(t2)
    ];
    w_sol = J1 \ b1_vel;
    w3 = w_sol(1);
    w4 = w_sol(2);
    
    % --- MALHA 1: ACELERAÇÕES ---
    b1_acc = [
        L2 * alpha2 * sin(t2) + L2 * (omega2^2) * cos(t2) + L3 * (w3^2) * cos(t3) - L4 * (w4^2) * cos(t4);
       -L2 * alpha2 * cos(t2) + L2 * (omega2^2) * sin(t2) + L3 * (w3^2) * sin(t3) - L4 * (w4^2) * sin(t4)
    ];
    al_sol = J1 \ b1_acc;
    al3 = al_sol(1);
    al4 = al_sol(2);
    
    alpha3_arr(k) = al3;
    alpha4_arr(k) = al4;
    
    % Ponto A (Manivela)
    aA = L2 * alpha2 * [-sin(t2); cos(t2)] - L2 * (omega2^2) * [cos(t2); sin(t2)];
    
    % Ponto B (Balancim)
    xB = L4 * cos(t4);
    yB = L4 * sin(t4);
    rB = [xB; yB];
    vB = L4 * w4 * [-sin(t4); cos(t4)];
    aB = L4 * al4 * [-sin(t4); cos(t4)] - L4 * (w4^2) * [cos(t4); sin(t4)];
    
    % Relativa BA
    aBA = L3 * al3 * [-sin(t3); cos(t3)] - L3 * (w3^2) * [cos(t3); sin(t3)];
    
    % --- MALHA 2: BIELA-PISTÃO (POSIÇÃO) ---
    % Pistão em O5 = (0, y_O5)
    % (0 - xB)^2 + (y_O5 - yB)^2 = L5^2 => y_O5 = yB - sqrt(L5^2 - xB^2)
    y_O5 = yB - sqrt(L5^2 - xB^2);
    y_O5_arr(k) = y_O5;
    
    % Ângulo do elo 5 (de B para O5)
    t5 = atan2(y_O5 - yB, -xB);
    theta5_arr(k) = t5;
    
    % --- MALHA 2: VELOCIDADE E ACELERAÇÃO ---
    w5 = vB(1) / (L5 * sin(t5));
    al5 = (aB(1) - L5 * (w5^2) * cos(t5)) / (L5 * sin(t5));
    alpha5_arr(k) = al5;
    
    a_O5B = L5 * al5 * [-sin(t5); cos(t5)] - L5 * (w5^2) * [cos(t5); sin(t5)];
    
    % --- ACELERAÇÃO DOS CENTROS DE GRAVIDADE (PONTOS MÉDIOS) ---
    % Elo 2: G2 no ponto médio de O2-A
    aG2 = 0.5 * aA;
    % Elo 3: G3 no ponto médio de A-B
    aG3 = aA + 0.5 * aBA;
    % Elo 4: G4 no ponto médio de O4-B
    aG4 = 0.5 * aB;
    % Elo 5: G5 no ponto médio de B-O5
    aG5 = aB + 0.5 * a_O5B;
    
    % Magnitudes das acelerações convertidas para m/s^2 (mm/s^2 * 1e-3)
    aG2_mag(k) = norm(aG2) * 1e-3;
    aG3_mag(k) = norm(aG3) * 1e-3;
    aG4_mag(k) = norm(aG4) * 1e-3;
    aG5_mag(k) = norm(aG5) * 1e-3;
    
    % Forças Inerciais de D'Alembert (F = m * aG em Newtons)
    Fin2(k) = m2 * aG2_mag(k);
    Fin3(k) = m3 * aG3_mag(k);
    Fin4(k) = m4 * aG4_mag(k);
    Fin5(k) = m5 * aG5_mag(k);
end

% Estatísticas de Curso e Forças
curso_obtido = max(y_O5_arr) - min(y_O5_arr);
fprintf('ANÁLISE DE POSIÇÃO:\n');
fprintf('  Faixa de theta4: [%.2f°, %.2f°] (Amplitude: %.2f°)\n', ...
    rad2deg(min(theta4_arr)), rad2deg(max(theta4_arr)), rad2deg(max(theta4_arr)-min(theta4_arr)));
fprintf('  Cota mínima y_O5: %7.2f mm (Ponto Morto Inferior / Quebra)\n', min(y_O5_arr));
fprintf('  Cota máxima y_O5: %7.2f mm (Ponto Morto Superior / Retração)\n', max(y_O5_arr));
fprintf('  CURSO TOTAL DO PISTÃO: %7.2f mm (Projetado: ~30.00 mm)\n', curso_obtido);
fprintf('------------------------------------------------------------------------\n');
fprintf('RESUMO DAS FORÇAS INERCIAIS (N):\n');
fprintf('  Barra 2 (Manivela):   Máx = %.4f N | Média = %.4f N\n', max(Fin2), mean(Fin2));
fprintf('  Barra 3 (Acoplador):  Máx = %.4f N | Média = %.4f N\n', max(Fin3), mean(Fin3));
fprintf('  Barra 4 (Balancim):   Máx = %.4f N | Média = %.4f N\n', max(Fin4), mean(Fin4));
fprintf('  Barra 5 (Biela P.):   Máx = %.4f N | Média = %.4f N\n', max(Fin5), mean(Fin5));
fprintf('========================================================================\n\n');

% -------------------------------------------------------------------------
% 4. Gráfico 1: Análise de Posição (Item b) - Curso e Ângulo do Balancim
% -------------------------------------------------------------------------
fig1 = figure('Name', 'Analise de Posicao da Prensa', 'NumberTitle', 'off', 'Position', [100, 100, 900, 650]);

subplot(2, 1, 1);
plot(theta2_deg, y_O5_arr, 'b-', 'LineWidth', 2.2); hold on;
plot([0, 360], [min(y_O5_arr), min(y_O5_arr)], 'r--', 'LineWidth', 1.0);
plot([0, 360], [max(y_O5_arr), max(y_O5_arr)], 'g--', 'LineWidth', 1.0);
grid on;
title('Item (b): Deslocamento Linear do Pistão O_5 ao Longo de uma Volta da Manivela', 'FontSize', 12);
xlabel('\theta_2 (graus)', 'FontSize', 10);
ylabel('Posição Vertical y_{O5} (mm)', 'FontSize', 10);
xlim([0, 360]);
legend({'y_{O5}(\theta_2)', ...
        sprintf('PMI (Quebra): %.2f mm', min(y_O5_arr)), ...
        sprintf('PMS (Retorno): %.2f mm (Curso: %.2f mm)', max(y_O5_arr), curso_obtido)}, ...
       'Location', 'east', 'FontSize', 9);

subplot(2, 1, 2);
plot(theta2_deg, rad2deg(theta4_arr), 'Color', [0.85, 0.35, 0.0], 'LineWidth', 2.2); hold on;
plot([0, 360], [-90, -90], 'k--', 'LineWidth', 1.0);
plot([0, 360], [-115, -115], 'm--', 'LineWidth', 1.0);
grid on;
title('Item (b): Ângulo de Oscilação do Elo Balancim (\theta_4) vs Entrada (\theta_2)', 'FontSize', 12);
xlabel('\theta_2 (graus)', 'FontSize', 10);
ylabel('\theta_4 (graus)', 'FontSize', 10);
xlim([0, 360]);
legend({'\theta_4(\theta_2)', ...
        'Limite Direito: \theta_4 = -90° (Posição B_2)', ...
        'Limite Esquerdo: \theta_4 = -115° (Posição B_1, \Delta\theta = 25°)'}, ...
       'Location', 'east', 'FontSize', 9);

caminho_fig1 = fullfile(assets_dir, 'ex2_posicoes_prensa.png');
print(fig1, caminho_fig1, '-dpng', '-r300');
fprintf('Figura 1 (Posições Prensa) salva em: %s\n', caminho_fig1);

% -------------------------------------------------------------------------
% 5. Gráfico 2: Esquema CAD das Duas Posições Extremas da Prensa (B1 e B2)
% -------------------------------------------------------------------------
fig2 = figure('Name', 'Esquema CAD - Posicoes Extremas da Prensa', 'NumberTitle', 'off', 'Position', [120, 120, 950, 700]);
hold on; grid on; axis equal;

% Linha de centro vertical da guia do pistão (X = 0)
plot([0, 0], [10, -350], 'c-.', 'LineWidth', 1.2);

% --- POSIÇÃO EXTREMA B2 (Alinhada verticalmente / Quebra de Baru / Ciano/Magenta) ---
plot([O4(1), B2(1)], [O4(2), B2(2)], 'm-', 'LineWidth', 3.0);
plot([B2(1), 0], [B2(2), -320], 'm-', 'LineWidth', 3.0);
% Pistão em B2
fill([-12, 12, 12, -12], [-320-10, -320-10, -320+10, -320+10], [0.9 0.7 0.9], 'EdgeColor', 'm', 'LineWidth', 1.5);

% --- POSIÇÃO EXTREMA B1 (Deflexão de 25° / Ponto Morto Superior / Azul) ---
plot([O4(1), B1(1)], [O4(2), B1(2)], 'b-', 'LineWidth', 3.0);
plot([B1(1), 0], [B1(2), -290.02], 'b-', 'LineWidth', 3.0);
% Pistão em B1
fill([-12, 12, 12, -12], [-290.02-10, -290.02-10, -290.02+10, -290.02+10], [0.7 0.8 1.0], 'EdgeColor', 'b', 'LineWidth', 1.5);

% Pivô O4 e pontos
plot(O4(1), O4(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 9);
plot(O2(1), O2(2), 'ks', 'MarkerFaceColor', [0.4 0.4 0.4], 'MarkerSize', 8);
plot(B2(1), B2(2), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8);
plot(B1(1), B1(2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8);

% Indicação do arco delta_theta = 25°
ang_arc = linspace(-pi/2 - delta_theta, -pi/2, 30);
plot(80*cos(ang_arc), 80*sin(ang_arc), 'r-', 'LineWidth', 1.5);
text(20, -75, '\Delta\theta = 25°', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'r');

% Rótulos e cotas
text(O4(1)+6, O4(2)+6, 'O_4 (0,0)', 'FontSize', 11, 'FontWeight', 'bold');
text(O2(1)-35, O2(2)+14, sprintf('O_2 (%.1f, %.1f)', O2(1), O2(2)), 'FontSize', 10, 'FontWeight', 'bold');
text(B2(1)+8, B2(2), 'B_2 (0, -160)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'm');
text(B1(1)-65, B1(2), 'B_1 (-67.6, -145)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'b');

% Cota do curso do pistão de 30 mm
plot([25, 25], [-320, -290.02], 'k-', 'LineWidth', 1.8);
plot([20, 30], [-320, -320], 'k-', 'LineWidth', 1.5);
plot([20, 30], [-290.02, -290.02], 'k-', 'LineWidth', 1.5);
text(32, -305, sprintf('Curso \\approx 30.0 mm\n(30.02 mm)'), 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');

% Seta da força de quebra (5000 N) no ponto O5
quiver(0, -345, 0, 20, 0, 'Color', [0.8 0 0], 'LineWidth', 3.0, 'MaxHeadSize', 1.5);
text(8, -338, 'F_{esmagamento} = 5000 N', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.8 0 0]);

title('Esquema CAD: Posições Extremas da Prensa (Curso de 30 mm do Pistão O_5)', 'FontSize', 12);
xlabel('Coordenada X (mm)', 'FontSize', 11);
ylabel('Coordenada Y (mm)', 'FontSize', 11);
xlim([-210, 80]);
ylim([-360, 25]);
legend({'Guia Vertical (X = 0)', ...
        'Posição B_2 (PMI / Quebra - Colinear)', '', '', ...
        'Posição B_1 (PMS / Retorno - Inclinada)', '', '', ...
        'Pivô O_4', 'Pivô O_2'}, ...
       'Location', 'northwest', 'FontSize', 9);

caminho_fig2 = fullfile(assets_dir, 'ex2_cad_posicoes_extremas.png');
print(fig2, caminho_fig2, '-dpng', '-r300');
fprintf('Figura 2 (CAD Extremos Prensa) salva em: %s\n', caminho_fig2);

% -------------------------------------------------------------------------
% 6. Gráfico 3: Aceleração dos Centros de Gravidade (Item d)
% -------------------------------------------------------------------------
fig3 = figure('Name', 'Aceleracoes dos CGs', 'NumberTitle', 'off', 'Position', [140, 140, 850, 550]);
plot(theta2_deg, aG2_mag, 'b-', 'LineWidth', 2.0); hold on;
plot(theta2_deg, aG3_mag, 'Color', [0.1 0.6 0.2], 'LineWidth', 2.0);
plot(theta2_deg, aG4_mag, 'r-', 'LineWidth', 2.0);
plot(theta2_deg, aG5_mag, 'm-', 'LineWidth', 2.0);
grid on;
title('Item (d): Aceleração dos Centros de Gravidade dos Elos (G_2, G_3, G_4, G_5)', 'FontSize', 12);
xlabel('\theta_2 (graus)', 'FontSize', 11);
ylabel('Aceleração Linear ||\vec{a}_{G}|| (m/s^2)', 'FontSize', 11);
xlim([0, 360]);
legend({'Elo 2: Manivela (G_2)', ...
        'Elo 3: Acoplador (G_3)', ...
        'Elo 4: Balancim (G_4)', ...
        'Elo 5: Biela da Prensa (G_5)'}, ...
       'Location', 'northeast', 'FontSize', 10);

caminho_fig3 = fullfile(assets_dir, 'ex2_aceleracoes_cg.png');
print(fig3, caminho_fig3, '-dpng', '-r300');
fprintf('Figura 3 (Acelerações CGs) salva em: %s\n', caminho_fig3);

% -------------------------------------------------------------------------
% 7. Gráfico 4: Forças Inerciais em cada Centro de Gravidade (Item e - Principal!)
% -------------------------------------------------------------------------
fig4 = figure('Name', 'Forcas Inerciais nos Centros de Gravidade', 'NumberTitle', 'off', 'Position', [160, 160, 900, 600]);
plot(theta2_deg, Fin2, 'b-', 'LineWidth', 2.2); hold on;
plot(theta2_deg, Fin3, 'Color', [0.1 0.6 0.2], 'LineWidth', 2.2);
plot(theta2_deg, Fin4, 'r-', 'LineWidth', 2.2);
plot(theta2_deg, Fin5, 'm-', 'LineWidth', 2.2);
grid on;
title('Item (e): Força Inercial de D''Alembert em cada Centro de Gravidade (Volta Completa)', 'FontSize', 12);
xlabel('\theta_2 (graus)', 'FontSize', 11);
ylabel('Força Inercial F_{in} = m_i \cdot ||\vec{a}_{Gi}|| (N)', 'FontSize', 11);
xlim([0, 360]);
legend({sprintf('Elo 2 (Manivela, m_2 = %.3f kg)', m2), ...
        sprintf('Elo 3 (Acoplador, m_3 = %.3f kg)', m3), ...
        sprintf('Elo 4 (Balancim, m_4 = %.3f kg)', m4), ...
        sprintf('Elo 5 (Biela Prensa, m_5 = %.3f kg)', m5)}, ...
       'Location', 'northeast', 'FontSize', 10);

caminho_fig4 = fullfile(assets_dir, 'ex2_forcas_inerciais.png');
print(fig4, caminho_fig4, '-dpng', '-r300');
fprintf('Figura 4 (Forças Inerciais) salva em: %s\n', caminho_fig4);

fprintf('\nTodos os cálculos e gráficos do Exercício 2 foram gerados com sucesso!\n');
