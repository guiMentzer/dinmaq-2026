% =========================================================================
% Item 2.5 - Diagrama Quiver dos Vetores Velocidade VB
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

theta3_rad = zeros(1, N);
theta4_rad = zeros(1, N);
omega4_rad = zeros(1, N);

x_atual = [deg2rad(10); deg2rad(60)];
options = optimset('Display', 'off');

for k = 1:N
    t2 = theta2_rad(k);
    
    sistema = @(x) [
        a * cos(t2) + b * cos(x(1)) - c * cos(x(2)) - d;
        a * sin(t2) + b * sin(x(1)) - c * sin(x(2))
    ];
    
    [x_sol, ~, info] = fsolve(sistema, x_atual, options);
    
    if info > 0
        t3 = x_sol(1);
        t4 = x_sol(2);
        theta3_rad(k) = t3;
        theta4_rad(k) = t4;
        x_atual = x_sol;
        
        % Velocidade angular do balancim (omega4)
        J = [-b * sin(t3),  c * sin(t4);
              b * cos(t3), -c * cos(t4)];
        A = [ a * omega2 * sin(t2);
             -a * omega2 * cos(t2)];
        w = J \ A;
        omega4_rad(k) = w(2);
    else
        warning("Convergência falhou para theta2 = %d°", theta2_deg(k));
    end
end

% -------------------------------------------------------------------------
% 3. Componentes do vetor velocidade VB
% -------------------------------------------------------------------------
% Ponto B (elo 4 em rotação pura em torno de O4):
% VB = omega4 x rO4B => VB_x = -c*omega4*sin(theta4), VB_y = c*omega4*cos(theta4)
VB_x = -c * omega4_rad .* sin(theta4_rad);
VB_y =  c * omega4_rad .* cos(theta4_rad);

% Posição de referência theta2 = 45°
idx_45 = find(theta2_deg == 45, 1);
VB_45 = [VB_x(idx_45); VB_y(idx_45)];

fprintf("=====================================================\n");
fprintf("Vetor Velocidade VB para theta2 = 45°:\n");
fprintf("  VB_x = %7.4f mm/s\n", VB_45(1));
fprintf("  VB_y = %7.4f mm/s\n", VB_45(2));
fprintf("  |VB| = %7.4f mm/s\n", hypot(VB_45(1), VB_45(2)));
fprintf("=====================================================\n\n");

% -------------------------------------------------------------------------
% 4. Amostragem dos vetores para o comando quiver
% -------------------------------------------------------------------------
passo_amostra = 30;
idx_amostras = 1:passo_amostra:N;

if idx_amostras(end) ~= N
    idx_amostras = [idx_amostras, N];
end
if ~ismember(idx_45, idx_amostras)
    idx_amostras = sort([idx_amostras, idx_45]);
end

idx_regulares = idx_amostras(idx_amostras ~= idx_45);

% Origem dos vetores no plano de velocidades: (0, 0)
X0_reg = zeros(size(idx_regulares));
Y0_reg = zeros(size(idx_regulares));
U_reg  = VB_x(idx_regulares);
V_reg  = VB_y(idx_regulares);

% -------------------------------------------------------------------------
% 5. Geração do Gráfico do Item 2.5 (Plano de Velocidades com Quiver)
% -------------------------------------------------------------------------
fig = figure(1, 'Name', 'Item 2.5 - Vetores Velocidade VB (Quiver)', 'NumberTitle', 'off');
clf(fig);

% 1. Curva contínua do hodógrafo (trajetória de VB) em segundo plano
plot(VB_x, VB_y, 'r--', 'LineWidth', 1.5);
hold on;

% 2. Vetores quiver regulares saindo da origem (escala 0 = comprimento real)
h_quiver = quiver(X0_reg, Y0_reg, U_reg, V_reg, 0, ...
                  'Color', [0.85, 0.35, 0.1], 'LineWidth', 1.3, 'MaxHeadSize', 0.08);

% 3. Vetor quiver em destaque para theta2 = 45°
h_quiver_45 = quiver(0, 0, VB_45(1), VB_45(2), 0, ...
                     'Color', 'b', 'LineWidth', 2.2, 'MaxHeadSize', 0.10);
plot(VB_45(1), VB_45(2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 7);

% 4. Marcador da origem (polo de velocidade zero)
plot(0, 0, 'k+', 'MarkerSize', 10, 'LineWidth', 1.5);

% 5. Linhas dos eixos passando pela origem
line([-5.5, 3.5], [0, 0], 'Color', [0.5, 0.5, 0.5], 'LineStyle', ':', 'LineWidth', 0.8);
line([0, 0], [-2.5, 2.5], 'Color', [0.5, 0.5, 0.5], 'LineStyle', ':', 'LineWidth', 0.8);

grid on;
axis equal;
xlim([-4.8, 3.2]);
ylim([-1.8, 2.2]);

title('Item 2.5: Diagrama Quiver dos Vetores Velocidade V_B (0 \leq \theta_2 \leq \pi)', 'FontSize', 12);
xlabel('Componente V_{Bx} (mm/s)', 'FontSize', 11);
ylabel('Componente V_{By} (mm/s)', 'FontSize', 11);

leg_45 = sprintf('V_B(\\theta_2 = 45°) = (%.2f, %.2f) mm/s', VB_45(1), VB_45(2));
legend([plot(NaN,NaN,'r--','LineWidth',1.5), h_quiver, h_quiver_45], ...
       'Hodógrafo de V_B', ...
       'Vetores V_B (\Delta\theta_2 = 30°)', ...
       leg_45, ...
       'Location', 'northeast');

% -------------------------------------------------------------------------
% 6. Salvar imagem na pasta assets
% -------------------------------------------------------------------------
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = '.';
end
assets_dir = fullfile(script_dir, 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

caminho_imagem = fullfile(assets_dir, 'grafico_2_5_quiver_VB.png');
print(fig, caminho_imagem, '-dpng', '-r300');
fprintf("Gráfico 2.5 salvo com sucesso em: %s\n", caminho_imagem);

% -------------------------------------------------------------------------
% 7. Manter a janela aberta
% -------------------------------------------------------------------------
fprintf('\n=========================================================================\n');
fprintf('Gráfico 2.5 gerado com sucesso!\n');
fprintf('Pressione <ENTER> no terminal para encerrar o programa e fechar a janela...\n');
fprintf('=========================================================================\n');
pause;
