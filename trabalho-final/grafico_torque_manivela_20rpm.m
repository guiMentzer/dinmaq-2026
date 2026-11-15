% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Geração do Gráfico de Torque na Manivela T_2(theta_2) e T_2(t)
% para Velocidade Angular Constante de 20 RPM (20 frutos/minuto)
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Parâmetros do Mecanismo e de Operação (20 RPM Constante)
% -------------------------------------------------------------------------
RPM = 20.0;                        % 20 frutos por minuto
w2  = RPM * 2.0 * pi / 60.0;       % Velocidade angular constante = 2.0944 rad/s
T_ciclo = 60.0 / RPM;              % Período de 1 ciclo = 3.00 s

h_curso = 30.0e-3;                 % Curso total = 30 mm (0.030 m)
delta_quebra = 10.0e-3;            % Curso de quebra do baru = 10 mm (0.010 m)
F_max = 5000.0;                    % Força máxima de cisalhamento = 5000 N
mu_guia = 0.10;                    % Coeficiente de atrito na guia prismática
m_eq_pistao = 2.5;                 % Massa equivalente (pistão + navalha + metade bielas) = 2.5 kg
g = 9.81;                          % Gravidade (m/s^2)

dt = deg2rad(30.0);                % Oscilação do balancim = 30°
L4 = h_curso / (2.0 * (1.0 - cos(dt))); % 0.1119615 m (111.96 mm)
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4];
B1 = [-L4*sin(dt); -L4*cos(dt)];
M_vec = B1 - B2;
corda_M = norm(M_vec);

% Configuração K = 1.5 (Ultra-Compacta)
O2 = B2 + 1.5 * M_vec;
L2 = corda_M / 2.0;                % 0.02898 m (28.98 mm)
L3 = corda_M;                      % 0.05796 m (57.96 mm)

y_pmi = -2.0 * L4;                 % -0.223923 m
y_pms = -2.0 * L4 * cos(dt);       % -0.193923 m
y_contato = y_pmi + delta_quebra;  % -0.213923 m (início da quebra a 10 mm do PMI)

% -------------------------------------------------------------------------
% 2. Solução Cinemática Completa: Posição, Velocidade e Aceleração
% -------------------------------------------------------------------------
N = 3600;
th2_deg = linspace(0, 360, N);
th2_rad = deg2rad(th2_deg);
dth = th2_rad(2) - th2_rad(1);
tempo = (th2_deg / 360.0) * T_ciclo; % Vetor de tempo de 0 a 3.00 s

y_p   = zeros(1, N);
beta5 = zeros(1, N); % Ângulo de obliquidade da biela 5 com a vertical

for i = 1:N
    t2 = th2_rad(i);
    xA = O2(1) + L2 * cos(t2);
    yA = O2(2) + L2 * sin(t2);
    d_A = hypot(xA, yA);
    a_c = (L4^2 - L3^2 + d_A^2) / (2.0 * d_A);
    h_c = sqrt(max(0.0, L4^2 - a_c^2));
    x2_c = a_c * xA / d_A;
    y2_c = a_c * yA / d_A;
    p_plus  = [x2_c + h_c * (-yA)/d_A; y2_c + h_c * (xA)/d_A];
    p_minus = [x2_c - h_c * (-yA)/d_A; y2_c - h_c * (xA)/d_A];
    if p_plus(1) <= 1e-4 && p_plus(2) < 0
        B = p_plus;
    else
        B = p_minus;
    end
    y_p(i) = B(2) - sqrt(L5^2 - B(1)^2);
    beta5(i) = asin(abs(B(1)) / L5);
end

% Coeficientes cinemáticos de 1ª e 2ª ordem do pistão:
% h_p  = dy_p / dtheta2 = v_p / w2 (m/rad)
% dh_p = d^2(y_p) / dtheta2^2 = a_p / w2^2 (m/rad^2)
h_p  = gradient(y_p, dth);
dh_p = gradient(h_p, dth);

v_p = h_p * w2;       % Velocidade linear da faca (m/s)
a_p = dh_p * (w2^2);  % Aceleração linear da faca (m/s^2)

% Rendimento instantâneo da guia prismática devido à obliquidade beta5:
% eta_guia = 1 - mu_guia * tan(beta5)
eta_guia = 1.0 - mu_guia * tan(beta5);
eta_juntas = 0.96; % Rendimento dos mancais de rolamento/buchas
eta_inst = eta_guia * eta_juntas;

% -------------------------------------------------------------------------
% 3. Cálculo do Torque na Manivela T_2(theta_2) por Trabalhos Virtuais
% -------------------------------------------------------------------------
% Identificar zona de descida onde ocorre a quebra de 10 mm:
idx_quebra = find((th2_deg > 166.0) & (y_p <= y_contato));
th2_ini_quebra = th2_deg(idx_quebra(1));
t_ini_quebra   = tempo(idx_quebra(1));

% Penetração normalizada s em [0, 1] nos 10 mm finais:
s_pen = zeros(1, N);
s_pen(idx_quebra) = (y_contato - y_p(idx_quebra)) / delta_quebra;

% Perfis de Força de Cisalhamento F_baru(theta2):
% 1) Carga Progressiva Linear (0 -> 5000 N nos 10 mm)
F_baru_lin = zeros(1, N);
F_baru_lin(idx_quebra) = F_max * s_pen(idx_quebra);

% 2) Carga de Biomaterial Lenhoso (s^0.4 -> subida rápida inicial e pico de 5000 N)
F_baru_bio = zeros(1, N);
F_baru_bio(idx_quebra) = F_max * (s_pen(idx_quebra).^0.4);

% 3) Carga Constante (Degrau de 5000 N durante todos os 10 mm)
F_baru_const = zeros(1, N);
F_baru_const(idx_quebra) = F_max;

% Parcelas de Inércia e Peso Próprio (em N.m):
% Pelo PTV: T_inercia + T_peso = m_eq * (a_p + g) * (dy_p / dtheta2)
T_inercia_peso = m_eq_pistao * (a_p + g) .* h_p;

% Torque Total na Manivela T_2 (N.m) para cada modelo de carga:
% Na descida (h_p < 0), F_baru aponta para cima (+Y), realizando trabalho resistente (-F_baru * h_p > 0)
T2_lin   = (-F_baru_lin   .* h_p) ./ eta_inst + T_inercia_peso;
T2_bio   = (-F_baru_bio   .* h_p) ./ eta_inst + T_inercia_peso;
T2_const = (-F_baru_const .* h_p) ./ eta_inst + T_inercia_peso;

% Torque médio no ciclo (N.m) e Potência média (W)
Tm_lin   = trapz(th2_rad, T2_lin)   / (2*pi);
Tm_bio   = trapz(th2_rad, T2_bio)   / (2*pi);
Tm_const = trapz(th2_rad, T2_const) / (2*pi);

[Tpico_lin, id_lin]     = max(T2_lin);
[Tpico_bio, id_bio]     = max(T2_bio);
[Tpico_const, id_const] = max(T2_const);

fprintf('===================================================================\n');
fprintf('RESULTADOS DO TORQUE NA MANIVELA A 20 RPM CONSTANTE (w2 = 2.094 rad/s)\n');
fprintf('===================================================================\n');
fprintf('Início da quebra (10 mm antes do PMI): theta_2 = %.2f° (t = %.2f s)\n', th2_ini_quebra, t_ini_quebra);
fprintf('Fim da quebra (PMI):                   theta_2 = 360.00° (t = 3.00 s)\n');
fprintf('-------------------------------------------------------------------\n');
fprintf('1. Modelo Linear Progressivo (0 -> 5 kN):\n');
fprintf('   - Torque de Pico T_max: %.2f N.m (em theta_2 = %.1f°, t = %.2f s)\n', Tpico_lin, th2_deg(id_lin), tempo(id_lin));
fprintf('   - Torque Médio T_med:   %.2f N.m (Potência Média = %.2f W | Pico = %.1f W)\n', Tm_lin, Tm_lin*w2, Tpico_lin*w2);
fprintf('2. Modelo Biomaterial Real (Endocarpo Lenhoso):\n');
fprintf('   - Torque de Pico T_max: %.2f N.m (em theta_2 = %.1f°, t = %.2f s)\n', Tpico_bio, th2_deg(id_bio), tempo(id_bio));
fprintf('   - Torque Médio T_med:   %.2f N.m (Potência Média = %.2f W | Pico = %.1f W)\n', Tm_bio, Tm_bio*w2, Tpico_bio*w2);
fprintf('3. Modelo Degrau Constante (5 kN constantes nos 10 mm):\n');
fprintf('   - Torque de Pico T_max: %.2f N.m (em theta_2 = %.1f°, t = %.2f s)\n', Tpico_const, th2_deg(id_const), tempo(id_const));
fprintf('   - Torque Médio T_med:   %.2f N.m (Potência Média = %.2f W | Pico = %.1f W)\n', Tm_const, Tm_const*w2, Tpico_const*w2);
fprintf('===================================================================\n');

% -------------------------------------------------------------------------
% 4. Geração da Figura Técnica de 3 Painéis (300 DPI)
% -------------------------------------------------------------------------
fig = figure('Visible', 'off', 'Position', [50, 50, 1350, 860], 'Color', 'w');

% --- PAINEL SUPERIOR (Largura Total): Torque na Manivela T2(theta2) e T2(t) ---
subplot(2, 2, [1, 2]);
hold on; grid on;

% Sombrear as fases do ciclo
fill([0, 166.0, 166.0, 0], [-5, -5, 110, 110], [0.93, 0.97, 0.93], 'EdgeColor', 'none');
fill([166.0, th2_ini_quebra, th2_ini_quebra, 166.0], [-5, -5, 110, 110], [0.94, 0.96, 1.00], 'EdgeColor', 'none');
fill([th2_ini_quebra, 360.0, 360.0, th2_ini_quebra], [-5, -5, 110, 110], [1.00, 0.90, 0.86], 'EdgeColor', 'none');

plot([0, 360], [0, 0], 'k-', 'LineWidth', 1.0);
plot([166.0, 166.0], [-5, 110], 'k:', 'LineWidth', 1.2);
plot([th2_ini_quebra, th2_ini_quebra], [-5, 110], 'r-.', 'LineWidth', 1.5);

% Curvas de Torque
h_c = plot(th2_deg, T2_const, 'Color', [0.50, 0.50, 0.55], 'LineStyle', '--', 'LineWidth', 2.0);
h_b = plot(th2_deg, T2_bio,   'Color', [0.90, 0.45, 0.00], 'LineStyle', '-.', 'LineWidth', 2.2);
h_l = plot(th2_deg, T2_lin,   'Color', [0.82, 0.12, 0.12], 'LineStyle', '-',  'LineWidth', 2.8);
h_m = plot([0, 360], [Tm_lin, Tm_lin], 'Color', [0.00, 0.42, 0.82], 'LineStyle', '--', 'LineWidth', 2.0);

% Marcadores de Pico
plot(th2_deg(id_lin), Tpico_lin, 'ro', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
plot(th2_deg(id_bio), Tpico_bio, 's',  'MarkerFaceColor', [0.95 0.5 0], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
plot(th2_deg(id_const), Tpico_const, '^', 'MarkerFaceColor', [0.6 0.6 0.65], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

% Anotações Técnicas
text(83, 55, 'FASE 1: RETORNO / SUBIDA (0° a 166°)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.15 0.50 0.20], 'HorizontalAlignment', 'center');
text(83, 45, 'Apenas peso próprio + inércia (T_2 \approx +0.4 N\cdotm)', 'FontSize', 8.2, 'Color', [0.2 0.4 0.2], 'HorizontalAlignment', 'center');

text(212, 100, 'FASE 2: DESCIDA EM VAZIO', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.15 0.35 0.65], 'HorizontalAlignment', 'center');
text(212, 91, '(166° a 258° — 20 mm livres)', 'FontSize', 8.2, 'Color', [0.15 0.35 0.65], 'HorizontalAlignment', 'center');

text(312, 100, 'FASE 3: QUEBRA DO BARU (10 mm)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.75 0.12 0.08], 'HorizontalAlignment', 'center');
text(312, 91, '(258° a 360° — \Deltat = 0.85 s a 20 RPM)', 'FontSize', 8.2, 'Color', [0.75 0.12 0.08], 'HorizontalAlignment', 'center');

text(th2_deg(id_lin) + 5, Tpico_lin + 4, sprintf('Pico Linear: %.1f N\\cdotm (\\theta_2 = %.0f°)', Tpico_lin, th2_deg(id_lin)), ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.75 0.10 0.10]);
text(th2_deg(id_bio) + 5, Tpico_bio + 3.5, sprintf('Pico Biomaterial: %.1f N\\cdotm (\\theta_2 = %.0f°)', Tpico_bio, th2_deg(id_bio)), ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.80 0.35 0.00]);
text(th2_deg(id_const) - 4, 75, sprintf('Pico Degrau 5 kN: %.1f N\\cdotm', Tpico_const), ...
     'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.35 0.35 0.40], 'HorizontalAlignment', 'right');

text(105, Tm_lin + 4.5, sprintf('Torque Médio Equivalente: T_m = %.2f N\\cdotm', Tm_lin), ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.00 0.35 0.75], 'HorizontalAlignment', 'center');

title('1. Diagrama Completo de Torque na Manivela T_2(\theta_2) a Velocidade Constante (20 RPM — T = 3.00 s)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Ângulo da Manivela \theta_2 (graus)   [Nota: 0° = 0.0 s | 120° = 1.0 s | 240° = 2.0 s | 360° = 3.0 s]', 'FontSize', 9.5);
ylabel('Torque Exigido na Manivela T_2 (N\cdotm)', 'FontSize', 9.5);
legend([h_l, h_b, h_c, h_m], ...
       {'Carga Linear Progressiva (0 \rightarrow 5 kN nos 10 mm)', ...
        'Carga Biomaterial Lenhoso (F \propto s^{0.4} até 5 kN)', ...
        'Carga Plena Constante (Degrau de 5 kN nos 10 mm)', ...
        'Torque Médio do Ciclo T_{méd} (Linear)'}, ...
       'Location', 'northwest', 'FontSize', 8.2);
xlim([0, 360]); ylim([-4, 110]);

% --- PAINEL INFERIOR ESQUERDO: Coeficiente Cinemático |dy_p/dtheta2| vs Força ---
subplot(2, 2, 3);
hold on; grid on;

[ax, h_f, h_v] = plotyy(th2_deg(idx_quebra), F_baru_lin(idx_quebra)/1000, ...
                        th2_deg(idx_quebra), abs(h_p(idx_quebra))*1000);
hold(ax(1), 'on'); hold(ax(2), 'on');

set(h_f, 'Color', [0.82, 0.12, 0.12], 'LineWidth', 2.4, 'LineStyle', '-');
plot(ax(1), th2_deg(idx_quebra), F_baru_bio(idx_quebra)/1000, 'Color', [0.90, 0.45, 0.00], 'LineWidth', 2.0, 'LineStyle', '-.');

set(h_v, 'Color', [0.05, 0.55, 0.25], 'LineWidth', 2.5, 'LineStyle', '-');

set(ax(1), 'YColor', [0.82, 0.12, 0.12], 'XLim', [255, 360], 'YLim', [0, 5.5]);
set(ax(2), 'YColor', [0.05, 0.55, 0.25], 'XLim', [255, 360], 'YLim', [0, 22]);

ylabel(ax(1), 'Força de Corte no Baru F_{baru} (kN)', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax(2), 'Braço Cinemático |dy_p / d\theta_2| (mm/rad)', 'FontSize', 9.5, 'FontWeight', 'bold');
xlabel(ax(1), 'Ângulo da Manivela na Zona de Quebra \theta_2 (graus)', 'FontSize', 9.5);
title('2. Por que o Torque cai a Zero no PMI? (Força \times Braço Cinemático)', 'FontSize', 10, 'FontWeight', 'bold');

text(ax(1), 324, 2.4, sprintf('No PMI (360°): F = 5 kN,\nmas |dy_p/d\\theta_2| = 0 mm/rad\n-> Torque T_2 = 0 N\\cdotm!'), ...
     'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.2], 'HorizontalAlignment', 'center');

legend([h_f; findobj(ax(1), 'LineStyle', '-.'); h_v], ...
       {'Força Linear F_{baru} (kN)', 'Força Biomaterial (kN)', 'Braço Cinemático |dy_p/d\theta_2| (mm/rad)'}, ...
       'Location', 'southwest', 'FontSize', 7.8);

% --- PAINEL INFERIOR DIREITO: Torque no Domínio do Tempo T_2(t) e Potência P(t) ---
subplot(2, 2, 4);
hold on; grid on;

[ax_t, h_t, h_p_w] = plotyy(tempo, T2_lin, tempo, T2_lin * w2);
hold(ax_t(1), 'on'); hold(ax_t(2), 'on');

set(h_t,   'Color', [0.75, 0.12, 0.12], 'LineWidth', 2.5);
set(h_p_w, 'Color', [0.00, 0.45, 0.85], 'LineWidth', 1.8, 'LineStyle', ':');

plot(ax_t(1), tempo, T2_bio, 'Color', [0.90, 0.45, 0.00], 'LineWidth', 2.0, 'LineStyle', '-.');
plot(ax_t(1), [t_ini_quebra, t_ini_quebra], [-5, 60], 'k--', 'LineWidth', 1.2);

set(ax_t(1), 'YColor', [0.75, 0.12, 0.12], 'XLim', [0, 3.0], 'YLim', [-3, 60]);
set(ax_t(2), 'YColor', [0.00, 0.45, 0.85], 'XLim', [0, 3.0], 'YLim', [-3*w2, 60*w2]);

ylabel(ax_t(1), 'Torque na Manivela T_2(t) (N\cdotm)', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax_t(2), 'Potência Instantânea P(t) = T_2 \cdot \omega_2 (Watts)', 'FontSize', 9.5, 'FontWeight', 'bold');
xlabel(ax_t(1), 'Tempo do Ciclo t (segundos) — 20 RPM (1 fruto a cada 3.00 s)', 'FontSize', 9.5);
title('3. Evolução Temporal do Torque T_2(t) e Potência Instantânea P(t)', 'FontSize', 10, 'FontWeight', 'bold');

text(ax_t(1), 2.12, 45, sprintf('Início do Corte:\nt = %.2f s\n(duração 0.85 s)', t_ini_quebra), ...
     'FontSize', 8.2, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
text(ax_t(1), 1.05, 10, sprintf('Ciclo de 3.00 s:\n- 0.00 a 2.15 s: Livre (P \\approx 0 W)\n- 2.15 a 3.00 s: Corte (P_{pico} = %.1f W)', Tpico_lin*w2), ...
     'FontSize', 8.2, 'Color', [0.2 0.2 0.25], 'HorizontalAlignment', 'center');

out_file = fullfile(assets_dir, 'torque_manivela_20rpm_constante.png');
print(fig, out_file, '-dpng', '-r300');
close(fig);
fprintf('\nGráfico salvo com sucesso em: %s\n', out_file);
