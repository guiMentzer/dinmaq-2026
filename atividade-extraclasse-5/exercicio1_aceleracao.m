% =========================================================================
% Atividade Extraclasse nº 5 - Exercício 1
% Análise de Aceleração em Mecanismo de 4 Barras (Norton 2010)
% Aluno: Guilherme Paiva Crispim Abalém | Prof. Sigeo Kitatani Jr.
% =========================================================================

clear; clc; close all;

% -------------------------------------------------------------------------
% 1. Parâmetros do mecanismo e condições cinemáticas de entrada
% -------------------------------------------------------------------------
a = 40.0;           % Elo 2: Manivela (mm)
b = 208.81;         % Elo 3: Acoplador (mm)
c = 70.0;           % Elo 4: Balancim (mm)
d = 200.0;          % Elo 1: Base fixa (mm)

theta2_deg = 45.0;
theta2 = deg2rad(theta2_deg);
omega2 = 1.0;       % rad/s
alpha2 = 0.1;       % rad/s^2

% -------------------------------------------------------------------------
% 2. Análise de Posição (Equação de Circuito Fechado - Newton-Raphson)
% -------------------------------------------------------------------------
sis_pos = @(x) [
    a * cos(theta2) + b * cos(x(1)) - c * cos(x(2)) - d;
    a * sin(theta2) + b * sin(x(1)) - c * sin(x(2))
];

opt = optimset('Display', 'off');
x0 = [deg2rad(10); deg2rad(60)];
[x_sol, res_pos, info_pos] = fsolve(sis_pos, x0, opt);

if info_pos <= 0
    error('Falha na convergência da análise de posição para theta2 = 45°.');
end

theta3 = x_sol(1);
theta4 = x_sol(2);

% Coordenadas dos nós
O2 = [0; 0];
O4 = [d; 0];
A  = [a * cos(theta2); a * sin(theta2)];
B  = [d + c * cos(theta4); c * sin(theta4)];

% -------------------------------------------------------------------------
% 3. Análise de Velocidades (Matriz Jacobiana)
% -------------------------------------------------------------------------
J = [
   -b * sin(theta3),  c * sin(theta4);
    b * cos(theta3), -c * cos(theta4)
];

b_vel = [
    a * omega2 * sin(theta2);
   -a * omega2 * cos(theta2)
];

w_sol = J \ b_vel;
omega3 = w_sol(1);
omega4 = w_sol(2);

% Velocidades dos pontos
vA = a * omega2 * [-sin(theta2); cos(theta2)];
vB = c * omega4 * [-sin(theta4); cos(theta4)];
vBA = b * omega3 * [-sin(theta3); cos(theta3)];

% -------------------------------------------------------------------------
% 4. Análise de Acelerações (Segunda Derivada do Circuito Fechado)
% -------------------------------------------------------------------------
% Equação Matricial: J * [alpha3; alpha4] = b_acc
b_acc = [
    a * alpha2 * sin(theta2) + a * (omega2^2) * cos(theta2) + b * (omega3^2) * cos(theta3) - c * (omega4^2) * cos(theta4);
   -a * alpha2 * cos(theta2) + a * (omega2^2) * sin(theta2) + b * (omega3^2) * sin(theta3) - c * (omega4^2) * sin(theta4)
];

alpha_sol = J \ b_acc;
alpha3 = alpha_sol(1);
alpha4 = alpha_sol(2);

% Componentes de Aceleração do Ponto A:
% Tangencial: a * alpha2 (perpendicular a O2A)
At_A = a * alpha2 * [-sin(theta2); cos(theta2)];
% Normal: a * omega2^2 (aponta de A para O2)
An_A = -a * (omega2^2) * [cos(theta2); sin(theta2)];
% Resultante:
A_tot = At_A + An_A;

% Componentes de Aceleração do Ponto B:
% Tangencial: c * alpha4 (perpendicular a O4B)
At_B = c * alpha4 * [-sin(theta4); cos(theta4)];
% Normal: c * omega4^2 (aponta de B para O4)
An_B = -c * (omega4^2) * [cos(theta4); sin(theta4)];
% Resultante:
B_tot = At_B + An_B;

% Componentes da Aceleração Relativa B em relação a A (Elo 3):
At_BA = b * alpha3 * [-sin(theta3); cos(theta3)];
An_BA = -b * (omega3^2) * [cos(theta3); sin(theta3)];
BA_tot = At_BA + An_BA;

% Resíduo da verificação: B_tot deve ser estritamente igual a A_tot + BA_tot
erro_fechamento_acc = norm(B_tot - (A_tot + BA_tot));

% Impressão detalhada no console
fprintf('========================================================================\n');
fprintf('RESULTADOS DA ANÁLISE CINEMÁTICA - EXERCÍCIO 1 (theta2 = 45°)\n');
fprintf('========================================================================\n');
fprintf('Posição Angular:\n');
fprintf('  theta2 = %8.4f rad (%6.2f°)\n', theta2, rad2deg(theta2));
fprintf('  theta3 = %8.4f rad (%6.2f°)\n', theta3, rad2deg(theta3));
fprintf('  theta4 = %8.4f rad (%6.2f°)\n', theta4, rad2deg(theta4));
fprintf('\nVelocidades Angulares:\n');
fprintf('  omega2 = %8.4f rad/s\n', omega2);
fprintf('  omega3 = %8.6f rad/s\n', omega3);
fprintf('  omega4 = %8.6f rad/s\n', omega4);
fprintf('\nAcelerações Angulares:\n');
fprintf('  alpha2 = %8.4f rad/s^2\n', alpha2);
fprintf('  alpha3 = %8.6f rad/s^2\n', alpha3);
fprintf('  alpha4 = %8.6f rad/s^2\n', alpha4);
fprintf('------------------------------------------------------------------------\n');
fprintf('COMPONENTES DE ACELERAÇÃO NO PONTO A:\n');
fprintf('  Aceleração Tangencial: At_A = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', At_A(1), At_A(2), norm(At_A));
fprintf('  Aceleração Normal:     An_A = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', An_A(1), An_A(2), norm(An_A));
fprintf('  Aceleração Total:      A_tot = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', A_tot(1), A_tot(2), norm(A_tot));
fprintf('------------------------------------------------------------------------\n');
fprintf('COMPONENTES DE ACELERAÇÃO NO PONTO B:\n');
fprintf('  Aceleração Tangencial: At_B = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', At_B(1), At_B(2), norm(At_B));
fprintf('  Aceleração Normal:     An_B = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', An_B(1), An_B(2), norm(An_B));
fprintf('  Aceleração Total:      B_tot = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', B_tot(1), B_tot(2), norm(B_tot));
fprintf('------------------------------------------------------------------------\n');
fprintf('COMPONENTES DA ACELERAÇÃO RELATIVA (B/A):\n');
fprintf('  Aceleração Tangencial: At_BA = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', At_BA(1), At_BA(2), norm(At_BA));
fprintf('  Aceleração Normal:     An_BA = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', An_BA(1), An_BA(2), norm(An_BA));
fprintf('  Aceleração Total:      BA_tot = [%8.4f, %8.4f] mm/s^2 | Módulo = %8.4f mm/s^2\n', BA_tot(1), BA_tot(2), norm(BA_tot));
fprintf('------------------------------------------------------------------------\n');
fprintf('Verificação de Consistência Vetorial: ||B_tot - (A_tot + BA_tot)|| = %e mm/s^2\n', erro_fechamento_acc);
fprintf('========================================================================\n\n');

% Diretório para salvar imagens
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 5. Gráfico 1: Desenho Esquemático Técnico (Simulação de CAD cotado)
% -------------------------------------------------------------------------
fig1 = figure('Name', 'Mecanismo 4 Barras - Esquema CAD', 'NumberTitle', 'off', 'Position', [100, 100, 950, 650]);
hold on; grid on; axis equal;

% Linha da base fixa
plot([O2(1), O4(1)], [O2(2), O4(2)], 'k--', 'LineWidth', 1.2);

% Barras do mecanismo
plot([O2(1), A(1)], [O2(2), A(2)], 'b-', 'LineWidth', 3.5);             % Elo 2
plot([A(1), B(1)], [A(2), B(2)], 'Color', [0.1, 0.6, 0.2], 'LineWidth', 3.5); % Elo 3
plot([O4(1), B(1)], [O4(2), B(2)], 'r-', 'LineWidth', 3.5);             % Elo 4

% Juntas rotativas (pinos)
plot(O2(1), O2(2), 'ks', 'MarkerFaceColor', [0.3 0.3 0.3], 'MarkerSize', 10);
plot(O4(1), O4(2), 'ks', 'MarkerFaceColor', [0.3 0.3 0.3], 'MarkerSize', 10);
plot(A(1), A(2), 'ko', 'MarkerFaceColor', 'b', 'MarkerSize', 9);
plot(B(1), B(2), 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 9);

% Triângulos de suporte para mancais fixos O2 e O4
tri_h = 10; tri_b = 8;
fill([O2(1), O2(1)-tri_b, O2(1)+tri_b], [O2(2), O2(2)-tri_h, O2(2)-tri_h], [0.8 0.8 0.8], 'EdgeColor', 'k');
fill([O4(1), O4(1)-tri_b, O4(1)+tri_b], [O4(2), O4(2)-tri_h, O4(2)-tri_h], [0.8 0.8 0.8], 'EdgeColor', 'k');
plot([O2(1)-tri_b-4, O2(1)+tri_b+4], [O2(2)-tri_h, O2(2)-tri_h], 'k-', 'LineWidth', 1.5);
plot([O4(1)-tri_b-4, O4(1)+tri_b+4], [O4(2)-tri_h, O4(2)-tri_h], 'k-', 'LineWidth', 1.5);

% Arcos e cotas de ângulos
ang_arc = linspace(0, theta2, 40);
plot(18*cos(ang_arc), 18*sin(ang_arc), 'k-', 'LineWidth', 1.0);
text(22, 10, sprintf('\\theta_2 = 45.0°'), 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'b');

ang_arc4 = linspace(0, theta4, 40);
plot(O4(1) + 20*cos(ang_arc4), O4(2) + 20*sin(ang_arc4), 'k-', 'LineWidth', 1.0);
text(O4(1) + 24, 15, sprintf('\\theta_4 = %.2f°', rad2deg(theta4)), 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'r');

% Rótulos dos nós e elos
text(O2(1)-18, O2(2)+6, 'O_2 (0,0)', 'FontSize', 12, 'FontWeight', 'bold');
text(O4(1)+6, O4(2)+6, sprintf('O_4 (%d,0)', d), 'FontSize', 12, 'FontWeight', 'bold');
text(A(1)-14, A(2)+14, sprintf('A (%.1f, %.1f)', A(1), A(2)), 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'b');
text(B(1)+6, B(2)+12, sprintf('B (%.1f, %.1f)', B(1), B(2)), 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'r');

% Rótulos de dimensão dos elos
text(A(1)/2 - 12, A(2)/2 + 8, 'a = 40 mm', 'FontSize', 11, 'Color', 'b', 'FontAngle', 'italic');
text((A(1)+B(1))/2 - 10, (A(2)+B(2))/2 + 12, 'b = 208.81 mm', 'FontSize', 11, 'Color', [0.1 0.6 0.2], 'FontAngle', 'italic');
text((O4(1)+B(1))/2 + 8, (O4(2)+B(2))/2, 'c = 70 mm', 'FontSize', 11, 'Color', 'r', 'FontAngle', 'italic');
text(d/2 - 15, -16, 'd = 200 mm', 'FontSize', 11, 'Color', 'k', 'FontAngle', 'italic');

title('Exercício 1: Esquema Estrutural Cotado do Mecanismo de 4 Barras (\theta_2 = 45°)', 'FontSize', 13);
xlabel('Coordenada X (mm)', 'FontSize', 11);
ylabel('Coordenada Y (mm)', 'FontSize', 11);
xlim([-40, 270]);
ylim([-35, 95]);

caminho_fig1 = fullfile(assets_dir, 'ex1_cad_mecanismo.png');
print(fig1, caminho_fig1, '-dpng', '-r300');
fprintf('Figura 1 salva em: %s\n', caminho_fig1);

% -------------------------------------------------------------------------
% 6. Gráfico 2: Componentes de Aceleração sobre a Solução Gráfica
% -------------------------------------------------------------------------
fig2 = figure('Name', 'Mecanismo 4 Barras - Componentes de Aceleracao', 'NumberTitle', 'off', 'Position', [100, 100, 950, 650]);
hold on; grid on; axis equal;

% Traçado suave do mecanismo em segundo plano (tons atenuados)
plot([O2(1), O4(1)], [O2(2), O4(2)], 'k--', 'LineWidth', 1.0);
plot([O2(1), A(1)], [O2(2), A(2)], 'Color', [0.4 0.4 0.8], 'LineWidth', 2.0);
plot([A(1), B(1)], [A(2), B(2)], 'Color', [0.4 0.7 0.4], 'LineWidth', 2.0);
plot([O4(1), B(1)], [O4(2), B(2)], 'Color', [0.8 0.4 0.4], 'LineWidth', 2.0);

plot(O2(1), O2(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(O4(1), O4(2), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(A(1), A(2), 'ko', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
plot(B(1), B(2), 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

text(O2(1)-14, O2(2)-8, 'O_2', 'FontSize', 11, 'FontWeight', 'bold');
text(O4(1)+6, O4(2)-8, 'O_4', 'FontSize', 11, 'FontWeight', 'bold');
text(A(1)+4, A(2)+6, 'A', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'b');
text(B(1)+6, B(2)+4, 'B', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'r');

% Função aninhada/local para desenhar vetores com ponta triangular perfeitamente dimensionada
function desenhar_seta_custom(x0, y0, u, v, cor, largura, tam_cabeca_nom)
    L = norm([u, v]);
    if L < 1e-6
        return;
    end
    x1 = x0 + u;
    y1 = y0 + v;
    
    % Haste do vetor
    plot([x0, x1], [y0, y1], 'Color', cor, 'LineWidth', largura);
    
    % Vetores unitários
    ux = u / L; uy = v / L;
    px = -uy;   py = ux;
    
    % Limita a cabeça a no máximo 35% do comprimento do vetor
    hc = min(tam_cabeca_nom, 0.35 * L);
    wc = hc * 0.45; % meia-largura da base
    
    % Vértices da cabeça triangular preenchida
    p_tip   = [x1, y1];
    p_left  = [x1 - hc*ux + wc*px, y1 - hc*uy + wc*py];
    p_right = [x1 - hc*ux - wc*px, y1 - hc*uy - wc*py];
    
    fill([p_tip(1), p_left(1), p_right(1)], [p_tip(2), p_left(2), p_right(2)], cor, 'EdgeColor', cor);
end

% Fator de escala visual para desenhar os vetores de aceleração (mm por mm/s^2)
s_acc = 1.0;
cor_normal = [0.0, 0.4, 0.85];       % Azul para componente normal
cor_tang   = [0.90, 0.35, 0.0];      % Laranja/Vermelho para tangencial
cor_tot    = [0.55, 0.0, 0.65];      % Roxo para resultante total

% --- VETORES NO PONTO A ---
% Normal An_A (aponta de A para O2)
desenhar_seta_custom(A(1), A(2), s_acc*An_A(1), s_acc*An_A(2), cor_normal, 2.2, 4.0);
% Tangencial At_A (perpendicular a O2A)
desenhar_seta_custom(A(1), A(2), s_acc*At_A(1), s_acc*At_A(2), cor_tang, 2.2, 2.5);
% Resultante A_tot
desenhar_seta_custom(A(1), A(2), s_acc*A_tot(1), s_acc*A_tot(2), cor_tot, 2.6, 4.5);

% --- VETORES NO PONTO B ---
% Normal An_B (aponta de B para O4)
desenhar_seta_custom(B(1), B(2), s_acc*An_B(1), s_acc*An_B(2), cor_normal, 2.2, 3.5);
% Tangencial At_B (perpendicular a O4B)
desenhar_seta_custom(B(1), B(2), s_acc*At_B(1), s_acc*At_B(2), cor_tang, 2.2, 4.0);
% Resultante B_tot
desenhar_seta_custom(B(1), B(2), s_acc*B_tot(1), s_acc*B_tot(2), cor_tot, 2.6, 4.5);

% Anotações textuais explicativas bem posicionadas
text(A(1) + s_acc*An_A(1)/2 + 4, A(2) + s_acc*An_A(2)/2 - 5, ...
    sprintf('A_A^n (40.0 mm/s^2)'), 'FontSize', 9, 'Color', cor_normal, 'FontWeight', 'bold');
text(A(1) + s_acc*At_A(1) - 28, A(2) + s_acc*At_A(2) + 6, ...
    sprintf('A_A^t (4.0 mm/s^2)'), 'FontSize', 9, 'Color', cor_tang, 'FontWeight', 'bold');
text(A(1) + s_acc*A_tot(1) - 20, A(2) + s_acc*A_tot(2) + 8, ...
    sprintf('A_A (40.2 mm/s^2)'), 'FontSize', 10, 'Color', cor_tot, 'FontWeight', 'bold');

text(B(1) + s_acc*An_B(1) + 4, B(2) + s_acc*An_B(2) - 6, ...
    sprintf('A_B^n (12.9 mm/s^2)'), 'FontSize', 9, 'Color', cor_normal, 'FontWeight', 'bold');
text(B(1) + s_acc*At_B(1)/2 - 10, B(2) + s_acc*At_B(2)/2 + 10, ...
    sprintf('A_B^t (35.2 mm/s^2)'), 'FontSize', 9, 'Color', cor_tang, 'FontWeight', 'bold');
text(B(1) + s_acc*B_tot(1) - 32, B(2) + s_acc*B_tot(2) + 8, ...
    sprintf('A_B (37.5 mm/s^2)'), 'FontSize', 10, 'Color', cor_tot, 'FontWeight', 'bold');

% Handles fictícios para legenda limpa e perfeita
h_leg_normal = plot(nan, nan, 'Color', cor_normal, 'LineWidth', 2.2);
h_leg_tang   = plot(nan, nan, 'Color', cor_tang,   'LineWidth', 2.2);
h_leg_tot    = plot(nan, nan, 'Color', cor_tot,    'LineWidth', 2.6);

title('Exercício 1: Componentes de Aceleração sobre o Mecanismo (\theta_2 = 45°)', 'FontSize', 12);
xlabel('Coordenada X (mm)', 'FontSize', 11);
ylabel('Coordenada Y (mm)', 'FontSize', 11);
legend([h_leg_normal, h_leg_tang, h_leg_tot], ...
    {'Componente Normal (A^n, centrípeta)', ...
     'Componente Tangencial (A^t)', ...
     'Aceleração Total Resultante (A_{tot})'}, ...
    'Location', 'northwest', 'FontSize', 10);

xlim([-40, 270]);
ylim([-35, 95]);

caminho_fig2 = fullfile(assets_dir, 'ex1_aceleracoes_vetores.png');
print(fig2, caminho_fig2, '-dpng', '-r300');
fprintf('Figura 2 salva em: %s\n', caminho_fig2);

% -------------------------------------------------------------------------
% 7. Gráfico 3: Acelerações Angulares alpha3 e alpha4 vs theta2 (0° a 360°)
% -------------------------------------------------------------------------
N_ang = 360;
th2_vec = linspace(0, 360, N_ang);
al3_vec = zeros(1, N_ang);
al4_vec = zeros(1, N_ang);
w3_vec  = zeros(1, N_ang);
w4_vec  = zeros(1, N_ang);

x_curr = x_sol;
for k = 1:N_ang
    t2_k = deg2rad(th2_vec(k));
    sis_k = @(x) [
        a * cos(t2_k) + b * cos(x(1)) - c * cos(x(2)) - d;
        a * sin(t2_k) + b * sin(x(1)) - c * sin(x(2))
    ];
    [x_k, ~, info_k] = fsolve(sis_k, x_curr, opt);
    x_curr = x_k;
    t3_k = x_k(1);
    t4_k = x_k(2);
    
    J_k = [-b*sin(t3_k), c*sin(t4_k); b*cos(t3_k), -c*cos(t4_k)];
    b_vel_k = [a*omega2*sin(t2_k); -a*omega2*cos(t2_k)];
    w_k = J_k \ b_vel_k;
    w3_vec(k) = w_k(1);
    w4_vec(k) = w_k(2);
    
    b_acc_k = [
        a*alpha2*sin(t2_k) + a*(omega2^2)*cos(t2_k) + b*(w_k(1)^2)*cos(t3_k) - c*(w_k(2)^2)*cos(t4_k);
       -a*alpha2*cos(t2_k) + a*(omega2^2)*sin(t2_k) + b*(w_k(1)^2)*sin(t3_k) - c*(w_k(2)^2)*sin(t4_k)
    ];
    al_k = J_k \ b_acc_k;
    al3_vec(k) = al_k(1);
    al4_vec(k) = al_k(2);
end

fig3 = figure('Name', 'Aceleracoes Angulares vs Theta2', 'NumberTitle', 'off', 'Position', [150, 150, 850, 550]);
plot(th2_vec, al3_vec, 'Color', [0.1 0.6 0.2], 'LineWidth', 2.0); hold on;
plot(th2_vec, al4_vec, 'r-', 'LineWidth', 2.0);
plot(45, alpha3, 'o', 'MarkerFaceColor', [0.1 0.6 0.2], 'MarkerEdgeColor', 'k', 'MarkerSize', 7);
plot(45, alpha4, 's', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 7);
plot([0, 360], [0, 0], 'k--', 'LineWidth', 0.8);
grid on;
title('Evolução das Acelerações Angulares (\alpha_3 e \alpha_4) para 0° \leq \theta_2 \leq 360°', 'FontSize', 12);
xlabel('\theta_2 (graus)', 'FontSize', 11);
ylabel('Aceleração Angular (rad/s^2)', 'FontSize', 11);
xlim([0, 360]);
legend({'\alpha_3(\theta_2) - Elo Acoplador', ...
        '\alpha_4(\theta_2) - Elo Balancim', ...
        sprintf('\\alpha_3 em 45° = %.4f rad/s^2', alpha3), ...
        sprintf('\\alpha_4 em 45° = %.4f rad/s^2', alpha4)}, ...
       'Location', 'northeast', 'FontSize', 10);

caminho_fig3 = fullfile(assets_dir, 'ex1_aceleracoes_angulares.png');
print(fig3, caminho_fig3, '-dpng', '-r300');
fprintf('Figura 3 salva em: %s\n', caminho_fig3);

fprintf('\nTodos os cálculos e gráficos do Exercício 1 concluídos com sucesso!\n');
