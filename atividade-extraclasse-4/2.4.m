% =========================================================================
% Item 2.4 - Diagrama Quiver dos Vetores Velocidade VA
% Disciplina: Dinâmica das Máquinas - Atividade Prática 4
% =========================================================================

clear; clc; close all;

% 1. Parâmetros geométricos e cinemáticos conhecidos
a = 40.0;          % Elo 2: Manivela (mm)
b = 208.81;        % Elo 3: Acoplador (mm)
c = 70.0;          % Elo 4: Balancim (mm)
d = 200.0;         % Elo 1: Base fixa (mm)
omega2 = 0.1;      % Velocidade angular da manivela (rad/s)

% -------------------------------------------------------------------------
% 2. Intervalo de análise: 0 <= theta2 <= pi (0° a 180°)
% -------------------------------------------------------------------------
theta2_deg = 0:1:180;
theta2_rad = deg2rad(theta2_deg);
N = length(theta2_deg);

% Componentes do vetor velocidade VA para cada ângulo
% VA = omega2 x rA => VA_x = -a*omega2*sin(theta2), VA_y = a*omega2*cos(theta2)
VA_x = -a * omega2 * sin(theta2_rad);
VA_y =  a * omega2 * cos(theta2_rad);

% Posição de referência theta2 = 45°
idx_45 = find(theta2_deg == 45, 1);
VA_45 = [VA_x(idx_45); VA_y(idx_45)];

fprintf("=====================================================\n");
fprintf("Vetor Velocidade VA para theta2 = 45°:\n");
fprintf("  VA_x = %7.4f mm/s\n", VA_45(1));
fprintf("  VA_y = %7.4f mm/s\n", VA_45(2));
fprintf("  |VA| = %7.4f mm/s\n", hypot(VA_45(1), VA_45(2)));
fprintf("=====================================================\n\n");

% -------------------------------------------------------------------------
% 3. Amostragem dos vetores para o comando quiver
% -------------------------------------------------------------------------
% Amostra a cada 30 graus para manter as flechas limpas e sem sobreposição
passo_amostra = 30;
idx_amostras = 1:passo_amostra:N;

% Garante que 180° e 45° estejam explicitamente incluídos
if idx_amostras(end) ~= N
    idx_amostras = [idx_amostras, N];
end
if ~ismember(idx_45, idx_amostras)
    idx_amostras = sort([idx_amostras, idx_45]);
end

% Vetores da amostragem regular (excluindo 45° para traçar em destaque)
idx_regulares = idx_amostras(idx_amostras ~= idx_45);

% Origem dos vetores no plano de velocidades: (0, 0)
X0_reg = zeros(size(idx_regulares));
Y0_reg = zeros(size(idx_regulares));
U_reg  = VA_x(idx_regulares);
V_reg  = VA_y(idx_regulares);

% -------------------------------------------------------------------------
% 4. Geração do Gráfico do Item 2.4 (Plano de Velocidades com Quiver)
% -------------------------------------------------------------------------
fig = figure(1, 'Name', 'Item 2.4 - Vetores Velocidade VA (Quiver)', 'NumberTitle', 'off');
clf(fig);

% 1. Curva contínua do hodógrafo (trajetória de VA) em segundo plano
plot(VA_x, VA_y, 'b--', 'LineWidth', 1.5);
hold on;

% 2. Vetores quiver regulares saindo da origem (escala 0 = comprimento real)
h_quiver = quiver(X0_reg, Y0_reg, U_reg, V_reg, 0, ...
                  'Color', [0.15, 0.45, 0.85], 'LineWidth', 1.4, 'MaxHeadSize', 0.08);

% 3. Vetor quiver em destaque para theta2 = 45°
h_quiver_45 = quiver(0, 0, VA_45(1), VA_45(2), 0, ...
                     'Color', 'r', 'LineWidth', 2.2, 'MaxHeadSize', 0.10);
plot(VA_45(1), VA_45(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);

% 4. Marcador da origem (polo de velocidade zero)
plot(0, 0, 'k+', 'MarkerSize', 10, 'LineWidth', 1.5);

% 5. Linhas dos eixos passando pela origem
line([-5.5, 4.0], [0, 0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', ':', 'LineWidth', 0.8);
line([0, 0], [-5.0, 5.0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', ':', 'LineWidth', 0.8);

grid on;
axis equal;
xlim([-4.8, 3.8]);
ylim([-4.8, 4.8]);

title('Item 2.4: Diagrama Quiver dos Vetores Velocidade V_A (0 \leq \theta_2 \leq \pi)', 'FontSize', 12);
xlabel('Componente V_{Ax} (mm/s)', 'FontSize', 11);
ylabel('Componente V_{Ay} (mm/s)', 'FontSize', 11);

leg_45 = sprintf('V_A(\\theta_2 = 45°) = (%.2f, %.2f) mm/s', VA_45(1), VA_45(2));
legend([plot(NaN,NaN,'b--','LineWidth',1.5), h_quiver, h_quiver_45], ...
       'Hodógrafo de V_A', ...
       'Vetores V_A (\Delta\theta_2 = 30°)', ...
       leg_45, ...
       'Location', 'northeast');

% -------------------------------------------------------------------------
% 5. Salvar imagem na pasta assets
% -------------------------------------------------------------------------
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

caminho_imagem = fullfile(assets_dir, 'grafico_2_4_quiver_VA.png');
print(fig, caminho_imagem, '-dpng', '-r300');
fprintf("Gráfico 2.4 salvo com sucesso em: %s\n", caminho_imagem);

% -------------------------------------------------------------------------
% 6. Manter a janela aberta
% -------------------------------------------------------------------------
fprintf('\n=========================================================================\n');
fprintf('Gráfico 2.4 gerado com sucesso!\n');
fprintf('Pressione <ENTER> no terminal para encerrar o programa e fechar a janela...\n');
fprintf('=========================================================================\n');
pause;
