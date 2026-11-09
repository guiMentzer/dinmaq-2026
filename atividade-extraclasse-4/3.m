% =========================================================================
% Item 3.1 - relação entre velocidades angulares omega3 e omega4 em função de theta2
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
% 2. Intervalo de análise: 0 <= theta2 <= pi (0° a 360°)
% -------------------------------------------------------------------------
theta2_deg = 0:1:360;
theta2_rad = deg2rad(theta2_deg);
N = length(theta2_deg);

theta3_rad = zeros(1, N);
theta4_rad = zeros(1, N);
omega3_rad = zeros(1, N);
omega4_rad = zeros(1, N);

relacao_omega3 = zeros(1, N);
relacao_omega4 = zeros(1, N);
vantagem_mecanica = NaN(1, N);

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
        omega3_rad(k) = w(1);
        omega4_rad(k) = w(2);

        relacao_omega3(k) = omega3_rad(k) / omega2;
        relacao_omega4(k) = omega4_rad(k) / omega2;

        vantagem_mecanica(k) = (omega2 / relacao_omega4(k))*(a / c);
    else
        warning("Convergência falhou para theta2 = %d°", theta2_deg(k));
    end
end

% -------------------------------------------------------------------------
% 3. Graficos das relacoes entre velocidades angulares
% -------------------------------------------------------------------------
fig_omega = figure(1, 'Name', 'Item 3.1 - Relacoes de Velocidade Angular', 'NumberTitle', 'off');
clf(fig_omega);

subplot(2, 1, 1);
plot(theta2_deg, relacao_omega3, 'b-', 'LineWidth', 1.5);
grid on;
xlim([0, 360]);
title('Item 3.1: {\omega_3}/{\omega_2}', 'FontSize', 12);
xlabel('{\theta_2} (graus)', 'FontSize', 11);
ylabel('{\omega_3}/{\omega_2}', 'FontSize', 11);

subplot(2, 1, 2);
plot(theta2_deg, relacao_omega4, 'r-', 'LineWidth', 1.5);
grid on;
xlim([0, 360]);
title('Item 3.1: {\omega_4}/{\omega_2}', 'FontSize', 12);
xlabel('{\theta_2} (graus)', 'FontSize', 11);
ylabel('{\omega_4}/{\omega_2}', 'FontSize', 11);


% -------------------------------------------------------------------------
% 4. Graficos da vantagem mecanica
% -------------------------------------------------------------------------
fig_vantagem = figure(3, 'Name', 'Item 3.1 - Vantagem Mecanica', 'NumberTitle', 'off');
clf(fig_vantagem);

indices_validos = find(isfinite(vantagem_mecanica));
valores_validos = vantagem_mecanica(indices_validos);
[valor_maximo, indice_maximo_local] = max(valores_validos);
[valor_minimo, indice_minimo_local] = min(valores_validos);
indice_maximo = indices_validos(indice_maximo_local);
indice_minimo = indices_validos(indice_minimo_local);
valor_medio = mean(valores_validos);

h_curva = plot(theta2_deg, vantagem_mecanica, 'g-', 'LineWidth', 1.5);
hold on;
h_maximo = plot(theta2_deg(indice_maximo), valor_maximo, 'ro', ...
    'MarkerFaceColor', 'r', 'MarkerSize', 7);
h_minimo = plot(theta2_deg(indice_minimo), valor_minimo, 'bo', ...
    'MarkerFaceColor', 'b', 'MarkerSize', 7);
h_media = plot(theta2_deg, valor_medio * ones(size(theta2_deg)), 'k--', 'LineWidth', 1.2);
text(theta2_deg(indice_maximo), valor_maximo, ...
    sprintf(' Maximo: %.4g', valor_maximo), 'VerticalAlignment', 'bottom');
text(theta2_deg(indice_minimo), valor_minimo, ...
    sprintf(' Minimo: %.4g', valor_minimo), 'VerticalAlignment', 'top');
grid on;
xlim([0, 360]);
title('Item 3.1: Vantagem Mecanica', 'FontSize', 12);
xlabel('{\theta_2} (graus)', 'FontSize', 11);
ylabel('Vantagem Mecanica', 'FontSize', 11);
legend([h_curva, h_maximo, h_minimo, h_media], ...
    'Vantagem mecanica', 'Maximo', 'Minimo', ...
    sprintf('Media: %.4g', valor_medio), 'Location', 'best');

fprintf('Vantagem mecanica maxima: %.6g em theta2 = %.1f graus\n', ...
    valor_maximo, theta2_deg(indice_maximo));
fprintf('Vantagem mecanica minima: %.6g em theta2 = %.1f graus\n', ...
    valor_minimo, theta2_deg(indice_minimo));
fprintf('Vantagem mecanica media (valores finitos): %.6g\n', valor_medio);

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

caminho_imagem_omega = fullfile(assets_dir, 'grafico_3_1_relacoes_omega.png');
print(fig_omega, caminho_imagem_omega, '-dpng', '-r300');
fprintf("Gráficos omega3/omega2 e omega4/omega2 salvos em: %s\n", caminho_imagem_omega);

caminho_imagem_vantagem = fullfile(assets_dir, 'grafico_3_1_vantagem_mecanica.png');
print(fig_vantagem, caminho_imagem_vantagem, '-dpng', '-r300');
fprintf("Gráfico de vantagem mecânica salvo em: %s\n", caminho_imagem_vantagem);

% -------------------------------------------------------------------------
% 7. Manter a janela aberta
% -------------------------------------------------------------------------
fprintf('\n=========================================================================\n');
fprintf('Gráfico 3.1 gerado com sucesso!\n');
fprintf('Pressione <ENTER> no terminal para encerrar o programa e fechar a janela...\n');
fprintf('=========================================================================\n');
pause;
