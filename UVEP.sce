clear
clc
// =========== INFORMAÇÕES IMPORTANTES ===============

// DADOS DE ENTRADA DO PROGRAMA: ARQUIVO COMPOSTO DE UMA COLUNA COM OS COMPRIMENTOS DE ONDA E OUTRA COM OS RESPECTIVOS
// COMPRIMENTOS DE ONDA OBSERVADOS. DEVEM VIR FORMATADOS DA SEGUINTE MANEIRA:

//      1) A COLUNA DOS COMPRIMENTOS DE ONDA DEVE SEMPRE COMEÇAR NA POSIÇÃO ZERO DE CADA LINHA

//            _________________
//           | 200    0.2301    <- ERRADO
//            _________________
//           |200    0.2301     <- CERTO

//      2) NÃO DEVEM EXISTIR ESPAÇOS NO INÍCIO DOS DADOS E NEM NO FINAL
//            _______________
//           |                <- ESPAÇO EM BRANCO NO INICIO DO ARQUIVO: ERRADO
//           |200   0.2244

//            _______________   
//           |200   0.2244    <- DADOS COMEÇAM NA POSIÇÃO ZERO DE CADA LINHA: CERTO 

//            _______________
//           |200   0.2244
//           ||               <- CURSOR POSICIONADO NA LINHA APÓS OS ÚLTIMOS DADOS: ERRADO 

//            _______________
//           |200   0.2222|   <- CURSOR POSICIONADO APÓS O ÚLTIMO DADO: CERTO

//      3) A ANÁLISE DEVE COMEÇAR DE TRÁS PARA FRENTE, OU SEJA, DO ÚLTIMO ARQUIVO A SE ANALISAR PARA O PRIMEIRO 

// Os dados capturados são do tipo string e são capturados em uma única linha, logo, 
// é necessário que sejam extraídos os dois valores. Como os dados impressos pelo equipamento possuem 4 casas de precisão,
// a extração do segundo valor é feita de trás para frente, visto que os dados impressos não possuem um espaço
// fixo entre eles. O primeiro valor segue sempre o mesmo padrão, então sua extração é simples. Um exemplo é mostrado abaixo.

// 200    -0.7586
// 201      0.6452
// 202    0.5423

// No entanto, contando as casas ocupadas pelos valores de absorção, pode-se constatar que esse número é sempre 6 ou 7.
// Foi sobre esse fato que a recuperação dos valores de absorção foi modelada. A recuperação dos valores de comprimento de onda
// é trivial, visto que eles sempre possuem 3 casas e possuem um padrão de organização fixo. A única exceção é para o último 
// valor, que é de 1000 nm, o qual é ajustado ao final da manipulação dos dados.

// VALE RESSALTAR QUE O PROGRAMA FOI PROJETADO PARA REALIZAR A ANÁLISE SOBRE A FAIXA DE 200 - 1000 nm! 

//------------------------------------------------------------------

// Inicialização das Variaveis de auxílio
A="";
B="";
M = string(zeros(1,7)); 

// Solicitação ao usuário
labels = ["Número de espectros:"; "Limite inferior de absorção(nm)"; "Limite superior de absorção(nm)"];
[ok, N, faixa1, faixa2] = getvalue("Defina o número de espectros:", labels,...
    list("str", 1, "str", 1,"str", 1),["6";"200"; "1000"]);

// Conversão string->int
N = strtod(N); // N é número de espectros gerados para cada concentração
amp = strtod(faixa2) - strtod(faixa1) + 1; // amp define a faixa da absorção

// Inicialização das bases
Base =zeros(amp, N); // Tabela onde os dados serão armazenados
Maximos = zeros(N,2);

// leitura do arquivos
for p = 1:N
caminho = uigetfile("*.*", "c:\Users\Wallace Andrade\Desktop", "Escolha o arquivo");
arq = mopen(caminho, 'r');

// captura de dados
a = mgetl(arq);
arq = mclose(arq); // fechando arquivo base
tamanho = size(a);
tamanho = tamanho(1); 

// ===== INICIO DO PROGRAMA ======
for x = 1:tamanho
a1 = a(x);

// captura de termos de auxilio para extração dos dos valores
tam = length(a1); 
cont = tam:-1:tam-6;

// quebra do dado capturado em um vetor de strings
partes = strsplit(a1);

// preparando o primeiro valor
// 1) Loop de construção do valor
for i=1:3
//    pause
//    disp(partes);
    try
    A = A + partes(i);
//    pause
    catch
    disp(x, "Posição em que se encontra o valor problemático:");
    disp(a, "Valor problemático:");
    end    
end
//pause

// 2) Conversão de string para número
A = strtod(A);

// preparando o segundo valor
// 1)Loop de construção 1
for j=1:7
    M(1,8-j) = partes(cont(j));
end

// 2) Ajuste da vírgula
M(1,3) = "."; 

// 3) Loop de contrução 2
for k=1:sum(length(M))
     B = B + M(1,k);
end

// 4) Conversão de string
B = strtod(B);

// Salvando na base
Base(x, 1) = A; // Salvando a faixa de absorção
Base(x, p+1) = B; // Salvando os valores de absorção
A="";
B="";
end

// Capturando os máximos
AbsMaxima = max(Base(:,p+1)); // Captura o valor máximo

// Salvando o máximo
Maximos(p,:) = [p, AbsMaxima];       
end

// Ajustando o ultimo valor
Base(amp, 1) = 1000;

// ======= RESULTADOS ========

// Regressão linear

//  1) Solicitação ao usuário
scf(1) // Nova janela gráfica
plot2d(Maximos(:,1), Maximos(:,2), -4);
choice = messagebox("Deseja deletar algum ponto?", "modal", "info", ["Sim" "Não"]);
while choice <> 2 then
    label = ["Exclusão de ponto (Acochambramento)"];
    [ok, ponto] = getvalue("Digite o ponto a ser excluído", label,...
        list("str", 1),[""]);
    ponto = strtod(ponto);
    Maximos(ponto,:) = 0;
    choice = messagebox("Deseja deletar algum ponto?", "modal", "info", ["Sim" "Não"]);
end

// 2) Reorganizando a tabela dos máximos e a base com os dados de absorção
k = 1;
exc = 0;
for f = 1:N
    if Maximos(f, :) <> 0 then
    NovoMaximos(k, :) = Maximos(f,:);
    k = k+1;
//       Nova base de absorção
        for r = 1:tamanho
            NovaBase(:,k) = Base(:, f+1);
        end
    else
        exc = exc+1; // Contador de exclusões
    end
end

NovaBase(:,1) = Base(:, 1); // Adicionando a coluna dos comprimentos de onda

// 3) Realizando a regressão
x = NovoMaximos(:,1);
y = NovoMaximos(:,2);
D = [x, ones(x)];
X = lsq(D, y); // Regressão Linear
y1e=X(1,1)*x+X(2,1); // Construção da reta

// 4) Variancia e desvio padrão
m = mean(NovoMaximos(:,2)); // Cálculo da média dos máximos de absorção
s = variance(y1e, "*", m); // Calculando a variância dos valores de absorção
SD = s^2; // Calculando o desvio padrão
r = correl(NovoMaximos(:,1), NovoMaximos(:,2)); // Coeficiente de correlação linear
// Resultados

// 1) Gráficos
clf(); // Limpa a janela gráfica anterior
plot2d(Maximos(:,1), Maximos(:,2), -4); // Plota o novo gráfico sem o ponto excluído
plot2d(x,y1e,2); // Inserindo a reta de regressão
title("Reta de regressão", "fontsize", 3); // Adiciona um título ao gráfico

// Imprimindo no console os resultados
disp("----------------------------------");
disp("Coeficiente Angular: " + string(X(1)));
disp("Coeficiente Linear: " + string(X(2)));
disp("Variância: " + string(s));
disp("Desvio Padrão: " + string(SD));
disp("Coeficiente de correlação linear: " + string(r));
disp("----------------------------------");

// Gráfico de Absorção
scf(); // Nova janela gráfica
for i =1:N - exc
//    scf(i); // O comando scf permite plotar gráficos em janelas separadas
    estilo(i) = i;
    hl(i) = "D" + string(i);
    label = ["Legendamento"];
    [ok, conc] = getvalue("Digite a concentração da solução" + " " + hl(i), label,...
        list("str", 1),[""]);
    hl(i) = hl(i) + " = " + conc + " " + "mol/dm^3";
    plot2d(NovaBase(:, 1), NovaBase(:,i+1), style = estilo(i));
end
//     Edição do gráfico
    legends(hl,[1:1:i], font_size = 3, opt = 1);
    a = gca();
    a.x_label.text = "nm";
    a.y_label.text = "Abs";
    a.x_label.font_size = 3;
    a.y_label.font_size = 3;
    
