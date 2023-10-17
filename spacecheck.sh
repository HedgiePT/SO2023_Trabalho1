#!/usr/bin/env bash

################################
# Escrever mensagens de ajuda ##
################################

function help_usage()
{
    echo "Utilização: $0 [parâmetros] diretório"
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
    echo "$0: Não foi possível criar um ficheiro temporário para a var \$$1"
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
out_sort_invert=false
out_max_lines=-1


while getopts "n:d:s:arl:" optparam; do
    case $optparam in
        n ) filter_fileName_regexp=${OPTARG} ;;
        d ) filter_maxModifiedTime=${OPTARG} ;;
        s ) filter_minSize=${OPTARG} ;;
        a ) out_sort_mode=$SORT_COLUMN_FILE_NAME ;;
        r ) out_sort_invert=true ;;
        l ) out_max_lines=${OPTARGS} ;;
        ? ) bad_parameter ;;
    esac
done


# Diretório pedido (último argumento)
root_directory=${@:$OPTIND:1}

if [[ -z "$root_directory" ]]; then
    echo "$0: ERRO: Não foi especificado nenhum diretório."
    bad_parameter
fi


###########################################
# Processar diretórios e calcular espaço ##
###########################################

# Criar ficheiro temporário
temp=$(mktemp) || temp=".spacecheck-$$.temp" || no_temp_file "temp"

function fetch_list_and_grep
{
    # ARGUMENTOS:
    #   - $1: diretório a listar.
    
    ls -l "$1" > $temp
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local tmpfilter=$(mktemp) || local tmpfilter=".spacecheck-$$-filter.temp" || no_temp_file "tmpfilter"
    grep $filter_fileName_regexp $temp > $tmpfilter
    mv $tmpfilter $temp
    
    return 0
}

function process_directory
# ARGUMENTOS:
#   - $1: diretório a processar.
{
    #FIXME: print $NF não funciona.
    local subdirs=$(ls -l '--quoting-style=escape' "$1" | grep ^d | awk '{print $NF}')
    echo "DEBUG: subdirs: $subdirs"
    
    for dir in $subdirs
    {
        process_directory "$1/$dir"
    }
    
}

process_directory $root_directory
