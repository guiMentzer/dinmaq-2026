% =========================================================================
% Script de Teste Dinâmico - Solução Norton 8x8 e DCLs
% =========================================================================
clear; clc;

% Parâmetros
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
alpha2 = 0.1;

% Escolha do ângulo representativo da Figura 1 (ex: theta2 = 60 deg)
theta2 = deg2rad(60);

% Cinemática
sin_t3 = -lambda * sin(theta2);
theta3 = asin(sin_t3);
cos_t3 = cos(theta3);

w3 = -(a * cos(theta2) / (b * cos_t3)) * w2;
vB = -a * w2 * sin(theta2) - b * w3 * sin_t3;

b_acc_y = -a * alpha2 * cos(theta2) + a * (w2^2) * sin(theta2) + b * (w3^2) * sin_t3;
alpha3 = b_acc_y / (b * cos_t3);
aB = -a * alpha2 * sin(theta2) - a * (w2^2) * cos(theta2) - b * alpha3 * sin_t3 - b * (w3^2) * cos_t3;

aG2x = -(a/2) * (alpha2 * sin(theta2) + (w2^2) * cos(theta2));
aG2y =  (a/2) * (alpha2 * cos(theta2) - (w2^2) * sin(theta2));

aAx = -a * (alpha2 * sin(theta2) + (w2^2) * cos(theta2));
aAy =  a * (alpha2 * cos(theta2) - (w2^2) * sin(theta2));

aG3x = aAx - (b/2) * (alpha3 * sin_t3 + (w3^2) * cos_t3);
aG3y = aAy + (b/2) * (alpha3 * cos_t3 - (w3^2) * sin_t3);

% Matriz Norton 8x8
% X = [F12x; F12y; F32x; F32y; F43x; F43y; F14y; T12]
A = zeros(8, 8);
B = zeros(8, 1);

% Eq 1 & 2: Elo 2 Forças
A(1, 1) = 1; A(1, 3) = 1; B(1) = mm * aG2x;
A(2, 2) = 1; A(2, 4) = 1; B(2) = mm * aG2y;

% Eq 3: Elo 2 Momento em G2
% R12x*F12y - R12y*F12x + R32x*F32y - R32y*F32x + T12 = IG2*alpha2
R12x = -(a/2)*cos(theta2); R12y = -(a/2)*sin(theta2);
R32x =  (a/2)*cos(theta2); R32y =  (a/2)*sin(theta2);

A(3, 1) = -R12y; A(3, 2) = R12x;
A(3, 3) = -R32y; A(3, 4) = R32x;
A(3, 8) = 1;
B(3) = IG2 * alpha2;

% Eq 4 & 5: Elo 3 Forças (-F32 + F43 = mb*aG3)
A(4, 3) = -1; A(4, 5) = 1; B(4) = mb * aG3x;
A(5, 4) = -1; A(5, 6) = 1; B(5) = mb * aG3y;

% Eq 6: Elo 3 Momento em G3
% (-R23y)*(-F32x) + ... -> R23 x (-F32) + R43 x F43 = IG3*alpha3
R23x = -(b/2)*cos(theta3); R23y = -(b/2)*sin(theta3);
R43x =  (b/2)*cos(theta3); R43y =  (b/2)*sin(theta3);

% R23 x F23 = R23x*(-F32y) - R23y*(-F32x) = -R23x*F32y + R23y*F32x
A(6, 3) = R23y; A(6, 4) = -R23x;
A(6, 5) = -R43y; A(6, 6) = R43x;
B(6) = IG3 * alpha3;

% Eq 7 & 8: Elo 4 Forças (-F43x + Fp = mp*aB, -F43y + F14y = 0)
Fp = 0; % Sem carga externa de gás especificada
A(7, 5) = -1; B(7) = mp * aB - Fp;
A(8, 6) = -1; A(8, 7) = 1; B(8) = 0;

X = A \ B;

fprintf('--- Forças e Torque em theta2 = 60° (1600 rpm) ---\n');
fprintf('F12 = [%.2f, %.2f] N  | |F12| = %.2f N\n', X(1), X(2), norm(X(1:2)));
fprintf('F32 = [%.2f, %.2f] N  | |F32| = %.2f N\n', X(3), X(4), norm(X(3:4)));
fprintf('F43 = [%.2f, %.2f] N  | |F43| = %.2f N\n', X(5), X(6), norm(X(5:6)));
fprintf('F14y = %.2f N\n', X(7));
fprintf('T12  = %.2f N.m\n', X(8));
