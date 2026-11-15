% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Benchmarking do Ângulo do Balancim (Delta_theta4): Compacidade, Tamanho dos Elos
% e Vantagem Mecânica na Posição Simétrica de O2 (K = 2)
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% Parâmetro fixo de projeto:
h = 30.0; % Curso total do pistão da faca (mm)
K = 2.0;  % Parâmetro de Norton para O2 colinear simétrico (alpha = 0°)

% Faixa de estudo para o ângulo de oscilação do balancim:
angulos_balancim_deg = [18, 22, 25, 30, 35, 40, 45];
num_ang = length(angulos_balancim_deg);

cores = {
    [0.70 0.20 0.20], ... % 18° (Marrom-avermelhado)
    [0.85 0.45 0.10], ... % 22° (Laranja escuro)
    [0.10 0.65 0.25], ... % 25° (Verde - Projeto Atual)
    [0.00 0.45 0.85], ... % 30° (Azul)
    [0.55 0.20 0.75], ... % 35° (Roxo)
    [0.80 0.10 0.50], ... % 40° (Magenta)
    [0.35 0.35 0.35]      % 45° (Cinza)
};

dados = struct();

fprintf('========================================================================================================================\n');
fprintf('BENCHMARKING DO ÂNGULO DO BALANCIM (Delta_theta4) — CURSO h = 30 mm (POSIÇÃO SIMÉTRICA K = 2)\n');
fprintf('========================================================================================================================\n');
fprintf('%-7s | L4=L5 (mm) | L2 (mm) | L3 (mm) | Base d (mm) | O2 [X, Y] (mm)      | Compacidade L_tot | mu_min - mu_max | VM_F (3mm)\n', 'Delta');
fprintf('------------------------------------------------------------------------------------------------------------------------\n');

N = 360;
theta2_deg = linspace(0, 360, N);
opt = optimset('Display', 'off');

for i = 1:num_ang
    dt_deg = angulos_balancim_deg(i);
    dt = deg2rad(dt_deg);
    
    % Geometria exata deduzida para L4 = L5 e curso h = 30 mm:
    % h = 2 * L4 * (1 - cos(dt)) => L4 = h / (2 * (1 - cos(dt)))
    L4 = h / (2.0 * (1.0 - cos(dt)));
    L5 = L4;
    
    % Posições extremas da junta B:
    B2 = [0.0; -L4];
    B1 = [-L4 * sin(dt); -L4 * cos(dt)];
    M = B1 - B2;
    corda_M = norm(M);
    
    % Síntese simétrica colinear de Norton (K = 2):
    O2 = B2 + K * M;
    d = norm(O2);
    
    r1 = norm(B1 - O2);
    r2 = norm(B2 - O2);
    L2 = (r2 - r1) / 2.0;
    L3 = (r2 + r1) / 2.0;
    L_tot = L2 + L3 + L4 + L5 + d;
    
    % Extremos de mu
    c1 = (L3^2 + L4^2 - (d - L2)^2) / (2 * L3 * L4);
    c2 = (L3^2 + L4^2 - (d + L2)^2) / (2 * L3 * L4);
    ang1 = rad2deg(acos(max(-1, min(1, c1))));
    ang2 = rad2deg(acos(max(-1, min(1, c2))));
    mu_min = min(ang1, ang2);
    mu_max = max(ang1, ang2);
    
    % Simulação cinemática da volta completa
    y_O5 = zeros(1, N);
    phi2 = atan2(B2(2) - O2(2), B2(1) - O2(1));
    x_curr = [phi2; -pi/2];
    mu_ciclo = zeros(1, N);
    
    for k = 1:N
        t2 = deg2rad(theta2_deg(k));
        sis = @(x) [
            O2(1) + L2 * cos(t2) + L3 * cos(x(1)) - L4 * cos(x(2));
            O2(2) + L2 * sin(t2) + L3 * sin(x(1)) - L4 * sin(x(2))
        ];
        [x_sol, ~, info] = fsolve(sis, x_curr, opt);
        if info > 0
            x_curr = x_sol;
            t3 = x_sol(1); t4 = x_sol(2);
            xB = L4 * cos(t4); yB = L4 * sin(t4);
            y_O5(k) = yB - sqrt(L5^2 - xB^2);
            
            diff_ang = abs(t4 - t3);
            diff_ang = mod(diff_ang, 2*pi);
            if diff_ang > pi, diff_ang = 2*pi - diff_ang; end
            mu_ciclo(k) = rad2deg(diff_ang);
        end
    end
    
    % Derivada da posição do pistão para obter a vantagem mecânica
    dth = deg2rad(theta2_deg(2) - theta2_deg(1));
    dy = gradient(y_O5, dth);
    VM_F = L2 ./ (abs(dy) + 1e-4); % Vantagem Mecânica de Força F_out / F_in
    VM_tau = 1.0 ./ (abs(dy) + 1e-4); % Vantagem Mecânica em relação ao Torque [rad/mm]
    
    y_min = min(y_O5);
    idx_3mm = find(y_O5 <= y_min + 3.0 & y_O5 >= y_min);
    vm_f_3mm = mean(VM_F(idx_3mm));
    
    dados(i).dt_deg = dt_deg;
    dados(i).L4 = L4;
    dados(i).L2 = L2;
    dados(i).L3 = L3;
    dados(i).d = d;
    dados(i).O2 = O2;
    dados(i).L_tot = L_tot;
    dados(i).mu_min = mu_min;
    dados(i).mu_max = mu_max;
    dados(i).y_O5 = y_O5;
    dados(i).mu_ciclo = mu_ciclo;
    dados(i).VM_F = VM_F;
    dados(i).VM_tau = VM_tau;
    dados(i).vm_f_3mm = vm_f_3mm;
    dados(i).dist_do_PMI = y_O5 - y_min;
    
    fprintf('%4d°   | %10.2f | %7.2f | %7.2f | %11.2f | [%7.2f, %7.2f] | %13.2f mm  | %5.1f° - %5.1f°  | %10.1f\n', ...
        dt_deg, L4, L2, L3, d, O2(1), O2(2), L_tot, mu_min, mu_max, vm_f_3mm);
end
fprintf('========================================================================================================================\n\n');

% -------------------------------------------------------------------------
% FIGURA 1: Tamanho dos Elos e Compacidade Estrutural vs Delta_theta4
% -------------------------------------------------------------------------
fig1 = figure('Name', 'Dimensoes e Compacidade vs Delta theta4', 'NumberTitle', 'off', 'Position', [100, 100, 1050, 650]);

subplot(2, 1, 1);
ang_sweep = linspace(15, 50, 200);
rad_sweep = deg2rad(ang_sweep);
L4_curve = h ./ (2.0 .* (1.0 - cos(rad_sweep)));
M_curve  = h ./ (2.0 .* sin(rad_sweep / 2.0));
L2_curve = M_curve / 2.0;
L3_curve = 1.5 .* M_curve;

plot(ang_sweep, L4_curve, 'Color', [0.85 0.2 0.2], 'LineWidth', 2.3); hold on; grid on;
plot(ang_sweep, L3_curve, 'Color', [0.15 0.65 0.25], 'LineWidth', 2.3);
plot(ang_sweep, L2_curve, 'Color', [0.0 0.45 0.85], 'LineWidth', 2.3);

% Marcador do projeto atual (25°)
plot(25, 160.1, 'ks', 'MarkerFaceColor', [0.1 0.65 0.25], 'MarkerSize', 8);
text(26, 175, 'Projeto Atual: \Delta\theta_4 = 25° (L_4 = 160 mm)', 'FontSize', 9, 'FontWeight', 'bold');

title('Influência do Ângulo de Oscilação (\Delta\theta_4) no Comprimento dos Elos (Curso Fixo h = 30 mm)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Ângulo de Oscilação do Balancim \Delta\theta_4 (graus)', 'FontSize', 10);
ylabel('Comprimento dos Elos (mm)', 'FontSize', 10);
xlim([15, 50]); ylim([0, 450]);
legend({'Balancim e Biela da Prensa: L_4 = L_5 = \frac{15}{1 - cos(\Delta\theta_4)}', ...
        'Acoplador: L_3 = 1.5 \cdot ||M||', ...
        'Manivela: L_2 = 0.5 \cdot ||M||'}, 'FontSize', 9, 'Location', 'northeast');

subplot(2, 1, 2);
L_tot_sweep = zeros(size(ang_sweep));
for k = 1:length(ang_sweep)
    dt_k = rad_sweep(k);
    l4_k = L4_curve(k);
    b2_k = [0; -l4_k];
    b1_k = [-l4_k * sin(dt_k); -l4_k * cos(dt_k)];
    m_k = b1_k - b2_k;
    o2_k = b2_k + 2 * m_k;
    d_k = norm(o2_k);
    L_tot_sweep(k) = L2_curve(k) + L3_curve(k) + 2*l4_k + d_k;
end

plot(ang_sweep, L_tot_sweep, 'Color', [0.2 0.2 0.2], 'LineWidth', 2.4); hold on; grid on;
% Marcadores dos pontos testados
for i = 1:num_ang
    plot(dados(i).dt_deg, dados(i).L_tot, 'o', 'MarkerFaceColor', cores{i}, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
    text(dados(i).dt_deg - 0.5, dados(i).L_tot + 45, sprintf('%d° (%d mm)', dados(i).dt_deg, round(dados(i).L_tot)), ...
         'FontSize', 8.5, 'FontWeight', 'bold', 'Color', cores{i});
end

title('Métrica de Compacidade Estrutural: Soma Total dos Elos L_{tot} = L_2 + L_3 + L_4 + L_5 + d', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Ângulo de Oscilação do Balancim \Delta\theta_4 (graus)', 'FontSize', 10);
ylabel('Envelope Linear Total L_{tot} (mm)', 'FontSize', 10);
xlim([15, 50]); ylim([180, 1650]);

caminho_fig1 = fullfile(assets_dir, 'benchmarking_balancim_dimensoes_compacidade.png');
print(fig1, caminho_fig1, '-dpng', '-r300');
fprintf('Figura 1 salva em: %s\n', caminho_fig1);

% -------------------------------------------------------------------------
% FIGURA 2: Comparativo da Vantagem Mecânica e Ângulo de Transmissão
% -------------------------------------------------------------------------
fig2 = figure('Name', 'Vantagem Mecanica e Angulo Transmissao vs Delta theta4', 'NumberTitle', 'off', 'Position', [120, 120, 1050, 700]);

% Subplot 1: Vantagem Mecânica de Força (F_out / F_in) na Zona de Prensagem (últimos 8 mm)
subplot(2, 1, 1);
hold on; grid on;

h_vm = zeros(1, num_ang);
for i = 1:num_ang
    % Filtrar curso próximo ao PMI durante a descida (avanço: 0° a 180°)
    idx_avanco = 1:round(N/2);
    dist_pmi = dados(i).dist_do_PMI(idx_avanco);
    vm_f = dados(i).VM_F(idx_avanco);
    
    % Ordenar por distância do PMI
    [dist_pmi_ord, idx_sort] = sort(dist_pmi);
    vm_f_ord = vm_f(idx_sort);
    
    % Plotar apenas os últimos 10 mm até o PMI (0 mm)
    idx_zona = find(dist_pmi_ord <= 8.0);
    h_vm(i) = plot(dist_pmi_ord(idx_zona), vm_f_ord(idx_zona), 'Color', cores{i}, 'LineWidth', 2.3);
end

set(gca, 'XDir', 'reverse'); % 8 mm para 0 mm (PMI)
set(gca, 'YScale', 'log');   % Escala logarítmica para ver o efeito joelho (tende a infinito)
title('Vantagem Mecânica de Força F_{out} / F_{in} ao se Aproximar do PMI (Zona de Quebra do Baru)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Distância Restante até o Fim do Curso / PMI (mm)', 'FontSize', 10);
ylabel('Vantagem Mecânica F_{out} / F_{in} (Escala Log)', 'FontSize', 10);
xlim([0, 8]); ylim([10, 1e5]);

labels_leg = cell(1, num_ang);
for i = 1:num_ang
    labels_leg{i} = sprintf('\\Delta\\theta_4 = %d° (L_4 = %.1f mm, L_2 = %.1f mm)', ...
        dados(i).dt_deg, dados(i).L4, dados(i).L2);
end
legend(h_vm, labels_leg, 'Location', 'northwest', 'FontSize', 8.5);

% Subplot 2: Ângulo de Transmissão mu(theta2)
subplot(2, 1, 2);
hold on; grid on;

fill([0, 360, 360, 0], [40, 40, 140, 140], [0.88, 0.96, 0.88], 'EdgeColor', 'none');
plot([0, 360], [90, 90], 'k--', 'LineWidth', 1.3);
plot([0, 360], [40, 40], 'r--', 'LineWidth', 1.1);
plot([0, 360], [140, 140], 'r--', 'LineWidth', 1.1);

h_mu = zeros(1, num_ang);
for i = 1:num_ang
    h_mu(i) = plot(theta2_deg, dados(i).mu_ciclo, 'Color', cores{i}, 'LineWidth', 2.0);
end

title('Variação do Ângulo de Transmissão \mu(\theta_2) para Cada Ângulo do Balancim (Posição Simétrica K = 2)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Posição Angular da Manivela \theta_2 (graus)', 'FontSize', 10);
ylabel('Ângulo de Transmissão \mu (graus)', 'FontSize', 10);
xlim([0, 360]); ylim([35, 145]);

text(10, 92, 'Ideal (\mu = 90°)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
text(10, 43, 'Limite Inferior Recomendado de Norton (\mu \geq 40°)', 'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');
legend(h_mu, labels_leg, 'Location', 'south', 'FontSize', 8.5);

caminho_fig2 = fullfile(assets_dir, 'benchmarking_balancim_vantagem_mecanica_transmissao.png');
print(fig2, caminho_fig2, '-dpng', '-r300');
fprintf('Figura 2 salva em: %s\n', caminho_fig2);

fprintf('\nBenchmarking do balancim concluído com sucesso!\n');
