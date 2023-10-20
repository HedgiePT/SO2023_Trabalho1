O Projeto
=========

Dois scripts em bash para monitorizar o uso de espaço no disco.


Resumo dos scripts
==================

## `spacecheck.sh` - Mostra o espaço ocupado por um diretório, seus subdiretórios e ficheiros.

### Sintaxe

`spacecheck.sh [parâmetros] diretório`

* Exemplo: `spacecheck.sh -n ".*conf" /etc`

### Parâmetros

Pode-se usar qualquer combinação (ou nenhuma) dos seguintes parâmetros.

#### Filtros

* `-n <expressão regular>`: Filtar por nome do ficheiro. Só serão processados os ficheiros cujo nome obedece à expressão regular.
    * Exemplo: `spacecheck.sh -n ".*conf"` inclui apenas os ficheiros cujo nome acaba em `conf`.

* `-d <data>`: Filtra por data máxima de modificação.
    * Exemplo: `spacecheck.sh -d "Sep 10 10:00"` inclui apenas ficheiros modificados até às 10:00 do dia 10 de setembro.

* `-s <tamanho>`: Filtra ficheiros por tamanho mínimo.
    * Exemplo: `spacecheck.sh -s 1024` inclui apenas ficheiros cujo tamanho seja maior ou igual que 1 KiB.


#### Ordenar e truncar resultado

Estes parâmetros permitem alterar a visualização do resultado do script, ordenando as linhas de várias formas ou limitando quantas linhas são geradas.

* `-a`: Ordenar lista por nome do ficheiro.
* `-r`: Inverter ordem da lista.
* `-l <número>`: Limitar resultado ao número especificado de linhas.

### Exemplo de saída (do PDF do professor)

```bash
./spacecheck.sh -n “.*sh” sop
```
```
SIZE NAME 20230910 -n .*sh sop
6723 sop
5729 sop/praticas
2668 sop/praticas/aula2
1939 sop/praticas/aula1
395 sop/teoricas
```

### Requisitos do professor

Temos de cumprir estes requisitos:

* Os resultados têm um cabeçalho: `SIZE    NAME    <Data do relatório> <Parâmetros passados>`
    * Exemplo: `SIZE NAME 20230910 -n .*sh sop`
    
* Temos de tratar corretamente ficheiros com espaços e caracteres especiais.

* Se o diretório pedido pelo utilizador não for encontrado, temos de mostrar um erro e abortar.

* Sempre que não seja possível averiguar o tamanho de um ficheiro ou diretoria, devemos escrever `NA` na coluna onde normalmente indicaríamos o espaço ocupado pelo dito ficheiro ou diretoria.
    * Isto pode acontecer, por exemplo, por falta de permissões.



## `spacerate.sh` - Mostra a evolução da ocupação do espaço em disco, através dos relatórios gerados pelo `spacecheck.sh`.

### Sintaxe

`spacecheck.sh [parâmetros] relatório1 relatório2`

* Exemplo: `./staterate.sh -r spacecheck_20230923 spacecheck_20220923`

### Parâmetros

Iguais às de ordenação do `spacecheck.sh`.

### Exemplo de saída (do PDF do professor)


```bash
./staterate.sh spacecheck_20230923 spacecheck_20220923
```
```
SIZE NAME
2668 sop/praticas/aula2 NEW
209 sop/praticas
90 sop/teoricas
0 sop/praticas/aula1
0 sop
-100 sop/dados REMOVED
```


```bash
./staterate.sh -r spacecheck_20230923 spacecheck_20220923
```
```
SIZE NAME
-100 sop/dados REMOVED
0 sop
0 sop/praticas/aula1
90 sop/teoricas
209 sop/praticas
2668 sop/praticas/aula2 NEW
```

### Requisitos do professor

Para as diretorias comuns a ambos os relatórios, é mostrada a diferença na utilização do espaço. Se houver diretorias presentes apenas num dos relatórios (indicando que foi apagado ou recém-criado), devemos indicar isso mesmo também.
