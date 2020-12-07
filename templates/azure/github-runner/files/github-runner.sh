#!/bin/bash

set -ex

while [ $# -gt 0 ]; do
  case "$1" in
    --action=*)
      ACTION="${1#*=}"
      ;;
    --config-file=*)
      CONFIG_FILE="${1#*=}"
      ;;
    --github-runner-binary=*)
      GITHUB_RUNNER_BINARY="${1#*=}"
      ;;
    --azure-authentication-method=*)
      AZURE_AUTHENTICATION_METHOD="${1#*=}"
      ;;
    --github-runner-config-script=*)
      GITHUB_RUNNER_CONFIG_SCRIPT="${1#*=}"
      ;;
    --github-runner-service-script=*)
      GITHUB_RUNNER_SERVICE_SCRIPT="${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done


if [[ -z ${ACTION} ]]; then
    echo Setting action to REGISTER by default
    ACTION="REGISTER"
elif [[ "${ACTION}" == "REGISTER" ]]; then
    echo Action is REGISTER
elif [[ "${ACTION}" == "REMOVE" ]]; then
    echo Action is REMOVE
else
    echo ERROR: Unknown action: ${ACTION}
    echo Use --action REGISTER or REMOVE
    exit 1
fi


if [[ -z ${CONFIG_FILE} ]]; then
    CONFIG_FILE="/etc/github-runner/github-runner-config.json"
fi

if [[ -z ${GITHUB_RUNNER_BINARY} ]]; then
    GITHUB_RUNNER_BINARY="/etc/github-runner/github-runner"
fi

if [[ -z ${AZURE_AUTHENTICATION_METHOD} ]]; then
    AZURE_AUTHENTICATION_METHOD="ENV"
fi

if [[ -z ${GITHUB_RUNNER_CONFIG_SCRIPT} ]]; then
    GITHUB_RUNNER_CONFIG_SCRIPT="/etc/github-runner/config.sh"
fi

if [[ -z ${GITHUB_RUNNER_SERVICE_SCRIPT} ]]; then
    GITHUB_RUNNER_SERVICE_SCRIPT="/etc/github-runner/svc.sh"
fi

AZURE_KEYVAULT_NAME=$(cat ${CONFIG_FILE} | jq -r .AZURE_KEYVAULT_NAME)
GITHUB_ORGANIZATION_KVSECRET=$(cat ${CONFIG_FILE} | jq -r .GITHUB_ORGANIZATION_KVSECRET)
GITHUB_APP_ID_KVSECRET=$(cat ${CONFIG_FILE} | jq -r .GITHUB_APP_ID_KVSECRET)
GITHUB_INSTALLATION_ID_KVSECRET=$(cat ${CONFIG_FILE} | jq -r .GITHUB_INSTALLATION_ID_KVSECRET)
GITHUB_PRIVATE_KEY_KVSECRET=$(cat ${CONFIG_FILE} | jq -r .GITHUB_PRIVATE_KEY_KVSECRET)

if [[ "${ACTION}" == "REGISTER" ]]; then
    GITHUB_RUNNER_OUTPUT=$(${GITHUB_RUNNER_BINARY} --value-source AZURE_KEYVAULT --azure-keyvault-name ${AZURE_KEYVAULT_NAME} --organization-kvsecret ${GITHUB_ORGANIZATION_KVSECRET} --app-id-kvsecret ${GITHUB_APP_ID_KVSECRET} --installation-id-kvsecret ${GITHUB_INSTALLATION_ID_KVSECRET} --private-key-kvsecret ${GITHUB_PRIVATE_KEY_KVSECRET} --azure-auth ${AZURE_AUTHENTICATION_METHOD} --output JSON)
    GITHUB_RUNNER_ORGANIZATION=$(echo ${GITHUB_RUNNER_OUTPUT} | jq -r .organization)
    GITHUB_RUNNER_REGISTER_TOKEN=$(echo ${GITHUB_RUNNER_OUTPUT} | jq -r .token)
    if id ghrunner &>/dev/null; then
        echo "User ghrunner already exists"
    else
        echo "Creating user ghrunner"
        useradd -s /bin/bash -d /home/ghrunner/ -m ghrunner
    fi

    usermod -a -G sudo,docker ghrunner
    echo "ghrunner ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ghrunner

    chown -R ghrunner:ghrunner /etc/github-runner

    runuser -l ghrunner -c "${GITHUB_RUNNER_CONFIG_SCRIPT} --url https://github.com/${GITHUB_RUNNER_ORGANIZATION} --token ${GITHUB_RUNNER_REGISTER_TOKEN} --name $(hostname) --work /home/ghrunner --unattended --replace"
    ${GITHUB_RUNNER_SERVICE_SCRIPT} install ghrunner
    ${GITHUB_RUNNER_SERVICE_SCRIPT} start
elif [[ "${ACTION}" == "REMOVE" ]]; then
    GITHUB_RUNNER_OUTPUT=$(${GITHUB_RUNNER_BINARY} --value-source AZURE_KEYVAULT --azure-keyvault-name ${AZURE_KEYVAULT_NAME} --organization-kvsecret ${GITHUB_ORGANIZATION_KVSECRET} --app-id-kvsecret ${GITHUB_APP_ID_KVSECRET} --installation-id-kvsecret ${GITHUB_INSTALLATION_ID_KVSECRET} --private-key-kvsecret ${GITHUB_PRIVATE_KEY_KVSECRET} --azure-auth ${AZURE_AUTHENTICATION_METHOD} --output JSON --token-type REMOVE)
    GITHUB_RUNNER_REMOVE_TOKEN=$(echo ${GITHUB_RUNNER_OUTPUT} | jq -r .token)
    set +e
    ${GITHUB_RUNNER_SERVICE_SCRIPT} uninstall
    set -e
    runuser -l ghrunner -c "${GITHUB_RUNNER_CONFIG_SCRIPT} remove --unattended --token ${GITHUB_RUNNER_REMOVE_TOKEN}"
fi
