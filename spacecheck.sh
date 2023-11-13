#!/usr/bin/env bash

###############################################################################
# FIXME!    FIXME!    FIXME!    FIXME!    FIXME!    FIXME!    FIXME!    FIXME!#
#                                                                             #
# * Se um ficheiro não for acessível, mas for filtrado pelo grep, não         #
#   deveriamos entrar no estado "failed" (i.e. escrever "NA" no tamanho       #
#   ocupado).                                                                 #
#                                                                             #
###############################################################################

################################
# Escrever mensagens de ajuda ##
################################

function help_usage()
{
    echo "Utilização: $0 [parâmetros] diretório [diretório ...]
Use -h para obter mais ajuda." >&2
}

function help_expanded
{
    echo -e "\
$0: Um script que analiza a ocupação do espaço de diretórios.

Utilização: $0 [parâmetros] diretório [diretório ...].
Pode especificar mais do que um diretório.

Parâmetros:
  Filtro:
\t-n REXP\tFiltrar análise por expressão regular. Apenas os ficheiros que
\t\tcorrepondam a REXP serão contabilizados.
\t-d DATA\tFiltra análise por data de modificação máxima. Ficheiros modificados
\t\tpela última vez numa data mais antiga não serão contabilizados.
\t-s TAMN\tFiltra a análise por tamanho máximo. Ficheiros mais pequenos não
\t\tserão contabilizados.

  Formatação do resultado:
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

function bad_argument
{
    echo "opção -$1: o argumento '$2' é inválido." >&2
    exit $EXIT_CODE_BAD_ARGUMENT
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

# Variáveis
filter_fileName_regexp=""
filter_maxModifiedTime=""
filter_minSize=1
out_sort_by_name=0
out_sort_invert=0
out_max_lines=-1

# Expressão regular para testar números
re_num='^[0-9]+$'

while getopts "n:d:s:arl:h" optparam; do
    case $optparam in
        n ) filter_fileName_regexp=${OPTARG} ;;
        d ) filter_maxModifiedTime=${OPTARG}
            if ! date -d "${OPTARG[@]}" &> /dev/null; then
                bad_argument $optparam "${OPTARG[@]}"
            fi
            ;;
        s ) filter_minSize=${OPTARG}
            if [[ ! $OPTARG =~ $re ]] || ((OPTARG < 1)); then
                bad_argument $optparam ${OPTARG[@]};
            fi
            ;;
        a ) out_sort_by_name=1 ;;
        r ) out_sort_invert=1 ;;
        l ) out_max_lines=${OPTARG}
            if [[ ! $OPTARG =~ $re ]] || ((OPTARG < 1)); then
                bad_argument $optparam ${OPTARG[@]}
            fi
            ;;
        h ) help_expanded ;;
        ? ) bad_parameter ;;
    esac
done


##########################################################################
# Garantir que pelo menos um diretório foi especificado pelo utilizador. #
##########################################################################

if ((OPTIND > $#)); then
    echo "ERRO: Não foi especificado nenhum diretório." >&2
    help_usage
    exit $EXIT_CODE_BAD_ARGUMENT
fi


###########################################
# Processar diretórios e calcular espaço ##
###########################################

# Criar ficheiro temporário
temp=$(mktemp) || temp=".spacecheck-$$.temp" || no_temp_file "temp"

#
if [[ -n $filter_maxModifiedTime ]]; then
    find_arg_newer="-not -newermt $filter_maxModifiedTime"
fi

function process_directory
# ARGUMENTOS:
#   - $1: diretório a processar.
{
    declare -i failed=$((0))
    local search_dir=$1
    local dir_size=0
    
    echo "A examinar: $search_dir" >&2
    
    ####### Iterar sobre ficheiros #######
    dir_size=$(\
        find "$search_dir" -maxdepth 1 -type f -size "+0$((filter_minSize-1))c"\
        $find_arg_newer -printf '%s\t%f\0'\
        | grep -z "[[:digit:]+][[:space:]]$filter_fileName_regexp"\
        | cut -zf 1\
        | { tr '\0' '+'; echo '0' ;} \
        | bc;
        return ${PIPESTATUS[0]}
        )

    failed=$?
    #echo "DEBUG: failed=$failed" >&2

    ####### Iterar sobre sub-diretórios #######
    while IFS= read -d $'\0' d; do
        declare -i sub_size=$(process_directory "$d")
        dir_size=$((dir_size + sub_size))
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d -print0)

    if ((failed)); then
        dir_size=""
    fi

    ####### Imprimir resultado #######
    echo -en "${dir_size:-NA} $search_dir\0" >> $temp     # Copiar p/ ficheiro
    echo ${dir_size:-$((0))}                                # "Devolver" valor
}

function sort_and_filter
{
    declare -a sort_options=()

    if ((out_sort_by_name)); then
        sort_options+=('-k2')
    else
        sort_options+=('-nk1,1')
    fi

    if ((out_sort_invert == out_sort_by_name)); then
        sort_options+=('-r')
    fi

 #   echo "DEBUG: sort_options: ${sort_options[@]}"
    sort $temp -z ${sort_options[@]} -o $temp

    if [[ $out_max_lines -gt $((-1)) ]]; then
#        echo "DEBUG: max_lines: $out_max_lines"
        headtemp=$(mktemp) || headtemp=".spacecheck-$$.temp" || no_temp_file "headtemp"
        head -z -n "$out_max_lines" $temp > $headtemp
        mv $headtemp $temp
    fi
}

for ((i = OPTIND; i <= $#; i++))
{
    process_directory "${@:$i:1}" > /dev/null
}

sort_and_filter

echo "SIZE NAME $(date +%Y%m%d) ${@:1}"
cat $temp | sed -ze "s/\n/\\\\n/g" | sed -e "s/\\x0/\\n/g"
rm $temp

#echo "==============================="
#echo "Outputting temp file $temp:"
# cat "$temp"
