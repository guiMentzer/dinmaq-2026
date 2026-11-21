# Relatório de Materiais, Custo e Fabricação — Prensas Knuckle-Joint de Baru (Vertentes A e B)

**Disciplina:** Dinâmica das Máquinas — EMC/UFG  
**Docente:** Prof. Dr. Sigeo Kitatani Jr.  
**Discente:** Guilherme Paiva Crispim Abalém  
**Projeto / Interface:** Centro de Inovação Social do Brasil Central (**CIS-bc/UFG**) — Processamento Mínimo do Endocarpo de Baru  
**Data-Base de Orçamentação:** Novembro/2026 (mercado brasileiro varejo/MRO e distribuidores regionais Centro-Oeste/GO, em **R$ — BRL**)

**Artefatos CAD e Dinâmicos de Referência:**
* **Vertente A (Manual — Ciência Aberta):** [prensa_baru_manual_v1.FCStd](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/prensa_baru_manual_v1.FCStd) | [prensa_baru_manual_v1.step](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/prensa_baru_manual_v1.step) | [gerar_prensa_baru_manual_cad.py](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/gerar_prensa_baru_manual_cad.py) | [propriedades_inerciais_freecad_manual_v1.json](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/propriedades_inerciais_freecad_manual_v1.json)
* **Vertente B (Motorizada 20 RPM — Item 9):** [prensa_baru_motorizada_v1.FCStd](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/prensa_baru_motorizada_v1.FCStd) | [prensa_baru_motorizada_v1.step](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/prensa_baru_motorizada_v1.step) | [gerar_prensa_baru_motorizada_cad.py](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/gerar_prensa_baru_motorizada_cad.py) | [propriedades_inerciais_freecad_motorizada_v1.json](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/propriedades_inerciais_freecad_motorizada_v1.json)
* **Memória de Inércias e Dinâmica de d'Alembert:** [Propriedades_Inerciais_e_Dinamicas_Prensa_Manual_v1.md](file:///home/guimentzer/vault/Din%C3%A2mica%20das%20M%C3%A1quinas/Trabalho%20Final%201/Propriedades_Inerciais_e_Dinamicas_Prensa_Manual_v1.md) | **Cartões `.FCMat`:** [materiais_freecad/](file:///home/guimentzer/Repos/dinmaq-2026/trabalho-final/materiais_freecad)

---

## 1. Síntese Executiva e Comparativo Técnico-Econômico (Vertente A vs. Vertente B)

Ambas as máquinas compartilham o **mesmo núcleo de saída knuckle-joint de alta eficiência** ($L_4 = L_5 = 111{,}96\text{ mm}$, curso útil $h = 30{,}00\text{ mm}$, força de cisalhamento $F_{\max} = 5{,}0\text{ kN}$, corte raso calibrado em **$4{,}75\text{ mm} \le 5{,}00\text{ mm}$** sobre baru $30\times 50\times 40\text{ mm}$, berço em cantoneira comercial V $90^\circ$, guia linear em chapa U com tiras substituíveis de UHMW, navalha de aço-mola SAE 5160, moega lateral `#18`, calha de descarga e coletor frontal removível de $12{,}3\text{ L}$). A divergência construtiva e econômica decorre diretamente da matriz de requisitos da **Tabela 1** de [instruções.pdf](file:///home/guimentzer/vault/Din%C3%A2mica%20das%20M%C3%A1quinas/Trabalho%20Final%201/instru%C3%A7%C3%B5es.pdf):

| Critério Técnico-Econômico | Vertente A — Prensa Manual (`prensa_baru_manual_v1`) | Vertente B — Prensa Motorizada (`prensa_baru_motorizada_v1`) |
| :--- | :--- | :--- |
| **Público-Alvo (`Tabela 1`)** | Agricultura familiar / extrativistas (Ciência Aberta) | Cooperativas e agroindústrias locais (escala semi-industrial) |
| **Regime Nominal e Produção** | Manual ($20\text{ frutos/min}$, $4\text{ h/dia}$ = **$4.800\text{ frutos/dia}$**) | Contínuo $20\text{ rpm}$ ($20\text{ frutos/min}$, $8\text{ h/dia}$ = **$9.600\text{ frutos/dia}$**) *(escalável até $50\text{ rpm}$)* |
| **Acionamento e Extração** | Alavanca em L ($R_{\text{ponta}} = 600\text{ mm}$) + pedal de piso $+X$ | Motor WEG $0{,}5\text{ cv}$ + correia A-56 + volante $400\text{ rpm}$ + redutor $20:1$ + came 3-4-5 |
| **Objetos / Sólidos CAD (excluindo fruto)** | **$45$ objetos `Part::Feature`** ($7$ `App::Part`) | **$54$ objetos `Part::Feature`** ($9$ `App::Part`) |
| **Massa Total Líquida (OCCT / `.FCMat`)** | **$35{,}1726\text{ kg}$** ($4.718{,}07\text{ cm}^3$) | **$98{,}5209\text{ kg}$** ($13.177{,}69\text{ cm}^3$) |
| **Envelope Estrutural no Piso (c/ sapatas)** | $430 \times 320 \times 1498{,}7\text{ mm}$ *(+ pedal $+X$)* | $525 \times 630 \times 1498{,}7\text{ mm}$ *(bandeja NR-12 fechada)* |
| **Infraestrutura Mínima de Fabricação** | **Serralheria rural básica** + furadeira de bancada + torno simples (canaletas O-ring) | **Oficina mecânica + caldeiraria** + torno + fresa/CNC (perfil came 3-4-5) + balanceamento + elétrica NR-12 |
| **Custo de Materiais + Comerciais (Protótipo 1x)** | **R$ 1.305 – R$ 2.000** | **R$ 3.870 – R$ 8.000** *(conforme redutor sem-fim vs. helicoidal)* |
| **Mão de Obra Terceirizada Estimada (1x)** | **R$ 980 – R$ 1.600** *(14–18 h)* | **R$ 2.100 – R$ 3.200** *(26–34 h)* |
| **CAPEX Total Unitário (Protótipo 1x)** | **R$ 2.285 – R$ 3.600** | **R$ 5.970 – R$ 11.200** *(típico industrial: ~R$ 8.500)* |
| **CAPEX Unitário em Lote Piloto (10 un.)** | **R$ 1.415 – R$ 2.277** *(rateio de barras 6 m/chapas + gabarito)* | **R$ 4.553 – R$ 8.757** *(rateio de chapas/tarugos + CNC em lote)* |

> [!TIP] Conclusão Estratégica de Custo-Benefício
> A **Vertente A** apresenta CAPEX **$2{,}6\times\text{ a }3{,}8\times$ menor** que a Vertente B e dispensa energia elétrica trifásica/monofásica, redutor, motor e usinagem CNC de came — podendo ser fabricada em qualquer serralheria do Cerrado por cerca de **R$ 1.400–2.300/unidade** em compras conjuntas de cooperativa (lote de 10 unidades). A **Vertente B** justifica seu investimento adicional (**~R$ 6.000–9.000**) quando há operação contínua de **$8\text{ h/dia}$** sem fadiga muscular do operador (substituição integral do esforço repetitivo manual e do pedal), recuperando a diferença de CAPEX via ganho de jornada diária dobrada ($9.600$ frutos/dia) e automação da extração.

---

## 2. Seleção de Materiais de Engenharia e Balanço Mássico (OCCT + `.FCMat`)

Todos os corpos sólidos de ambos os projetos possuem atribuição nativa `ShapeMaterial` no FreeCAD (`materiais_freecad/*.FCMat`), integrando propriedades elásticas (`LinearElastic`) e renderização (`BasicRendering`). A escolha dos **8 materiais de engenharia** foi orientada por disponibilidade em distribuidoras brasileiras, soldabilidade, vida em desgaste por abrasão do endocarpo lenhoso e ausência de contaminação alimentar por graxa na zona de corte.

### 2.1. Matriz de Propriedades Mecânicas e Justificativa de Seleção

| Cartão `.FCMat` | $\rho$ ($\text{kg/m}^3$) | $E$ ($\text{GPa}$) | $S_y$ ($\text{MPa}$) | $S_{ut}$ ($\text{MPa}$) | Justificativa de Engenharia e Alternativa Evitada |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`Aco_ABNT_1020`** | $7850$ | $205$ | $250$ | $420$ | Alta soldabilidade sem pré-aquecimento, custo mínimo e estoque universal em barras chatas, cantoneiras, Metalon NBR 6591/8261 e chapas `#18`/`#16`/`1/4"`. Na motorizada, também compõe `Volante_Inercia_Aco` ($14{,}17\text{ kg}$). |
| **`Aco_SAE_1045`** | $7850$ | $210$ | $450$ | $620$ | Resistência elevada ao escoamento e ao cisalhamento para o elo mais carregado ($L_4$ sob $5{,}0\text{ kN}$), êmbolo $1''\times 1''$, eixos $\varnothing 20\text{ mm}$ ($O_2$ e $400\text{ rpm}$ com $FS_{\text{torção}} = 7{,}38$), pinos retificados $\varnothing 12\text{ mm}$, `Came_Extrator_O2` e parafusos Classe 8.8. |
| **`Aco_Mola_SAE_5160`** | $7850$ | $210$ | $1100$ | $1400$ | Tenacidade superior ao impacto repetitivo sobre o endocarpo lenhoso com têmpera em óleo + revenimento duplo para **$54\text{–}58\text{ HRC}$** (realizável em oficina básica). **Evitado AISI D2** por fragilidade de gume, alto custo e tratamento térmico complexo. Também empregado na `Mola_Retorno`. |
| **`Ferro_Fundido_GG20`** | $7200$ | $105$ | $180$ | $220$ | Material padrão dos componentes **OEM comerciais** da Vertente B: carcaça do motor WEG IEC 71, carcaça do redutor $20:1$, polias perfil A ($\varnothing 75/\varnothing 325\text{ mm}$) e mancais `UCP204`/`F204`, oferecendo alto amortecimento interno de vibrações. |
| **`Bronze_TM23_SAE_660`** | $8930$ | $100$ | $140$ | $240$ | Buchas cilíndricas padronizadas de catálogo (`Ø12×Ø14` e `Ø20×Ø23`) com excelente conformabilidade e resistência a choque estático de $5\text{ kN}$. **Evitados rolamentos 608/6200** nos elos do mecanismo por menor capacidade de carga estática e maior volume de cubo. |
| **`UHMW_PE`** | $935$ | $0{,}75$ | $22$ | $40$ | Tiras planas substituíveis da guia linear: autolubrificante ($\mu \approx 0{,}10$), imune a poeira/óleo do baru e isento de graxa na zona do fruto; pressão de contato máxima de $1{,}9\text{–}6{,}6\text{ MPa} \ll 22\text{ MPa}$. **Evitadas buchas de esferas `LM16UU`** por travamento com resíduos vegetais e *brinelling* sob choque. |
| **`Policarbonato_NR12`** | $1200$ | $2{,}35$ | $60$ | $65$ | Visor frontal transparente inquebrável para inspeção visual segura da lâmina sem abertura da carenagem (atende **NR-12**). **Evitado acrílico (PMMA)** por estilhaçamento frágil em caso de projeção de casca. |
| **`Borracha_NBR_70`** | $1200$ | $0{,}010$ | $12$ | $18$ | Resistência a óleos vegetais e graxas: anéis de retenção O-ring ($10\times 1{,}8\text{ mm}$), manopla ergonômica, correia trapezoidal **A-56** e $4\times$ coxins antivibratórios de piso. |

### 2.2. Distribuição Mássica Exata por Material (Integrada no OpenCascade)

| Material (`ShapeMaterial`) | Manual — Qtd. Objetos | Manual — Massa ($\text{kg}$) | Manual — Fração (%) | Motorizada — Qtd. Objetos | Motorizada — Massa ($\text{kg}$) | Motorizada — Fração (%) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **`Aco_ABNT_1020`** | $19$ | $31{,}0070$ | $88{,}16\%$ | $19$ | $64{,}9134$ | $65{,}89\%$ |
| **`Ferro_Fundido_GG20`** | $0$ | $0{,}0000$ | $0{,}00\%$ | $5$ | $28{,}7368$ | $29{,}17\%$ |
| **`Aco_SAE_1045`** | $11$ | $3{,}7209$ | $10{,}58\%$ | $15$ | $4{,}3775$ | $4{,}44\%$ |
| **`Borracha_NBR_70`** | $5$ | $0{,}1167$ | $0{,}33\%$ | $5$ | $0{,}1687$ | $0{,}17\%$ |
| **`Policarbonato_NR12`** | $1$ | $0{,}1197$ | $0{,}34\%$ | $1$ | $0{,}1515$ | $0{,}15\%$ |
| **`UHMW_PE`** | $1$ | $0{,}0757$ | $0{,}22\%$ | $1$ | $0{,}0757$ | $0{,}08\%$ |
| **`Aco_Mola_SAE_5160`** | $2$ | $0{,}0863$ | $0{,}25\%$ | $2$ | $0{,}0579$ | $0{,}06\%$ |
| **`Bronze_TM23_SAE_660`** | $6$ | $0{,}0462$ | $0{,}13\%$ | $6$ | $0{,}0394$ | $0{,}04\%$ |
| **TOTAL MÁQUINA** | **$45$** | **$35{,}1726\text{ kg}$** | **$100{,}00\%$** | **$54$** | **$98{,}5209\text{ kg}$** | **$100{,}00\%$** |

*(Nota: ambos os arquivos CAD também contêm o corpo de prova visual `Baru_Simulado_30x50x40` em `Endocarpo_Baru_Simulado`, $\rho = 1100\text{ kg/m}^3$, $31{,}40\text{ cm}^3$, $0{,}0345\text{ kg}$, excluído da BOM industrial.)*

---

## 3. Lista de Materiais (BOM) e Orçamento — Vertente A (Prensa Manual `prensa_baru_manual_v1`)

### 3.1. Inventário Técnico Completo por Subsistema (45 Peças CAD)

<details>
<summary>Tabela técnica completa das 45 peças da Vertente A (Subsistema, Material, Sólidos, Volume e Massa OCCT)</summary>

| Subsistema (`App::Part`) | Objeto FreeCAD | Descrição e Perfil Comercial | Material | Sólidos | Vol. ($\text{cm}^3$) | Massa ($\text{kg}$) |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **`Sub01_Estator`** | `Chapa_Base_Estrutural` | Chapa de mesa $1/4''$ ($340\times 100\times 6{,}35\text{ mm}$) | `ABNT 1020` | 1 | $191{,}52$ | $1{,}5034$ |
| `Sub01_Estator` | `Portico_Estrutural_Traseiro` | Barra chata $2''\times 1/4''$ soldada (4 furos M8 guia U) | `ABNT 1020` | 1 | $475{,}94$ | $3{,}7361$ |
| `Sub01_Estator` | `Portico_Estrutural_Frontal` | Barra chata $2''\times 1/4''$ soldada | `ABNT 1020` | 1 | $405{,}07$ | $3{,}1798$ |
| `Sub01_Estator` | `Espacadores_Transversais_Portico` | $4\times$ espaçadores tubulares + parafusos M10 Cl. 8.8 | `SAE 1045` | 8 | $98{,}15$ | $0{,}7705$ |
| `Sub01_Estator` | `Batentes_Pinos_Soldados_PMS_PMI` | $2\times$ pinos batentes $\varnothing 10\text{ mm}$ c/ luva NBR ($20^\circ/80^\circ$) | `ABNT 1020` | 4 | $2{,}73$ | $0{,}0214$ |
| `Sub01_Estator` | `Suporte_Baru_Cantoneira` | Cantoneira comercial $1.1/2''\times 3/16''$ (V $90^\circ$) + pés dobrados | `ABNT 1020` | 1 | $27{,}23$ | $0{,}2138$ |
| `Sub01_Estator` | `Guia_Pistao_Chapa_U` | Guia em chapa dobrada em U ($3{,}0\text{ mm}$, parafusável 4x M8) | `ABNT 1020` | 3 | $55{,}88$ | $0{,}4386$ |
| `Sub01_Estator` | `Parafusos_Guia_Pistao_M8` | $4\times$ parafusos sextavados M8$\times$20 Cl. 8.8 + porcas | `SAE 1045` | 4 | $7{,}08$ | $0{,}0556$ |
| `Sub01_Estator` | `Tiras_Desgaste_UHMW_5mm` | $4\times$ tiras planas retas substituíveis de UHMW ($5{,}0\text{ mm}$) | `UHMW_PE` | 4 | $80{,}97$ | $0{,}0757$ |
| `Sub01_Estator` | `Buchas_Catalogo_Estator` | $4\times$ buchas de catálogo: $O_4$ ($12\times 14$) e $O_2$ ($20\times 23$) | `Bronze TM23` | 4 | $1{,}78$ | $0{,}0159$ |
| `Sub01_Estator` | `Pino_Eixo_O4` | Pino liso comercial $\varnothing 12\text{ mm}$ c/ canaletas O-ring ($O_4$) | `SAE 1045` | 3 | $9{,}49$ | $0{,}0745$ |
| `Sub01_Estator` | `Aneis_Retencao_ORing_O4` | $2\times$ anéis O-ring NBR 70 ($10\times 1{,}8\text{ mm}$) | `NBR 70` | 2 | $0{,}20$ | $0{,}0002$ |
| **`Corpo2_O2`** | `Conjunto_Soldado_L2_Alavanca_O2` | Eixo $\varnothing 20$ soldado ao braço $L_2$ + tubo $\varnothing 1.1/4''\times 2{,}0$ ($R=600$) | `SAE 1045` | 3 | $161{,}45$ | $1{,}2674$ |
| `Corpo2_O2` | `Buchas_Catalogo_A` | $1\times$ bucha catálogo $12\times 14\text{ mm}$ da junta $A$ | `Bronze TM23` | 1 | $0{,}38$ | $0{,}0034$ |
| `Corpo2_O2` | `Manopla_Empunhadura_Borracha` | Manopla ergonômica NBR ($\varnothing 32\times 120\text{ mm}$) | `NBR 70` | 1 | $96{,}43$ | $0{,}1157$ |
| `Corpo2_O2` | `Pino_Eixo_A` | Pino liso $\varnothing 12\text{ mm}$ c/ canaletas O-ring e arruelas DIN 125 | `SAE 1045` | 4 | $2{,}83$ | $0{,}0222$ |
| `Corpo2_O2` | `Aneis_Retencao_ORing_A` | $2\times$ anéis O-ring NBR 70 ($10\times 1{,}8\text{ mm}$) | `NBR 70` | 2 | $0{,}20$ | $0{,}0002$ |
| **`Corpo3_L3`** | `Elo3_Biela_L3` | Biela $L_3 = 100{,}00\text{ mm}$ em barra chata $1''\times 1/4''$ | `ABNT 1020` | 1 | $17{,}38$ | $0{,}1364$ |
| `Corpo3_L3` | `Buchas_Catalogo_L3` | $2\times$ buchas catálogo $12\times 14\text{ mm}$ | `Bronze TM23` | 2 | $0{,}50$ | $0{,}0045$ |
| **`Corpo4_L4`** | `Elo4_Balancim_L4` | Balancim $L_4 = 111{,}96\text{ mm}$ em barra chata $1.1/2''\times 1/2''$ | `SAE 1045` | 1 | $64{,}72$ | $0{,}5081$ |
| `Corpo4_L4` | `Buchas_Catalogo_L4` | $2\times$ buchas catálogo $12\times 14\text{ mm}$ | `Bronze TM23` | 2 | $1{,}01$ | $0{,}0090$ |
| **`Corpo5_L5`** | `Elo5_Garfo_Duplo_L5` | Garfo duplo $L_5 = 111{,}96\text{ mm}$ ($2\times$ barra $1.1/4''\times 1/4''$) | `ABNT 1020` | 2 | $51{,}27$ | $0{,}4025$ |
| `Corpo5_L5` | `Buchas_Catalogo_L5` | $4\times$ buchas catálogo $12\times 14\text{ mm}$ | `Bronze TM23` | 4 | $1{,}00$ | $0{,}0089$ |
| `Corpo5_L5` | `Pino_Eixo_B` | Pino liso $\varnothing 12\text{ mm}$ c/ canaletas O-ring e arruelas DIN 125 | `SAE 1045` | 6 | $5{,}92$ | $0{,}0464$ |
| `Corpo5_L5` | `Aneis_Retencao_ORing_B` | $2\times$ anéis O-ring NBR 70 ($10\times 1{,}8\text{ mm}$) | `NBR 70` | 2 | $0{,}20$ | $0{,}0002$ |
| **`Corpo6_O5`** | `Pistao_Embolo_Quadrado` | Êmbolo barra quadrada $1''\times 1''$ + chapa encosto e orelha $O_5$ | `SAE 1045` | 1 | $106{,}38$ | $0{,}8351$ |
| `Corpo6_O5` | `Navalha_Corte_SAE5160` | Navalha reta cunha $30^\circ$ ($50\times 26\times 6{,}35\text{ mm}$) | `SAE 5160` | 1 | $6{,}26$ | $0{,}0492$ |
| `Corpo6_O5` | `Parafusos_Fixacao_Navalha_M6` | $2\times$ parafusos sextavados M6$\times$20 Cl. 8.8 + porcas | `SAE 1045` | 2 | $1{,}88$ | $0{,}0148$ |
| `Corpo6_O5` | `Bucha_Catalogo_O5` | $1\times$ bucha catálogo $12\times 14\text{ mm}$ do olhal $O_5$ | `Bronze TM23` | 1 | $0{,}51$ | $0{,}0045$ |
| `Corpo6_O5` | `Pino_Eixo_O5` | Pino liso $\varnothing 12\text{ mm}$ c/ canaletas O-ring e arruelas DIN 125 | `SAE 1045` | 5 | $4{,}97$ | $0{,}0390$ |
| `Corpo6_O5` | `Aneis_Retencao_ORing_O5` | $2\times$ anéis O-ring NBR 70 ($10\times 1{,}8\text{ mm}$) | `NBR 70` | 2 | $0{,}20$ | $0{,}0002$ |
| **`Sub07_Cavalete_Gabinete`** | `Quadro_Tubular_Metalon_20x20` | Cavalete $1{,}50\text{ m}$ + gabinete NR-12 (Metalon $20\times 20\times 1{,}50\text{ mm}$) | `ABNT 1020` | 3 | $1422{,}77$ | $11{,}1687$ |
| `Sub07` | `Sapatas_Ancoragem_Piso` | $4\times$ sapatas $70\times 70\times 4{,}76\text{ mm}$ ($8$ furos $\varnothing 10{,}5\text{ mm}$) | `ABNT 1020` | 4 | $90{,}00$ | $0{,}7065$ |
| `Sub07` | `Carenagem_Chapa_Galvanizada` | Fechamento superior NR-12 em chapa `#18` ($1{,}20\text{ mm}$) | `ABNT 1020` | 6 | $461{,}30$ | $3{,}6212$ |
| `Sub07` | `Visor_Policarbonato_NR12` | Visor transparente frontal NR-12 (placa $2{,}0\text{ mm}$; $1{,}2\text{ mm}$ CAD) | `PC NR12` | 1 | $99{,}77$ | $0{,}1197$ |
| `Sub07` | `Calha_Alimentacao_Segura_NR12` | Calha lateral segura $42\times 48\text{ mm}$ (parede $1{,}50\text{ mm}$ `#16`) | `ABNT 1020` | 1 | $60{,}48$ | $0{,}4747$ |
| `Sub07` | `Reservatorio_Alimentacao_Chapa` | Moega dedicada parafusada ($4\times$ M6) em chapa dobrada `#18` | `ABNT 1020` | 1 | $156{,}20$ | $1{,}2262$ |
| `Sub07` | `Parafusos_Fixacao_Gabinete_M6` | Parafusos M6/M8 + porcas do visor, carenagem, calha e moega | `SAE 1045` | 20 | $11{,}13$ | $0{,}0874$ |
| `Sub07` | `Calha_Descarga_Chapa` | Calha inclinada sob a mesa em chapa dobrada `#18` | `ABNT 1020` | 1 | $52{,}41$ | $0{,}4114$ |
| `Sub07` | `Reservatorio_Chapa_Coleta` | Reservatório frontal removível $12{,}3\text{ L}$ em chapa dobrada `#18` | `ABNT 1020` | 1 | $327{,}01$ | $2{,}5670$ |
| `Sub07` | `Suporte_Eixo_Ejetor_NR12` | Mancais + eixo $\varnothing 8\text{ mm}$ da alavanca ejetora ($O_{\text{ext}}$) | `ABNT 1020` | 1 | $3{,}79$ | $0{,}0298$ |
| `Sub07` | `Mola_Retorno_Pedal` | Mola helicoidal de tração p/ retorno do pedal | `SAE 5160` | 20 | $4{,}73$ | $0{,}0372$ |
| **`Pedal_Alavanca_Ejetora`** | `Alavanca_Ejetora_Pedal` | Alavanca basculante no rasgo da cantoneira ($0^\circ \to 22^\circ$) | `ABNT 1020` | 1 | $9{,}13$ | $0{,}0717$ |
| **`Pedal_Tirante`** | `Tirante_Pedal_Extracao` | Haste 4-barras em barra chata/redonda $\varnothing 8\text{ mm}$ (furos redondos) | `ABNT 1020` | 1 | $44{,}84$ | $0{,}3520$ |
| **`Pedal_Piso`** | `Pedal_Extracao` | Pedal de piso alinhado em $+X$ ($X \in [490, 590]\text{ mm}$) | `ABNT 1020` | 1 | $95{,}00$ | $0{,}7458$ |
| **TOTAL VERTENTE A** | **45 objetos** | — | — | **118** | **$4.718{,}07$** | **$35{,}1726\text{ kg}$** |

</details>

### 3.2. Lista de Compras Comercial e Orçamento Estimado — Vertente A (R$)

| Categoria | Item Comercial e Consumo Líquido (CAD) | Compra Mínima (1x) | Protótipo 1x (R$) | Lote 10x / un. (R$) |
| :--- | :--- | :---: | :---: | :---: |
| **Aço ABNT 1020** | Tubo Metalon $20\times 20\times 1{,}50\text{ mm}$ `#16` (**$12{,}82\text{ m}$ líq.**) | $3$ barras $\times\, 6{,}0\text{ m}$ *(sobra $5{,}18\text{ m}$)* | $180\text{ – }270$ | $128\text{ – }192$ |
| **Aço ABNT 1020** | Chapa Galvanizada `#18` $1{,}20\text{ mm}$ (**$0{,}831\text{ m}^2$ líq.**) | $1$ chapa $2{,}00\times 1{,}00\text{ m}$ *(sobra $1{,}17\text{ m}^2$)* | $280\text{ – }350$ | $140\text{ – }175$ |
| **Aço ABNT 1020** | Barra Chata $2''\times 1/4''$ + Chapa $1/4''$ ($340\times 100\text{ mm}$ mesa + pórticos) | Retalho/corte $\sim 2{,}5\text{ m}$ | $110\text{ – }160$ | $85\text{ – }125$ |
| **Aço ABNT 1020** | Cantoneira $1.1/2''\times 3/16''$, Barras $1.1/4''\times 1/4''$, $1''\times 1/4''$, `#11`/`#16`, Tubo $\varnothing 1.1/4''$, $\varnothing 8\text{ mm}$ | Cortes comerciais de serralheria | $150\text{ – }230$ | $105\text{ – }160$ |
| **Aço SAE 1045** | Barra $1.1/2''\times 1/2''$ ($L_4$), Quad. $1''\times 1''$ (pistão), Red. tref. $\varnothing 20\text{ mm}$ e $\varnothing 12\text{ mm}$ | Frações $0{,}3\text{–}0{,}6\text{ m}$ | $130\text{ – }195$ | $90\text{ – }135$ |
| **Aço SAE 5160** | Barra chata cutelaria/mola $50\times 6{,}35\text{ mm}$ (navalha) + mola tração comercial | $1$ barra $30\text{ cm}$ + $1$ mola | $55\text{ – }110$ | $35\text{ – }65$ |
| **Bronze TM-23** | Buchas padronizadas catálogo: $12\times\varnothing 12\times\varnothing 14$ ($O_4, A, L_3, L_4, L_5, O_5$) + $2\times \varnothing 20\times\varnothing 23$ ($O_2$) | $14$ buchas comerciais | $160\text{ – }290$ | $120\text{ – }220$ |
| **Elastômeros** | Kit Anéis O-Ring NBR 70 ($10\times 1{,}8\text{ mm}$, $8$ un. + reserva) + Manopla borracha $\varnothing 32\text{ mm}$ | $1$ kit ($10$ un.) + $1$ manopla | $30\text{ – }55$ | $20\text{ – }38$ |
| **Polímeros NR-12** | Chapa UHMW $5\text{–}6\text{ mm}$ ($4$ tiras guia) + Policarbonato compacto $2{,}0\text{ mm}$ ($340\times 245\text{ mm}$) | Cortes/retalhos comerciais | $75\text{ – }120$ | $45\text{ – }72$ |
| **Fixadores** | Parafusos Cl. 8.8 ($4\times$ M10, $4\times$ M8$\times$20, $22\times$ M6) + porcas trav./arruelas + $4\text{–}8$ chumbadores $3/8''$ | Kit ferragem local | $45\text{ – }75$ | $32\text{ – }55$ |
| **Consumíveis** | Eletrodo E6013/MIG, discos corte/flap, primer epóxi + esmalte sintético, óleo têmpera | Rateio de oficina | $90\text{ – }145$ | $55\text{ – }90$ |
| **SUBTOTAL MATERIAIS** | — | — | **R$ 1.305 – R$ 2.000** | **R$ 855 – R$ 1.327** |
| **Mão de Obra / Serv.** | Serralheria, furação c/ gabarito, torneamento pinos/canaletas, dobra `#18`/`#11`, têmpera, pintura ($14\text{–}18\text{ h}$ protótipo; $8\text{–}11\text{ h}$ lote) | Oficina mecânica / serralheria | **R$ 980 – R$ 1.600** | **R$ 560 – R$ 950** |
| **TOTAL VERTENTE A** | **Prensa Manual Completa Pronta p/ Operação** | — | **R$ 2.285 – R$ 3.600** | **R$ 1.415 – R$ 2.277** |

---

## 4. Lista de Materiais (BOM) e Orçamento — Vertente B (Motorizada 20 RPM `prensa_baru_motorizada_v1`)

### 4.1. Inventário Técnico Completo por Subsistema (54 Peças CAD)

<details>
<summary>Tabela técnica completa das 54 peças da Vertente B (Subsistema, Material, Sólidos, Volume e Massa OCCT)</summary>

| Subsistema (`App::Part`) | Objeto FreeCAD | Descrição e Perfil Comercial | Material | Sólidos | Vol. ($\text{cm}^3$) | Massa ($\text{kg}$) |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **`Sub01_Estator`** | `Chapa_Base_Estrutural` | Mesa $1/4''$ ($340\times 100\times 6{,}35\text{ mm}$) | `ABNT 1020` | 1 | $194{,}95$ | $1{,}5303$ |
| `Sub01_Estator` | `Portico_Estrutural_Traseiro` | Pórtico traseiro $2''\times 1/4''$ (s/ batentes, $360^\circ$ livre) | `ABNT 1020` | 1 | $466{,}39$ | $3{,}6612$ |
| `Sub01_Estator` | `Portico_Estrutural_Frontal` | Pórtico frontal $2''\times 1/4''$ ($360^\circ$ livre) | `ABNT 1020` | 1 | $390{,}13$ | $3{,}0626$ |
| `Sub01_Estator` | `Espacadores_Transversais_Portico` | $4\times$ espaçadores tubulares M10 realocados | `SAE 1045` | 8 | $101{,}40$ | $0{,}7960$ |
| `Sub01_Estator` | `Suporte_Baru_Cantoneira` | Cantoneira $1.1/2''\times 3/16''$ (V $90^\circ$) + pés dobrados | `ABNT 1020` | 1 | $27{,}23$ | $0{,}2138$ |
| `Sub01_Estator` | `Guia_Pistao_Chapa_U` | Guia em chapa dobrada em U ($3{,}0\text{ mm}$, $4\times$ M8) | `ABNT 1020` | 3 | $55{,}88$ | $0{,}4386$ |
| `Sub01_Estator` | `Parafusos_Guia_Pistao_M8` | $4\times$ M8$\times$20 Cl. 8.8 + porcas | `SAE 1045` | 4 | $7{,}08$ | $0{,}0556$ |
| `Sub01_Estator` | `Tiras_Desgaste_UHMW_5mm` | $4\times$ tiras retas substituíveis UHMW $5{,}0\text{ mm}$ | `UHMW_PE` | 4 | $80{,}97$ | $0{,}0757$ |
| `Sub01_Estator` | `Buchas_Catalogo_Estator` | Buchas catálogo $O_4$ ($12\times 14$) e $O_2$ ($20\times 23$) | `Bronze TM23` | 3 | $1{,}14$ | $0{,}0102$ |
| `Sub01_Estator` | `Pino_Eixo_O4` | Pino liso $\varnothing 12\text{ mm}$ c/ canaletas O-ring ($O_4$) | `SAE 1045` | 3 | $9{,}73$ | $0{,}0764$ |
| `Sub01_Estator` | `Aneis_Retencao_ORing_O4` | $2\times$ O-ring NBR 70 ($10\times 1{,}8\text{ mm}$) | `NBR 70` | 2 | $0{,}20$ | $0{,}0002$ |
| **`Corpo2_O2`** | `Eixo_Principal_O2_20rpm` | Eixo $\varnothing 20\text{ mm}$ ($Y \in [-24{,}5;\, +175{,}0]\text{ mm}$) | `SAE 1045` | 1 | $63{,}26$ | $0{,}4966$ |
| `Corpo2_O2` | `Elo2_Manivela_L2` | Manivela $L_2 = 28{,}98\text{ mm}$ ($K=1{,}5$, chapa $1/4''$) | `SAE 1045` | 1 | $9{,}04$ | $0{,}0710$ |
| `Corpo2_O2` | `Came_Extrator_O2` | Came de disco 3-4-5 ($R_{\text{base}}=52\text{ mm}$, $e=14\text{ mm}$) | `SAE 1045` | 1 | $89{,}74$ | $0{,}7044$ |
| `Corpo2_O2` | `Buchas_Catalogo_A` | $1\times$ bucha $12\times 14\text{ mm}$ junta $A$ | `Bronze TM23` | 1 | $0{,}25$ | $0{,}0022$ |
| `Corpo2_O2` | `Pino_Eixo_A` | Pino $\varnothing 12\text{ mm}$ c/ canaletas O-ring | `SAE 1045` | 2 | $2{,}54$ | $0{,}0199$ |
| `Corpo2_O2` | `Aneis_Retencao_ORing_A` | $2\times$ O-ring NBR 70 ($10\times 1{,}8\text{ mm}$) | `NBR 70` | 2 | $0{,}20$ | $0{,}0002$ |
| **`Corpo3_L3`** | `Elo3_Biela_L3` | Biela $L_3 = 57{,}96\text{ mm}$ (barra chata $1''\times 1/4''$) | `ABNT 1020` | 1 | $9{,}74$ | $0{,}0765$ |
| `Corpo3_L3` | `Buchas_Catalogo_L3` | $2\times$ buchas $12\times 14\text{ mm}$ | `Bronze TM23` | 2 | $0{,}50$ | $0{,}0045$ |
| **`Corpo4_L4`** | `Elo4_Balancim_L4` | Balancim $L_4 = 111{,}96\text{ mm}$ ($1.1/2''\times 1/2''$) | `SAE 1045` | 1 | $51{,}27$ | $0{,}4025$ |
| `Corpo4_L4` | `Buchas_Catalogo_L4` | $2\times$ buchas $12\times 14\text{ mm}$ | `Bronze TM23` | 2 | $1{,}01$ | $0{,}0090$ |
| **`Corpo5_L5`** | `Elo5_Garfo_Duplo_L5` | Garfo duplo $L_5 = 111{,}96\text{ mm}$ ($2\times$ $1.1/4''\times 1/4''$) | `ABNT 1020` | 2 | $51{,}27$ | $0{,}4025$ |
| `Corpo5_L5` | `Buchas_Catalogo_L5` | $4\times$ buchas $12\times 14\text{ mm}$ | `Bronze TM23` | 4 | $1{,}00$ | $0{,}0089$ |
| `Corpo5_L5` | `Pino_Eixo_B` | Pino $\varnothing 12\text{ mm}$ c/ canaletas O-ring | `SAE 1045` | 6 | $9{,}00$ | $0{,}0706$ |
| `Corpo5_L5` | `Aneis_Retencao_ORing_B` | $2\times$ O-ring NBR 70 ($10\times 1{,}8\text{ mm}$) | `NBR 70` | 2 | $0{,}20$ | $0{,}0002$ |
| **`Corpo6_O5`** | `Pistao_Embolo_Quadrado` | Êmbolo $1''\times 1''$ + chapa encosto e orelha $O_5$ | `SAE 1045` | 1 | $106{,}38$ | $0{,}8351$ |
| `Corpo6_O5` | `Navalha_Corte_SAE5160` | Navalha cunha $30^\circ$ ($50\times 26\times 6{,}35\text{ mm}$) | `SAE 5160` | 1 | $6{,}26$ | $0{,}0492$ |
| `Corpo6_O5` | `Parafusos_Fixacao_Navalha_M6` | $2\times$ M6$\times$20 Cl. 8.8 + porcas | `SAE 1045` | 2 | $1{,}88$ | $0{,}0148$ |
| `Corpo6_O5` | `Bucha_Catalogo_O5` | $1\times$ bucha $12\times 14\text{ mm}$ | `Bronze TM23` | 1 | $0{,}51$ | $0{,}0045$ |
| `Corpo6_O5` | `Pino_Eixo_O5` | Pino $\varnothing 12\text{ mm}$ c/ canaletas O-ring | `SAE 1045` | 5 | $4{,}97$ | $0{,}0390$ |
| `Corpo6_O5` | `Aneis_Retencao_ORing_O5` | $2\times$ O-ring NBR 70 ($10\times 1{,}8\text{ mm}$) | `NBR 70` | 2 | $0{,}20$ | $0{,}0002$ |
| **`Sub07_Trem_Potencia`** | `Motor_Eletrico_WEG_05cv_IEC71` | Motor WEG W22 IR3 $0{,}5\text{ cv}$ 4P $1730\text{ rpm}$ IEC 71 | `GG-20` | 2 | $1308{,}40$ | $9{,}4205$ |
| `Sub07_Trem` | `Polia_Motora_D75` | Polia comercial canal A $\varnothing 75\text{ mm}$ | `GG-20` | 1 | $83{,}70$ | $0{,}6027$ |
| `Sub07_Trem` | `Polia_Movida_D325` | Polia comercial canal A $\varnothing 325\text{ mm}$ | `GG-20` | 1 | $795{,}45$ | $5{,}7272$ |
| `Sub07_Trem` | `Correia_V_Perfil_A` | Correia trapezoidal em V comercial **A-56** | `NBR 70` | 1 | $139{,}83$ | $0{,}1678$ |
| `Sub07_Trem` | `Volante_Inercia_Aco` | Volante aro $\varnothing 300/\varnothing 220\times 40\text{ mm}$, alma $10\text{ mm}$, cubo $\varnothing 65$ | `ABNT 1020` | 1 | $1805{,}64$ | $14{,}1742$ |
| `Sub07_Trem` | `Eixo_Intermediario_400rpm` | Eixo $\varnothing 20\text{ mm} \times 219\text{ mm}$ ($399{,}2\text{ rpm}$) | `SAE 1045` | 1 | $68{,}80$ | $0{,}5401$ |
| `Sub07_Trem` | `Mancais_Rolamento_P204_F204` | $1\times$ F204 ($O_2$ tras.) + $2\times$ UCP204 ($400\text{ rpm}$) | `GG-20` | 3 | $363{,}24$ | $2{,}6153$ |
| `Sub07_Trem` | `Redutor_Helicoidal_20_1` | Redutor comercial $20:1$ ($M_{n2}\ge 120\text{ N}\cdot\text{m}$) | `GG-20` | 1 | $1440{,}42$ | $10{,}3710$ |
| `Sub07_Trem` | `Base_Tensora_Motor` | Base deslizante chapa $1/4''$ ($180\times 160\text{ mm}$) + guias | `ABNT 1020` | 1 | $236{,}64$ | $1{,}8576$ |
| **`Sub08_Cavalete_Gabinete`** | `Quadro_Tubular_Metalon_20x20` | Cavalete $1{,}50\text{ m}$ + gabinete NR-12 ampliado ($22{,}75\text{ m}$) | `ABNT 1020` | 3 | $2525{,}66$ | $19{,}8264$ |
| `Sub08` | `Sapatas_Ancoragem_Piso` | $4\times$ sapatas $80\times 80\times 4{,}76\text{ mm}$ ($8$ furos $\varnothing 10{,}5\text{ mm}$) | `ABNT 1020` | 4 | $118{,}56$ | $0{,}9307$ |
| `Sub08` | `Carenagem_Chapa_Galvanizada` | Fechamento NR-12 c/ bandeja inf. ($\le 7\text{ mm}$) + aletas ($\le 6\text{ mm}$) | `ABNT 1020` | 6 | $1732{,}32$ | $13{,}5987$ |
| `Sub08` | `Visor_Policarbonato_NR12` | Visor frontal NR-12 ($430\times 245\text{ mm}$, placa $2{,}0\text{ mm}$; $1{,}2\text{ mm}$ CAD) | `PC NR12` | 1 | $126{,}24$ | $0{,}1515$ |
| `Sub08` | `Calha_Alimentacao_Segura_NR12` | Calha lateral $42\times 48\text{ mm}$ (parede `#16`) | `ABNT 1020` | 1 | $64{,}00$ | $0{,}5024$ |
| `Sub08` | `Reservatorio_Alimentacao_Chapa` | Moega dedicada `#18` ($4\times$ M6 na lateral) | `ABNT 1020` | 1 | $159{,}12$ | $1{,}2491$ |
| `Sub08` | `Parafusos_Fixacao_Gabinete_M6` | Parafusos M6/M8 + porcas do visor, calha e moega | `SAE 1045` | 20 | $11{,}13$ | $0{,}0874$ |
| `Sub08` | `Calha_Descarga_Chapa` | Calha inclinada de descarga `#18` | `ABNT 1020` | 1 | $52{,}41$ | $0{,}4114$ |
| `Sub08` | `Reservatorio_Chapa_Coleta` | Reservatório frontal removível $12{,}3\text{ L}$ `#18` | `ABNT 1020` | 1 | $327{,}01$ | $2{,}5670$ |
| `Sub08` | `Suporte_Eixo_Ejetor_NR12` | Mancais ejetor + pino $O_{\text{seg}}$ + braço âncora mola | `ABNT 1020` | 7 | $19{,}00$ | $0{,}1492$ |
| `Sub08` | `Mola_Retorno` | Mola helicoidal tração ($F_0 = 12\text{ N}$, $k = 0{,}80\text{ N/mm}$) | `SAE 5160` | 13 | $1{,}12$ | $0{,}0088$ |
| **`Ext_Seguidora`** | `Alavanca_Seguidora` | Alavanca seguidora de came c/ rolete $\varnothing 19\text{ mm}$ (`KR19`) | `SAE 1045` | 2 | $21{,}42$ | $0{,}1681$ |
| **`Ext_Tirante`** | `Tirante_Extracao` | Tirante extrator com furos redondos simples | `ABNT 1020` | 1 | $22{,}14$ | $0{,}1738$ |
| **`Ext_Ejetora`** | `Alavanca_Ejetora` | Alavanca basculante ejetora ($0^\circ \to 22^\circ$) | `ABNT 1020` | 1 | $11{,}14$ | $0{,}0874$ |
| **TOTAL VERTENTE B** | **54 objetos** | — | — | **136** | **$13.177{,}69$** | **$98{,}5209\text{ kg}$** |

</details>

### 4.2. Lista de Compras Comercial e Orçamento Estimado — Vertente B (R$)

> [!NOTE] Escolha Comercial do Redutor $20:1$ no Mercado Brasileiro
> Para potência de $0{,}5\text{ cv}$ e relação exata $20:1$, existem duas famílias comerciais no Brasil:
> 1. **Faixa Econômica — Redutor Coroa & Rosca Sem-Fim (NMRV 40/50 ou WEG-Cestari WCG01 40/63, R$ 400–850):** menor CAPEX e ampla disponibilidade nacional, com rendimento típico $\eta_2 \approx 0{,}72\text{–}0{,}82$. Ainda assim, a potência exigida no eixo do motor permanece em $13{,}2\text{ W} / 0{,}72 \approx 18{,}4\text{ W} \ll 370\text{ W}$ ($20\times$ de folga no motor WEG $0{,}5\text{ cv}$), e a inércia refletida do conjunto volante + polia excede $56\text{ kg}\cdot\text{m}^2 \gg 36{,}56\text{ kg}\cdot\text{m}^2$ ($C_f < 8{,}7\%$).
> 2. **Faixa Industrial — Redutor Helicoidal / Eixos Ortogonais ($\eta_2 = 0{,}95$, R$ 1.400–2.200):** especificação nominal adotada na EDO RK45 ($C_f = 6{,}71\%$), recomendada para jornadas contínuas de $8\text{ h/dia}$ em cooperativas pela menor perda térmica e maior vida útil de engrenamento.

| Categoria | Item Comercial e Consumo Líquido (CAD) | Compra Mínima (1x) | Protótipo 1x (R$) | Lote 10x / un. (R$) |
| :--- | :--- | :---: | :---: | :---: |
| **Aço ABNT 1020** | Tubo Metalon $20\times 20\times 1{,}50\text{ mm}$ `#16` (**$22{,}75\text{ m}$ líq.**) | $4$ barras $\times\, 6{,}0\text{ m}$ *(sobra $1{,}25\text{ m}$)* | $240\text{ – }360$ | $228\text{ – }342$ |
| **Aço ABNT 1020** | Chapa Galvanizada `#18` $1{,}20\text{ mm}$ (**$1{,}892\text{ m}^2$ líq.** c/ recortes) | $2$ chapas $2{,}0\times 1{,}0\text{ m}$ ou $1\times 3{,}0\times 1{,}2\text{ m}$ | $380\text{ – }580$ | $300\text{ – }440$ |
| **Aço ABNT 1020** | Pórticos $2''\times 1/4''$, mesa $1/4''$, base tensora $1/4''$, sapatas $80\times 80$, $L_3$, $L_5$, cantoneira $V$ | Cortes comerciais + chapas | $290\text{ – }420$ | $230\text{ – }340$ |
| **Volante e Came** | Tarugo/chapa oxicortada ABNT 1020 p/ volante $\varnothing 300\times 50\text{ mm}$ ($\sim 22\text{ kg}$ bruto) + chapa SAE 1045 $14\text{ mm}$ p/ came | $1$ disco bruto $\varnothing 310\times 52\text{ mm}$ + retalho | $240\text{ – }380$ | $175\text{ – }280$ |
| **Aço 1045 e 5160** | Barras $L_4$, Quad. $1''$, Eixos $\varnothing 20$ ($O_2$ e $400\text{ rpm}$), pinos $\varnothing 12$, seguidora, navalha e mola SAE 5160 | Frações de barra + mola tração | $220\text{ – }340$ | $165\text{ – }255$ |
| **Motor OEM** | Motor Elétrico WEG W22 IR3 **$0{,}5\text{ cv}$** 4P $1730\text{ rpm}$ Carcaça IEC 71 | $1$ un. nova c/ garantia | $1.100\text{ – }1.850$ | $990\text{ – }1.650$ |
| **Redutor OEM** | Redutor comercial $20:1$ ($M_{n2}\ge 120\text{ N}\cdot\text{m}$): *Eco Sem-Fim* vs. *Ind. Helicoidal* | $1$ unidade comercial | $400\text{ – }2.200$ | $360\text{ – }1.950$ |
| **Transmissão V** | Polia canal A $\varnothing 75\text{ mm}$ + Polia canal A $\varnothing 325\text{ mm}$ + Correia **A-56** + chavetas DIN 6885 | Kit completo | $175\text{ – }290$ | $150\text{ – }250$ |
| **Mancais / Rolete** | $2\times$ Mancais `UCP204` + $1\times$ Flangeado `F204` *(ou $2\times$ F204)* + Rolete seguidor `KR19` | Kit rolamentos | $165\text{ – }360$ | $140\text{ – }300$ |
| **Polímeros e Fix.** | Buchas bronze TM-23 ($12\times\varnothing 12\times 14$ + $2\times\varnothing 20\times 23$), O-rings, UHMW, PC $2{,}0\text{ mm}$, $4\times$ coxins NBR 70, Cl. 8.8 | Kit completo | $240\text{ – }390$ | $175\text{ – }285$ |
| **Elétrica NR-12** | Disjuntor-motor $1{,}6\text{–}2{,}5\text{ A}$ + contator/caixa + botão cogumelo NR-12 + chave intertravamento tampa + cabos | Kit elétrico certificado | $290\text{ – }620$ | $250\text{ – }520$ |
| **Consumíveis** | Eletrodo/MIG, discos corte/flap, primer epóxi + esmalte, óleo lubrificante redutor | Rateio de oficina | $130\text{ – }210$ | $90\text{ – }145$ |
| **SUBTOTAL MATERIAIS** | — | — | **R$ 3.870 – R$ 8.000** | **R$ 3.253 – R$ 6.757** |
| **Mão de Obra / Serv.** | Caldeiraria, furação c/ gabarito, torneamento/chavetas, CNC came, balanceamento G6.3, montagem elétrica ($26\text{–}34\text{ h}$ 1x; $16\text{–}22\text{ h}$ lote) | Oficina + eletricista | **R$ 2.100 – R$ 3.200** | **R$ 1.300 – R$ 2.000** |
| **TOTAL VERTENTE B** | **Prensa Motorizada Completa (`Eco Sem-Fim` $\leftrightarrow$ `Ind. Helicoidal`)** | — | **R$ 5.970 – R$ 11.200** | **R$ 4.553 – R$ 8.757** |

---

## 5. Plano de Fabricação, Decisões de DFM e Controle de Qualidade

### 5.1. Decisões de DFM (*Design for Manufacturing*) Incorporadas no CAD

As revisões de engenharia registradas até a versão final consolidaram escolhas que eliminam operações caras de fresamento 3D/CNC no núcleo da prensa:
1. **Substituição da bigorna usinada por cantoneira comercial a $45^\circ$:** `Suporte_Baru_Cantoneira` usa cantoneira laminada $1.1/2''\times 3/16''$ dobrada/cortada formando berço V de $90^\circ$ sem usinagem de prisma maciço.
2. **Guia linear modular em U parafusável sem fresagem de rabo-de-andorinha:** `Guia_Pistao_Chapa_U` é dobrada em chapa $3{,}0\text{ mm}$ (`#11`) e fixada por $4\times$ M8 ao pórtico traseiro, recebendo $4$ tiras retas de UHMW substituíveis sem usinagem de canais de retenção.
3. **Pistão sem fresa e pino liso com O-rings:** `Pistao_Embolo_Quadrado` utiliza barra quadrada trefilada $1''\times 1''$ com orelha superior soldada (sem rasgo em U fresado), e todos os pinos das 4 juntas ($O_4, A, B, O_5$) são cortados de barra retificada $\varnothing 12\text{ mm}$ SAE 1045 com duas canaletas simples de torno para O-ring NBR 70 (sem roscas finas nem brochamento de cupilhas).
4. **Acoplamento de $O_2$ sem chaveta na Vertente A:** `Conjunto_Soldado_L2_Alavanca_O2` solda diretamente o eixo $\varnothing 20\text{ mm}$ ao braço $L_2$ e ao tubo da alavanca, transferindo $94{,}4\text{ N}\cdot\text{m}$ sem brochamento de chaveta (mantendo o desacoplamento axial com $0{,}000000\text{ mm}^3$ de colisão).
5. **Extrator sem rasgos oblongos:** tanto na Vertente A (pedal) quanto na Vertente B (came), o tirante trabalha apenas com furos redondos simples, eliminando fresagem de oblongos.

### 5.2. Roteiro de Fabricação — Vertente A (Manual — Serralheria Rural / Oficina Básica)

*Tempo total estimado de oficina: **$14\text{–}18\text{ h}$** (protótipo unitário) / **$8\text{–}11\text{ h}$** (lote com gabarito de furação e solda).*

1. **OP-10 — Corte de Perfis e Barras (Serra policorte / serra fita, ~$2{,}5\text{ h}$):** Cortar Metalon $20\times 20\times 1{,}50\text{ mm}$ ($12{,}82\text{ m}$ totais para cavalete $1{,}50\text{ m}$ + gabinete), barras chatas do pórtico ($2''\times 1/4''$), elos $L_2, L_3, L_4, L_5$, cantoneira $V$ e êmbolo quadrado $1''\times 1''$.
2. **OP-20 — Corte e Dobra de Chapas `#18` e `#11` (Guilhotina + viradeira manual, ~$2{,}5\text{ h}$):** Planificar, cortar e dobrar `Guia_Pistao_Chapa_U` ($3{,}0\text{ mm}$), `Calha_Alimentacao_Segura_NR12` (`#16`, vão livre $42\times 48\text{ mm}$), `Reservatorio_Alimentacao_Chapa` (moega lateral `#18`), `Calha_Descarga_Chapa`, `Reservatorio_Chapa_Coleta` ($12{,}3\text{ L}$), carenagem `#18` e cortar visor de policarbonato $2{,}0\text{ mm}$.
3. **OP-30 — Furação de Precisão com Gabarito e Alargamento (Furadeira de bancada, ~$2{,}5\text{ h}$):** Furar com gabarito único os entre-eixos críticos ($L_2 = 70{,}00\text{ mm}$, $L_3 = 100{,}00\text{ mm}$, $L_4 = 111{,}96\text{ mm}$, $L_5 = 111{,}96\text{ mm}$), passar alargador manual para $\varnothing 14{,}00\text{ H7}$ / $\varnothing 23{,}00\text{ H7}$, prensar buchas de bronze TM-23 em morsa/prensa e conferir $\varnothing 12{,}00\text{ H7}$ interno; abrir furos de fixação M8 da guia U e M6 do visor/moega/calha.
4. **OP-40 — Torneamento Simples (Torno mecânico convencional, ~$1{,}5\text{ h}$):** Cortar $4$ pinos de barra trefilada $\varnothing 12\text{ mm}$ SAE 1045, usinar canaletas de retenção dos O-rings ($10\times 1{,}8\text{ mm}$) e preparar o trecho de eixo $\varnothing 20\text{ mm}$ ($O_2$) + $4$ espaçadores tubulares do pórtico.
5. **OP-50 — Cutelaria e Tratamento Térmico da Navalha (Forja simples/maçarico + esmeril, ~$1{,}5\text{ h}$):** Desbastar o gume em cunha dupla de $30^\circ$ ($15^\circ$/face) na barra SAE 5160 ($50\times 26\times 6{,}35\text{ mm}$), furar $2\times$ M6 antes da têmpera, temperar em óleo aquecido ($840^\circ\text{C}$ / imã não-magnético) + duplo revenimento a $220^\text{–}250^\circ\text{C}$ ($54\text{–}58\text{ HRC}$) e formar micro-chanfro de $0{,}5\text{ mm}$ contra lascamento.
6. **OP-60 — Soldagem em Gabarito (E6013 / MIG, ~$2{,}5\text{ h}$):** Ponteamento e cordões alternados (controle de empenamento) da mesa $1/4''$ + pórticos frontal/traseiro, cavalete Metalon + sapatas $70\times 70\text{ mm}$, conjunto `L2 + eixo O2 + tubo alavanca` ($\delta_L = 50^\circ$), batentes de $20^\circ$/$80^\circ$ e pedal $+X$.
7. **OP-70 — Acabamento, Pintura e Montagem Final (~$2{,}0\text{ h}$):** Escovamento, desengraxe, pintura anticorrosiva (primer epóxi + esmalte industrial **fora** das guias/pinos e **fora** das paredes internas da calha em contato com o fruto), montagem das tiras UHMW, fixação das calhas, teste de calibração do corte PMI (**$4{,}75\text{ mm}$** sobre corpo de prova $\varnothing 30\times 40\text{ mm}$) e instalação da manopla e O-rings.

### 5.3. Roteiro Adicional de Fabricação — Vertente B (Motorizada 20 RPM)

Além das operações estruturais equivalentes à Vertente A (ajustadas para o cavalete ampliado $22{,}75\text{ m}$ sem batentes no pórtico e com $L_2 = 28{,}98\text{ mm}$ / $L_3 = 57{,}96\text{ mm}$), a Vertente B requer **$+12\text{ a }16\text{ h}$** de usinagem mecânica, caldeiraria fina e elétrica industrial (**total $26\text{–}34\text{ h}$**):

1. **OP-25B — Caldeiraria Ampliada ISO 13857:** Recorte/estampagem das aletas traseiras de ventilação ($\le 6{,}0\text{ mm}$) e dos $10$ rasgos da bandeja inferior do motor ($\le 7{,}0\text{ mm}$ de largura) para impedir acesso de dedos às partes móveis inferiores, além das travessas de sustentação dos mancais `UCP204` e da `Base_Tensora_Motor`.
2. **OP-45B — Torneamento do Volante, Eixos e Chavetas (Torno + chaveteiro/fresa):** Usinar `Volante_Inercia_Aco` a partir de disco bruto ABNT 1020 até $\varnothing_{\text{ext}} = 300\text{ mm}$, $\varnothing_{\text{int}} = 220\text{ mm}$, largura de aro $40\text{ mm}$, alma $10\text{ mm}$, cubo $\varnothing 65\times 50\text{ mm}$ e furo $\varnothing 20\text{ H7}$ ($m = 14{,}17\text{ kg}$); usinar rasgos de chaveta **DIN 6885 ($6\times 6\text{ mm}$)** no `Eixo_Principal_O2_20rpm` (saída do redutor $20:1$, manivela $L_2$ e came) e no `Eixo_Intermediario_400rpm` (volante e polia $\varnothing 325\text{ mm}$).
3. **OP-48B — Usinagem CNC do Came de Disco 3-4-5 (`Came_Extrator_O2`):** Corte inicial em plasma/laser CNC + acabamento em fresadora CNC do perfil conjugado **3-4-5** em chapa/disco SAE 1045 ($14\text{ mm}$, $R_{\text{base}} = 52{,}0\text{ mm}$, $s_{\max} = 10{,}25\text{ mm}$), garantindo acabamento superficial $R_a \le 1{,}6\,\mu\text{m}$ na pista de rolagem do rolete `KR19` (opcionalmente têmpera superficial por indução/chama na pista).
4. **OP-55B — Balanceamento do Volante (`ISO 1940-1 G6.3`):** Balanceamento estático em lâminas paralelas ou dinâmico em balanceadora até desbalanceamento residual $e_{\text{per}} \le 0{,}15\text{ mm}$ ($F_{\text{desb}} \le 3{,}74\text{ N}$ a $400\text{ rpm}$).
5. **OP-75B — Alinhamento do Trem de Potência e Quadro Elétrico NR-12:** Alinhar polias $\varnothing 75\text{ mm}$ e $\varnothing 325\text{ mm}$ com régua metálica ($\le 0{,}5\text{ mm}$ de desvio axial em $Y = 368\text{ mm}$), tensionar a correia **A-56** na `Base_Tensora_Motor` (mantendo função de fusível mecânico por escorregamento em *jam*), instalar os $4\times$ coxins NBR 70 sob as sapatas e cabear o disjuntor-motor ($1{,}6\text{–}2{,}5\text{ A}$), botão de emergência cogumelo com retenção e chave de intertravamento da tampa traseira.

### 5.4. Pontos Críticos de Inspeção e Controle de Qualidade (CQ)

| Item Inspecionado | Especificação / Tolerância de Projeto | Impacto se Fora de Tolerância |
| :--- | :--- | :--- |
| **Entre-eixos $L_4, L_5$ ($111{,}96\text{ mm}$) e altura $O_4 \leftrightarrow$ Berço V** | $\pm 0{,}15\text{ mm}$ nos elos; $Z_{\text{ponta,PMI}} = 1037{,}50 \pm 0{,}30\text{ mm}$ *(piso)* | Se baixo demais, esmaga a amêndoa ($> 5\text{ mm}$ de penetração); se alto demais, falha a abertura do endocarpo. |
| **Ajuste pino-bucha ($O_4, A, B, O_5$)** | Furo bucha $\varnothing 12{,}00\text{ H7}$ ($+0{,}018/0$) / Pino $\varnothing 12\text{ g6}$ ($-0{,}006/-0{,}017$) | Folga excessiva causa choque dinâmico e perda de curso útil no PMI. |
| **Folga Pistão Quadrado $\leftrightarrow$ Tiras UHMW** | $0{,}15\text{–}0{,}25\text{ mm}$ total regulada por calços/parafusos M8 da guia U | Aperto trava a descida; folga excessiva torce o gume da navalha no corte. |
| **Frestas da Carenagem e Bandeja (Vertente B)** | $\le 6{,}0\text{ mm}$ (aletas traseiras) e $\le 7{,}0\text{ mm}$ (rasgos bandeja) | Conformidade direta com **NR-12 / ABNT NBR NM ISO 13857** contra acesso de dedos. |
| **Alinhamento Correia A-56 e Fase do Came** | Desalinhamento polias $\le 0{,}5\text{ mm}$; subida do came a $\theta_2 = 60^\circ \pm 2^\circ$ | Atraso no came colide a pá ejetora com a descida do pistão ($165^\circ$ PMS). |
| **Teste Funcional Pré-Entrega** | $10$ ciclos em vazio + $10$ frutos reais (ou tarugos $\varnothing 30\times 40\text{ mm}$) | Validação de corte limpo ($\le 5\text{ mm}$), extração livre e ausência de aquecimento/vibração anômala. |

---

## 6. Diretriz de Implantação para o CIS-bc/UFG

* **Cenário 1 — Grupos Familiares / Extrativismo Isolado:** Implantar a **Vertente A (`prensa_baru_manual_v1`)**, disponibilizando os desenhos abertos (`.step` + roteiro `OP-10` a `OP-70`) para fabricação em serralherias municipais do Cerrado goiano, com compra centralizada de buchas, O-rings, chapas e barras de aço SAE 1045/5160 pela cooperativa para reduzir o custo unitário para a faixa de **R$ 1.415–2.277**.
* **Cenário 2 — Unidade Central de Beneficiamento / Cooperativa ($8\text{ h/dia}$):** Implantar a **Vertente B (`prensa_baru_motorizada_v1`)** preferencialmente com **redutor helicoidal industrial $20:1$** (ou com **redutor coroa/sem-fim** quando o orçamento inicial for restrito), garantindo acionamento contínuo a $20\text{ rpm}$, segurança NR-12 integral, proteção por correia fusível + disjuntor-motor e extração automática livre de exposição manual na zona de corte.

---

## 7. Estudo Comparativo de Custo: Redutor Helicoidal vs. Volante de Inércia a 20 RPM

A $20\text{ rpm}$ ($\bar{\omega}_2 = 2{,}0944\text{ rad/s}$), a energia cinética armazenada cai quadraticamente com a rotação ($E_k = \frac{1}{2}I\omega^2$), enquanto o corte biomaterial $s^{0{,}4}$ de $10\text{ mm}$ impõe um pulso concentrado de **$\Delta E = 32{,}08\text{ J}$**, pico de torque **$T_{\text{pico}} = 55{,}32\text{ N}\cdot\text{m}$** ($P_{\text{pico}} = 115{,}86\text{ W}$ contra $P_{\text{méd}} = 13{,}23\text{ W}$, razão de pico de **$8{,}76\times$**). A tabela abaixo confronta as quatro rotas possíveis para acionar o eixo $O_2$ a $20\text{ rpm}$ (preços Brasil Nov/2026, incluindo motor WEG $0{,}5\text{ cv}$):

| Arquitetura do Trem de Potência a $20\text{ rpm}$ | Inércia Efetiva em $O_2$ ($I_{\text{eq}}$) | $C_f$ na Quebra $s^{0{,}4}$ | Custo sem Motor (R$) | Custo Total c/ Motor (R$) | Veredito Técnico e de Proteção Mecânica |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **1. Volante Direto em $20\text{ rpm}$** ($\varnothing 800\text{ mm}$, $265{,}4\text{ kg}$ no aro) + transmissão lenta correia/corrente + mancais `P208/210` + reforço gabinete | $36{,}56\text{ kg}\cdot\text{m}^2$ *(mín. $C_f=20\%$)* | $\approx 19{,}8\%$ | $4.250\text{ – }7.600$ | **$5.350\text{ – }9.450$** | **Inviável em serralheria e mais caro:** exige $\sim 300\text{ kg}$ de aço bruto + oxicorte, torno pesado ($\varnothing > 850\text{ mm}$) e ampliação estrutural. |
| **2a. Projeto Atual — Redutor Helicoidal $20:1$ + Volante $400\text{ rpm}$ ($14{,}17\text{ kg}$)** + correia A-56 (`fusível`) + `2x UCP204` + `1x F204` | **$108{,}65\text{ kg}\cdot\text{m}^2$** *(fator $380\times$)* | **$6{,}71\%$** | $2.230\text{ – }3.630$ | **$3.330\text{ – }5.480$** | **Vencedor técnico-industrial:** substitui $265{,}4\text{ kg}$ por $14{,}17\text{ kg}$ ($18{,}7\times$ menor), reduz o custo em **$38\%\text{–}42\%$** vs. Opção 1 e mantém **fusível de correia** + $C_f = 6{,}71\%$. |
| **2b. Projeto Atual Econômico — Redutor Coroa/Sem-Fim $20:1$ + Volante $400\text{ rpm}$ ($14{,}17\text{ kg}$)** | $\ge 56{,}5\text{ kg}\cdot\text{m}^2$ *(só volante, $\eta\ge 0{,}72$)* | $< 8{,}7\%$ | $1.230\text{ – }2.280$ | **$2.330\text{ – }4.130$** | **Menor custo com volante + fusível:** mantém a correia A-56 protetora e o volante de $14{,}17\text{ kg}$ pagando até $56\%$ menos que a Opção 1. |
| **3. Motoredutor Helicoidal Direto $85:1$ ($0{,}5\text{ cv} \to 20\text{ rpm}$, SEM Volante e SEM Correia)** *(SEW / WEG-Cestari)* | Inércia baixa do rotor refletida | Absorvido direto pelos dentes e rede | — *(integrado)* | **$2.300\text{ – }4.700$** | **Mais barato que o volante gigante e mais enxuto que 2a**, porém **perde o fusível mecânico de deslizamento**: picos de $55{,}3\text{ N}\cdot\text{m}$ e eventuais travamentos (*jams*) atingem direto os engrenamentos. |

**Conclusão Objetiva:** **Sim — o redutor helicoidal (tanto acoplado a um volante leve a $400\text{ rpm}$ quanto em motoredutor direto $85:1$) sai substancialmente mais barato do que dimensionar e fabricar um volante de inércia para operar diretamente a $20\text{ rpm}$.** A massa bruta de aço ($\sim 300\text{ kg}$ para atingir $36{,}56\text{ kg}\cdot\text{m}^2$), o torneamento em torno de grande porte e os mancais/chassi reforçados do volante lento custam mais que o próprio redutor helicoidal industrial comercial.

