% =========================================================================
% Cálculo das Posições dos Pontos A, B e P - Mecanismo de 4 Barras
% Disciplina: Dinâmica das Máquinas (Atividade Extraclasse nº 3)
% =========================================================================

clear; clc; close all;

% 1. Parâmetros geométricos dos elos (em mm)
a = 40.0;          % Elo 2: Manivela (O2 -> A)
b = 208.0;         % Elo 3: Acoplador (A -> B)
c = 156.0;         % Elo 4: Balancim  (O4 -> B)
d = 200.0;         % Elo 1: Base fixa (O2 -> O4)

% Parâmetros do ponto P no elo acoplador
p = 180.0;                 % Distância de A até P (mm)
delta3 = deg2rad(20);      % Ângulo do ponto P relativo à linha AB (20°)

% Origens fixas no plano cartesiano:
% O2: pivô da manivela na origem (0, 0)
% O4: pivô do balancim em (d, 0)
O2 = [0; 0];
O4 = [d; 0];

% =========================================================================
% 2. Posição dos pontos para theta2 = 45°
% =========================================================================
theta2_ref = deg2rad(45);

sistema = @(x) [
    a * cos(theta2_ref) + b * cos(x(1)) - c * cos(x(2)) - d;
    a * sin(theta2_ref) + b * sin(x(1)) - c * sin(x(2))
];

options = optimset('Display', 'off');
x0 = [deg2rad(20); deg2rad(45)];
[x_sol, ~, info] = fsolve(sistema, x0, options);

if info <= 0
    error('Falha na convergência para theta2 = 45°.');
end

theta3_ref = x_sol(1);
theta4_ref = x_sol(2);

% Ponto A (extremidade da manivela)
xA_ref = a * cos(theta2_ref);
yA_ref = a * sin(theta2_ref);
A_ref  = [xA_ref; yA_ref];

% Ponto B (extremidade do balancim)
xB_ref = d + c * cos(theta4_ref);
yB_ref = c * sin(theta4_ref);
B_ref  = [xB_ref; yB_ref];

% Ponto P (ponto do elo acoplador)
xP_ref = xA_ref + p * cos(theta3_ref + delta3);
yP_ref = yA_ref + p * sin(theta3_ref + delta3);
P_ref  = [xP_ref; yP_ref];

% Ponto G (Centro de Gravidade do elo acoplador triangular ABP)
xG_ref = (xA_ref + xB_ref + xP_ref) / 3;
yG_ref = (yA_ref + yB_ref + yP_ref) / 3;
G_ref  = [xG_ref; yG_ref];

fprintf("=====================================================\n");
fprintf("POSIÇÃO DOS PONTOS PARA theta2 = 45°:\n");
fprintf("-----------------------------------------------------\n");
fprintf("Ponto A (Manivela):  X_A = %7.2f mm | Y_A = %7.2f mm\n", A_ref(1), A_ref(2));
fprintf("Ponto B (Balancim):  X_B = %7.2f mm | Y_B = %7.2f mm\n", B_ref(1), B_ref(2));
fprintf("Ponto P (Acoplador): X_P = %7.2f mm | Y_P = %7.2f mm\n", P_ref(1), P_ref(2));
fprintf("Ponto G (CG elo 3):  X_G = %7.2f mm | Y_G = %7.2f mm\n", G_ref(1), G_ref(2));
fprintf("-----------------------------------------------------\n");
fprintf("Verificação do elo 3 (AB): %.2f mm (esperado: %.2f mm)\n", norm(B_ref - A_ref), b);
fprintf("Verificação do elo AP:     %.2f mm (esperado: %.2f mm)\n", norm(P_ref - A_ref), p);
fprintf("=====================================================\n\n");

% =========================================================================
% 3. Trajetórias para 0° <= theta2 <= 359° (360 passos de 1°)
% =========================================================================
theta2_deg = 0:1:359;
theta2_rad = deg2rad(theta2_deg);
N = length(theta2_rad); % 360 pontos

% Pré-alocação dos vetores de coordenadas
xA = zeros(1, N);
yA = zeros(1, N);
xB = zeros(1, N);
yB = zeros(1, N);
xP = zeros(1, N);
yP = zeros(1, N);

x_atual = x_sol;

for k = 1:N
    t2 = theta2_rad(k);
    
    sis = @(x) [
        a * cos(t2) + b * cos(x(1)) - c * cos(x(2)) - d;
        a * sin(t2) + b * sin(x(1)) - c * sin(x(2))
    ];
    
    [x_sol_k, ~, info_k] = fsolve(sis, x_atual, options);
    
    if info_k > 0
        t3_k = x_sol_k(1);
        t4_k = x_sol_k(2);
        
        % Coordenadas de A
        xA(k) = a * cos(t2);
        yA(k) = a * sin(t2);
        
        % Coordenadas de B
        xB(k) = d + c * cos(t4_k);
        yB(k) = c * sin(t4_k);
        
        % Coordenadas de P
        xP(k) = xA(k) + p * cos(t3_k + delta3);
        yP(k) = yA(k) + p * sin(t3_k + delta3);
        
        % Atualiza chute inicial
        x_atual = x_sol_k;
    else
        warning("Convergência falhou para theta2 = %d°", theta2_deg(k));
    end
end

% =========================================================================
% Matriz 6x360 com todas as posições dos pontos A, B e P
% =========================================================================
% Linha 1: X_A (mm)
% Linha 2: Y_A (mm)
% Linha 3: X_B (mm)
% Linha 4: Y_B (mm)
% Linha 5: X_P (mm)
% Linha 6: Y_P (mm)
% Colunas 1 a 360: correspondem a theta2 = 0°, 1°, ..., 359°
M_posicoes = [
    xA;
    yA;
    xB;
    yB;
    xP;
    yP
];

% Trajetória do Centro de Gravidade G (média vetorial de A, B e P)
xG = (xA + xB + xP) / 3;
yG = (yA + yB + yP) / 3;
G_posicoes = [xG; yG]; % Matriz 2x360

fprintf("=====================================================\n");
fprintf("MATRIZ DE POSIÇÕES (M_posicoes):\n");
fprintf("  Dimensão: %d linhas x %d colunas\n", size(M_posicoes, 1), size(M_posicoes, 2));
fprintf("  Linha 1: x_A(t2) | Linha 2: y_A(t2)\n");
fprintf("  Linha 3: x_B(t2) | Linha 4: y_B(t2)\n");
fprintf("  Linha 5: x_P(t2) | Linha 6: y_P(t2)\n");
fprintf("  Exemplo coluna 46 (theta2 = 45°):\n");
fprintf("    [xA; yA; xB; yB; xP; yP] = [%.2f; %.2f; %.2f; %.2f; %.2f; %.2f]\n", M_posicoes(:, 46));
fprintf("-----------------------------------------------------\n");
fprintf("TRAJETÓRIA DO CENTRO DE GRAVIDADE G (G_posicoes):\n");
fprintf("  Dimensão: %d linhas x %d colunas\n", size(G_posicoes, 1), size(G_posicoes, 2));
fprintf("  Faixa X_G: [%.2f, %.2f] mm\n", min(xG), max(xG));
fprintf("  Faixa Y_G: [%.2f, %.2f] mm\n", min(yG), max(yG));
fprintf("=====================================================\n\n");

% =========================================================================
% 4. Visualização Gráfica das Trajetórias (A, B, P e G)
% =========================================================================
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end

% --- FIGURA 1: Trajetórias separadas dos pontos A, B, P e G (2x2) ---
fig1 = figure('Name', 'Trajetorias Separadas - A, B, P e G', 'NumberTitle', 'off', 'Position', [100, 100, 900, 700]);

% Subplot 1: Trajetória do ponto A
subplot(2, 2, 1);
plot(xA, yA, 'b-', 'LineWidth', 2); hold on;
plot(0, 0, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
plot(xA_ref, yA_ref, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
grid on; axis equal;
title('Trajetória de A (Manivela)', 'FontSize', 11);
xlabel('X (mm)'); ylabel('Y (mm)');
legend('Trajetória de A', 'Pivô O_2', '\theta_2 = 45°', 'Location', 'northeast');

% Subplot 2: Trajetória do ponto B
subplot(2, 2, 2);
plot(xB, yB, 'r-', 'LineWidth', 2); hold on;
plot(d, 0, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
plot(xB_ref, yB_ref, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 6);
grid on; axis equal;
title('Trajetória de B (Balancim)', 'FontSize', 11);
xlabel('X (mm)'); ylabel('Y (mm)');
legend('Trajetória de B', 'Pivô O_4', '\theta_2 = 45°', 'Location', 'northeast');

% Subplot 3: Trajetória do ponto P
subplot(2, 2, 3);
plot(xP, yP, 'm-', 'LineWidth', 2); hold on;
plot(xP_ref, yP_ref, 'ko', 'MarkerFaceColor', 'm', 'MarkerSize', 6);
grid on; axis equal;
title('Trajetória de P (Acoplador)', 'FontSize', 11);
xlabel('X (mm)'); ylabel('Y (mm)');
legend('Trajetória de P', '\theta_2 = 45°', 'Location', 'northeast');

% Subplot 4: Trajetória do ponto G (Centro de Gravidade)
subplot(2, 2, 4);
plot(xG, yG, 'Color', [0.1, 0.6, 0.2], 'LineWidth', 2); hold on;
plot(xG_ref, yG_ref, 'ko', 'MarkerFaceColor', [0.1, 0.6, 0.2], 'MarkerSize', 6);
grid on; axis equal;
title('Trajetória de G (Centro de Gravidade)', 'FontSize', 11);
xlabel('X (mm)'); ylabel('Y (mm)');
legend('Trajetória de G', '\theta_2 = 45°', 'Location', 'northeast');

caminho_fig1 = fullfile(script_dir, 'assets', 'trajetorias_separadas_ABPG.png');
print(fig1, caminho_fig1, '-dpng', '-r300');
fprintf("Gráfico das 4 trajetórias salvo em: %s\n", caminho_fig1);

% --- FIGURA 2: Detalhe exclusivo da Trajetória do CG (Ponto G) ---
fig2 = figure('Name', 'Trajetoria do Centro de Gravidade (G)', 'NumberTitle', 'off');
plot(xG, yG, 'Color', [0.1, 0.6, 0.2], 'LineWidth', 2.2); hold on;
plot(xG_ref, yG_ref, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
grid on; axis equal;
title('Trajetória do Centro de Gravidade G (Elo Acoplador)', 'FontSize', 12);
xlabel('X_G (mm)', 'FontSize', 11);
ylabel('Y_G (mm)', 'FontSize', 11);
legend('Trajetória de G (\theta_2: 0° a 359°)', 'Posição em \theta_2 = 45°', 'Location', 'northeast');

caminho_fig2 = fullfile(script_dir, 'assets', 'trajetoria_ponto_G.png');
print(fig2, caminho_fig2, '-dpng', '-r300');
fprintf("Gráfico específico do ponto G salvo em: %s\n", caminho_fig2);
