% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Trade-Off de Validação do Ângulo de 30°:
% Comprimento Total da Máquina vs. Força Transversal e Eficiência na Guia
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Parâmetros Físicos e Geométricos
% -------------------------------------------------------------------------
h = 30.0;           % Curso útil vertical fixo da navalha (mm)
F_axial = 5000.0;   % Força de corte do endocarpo do baru por cisalhamento (N) [0.5 ton]
mu_lub = 0.10;      % Coeficiente de atrito aço-bronze lubrificado (guia padrão)
mu_seco = 0.15;     % Coeficiente de atrito intermediário / severo (sem lubrificação ideal)

% Varredura angular do balancim (15° a 48°)
ang_sweep = linspace(15, 48, 250);
rad_sweep = deg2rad(ang_sweep);

% Geometria exata para L4 = L5 e O2 simétrico de Norton (K = 2):
L4_curve = h ./ (2.0 .* (1.0 - cos(rad_sweep)));
M_curve  = h ./ (2.0 .* sin(rad_sweep / 2.0));
L2_curve = M_curve / 2.0;
L3_curve = 1.5 .* M_curve;

L_tot = zeros(size(ang_sweep));
for k = 1:length(ang_sweep)
    dt_k = rad_sweep(k);
    l4_k = L4_curve(k);
    b2_k = [0; -l4_k];
    b1_k = [-l4_k * sin(dt_k); -l4_k * cos(dt_k)];
    m_k = b1_k - b2_k;
    o2_k = b2_k + 2 * m_k;
    d_k = norm(o2_k);
    L_tot(k) = L2_curve(k) + L3_curve(k) + 2*l4_k + d_k;
end

% -------------------------------------------------------------------------
% 2. Força Transversal e Eficiência Mecânica na Guia Prismática
% -------------------------------------------------------------------------
% Na posição de máxima deflexão (topo de contato), beta_max = Delta_theta4
tan_beta = tan(rad_sweep);
F_trans = F_axial .* tan_beta; % Força normal transversal na guia (N)

% Eficiência mecânica da transmissão na guia:
% F_total_necessaria = F_axial + mu_atrito * F_trans = F_axial * (1 + mu_atrito * tan_beta)
% eta_guia = F_axial / F_total_necessaria = 1 / (1 + mu_atrito * tan_beta)
eta_guia_lub  = (1.0 ./ (1.0 + mu_lub .* tan_beta)) .* 100;  % [%]
eta_guia_seco = (1.0 ./ (1.0 + mu_seco .* tan_beta)) .* 100; % [%]

% Ponto de projeto de validação: Delta_theta4 = 30°
dt_30 = deg2rad(30.0);
l4_30 = h / (2.0 * (1.0 - cos(dt_30)));
m_30 = h / (2.0 * sin(dt_30 / 2.0));
l2_30 = m_30 / 2.0;
l3_30 = 1.5 * m_30;
b2_30 = [0; -l4_30];
b1_30 = [-l4_30 * sin(dt_30); -l4_30 * cos(dt_30)];
o2_30 = b2_30 + 2 * (b1_30 - b2_30);
d_30 = norm(o2_30);
L_tot_30 = l2_30 + l3_30 + 2*l4_30 + d_30;
F_trans_30 = F_axial * tan(dt_30);
eta_30_lub = (1.0 / (1.0 + mu_lub * tan(dt_30))) * 100;

% Ponto de comparação: Delta_theta4 = 25° (Projeto Anterior)
dt_25 = deg2rad(25.0);
l4_25 = h / (2.0 * (1.0 - cos(dt_25)));
m_25 = h / (2.0 * sin(dt_25 / 2.0));
l2_25 = m_25 / 2.0;
l3_25 = 1.5 * m_25;
b2_25 = [0; -l4_25];
b1_25 = [-l4_25 * sin(dt_25); -l4_25 * cos(dt_25)];
o2_25 = b2_25 + 2 * (b1_25 - b2_25);
d_25 = norm(o2_25);
L_tot_25 = l2_25 + l3_25 + 2*l4_25 + d_25;
F_trans_25 = F_axial * tan(dt_25);
eta_25_lub = (1.0 / (1.0 + mu_lub * tan(dt_25))) * 100;

fprintf('========================================================================================\n');
fprintf('VALIDAÇÃO DO COMPROMISSO DO ÂNGULO DO BALANCIM (25° vs 30°)\n');
fprintf('========================================================================================\n');
fprintf('Parâmetro / Métrica             | delta = 25° (Anterior)   | delta = 30° (Validado/Ótimo)\n');
fprintf('----------------------------------------------------------------------------------------\n');
fprintf('Comprimento Balancim (L4 = L5)  | %8.2f mm              | %8.2f mm (-30.0%%)\n', l4_25, l4_30);
fprintf('Comprimento Manivela (L2)       | %8.2f mm              | %8.2f mm (-16.4%%)\n', l2_25, l2_30);
fprintf('Comprimento Biela (L3)          | %8.2f mm              | %8.2f mm (-16.4%%)\n', l3_25, l3_30);
fprintf('Distância entre Mancais (d)     | %8.2f mm              | %8.2f mm (-26.1%%)\n', d_25, d_30);
fprintf('COMPACTABILIDADE TOTAL (L_tot)  | %8.2f mm              | %8.2f mm (-26.0%%)\n', L_tot_25, L_tot_30);
fprintf('Força Transversal Máx (F_trans) | %8.1f N (0.47 F_axial) | %8.1f N (0.58 F_axial)\n', F_trans_25, F_trans_30);
fprintf('Eficiência Guia (mu = 0.10)     | %8.2f %%               | %8.2f %% (Perda: 5.5%%)\n', eta_25_lub, eta_30_lub);
fprintf('========================================================================================\n\n');

% -------------------------------------------------------------------------
% 3. Construção da Figura com X Compartilhado (Dual Y-Axis)
% -------------------------------------------------------------------------
fig = figure('Name', 'Tradeoff Compacidade vs Forca Guia', 'NumberTitle', 'off', 'Position', [80, 80, 1050, 750]);

% === SUBPLOT 1: GRÁFICO COM X COMPARTILHADO (L_tot à esquerda, F_transversal à direita) ===
subplot(2, 1, 1);

cor_azul = [0.00, 0.35, 0.75]; % Comprimento total
cor_verm = [0.85, 0.15, 0.15]; % Força transversal

[ax, h_comp, h_forca] = plotyy(ang_sweep, L_tot, ang_sweep, F_trans);

% Configurações da curva da Esquerda (Comprimento Total)
set(h_comp, 'Color', cor_azul, 'LineWidth', 2.8);
set(ax(1), 'YColor', cor_azul, 'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax(1), 'Envelope Linear Total L_{tot} (mm)', 'FontSize', 11, 'Color', cor_azul);
ylim(ax(1), [200, 1600]);
set(ax(1), 'YTick', 200:200:1600);
grid(ax(1), 'on');

% Configurações da curva da Direita (Força Transversal na Guia)
set(h_forca, 'Color', cor_verm, 'LineWidth', 2.8);
set(ax(2), 'YColor', cor_verm, 'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax(2), 'Força Transversal Máx na Guia F_{trans} (N)', 'FontSize', 11, 'Color', cor_verm);
ylim(ax(2), [1000, 6000]);
set(ax(2), 'YTick', 1000:1000:6000);

xlim(ax(1), [15, 48]);
xlim(ax(2), [15, 48]);
xlabel(ax(1), 'Ângulo de Oscilação do Balancim \Delta\theta_4 (graus)', 'FontSize', 11, 'FontWeight', 'bold');

% Linhas verticais de referência para 25° e 30°
hold(ax(1), 'on');
hold(ax(2), 'on');

% Faixa ótima recomendada (25° a 32°) sombreada em verde suave no ax(1)
fill(ax(1), [25, 32, 32, 25], [200, 200, 1600, 1600], [0.88, 0.96, 0.88], 'EdgeColor', 'none');

% Re-plot das curvas para ficarem visíveis sobre o preenchimento
plot(ax(1), ang_sweep, L_tot, 'Color', cor_azul, 'LineWidth', 2.8);
plot(ax(2), ang_sweep, F_trans, 'Color', cor_verm, 'LineWidth', 2.8);

% Linha vertical tracejada do ângulo de 30° (Validado)
plot(ax(1), [30, 30], [200, 1600], 'Color', [0.1 0.6 0.2], 'LineStyle', '--', 'LineWidth', 2.0);
plot(ax(1), 30, L_tot_30, 's', 'MarkerFaceColor', cor_azul, 'MarkerEdgeColor', 'k', 'MarkerSize', 9);
plot(ax(2), 30, F_trans_30, 'o', 'MarkerFaceColor', cor_verm, 'MarkerEdgeColor', 'k', 'MarkerSize', 9);

% Linha vertical pontilhada do ângulo de 25° (Projeto Anterior)
plot(ax(1), [25, 25], [200, 1600], 'Color', [0.4 0.4 0.4], 'LineStyle', ':', 'LineWidth', 1.5);
plot(ax(1), 25, L_tot_25, 's', 'MarkerFaceColor', [0.3 0.5 0.8], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
plot(ax(2), 25, F_trans_25, 'o', 'MarkerFaceColor', [0.9 0.4 0.4], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

% Rótulos explicativos
text(ax(1), 30.6, 680, sprintf('\\Delta\\theta_4 = 30° (Ótimo):\n\\bullet L_{tot} = 478.6 mm (-26%%)\n\\bullet F_{trans} = 2887 N'), ...
     'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.1 0.5 0.1], 'BackgroundColor', [1 1 1]);

text(ax(1), 16, 1450, 'Região Inviável:\nBarras gigantescas (L_{tot} > 1.1 m)', 'FontSize', 8.5, 'Color', [0.5 0.1 0.1]);
text(ax(1), 37, 1350, 'Região Crítica:\nForça normal > 3.5 kN\nRisco de emperramento', 'FontSize', 8.5, 'Color', [0.7 0.1 0.1]);

title(ax(1), 'Trade-Off Fundamental: Compacidade Dimensional vs. Esforço Transversal na Guia Prismática', ...
      'FontSize', 12, 'FontWeight', 'bold');

% Legenda combinada
legend([h_comp, h_forca], ...
       {'Compacidade: Envelope Linear Total L_{tot} (mm) [Eixo Esquerdo]', ...
        'Esforço Normal: Força Transversal Máx F_{trans} = 5000 \cdot tan(\Delta\theta_4) (N) [Eixo Direito]'}, ...
       'Location', 'northeast', 'FontSize', 9);

% === SUBPLOT 2: EFICIÊNCIA MECÂNICA DA GUIA (PERDAS POR ATRITO) ===
subplot(2, 1, 2);
hold on; grid on;

% Faixa ótima recomendada (25° a 32°) sombreada em verde suave
fill([25, 32, 32, 25], [85, 85, 100, 100], [0.88, 0.96, 0.88], 'EdgeColor', 'none');

h_eta1 = plot(ang_sweep, eta_guia_lub, 'Color', [0.10, 0.65, 0.25], 'LineWidth', 2.4);
h_eta2 = plot(ang_sweep, eta_guia_seco, 'Color', [0.85, 0.45, 0.10], 'LineStyle', '--', 'LineWidth', 2.2);

% Linhas dos pontos 25° e 30°
plot([30, 30], [85, 100], 'Color', [0.1 0.6 0.2], 'LineStyle', '--', 'LineWidth', 1.8);
plot([25, 25], [85, 100], 'Color', [0.4 0.4 0.4], 'LineStyle', ':', 'LineWidth', 1.3);

plot(30, eta_30_lub, 's', 'MarkerFaceColor', [0.10, 0.65, 0.25], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
plot(25, eta_25_lub, 's', 'MarkerFaceColor', [0.4 0.7 0.4], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

% Rótulo em 30°
text(30.6, 94.2, sprintf('Em 30°:\n\\eta = 94.5%% (\\mu_{atrito} = 0.10)\n\\eta = 92.0%% (\\mu_{atrito} = 0.15)\nPerda de rendimento: ~5.5%%'), ...
     'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.5 0.1], 'BackgroundColor', [1 1 1]);

% Limite de perda crítica aceitável (90%)
plot([15, 48], [90, 90], 'r--', 'LineWidth', 1.2);
text(16, 90.5, 'Limite Mínimo de Eficiência Aceitável na Guia (\eta \geq 90%)', 'FontSize', 8.5, 'Color', 'r', 'FontWeight', 'bold');

title('Eficiência Mecânica de Transmissão da Guia Linear do Pistão: \eta_{guia} = 1 / (1 + \mu_{atrito} \cdot tan\Delta\theta_4)', ...
      'FontSize', 11, 'FontWeight', 'bold');
xlabel('Ângulo de Oscilação do Balancim \Delta\theta_4 (graus)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Eficiência Mecânica da Guia \eta (%)', 'FontSize', 11);
xlim([15, 48]); ylim([87, 98.5]);

legend([h_eta1, h_eta2], ...
       {'Eficiência com Lubrificação Adequada (\mu_{atrito} = 0.10, Bronze Sintetizado/PTFE)', ...
        'Eficiência sob Lubrificação Severa/Mista (\mu_{atrito} = 0.15)'}, ...
       'Location', 'southwest', 'FontSize', 9);

caminho_fig = fullfile(assets_dir, 'tradeoff_compacidade_forca_guia_30graus.png');
print(fig, caminho_fig, '-dpng', '-r300');
fprintf('Figura salva com sucesso em: %s\n', caminho_fig);

fprintf('\nExecução concluída com sucesso!\n');
