RELATÓRIO DE PROGRESSO  e  LISTA DE AFAZERES
==========================================================

# spacecheck.sh
* IMPORTANTE:
    * Imprimir `NA` na coluna do espaço ocupado por diretórios aos quais não conseguimos aceder.
    * Verificar se argumentos estão corretos. (Por exemplo, `-l AAA` não faz sentido.)
    * Opção `-n`: filtrar APENAS pelo nome do ficheiro, e não olhar ao caminho completo.
        * Isto é, com `-n ".*conf`:
            * **OK:** /home/cenas/zsh.conf
            * **ERRADO:** /home/cenas/.gsn3.conf/LastProject (o nome do *ficheiro* não acaba em conf)
* Porreiro:
    * Melhorar desempenho
