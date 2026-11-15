% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Dimensionamento do Volante de Inércia em Aro (20 RPM, Quebra de 10 mm)
% e Simulação Numérica da EDO Não-Linear de Movimento (ode45)
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Parâmetros Cinemáticos e de Operação (20 RPM, Curso de Quebra = 10 mm)
% -------------------------------------------------------------------------
h_curso = 30.0e-3;       % Curso total da navalha = 30 mm (0.030 m)
delta_quebra = 10.0e-3;  % Curso efetivo de quebra do baru = 10 mm (0.010 m)
F_max = 5000.0;          % Força máxima de cisalhamento = 5000 N
eta_mec = 0.90;          % Rendimento mecânico das juntas e guia prismática

RPM_alvo = 20.0;                   % Rotação nominal = 20 RPM
w_med = RPM_alvo * 2 * pi / 60.0;  % 2.0944 rad/s
T_ciclo = 60.0 / RPM_alvo;         % 3.00 s por ciclo

dt = deg2rad(30.0);
L4 = h_curso / (2.0 * (1.0 - cos(dt))); % 0.1119615 m
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4];
B1 = [-L4*sin(dt); -L4*cos(dt)];
M_vec = B1 - B2;
corda_M = norm(M_vec);

O2 = B2 + 1.5 * M_vec;   % Configuração Ultra-Compacta K = 1.5
L2 = corda_M / 2.0;      % 0.02898 m
L3 = corda_M;            % 0.05796 m

y_pmi = -2.0 * L4;                 % -0.223923 m
y_pms = -2.0 * L4 * cos(dt);       % -0.193923 m
y_contato = y_pmi + delta_quebra;  % -0.213923 m (10 mm acima do PMI)

% -------------------------------------------------------------------------
% 2. Pré-Cálculo Cinemático e Diagrama de Torque Resistente T_res(theta2)
% -------------------------------------------------------------------------
N_pts = 3600;
th2_deg = linspace(0, 360, N_pts);
th2_rad = deg2rad(th2_deg);
dth = th2_rad(2) - th2_rad(1);

y_p = zeros(1, N_pts);
for i = 1:N_pts
    t2 = th2_rad(i);
    xA = O2(1) + L2 * cos(t2);
    yA = O2(2) + L2 * sin(t2);
    d_A = hypot(xA, yA);
    a_c = (L4^2 - L3^2 + d_A^2) / (2.0 * d_A);
    h_c = sqrt(max(0.0, L4^2 - a_c^2));
    x2_c = a_c * xA / d_A;
    y2_c = a_c * yA / d_A;
    p_plus = [x2_c + h_c * (-yA)/d_A; y2_c + h_c * (xA)/d_A];
    p_minus = [x2_c - h_c * (-yA)/d_A; y2_c - h_c * (xA)/d_A];
    if p_plus(1) <= 1e-4 && p_plus(2) < 0
        B = p_plus;
    else
        B = p_minus;
    end
    y_p(i) = B(2) - sqrt(L5^2 - B(1)^2);
end

% Coeficiente cinemático de velocidade do pistão: h_p = dy_p / dtheta2 (m/rad)
h_p = gradient(y_p, dth);
dh_p = gradient(h_p, dth);

% Região de descida com contato no baru (últimos 10 mm antes do PMI)
idx_quebra = find((th2_deg > 166.0) & (y_p <= y_contato));
th2_ini_deg = th2_deg(idx_quebra(1));

% Penetração normalizada s em [0, 1] ao longo dos 10 mm
s_pen = zeros(1, N_pts);
s_pen(idx_quebra) = (y_contato - y_p(idx_quebra)) / delta_quebra;

% Perfis de Força F(y):
% 1) Linear Progressivo (0 -> 5000 N nos 10 mm: W_corte = 25.0 J)
F_lin = zeros(1, N_pts);
F_lin(idx_quebra) = F_max * s_pen(idx_quebra);

% 2) Constante Pleno (5000 N constantes nos 10 mm: W_corte = 50.0 J)
F_const = zeros(1, N_pts);
F_const(idx_quebra) = F_max;

% Torque resistente refletido no eixo da manivela (N.m)
T_res_lin   = (F_lin   .* abs(h_p)) / eta_mec;
T_res_const = (F_const .* abs(h_p)) / eta_mec;

% Trabalho por ciclo e Torque constante do motor
W_ciclo_lin   = trapz(th2_rad, T_res_lin);
Tm_lin        = W_ciclo_lin / (2*pi);
dE_lin        = trapz(th2_rad, max(0, T_res_lin - Tm_lin));

W_ciclo_const = trapz(th2_rad, T_res_const);
Tm_const      = W_ciclo_const / (2*pi);
dE_const      = trapz(th2_rad, max(0, T_res_const - Tm_const));

% Ângulos onde T_res_lin cruza Tm_lin (limites da zona de déficit de energia)
idx_deficit = find(T_res_lin > Tm_lin);
th_A_deg = th2_deg(idx_deficit(1));
th_B_deg = th2_deg(idx_deficit(end));

% -------------------------------------------------------------------------
% 3. Integração Numérica da EDO Não-Linear via ode45 (Dinâmica Direta)
% -------------------------------------------------------------------------
% Equação de movimento:
% I_eq(th2) * d(w2)/dt + 0.5 * dI_eq/dth2 * w2^2 = T_motor - T_res(th2)
% onde I_eq(th2) = I_volante + m_pistao * h_p(th2)^2
m_eq_pistao = 2.5; % Massa equivalente do pistão + faca + bielas (kg)

% Testar 3 valores de Inércia do Volante em Aro (para o caso Linear Progressivo):
% Caso 1: Cf = 0.10 -> I1 = 50.89 kg.m^2 (Volante Grande / Industrial)
% Caso 2: Cf = 0.20 -> I2 = 25.44 kg.m^2 (Volante Padrão Norton p/ Prensas)
% Caso 3: Cf = 0.35 -> I3 = 14.54 kg.m^2 (Volante Compacto Econômico)
I_casos = [dE_lin/(w_med^2 * 0.10), dE_lin/(w_med^2 * 0.20), dE_lin/(w_med^2 * 0.35)];
nomes_casos = {
    sprintf('C_f = 10%% (I = %.1f kg\\cdotm^2)', I_casos(1)),
    sprintf('C_f = 20%% (I = %.1f kg\\cdotm^2 - Recomendado)', I_casos(2)),
    sprintf('C_f = 35%% (I = %.1f kg\\cdotm^2 - Compacto)', I_casos(3))
};
cores_casos = {[0.00, 0.45, 0.85], [0.10, 0.65, 0.25], [0.85, 0.20, 0.10]};

% Simular 3 ciclos completos (9.0 segundos)
t_span = linspace(0, 3 * T_ciclo, 1500);
opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-7, 'MaxStep', 0.01);

sol_t = cell(1, 3);
sol_th = cell(1, 3);
sol_rpm = cell(1, 3);

for c = 1:3
    I_vol = I_casos(c);
    % A velocidade em theta2 = 0 (PMI) é próxima de w_min!
    % Para iniciar já em regime periódico estacionário:
    % Entre th_B (~352°) e 360°, o motor já acelerou um pouco, mas ainda está perto de w_min.
    % Calculamos w0 exato pelo balanço energético:
    % Em th2 = 0, a energia acumulada desde th_B é int_{th_B}^{360} (Tm - T_res) dth
    w_min_est = w_med * (1 - (dE_lin / (I_vol * w_med^2)) / 2);
    x0 = [0.0; w_min_est];
    
    edo_fn = @(t, x) [
        x(2);
        (Tm_lin - interp1(th2_rad, T_res_lin, mod(x(1), 2*pi), 'linear') ...
         - m_eq_pistao * interp1(th2_rad, h_p .* dh_p, mod(x(1), 2*pi), 'linear') * x(2)^2) ...
        / (I_vol + m_eq_pistao * (interp1(th2_rad, h_p, mod(x(1), 2*pi), 'linear'))^2)
    ];
    
    [t_out, x_out] = ode45(edo_fn, t_span, x0, opts);
    sol_t{c} = t_out;
    sol_th{c} = x_out(:, 1);
    sol_rpm{c} = x_out(:, 2) * 60.0 / (2*pi);
end

% -------------------------------------------------------------------------
% 4. Geração da Figura Técnica de 4 Painéis (300 DPI)
% -------------------------------------------------------------------------
fig = figure('Visible', 'off', 'Position', [50, 50, 1400, 920], 'Color', 'w');

% --- PAINEL 1 (Superior Esquerdo): Diagrama de Torque e Energia Delta_E ---
subplot(2, 2, 1);
hold on; grid on;

% Sombrear área Delta_E (onde T_res > T_motor)
th_def = th2_deg(idx_deficit);
T_def = T_res_lin(idx_deficit);
fill([th_def, fliplr(th_def)], [T_def, repmat(Tm_lin, 1, length(th_def))], ...
     [1.0, 0.85, 0.80], 'EdgeColor', 'none');

% Sombrear área de acumulação (onde T_motor > T_res)
idx_acum1 = find(th2_deg <= th_A_deg);
fill([th2_deg(idx_acum1), fliplr(th2_deg(idx_acum1))], ...
     [T_res_lin(idx_acum1), repmat(Tm_lin, 1, length(idx_acum1))], ...
     [0.85, 0.95, 0.85], 'EdgeColor', 'none');

plot(th2_deg, T_res_const, 'Color', [0.65, 0.65, 0.70], 'LineStyle', ':', 'LineWidth', 1.8);
plot(th2_deg, T_res_lin, 'Color', [0.85, 0.15, 0.10], 'LineWidth', 2.5);
plot([0, 360], [Tm_lin, Tm_lin], 'Color', [0.00, 0.45, 0.85], 'LineStyle', '--', 'LineWidth', 2.2);

% Linha vertical de início dos 10 mm de quebra
plot([th2_ini_deg, th2_ini_deg], [0, 105], 'k-.', 'LineWidth', 1.2);
text(th2_ini_deg - 6, 52, sprintf('Início Quebra (10 mm)\n\\theta_2 = %.1f°', th2_ini_deg), ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');

text(110, Tm_lin + 7, sprintf('Torque Constante do Motor: T_m = %.2f N\\cdotm (P = %.1f W)', Tm_lin, Tm_lin*w_med), ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.00, 0.35, 0.75], 'HorizontalAlignment', 'center');

text(310, 20, sprintf('\\DeltaE = %.1f J\n(Cedida pelo\nVolante)', dE_lin), ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.75, 0.10, 0.05], 'HorizontalAlignment', 'center');

text(115, 22, 'Zona de Recarga Cinética (+22.3 J)', ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.10, 0.50, 0.15], 'HorizontalAlignment', 'center');

title('1. Diagrama de Torque no Eixo da Manivela e Energia \DeltaE (Curso 10 mm)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Ângulo da Manivela \theta_2 (graus)', 'FontSize', 9.5);
ylabel('Torque no Eixo O_2 (N\cdotm)', 'FontSize', 9.5);
legend({'Déficit \DeltaE (Descarga do Volante)', 'Superávit (Acumulação no Volante)', ...
        'Carga Plena Constante (5 kN x 10 mm)', 'Carga Progressiva Linear (0 \rightarrow 5 kN)', ...
        'Torque Motor Constante T_m'}, 'Location', 'northwest', 'FontSize', 7.8);
xlim([0, 360]); ylim([0, 105]);

% --- PAINEL 2 (Superior Direito): Dimensionamento Geométrico do Aro e Materiais ---
subplot(2, 2, 2);
hold on; grid on;

Re_vec = linspace(0.25, 0.50, 50); % Raio externo de 250 a 500 mm
Ri_vec = 0.80 * Re_vec;            % Aro com R_int = 0.80 * R_ext

% Massa do aro depende apenas de Re e I_req (independente do material!):
m_aro_20 = I_casos(2) ./ (1.05 * 0.5 * (Re_vec.^2 + Ri_vec.^2)); % Cf = 20%
m_aro_35 = I_casos(3) ./ (1.05 * 0.5 * (Re_vec.^2 + Ri_vec.^2)); % Cf = 35%

% Largura axial b (mm) para Cf = 20% em 3 materiais:
b_fofo   = (m_aro_20 / 7200)  ./ (pi * (Re_vec.^2 - Ri_vec.^2)) * 1000;
b_aco    = (m_aro_20 / 7850)  ./ (pi * (Re_vec.^2 - Ri_vec.^2)) * 1000;
b_chumbo = (m_aro_20 / 10800) ./ (pi * (Re_vec.^2 - Ri_vec.^2)) * 1000;

[ax, h1, h2] = plotyy(Re_vec*1000, m_aro_20, Re_vec*1000, b_aco);
hold(ax(1), 'on'); hold(ax(2), 'on');

set(h1, 'Color', [0.10, 0.10, 0.15], 'LineWidth', 2.6, 'LineStyle', '-');
plot(ax(1), Re_vec*1000, m_aro_35, 'Color', [0.35, 0.35, 0.40], 'LineWidth', 2.0, 'LineStyle', '--');

set(h2, 'Color', [0.00, 0.45, 0.85], 'LineWidth', 2.2, 'LineStyle', '-');
plot(ax(2), Re_vec*1000, b_fofo, 'Color', [0.85, 0.40, 0.00], 'LineWidth', 2.0, 'LineStyle', '-.');
plot(ax(2), Re_vec*1000, b_chumbo, 'Color', [0.60, 0.15, 0.70], 'LineWidth', 2.0, 'LineStyle', ':');

% Destacar ponto ótimo de projeto em R_ext = 400 mm (D = 800 mm)
plot(ax(1), 400, interp1(Re_vec*1000, m_aro_20, 400), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 8);
plot(ax(2), 400, interp1(Re_vec*1000, b_aco, 400), 'ks', 'MarkerFaceColor', 'c', 'MarkerSize', 8);

set(ax(1), 'YColor', [0.1 0.1 0.15], 'YLim', [50, 500]);
set(ax(2), 'YColor', [0.0 0.45 0.85], 'YLim', [0, 450]);
ylabel(ax(1), 'Massa do Aro m_{aro} (kg)', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax(2), 'Largura Axial do Aro b (mm) [p/ C_f=20%]', 'FontSize', 9.5, 'FontWeight', 'bold');
xlabel(ax(1), 'Raio Externo do Aro R_{ext} (mm) [com R_{int} = 0.80 R_{ext}]', 'FontSize', 9.5);
title('2. Dimensionamento do Aro a 20 RPM: Massa e Largura vs. Raio e Material', 'FontSize', 10.5, 'FontWeight', 'bold');

legend([h1; findobj(ax(1), 'LineStyle', '--'); h2; findobj(ax(2), 'LineStyle', '-.'); findobj(ax(2), 'LineStyle', ':')], ...
       {'Massa do Aro (C_f = 20%, I = 25.4 kg\cdotm^2)', ...
        'Massa do Aro (C_f = 35%, I = 14.5 kg\cdotm^2)', ...
        'Largura b: Aço ABNT 1020 (\rho = 7850 kg/m^3)', ...
        'Largura b: Ferro Fundido GG20 (\rho = 7200 kg/m^3)', ...
        'Largura b: Compósito Aço+Chumbo (\rho = 10800 kg/m^3)'}, ...
       'Location', 'northeast', 'FontSize', 7.5);

% --- PAINEL 3 (Inferior Esquerdo): Simulação Temporal ode45 omega2(t) ---
subplot(2, 2, 3);
hold on; grid on;

plot([0, 3*T_ciclo], [RPM_alvo, RPM_alvo], 'k:', 'LineWidth', 1.5);
for c = 1:3
    plot(sol_t{c}, sol_rpm{c}, 'Color', cores_casos{c}, 'LineWidth', 2.2);
end

% Destacar os instantes de impacto com o baru em cada ciclo
for k_c = 1:3
    t_imp = (k_c - 1)*T_ciclo + (th2_ini_deg/360)*T_ciclo;
    fill([t_imp, k_c*T_ciclo, k_c*T_ciclo, t_imp], [15.5, 15.5, 24.5, 24.5], ...
         [1.0, 0.90, 0.85], 'EdgeColor', 'none');
end
% Replotar linhas por cima do sombreamento
plot([0, 3*T_ciclo], [RPM_alvo, RPM_alvo], 'k:', 'LineWidth', 1.5);
h_lines = zeros(1, 3);
for c = 1:3
    h_lines(c) = plot(sol_t{c}, sol_rpm{c}, 'Color', cores_casos{c}, 'LineWidth', 2.2);
end

text(2.55, 16.3, sprintf('Quebra\n(10 mm)'), 'FontSize', 7.8, 'Color', [0.75 0.15 0.1], 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(5.55, 16.3, sprintf('Quebra\n(10 mm)'), 'FontSize', 7.8, 'Color', [0.75 0.15 0.1], 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(8.55, 16.3, sprintf('Quebra\n(10 mm)'), 'FontSize', 7.8, 'Color', [0.75 0.15 0.1], 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

title('3. Resposta Dinâmica Real Integrada (ode45): Flutuação de Rotação \omega_2(t)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Tempo t (segundos) — 3 Ciclos Completos a 20 RPM (T = 3.00 s)', 'FontSize', 9.5);
ylabel('Velocidade Angular \omega_2 (RPM)', 'FontSize', 9.5);
legend(h_lines, nomes_casos, 'Location', 'northwest', 'FontSize', 8.0);
xlim([0, 3*T_ciclo]); ylim([15.5, 24.5]);

% --- PAINEL 4 (Inferior Direito): Retrato de Fase Estacionário omega2(theta2) ---
subplot(2, 2, 4);
hold on; grid on;

fill([th_A_deg, th_B_deg, th_B_deg, th_A_deg], [15.5, 15.5, 24.5, 24.5], ...
     [1.0, 0.90, 0.85], 'EdgeColor', 'none');

plot([0, 360], [RPM_alvo, RPM_alvo], 'k:', 'LineWidth', 1.5);

% Plotar 1 ciclo completo no retrato de fase
for c = 1:3
    idx_1ciclo = find(sol_th{c} <= 2*pi);
    plot(rad2deg(sol_th{c}(idx_1ciclo)), sol_rpm{c}(idx_1ciclo), 'Color', cores_casos{c}, 'LineWidth', 2.4);
end

% Marcar omega_max (em th_A) e omega_min (em th_B) para o caso recomendado Cf=20%
idx_1c = find(sol_th{2} <= 2*pi);
[rpm_max2, id_max2] = max(sol_rpm{2}(idx_1c));
[rpm_min2, id_min2] = min(sol_rpm{2}(idx_1c));
th_max2 = rad2deg(sol_th{2}(idx_1c(id_max2)));
th_min2 = rad2deg(sol_th{2}(idx_1c(id_min2)));

plot(th_max2, rpm_max2, 'ko', 'MarkerFaceColor', 'g', 'MarkerSize', 8);
plot(th_min2, rpm_min2, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

text(th_max2 - 15, rpm_max2 + 0.55, sprintf('\\omega_{max} = %.1f RPM (\\theta_2 = %.0f°)', rpm_max2, th_max2), ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.05 0.45 0.15], 'HorizontalAlignment', 'right');
text(th_min2 - 10, rpm_min2 - 0.65, sprintf('\\omega_{min} = %.1f RPM (\\theta_2 = %.0f°)', rpm_min2, th_min2), ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.75 0.10 0.05], 'HorizontalAlignment', 'right');

title('4. Retrato de Fase Dinâmico \omega_2(\theta_2): Aceleração no Vazio vs. Queda na Quebra', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('Posição Angular da Manivela \theta_2 (graus)', 'FontSize', 9.5);
ylabel('Velocidade Angular \omega_2 (RPM)', 'FontSize', 9.5);
xlim([0, 360]); ylim([15.5, 24.5]);

out_img = fullfile(assets_dir, 'dimensionamento_volante_20rpm_dinamica.png');
print(fig, out_img, '-dpng', '-r300');
close(fig);
fprintf('\nFigura técnica salva com sucesso em: %s\n', out_img);
