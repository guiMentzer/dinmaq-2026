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
___ 

A partir daqui já podemos jogar no octave: 

> Dica: você pode escrever a sequência de resolução em um arquivo `.m` para facilitar a correção e troca de valores. Você pode executar pela GUI ou rodar pelo terminal com `octave <caminho/para/seu/arquivo.m>
 
```c
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
```C
# 2. Definição do sistema de equações F(x) = 0                 
# x(1) corresponde a theta3                                    
# x(2) corresponde a theta4                                    
sistema = @(x) [                                               
a * cos(theta2) + b * cos(x(1)) - c * cos(x(2)) - d;       
a * sin(theta2) + b * sin(x(1)) - c * sin(x(2))            
];                                                               
```                            
```c                                                               
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

> Interpretação: Para θ₂ = 45^∘, o torque útil disponível no balancim (T₄) é cerca de 25.5 vezes maior do que o torque aplicado na manivela (T₂).               

---
## Atividade 2 

![[Captura de tela de 2026-09-16 11-50-15.png]]



---
## Atividade 3
![[Captura de tela de 2026-09-16 11-50-44.png]]