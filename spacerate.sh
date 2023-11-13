#!/usr/bin/env bash

###############################################################################
# FIXME!    FIXME!    FIXME!    FIXME!    FIXME!    FIXME!    FIXME!    FIXME!#
#                                                                             #
# * Não faço ideia do que acontece quando um diretório tem tamanho "NA".      #
#                                                                             #
###############################################################################

################################
# Escrever mensagens de ajuda ##
################################

function help_usage
{
    echo "Utilização: $0 [parâmetros] relatório_novo relatório_velho" >&2
}

function help_expanded
{
    echo -e "\
$0: Um script que analiza a evolução do tamanho de diretórios.

Utilização: $0 [parâmetros] relatório_novo relatório_velho.

Parâmetros:
\t-a\tOrdenar por nome. Sem esta opção, o relatório é ordenado por tamanho.
\t-r\tInverter ordenação.
\t-l N\tMostrar apenas as primeiras N linhas do relatório. (O cabeçalho não
\t\tconta para este limite e é sempre impresso.)
\t-h\tMostra esta ajuda.">&2

    exit 0
}

####################
# Em caso de erro ##
####################

EXIT_CODE_SUCCESS=0
EXIT_CODE_BAD_PARAMETER=1
EXIT_CODE_BAD_ARGUMENT=2
EXIT_CODE_UNEXPECTED_ERROR=255

function bad_parameter
{
    help_usage
    exit $EXIT_CODE_BAD_PARAMETER
}

function no_temp_file
{
    echo "$0: Não foi possível criar um ficheiro temporário para a var \$$1" >&2
    exit $EXIT_CODE_UNEXPECTED_ERROR
}


######################################################################
# Processar argumentos passados na linha de comandos (-n, -d, etc.) ##
######################################################################

# Constantes para ajudar
SORT_COLUMN_FILE_SIZE=1
SORT_COLUMN_FILE_NAME=2
SORT_COLUMN_DEFAULT=$SORT_COLUMN_FILE_SIZE

# Variáveis
out_sort_by_name=0
out_sort_invert=0
out_max_lines=-1


# FIXME: Detetar argumentos inválidos.
while getopts "arl:h" optparam; do
    case $optparam in
        a ) out_sort_by_name=1 ;;
        r ) out_sort_invert=1 ;;
        l ) out_max_lines=${OPTARG} ;;
        h ) help_expanded ;;
        ? ) bad_parameter ;;
    esac
done


for i in "$@"
{
    echo "DEBUG: PARAM: $i" >&2
}

if ((OPTIND+1 != $#)); then
    echo "$0: ERRO: Não foram especificados dois relatórios." >&2
    help_usage
    exit $EXIT_CODE_BAD_ARGUMENT
fi

######################################################################
# Carregar relatórios para arrays associativos (dicionários)  ########
######################################################################

report_new="${@:$OPTIND:1}"
report_old="${@:$((OPTIND+1)):1}"

declare -A new
declare -A old

echo "A carregar o relatório novo..." >&2
while read -r line; do
    size=$(cut -d ' ' -f 1 <<<$line)
    dir=$(cut -d ' ' -f 2- <<<$line)

    new[$dir]=$size
done < <(tail -n +2 "${report_new[*]}")

echo "A carregar o relatório velho..." >&2
while read -r line; do
    size=$(echo $line | cut -d ' ' -f 1)
    dir=$(echo $line | cut -d ' ' -f 2-)

    old[$dir]=$size
done < <(tail -n +2 "${report_old[*]}")

#echo "DEBUG: new:"$'\n'"${!new[@]}" >&2
#echo "DEBUG: old:"$'\n'"${!old[@]}" >&2

#################################################
# Comparar dicionários e processar diferenças   #
#################################################

declare -A where
declare diff=""

echo "A construir lista de diretórios presentes no relatório novo..." >&2
for dir in "${!new[@]}"
{
    where[$dir]=$((1))
}

echo "A construir lista de diretórios presentes no relatório velho..." >&2
for dir in "${!old[@]}"
{
    where[$dir]=$((where[$dir] + 2))
}

echo "A comparar tamanhos..." >&2
for dir in "${!where[@]}"
{
    #echo "DEBUG: where:"$'\n'"DIR | VALUE"$'\n'"$dir | ${where[$dir]}" >&2
    #echo "new=${new[$dir]}; old=${old[$dir]}" >&2
    size=$((new[$dir] - old[$dir]))
    #echo -e "$size\n" >&2
    
    if ((where[$dir] == 3)); then   # Diretório existe em ambos os relatórios.
        suffix=$''
    elif ((where[$dir] == 2)); then  # Dir existe só no relatório velho.
        suffix=$' REMOVED'
    else    # Diretório existe apenas no relatório mais recente.
        suffix=$' NEW';
    fi

    IFS=$'\n' diff=("${diff[*]}""$size $dir$suffix"$'\n')
}

echo "A ordenar resultados..." >&2
declare -a sort_options=()

if ((out_sort_by_name)); then
    sort_options+=($'-k2')
else
    sort_options+=($'-nk1,1')
fi

if ((out_sort_invert == out_sort_by_name)); then
    sort_options+=($'-r')
fi

#   echo "DEBUG: sort_options: ${sort_options[@]}"
IFS=$'\n' diff=$(sort ${sort_options[*]} <<<${diff[*]})

if ((out_max_lines > -1)); then
    diff=$(head -n $out_max_lines <<<${diff[*]})
fi

echo "A imprimir resultados..." >&2
echo "SIZE NAME"
IFS='\n' cat <<<${diff[*]}
