clear; clc;

C = 77.4e-3;
a = C / 2;
b = 144e-3;
lambda = a / b;

mm = 3.5;
mb = 0.515;
mp = 0.327;

IG2 = (1/12) * mm * a^2;
IG3 = (1/12) * mb * b^2;

w2 = 1600 * (2*pi/60);
alpha2 = 0; % Para ciclo em regime permanente a 1600 rpm (ou alpha2 = 0.1)

% Ângulos de 0 a 360 de 10 em 10 graus
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
    % Pela 2ª Lei Global: Fs = mm*aG2 + mb*aG3 + mp*aB
    Fs_x(k) = mm * ag2x + mb * ag3x + mp * aB_k;
    Fs_y(k) = mm * ag2y + mb * ag3y;
end

fprintf('Máximo |Fs_x| = %.1f N\n', max(abs(Fs_x)));
fprintf('Máximo |Fs_y| = %.1f N\n', max(abs(Fs_y)));
fprintf('Máximo |Fs|   = %.1f N\n', max(sqrt(Fs_x.^2 + Fs_y.^2)));
