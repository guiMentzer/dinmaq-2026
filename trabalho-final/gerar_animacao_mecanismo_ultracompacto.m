% =========================================================================
% Trabalho Final 1 - Dinâmica das Máquinas (UFG)
% Animação Cinemática do Mecanismo Ultra-Compacto (K = 1.5, Delta_theta4 = 30°)
% Geração de Frames e Compilação em GIF e MP4
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = '.'; end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir'), mkdir(assets_dir); end

frames_dir = '/tmp/frames_prensa_k15';
if exist(frames_dir, 'dir')
    rmdir(frames_dir, 's');
end
mkdir(frames_dir);

% -------------------------------------------------------------------------
% 1. Parâmetros Físicos e Geométricos
% -------------------------------------------------------------------------
h = 30.0; % Curso útil (mm)
dt_deg = 30.0;
dt = deg2rad(dt_deg);

L4 = h / (2.0 * (1.0 - cos(dt))); % 111.9615 mm
L5 = L4;

O4 = [0.0; 0.0];
B2 = [0.0; -L4];                     % PMI
B1 = [-L4 * sin(dt); -L4 * cos(dt)]; % PMS
M = B1 - B2;
corda_M = norm(M);                   % 57.9555 mm

% Pivô O2 ultra-compacto K = 1.5
O2 = B2 + 1.5 * M;                   % [-83.97; -89.46] mm
L2 = corda_M / 2.0;                  % 28.98 mm
L3 = corda_M;                        % 57.96 mm
d_base = norm(O2);                   % 122.70 mm

% Posições extremas teóricas
y_pmi = -2 * L4;           % -223.92 mm
y_pms = -2 * L4 * cos(dt); % -193.92 mm

% -------------------------------------------------------------------------
% 2. Pré-Cálculo de Toda a Trajetória (para os Gráficos do Lado Direito)
% -------------------------------------------------------------------------
N_curve = 360;
t2_full = linspace(0, 360, N_curve);
y_pist_full = zeros(1, N_curve);
mu_ang_full = zeros(1, N_curve);

for i = 1:N_curve
    t2 = deg2rad(t2_full(i));
    xA = O2(1) + L2 * cos(t2);
    yA = O2(2) + L2 * sin(t2);
    d_A = sqrt(xA^2 + yA^2);
    a_circ = (L4^2 - L3^2 + d_A^2) / (2 * d_A);
    h_c = sqrt(max(0, L4^2 - a_circ^2));
    x2_c = a_circ * xA / d_A;
    y2_c = a_circ * yA / d_A;
    
    p_plus = [x2_c + h_c * (-yA)/d_A; y2_c + h_c * (xA)/d_A];
    p_minus = [x2_c - h_c * (-yA)/d_A; y2_c - h_c * (xA)/d_A];
    if p_plus(1) <= 0.01 && p_plus(2) < 0
        B_pt = p_plus;
    else
        B_pt = p_minus;
    end
    
    y_pist_full(i) = B_pt(2) - sqrt(L5^2 - B_pt(1)^2);
    
    v_biela = B_pt - [xA; yA];
    v_bal = B_pt - O4;
    cos_m = dot(v_biela, v_bal) / (norm(v_biela) * norm(v_bal));
    ang_m = rad2deg(acos(max(-1, min(1, cos_m))));
    if ang_m > 90, ang_m = 180 - ang_m; end
    mu_ang_full(i) = ang_m;
end

% -------------------------------------------------------------------------
% 3. Loop de Renderização dos Frames da Animação
% -------------------------------------------------------------------------
num_frames = 72; % 5° por frame (24 fps -> 3.0 s por ciclo suave)
theta2_frames = linspace(0, 360 - 360/num_frames, num_frames);

fig = figure('Visible', 'off', 'Position', [50, 50, 1200, 750], 'Color', 'w');

fprintf('Gerando %d frames da animação...\n', num_frames);

for k = 1:num_frames
    clf;
    t2_deg_k = theta2_frames(k);
    t2_rad_k = deg2rad(t2_deg_k);
    
    % Posição instantânea de A
    xA = O2(1) + L2 * cos(t2_rad_k);
    yA = O2(2) + L2 * sin(t2_rad_k);
    
    % Posição instantânea de B
    d_A = sqrt(xA^2 + yA^2);
    a_circ = (L4^2 - L3^2 + d_A^2) / (2 * d_A);
    h_c = sqrt(max(0, L4^2 - a_circ^2));
    x2_c = a_circ * xA / d_A;
    y2_c = a_circ * yA / d_A;
    p_plus = [x2_c + h_c * (-yA)/d_A; y2_c + h_c * (xA)/d_A];
    p_minus = [x2_c - h_c * (-yA)/d_A; y2_c - h_c * (xA)/d_A];
    if p_plus(1) <= 0.01 && p_plus(2) < 0
        B = p_plus;
    else
        B = p_minus;
    end
    
    % Posição instantânea do Pistão O5
    yO5 = B(2) - sqrt(L5^2 - B(1)^2);
    
    % Ângulo de transmissão instantâneo
    v_biela = B - [xA; yA];
    v_bal = B - O4;
    cos_m = dot(v_biela, v_bal) / (norm(v_biela) * norm(v_bal));
    mu_inst = rad2deg(acos(max(-1, min(1, cos_m))));
    if mu_inst > 90, mu_inst = 180 - mu_inst; end
    
    % Fase: Descida (0° a 180°) vs Subida (180° a 360°)
    is_descendo = (t2_deg_k > 0 && t2_deg_k < 180);
    is_zona_quebra = (abs(yO5 - y_pmi) < 4.0);
    
    % =====================================================================
    % PAINEL ESQUERDO: MECANISMO EM MOVIMENTO
    % =====================================================================
    subplot(1, 2, 1);
    hold on; grid on; axis equal;
    
    % Trajetória circular de A
    ang_c = linspace(0, 2*pi, 100);
    plot(O2(1) + L2*cos(ang_c), O2(2) + L2*sin(ang_c), 'Color', [0.8 0.8 0.85], 'LineStyle', ':', 'LineWidth', 1.4);
    
    % Trajetória em arco de B
    ang_b = linspace(-pi/2 - dt, -pi/2, 60);
    plot(L4*cos(ang_b), L4*sin(ang_b), 'Color', [0.75 0.8 0.85], 'LineStyle', '--', 'LineWidth', 1.8);
    
    % Linha guia vertical
    plot([0, 0], [-270, 25], 'Color', [0.4 0.4 0.4], 'LineStyle', '-.', 'LineWidth', 1.2);
    
    % Bigorna
    fill([-32, 32, 32, -32], [-248, -248, -240, -240], [0.6 0.6 0.65], 'EdgeColor', 'k', 'LineWidth', 1.3);
    plot([-40, 40], [-248, -248], 'k-', 'LineWidth', 2.0);
    for hx = -36:8:32
        plot([hx, hx + 7], [-248, -256], 'Color', [0.3 0.3 0.3], 'LineWidth', 1.2);
    end
    
    % Guias lineares prismáticas laterais
    fill([-18, -13, -13, -18], [-230, -230, -175, -175], [0.88 0.88 0.90], 'EdgeColor', [0.4 0.4 0.45], 'LineWidth', 1.2);
    fill([13, 18, 18, 13], [-230, -230, -175, -175], [0.88 0.88 0.90], 'EdgeColor', [0.4 0.4 0.45], 'LineWidth', 1.2);
    
    % Fruto do Baru sobre a bigorna
    baru_t = linspace(0, 2*pi, 50);
    fill(9.5*cos(baru_t), -233 + 7.0*sin(baru_t), [0.55 0.28 0.10], 'EdgeColor', [0.30 0.12 0.04], 'LineWidth', 1.6);
    
    % Efeito visual especial na zona de quebra (PMI):
    if is_zona_quebra
        % Alerta no chassi sem encavalar com o pistão
        fill([-30, 30, 30, -30], [-239, -239, -227, -227], [1.0, 0.92, 0.60], 'EdgeColor', [0.9 0.4 0.0], 'LineWidth', 1.2);
        text(0, -233, 'ZONA DE ESMAGAMENTO', ...
             'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.85 0.15 0.0], 'HorizontalAlignment', 'center');
    end
    
    % ELO 2: Manivela (Vermelho)
    plot([O2(1), xA], [O2(2), yA], 'Color', [0.85 0.15 0.10], 'LineWidth', 4.0);
    % ELO 3: Biela (Azul)
    plot([xA, B(1)], [yA, B(2)], 'Color', [0.00 0.45 0.85], 'LineWidth', 4.0);
    % ELO 4: Balancim (Verde)
    plot([O4(1), B(1)], [O4(2), B(2)], 'Color', [0.10 0.65 0.25], 'LineWidth', 4.2);
    % ELO 5: Biela Prensa (Púrpura)
    plot([B(1), 0], [B(2), yO5], 'Color', [0.70 0.15 0.75], 'LineWidth', 4.2);
    
    % Pistão com Lâmina Afiada
    fill([-11, 11, 11, 0, -11], ...
         [yO5+14, yO5+14, yO5, yO5-7, yO5], ...
         [0.30 0.30 0.35], 'EdgeColor', 'k', 'LineWidth', 1.8);
    plot(0, yO5, 'o', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 7);
    
    % Pinos / Juntas
    plot(xA, yA, 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'MarkerSize', 7, 'LineWidth', 1.5);
    plot(B(1), B(2), 's', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 9, 'LineWidth', 1.5);
    
    % Mancal O4
    plot(0, 0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 9);
    fill([-8, 8, 0], [-10, -10, 0], [0.55 0.55 0.60], 'EdgeColor', 'k');
    plot([-12, 12], [-10, -10], 'k-', 'LineWidth', 1.5);
    text(6, 6, 'O_4', 'FontSize', 9.5, 'FontWeight', 'bold');
    
    % Mancal O2
    plot(O2(1), O2(2), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 9);
    fill([O2(1)-8, O2(1)+8, O2(1)], [O2(2)-10, O2(2)-10, O2(2)], [0.55 0.55 0.60], 'EdgeColor', 'k');
    plot([O2(1)-12, O2(1)+12], [O2(2)-10, O2(2)-10], 'k-', 'LineWidth', 1.5);
    text(O2(1) - 25, O2(2) - 13, 'O_2', 'FontSize', 9, 'FontWeight', 'bold');
    
    % Base entre O2 e O4
    plot([O2(1), O4(1)], [O2(2), O4(2)], 'Color', [0.4 0.4 0.4], 'LineStyle', ':', 'LineWidth', 1.3);
    
    % Banner de Status no Topo do Mecanismo
    if is_zona_quebra
        status_fase = 'FASE: IMPACTO / QUEBRA (PMI)';
        cor_fase = [0.85 0.1 0.1];
    elseif is_descendo
        status_fase = 'FASE: AVANÇO / CISALHAMENTO \downarrow';
        cor_fase = [0.8 0.4 0.0];
    else
        status_fase = 'FASE: RETORNO / ALIMENTAÇÃO \uparrow';
        cor_fase = [0.1 0.5 0.2];
    end
    
    text(-135, 18, sprintf('%s | \\theta_2 = %03.0f° | y = %.1f mm', status_fase, t2_deg_k, yO5), ...
         'FontSize', 9.5, 'FontWeight', 'bold', 'Color', cor_fase);
    
    title('Mecanismo Ultra-Compacto (K = 1.5, \Delta\theta_4 = 30°)', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X (mm)', 'FontSize', 9); ylabel('Y (mm)', 'FontSize', 9);
    xlim([-140, 50]); ylim([-275, 30]);
    
    % =====================================================================
    % PAINEL DIREITO: CURVAS DINÂMICAS SINCRONIZADAS
    % =====================================================================
    % Subplot Superior Direito: Deslocamento y_O5
    subplot(2, 2, 2);
    hold on; grid on;
    plot(t2_full, y_pist_full, 'Color', [0.70 0.15 0.75], 'LineWidth', 2.0);
    plot([0, 360], [y_pmi, y_pmi], 'r--', 'LineWidth', 1.1);
    plot([0, 360], [y_pms, y_pms], 'b--', 'LineWidth', 1.1);
    
    % Ponto Rastreador Atual
    plot(t2_deg_k, yO5, 'ro', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
    
    title('Deslocamento da Navalha y_{O5}(\theta_2)', 'FontSize', 10, 'FontWeight', 'bold');
    xlabel('\theta_2 (graus)', 'FontSize', 8.5); ylabel('y (mm)', 'FontSize', 8.5);
    xlim([0, 360]); ylim([-228, -190]);
    
    % Subplot Inferior Direito: Ângulo de Transmissão mu
    subplot(2, 2, 4);
    hold on; grid on;
    fill([0, 360, 360, 0], [40, 40, 90, 90], [0.88, 0.96, 0.88], 'EdgeColor', 'none');
    plot([0, 360], [40, 40], 'r--', 'LineWidth', 1.1);
    plot([0, 360], [90, 90], 'k:', 'LineWidth', 1.1);
    plot(t2_full, mu_ang_full, 'Color', [0.00 0.45 0.85], 'LineWidth', 2.0);
    
    % Ponto Rastreador Atual de mu
    plot(t2_deg_k, mu_inst, 's', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
    if mu_inst > 80
        text(t2_deg_k, mu_inst - 5.5, sprintf('\\mu = %.1f°', mu_inst), 'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    else
        text(t2_deg_k, mu_inst + 5.5, sprintf('\\mu = %.1f°', mu_inst), 'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
    
    title('Ângulo de Transmissão Instantâneo \mu(\theta_2)', 'FontSize', 10, 'FontWeight', 'bold');
    xlabel('\theta_2 (graus)', 'FontSize', 8.5); ylabel('\mu (graus)', 'FontSize', 8.5);
    xlim([0, 360]); ylim([35, 95]);
    
    % Salvar Frame
    frame_path = fullfile(frames_dir, sprintf('frame_%03d.png', k));
    print(fig, frame_path, '-dpng', '-r150');
    
    if mod(k, 12) == 0 || k == num_frames
        fprintf('  Frame %d / %d gerado com sucesso.\n', k, num_frames);
    end
end

close(fig);
fprintf('\nTodos os frames foram gerados em %s!\n', frames_dir);

% -------------------------------------------------------------------------
% 4. Compilação em GIF e MP4 usando FFmpeg
% -------------------------------------------------------------------------
gif_path = fullfile(assets_dir, 'mecanismo_ultracompacto_k15_animacao.gif');
mp4_path = fullfile(assets_dir, 'mecanismo_ultracompacto_k15_animacao.mp4');

fprintf('\nCompilando GIF de alta qualidade com FFmpeg...\n');
% Usar filtro palettegen + paletteuse para máxima fidelidade e tamanho reduzido
cmd_gif = sprintf('ffmpeg -y -framerate 24 -i "%s/frame_%%03d.png" -vf "split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" "%s"', ...
                  frames_dir, gif_path);
[status_gif, out_gif] = system(cmd_gif);
if status_gif == 0
    fprintf('GIF gerado com sucesso em: %s\n', gif_path);
else
    fprintf('Erro ao gerar GIF:\n%s\n', out_gif);
end

fprintf('\nCompilando MP4 H.264 com FFmpeg...\n');
cmd_mp4 = sprintf('ffmpeg -y -framerate 24 -i "%s/frame_%%03d.png" -c:v libx264 -pix_fmt yuv420p -crf 20 "%s"', ...
                  frames_dir, mp4_path);
[status_mp4, out_mp4] = system(cmd_mp4);
if status_mp4 == 0
    fprintf('MP4 gerado com sucesso em: %s\n', mp4_path);
else
    fprintf('Erro ao gerar MP4:\n%s\n', out_mp4);
end

fprintf('\nProcesso de renderização concluído!\n');
