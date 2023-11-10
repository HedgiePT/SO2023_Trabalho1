#!/usr/bin/env bash

################################
# Escrever mensagens de ajuda ##
################################

function help_usage()
{
    echo "Utilização: $0 [parâmetros] relatório1 relatório2" >&2
}


function debug
{
    echo "$1" >&2
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
out_sort_mode=$SORT_COLUMN_DEFAULT
out_sort_invert=0
out_max_lines=-1


# FIXME: Detetar argumentos inválidos.
while getopts "arl:" optparam; do
    case $optparam in
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


function process_reports
# ARGUMENTOS:
#   - $1: relatório mais recente;
#   - $2: relatório mais antigo.
{
    report_new=$1
    report_old=$2
    
    declare -A new
    declare -A old
    
    while read -r line; do
        size=$(echo $line | cut -d ' ' -f 1)
        dir=$(echo $line | cut -d ' ' -f 2-)
        
        new[$dir]=$size
    done < <(tail -n +2 $1)
    
    while read -r line; do
        size=$(echo $line | cut -d ' ' -f 1)
        dir=$(echo $line | cut -d ' ' -f 2-)
        
        old[$dir]=$size
    done < <(tail -n +2 $2)
}

process_reports $1 $2
