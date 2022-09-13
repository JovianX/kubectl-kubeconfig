#!/bin/bash
set -e
set -o pipefail


SERVICE_ACCOUNT_NAME="jovianx-admin"
NAMESPACE="jovianx-system"

TARGET_FOLDER="/tmp/kube"
KUBECFG_FILE_NAME="kubeconfig-${SERVICE_ACCOUNT_NAME}-${NAMESPACE}.yaml"
KUBECFG_FILE_PATH="$TARGET_FOLDER/$KUBECFG_FILE_NAME"
OUTPUT_FILE="./$KUBECFG_FILE_NAME"

NO_INPUT=false
UPLOAD=false
DEBUG=false

HELP_TEXT="
Generates administrative Kubeconfig file for your cluster.

This script generates a Kubeconfig file that allows full administrative access
to your cluster
Please note that this creates a Kubernetes service account
'$SERVICE_ACCOUNT_NAME' with *CLUSTER-ADMIN* role in the '$NAMESPACE' namespace.

Available parameters:
    --debug     if this flag set additional output will provided.

    --output    path to creating Kubernetes configuration file.
                Default: '$OUTPUT_FILE'.

    --quiet     don't reques input from user.

    --upload    Upload configuration to JovianX Service Hub. Note: if this flag
                set configuration file will not be created on your file system.

    --help      Print this message.
"


create_target_directory() {
    [[ $DEBUG == true ]] && printf "%s" "Creating target directory to hold files in '${TARGET_FOLDER}'... "
    mkdir -p "${TARGET_FOLDER}"
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


test_current_kubeconfig() {
    [[ $DEBUG == true ]] && printf "%s" "Trying to get resoruces using current Kubeconfig... "
    if [[ "$DEBUG" == true ]]; then
        kubectl get pods --all-namespaces
    else
        kubectl get pods --all-namespaces > /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


test_generated_kubeconfig() {
    [[ $DEBUG == true ]] && printf "%s" "Trying to get resources using generated Kubeconfig... "
    if [[ "$DEBUG" == true ]]; then
        KUBECONFIG=${OUTPUT_FILE} kubectl get pods --all-namespaces
    else
        KUBECONFIG=${OUTPUT_FILE} kubectl get pods --all-namespaces > /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


create_namespace() {
    [[ $DEBUG == true ]] && printf "%s" "Creating namespace ${NAMESPACE}... "
    if [[ "$DEBUG" == true ]]; then
        kubectl create namespace "${NAMESPACE}"
    else
        kubectl create namespace "${NAMESPACE}" 2> /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


create_service_account() {
    [[ $DEBUG == true ]] && printf "%s" "Creating a service account '${SERVICE_ACCOUNT_NAME}' in '${NAMESPACE}' namespace... "
    if [[ "$DEBUG" == true ]]; then
        kubectl create sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}"
    else
        kubectl create sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}" 2> /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


create_cluster_role_binding() {
    [[ $DEBUG == true ]] && printf "%s" "Creating a cluster role binding cluster-admin... "
    user="system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}"
    if [[ "$DEBUG" == true ]]; then
        kubectl create clusterrolebinding jovianx-cluster-admin-binding --clusterrole cluster-admin --user $user
    else
        kubectl create clusterrolebinding jovianx-cluster-admin-binding --clusterrole cluster-admin --user $user 2> /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


get_secret_name_from_service_account() {
    [[ $DEBUG == true ]] && printf "%s" "Getting secret of service account ${SERVICE_ACCOUNT_NAME} on ${NAMESPACE}... "
    SECRET_NAME=$(kubectl get sa "${SERVICE_ACCOUNT_NAME}" --namespace="${NAMESPACE}" -o json | jq -r .secrets[].name)
    [[ $DEBUG == true ]] && printf "%s\n" "Secret name: ${SECRET_NAME}"

    return 0
}


extract_ca_crt_from_secret() {
    [[ $DEBUG == true ]] && printf "%s" "Extracting ca.crt from secret... "
    kubectl get secret --namespace "${NAMESPACE}" "${SECRET_NAME}" -o json | jq \
        -r '.data["ca.crt"]' | base64 -d > "${TARGET_FOLDER}/ca.crt"
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


get_user_token_from_secret() {
    [[ $DEBUG == true ]] && printf "%s" "Getting user token from secret... "
    USER_TOKEN=$(kubectl get secret --namespace "${NAMESPACE}" "${SECRET_NAME}" -o json | jq -r '.data["token"]' | base64 -d)
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


set_kube_config_values() {
    [[ $DEBUG == true ]] && printf "%s" "Setting current context to: $context... "
    context=$(kubectl config current-context)
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    [[ $DEBUG == true ]] && printf "%s" "Getting cluster name... "
    CLUSTER_NAME=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)
    [[ $DEBUG == true ]] && printf "%s\n" "Cluster name: ${CLUSTER_NAME}"

    [[ $DEBUG == true ]] && printf "%s" "Getting endpoint... "
    ENDPOINT=$(kubectl config view \
        -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")
    [[ $DEBUG == true ]] && printf "%s\n" "Endpoint: ${ENDPOINT}"

    # Set up the config
    [[ $DEBUG == true ]] && printf "%s" "Assembling Kubernetes configuration. Setting a cluster entry... "
    if [[ "$DEBUG" == true ]]; then
        kubectl config set-cluster "${CLUSTER_NAME}" \
            --kubeconfig="${KUBECFG_FILE_PATH}" \
            --server="${ENDPOINT}" \
            --certificate-authority="${TARGET_FOLDER}/ca.crt" \
            --embed-certs=true
    else
        kubectl config set-cluster "${CLUSTER_NAME}" \
            --kubeconfig="${KUBECFG_FILE_PATH}" \
            --server="${ENDPOINT}" \
            --certificate-authority="${TARGET_FOLDER}/ca.crt" \
            --embed-certs=true > /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    [[ $DEBUG == true ]] && printf "%s" "Assembling Kubernetes configuration. Setting token credentials entry... "
    if [[ "$DEBUG" == true ]]; then
        kubectl config set-credentials \
            "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
            --kubeconfig="${KUBECFG_FILE_PATH}" \
            --token="${USER_TOKEN}"
    else
        kubectl config set-credentials \
            "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
            --kubeconfig="${KUBECFG_FILE_PATH}" \
            --token="${USER_TOKEN}" > /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    [[ $DEBUG == true ]] && printf "%s" "Assembling Kubernetes configuration. Setting a context entry... "
    if [[ "$DEBUG" == true ]]; then
        kubectl config set-context \
            "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
            --kubeconfig="${KUBECFG_FILE_PATH}" \
            --cluster="${CLUSTER_NAME}" \
            --user="${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
            --namespace="${NAMESPACE}"
    else
        kubectl config set-context \
            "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
            --kubeconfig="${KUBECFG_FILE_PATH}" \
            --cluster="${CLUSTER_NAME}" \
            --user="${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
            --namespace="${NAMESPACE}" > /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    [[ $DEBUG == true ]] && printf "%s" "Assembling Kubernetes configuration. Setting the current-context... "
    if [[ "$DEBUG" == true ]]; then
        kubectl config use-context "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
            --kubeconfig="${KUBECFG_FILE_PATH}"
    else
        kubectl config use-context "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
            --kubeconfig="${KUBECFG_FILE_PATH}" > /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


copy_generated_kubeconfig() {
    [[ $DEBUG == true ]] && printf "%s" "Copying kubeconfig file to current directory and removing temporary working directory... "
    cp "$KUBECFG_FILE_PATH" "$OUTPUT_FILE"
    rm -Rf ${TARGET_FOLDER}
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


delete_generated_kubeconfig() {
    [[ $DEBUG == true ]] && printf "%s" "Deleting kubeconfig file to current directory and removing temporary working directory... "
    rm -Rf ${TARGET_FOLDER}
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


upload_configuration() {
    [[ $DEBUG == true ]] && printf "%s" "Uploading configuration to JovianX Service Hub... "
    UPLOAD_ENDPOINT=""
    if [[ -z "$UPLOAD_ENDPOINT" ]]; then
        printf "%s" "Upload endpoint was not provided."
        exit 1
    fi
    AUTH_TOKEN=""
    if [[ -z "$AUTH_TOKEN" ]]; then
        printf "%s" "Upload authentication token was not provided."
        exit 1
    fi
    FILE_CONTENT=$(yq --output-format=json eval "${KUBECFG_FILE_PATH}")
    if [[ "$DEBUG" == true ]]; then
        curl --silent --show-error -X 'POST' "$UPLOAD_ENDPOINT" \
            -H 'accept: application/json' \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -H 'Content-Type: application/json' \
            -d "$FILE_CONTENT"
    else
        curl --silent --show-error -X 'POST' "$UPLOAD_ENDPOINT" \
            -H 'accept: application/json' \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -H 'Content-Type: application/json' \
            -d "$FILE_CONTENT" > /dev/null
    fi
    [[ $DEBUG == true ]] && printf "%s\n" "Done"

    return 0
}


while test $# -gt 0; do
    case "$1" in
        (--quiet)
            NO_INPUT=true
            shift
            ;;
        (--debug)
            DEBUG=true
            shift
            ;;
        (--upload)
            UPLOAD=true
            shift
            ;;
        (--output)
            shift
            if test $# -gt 0; then
                OUTPUT_FILE="$1"
            else
                printf "%s\n" "$HELP_TEXT"
                exit 1
            fi
            shift
            ;;
        (--output*)
            OUTPUT_FILE=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        (--help)
            printf "%s\n" "$HELP_TEXT"
            exit 0
            ;;
        *)
            printf '%s\n' "Unknown argument $1."
            printf "%s\n" "$HELP_TEXT"
            exit 1
            ;;
    esac
done

if [[ "$NO_INPUT" == true ]]; then
    REPLY='y'
else
    printf "%s\n" "'$SERVICE_ACCOUNT_NAME' Kubernetes service account with *CLUSTER-ADMIN* role in '$NAMESPACE' namespace will be created."
    read -p "Proceed? [Y/n]:" -n 1 -r
    printf "\n"
fi

if [[ $REPLY =~ ^[Yy]$ ]];
then
    test_current_kubeconfig
    create_target_directory
    create_namespace || true
    create_service_account || true
    create_cluster_role_binding || true
    get_secret_name_from_service_account
    extract_ca_crt_from_secret
    get_user_token_from_secret
    set_kube_config_values
    if [[ "$UPLOAD" == true ]]; then
        upload_configuration
        delete_generated_kubeconfig
    else
        copy_generated_kubeconfig
        test_generated_kubeconfig
        printf "%s\n" "Kubernetes configuration saved to: $OUTPUT_FILE"
    fi
fi
