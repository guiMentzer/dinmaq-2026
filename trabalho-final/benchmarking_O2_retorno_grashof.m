% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Benchmarking de Posições de O2: Ângulo de Transmissão, Tempo de Retorno
% e Determinação da Região de Grashof Classe II
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

% Diretório de salvamento
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Parâmetros Invariantes do Mecanismo da Prensa
% -------------------------------------------------------------------------
L4 = 160.0;              % Comprimento do balancim (mm)
L5 = 160.0;              % Comprimento da biela da prensa (mm)
Delta_theta = deg2rad(25.0); % Amplitude de oscilação do balancim (25°)

% Posições extremas da junta B:
% B2: limite inferior (PMI da prensa, alinhamento vertical x=0, theta4 = -90°)
B2 = [0.0; -L4];
% B1: limite superior (PMS da prensa, retraído de 25°, theta4 = -115°)
B1 = [-L4 * sin(Delta_theta); -L4 * cos(Delta_theta)];

corda_M = norm(B1 - B2); % Comprimento da corda de alternância (69.26 mm)
rpm = 50.0;
T_ciclo = 60.0 / rpm;    % Período de rotação da manivela = 1.20 s
omega2 = (2 * pi * rpm) / 60.0; % 5.236 rad/s

% -------------------------------------------------------------------------
% 2. Definição das Posições de O2 para Benchmarking
% -------------------------------------------------------------------------
% Cada linha: {Nome, [x; y], Cor, Estilo_linha}
casos_bench = {
    '1. Colinear K=2 (Simétrico \alpha=0°)', ...
    [-135.24; -130.02], [0.15 0.15 0.15], '-';
    
    '2. Solução Alt Clássica (Ativ. 5)', ...
    [-138.61; -150.00], [0.85 0.20 0.20], '--';
    
    '3. Solução Adotada (Ativ. 5)', ...
    [-180.00;  -70.00], [0.10 0.65 0.25], '-.';
    
    '4. Trade-off Equilibrado (Recomendado)', ...
    [-125.00;  -95.00], [0.00 0.45 0.90], '-';
    
    '5. Máximo Retorno Seguro (\mu_{min}\approx 40°)', ...
    [-100.00; -100.00], [0.85 0.45 0.00], ':'
};

num_casos = size(casos_bench, 1);
metricas = struct();

fprintf('========================================================================================\n');
fprintf('BENCHMARKING DE POSIÇÕES DE O2 — PRENSA DE BARU\n');
fprintf('========================================================================================\n');
fprintf('%-28s | O2 [x, y] (mm) | alpha   | T_ret (s) [%%] | mu_min - mu_max | L2 (mm) | L3 (mm) | d (mm)\n', 'Configuração');
fprintf('----------------------------------------------------------------------------------------\n');

for c = 1:num_casos
    O2 = casos_bench{c, 2};
    r1 = norm(B1 - O2);
    r2 = norm(B2 - O2);
    L2 = (r2 - r1) / 2.0;
    L3 = (r2 + r1) / 2.0;
    d  = norm(O2);
    
    v1 = B1 - O2; v2 = B2 - O2;
    cos_a = dot(v1, v2) / (r1 * r2);
    cos_a = max(-1.0, min(1.0, cos_a));
    alpha = rad2deg(acos(cos_a));
    
    t_ret = T_ciclo * (180.0 + alpha) / 360.0;
    pct_ret = (180.0 + alpha) / 3.6;
    
    % Extremos teóricos de mu pela lei dos cossenos
    c1 = (L3^2 + L4^2 - (d - L2)^2) / (2 * L3 * L4);
    c2 = (L3^2 + L4^2 - (d + L2)^2) / (2 * L3 * L4);
    ang1 = rad2deg(acos(max(-1, min(1, c1))));
    ang2 = rad2deg(acos(max(-1, min(1, c2))));
    mu_min = min(ang1, ang2);
    mu_max = max(ang1, ang2);
    
    metricas(c).nome = casos_bench{c, 1};
    metricas(c).O2 = O2;
    metricas(c).L2 = L2;
    metricas(c).L3 = L3;
    metricas(c).d  = d;
    metricas(c).alpha = alpha;
    metricas(c).t_ret = t_ret;
    metricas(c).pct_ret = pct_ret;
    metricas(c).mu_min = mu_min;
    metricas(c).mu_max = mu_max;
    metricas(c).desvio_mu = max(abs(mu_min - 90), abs(mu_max - 90));
    
    fprintf('%-28s | [%6.1f, %6.1f] | %5.2f°  | %5.3fs [%4.1f%%] | %5.1f° - %5.1f°  | %7.2f | %7.2f | %6.2f\n', ...
        metricas(c).nome, O2(1), O2(2), alpha, t_ret, pct_ret, mu_min, mu_max, L2, L3, d);
end
fprintf('========================================================================================\n\n');

% -------------------------------------------------------------------------
% 3. Simulação Cinemática no Domínio da Rotação da Manivela (360°)
% -------------------------------------------------------------------------
N = 360;
theta2_deg = linspace(0, 360, N);
mu_trajectories = zeros(num_casos, N);
y_O5_trajectories = zeros(num_casos, N);
opt = optimset('Display', 'off');

for c = 1:num_casos
    O2 = metricas(c).O2;
    L2 = metricas(c).L2;
    L3 = metricas(c).L3;
    
    phi2 = atan2(B2(2) - O2(2), B2(1) - O2(1));
    x_curr = [phi2; -pi/2];
    
    for k = 1:N
        t2 = deg2rad(theta2_deg(k));
        sis = @(x) [
            O2(1) + L2 * cos(t2) + L3 * cos(x(1)) - L4 * cos(x(2));
            O2(2) + L2 * sin(t2) + L3 * sin(x(1)) - L4 * sin(x(2))
        ];
        [x_sol, ~, info] = fsolve(sis, x_curr, opt);
        if info > 0
            x_curr = x_sol;
            t3 = x_sol(1);
            t4 = x_sol(2);
            
            % Ângulo de transmissão mu
            diff_ang = abs(t4 - t3);
            diff_ang = mod(diff_ang, 2*pi);
            if diff_ang > pi, diff_ang = 2*pi - diff_ang; end
            mu_trajectories(c, k) = rad2deg(diff_ang);
            
            % Posição do pistão vertical O5
            xB = L4 * cos(t4);
            yB = L4 * sin(t4);
            y_O5_trajectories(c, k) = yB - sqrt(L5^2 - xB^2);
        end
    end
end

% -------------------------------------------------------------------------
% 4. FIGURA 1: Gráfico do Ângulo de Transmissão mu(theta2)
% -------------------------------------------------------------------------
fig1 = figure('Name', 'Benchmarking Angulo de Transmissao', 'NumberTitle', 'off', 'Position', [100, 100, 950, 600]);
hold on; grid on;

% Faixa aceitável de Norton [40°, 140°] sombreada em verde suave
fill([0, 360, 360, 0], [40, 40, 140, 140], [0.88, 0.96, 0.88], 'EdgeColor', 'none');
plot([0, 360], [90, 90], 'k--', 'LineWidth', 1.4); % Ideal 90°
plot([0, 360], [40, 40], 'r--', 'LineWidth', 1.2); % Limite inferior 40°
plot([0, 360], [140, 140], 'r--', 'LineWidth', 1.2); % Limite superior 140°

h_plots = zeros(1, num_casos);
for c = 1:num_casos
    cor = casos_bench{c, 3};
    est = casos_bench{c, 4};
    h_plots(c) = plot(theta2_deg, mu_trajectories(c, :), 'Color', cor, 'LineStyle', est, 'LineWidth', 2.3);
end

title('Benchmarking do Ângulo de Transmissão \mu(\theta_2) para Diferentes Posições de O_2', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Posição Angular da Manivela \theta_2 (graus)', 'FontSize', 11);
ylabel('Ângulo de Transmissão \mu (graus)', 'FontSize', 11);
xlim([0, 360]); ylim([30, 145]);

text(10, 92, 'Ideal Norton: \mu = 90°', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
text(10, 43, 'Limite Inferior Recomendado (\mu \geq 40°)', 'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');
text(10, 137, 'Limite Superior Recomendado (\mu \leq 140°)', 'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');

leg_labels = cell(1, num_casos);
for c = 1:num_casos
    leg_labels{c} = sprintf('%s | \\mu \\in [%.1f°, %.1f°] | T_{ret} = %.3fs (%.1f%%)', ...
        casos_bench{c, 1}, metricas(c).mu_min, metricas(c).mu_max, metricas(c).t_ret, metricas(c).pct_ret);
end
legend(h_plots, leg_labels, 'Location', 'south', 'FontSize', 9);

caminho_fig1 = fullfile(assets_dir, 'benchmarking_angulo_transmissao_O2.png');
print(fig1, caminho_fig1, '-dpng', '-r300');
fprintf('Figura 1 salva em: %s\n', caminho_fig1);

% -------------------------------------------------------------------------
% 5. FIGURA 2: Comparativo de Tempo de Retorno (Deslocamento do Pistão y_O5)
% -------------------------------------------------------------------------
fig2 = figure('Name', 'Comparativo Tempo de Retorno Prensa', 'NumberTitle', 'off', 'Position', [120, 120, 950, 600]);
hold on; grid on;

h_disp = zeros(1, num_casos);
for c = 1:num_casos
    cor = casos_bench{c, 3};
    est = casos_bench{c, 4};
    h_disp(c) = plot(theta2_deg, y_O5_trajectories(c, :), 'Color', cor, 'LineStyle', est, 'LineWidth', 2.3);
end

% Linhas dos pontos mortos
plot([0, 360], [-290.02, -290.02], 'Color', [0.3 0.3 0.3], 'LineStyle', ':', 'LineWidth', 1.2);
plot([0, 360], [-320.00, -320.00], 'Color', [0.8 0.1 0.1], 'LineStyle', '--', 'LineWidth', 1.3);

text(15, -288, 'Ponto Morto Superior (PMS - Abertura p/ Alimentação de Baru): y = -290.0 mm', 'FontSize', 9, 'FontWeight', 'bold');
text(15, -318, 'Ponto Morto Inferior (PMI - Esmagamento Máximo): y = -320.0 mm (Curso = 30 mm)', 'FontSize', 9, 'Color', [0.8 0.1 0.1], 'FontWeight', 'bold');

title('Cinemática do Pistão: Avanço (Corte Rápido) vs Retorno (Recarga Prolongada de Baru)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Posição Angular da Manivela \theta_2 (graus)', 'FontSize', 11);
ylabel('Posição Vertical da Navalha y_{O5} (mm)', 'FontSize', 11);
xlim([0, 360]); ylim([-325, -285]);
legend(h_disp, leg_labels, 'Location', 'northeast', 'FontSize', 8.5);

caminho_fig2 = fullfile(assets_dir, 'benchmarking_tempo_retorno_prensa.png');
print(fig2, caminho_fig2, '-dpng', '-r300');
fprintf('Figura 2 salva em: %s\n', caminho_fig2);

% -------------------------------------------------------------------------
% 6. FIGURA 3: Mapa de Regiões de Grashof (Classe I vs Classe II) no Plano O2
% -------------------------------------------------------------------------
fig3 = figure('Name', 'Mapeamento Grashof Plano O2', 'NumberTitle', 'off', 'Position', [140, 140, 950, 750]);
hold on; grid on; axis equal;

% Análise de Grashof mantendo as barras já fabricadas/dimensionadas
% L2 = 34.63 mm, L3 = 103.89 mm, L4 = 160.0 mm
% Fronteiras analíticas de Grashof para a distância entre pivôs d:
% 1) d_lim_sup_classe1 = (L3 + L4) - L2 = 103.89 + 160 - 34.63 = 229.26 mm
% 2) d_max_montabilidade = L2 + L3 + L4 = 34.63 + 103.89 + 160 = 298.52 mm
% 3) d_lim_inf_classe1 = L4 - L3 + L2 = 160 - 103.89 + 34.63 = 90.74 mm
% 4) d_min_montabilidade = L4 - L3 - L2 = 160 - 103.89 - 34.63 = 21.48 mm

d_c1_max = (103.89 + 160.0) - 34.63; % 229.26 mm
d_mont_max = 34.63 + 103.89 + 160.0; % 298.52 mm
d_c1_min = 160.0 - 103.89 + 34.63;   % 90.74 mm
d_mont_min = 160.0 - 103.89 - 34.63; % 21.48 mm

% Construção de setores circulares para preenchimento
phi_arc = linspace(pi/2, 3*pi/2, 100); % Foco no semiplano esquerdo (x < 0)

% Coroa externa Classe II (Não-Grashof): 229.26 < d < 298.52 mm
x_outer_c2 = [d_mont_max * cos(phi_arc), fliplr(d_c1_max * cos(phi_arc))];
y_outer_c2 = [d_mont_max * sin(phi_arc), fliplr(d_c1_max * sin(phi_arc))];
h_c2_ext = fill(x_outer_c2, y_outer_c2, [1.0, 0.88, 0.88], 'EdgeColor', [0.8 0.2 0.2], 'LineStyle', '--', 'LineWidth', 1.2);

% Região Classe I (Manivela-Balancim): 90.74 < d < 229.26 mm
x_c1 = [d_c1_max * cos(phi_arc), fliplr(d_c1_min * cos(phi_arc))];
y_c1 = [d_c1_max * sin(phi_arc), fliplr(d_c1_min * sin(phi_arc))];
h_c1 = fill(x_c1, y_c1, [0.88, 0.95, 0.88], 'EdgeColor', [0.2 0.6 0.2], 'LineWidth', 1.5);

% Coroa interna Classe II (Não-Grashof): 21.48 < d < 90.74 mm
x_inner_c2 = [d_c1_min * cos(phi_arc), fliplr(d_mont_min * cos(phi_arc))];
y_inner_c2 = [d_c1_min * sin(phi_arc), fliplr(d_mont_min * sin(phi_arc))];
h_c2_int = fill(x_inner_c2, y_inner_c2, [1.0, 0.88, 0.88], 'EdgeColor', [0.8 0.2 0.2], 'LineStyle', '--', 'LineWidth', 1.2);

% Traçado das posições dos elos fundamentais
plot([0, B2(1)], [0, B2(2)], 'k-', 'LineWidth', 2.5); % Balancim em B2
plot([0, B1(1)], [0, B1(2)], 'k--', 'LineWidth', 1.5); % Balancim em B1
plot([B1(1), B2(1)], [B1(2), B2(2)], 'm-.', 'LineWidth', 1.5); % Corda M

% Linha colinear de alternância (estendida)
u_M = (B1 - B2) / corda_M;
reta_col = [B2 - 0.5*corda_M*u_M, B2 + 3.0*corda_M*u_M];
plot(reta_col(1, :), reta_col(2, :), 'Color', [0.4 0.4 0.4], 'LineStyle', ':', 'LineWidth', 1.4);

% Pivôs fixos e juntas
plot(0, 0, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
plot(B2(1), B2(2), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8);
plot(B1(1), B1(2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8);

text(8, 8, 'Pivô O_4 (0, 0)', 'FontSize', 10, 'FontWeight', 'bold');
text(B2(1)+8, B2(2), 'B_2 (0, -160)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'm');
text(B1(1)-75, B1(2), 'B_1 (-67.6, -145)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'b');
text(-215, -125, 'Linha Colinear de Norton (\alpha = 0°)', 'FontSize', 9, 'Color', [0.3 0.3 0.3], 'Rotation', rad2deg(atan2(u_M(2), u_M(1))));

% Plotagem dos 5 pontos do Benchmarking
h_pts = zeros(1, num_casos);
for c = 1:num_casos
    P = metricas(c).O2;
    cor = casos_bench{c, 3};
    h_pts(c) = plot(P(1), P(2), 'p', 'MarkerFaceColor', cor, 'MarkerEdgeColor', 'k', 'MarkerSize', 13);
    text(P(1)-18, P(2)-12, sprintf('P_%d', c), 'FontSize', 10, 'FontWeight', 'bold', 'Color', cor);
end

% Rótulos explicativos das regiões
text(-160, 20, {'REGIÃO CLASSE I (GRASHOF)', 'Manivela-Balancim (Giro Contínuo 360°)', '90.74 mm \leq d \leq 229.26 mm'}, ...
     'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1 0.5 0.1], 'HorizontalAlignment', 'center');

text(-265, -180, {'REGIÃO CLASSE II (NÃO-GRASHOF)', 'Duplo-Balancim (Oscilante)', '229.26 mm < d < 298.52 mm'}, ...
     'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.7 0.1 0.1], 'HorizontalAlignment', 'center');

text(-60, -40, {'CLASSE II', 'd < 90.74 mm'}, 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.7 0.1 0.1]);

title('Mapeamento Geométrico no Plano (X, Y): Regiões de Grashof Classe I vs Classe II para o Pivô O_2', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Coordenada X (mm)', 'FontSize', 10);
ylabel('Coordenada Y (mm)', 'FontSize', 10);
xlim([-320, 60]); ylim([-310, 60]);

legend([h_c1, h_c2_ext, h_pts], ...
    {'Região Classe I: Manivela-Balancim (s+l \leq p+q)', ...
     'Região Classe II: Duplo-Balancim (s+l > p+q)', ...
     sprintf('P_1: Colinear K=2 (d=187.6 mm, \\alpha=0.0°, T_{ret}=0.600s)'), ...
     sprintf('P_2: Alt Clássico (d=204.2 mm, \\alpha=8.1°, T_{ret}=0.627s)'), ...
     sprintf('P_3: Adotado Ativ. 5 (d=193.1 mm, \\alpha=7.2°, T_{ret}=0.624s)'), ...
     sprintf('P_4: Trade-off Ótimo (d=157.0 mm, \\alpha=13.6°, T_{ret}=0.645s)'), ...
     sprintf('P_5: Máx. Retorno (d=141.4 mm, \\alpha=23.3°, T_{ret}=0.678s)')}, ...
    'Location', 'southwest', 'FontSize', 8.5);

caminho_fig3 = fullfile(assets_dir, 'mapeamento_regioes_grashof_O2.png');
print(fig3, caminho_fig3, '-dpng', '-r300');
fprintf('Figura 3 salva em: %s\n', caminho_fig3);

fprintf('\nExecução e geração de todos os gráficos concluída com sucesso!\n');
