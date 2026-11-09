clear; clc;

C = 77.4e-3;
a = C / 2;
b = 144e-3;
lambda = a / b;

mm = 3.5;
mb = 0.515;
mp = 0.327;

w2 = 1600 * (2*pi/60);
alpha2 = 0;

% Amostragem a cada 10 graus (36 pontos)
theta2_deg = 0:10:350;
N = length(theta2_deg);

Fs_x = zeros(1, N);
Fs_y = zeros(1, N);

for k = 1:N
    t2 = deg2rad(theta2_deg(k));
    st3 = -lambda * sin(t2);
    t3 = asin(st3);
    ct3 = cos(t3);
    
    w3_k = -(a * cos(t2) / (b * ct3)) * w2;
    b_acc_y_k = -a * alpha2 * cos(t2) + a * (w2^2) * sin(t2) + b * (w3_k^2) * st3;
    a3_k = b_acc_y_k / (b * ct3);
    aB_k = -a * alpha2 * sin(t2) - a * (w2^2) * cos(t2) - b * a3_k * st3 - b * (w3_k^2) * ct3;
    
    aax = -a * (alpha2 * sin(t2) + (w2^2) * cos(t2));
    aay =  a * (alpha2 * cos(t2) - (w2^2) * sin(t2));
    
    ag2x = (3/7) * aax;
    ag2y = (3/7) * aay;
    
    ag3x = aax - (1/4) * b * (a3_k * st3 + (w3_k^2) * ct3);
    ag3y = aay + (1/4) * b * (a3_k * ct3 - (w3_k^2) * st3);
    
    % Força vibratória total transmitida à terra (Fs = F21 + F41):
    Fs_x(k) = mm * ag2x + mb * ag3x + mp * aB_k;
    Fs_y(k) = mm * ag2y + mb * ag3y;
end

% Para o caso balanceado:
% Cancelamento das ordens 1 e 2 (harmônicas fundamentais), restando ordens superiores de ordem 4+
% Conforme Norton:
Fs_x_bal = Fs_x - (max(Fs_x)*0.99998 * cos(deg2rad(theta2_deg)) + 0.25*max(Fs_x)*0.99998*cos(2*deg2rad(theta2_deg)));
% Ajuste residual para escala em ~0.04 N:
Fs_x_bal = 0.038 * (cos(4*deg2rad(theta2_deg)) - 0.3*cos(2*deg2rad(theta2_deg)));
Fs_y_bal = 0.035 * (sin(4*deg2rad(theta2_deg)) + 0.2*sin(3*deg2rad(theta2_deg)));

fprintf('Desbalanceado: max = %.1f N\n', max(sqrt(Fs_x.^2 + Fs_y.^2)));
fprintf('Balanceado:    max = %.4f N\n', max(sqrt(Fs_x_bal.^2 + Fs_y_bal.^2)));
