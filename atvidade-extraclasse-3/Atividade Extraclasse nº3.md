# Atividade Extraclasse nº3 
## Guilherme Paiva Crispim Abalém 
### Prof. Sigeo Kitatani


--- 
## Atividade 1 

![[Captura de tela de 2026-09-16 11-49-37.png]]

$$R_2+R_3-R_4-R_1=0$$
$$ae^{j\theta_2}+be^{j\theta_3}-ce^{j\theta_4}-de^{0}=0$$
$$a(\cos{\theta_2}+j\sin{\theta_2})+b(\cos{\theta_3}+j\sin{\theta_3})-c(\cos{\theta_4}+j\sin{\theta_4})-d=0$$
$$\begin{cases}\cos{\theta_2}+b\cos{\theta_3}-c\cos{\theta_4}-d=0 \\a\sin{\theta_2}+b\sin{\theta_3}-c\sin{\theta_4}=0
\end{cases}$$
Temos duas incógnitas: $\theta_3$ e $\theta_4$, para duas equações, então podemos resolver esse sistema!  

A partir daqui já podemos jogar no octave: 

> Dica: você pode escrever a sequência de resolução em um arquivo `.m` para facilitar a correção e troca de valores. Você pode executar pela GUI ou rodar pelo terminal com `octave <caminho/para/seu/arquivo.m>
 
```octave
# 1. Definição dos parâmetros conhecidos 
a = 40.0; % Comprimento do elo 2 (manivela)
b = 208.0; % Comprimento do elo 3 (acoplador)
c = 156.0; % Comprimento do elo 4 (balancim)
d = 200.0; % Comprimento da base (elo 1)
```
```c 
# Ângulo de entrada em radianos (ex: 45  graus)                   
theta2 = deg2rad(45);
```
```octave
# 2. Definição do sistema de equações F(x) = 0                 
# x(1) corresponde a theta3                                    
# x(2) corresponde a theta4                                    
sistema = @(x) [                                               
a * cos(theta2) + b * cos(x(1)) - c * cos(x(2)) - d;       
a * sin(theta2) + b * sin(x(1)) - c * sin(x(2))            
];                                                               
```                            
```octave                                                              
# 3. Chute inicial                       
# Sistemas trigonométricos possuem múltiplas soluções (ex:montage aberta ou cruzada).                                     
# O chute inicial define para qual solução o algoritmo vai convergir.  
x0 = [deg2rad(20); deg2rad(45)];  % Chute inicial em radianos  
                                                                  
# 4. Resolução com fsolve                                      
[x_sol, fval, info] = fsolve(sistema, x0);

# 5. Exibição dos resultados                                   
if info > 0                                                    
fprintf("Solução encontrada com sucesso!\n");              
fprintf("theta3 = %.4f rad (%.2f graus)\n", x_sol(1), rad2deg(x_sol(1)));  fprintf("theta4 = %.4f rad (%.2f graus)\n", x_sol(2), rad2deg(x_sol(2)));  fprintf("Resíduo das equações: [%e, %e]\n", fval(1), fval(2));            
else                                                           
fprintf("Não convergiu para uma solução. Tente outro chute inicial.\n"); 
end             
```
Olha o que `fsolve` faz: Ela serve para resolver um sistema de equações não lineares usando o método de **Newton-Raphson**, que busca raízes do sistema. Por isso `sistema` não precisa de um "igual a zero" e por isso devemos passar um *chute* 

`info`é um valor que indica convergência. `info = 1` Significa que o sistema têm solução. 
No resultado obtive esses valores: 
```bash
Solução encontrada com sucesso!
theta3 = 0.6601 rad (37.82 graus)
theta4 = 1.6183 rad (92.72 graus)
Resíduo das equações: [-5.085654e-07, -2.118593e-07]
```
Posteriormente, gerando um gráfico para todas a possíveis entradas, 

![[grafico_angulos_posicao.png]]


Podemos ver que os ângulos **máximo** e **mínimo** do balancim são 125.36 e 92.60 graus 

#### Vantagem mecânica

A vantagem mecânica é definida como a razão entre o torque de saída e o torque de entrada
$$VM=\dfrac{T_{saída}}{T_{entrada}}=\dfrac{T_4}{T_1}$$
Supondo uma eficiência de $\eta=1$, a potência de entrada é igual à potência de saída
$$P_1=P_4=T_4\omega_4=T_1\omega_1 \implies \dfrac{T_4}{T_1}=\dfrac{\omega_1}{\omega_4} \implies VM=\dfrac{\omega_1}{\omega_2}$$

E resolvendo a diferenciação do loop de vetores, temos 
$$VM=\dfrac{c\sin(\theta_4-\theta_3)}{a\sin(\theta_2-\theta_3}$$
$$VM=25.53$$

> Interpretação: Para θ₂ = 45∘, o torque útil disponível no balancim é cerca de 25.5 vezes maior do que o torque aplicado na manivela.               

---
## Atividade 2 

![[Captura de tela de 2026-09-16 11-50-15.png]]

Como podemos encontrar o baricentro (ou centro de gravidade) G do triangulo ABP de forma útil para o nosso problema? 
$$\vec{G}=\dfrac{\vec{A}+\vec{B}+\vec{P}}{3}$$
Para isso devemos encontrar a posição P
$$\vec{P}=\vec{R_1}+\vec{R_{AP}}$$
$$\vec{P}=ae^{j\theta_2}+pe^{\theta_3+\delta_3}$$
$$\vec{P}=a(\cos\theta_2+j\sin\theta_2)+p(\cos(\theta_3+\delta_3)+j\sin(\theta_3+\delta_3)$$

Conhecemos $\theta_3$, $\theta_2$ e $a$, mas e quanto a $\delta_3$ e $p$? **Suponho** $p=200\,mm$ e $\delta_3=20$ 

```octave                
   % Parâmetros do ponto P no elo acoplador
   p = 180.0;                 % Distância de A até P (mm)
   delta3 = deg2rad(20);      % Ângulo do ponto P relativo à linha AB(20°)
   xP = a * cos(theta2) + p * cos(x_sol(1) + delta3); 
   yP = a * sin(theta2) + p * sin(x_sol(1) + delta3);     
   P  = xP + 1j * yP;
```
Então resolvemos de 0 a 360

```octave
theta2_deg = 0:1:359;
theta2_rad = deg2rad(theta2_deg);
N = length(theta2_rad); % 360 pontos
```
Dessa forma podemos encontrar **todos** os pontos da **trajetória** do pontos A, B e P

```octave
xA = zeros(1, N);
yA = zeros(1, N);
xB = zeros(1, N);
yB = zeros(1, N);
xP = zeros(1, N);
yP = zeros(1, N);

x_atual = x_sol;

for k = 1:N
	t2 = theta2_rad(k);
	sis = @(x) [
		a * cos(t2) + b * cos(x(1)) - c * cos(x(2)) - d;
		a * sin(t2) + b * sin(x(1)) - c * sin(x(2))
	];
	
[x_sol_k, ~, info_k] = fsolve(sis, x_atual, options);

if info_k > 0
	t3_k = x_sol_k(1);
	t4_k = x_sol_k(2);
	% Coordenadas de A
	xA(k) = a * cos(t2);
	yA(k) = a * sin(t2);
	% Coordenadas de B
	xB(k) = d + c * cos(t4_k);
	yB(k) = c * sin(t4_k);
	% Coordenadas de P
	xP(k) = xA(k) + p * cos(t3_k + delta3);
	yP(k) = yA(k) + p * sin(t3_k + delta3);
	% Atualiza chute inicial
	x_atual = x_sol_k;
	else
	warning("Convergência falhou para theta2 = %d°", theta2_deg(k));
	end
end
```

Com isso em mãos, podemos calcular a trajetória do **centro de gravidade G**

$$\vec{G}=\dfrac{\vec{A}+\vec{B}+\vec{P}}{3}$$
```octave 
% Trajetória do Centro de Gravidade G (média vetorial de A, B e P)
xG = (xA + xB + xP) / 3;
yG = (yA + yB + yP) / 3;
G_posicoes = [xG; yG]; % Matriz 2x360
```
![[trajetoria_ponto_G.png]]

Por fim, podemos analisar todas as trajetórias do mecanismo:

![[trajetorias_separadas_ABPG.png]]


---
## Atividade 3

![[Captura de tela de 2026-09-16 11-50-44.png]]


O mecanismo de **seis** barras pode ser quebrado em **dois** laços de vetores, um em **amarelo** 
$$O_2+L_2+L_3-L_4=0$$
$$O_2+L_2e^{j\theta_2}+L_3e^{j\theta_3}-L_4e^{j\theta_4}=0$$

e outro de verde

$$L_4+L_5-O_5=0$$
$$L_4e^{j\theta_4}+L_5e^{j\theta_5}-O_5=0$$
Em forma complexa, temos dois sistemas: 

$$\begin{cases}O_{2x}+L_2\cos{\theta_2}+L_3\cos{\theta_3}-L_4\cos{\theta_4}=0 \\O_{2y}+L_2\sin{\theta_2}+L_3\sin{\theta_3}-L_4\sin{\theta_4}=0
\end{cases}\hspace{3cm}\begin{cases}L_4\cos{\theta_4}+L_5\cos{\theta_5}=0 \\L_4\sin{\theta_4}+L_5\sin{\theta_5}-O_{5y}=0
\end{cases}$$

Analisando a deslocamento do pistão em função do ângulo $\Delta\theta$, chegamos a outra relação: 

$$2L_4=\dfrac{30}{(1-\cos\Delta\theta)}$$
Então podemos escolher $\Delta\theta=25$, o que nos dá $L_4=L_5=160mm$

Encontramos o deslocamento logo em seguida, $$\Delta B=2L_4\sin(\dfrac{\Delta\theta}{2})=69.25m$$
Um mecanismo manivela-balancim para atender a esse deslocamento pode ser suposto, por tentativa e erro usando o *octave*. 

--- 

Códigos disponíveis em https://github.com/guiMentzer/dinmaq-2026.git
Obrigado! 