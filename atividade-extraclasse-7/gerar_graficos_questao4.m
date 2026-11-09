%% Script para geração dos gráficos do Exercício 4
%% Disciplina: Dinâmica das Máquinas - Prof. Sigeo Kitatani Jr.
%% Custo/Mecanismo excêntrico circular com mola Polimold

clear; close all; clc;
graphics_toolkit('qt');

assets_dir = fullfile(fileparts(mfilename('fullpath')), 'assets');
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% -------------------------------------------------------------------------
% 1. DADOS DO PROBLEMA
% -------------------------------------------------------------------------
a_ecc = 30.0 / 1000.0;     % Excentricidade: 30 mm = 0.030 m
m_seg = 20.0 / 1000.0;     % Massa do conjunto seguidor: 20 g = 0.020 kg
N_rpm = 5000.0;            % Rotação de operação: 5.000 RPM
omega = (2 * pi * N_rpm) / 60.0; % rad/s (aprox 523.599 rad/s)

% Rigidez da mola comercial Polimold (especificação do aluno: k = 3.56 N/mm)
% Adotando a mola Polimold V 10-64 ou V 13-102 (k = 3.56 a 4.1 N/mm)
k_mola_N_mm = 3.56;        % N/mm
k_mola = k_mola_N_mm * 1000.0; % N/m = 3560 N/m

% Pré-carga da mola:
% Para garantir contato permanente (sem salto do seguidor) em todo o ciclo:
% A força exercida sobre o seguidor pelo came é F_contato = F_mola - F_inercia >= 0
% No ponto mais crítico (theta = pi, onde F_inercia atinge seu pico positivo de empurrar para longe ou onde a desaceleração tenta separar o seguidor).
% Sendo a aceleração a_seg(theta) = -a_ecc * omega^2 * cos(theta):
% Força inercial d'Alembert: F_in = -m * a_seg = m * a_ecc * omega^2 * cos(theta).
% Equilíbrio de forças no seguidor: F_came - F_mola - m*a_seg = 0 => F_came = F_mola + m*a_seg = F_mola - F_in.
% Para que F_came >= F_min > 0 em qualquer ponto:
% F_mola(theta) = F_pre + k * s(theta)
% No topo (theta = 0), a_seg = -a_ecc*omega^2 (máxima para baixo), o seguidor tende a voar para fora do came!
% A força inercial para cima é m*a_ecc*omega^2 = 0.020 * 0.030 * (523.6)^2 = 164.5 N!
% Logo, na posição theta = 0, para que F_came > 0, F_mola(0) deve ser maior que 164.5 N!
% Com s(0) = 2*a_ecc = 60 mm: F_mola(0) = F_pre + k*(0.060).
% Se F_pre = 20 N (ou pré-compressão delta_0):
delta_pre = 10.0 / 1000.0; % 10 mm de pré-compressão
F_pre = k_mola * delta_pre;

% Vetor angular em radianos [0, 2*pi]
theta_rad = linspace(0, 2*pi, 1000);

% Cinemática do seguidor (s(0) = máximo = 2*a):
% s(theta) = a * (1 + cos(theta))  [m]
% v(theta) = -a * omega * sin(theta) [m/s]
% acc(theta) = -a * omega^2 * cos(theta) [m/s^2]
s_m = a_ecc * (1 + cos(theta_rad));          % m
s_mm = s_m * 1000.0;                         % mm
v_ms = -a_ecc * omega * sin(theta_rad);      % m/s
acc_ms2 = -a_ecc * (omega^2) * cos(theta_rad); % m/s^2

% -------------------------------------------------------------------------
% 2. FORÇAS ATUANTES (em Newtons)
% -------------------------------------------------------------------------
% Força de inércia do seguidor (D'Alembert):
% F_in = -m * acc = m * a * omega^2 * cos(theta)
F_inercial = -m_seg * acc_ms2; 

% Força restauradora da mola:
% F_mola = F_pre + k * s(theta)
F_mola = F_pre + k_mola * s_m;

% Força de contato normal Came-Seguidor (F_came):
% Do equilíbrio: F_came - F_mola - m*acc = 0  =>  F_came = F_mola + m*acc = F_mola - F_inercial
% Ou soma direta mola + inercial conforme solicitado
F_soma_contato = F_mola - F_inercial;

% -------------------------------------------------------------------------
% 3. GRÁFICO 1: CINEMÁTICA (s, v, a) COM ABSCISSA EM RADIANOS
% -------------------------------------------------------------------------
fig1 = figure('visible', 'off', 'position', [100, 100, 900, 750]);

subplot(3, 1, 1);
plot(theta_rad, s_mm, 'b-', 'LineWidth', 2.0);
grid on; box on;
xlim([0, 2*pi]);
set(gca, 'XTick', [0, pi/2, pi, 3*pi/2, 2*pi], ...
         'XTickLabel', {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'}, 'FontSize', 10);
ylabel('s(\theta) [mm]', 'FontSize', 11, 'FontWeight', 'bold');
title('Cinemática do Came Excêntrico Circular (a = 30 mm)', 'FontSize', 12, 'FontWeight', 'bold');

subplot(3, 1, 2);
plot(theta_rad, v_ms, 'Color', [0.0, 0.5, 0.2], 'LineWidth', 2.0);
grid on; box on;
xlim([0, 2*pi]);
set(gca, 'XTick', [0, pi/2, pi, 3*pi/2, 2*pi], ...
         'XTickLabel', {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'}, 'FontSize', 10);
ylabel('v(\theta) [m/s]', 'FontSize', 11, 'FontWeight', 'bold');

subplot(3, 1, 3);
plot(theta_rad, acc_ms2, 'r-', 'LineWidth', 2.0);
grid on; box on;
xlim([0, 2*pi]);
set(gca, 'XTick', [0, pi/2, pi, 3*pi/2, 2*pi], ...
         'XTickLabel', {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'}, 'FontSize', 10);
xlabel('\theta [rad]', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('a(\theta) [m/s^2]', 'FontSize', 11, 'FontWeight', 'bold');

print(fig1, fullfile(assets_dir, 'grafico_q4_cinematica_rad.png'), '-dpng', '-r300');

% -------------------------------------------------------------------------
% 4. GRÁFICO 2: FORÇA INERCIAL (5000 RPM)
% -------------------------------------------------------------------------
fig2 = figure('visible', 'off', 'position', [100, 100, 850, 450]);
plot(theta_rad, F_inercial, 'r-', 'LineWidth', 2.2);
grid on; box on;
xlim([0, 2*pi]);
set(gca, 'XTick', [0, pi/2, pi, 3*pi/2, 2*pi], ...
         'XTickLabel', {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'}, 'FontSize', 11);
xlabel('\theta [rad]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Força Inercial F_{in} [N]', 'FontSize', 12, 'FontWeight', 'bold');
title('Força Inercial no Centro de Massa do Seguidor a 5.000 RPM (m = 20 g)', 'FontSize', 13, 'FontWeight', 'bold');

print(fig2, fullfile(assets_dir, 'grafico_q4_forca_inercial.png'), '-dpng', '-r300');

% -------------------------------------------------------------------------
% 5. GRÁFICO 3: COMPARATIVO DINÂMICO (FORÇA DA MOLA, INERCIAL E CONTATO)
% -------------------------------------------------------------------------
fig3 = figure('visible', 'off', 'position', [100, 100, 900, 500]);
hold on; box on; grid on;

plot(theta_rad, F_inercial, 'Color', [0.85, 0.15, 0.1], 'LineWidth', 2.0, ...
     'DisplayName', 'Força Inercial: F_{in} = -m \cdot a(\theta)');
plot(theta_rad, F_mola, 'Color', [0.0, 0.45, 0.85], 'LineWidth', 2.0, 'LineStyle', '--', ...
     'DisplayName', sprintf('Força da Mola: F_{mola} (k = %.2f N/mm)', k_mola_N_mm));
plot(theta_rad, F_soma_contato, 'Color', [0.1, 0.7, 0.2], 'LineWidth', 2.4, ...
     'DisplayName', 'Força Resultante no Came: F_{came} = F_{mola} - F_{in}');

xlim([0, 2*pi]);
set(gca, 'XTick', [0, pi/2, pi, 3*pi/2, 2*pi], ...
         'XTickLabel', {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'}, 'FontSize', 11);
xlabel('\theta [rad]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Força [N]', 'FontSize', 12, 'FontWeight', 'bold');
title('Equilíbrio Dinâmico no Seguidor: Força Inercial, Mola e Contato (5.000 RPM)', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 10.5);

print(fig3, fullfile(assets_dir, 'grafico_q4_comparativo_forcas.png'), '-dpng', '-r300');

fprintf('Gráficos do Exercício 4 gerados com sucesso em assets/!\n');
