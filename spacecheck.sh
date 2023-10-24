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
# FIXME: Temos de suportar vários diretórios pedidos.
root_directory=${@:$OPTIND:1}

if [[ -z "$root_directory" ]]; then
    echo "$0: ERRO: Não foi especificado nenhum diretório." >&2
    bad_parameter
fi


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
    declare -a subdirs
    
    echo "DEBUG: Entering directory $search_dir" >&2
    
    for entry in "$search_dir"/*
    {
        echo -e "DEBUG:\tEntry: $entry" >&2
        
        if [[ -h $entry ]];
            then echo -e "DEBUG:\t\tIs symlink." >&2; continue    # Filtrar symlinks.
        elif [[ -f $entry ]];
                then echo -e "\t\tIs file." >&2
                if [[ ! ($entry =~ "$filter_fileName_regexp") ]];
                    then echo -e "DEBUG:\t\tDIDN'T MATCH Regexp!" >&2
                    continue
                fi
                
                dir_size=$(echo "$dir_size" +\
                                 $(wc -c "$entry" | awk '{ print $1 }')\
                           | bc)
        elif [[ -d $entry ]];
            then echo -e "DEBUG:\t\tIs directory." >&2; subdirs+=("$entry")
        else
            echo -e "DEBUG:\t\tISTO NÃO DEVIA ACONTECER!" >&2
        fi
    }

    for d in "${subdirs[@]}"
    {
        local sub_size=0;
        dir_size=$(echo "$dir_size + $(process_directory $d)" | bc)
    }

    echo "DEBUG: dir_size: $dir_size" >&2
    echo -e "$search_dir\t$dir_size" >> $temp
    echo $dir_size
}

process_directory $root_directory > /dev/null
echo "==============================="
echo "Outputting temp file $temp:"
cat $temp
