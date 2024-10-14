#!/bin/bash

# Function to prompt user for input
function prompt_input() {
    read -p "$1: " input
    echo $input
}

# Function to handle invalid selection and allow retries
function retry_or_back() {
    while true; do
        echo "Invalid selection or failure occurred."
        echo "Would you like to retry (r), go back one step (b), or exit (e)?"
        read -p "(r/b/e): " choice
        case $choice in
            r|R)
                return 0  # Retry the same step
                ;;
            b|B)
                return 1  # Go back one step
                ;;
            e|E)
                echo "Exiting the script."
                exit 0
                ;;
            *)
                echo "Invalid option. Please choose (r), (b), or (e)."
                ;;
        esac
    done
}

# Function to debug a specific component
function debug_component() {
    while true; do
        # Get the namespace
        NAMESPACE=$(prompt_input "Enter the namespace (leave blank for default)")

        # Choose a component to debug
        echo "Select the Kubernetes component to debug:"
        echo "1. Pod"
        echo "2. Deployment"
        echo "3. StatefulSet"
        echo "4. DaemonSet"
        echo "5. ReplicaSet"
        echo "6. ReplicationController"
        echo "7. Job"
        echo "8. CronJob"
        read -p "Enter the number corresponding to the component: " COMPONENT

        case $COMPONENT in
            1) # Pod debugging
                POD_NAME=$(prompt_input "Enter the name of the pod you want to debug")
                echo "Fetching details of the pod $POD_NAME in namespace ${NAMESPACE:-default}"
                if ! kubectl describe pod $POD_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                
                # Logs check
                CHECK_LOGS=$(prompt_input "Do you want to check the pod logs? (yes/no)")
                if [ "$CHECK_LOGS" == "yes" ]; then
                    CONTAINER_NAME=$(prompt_input "Enter the container name (if applicable, leave blank otherwise)")
                    if [ -z "$CONTAINER_NAME" ]; then
                        if ! kubectl logs $POD_NAME -n ${NAMESPACE:-default}; then
                            if retry_or_back; then continue; else debug_component; return; fi
                        fi
                    else
                        if ! kubectl logs $POD_NAME -n ${NAMESPACE:-default} -c $CONTAINER_NAME; then
                            if retry_or_back; then continue; else debug_component; return; fi
                        fi
                    fi
                fi
                ;;

            2) # Deployment debugging
                DEPLOYMENT_NAME=$(prompt_input "Enter the name of the deployment you want to debug")
                echo "Fetching details of the deployment $DEPLOYMENT_NAME"
                if ! kubectl describe deployment $DEPLOYMENT_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                if ! kubectl rollout status deployment $DEPLOYMENT_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                ;;

            3) # StatefulSet debugging
                STATEFULSET_NAME=$(prompt_input "Enter the name of the StatefulSet you want to debug")
                echo "Fetching details of the StatefulSet $STATEFULSET_NAME"
                if ! kubectl describe statefulset $STATEFULSET_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                if ! kubectl rollout status statefulset $STATEFULSET_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                ;;

            4) # DaemonSet debugging
                DAEMONSET_NAME=$(prompt_input "Enter the name of the DaemonSet you want to debug")
                echo "Fetching details of the DaemonSet $DAEMONSET_NAME"
                if ! kubectl describe daemonset $DAEMONSET_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                if ! kubectl rollout status daemonset $DAEMONSET_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                ;;

            5) # ReplicaSet debugging
                REPLICASET_NAME=$(prompt_input "Enter the name of the ReplicaSet you want to debug")
                echo "Fetching details of the ReplicaSet $REPLICASET_NAME"
                if ! kubectl describe replicaset $REPLICASET_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                ;;

            6) # ReplicationController debugging
                RC_NAME=$(prompt_input "Enter the name of the ReplicationController you want to debug")
                echo "Fetching details of the ReplicationController $RC_NAME"
                if ! kubectl describe rc $RC_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                ;;

            7) # Job debugging
                JOB_NAME=$(prompt_input "Enter the name of the Job you want to debug")
                echo "Fetching details of the Job $JOB_NAME"
                if ! kubectl describe job $JOB_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                if ! kubectl get job $JOB_NAME -n ${NAMESPACE:-default} -o wide; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                ;;

            8) # CronJob debugging
                CRONJOB_NAME=$(prompt_input "Enter the name of the CronJob you want to debug")
                echo "Fetching details of the CronJob $CRONJOB_NAME"
                if ! kubectl describe cronjob $CRONJOB_NAME -n ${NAMESPACE:-default}; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                if ! kubectl get cronjob $CRONJOB_NAME -n ${NAMESPACE:-default} -o wide; then
                    if retry_or_back; then continue; else debug_component; return; fi
                fi
                ;;

            *) # Invalid option
                echo "Invalid selection."
                if retry_or_back; then continue; else debug_component; return; fi
                ;;
        esac
        
        # If we reach here, it means debugging was successful for the selected component
        break
    done
}

# Start the debugging process
debug_component

# Additional cluster-wide checks (optional)
while true; do
    CHECK_NODES=$(prompt_input "Do you want to check the status of the nodes? (yes/no)")
    if [ "$CHECK_NODES" == "yes" ]; then
        echo "Fetching node status..."
        if ! kubectl get nodes; then
            if retry_or_back; then continue; else debug_component; return; fi
        fi
    fi

    # Cluster info check
    CLUSTER_INFO=$(prompt_input "Do you want to check the overall cluster status? (yes/no)")
    if [ "$CLUSTER_INFO" == "yes" ]; then
        echo "Fetching cluster info..."
        if ! kubectl cluster-info; then
            if retry_or_back; then continue; else debug_component; return; fi
        fi
    fi

    echo "Debugging completed. Please review the information gathered."
    break
done
