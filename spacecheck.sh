#!/usr/bin/env bash

################################
# Escrever mensagens de ajuda ##
################################

function help_usage()
{
    echo "Utilização: $0 [parâmetros] diretório" >&2
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
filter_fileName_regexp=""
filter_maxModifiedTime=""
filter_minSize=""
out_sort_mode=$SORT_COLUMN_DEFAULT
out_sort_invert=0
out_max_lines=-1


# FIXME: Detetar argumentos inválidos.
while getopts "n:d:s:arl:" optparam; do
    case $optparam in
        n ) filter_fileName_regexp=${OPTARG} ;;
        d ) filter_maxModifiedTime=${OPTARG} ;;
        s ) filter_minSize=${OPTARG} ;;
        a ) out_sort_mode=$SORT_COLUMN_FILE_NAME ;;
        r ) out_sort_invert=1 ;;
        l ) out_max_lines=${OPTARG} ;;
        ? ) bad_parameter ;;
    esac
done


for i in "$@"
{
    echo "DEBUG: PARAM: $i" >&2
}


###########################################
# Processar diretórios e calcular espaço ##
###########################################

# Criar ficheiro temporário
temp=$(mktemp) || temp=".spacecheck-$$.temp" || no_temp_file "temp"

function process_directory
# ARGUMENTOS:
#   - $1: diretório a processar.
{
    local search_dir=$1
    local dir_size=0
    
    echo "DEBUG: Entering directory $search_dir" >&2
    
    ####### Iterar sobre ficheiros #######
    while IFS= read -d $'\0' entry;
    do
        echo -e "DEBUG:\tEntry: $entry" >&2
        entry_wc=$(wc -c "$entry")
        
        if [[ $? ]]; then
            entry_size=$(echo $entry_wc | awk '{ print $1 }')
            echo -e "DEBUG:\t\tSIZE: $entry_size" >&2
            dir_size=$(echo "$dir_size + $entry_size" | bc)
        else
            echo -e "DEBUG:\t\tERRO DE ACESSO!" >&2
        fi
    done < <(find "$search_dir" -maxdepth 1 -type f -size "+0${filter_minSize}c" -not -newermt "$filter_maxModifiedTime" -print0 | grep -z "$filter_fileName_regexp")

    ####### Iterar sobre sub-diretórios #######
    while IFS= read -d $'\0' d; do
        declare -i sub_size=$(process_directory "$d")
        dir_size=$((dir_size + sub_size))
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d -print0)

    echo "DEBUG: dir_size: $dir_size" >&2
    #IFS= printf "%d$nextPart%s\0" $dir_size $search_dir >> $temp
    echo -en "$dir_size $search_dir\0" >> $temp
    echo $dir_size
}

function sort_and_filter
{
    declare -a sort_options=()

    if [[ $out_sort_mode -eq $SORT_COLUMN_FILE_NAME ]]; then
        sort_options+=('-k2')
    elif [[ $out_sort_mode -eq $SORT_COLUMN_FILE_SIZE ]]; then
        sort_options+=('-nk 1,1')
    else
        echo "ERRO: Coluna desconhecida."
        exit EXIT_CODE_UNEXPECTED_ERROR
    fi

    echo "DEBUG: out_sort_invert = $out_sort_invert"
    if [[ $out_sort_invert -eq 0 ]]; then
        sort_options+=('-r')
    fi

    echo "DEBUG: sort_options: ${sort_options[@]}"
    sort $temp -z ${sort_options[@]} -o $temp

    if [[ $out_max_lines -gt $((-1)) ]]; then
        echo "DEBUG: max_lines: $out_max_lines"
        headtemp=$(mktemp) || headtemp=".spacecheck-$$.temp" || no_temp_file "headtemp"
        head -z -n "$out_max_lines" $temp > $headtemp
        mv $headtemp $temp
    fi
}

requested_dirs=${@:$OPTIND}

if [[ -z $requested_dirs ]]; then
    echo "$0: ERRO: Não foi especificado nenhum diretório." >&2
    bad_parameter
fi

for dir in $requested_dirs
{
    process_directory "$dir" > /dev/null
}


sort_and_filter
echo "SIZE NAME $(date +%Y%m%d) ${@:1}"
cat $temp | sed -ze "s/\n/\\\\n/g" | sed -e "s/\\x0/\\n/g"
#echo "==============================="
#echo "Outputting temp file $temp:"
# cat "$temp"
