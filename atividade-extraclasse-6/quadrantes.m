clear; clc;
C = 77.4e-3; a = C/2; b = 144e-3; lambda = a/b;
mm = 3.5; mb = 0.515; mp = 0.327;
w2 = 1600 * (2*pi/60); alpha2 = 0;
th = 0:10:350;

for k = 1:length(th)
    t2 = deg2rad(th(k));
    st3 = -lambda * sin(t2); ct3 = cos(asin(st3));
    w3 = -(a*cos(t2)/(b*ct3))*w2;
    a3 = (-a*alpha2*cos(t2) + a*w2^2*sin(t2) + b*w3^2*st3)/(b*ct3);
    aB = -a*alpha2*sin(t2) - a*w2^2*cos(t2) - b*a3*st3 - b*w3^2*ct3;
    aa = -a*(alpha2*sin(t2) + w2^2*cos(t2)) + 1i*a*(alpha2*cos(t2) - w2^2*sin(t2));
    ag2 = (3/7)*aa;
    ag3 = aa - (1/4)*b*(a3*st3 + w3^2*ct3) + 1i*(imag(aa) + (1/4)*b*(a3*ct3 - w3^2*st3));
    
    % Fs = mm*ag2 + mb*ag3 + mp*aB
    Fs(k) = mm*ag2 + mb*ag3 + mp*aB;
end

% Check which quadrant Fs is for each theta2
idx_q3 = find(real(Fs) < 0 & imag(Fs) < 0);
fprintf('Theta2 in Quadrant 3: %s\n', mat2str(th(idx_q3)));
