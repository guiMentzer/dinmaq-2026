% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Benchmarking Completo da Posição do Pivô Fixo O2 para Delta_theta4 = 30°
% Comparativo: Tamanho dos Elos, Compacidade e Ângulo de Transmissão mu
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Parâmetros Fixados para Balancim com Delta_theta4 = 30°
% -------------------------------------------------------------------------
h = 30.0; % Curso do pistão (mm)
dt_deg = 30.0;
dt = deg2rad(dt_deg);

% Balancim e biela da prensa
L4 = h / (2.0 * (1.0 - cos(dt))); % 111.96 mm
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4]; % PMI (alinhado na vertical com o pistão)
B1 = [-L4 * sin(dt); -L4 * cos(dt)]; % PMS (defletido de 30°)
M = B1 - B2;
corda_M = norm(M); % 57.96 mm

rpm = 50.0;
T_ciclo = 60.0 / rpm; % 1.20 s

% -------------------------------------------------------------------------
% 2. Definição das Configurações Candidatas de O2
% -------------------------------------------------------------------------
configs = {
    'Colinear K=1.5 (Ultra-Compacta)', B2 + 1.5 * M, [0.85 0.35 0.10]; % Laranja
    'Colinear K=2.0 (Norton Padrão)',  B2 + 2.0 * M, [0.00 0.45 0.85]; % Azul
    'Colinear K=2.5 (Biela Longa)',    B2 + 2.5 * M, [0.10 0.65 0.25]; % Verde
    'Retorno Rápido (Mais Tempo Recarga)', [-95.0; -60.0], [0.60 0.20 0.75]; % Roxo
    'Biela Horizontal (mu=90° no PMI)', [-160.0; -L4], [0.85 0.15 0.15]  % Vermelho
};

num_cfg = size(configs, 1);
res = struct();

fprintf('====================================================================================================================================\n');
fprintf('BENCHMARKING DE POSIÇÃO DE O2 PARA BALANCIM DE 30° (L4 = L5 = %.2f mm, CORDA M = %.2f mm)\n', L4, corda_M);
fprintf('====================================================================================================================================\n');
fprintf('%-36s | O2 [X, Y] (mm)      | L2 (mm) | L3 (mm) | Base d  | L_tot (mm) | alpha  | T_ret (s) [%%]  | mu_min - mu_max | mu_PMI\n', 'Configuração');
fprintf('------------------------------------------------------------------------------------------------------------------------------------\n');

N = 360;
theta2_deg = linspace(0, 360, N);
opt = optimset('Display', 'off');

for k = 1:num_cfg
    nome = configs{k, 1};
    O2 = configs{k, 2};
    cor = configs{k, 3};
    
    r1 = norm(B1 - O2);
    r2 = norm(B2 - O2);
    L2 = abs(r2 - r1) / 2.0;
    L3 = (r2 + r1) / 2.0;
    d = norm(O2);
    L_tot = L2 + L3 + 2.0*L4 + d;
    
    v1 = B1 - O2; v2 = B2 - O2;
    cos_al = dot(v1, v2) / (r1 * r2);
    alpha = rad2deg(acos(max(-1, min(1, cos_al))));
    T_ret = T_ciclo * (0.5 + alpha / 360.0);
    pct_ret = (T_ret / T_ciclo) * 100.0;
    
    c1 = (L3^2 + L4^2 - (d - L2)^2) / (2 * L3 * L4);
    c2 = (L3^2 + L4^2 - (d + L2)^2) / (2 * L3 * L4);
    ang1 = rad2deg(acos(max(-1, min(1, c1))));
    ang2 = rad2deg(acos(max(-1, min(1, c2))));
    mu_min = min(ang1, ang2);
    mu_max = max(ang1, ang2);
    
    % mu no PMI
    v_biela_PMI = B2 - O2;
    v_bal_PMI = B2 - O4;
    cos_pmi = dot(v_biela_PMI, v_bal_PMI) / (norm(v_biela_PMI) * norm(v_bal_PMI));
    mu_pmi = rad2deg(acos(max(-1, min(1, cos_pmi))));
    if mu_pmi > 90, mu_pmi = 180 - mu_pmi; end
    
    % Simulação Cinemática do Ciclo
    mu_ciclo = zeros(1, N);
    y_O5 = zeros(1, N);
    phi2 = atan2(B2(2) - O2(2), B2(1) - O2(1));
    x_curr = [phi2; -pi/2];
    
    for i = 1:N
        t2 = deg2rad(theta2_deg(i));
        sis = @(x) [
            O2(1) + L2 * cos(t2) + L3 * cos(x(1)) - L4 * cos(x(2));
            O2(2) + L2 * sin(t2) + L3 * sin(x(1)) - L4 * sin(x(2))
        ];
        [x_sol, ~, info] = fsolve(sis, x_curr, opt);
        if info > 0
            x_curr = x_sol;
            t3 = x_sol(1); t4 = x_sol(2);
            xB = L4 * cos(t4); yB = L4 * sin(t4);
            y_O5(i) = yB - sqrt(L5^2 - xB^2);
            
            diff_ang = abs(t4 - t3);
            diff_ang = mod(diff_ang, 2*pi);
            if diff_ang > pi, diff_ang = 2*pi - diff_ang; end
            mu_ciclo(i) = rad2deg(diff_ang);
        end
    end
    
    res(k).nome = nome;
    res(k).O2 = O2;
    res(k).cor = cor;
    res(k).L2 = L2;
    res(k).L3 = L3;
    res(k).d = d;
    res(k).L_tot = L_tot;
    res(k).alpha = alpha;
    res(k).T_ret = T_ret;
    res(k).pct_ret = pct_ret;
    res(k).mu_min = mu_min;
    res(k).mu_max = mu_max;
    res(k).mu_pmi = mu_pmi;
    res(k).mu_ciclo = mu_ciclo;
    res(k).y_O5 = y_O5;
    
    fprintf('%-36s | [%7.2f, %7.2f] | %7.2f | %7.2f | %7.2f | %10.2f | %5.2f° | %5.3f s [%4.1f%%] | %5.1f° - %5.1f°  | %5.1f°\n', ...
        nome, O2(1), O2(2), L2, L3, d, L_tot, alpha, T_ret, pct_ret, mu_min, mu_max, mu_pmi);
end
fprintf('====================================================================================================================================\n\n');

% -------------------------------------------------------------------------
% 3. FIGURA 1: Mapeamento no Plano 2D (X, Y) do Espaço de Soluções de O2
% -------------------------------------------------------------------------
fig1 = figure('Name', 'Mapeamento Espaco de Solucoes O2 Balancim 30', 'NumberTitle', 'off', 'Position', [80, 80, 1050, 700]);
hold on; grid on; axis equal;

% Reta colinear das soluções simétricas de Norton
k_vals = linspace(1.0, 3.2, 100);
col_X = B2(1) + k_vals * M(1);
col_Y = B2(2) + k_vals * M(2);
plot(col_X, col_Y, 'k--', 'LineWidth', 1.8);
text(col_X(end) - 15, col_Y(end) + 8, 'Reta Colinear Simétrica (\alpha = 0°)', 'FontSize', 9, 'FontWeight', 'bold');

% Linha horizontal do PMI (y = -L4)
plot([-220, 20], [-L4, -L4], 'Color', [0.6 0.6 0.6], 'LineStyle', ':', 'LineWidth', 1.2);
text(-215, -L4 - 6, 'Linha Horizontal do PMI (y = -L_4 \rightarrow \mu_{PMI} = 90°)', 'FontSize', 8.5, 'Color', [0.4 0.4 0.4]);

% Ponto fixo O4 e extremos do balancim B1 e B2
plot(0, 0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
text(4, 5, 'O_4 (0, 0)', 'FontSize', 10, 'FontWeight', 'bold');

% Arco do balancim entre B1 e B2
th_arc = linspace(-pi/2 - dt, -pi/2, 50);
plot(L4 * cos(th_arc), L4 * sin(th_arc), 'Color', [0.3 0.3 0.3], 'LineWidth', 2.0);

plot(B2(1), B2(2), 'bs', 'MarkerFaceColor', [0.2 0.5 0.9], 'MarkerSize', 9);
text(B2(1) + 4, B2(2) - 4, 'B_2 (PMI)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.4 0.8]);

plot(B1(1), B1(2), 'bs', 'MarkerFaceColor', [0.2 0.5 0.9], 'MarkerSize', 9);
text(B1(1) - 30, B1(2) - 4, 'B_1 (PMS)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.4 0.8]);

% Corda M conectando B1 e B2
plot([B1(1), B2(1)], [B1(2), B2(2)], 'Color', [0.8 0.4 0.1], 'LineWidth', 1.5);

% Plotar os 5 candidatos de O2
h_pts = zeros(1, num_cfg);
for k = 1:num_cfg
    O2 = res(k).O2;
    cor = res(k).cor;
    h_pts(k) = plot(O2(1), O2(2), 'o', 'MarkerFaceColor', cor, 'MarkerEdgeColor', 'k', 'MarkerSize', 11);
    
    rotulo = sprintf('%s\n(d = %.1f mm, L_3 = %.1f mm)', res(k).nome, res(k).d, res(k).L3);
    text(O2(1) + 4, O2(2) + 6, rotulo, 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', cor, 'BackgroundColor', [1 1 1]);
end

title('Mapeamento Geométrico das Posições de O_2 para Balancim de 30° (h = 30 mm, L_4 = 111.96 mm)', ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Coordenada X (mm)', 'FontSize', 10);
ylabel('Coordenada Y (mm)', 'FontSize', 10);
xlim([-230, 40]); ylim([-180, 40]);

leg_txt = cell(1, num_cfg);
for k = 1:num_cfg
    leg_txt{k} = sprintf('%s [\\mu \\in %4.1f°-%4.1f°, L_{tot} = %.1f mm]', ...
        res(k).nome, res(k).mu_min, res(k).mu_max, res(k).L_tot);
end
legend(h_pts, leg_txt, 'Location', 'southwest', 'FontSize', 8.5);

caminho_fig1 = fullfile(assets_dir, 'benchmarking_O2_balancim30_geometria.png');
print(fig1, caminho_fig1, '-dpng', '-r300');
fprintf('Figura 1 salva em: %s\n', caminho_fig1);

% -------------------------------------------------------------------------
% 4. FIGURA 2: Curvas do Ângulo de Transmissão mu(theta2) e Deslocamento y_O5
% -------------------------------------------------------------------------
fig2 = figure('Name', 'Angulo Transmissao e Deslocamento O2 Balancim 30', 'NumberTitle', 'off', 'Position', [100, 100, 1050, 750]);

% Subplot 1: Ângulo de Transmissão mu(theta2)
subplot(2, 1, 1);
hold on; grid on;

% Zona aceitável de Norton (40° a 140°)
fill([0, 360, 360, 0], [40, 40, 140, 140], [0.88, 0.96, 0.88], 'EdgeColor', 'none');
plot([0, 360], [90, 90], 'k--', 'LineWidth', 1.3);
plot([0, 360], [40, 40], 'r--', 'LineWidth', 1.1);
plot([0, 360], [140, 140], 'r--', 'LineWidth', 1.1);

h_mu = zeros(1, num_cfg);
for k = 1:num_cfg
    h_mu(k) = plot(theta2_deg, res(k).mu_ciclo, 'Color', res(k).cor, 'LineWidth', 2.2);
end

title('Variação do Ângulo de Transmissão \mu(\theta_2) para Cada Configuração de O_2 (\Delta\theta_4 = 30°)', ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Ângulo de Rotação da Manivela \theta_2 (graus)', 'FontSize', 10);
ylabel('Ângulo de Transmissão \mu (graus)', 'FontSize', 10);
xlim([0, 360]); ylim([35, 145]);

text(10, 92.5, 'Ideal (\mu = 90°)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
text(10, 43, 'Limite Inferior Crítico de Norton (\mu \geq 40°)', 'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');
legend(h_mu, leg_txt, 'Location', 'south', 'FontSize', 8.5);

% Subplot 2: Perfil de Deslocamento do Pistão da Navalha y_O5 (Avanço vs Retorno)
subplot(2, 1, 2);
hold on; grid on;

tempo_ciclo = (theta2_deg / 360.0) * T_ciclo;

for k = 1:num_cfg
    plot(tempo_ciclo, res(k).y_O5, 'Color', res(k).cor, 'LineWidth', 2.2);
end

title('Deslocamento Vertical do Pistão da Navalha y_{O5}(t) ao Longo do Ciclo a 50 rpm (T = 1.20 s)', ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Tempo de Ciclo (s)', 'FontSize', 10);
ylabel('Posição Vertical y_{O5} (mm)', 'FontSize', 10);
xlim([0, T_ciclo]);
ylim([-228, -190]);

% Indicação do PMI e PMS
plot([0, T_ciclo], [-2*L4, -2*L4], 'k:', 'LineWidth', 1.2);
text(0.05, -2*L4 + 1.2, sprintf('PMI: y = -223.9 mm (Quebra do Baru)'), 'FontSize', 8.5, 'FontWeight', 'bold');

plot([0, T_ciclo], [-2*L4*cos(dt), -2*L4*cos(dt)], 'k:', 'LineWidth', 1.2);
text(0.05, -2*L4*cos(dt) - 1.5, sprintf('PMS: y = -193.9 mm (Abertura para Recarga)'), 'FontSize', 8.5, 'FontWeight', 'bold');

legend(h_mu, leg_txt, 'Location', 'northeast', 'FontSize', 8.5);

caminho_fig2 = fullfile(assets_dir, 'benchmarking_O2_balancim30_transmissao_cinematica.png');
print(fig2, caminho_fig2, '-dpng', '-r300');
fprintf('Figura 2 salva em: %s\n', caminho_fig2);

fprintf('\nExecução finalizada com êxito!\n');
