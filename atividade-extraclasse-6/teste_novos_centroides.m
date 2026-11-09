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
alpha2 = 0.1;
theta2 = deg2rad(60);

sin_t3 = -lambda * sin(theta2);
theta3 = asin(sin_t3);
cos_t3 = cos(theta3);

w3 = -(a * cos(theta2) / (b * cos_t3)) * w2;
vB = -a * w2 * sin(theta2) - b * w3 * sin_t3;

b_acc_y = -a * alpha2 * cos(theta2) + a * (w2^2) * sin(theta2) + b * (w3^2) * sin_t3;
alpha3 = b_acc_y / (b * cos_t3);
aB = -a * alpha2 * sin(theta2) - a * (w2^2) * cos(theta2) - b * alpha3 * sin_t3 - b * (w3^2) * cos_t3;

% Pontos
O2 = [0, 0];
A  = [a * cos(theta2), a * sin(theta2)];
B  = [A(1) + b * cos(theta3), 0];

% NOVAS POSIÇÕES DOS CENTRÓIDES:
% Manivela: r_G2 = (3/7) * a
G2 = (3/7) * A;
R12 = O2 - G2;      % - (3/7) * A
R32 = A - G2;       % + (4/7) * A

% Biela: r_G3 = A + (1/4) * (B - A)
G3 = A + (1/4) * (B - A);
R23 = A - G3;       % - (1/4) * (B - A)
R43 = B - G3;       % + (3/4) * (B - A)

% Acelerações com novos centróides:
aAx = -a * (alpha2 * sin(theta2) + (w2^2) * cos(theta2));
aAy =  a * (alpha2 * cos(theta2) - (w2^2) * sin(theta2));

aG2x = (3/7) * aAx;
aG2y = (3/7) * aAy;

aG3x = aAx - (1/4) * b * (alpha3 * sin_t3 + (w3^2) * cos_t3);
aG3y = aAy + (1/4) * b * (alpha3 * cos_t3 - (w3^2) * sin_t3);

% Matriz Norton 8x8
A_mat = zeros(8, 8);
B_vec = zeros(8, 1);

% Elo 2
A_mat(1, 1) = 1; A_mat(1, 3) = 1; B_vec(1) = mm * aG2x;
A_mat(2, 2) = 1; A_mat(2, 4) = 1; B_vec(2) = mm * aG2y;

A_mat(3, 1) = -R12(2); A_mat(3, 2) = R12(1);
A_mat(3, 3) = -R32(2); A_mat(3, 4) = R32(1);
A_mat(3, 8) = 1;
B_vec(3) = IG2 * alpha2;

% Elo 3
A_mat(4, 3) = -1; A_mat(4, 5) = 1; B_vec(4) = mb * aG3x;
A_mat(5, 4) = -1; A_mat(5, 6) = 1; B_vec(5) = mb * aG3y;

A_mat(6, 3) = R23(2);  A_mat(6, 4) = -R23(1);
A_mat(6, 5) = -R43(2); A_mat(6, 6) = R43(1);
B_vec(6) = IG3 * alpha3;

% Elo 4
A_mat(7, 5) = -1; B_vec(7) = mp * aB;
A_mat(8, 6) = -1; A_mat(8, 7) = 1; B_vec(8) = 0;

sol = A_mat \ B_vec;

F12 = sol(1:2);
F32 = sol(3:4);
F23 = -F32;
F43 = sol(5:6);
F34 = -F43;
F14 = [0; sol(7)];
T12 = sol(8);

Fin2 = -mm * [aG2x; aG2y];
Fin3 = -mb * [aG3x; aG3y];
Fin4 = -mp * [aB; 0];
Tin3 = -IG3 * alpha3;

fprintf('--- NOVOS RESULTADOS DINÂMICOS COM G2(3/7) e G3(1/4) ---\n');
fprintf('F12 = [%.2f, %.2f] N  | |F12| = %.2f N\n', F12(1), F12(2), norm(F12));
fprintf('F32 = [%.2f, %.2f] N  | |F32| = %.2f N\n', F32(1), F32(2), norm(F32));
fprintf('F23 = [%.2f, %.2f] N  | |F23| = %.2f N\n', F23(1), F23(2), norm(F23));
fprintf('F43 = [%.2f, %.2f] N  | |F43| = %.2f N\n', F43(1), F43(2), norm(F43));
fprintf('F34 = [%.2f, %.2f] N  | |F34| = %.2f N\n', F34(1), F34(2), norm(F34));
fprintf('F14 = [%.2f, %.2f] N\n', F14(1), F14(2));
fprintf('T12 = %.2f N.m\n', T12);
fprintf('Fin2 = [%.2f, %.2f] N\n', Fin2(1), Fin2(2));
fprintf('Fin3 = [%.2f, %.2f] N\n', Fin3(1), Fin3(2));
fprintf('Fin4 = [%.2f, %.2f] N\n', Fin4(1), Fin4(2));
fprintf('Tin3 = %.2f N.m\n', Tin3);
