% =========================================================================
% Comparativo do Ângulo de Transmissão (mu) entre as Três Soluções
% Mecanismo de Prensa Mecânica para Quebra de Baru
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

% 1. Parâmetros invariantes do balancim
L4 = 160.0;
Delta_theta = deg2rad(25.0);
B2 = [0.0; -L4];
B1 = [-L4 * sin(Delta_theta); -L4 * cos(Delta_theta)];

% 2. Definição das três soluções de projeto
% [Nome, O2_x, O2_y, Cor, Estilo_linha]
solucoes = {
    'Solução 1: Ótimo Teórico de Alt (O_2 = [-138.6, -150.0])', ...
    [-138.61; -150.00], [0.85, 0.20, 0.20], '--';
    
    'Solução 2: Ponto Adotado no Trabalho (O_2 = [-180.0, -70.0])', ...
    [-180.00; -70.00], [0.10, 0.65, 0.25], '-';
    
    'Solução 3: Ótimo Restrito de Maior Compacidade (O_2 = [-210.0, -80.0])', ...
    [-210.00; -80.00], [0.10, 0.40, 0.85], '-.'
};

N = 360;
theta2_deg = linspace(0, 360, N);
mu_todas = zeros(size(solucoes, 1), N);

opt = optimset('Display', 'off');

for s = 1:size(solucoes, 1)
    O2 = solucoes{s, 2};
    r1 = norm(B1 - O2);
    r2 = norm(B2 - O2);
    L2 = (r2 - r1) / 2.0;
    L3 = (r2 + r1) / 2.0;
    
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
            
            % O ângulo de transmissão mu (Norton 2010) é o menor ângulo entre
            % a linha do acoplador (elo 3) e a linha do balancim (elo 4):
            diff_ang = abs(t4 - t3);
            diff_ang = mod(diff_ang, 2*pi);
            if diff_ang > pi
                diff_ang = 2*pi - diff_ang;
            end
            mu_todas(s, k) = rad2deg(diff_ang);
        end
    end
end

% -------------------------------------------------------------------------
% Criação da Figura Didática Composta
% -------------------------------------------------------------------------
fig = figure('Name', 'Analise e Comparacao do Angulo de Transmissao', ...
             'NumberTitle', 'off', 'Position', [100, 100, 1100, 750]);

% --- SUBPLOT 1: Visualização Didática com Quiver dos Vetores de Força na Junta B ---
subplot(2, 2, 1);
hold on; grid on; axis equal;

O4 = [0; 0];
O2_adotado = [-180; -70];
r1_ad = norm(B1 - O2_adotado);
r2_ad = norm(B2 - O2_adotado);
L2_ad = (r2_ad - r1_ad)/2;
L3_ad = (r2_ad + r1_ad)/2;

% Configuração geométrica em theta2 = 50° para abertura angular nítida
t2_demo = deg2rad(50);
sis_demo = @(x) [
    O2_adotado(1) + L2_ad*cos(t2_demo) + L3_ad*cos(x(1)) - L4*cos(x(2));
    O2_adotado(2) + L2_ad*sin(t2_demo) + L3_ad*sin(x(1)) - L4*sin(x(2))
];
[x_demo, ~, ~] = fsolve(sis_demo, [-0.5; -1.8], opt);
t3_demo = x_demo(1);
t4_demo = x_demo(2);

A_demo = O2_adotado + L2_ad * [cos(t2_demo); sin(t2_demo)];
B_demo = [L4 * cos(t4_demo); L4 * sin(t4_demo)];

% Traçado das barras do mecanismo
plot([O2_adotado(1), A_demo(1)], [O2_adotado(2), A_demo(2)], 'Color', [0.2 0.4 0.8], 'LineWidth', 2.4); % Elo 2 (Manivela)
plot([A_demo(1), B_demo(1)], [A_demo(2), B_demo(2)], 'Color', [0.15 0.65 0.25], 'LineWidth', 2.8);   % Elo 3 (Acoplador)
plot([O4(1), B_demo(1)], [O4(2), B_demo(2)], 'Color', [0.85 0.25 0.25], 'LineWidth', 3.0);          % Elo 4 (Balancim)
plot([O2_adotado(1), O4(1)], [O2_adotado(2), O4(2)], 'k--', 'LineWidth', 1.0);                       % Base fixa d

% Linhas tracejadas de referência colineares
u_biela = (B_demo - A_demo) / norm(B_demo - A_demo);
u_rad   = (B_demo - O4) / norm(B_demo - O4); % ao longo do balancim (de O4 para B)
u_tang  = [-u_rad(2); u_rad(1)];             % perpendicular ao balancim
if dot(u_tang, u_biela) < 0
    u_tang = -u_tang;
end

% Extensões tracejadas das linhas de centro
plot([B_demo(1), B_demo(1) + 65*u_biela(1)], [B_demo(2), B_demo(2) + 65*u_biela(2)], 'Color', [0.15 0.65 0.25], 'LineStyle', ':', 'LineWidth', 1.2);
plot([B_demo(1), B_demo(1) + 45*u_rad(1)], [B_demo(2), B_demo(2) + 45*u_rad(2)], 'Color', [0.85 0.25 0.25], 'LineStyle', ':', 'LineWidth', 1.2);

% --- VETORES DE FORÇA USANDO QUIVER (ESCALA FIXA REAL) ---
F_mag = 55.0; % Comprimento base para visualização do vetor (mm)
F_biela = F_mag * u_biela;
F_util  = dot(F_biela, u_tang) * u_tang;
F_rad   = dot(F_biela, u_rad) * u_rad;

% 1. Força aplicada pela biela F_biela (verde)
h_fb = quiver(B_demo(1), B_demo(2), F_biela(1), F_biela(2), 0, ...
              'Color', [0.1 0.6 0.2], 'LineWidth', 2.8, 'MaxHeadSize', 0.45);

% 2. Componente Útil Tangencial F_útil = F*sen(mu) (magenta)
h_fu = quiver(B_demo(1), B_demo(2), F_util(1), F_util(2), 0, ...
              'Color', [0.8 0.0 0.8], 'LineWidth', 2.8, 'MaxHeadSize', 0.45);

% 3. Componente Radial F_radial = F*cos(mu) (azul)
h_fr = quiver(B_demo(1), B_demo(2), F_rad(1), F_rad(2), 0, ...
              'Color', [0.0 0.45 0.9], 'LineWidth', 2.5, 'MaxHeadSize', 0.45);

% Linhas tracejadas de projeção do paralelogramo de forças
plot([B_demo(1)+F_util(1), B_demo(1)+F_biela(1)], [B_demo(2)+F_util(2), B_demo(2)+F_biela(2)], 'k--', 'LineWidth', 1.0);
plot([B_demo(1)+F_rad(1), B_demo(1)+F_biela(1)], [B_demo(2)+F_rad(2), B_demo(2)+F_biela(2)], 'k--', 'LineWidth', 1.0);

% Ângulo de transmissão mu na junta B
mu_val = rad2deg(acos(dot(u_biela, u_rad)));
ang1 = atan2(u_rad(2), u_rad(1));
ang2 = atan2(u_biela(2), u_biela(1));
ang_arco = linspace(min(ang1, ang2), max(ang1, ang2), 30);
plot(B_demo(1) + 24*cos(ang_arco), B_demo(2) + 24*sin(ang_arco), 'Color', [0.9 0.4 0.0], 'LineWidth', 2.0);

% Marcadores de juntas e pivôs
plot(O4(1), O4(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(O2_adotado(1), O2_adotado(2), 'ks', 'MarkerFaceColor', [0.3 0.3 0.3], 'MarkerSize', 7);
plot(A_demo(1), A_demo(2), 'ko', 'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize', 7);
plot(B_demo(1), B_demo(2), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 9);

% Rótulos explicativos sem artefatos TeX
text(B_demo(1) + 28*cos((ang1+ang2)/2), B_demo(2) + 28*sin((ang1+ang2)/2), ...
     sprintf('\\mu = %.1f°', mu_val), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.9 0.4 0.0]);
text(B_demo(1) + F_biela(1) + 4, B_demo(2) + F_biela(2) - 4, ...
     'F_{biela}', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.6 0.2]);
text(B_demo(1) + F_util(1) + 4, B_demo(2) + F_util(2) + 8, ...
     'F_{útil} (\tau_4)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.8 0.0 0.8]);
text(B_demo(1) + F_rad(1) - 28, B_demo(2) + F_rad(2) - 10, ...
     'F_{rad}', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.0 0.45 0.9]);

text(O4(1)+6, O4(2)+6, 'Pivô O_4', 'FontSize', 10, 'FontWeight', 'bold');
text(O2_adotado(1)-25, O2_adotado(2)+8, 'Pivô O_2', 'FontSize', 9, 'FontWeight', 'bold');
text(A_demo(1)-18, A_demo(2)+14, 'Junta A', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.2 0.4 0.8]);
text(B_demo(1)-35, B_demo(2)-6, 'Junta B', 'FontSize', 10, 'FontWeight', 'bold');

text(-130, -75, 'Acoplador L_3', 'FontSize', 9, 'Color', [0.15 0.65 0.25], 'FontAngle', 'italic');
text(-4, -70, 'Balancim L_4', 'FontSize', 9, 'Color', [0.85 0.25 0.25], 'FontAngle', 'italic');

title('Decomposição dos Vetores de Força na Junta B (Quiver)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('X (mm)'); ylabel('Y (mm)');
xlim([-250, 70]); ylim([-240, 50]);

legend([h_fb, h_fu, h_fr], ...
    {'F_{biela}: Força transmitida', ...
     'F_{útil} = F \cdot sen(\mu)  [Torque]', ...
     'F_{rad} = F \cdot cos(\mu)  [Mancal O_4]'}, ...
    'Location', 'northwest', 'FontSize', 8.5);

% --- SUBPLOT 2: Conceito de Eficiência de Transmissão (sin(mu)) ---
subplot(2, 2, 2);
mu_range = linspace(0, 180, 300);
sin_range = sin(deg2rad(mu_range));
plot(mu_range, sin_range, 'k-', 'LineWidth', 2.2); hold on;
% Zona aceitável Norton (40° a 140°)
fill([40, 140, 140, 40], [0, 0, 1.05, 1.05], [0.8 0.95 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
plot(mu_range, sin_range, 'k-', 'LineWidth', 2.2); % replot para ficar sobre o preenchimento
plot([90, 90], [0, 1.0], 'r--', 'LineWidth', 1.5);
plot([0, 180], [sin(deg2rad(40)), sin(deg2rad(40))], 'b--', 'LineWidth', 1.0);
plot(90, 1.0, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

text(95, 0.95, 'Ideal: \mu = 90° (\tau_{útil} = 100%)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'r');
text(45, 0.25, {'Zona Aceitável de Norton:', '40° \leq \mu \leq 140°'}, ...
     'FontSize', 10, 'Color', [0.1 0.5 0.1], 'FontWeight', 'bold');
text(5, 0.68, 'Limite Mínimo: sin(40°) \approx 0.64', 'FontSize', 9, 'Color', 'b');

grid on;
title('Eficiência de Torque Útil: \tau_{útil} \propto sen(\mu)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Ângulo de Transmissão \mu (graus)');
ylabel('Fração Útil de Força: sen(\mu)');
xlim([0, 180]); ylim([0, 1.08]);

% --- SUBPLOT 3: Comparativo Completo das Três Soluções ao Longo da Volta ---
subplot(2, 1, 2);
hold on; grid on;

% Faixa segura de Norton sombreada
fill([0, 360, 360, 0], [40, 40, 140, 140], [0.85, 0.96, 0.85], 'EdgeColor', 'none');

% Linha ideal de 90°
plot([0, 360], [90, 90], 'k--', 'LineWidth', 1.5);
plot([0, 360], [40, 40], 'Color', [0.6 0.2 0.2], 'LineStyle', ':', 'LineWidth', 1.2);
plot([0, 360], [140, 140], 'Color', [0.6 0.2 0.2], 'LineStyle', ':', 'LineWidth', 1.2);

h_linhas = zeros(1, size(solucoes, 1));
for s = 1:size(solucoes, 1)
    nome = solucoes{s, 1};
    cor = solucoes{s, 3};
    estilo = solucoes{s, 4};
    h_linhas(s) = plot(theta2_deg, mu_todas(s, :), 'Color', cor, 'LineStyle', estilo, 'LineWidth', 2.4);
    
    % Marcadores no mínimo e máximo
    [mu_min_s, idx_min] = min(mu_todas(s, :));
    [mu_max_s, idx_max] = max(mu_todas(s, :));
    plot(theta2_deg(idx_min), mu_min_s, 'o', 'MarkerFaceColor', cor, 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
    plot(theta2_deg(idx_max), mu_max_s, 's', 'MarkerFaceColor', cor, 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
end

title('Variação do Ângulo de Transmissão \mu(\theta_2) para as Três Soluções (0° \leq \theta_2 \leq 360°)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Ângulo da Manivela \theta_2 (graus)', 'FontSize', 11);
ylabel('Ângulo de Transmissão \mu (graus)', 'FontSize', 11);
xlim([0, 360]);
ylim([30, 150]);

text(10, 93, 'Ideal Teórico (\mu = 90°)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
text(10, 43, 'Limite Inferior Recomendado (\mu = 40°)', 'FontSize', 9, 'Color', [0.6 0.2 0.2]);
text(10, 137, 'Limite Superior Recomendado (\mu = 140°)', 'FontSize', 9, 'Color', [0.6 0.2 0.2]);

legend(h_linhas, ...
    {sprintf('Solução 1 (Alt puro): [%.1f°, %.1f°] | Desvio Máx: %.1f°', min(mu_todas(1,:)), max(mu_todas(1,:)), max(abs(mu_todas(1,:)-90))), ...
     sprintf('Solução 2 (Adotada):  [%.1f°, %.1f°] | Desvio Máx: %.1f°', min(mu_todas(2,:)), max(mu_todas(2,:)), max(abs(mu_todas(2,:)-90))), ...
     sprintf('Solução 3 (Compac.):  [%.1f°, %.1f°] | Desvio Máx: %.1f°', min(mu_todas(3,:)), max(mu_todas(3,:)), max(abs(mu_todas(3,:)-90)))}, ...
    'Location', 'south', 'FontSize', 10);

% Salvamento da imagem em 300 DPI
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
caminho_fig = fullfile(assets_dir, 'ex2_comparativo_angulo_transmissao.png');
print(fig, caminho_fig, '-dpng', '-r300');
fprintf('Gráfico comparativo salvo com sucesso em: %s\n', caminho_fig);
