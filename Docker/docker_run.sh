#!/usr/bin/env bash

# NOTE: Please set the follow variables for using this script:
# - DOCKER_IAMGE		the name of the docker image, which will be used
# - PROJECT_DIR_PATH		[optional] project root path, default is current script path
# - DOCKERFILE			[optional] the path of dockerfile, default is './Dockerfile'
# - DOCKER_BUILD_CMD		[optional] command which use to build image from dockerfile
#
# Examples 1:
# 	env DOCKER_IAMGE=ugw_build ./docker_run.sh make
#
# Examples 2:
# 	echo 'export DOCKER_IAMGE=ugw_build' > .envrc && direnv allow
# 	./docker_run.sh make
#

VERBOSE=1

# set -x

if cat /proc/version | grep -q -i wsl ;then
	is_wsl=1
else
	is_wsl=0
fi

bell_message=$(tmux run 2>/dev/null && tmux display-message -p 'Bell in session ❐ #{session_name} ● #{window_index}:#{window_name}')

bell(){
	echo -e '\a';

	if [ "${is_wsl}" = "1" ]; then
		notify-send-wsl() { wsl-notify-send.exe --category $WSL_DISTRO_NAME "${@}"; }
		notify-send-wsl "${bell_message}"
	else
		if which notify-send > /dev/null 2>&1; then
			notify-send -i wezterm -u critical "${bell_message}"
		fi
	fi
}

run() {
	if [ "${VERBOSE}" = "1" ]; then
		echo ""
		echo "===> [RUN] $*"
		echo ""
	fi

	"$@" || exit $?
}

# NOTE: try to load variables from .envrc
if ! which direnv > /dev/null 2>&1 && [ -e .envrc ]; then
	run source .envrc
fi

if [ -z "${DOCKER_IAMGE}" ] || [ -z "$(docker images -q "${DOCKER_IAMGE}" 2> /dev/null)" ]; then
	printf "ERROR: docker image not found, DOCKER_IAMGE=%s\n" "${DOCKER_IAMGE}"
	exit 1
fi

# don't expand symlinks
SCRIPT_DIR_PATH=$(dirname "$(realpath -s "$0")")

# if $PROJECT_DIR_PATH not set, Assume the projects top level path is same as this script absolute path
PROJECT_DIR_PATH=${PROJECT_DIR_PATH:-${SCRIPT_DIR_PATH}}
PROJECT_DIR_NAME=$(basename "${PROJECT_DIR_PATH}")
# RELATIVE_POS=$(realpath -m --relative-to="${PROJECT_DIR_PATH}" "${PWD}")
CONTAINER_NAME="${PROJECT_DIR_NAME}_$(date +%Y%m%d_%H_%M).${RANDOM}"

DOCKERFILE_BUILD_ENABLE=true
DOCKERFILE=${DOCKERFILE:-${PROJECT_DIR_PATH}/Dockerfile}
DOCKER_ENV_FILE=${DOCKER_ENV_FILE:-${PROJECT_DIR_PATH}/docker.env}
# DOCKER_BUILD_CMD=${DOCKER_BUILD_CMD:-docker buildx build -t "$DOCKER_IAMGE" -f "${DOCKERFILE}" .}
DOCKER_BUILD_CMD=${DOCKER_BUILD_CMD:-docker build -t "${DOCKER_IAMGE}" -f "${DOCKERFILE}" .}

DOCKER_BASE_OPTS=(
	--hostname "${DOCKER_IAMGE}"
	--name "${CONTAINER_NAME}"
	--user "$(id -u)":"$(id -g)"
	-w "${PWD}"
	-v "${PROJECT_DIR_PATH}":"${PROJECT_DIR_PATH}"
	-v /etc/passwd:/etc/passwd:ro
	-v /etc/shadow:/etc/shadow
	-v /etc/group:/etc/group:ro
	-v /etc/sudoers:/etc/sudoers:ro
	-v "${HOME}"/.ssh:"${HOME}"/.ssh:ro
	-v "$(realpath -s ${HOME}/.ssh/config)":"${HOME}/.ssh/config":ro
	)

SSH_AGENT_OPTS=()
if [ -n "${SSH_AUTH_SOCK}" ]; then
	SSH_AGENT_OPTS=(
		-v "$(dirname "${SSH_AUTH_SOCK}")":"$(dirname "${SSH_AUTH_SOCK}")"
		-e SSH_AUTH_SOCK="${SSH_AUTH_SOCK}"
		)
fi

ENV_FILE_OPTS=()
if [ -e "${DOCKER_ENV_FILE}" ]; then
	ENV_FILE_OPTS=(
		--env-file "${DOCKER_ENV_FILE}"
		)
fi

# NOTE: Build docker image from dockerfile
if ${DOCKERFILE_BUILD_ENABLE} && [ -z "$(docker images -q "${DOCKER_IAMGE}" 2> /dev/null)" ]; then
	if [ ! -e "${DOCKERFILE}" ]; then
		echo "Error: Dockerfile not found !!!"
		exit 1
	fi

	echo "Try to build docker image by Dockerfile ..."
	run "${DOCKER_BUILD_CMD}"
fi

# NOTE: The hook script before running docker, which is useful for many projects need to do something to adapt with docker
# 1. set $OTHER_OPTS array in hook script can import more docker option for project
if [ -e "${PROJECT_DIR_PATH}/hook_docker_build_pre_run.sh" ]; then
	chmod u+x "${PROJECT_DIR_PATH}/hook_docker_build_pre_run.sh"
	run source "${PROJECT_DIR_PATH}/hook_docker_build_pre_run.sh"
fi

DOCKER_OPTS=(
	"${DOCKER_BASE_OPTS[@]}"
	"${SSH_AGENT_OPTS[@]}" 
	"${ENV_FILE_OPTS[@]}" 
	"${OTHER_OPTS[@]}" 
	)

if [ "$#" = "0" ];then
	run docker run --rm -it "${DOCKER_OPTS[@]}" "${DOCKER_IAMGE}" bash
else
	run docker run --rm -it "${DOCKER_OPTS[@]}" "${DOCKER_IAMGE}" bash -c "$*"
	bell
fi

