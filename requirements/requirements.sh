#!/bin/bash
#
# Author MFDD + ChatGPT <3

# Declare help string
help=$(cat <<EOF
____________________
|       Help       |
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
Usage:
    Create:      
        ./requirements.sh <virtualenv_name>
    Delete:
        ./requirements.sh --delete <virtualenv_name>
Example:
    Create:     
        ./requirements.sh avd-env-4.1.0
    Delete:
        ./requirements.sh --delete avd-env-4.1.0
Note:
  If no argument provided, the <virtualenv_name> will be set to default value -> "avd-env-3.8.x"

\n\033[1;30m\033[3m@MFDD + ChatGPT\033[0m \xE2\x9D\xA4 
EOF
)

# A print function that use cowsay only if installed
function moo() {
    command -v cowsay &>/dev/null && echo "$1" | cowsay -snW 999 || echo "$1"
}

# A function that print a line break by multying '=' by the length of your shell
function lbreak() {
    local delimiter="${1:-=}" 
    printf '%*s\n' "$(tput cols)" | tr ' ' "$delimiter"
}

function list_env_info() {
    virtualenv_name=$1
    if pyenv virtualenvs | grep -q "$virtualenv_name"; then
        if pyenv activate "$virtualenv_name"; then
            lbreak && echo -e '# pip packages' && lbreak
            pip freeze
            lbreak && echo -e '# pip version' && lbreak
            pip --version
            lbreak && echo -e '# python version && pyenv path' && lbreak
            python --version
            python -c "import sys; print(sys.executable)"
            lbreak && echo -e '# ansible-galaxy version' && lbreak
            ansible-galaxy --version
            lbreak && echo -e '# ansible-galaxy collection list' && lbreak
            ansible-galaxy collection list
            lbreak
            moo "Have fun smart ass!"
        else
            echo "==> Virtual environment <$virtualenv_name> failed to activate!"
            exit 1
        fi
    else
        echo "==> Virtual environment <$virtualenv_name> doesn't exists!"
        exit 1
    fi
}

now="$(date +%Y%m%d)_$(date +%H%M%S)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
DEFAULT_PYTHON_VERSION=3.12.3; python_version=$DEFAULT_PYTHON_VERSION
DEFAULT_AVD_VERSION="4.7.0"; avd_version=$DEFAULT_AVD_VERSION
DEFAULT_VIRTUALENV_NAME="rtm-sandbox-env" #"avd-env-${avd_version}"
DEFAULT_REQ_DIR="./requirements/${avd_version}"
DEFAULT_COLLECTION_DIR="./collections"

case "$1" in
    "")
        # Set variable with hardcoded string
        virtualenv_name=$DEFAULT_VIRTUALENV_NAME
        echo "==> First argument is empty -> Set to: $virtualenv_name"
        ;;
    "-h" | "--help")
        # Display help message
        echo -e "$help"
        exit 0
        ;;
    "-l" | "--list")
        # List environment info
        list_env_info
        exit 0
        ;;
    "-d" | "--delete")
        # Delete the virtualenv
        delete="true"
        ;;
    "-c" | "--clean")
        # Delete the virtualenv
        clean="true"
        ;;
    *)
        # Virtualenv is provided
        virtualenv_name="$1"
        echo "==> First argument provided -> Set to: $1"
        ;;
esac

# Check if pyenv, pyenv update, and pyenv virtualenv are installed
if ! command -v pyenv &> /dev/null || ! pyenv update &> /dev/null || ! pyenv virtualenv --version &> /dev/null; then
    echo "==> pyenv, pyenv update, or pyenv virtualenv is not installed or not properly configured."
    exit 1
fi

# Check if the flag `--delete` is passed and delete the concerned virtualenv if present
if [ "$delete" = "true" ]; then
    if pyenv virtualenvs | grep -q "${2:-$DEFAULT_VIRTUALENV_NAME}"; then
        # Delete the virtual environment
        lbreak && pyenv virtualenvs && lbreak
        pyenv deactivate "${2:-$DEFAULT_VIRTUALENV_NAME}"
        pyenv virtualenv-delete "${2:-$DEFAULT_VIRTUALENV_NAME}"
        echo "==> Virtual environment <${2:-$DEFAULT_VIRTUALENV_NAME}> successfully deleted!"
        [ -d "$DEFAULT_COLLECTION_DIR" ] && rm -rf "$DEFAULT_COLLECTION_DIR"
        exit 0
    else
        echo "==> Virtual environment <${2:-$DEFAULT_VIRTUALENV_NAME}> doesn't exists!"
        exit 1
    fi
# Check if the flag `--delete` is passed and delete the concerned virtualenv if present
elif [ "$clean" = "true" ]; then
    # Clean the virtual environment after fail uninstall
    rm -drf "$(pyenv root)/versions/${2:-$DEFAULT_VIRTUALENV_NAME}"
    rm -drf "$(pyenv root)/versions/$python_version/envs/${2:-$DEFAULT_VIRTUALENV_NAME}"
    mv  $HOME/.ansible/collections/ansible_collections $HOME/.ansible/collections/ansible_collections_${now}.bak
    echo "==> Virtual environment <${2:-$DEFAULT_VIRTUALENV_NAME}> successfully cleaned!"
    exit 0
fi

# Check if virtualenv avd-env-3.8.x already exists
if pyenv virtualenvs | grep -q "$virtualenv_name"; then
    echo "==> Virtual environment <$virtualenv_name> already exists - You can use the flag --delete and try again."
    exit 1
else
    # Run the commands after the checks
    pyenv update
    echo "==> pyenv successfully updated!"
    pyenv install $python_version
    pyenv virtualenv $python_version "$virtualenv_name"
    echo "==> Virtual environment <$virtualenv_name> <$python_version> successfully installed!"
fi

# Activate the virtual environment
if pyenv activate "$virtualenv_name"; then
    # Check if pip upgrade and pip requirements installation succeed
    if pip install pip --upgrade && \
       pip install -r $DEFAULT_REQ_DIR/requirements-avd.txt && \
       pip install -r $DEFAULT_REQ_DIR/requirements-avd-dev.txt && \
       pip install -r $DEFAULT_REQ_DIR/requirements-gns3.txt && \
       pip install -r $DEFAULT_REQ_DIR/requirements.txt; then
        # Optional: Display Python, virtual environment and ansible-galaxy collection info
        lbreak && echo '# pip packages' && lbreak
        pip freeze
        lbreak && echo '# pip version' && lbreak
        pip --version
        lbreak && echo '# python version && pyenv path' && lbreak
        python --version
        python -c "import sys; print(sys.executable)"
        lbreak
    else
        echo "==> pip installation or requirements installation failed."
        exit 1
    fi
    # Check if ansible-galaxy requirements installation succeed
    if ansible-galaxy collection install -r $DEFAULT_REQ_DIR/requirements.yml; then
        lbreak && echo '# ansible-galaxy version' && lbreak
        ansible-galaxy --version
        lbreak && echo '# ansible-galaxy collection list' && lbreak
        ansible-galaxy collection list
        lbreak
        moo 'Enjoy!'
    else
        echo "==> ansible-galaxy collection requirements installation failed."
        exit 1
    fi
else
    echo "==> Virtual environment <$virtualenv_name> failed to activate!"
    exit 1
fi