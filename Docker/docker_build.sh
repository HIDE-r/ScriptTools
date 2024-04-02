#!/usr/bin/env bash

if [ -z "${DOCKER_IAMGE}" ] || [ -z "$(docker images -q "${DOCKER_IAMGE}" 2> /dev/null)" ]; then
	printf "ERROR: docker image not found, DOCKER_IAMGE=%s\n" "${DOCKER_IAMGE}"
	exit 1
fi

DOCKERFILE_BUILD_ENABLE=true
DOCKERFILE="./Dockerfile"

run() {
	local verbose=1
	if [ "${verbose}" = "1" ]; then
		echo ""
		echo "===> [RUN] $*"
		echo ""
	fi

	"$@" || exit $?
}

SCRIPT_DIR_PATH=$(dirname "$(realpath -s "$0")")

# NOTE: Assume the projects top level path is same as this script absolute path
PROJECT_DIR_PATH=${SCRIPT_DIR_PATH}
PROJECT_DIR_NAME=$(basename "${SCRIPT_DIR_PATH}")
RELATIVE_POS=$(realpath -m --relative-to="${PROJECT_DIR_PATH}" "${PWD}")
CONTAINER_NAME="${PROJECT_DIR_NAME}_$(date +%Y%m%d_%H_%M).${RANDOM}"

DOCKER_BASE_OPTS=(
	--hostname "${DOCKER_IAMGE}"
	--name "${CONTAINER_NAME}"
	--user "$(id -u)":"$(id -g)"
	-w "${PROJECT_DIR_PATH}/${RELATIVE_POS}"
	-v "${PROJECT_DIR_PATH}":"${PROJECT_DIR_PATH}"
	-v /etc/passwd:/etc/passwd:ro
	-v /etc/shadow:/etc/shadow
	-v /etc/group:/etc/group:ro
	-v /etc/sudoers:/etc/sudoers:ro
	-v "${HOME}"/.ssh:"${HOME}"/.ssh:ro
	)

SSH_AGENT_OPTS=()
if [ -n "${SSH_AUTH_SOCK}" ]; then
	SSH_AGENT_OPTS=(
		-v "$(dirname "${SSH_AUTH_SOCK}")":"$(dirname "${SSH_AUTH_SOCK}")"
		-e SSH_AUTH_SOCK="${SSH_AUTH_SOCK}"
		)
fi

# NOTE: Build docker image from dockerfile
if ${DOCKERFILE_BUILD_ENABLE} && [ -z "$(docker images -q "${DOCKER_IAMGE}" 2> /dev/null)" ]; then
	if [ ! -e "${DOCKERFILE}" ]; then
		echo "Error: Dockerfile not found !!!"
		exit 1
	fi

	echo "Try to build docker image by Dockerfile ..."
	run docker buildx build -t "$DOCKER_IAMGE" -f "${DOCKERFILE}" .
fi

# NOTE: The hook script before running, which use for some projects need to do something to adapt with docker
if [ -x "${PROJECT_DIR_PATH}/hook_docker_build_pre_run.sh" ]; then
	run source "${PROJECT_DIR_PATH}/hook_docker_build_pre_run.sh"
fi

DOCKER_OPTS=(
	"${DOCKER_BASE_OPTS[@]}"
	"${SSH_AGENT_OPTS[@]}" 
	"${OTHER_OPTS[@]}" 
	)

run docker run --rm -it "${DOCKER_OPTS[@]}" "${DOCKER_IAMGE}" /usr/bin/bash -c "$*"
