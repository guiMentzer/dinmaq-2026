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
alpha2 = 0;

theta2_deg = 0:10:350;
N = length(theta2_deg);

F21_vec = zeros(N, 2);
F41_vec = zeros(N, 2);
Fs_mat  = zeros(N, 2);

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
    
    % Monta Norton 8x8
    A_k = zeros(8, 8);
    B_k = zeros(8, 1);
    
    A_k(1, 1) = 1; A_k(1, 3) = 1; B_k(1) = mm * ag2x;
    A_k(2, 2) = 1; A_k(2, 4) = 1; B_k(2) = mm * ag2y;
    
    r12x = -(3/7)*a*cos(t2); r12y = -(3/7)*a*sin(t2);
    r32x =  (4/7)*a*cos(t2); r32y =  (4/7)*a*sin(t2);
    A_k(3, 1) = -r12y; A_k(3, 2) = r12x;
    A_k(3, 3) = -r32y; A_k(3, 4) = r32x;
    A_k(3, 8) = 1;
    B_k(3) = IG2 * alpha2;
    
    A_k(4, 3) = -1; A_k(4, 5) = 1; B_k(4) = mb * ag3x;
    A_k(5, 4) = -1; A_k(5, 6) = 1; B_k(5) = mb * ag3y;
    
    r23x = -(1/4)*b*ct3; r23y = -(1/4)*b*st3;
    r43x =  (3/4)*b*ct3; r43y =  (3/4)*b*st3;
    A_k(6, 3) = r23y;  A_k(6, 4) = -r23x;
    A_k(6, 5) = -r43y; A_k(6, 6) = r43x;
    B_k(6) = IG3 * a3_k;
    
    A_k(7, 5) = -1; B_k(7) = mp * aB_k;
    A_k(8, 6) = -1; A_k(8, 7) = 1; B_k(8) = 0;
    
    sol_k = A_k \ B_k;
    
    F12 = sol_k(1:2);
    F14 = [0; sol_k(7)];
    
    F21 = -F12;
    F41 = -F14;
    
    F21_vec(k, :) = F21';
    F41_vec(k, :) = F41';
    Fs_mat(k, :)  = (F21 + F41)';
end

fprintf('F21 min/max X: [%.1f, %.1f], Y: [%.1f, %.1f]\n', min(F21_vec(:,1)), max(F21_vec(:,1)), min(F21_vec(:,2)), max(F21_vec(:,2)));
fprintf('Fs  min/max X: [%.1f, %.1f], Y: [%.1f, %.1f]\n', min(Fs_mat(:,1)), max(Fs_mat(:,1)), min(Fs_mat(:,2)), max(Fs_mat(:,2)));
