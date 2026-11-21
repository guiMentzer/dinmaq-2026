% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Benchmarking Paramétrico da Alavanca em L (Estilo Design #140)
%
% Variáveis de Projeto Avaliadas:
%   1) Posição do eixo fixo da alavanca O2 ao longo da mediatriz (s_offset)
%      -> controla diretamente o tamanho da biela L3 e o afastamento O2x
%   2) Ângulo entre os braços da alavanca em L (delta_L = theta_A - theta_P,
%      equivalente à dobra interna gamma_L = 180° - delta_L, mantendo o arco
%      ergonômico da empunhadura fixo em +30° -> -30°, Delta_theta_alav = 60°)
%   3) Estratégias para manter a força manual F_mao <= 60 N:
%      dimensionamento de L_alav e comparação com arco expandido de 90°
%
% Métricas Comparadas:
%   - Ângulo de transmissão mu: mínimo, médio, na zona de quebra (10 mm) e PMI
%   - Tamanho da biela L3 (mm), posição O2 = [X, Y] e folga de colisão
%   - Torque de pico (linear e biomaterial s^0.4), F_mao (N) e L_60N (m)
%
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

% -------------------------------------------------------------------------
% 1. Núcleo Cinemático Invariante da Prensa Knuckle-Joint (Delta_theta4=30°)
% -------------------------------------------------------------------------
h_curso    = 30.0;       % Curso útil total da navalha (mm)
delta_q    = 10.0;       % Curso efetivo de cisalhamento do baru (mm)
F_max      = 5000.0;     % Força máxima de corte por cisalhamento (N)
F_alvo     = 60.0;       % Limite ergonômico alvo de força manual (N)
dt_deg     = 30.0;
dt         = deg2rad(dt_deg);

L4 = h_curso / (2.0 * (1.0 - cos(dt))); % 111.9615 mm
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4];                       % PMI (alinhamento vertical x = 0)
B1 = [-L4 * sin(dt); -L4 * cos(dt)];   % PMS (defletido de 30° à esquerda)

y_pmi     = -2.0 * L4;                 % -223.9230 mm
y_pms     = -2.0 * L4 * cos(dt);       % -193.9230 mm
y_contato = y_pmi + delta_q;           % -213.9230 mm

mu_guia    = 0.10;
eta_juntas = 0.96;
L2_ref     = 70.0;                     % Braço curto de acionamento (mm)

% -------------------------------------------------------------------------
% 2. Função de Avaliação Cinemática e Dinâmica de 1 Configuração
% -------------------------------------------------------------------------
function res = avaliar_config(L2, delta_L_deg, s_offset, dth_deg, ...
                              L4, L5, B1, B2, y_contato, delta_q, F_max, F_alvo, mu_guia, eta_juntas)
    res.valid = false;
    th_pms_deg = 0.5 * dth_deg + delta_L_deg;
    th_pmi_deg = th_pms_deg - dth_deg;
    th_pms = deg2rad(th_pms_deg);
    th_pmi = deg2rad(th_pmi_deg);

    P1 = B1 - L2 * [cos(th_pms); sin(th_pms)];
    P2 = B2 - L2 * [cos(th_pmi); sin(th_pmi)];
    dP = P2 - P1;
    if norm(dP) < 1e-6, return; end
    midP = 0.5 * (P1 + P2);
    nP = [-dP(2); dP(1)] / norm(dP);
    if nP(1) < 0, nP = -nP; end  % Sentido +s aponta para +X

    O2 = midP + s_offset * nP;
    L3 = norm(P2 - O2);
    d_base = norm(O2);

    N = 401;
    th2_rad = linspace(th_pms, th_pmi, N);
    phi_deg = linspace(0.0, dth_deg, N);
    dphi = deg2rad(phi_deg(2) - phi_deg(1));

    Ax = O2(1) + L2 * cos(th2_rad);
    Ay = O2(2) + L2 * sin(th2_rad);
    dA = hypot(Ax, Ay);
    if any(dA < 1e-6), return; end

    a_c = (L4^2 - L3^2 + dA.^2) ./ (2.0 * dA);
    arg_h = L4^2 - a_c.^2;
    if any(arg_h < -1e-6), return; end
    h_c = sqrt(max(0.0, arg_h));

    % Seleção do ramo coincidente com B1 no PMS
    x2_1 = a_c(1) * Ax(1) / dA(1);
    y2_1 = a_c(1) * Ay(1) / dA(1);
    Bp = [x2_1 + h_c(1)*(-Ay(1))/dA(1); y2_1 + h_c(1)*(Ax(1))/dA(1)];
    Bm = [x2_1 - h_c(1)*(-Ay(1))/dA(1); y2_1 - h_c(1)*(Ax(1))/dA(1)];
    sgn = (norm(Bp - B1) < norm(Bm - B1)) * 2 - 1;

    Bx = a_c .* Ax ./ dA + sgn * h_c .* (-Ay) ./ dA;
    By = a_c .* Ay ./ dA + sgn * h_c .* (Ax)  ./ dA;

    % Verifica se o ramo atinge B2 no PMI sem salto de montagem
    if hypot(Bx(end) - B2(1), By(end) - B2(2)) > 0.5, return; end

    y_p = By - sqrt(max(0.0, L5^2 - Bx.^2));
    if (max(y_p) - y_p(1) > 0.5) || (y_p(end) - min(y_p) > 0.5), return; end

    th3_rad = atan2(By - Ay, Bx - Ax);
    th4_rad = atan2(By, Bx);
    beta5   = asin(min(1.0, abs(Bx) / L5));

    da = mod(abs(th4_rad - th3_rad), 2*pi);
    da(da > pi) = 2*pi - da(da > pi);
    mu_deg = rad2deg(da);

    hp_m = abs(gradient(y_p * 1e-3, dphi));
    eta_mec = (1.0 - mu_guia * tan(beta5)) * eta_juntas;

    s_pen = max(0.0, (y_contato - y_p) / delta_q);
    idx_q = find(s_pen > 0);
    if length(idx_q) < 5, return; end

    T_lin = (F_max * s_pen .* hp_m) ./ eta_mec;
    T_bio = (F_max * (s_pen.^0.4) .* hp_m) ./ eta_mec;

    res.valid       = true;
    res.O2          = O2;
    res.d_base      = d_base;
    res.L2          = L2;
    res.L3          = L3;
    res.delta_L     = delta_L_deg;
    res.gamma_L     = 180.0 - delta_L_deg;
    res.th_pms_deg  = th_pms_deg;
    res.th_pmi_deg  = th_pmi_deg;
    res.dth_deg     = dth_deg;
    res.s_offset    = s_offset;
    res.phi_deg     = phi_deg;
    res.phi_norm    = phi_deg / dth_deg * 100.0;
    res.Ax          = Ax;
    res.Ay          = Ay;
    res.Bx          = Bx;
    res.By          = By;
    res.y_p         = y_p;
    res.mu_deg      = mu_deg;
    res.mu_min      = min(mu_deg);
    res.mu_max      = max(mu_deg);
    res.mu_mean     = mean(mu_deg);
    res.mu_q_ini    = mu_deg(idx_q(1));
    res.mu_q_min    = min(mu_deg(idx_q));
    res.mu_q_mean   = mean(mu_deg(idx_q));
    res.mu_q_max    = max(mu_deg(idx_q));
    res.mu_pmi      = mu_deg(end);
    res.span_q_deg  = dth_deg - phi_deg(idx_q(1));
    res.T_lin       = T_lin;
    res.T_bio       = T_bio;
    res.T_lin_pico  = max(T_lin);
    res.T_bio_pico  = max(T_bio);
    res.L60_lin     = max(T_lin) / F_alvo;
    res.L60_bio     = max(T_bio) / F_alvo;
    res.F_1050_lin  = max(T_lin) / 1.05;
    res.F_1050_bio  = max(T_bio) / 1.05;
    res.F_450_lin   = max(T_lin) / 0.45;
    res.F_450_bio   = max(T_bio) / 0.45;
    res.livre_colis = (O2(1) >= 35.0) || (O2(1) <= -55.0);
end

% -------------------------------------------------------------------------
% 3. Varredura Paramétrica 2D (s_offset x delta_L) para Mapas de Contorno
% -------------------------------------------------------------------------
s_vec  = 70:5:250;          % 37 posições de O2 ao longo da mediatriz (+X)
dL_vec = 15:2:115;          % 51 ângulos entre braços (delta_L = 15°..115°)
nS = length(s_vec);
nD = length(dL_vec);

M_mu_min    = NaN(nD, nS);
M_mu_max    = NaN(nD, nS);
M_mu_mean   = NaN(nD, nS);
M_mu_q_mean = NaN(nD, nS);
M_mu_pmi    = NaN(nD, nS);
M_L3        = NaN(nD, nS);
M_O2x       = NaN(nD, nS);
M_O2y       = NaN(nD, nS);
M_Tlin      = NaN(nD, nS);
M_Tbio      = NaN(nD, nS);
M_L60_lin   = NaN(nD, nS);
M_L60_bio   = NaN(nD, nS);

for i = 1:nD
    for j = 1:nS
        r = avaliar_config(L2_ref, dL_vec(i), s_vec(j), 60.0, ...
                           L4, L5, B1, B2, y_contato, delta_q, F_max, F_alvo, mu_guia, eta_juntas);
        if r.valid
            M_mu_min(i,j)    = r.mu_min;
            M_mu_max(i,j)    = r.mu_max;
            M_mu_mean(i,j)   = r.mu_mean;
            M_mu_q_mean(i,j) = r.mu_q_mean;
            M_mu_pmi(i,j)    = r.mu_pmi;
            M_L3(i,j)        = r.L3;
            M_O2x(i,j)       = r.O2(1);
            M_O2y(i,j)       = r.O2(2);
            M_Tlin(i,j)      = r.T_lin_pico;
            M_Tbio(i,j)      = r.T_bio_pico;
            M_L60_lin(i,j)   = r.L60_lin;
            M_L60_bio(i,j)   = r.L60_bio;
        end
    end
end

% -------------------------------------------------------------------------
% 4. Avaliação Comparativa de Candidatos Representativos
% -------------------------------------------------------------------------
% {Nome Curto, delta_L (deg), s_offset (mm), dth_alav (deg), Cor RGB}
cands_spec = {
    'C1: Ref. #140 (dL=55, s=135)',    55.0,  135.0, 60.0, [0.15 0.15 0.15];
    'C2: O2 Prox. (dL=55, s=95)',     55.0,   95.0, 60.0, [0.85 0.45 0.00];
    'C3: O2 Dist. (dL=55, s=200)',    55.0,  200.0, 60.0, [0.55 0.35 0.75];
    'C4: Otimo #140-B (dL=40, s=135)',40.0,  135.0, 60.0, [0.05 0.60 0.25];
    'C5: L Aberto (dL=30, s=160)',    30.0,  160.0, 60.0, [0.00 0.55 0.80];
    'C6: L Agudo (dL=100, s=135)',   100.0,  135.0, 60.0, [0.75 0.20 0.55];
    'C7: Esquerda -X (dL=55, s=-135)',55.0, -135.0, 60.0, [0.45 0.35 0.20];
    'C8: Arco 90 (dL=15, s=120)',     15.0,  120.0, 90.0, [0.85 0.10 0.15];
    'C9: Singul. Rej. (dL=70, s=135)',70.0,  135.0, 60.0, [0.60 0.60 0.60]
};

nc = size(cands_spec, 1);
fprintf('========================================================================================================================================================\n');
fprintf('BENCHMARKING ALAVANCA EM L (DESIGN #140) - POSICAO DE O2 (s_offset) E ANGULO ENTRE BRACOS (delta_L / gamma_L)\n');
fprintf('========================================================================================================================================================\n');
fprintf('%-30s | O2 [X, Y] (mm)   | L3 (mm) | mu_min | mu_med | mu_q_med | mu_PMI | T_lin  | T_bio  | L60_lin | L60_bio | F@1.05m (lin/bio)\n', 'Candidato');
fprintf('--------------------------------------------------------------------------------------------------------------------------------------------------------\n');

cands = struct();
for k = 1:nc
    r = avaliar_config(L2_ref, cands_spec{k,2}, cands_spec{k,3}, cands_spec{k,4}, ...
                       L4, L5, B1, B2, y_contato, delta_q, F_max, F_alvo, mu_guia, eta_juntas);
    r.nome = cands_spec{k,1};
    r.cor  = cands_spec{k,5};
    cands(k).r = r;
    fprintf('%-30s | [%6.1f, %6.1f] | %7.2f | %5.1f° | %5.1f° | %7.1f° | %5.1f° | %6.2f | %6.2f | %6.2fm | %6.2fm | %5.1f N / %5.1f N\n', ...
        r.nome, r.O2(1), r.O2(2), r.L3, r.mu_min, r.mu_mean, r.mu_q_mean, r.mu_pmi, ...
        r.T_lin_pico, r.T_bio_pico, r.L60_lin, r.L60_bio, r.F_1050_lin, r.F_1050_bio);
end
fprintf('========================================================================================================================================================\n');

% Exporta dados intermediários em pasta temporária para pós-processamento sem poluir assets/
tmp_dir = tempdir();
csv_grid = fullfile(tmp_dir, 'benchmarking_alavanca_L_grid2d.csv');
fidg = fopen(csv_grid, 'w');
fprintf(fidg, 'i,j,s_offset,delta_L,mu_min,mu_max,mu_mean,mu_q_mean,mu_pmi,L3,O2x,O2y,T_lin,T_bio,L60_lin,L60_bio\n');
for i = 1:nD
    for j = 1:nS
        fprintf(fidg, '%d,%d,%.2f,%.2f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
            i-1, j-1, s_vec(j), dL_vec(i), M_mu_min(i,j), M_mu_max(i,j), M_mu_mean(i,j), ...
            M_mu_q_mean(i,j), M_mu_pmi(i,j), M_L3(i,j), M_O2x(i,j), M_O2y(i,j), ...
            M_Tlin(i,j), M_Tbio(i,j), M_L60_lin(i,j), M_L60_bio(i,j));
    end
end
fclose(fidg);

csv_cand = fullfile(tmp_dir, 'benchmarking_candidatos_resumo.csv');
fid = fopen(csv_cand, 'w');
fprintf(fid, 'nome,delta_L,gamma_L,s_offset,dth_deg,O2_x,O2_y,d_base,L3,mu_min,mu_max,mu_mean,mu_q_ini,mu_q_min,mu_q_mean,mu_pmi,span_q_deg,T_lin_pico,T_bio_pico,L60_lin,L60_bio,F1050_lin,F1050_bio\n');
for k = 1:nc
    r = cands(k).r;
    fprintf(fid, '"%s",%.2f,%.2f,%.2f,%.2f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n', ...
        r.nome, r.delta_L, r.gamma_L, r.s_offset, r.dth_deg, r.O2(1), r.O2(2), r.d_base, r.L3, ...
        r.mu_min, r.mu_max, r.mu_mean, r.mu_q_ini, r.mu_q_min, r.mu_q_mean, r.mu_pmi, r.span_q_deg, ...
        r.T_lin_pico, r.T_bio_pico, r.L60_lin, r.L60_bio, r.F_1050_lin, r.F_1050_bio);
end
fclose(fid);

csv_curvas = fullfile(tmp_dir, 'benchmarking_candidatos_curvas.csv');
fid2 = fopen(csv_curvas, 'w');
fprintf(fid2, 'cand_idx,phi_norm,phi_deg,y_p,mu_deg,T_lin,T_bio\n');
for k = 1:nc
    r = cands(k).r;
    for p = 1:length(r.phi_norm)
        fprintf(fid2, '%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n', ...
            k, r.phi_norm(p), r.phi_deg(p), r.y_p(p), r.mu_deg(p), r.T_lin(p), r.T_bio(p));
    end
end
fclose(fid2);
fprintf('Dados CSV exportados em %s\n', tmp_dir);

% -------------------------------------------------------------------------
% 5. Plotagem Nativa em Octave (executada quando há toolkit gráfico ativo)
% -------------------------------------------------------------------------
if ~isempty(available_graphics_toolkits())
    fig1 = figure('Visible', 'off', 'Position', [40, 40, 1480, 920], 'Color', 'w');
    subplot(2,2,1); contourf(s_vec, dL_vec, M_mu_min, 16); colorbar; hold on;
    contour(s_vec, dL_vec, M_mu_min, [40, 60, 70], 'w--', 'LineWidth', 1.4);
    plot(135, 55, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8);
    plot(135, 40, 'gp', 'MarkerFaceColor', 'g', 'MarkerSize', 11);
    title('\mu_{min} (graus)'); xlabel('s_{offset} (mm)'); ylabel('\delta_L (graus)');

    subplot(2,2,2); contourf(s_vec, dL_vec, M_mu_q_mean, 16); colorbar; hold on;
    contour(s_vec, dL_vec, M_mu_q_mean, [40, 90, 110], 'w--', 'LineWidth', 1.4);
    title('\mu_{quebra,med} (graus)'); xlabel('s_{offset} (mm)'); ylabel('\delta_L (graus)');

    subplot(2,2,3); contourf(s_vec, dL_vec, M_L3, 16); colorbar; hold on;
    contour(s_vec, dL_vec, M_O2x, [35, 35], 'r--', 'LineWidth', 1.8);
    title('Tamanho da Biela L_3 (mm)'); xlabel('s_{offset} (mm)'); ylabel('\delta_L (graus)');

    subplot(2,2,4); contourf(s_vec, dL_vec, M_L60_lin, 16); colorbar; hold on;
    title('Comprimento L_{60N} Linear (m)'); xlabel('s_{offset} (mm)'); ylabel('\delta_L (graus)');

    print(fig1, fullfile(assets_dir, 'benchmarking_alavanca_L_mapas_2D.png'), '-dpng', '-r300');
    close(fig1);
else
    fprintf('Ambiente headless sem toolkit grafico Octave ativo; use o script Python complementar para renderizar os PNGs em 300 DPI a partir dos dados exatos acima.\n');
end
