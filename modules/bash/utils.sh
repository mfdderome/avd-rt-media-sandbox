#!/bin/bash
# Author MFDD + ChatGPT <3

#########################################################################################################
#                                                Utils                                                  #   
#########################################################################################################

function _get_git_root() {
    git rev-parse --show-toplevel
}

function _get_collection_path_from_cfg() {
    if command -v ansible &>/dev/null; then
        ANSIBLE_CONFIG=$(ansible --version | grep "config file")
        ANSIBLE_CONFIG_PATH=$(echo "$ANSIBLE_CONFIG" | sed 's/  config file = //')
        COLLECTIONS_PATH=$(sed -n 's/^collections_paths *= *//p' "$ANSIBLE_CONFIG_PATH")
        # COLLECTIONS_PATH=$(awk -F' = ' '/^collections_paths/ {print $2}' "$ANSIBLE_CONFIG_PATH")
        echo "$COLLECTIONS_PATH"
    else
        echo "Ansible is not installed or not in your PATH."
    fi
}

# A function that print a line break by multying '*' by the length of your shell
function _lbreak() {
    local color_code=${1:-37}
    echo -ne "\e[${color_code}m$(printf '%*s\n' "$(tput cols)" | tr ' ' '=')\e[0m"
}

# A print function that use cowsay only if installed 🐮
function _moo() {
    command -v cowsay &>/dev/null && echo -ne "$1" | cowsay -snW "$(tput cols)" || echo -ne "$1"
}

# A print function that use figlet only if installed
function _fig() {
    command -v figlet &>/dev/null && echo -ne "$1" | figlet -w "$(tput cols)" || echo -ne "$1"
}

# A print function that use figlet only if installed + ascii support 🌈
function _cfig() {
    # """
    # Black        0;30     Dark Gray     1;30
    # Red          0;31     Light Red     1;31
    # Green        0;32     Light Green   1;32
    # Brown/Orange 0;33     Yellow        1;33
    # Blue         0;34     Light Blue    1;34
    # Purple       0;35     Light Purple  1;35
    # Cyan         0;36     Light Cyan    1;36
    # Light Gray   0;37     White         1;37
    # """
    local color_code=$1
    shift
    command -v figlet &>/dev/null && echo -ne "\e[${color_code}m$(figlet -w "$(tput cols)" $@)\e[0m\n" || echo -ne "$1"
}

function _ls_octal_perm() {
    echo "$(stat -c "%a" "${1}") $(ls -l "${1}")"
}

function _is_array() {
    [[ "$(declare -p dirs)" =~ "declare -a" ]];
}

function _is_valid_usb_device() {
    # Check if the argument is provided
    if [ $# -eq 0 ]; then
        echo "Usage: is_valid_usb_device <device_path>"
        return 1
    fi

    device_path=$1

    # Check if the device path exists
    if [ ! -e "$device_path" ]; then
        echo "Device path $device_path does not exist."
        return 1
    fi

    # Check if the device is a block device
    if [ ! -b "$device_path" ]; then
        echo "Device at $device_path is not a block device."
        return 1
    fi

    # Get the symbolic links associated with the device
    symbolic_links=$(udevadm info -n "$device_path" -q symlink)

    # Iterate through each symbolic link and check if it matches the USB pattern
    found_usb_link=false
    while read -r link; do
        if [[ $link =~ usb-.*-0:0 ]]; then
            found_usb_link=true
            break
        fi
    done <<< "$symbolic_links"

    if [ "$found_usb_link" = false ]; then
        echo "Device at $device_path is not associated with a USB device."
        return 1
    fi

    # Check if the device is connected
    if ! lsblk -n -o NAME | grep -q "$(basename $device_path)"; then
        echo "Device at $device_path is not connected."
        return 1
    fi

    echo "Device at $device_path is a valid and connected USB device."
    return 0
}

# Function to check for intersections between two arrays
function _is_any() {
    # Loop through the elements of all arrays and store them an associative array
    i=0
    for array_name in "$@"; do
        # Decalre the associative array name variable using loop index
        ((i++)); declare -n "aarray${i}"="$array_name" 
        # Declare an associative array local to the loop to print it to the shell
        declare -n aarray="aarray${i}"
    done

    # Declare a global empty array to store intersections found
    declare -ag intersections=()

    # Loop through the elements of all associative arrays to check for intersections
    for item in "${aarray1[@]}"; do
        for check_item in "${aarray2[@]}"; do
            # Append found intersection to the global empty array using simple if statement 
            if [[ "$item" == "$check_item" ]]; then
                intersections+=("$item")
            fi
        done
    done
    
    if [ "${#intersections[@]}" -ne 0 ]; then
        # Declare a global var to store the intersections founs as a string
        declare -g intersections_str="${intersections[@]}"
        return 0  # Item found in both lists
    else
        unset -n intersections
        return 1  # Item not found in both lists
    fi
}

function _is_valid_foo() {
    foo="$1"
    if ! compgen -A function | grep -q $foo ; then
        echo -e "$lheadr Error:   The argument $foo is not a valid function!"
        _upromt "$lheady Prompt:  Would you like to print out the help in the shell?"
        if [[ $? -eq 0 ]]; then help -ls; fi
        return 1
    else
        return 0
    fi
}

function _is_env_compliant() {
    # Decalre an associative array for required environment variables ⭐
    declare -n required_env_aarray="$1"

    # Check if any required environment variable is missing
    for env_var in "${required_env_aarray[@]}"; do
        if [[ -z "${!env_var}" ]]; then
            echo -e "$lheadr Error:   Required environment variable '$env_var' is not set."
            echo -e "$help_env\n$signature"
            exit 1
        else
            echo -e "$lheadg Succeed: Required environment variable '$env_var' is set."
        fi
    done
}

function _is_run_as_root() {
    # Check if script is run as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "$lheadr Error:   This script must be run as root."
        exit 1
    fi
}

function _get_sudoer() {
  if [[ -n $SUDO_USER ]]; then
    current_user=$SUDO_USER
  elif [[ -n $LOGNAME ]]; then
    current_user=$LOGNAME
  else
    current_user=$USER
  fi

  echo "$current_user"
}

function _get_sudoer_group() {
    local sudoer_user="$(_get_sudoer)"
    echo "$sudoer_user:$(id -gn "$sudoer_user")"
}

# function to run a command as sudoer
function _run_as_sudoer() {
    local sudoer=$(_get_sudoer)
    su -c "$1" -s $SHELL $sudoer
}

# function to run a command as sudo with option -u
function _run_as_sudosu() {
    local sudoer=$(_get_sudoer)
    sudo -S -u $sudoer $SHELL -c "$1"
}

# function to run a command as sudo with option -u using custom password prompt
function _run_as_sudosu_cpp() {
    local sudoer=$(_get_sudoer)
    local custom_password_prompt=${2:-"Enter sudoer's password for <$sudoer>: "}
    read -s -p "$custom_password_prompt" sudo_password
    echo && echo "$sudo_password" | sudo -S -u $sudoer $SHELL -c "$1"
}

function _upromt() {
    read -ra choicesArray <<< "${2:-"Y n"}"
    choicesArray+=("q")
    choices=$(printf "%s/" "${choicesArray[@]}")
    read -p "$(printf '%b' "$1") [${choices%/}]: " response

    # if [[ " $(IFS='|'; echo "$2") " == *" $response "* ]]; then # case-sensitive
    if [[ " $(IFS='|'; echo "${2,,}") " == *" ${response,,} "* ]]; then # case-insensitive
        declare -g response="$response"
        return 0
    elif [[ -z "$response" ]]; then
        declare -g response="${choicesArray[0]}"
        return 0
    elif [[ "$response" =~ ^[Yy]$ ]] && [[ -z "$2" ]]; then
        return 0
    elif [[ "$response" =~ ^[Nn]$ ]] && [[ -z "$2" ]]; then
        return 1
    elif [[ "$response" =~ ^[Qq]$ ]]; then 
        _moo "Exited by the user!"
        exit 0
    else
        _upromt "$1" "$2"
    fi
}

function _select_file() {
    local dir="$1"
    local filter=${2:-".*"}
    declare -g selected_file=""
    
    if [[ ! -d "$dir" ]]; then
        echo -e "$lheadr Error:   Invalid directory: $dir"
        return 1
    fi

    local files=( $(ls "$dir"/* | grep -P "$filter") )    
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "$lheadr Error:   No files found in directory: $dir"
        return 1
    fi
    
    PS3="${lheady} Prompt:  Select a file (enter the number, or 'q' to quit): "
    options=("${files[@]}" "Quit")
    
    select file in "${options[@]}"; do
        if [[ "$REPLY" =~ ^[Qq]$ || "$file" == "Quit" ]]; then
            _moo "Exited by the user!"
            exit 0
        elif [[ -n "$file" ]]; then
            declare -g selected_file="$file"
            return 0
            break
        else
            echo -e "$lheadr Error:   Invalid selection. Please try again."
        fi
    done
}

function _browse_file() {
    local initial_path=${1:-"/"}
    local dialog_width=$(($(tput cols) - 10))
    local dialog_height=20
    local file_choice=""
    declare -g selected_path=""

    while true; do
        file_choice=$(dialog --stdout --title "File Browser" --fselect "$initial_path" $dialog_height $dialog_width)
        
        # Check if the user canceled the selection
        if [ -z "$file_choice" ]; then
            tput reset # reset shell
            echo -e "$lheady Verbose: Selection canceled."
            return 1
        fi
        
        if [ -e "$file_choice" ]; then
            tput reset # reset shell
            declare -g selected_path="$file_choice"
            return 0
            break
        else
            dialog --msgbox "Selected path does not exist." 8 40
        fi
    done
}

function _retention() {
    parent_directory="$1"
    if [ -z "$parent_directory" ]; then
        echo "Please provide a parent directory."
        return 1
    fi

    if [ ! -d "$parent_directory" ]; then
        echo "The specified directory does not exist: $parent_directory"
        return 1
    fi

    # List all child directories and sort them by modification time (newest first)
    child_directories=($(find "$parent_directory" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -nr | awk '{print $2}'| grep -vE 'work'))

    # Keep the three latest directories, delete the rest
    i=0
    for dir in "${child_directories[@]}"; do
        if [ $i -lt 3 ]; then
            ((i++));
        else
            echo "Deleting: $dir"
            rm -rf "$dir"
        fi
    done
}

# Function to copy files and directories while following symbolic links (copy nested symlinks)
function _follow_symlinks() {
  local source="$1"
  local destination="$2"

  for item in "$source"/*; do
    local item_name
    item_name=$(basename "$item")

    if [ -L "$item" ]; then
      # Copy symbolic links
      cp -RL "$item" "$destination/$item_name"
    elif [ -d "$item" ]; then
      # Copy directories recursively
      mkdir -p "$destination/$item_name"
      _follow_symlinks "$item" "$destination/$item_name"
    elif [ -f "$item" ]; then
      # Copy regular files
      cp "$item" "$destination/$item_name"
    fi
  done
}

function _insert_substring() {
    local originalString=${1:-"archlinux-2023.08.31-x86_64.iso"}
    local substringToInsert=${2:-"-dell_p5520-zfs"}
    local substring1=${3:-"x86_64"}
    local substring2=${4:-".iso"}
    local renamedString="$(echo "$originalString" | sed "s/$substring1\(.*\)$substring2/$substring1$substringToInsert$substring2/")"

    echo "$renamedString"
    return 0 
}

function _trim() {
    original_string=$1
    # Remove leading and trailing spaces using parameter expansion
    trimmed_string="${original_string#"${original_string%%[![:space:]]*}"}"
    trimmed_string="${trimmed_string%"${trimmed_string##*[![:space:]]}"}"
    echo "$trimmed_string"  
}

function _pass() { :; }

function _try() {
    declare -n msg_array="$1"
    local action_msg_array=("${msg_array[@]}")
    local action_msg_array[0]="${action_msg_array[0]}..."
    local cmd="$2"
    shift 2

    echo -e "$lheadb Action:  $(printf "%s\n" "${action_msg_array[@]}")"
    echo -e "$lheadb Command executed:\n$lhead2 ``\u001b[34m$cmd "$@"\u001b[0m``"
    if $cmd "$@"; then
        echo -e "$lheadg Succeed: $msg_array!"
        return 0
    else
        echo -e "$lheadr Error:   $msg_array! Shit happens..."
        return 1
    fi
}

function _die() {
    echo -e "$lheadr Error!\n    Shit happen while $1"
    exit 1
}

#########################################################################################################
#                                                 Help                                                  #   
#########################################################################################################

declare -g lhead=$'==>'
declare -g lheadr=$'\u001b[31m==>\u001b[0m'
declare -g lheadg=$'\u001b[32m==>\u001b[0m'
declare -g lheady=$'\u001b[33m==>\u001b[0m'
declare -g lheadb=$'\u001b[34m==>\u001b[0m'
declare -g lhead2=$'\u001b[34m  ->\u001b[0m'
declare -g lhead3=$'\u001b[34m\t->\u001b[0m'
declare -g signature="\n\033[1;30m\033[3m@MFDD + ChatGPT\033[0m \xE2\x9D\xA4"
declare -g now=$(date +"%Y%m%d_%H%M%S")
declare -g script_name=$0 #"${BASH_SOURCE[0]}"

function help_case() {
    # Get the current script's name where the function resides and declare local vars
    local start_line
    local end_line

    # Find the line numbers where the 'case' statement starts and ends ⭐
    if ! start_line=$(grep -n -m 1 "^[[:space:]]*case" "$script_name" | cut -d':' -f1); then
        echo "No 'case' statement found in the script."
        return 1
    fi
    if ! end_line=$(grep -n -m 1 "^[[:space:]]*esac" "$script_name" | cut -d':' -f1); then
        echo "No 'esac' found to close the 'case' statement."
        return 1
    fi

    # Extract the desired range of lines using sed
    local range="${start_line},${end_line}"
    sed -n "${range}p" "$script_name" | grep -P '^    ".*"\)'
}

function help_foos() {

    # Get a list of all function names in the script except if help or start with an underscore
    local args=($(printf "%s\n" "$@" | grep -vE \\'--help|-h')) # ⭐⭐
    local declared_foos=($(declare -F | cut -d ' ' -f 3- | grep -vE '^(help|_[^[:space:]]+)')) # ⭐⭐

    # Decision tree for the help_foos() function arguments 
    if _is_any args declared_foos; then
        _lbreak "1;37"
        echo -ne "$lhead Help:    Selected function(s) 👇\n\n"
        local selected_foos="${intersections[@]}"
        #echo "$intersections_str" | tr ' ' '\n'            # Uncomment to debug 🩺
    elif [[ $args = "-la" ]]; then
        _lbreak "1;37"
        echo -ne "$lhead Help:    Detailed list of available functions 👇\n\n"
        local selected_foos="${declared_foos[@]}"
        #echo "${declared_foos[@]}" | tr ' ' '\n'           # Uncomment to debug 🩺
    elif [[ $args = "-ls" ]]; then
        _lbreak "1;37"
        echo -ne "$lhead Help:    List of available functions 👇\n\n"
        echo -ne "\e[37m---------------------\e[0m\n"
        for foo in "${declared_foos[@]}"; do echo "$foo"; done
        echo -ne "\e[37m---------------------\e[0m\n"
        return 0
    else
        return 1
    fi

    # Iterate over the function names if the array $selected_foos is declared by the decision tree
    if declare -p selected_foos &>/dev/null; then
        echo -ne "\e[37m---------------------\e[0m\n"
        for foo in $selected_foos; do

            # Get the function definition and extract the docstring from the function definition
            local foo_definition=$(declare -f $foo)
            local docstring=$(echo "$foo_definition" | awk '/local docstring=.*"""/ {p=1; print $0} /"""/ {p=0} p {print $0}')

            # Print the function name and, only if present, the docstring as well
            echo "Function: $foo"
            if [ -n "$docstring" ]; then
                echo -ne "\n$docstring\n"
            else
                echo "No docstring found."
            fi
            echo -ne "\e[37m---------------------\e[0m\n"

        done
        return 0
    fi
}

function help() {

    local help=$(cat <<EOF
$(_lbreak "1;37")
$lhead Help:     This is a dynamic help message 🤓

    Usage:
        
        $(echo $script_name) <option>

    Options:

    "-h" | "--help") <"-ls" | "-la">        # Help option (Can be combines with other arguments)
$(help_case)
    *)                                      # Allow to provide a foo as script argument instead of an option ⭐

$(help_foos $@ || (printf %s ""))

$(_lbreak)$signature\n
EOF
)

echo -e "$help"
exit 0
}

# Check if any argument is equal to '-h' or '--help' and print out the help
for arg in "$@"; do [[ "$arg" =~ ^(-h|--help)$ ]] && help $@; done