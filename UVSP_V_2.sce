clear
clc

// Inicialização das Variaveis de auxílio
A="";
B="";
M = string(zeros(1,7)); 

// Solicitação ao usuário
labels = ["Nome da Amostra:";"Número de espectros:"; "Limite inferior de absorção(nm)"; "Limite superior de absorção(nm)"];
[ok,nomeAmostra,N, faixa1, faixa2] = getvalue("Informações sobre os dados:", labels,...
    list("str", 1, "str", 1, "str", 1,"str", 1),["";"6";"200"; "1000"]);
    if ok == %F then
        abort
    end
    messagebox("Composto " + nomeAmostra + " em análise!", "Lembrete", "info");
// Conversão string->int
N = strtod(N); // N é número de espectros gerados para cada concentração
amp = strtod(faixa2) - strtod(faixa1) + 1; // amp define a faixa da absorção

// Inicialização das bases
Base =zeros(amp, N); // Tabela onde os dados serão armazenados os comprimentos de onda as absorções
Maximos = zeros(N,2); // Tabela onde serão guardados os valores máximos
conc = zeros(N, 2); // Tabela das concentrações
conc = string(conc);

// leitura do arquivos
caminho = uigetfile("*.*", "c:\Users\Wallace Andrade\Desktop", "Escolha os arquivos do "+ nomeAmostra, %t); 
                                                                                      // %t permite que sejam selecionados                                                                                               vários arquivos
for p = 1:N
arq = mopen(caminho(N-p+1), 'r');

// captura de dados
a = mgetl(arq); // lendo o arquivo
arq = mclose(arq); // fechando arquivo base
label2 = ["Concentração"];
    [ok, valor] = getvalue("Digite a concentração da solução " + string(N-p+1) + " (mol/dm^3)" , label2,...
        list("str", 1),[""]);
    if ok == %F then
        abort
    end
Conc(p, :) = [string(p), valor];
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
valorExcluido = [];
flagValorExcluido = 1;
//  1) Solicitação ao usuário
scf(1) // Nova janela gráfica
plot2d(Maximos(:,1), Maximos(:,2), -4);
choice = messagebox("Deseja deletar algum ponto?", "modal", "info", ["Sim" "Não"]);
while choice <> 2 then
    label = ["Exclusão de ponto (Acochambramento)"];
    [ok, ponto] = getvalue("Digite o ponto a ser excluído (valor em x)", label,...
        list("str", 1),[""]);
    ponto = strtod(ponto);
    valorExcluido(flagValorExcluido, :) = Maximos(ponto, :); // Recupera o valor excluído
    flagValorExcluido = flagValorExcluido + 1;
    Maximos(ponto,:) = 0; // Elimina o valor 
    Conc(ponto, :) = string(0); // Elimina a concentração relativa ao ponto excluído
    clf(); // limpando a janela gráfica
    plot2d(Maximos(:,1), Maximos(:,2), -4); // novo gráfico sem o ponto deletado
    choice = messagebox("Deseja deletar algum ponto?", "modal", "info", ["Sim" "Não"]);
end

// 2) Reorganizando a tabela dos máximos, a base com os dados de absorção e a tabela com as concentrações
k = 1;
exc = 0;
for f = 1:N
    if Maximos(f, :) <> 0 then
    NovoMaximos(k, :) = Maximos(f,:);
    NovaConc(k, :) = Conc(f,:) +" " + "mol/dm^3";
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
        
// Imprimindo resultados no arquivo
messagebox("Os resultados estão impressos no console e em um arquivo de texto, o qual se encontra no mesmo diretório onde está a rotina.", "info");

remat = zeros(8 + length(valorExcluido(:,1)),1); // Matriz de impressão
remat = string(remat);
remat(1) = "=============" + " Resultados da Análise " + "=============";
remat(2) = "Nome do composto: " + nomeAmostra;
remat(size(remat)) = "=================================================";
remat(3:7,1) = ["Coeficiente Angular: " + string(X(1));"Coeficiente Linear: " + string(X(2)); "Variância: " + string(s);...
                "SD: " + string(SD); "Coeficiente de correlação linear (r^2): " + string(r)];

for ij = 1:length(valorExcluido(:,1)) // Adicionando os valores excluídos à matriz de impressão
remat(7+ij) = "Valor de Absorção Excluida: " + string(valorExcluido(ij, 2)) + " | Posição (valor de x): " +...
                 string(valorExcluido(ij, 1));
end

//d = 0;
//while d <> 1 then
//    try
    resultados = file('open', 'Resultados_' + nomeAmostra + '.txt', 'new');
    write(resultados, remat);
    file('close', resultados);
//    d = 1;
//    catch
//        messagebox("Oops! Provavelmente você esqueceu de remover o arquivo antigo! Remova-o e digite no console para prosseguir!");
//    input("Quando tiver terminado, pressione qualquer tecla para prosseguir -> ");
//    end
//end
//
// Impressão no console
disp("============= Resultados da Análise =============");
disp("Nome da Amostra: " + nomeAmostra);
disp("Coeficiente Angular: " + string(X(1)));
disp("Coeficiente Linear: " + string(X(2)));
disp("Variância: " + string(s));
disp("SD: " + string(SD));
disp("Coeficiente de correlação linear (r^2): " + string(r));

for jk = 1:length(valorExcluido(:,1)) // Imprimindo no console os pontos excluídos
    disp("Valor de Absorção Excluida: " + string(valorExcluido(jk, 2)) + " |Posição: " + string(string(valorExcluido(jk, 1))));
end
disp("=================================================");
    
// Gráfico de Absorção
scf(); // Nova janela gráfica
for i =1:N - exc
//    scf(i); // O comando scf permite plotar gráficos em janelas separadas
    estilo(i) = i;
    plot2d(NovaBase(:, 1), NovaBase(:,i+1), style = estilo(i));
end
//     Edição do gráfico
    legends(NovaConc(:,2),[1:1:i], font_size = 3, opt = 1);
    a = gca();
    a.x_label.text = "nm";
    a.y_label.text = "Abs";
    a.x_label.font_size = 3;
    a.y_label.font_size = 3;
    
// ------------------------------------------
