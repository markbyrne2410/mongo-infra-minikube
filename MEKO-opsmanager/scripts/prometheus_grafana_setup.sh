# Configures Prometheus and Grafana monitoring for the deployed MongoDB Search & Vector Deployment 

NAMESPACE="mongodb"
MONITORING_DIR="./monitoring"
# DASHBOARD_URL="https://github.com/10gen/self-managed-mongot-prometheus-grafana/blob/main/grafana/dashboards/mongot-drilldown.json"
DASHBOARD_FILE="${MONITORING_DIR}/mongot-drilldown.json"

read -p "Do you want to enable Prometheus and Grafana monitoring? (y/n): " answer

if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
        echo "Enabling Prometheus and Grafana monitoring..."

        echo "Applying Prometheus ConfigMap..."
        kubectl apply -f "${MONITORING_DIR}/prometheus_configmap.yaml"

        echo "Deploying Prometheus..."
        kubectl apply -f "${MONITORING_DIR}/prometheus.yaml"

        echo ""
        echo "Waiting for Prometheus deployment to become available..."

        if kubectl rollout status deployment/prometheus-server \
            -n "${NAMESPACE}" \
            --timeout=180s; then

            echo "✅ Prometheus deployment is running."

            echo "Checking Prometheus service..."

            if kubectl get service prometheus-server -n "${NAMESPACE}" >/dev/null 2>&1; then
                echo "✅ Prometheus service is available."
                echo ""
                echo "Prometheus monitoring has been successfully deployed."
            else
                echo "❌ Prometheus service was not found."
                exit 1
            fi

        else
            echo "❌ Prometheus deployment failed to become ready within the timeout."
            exit 1
        fi

        # echo "Downloading MongoDB Grafana dashboard..."

        # if curl -fsSL -o "${DASHBOARD_FILE}" "${DASHBOARD_URL}"; then
        #     echo "✅ Dashboard downloaded successfully."

        #     echo "✅ Dashboard ConfigMap created."
        # else
        #     echo "⚠️ Unable to download dashboard from GitHub."
        #     echo "Continuing with Grafana deployment..."
        # fi

        echo "Creating Grafana dashboard ConfigMap..."
        # If downloading the latest dashboard fails, use the local copy of the dashboard file
        kubectl create configmap grafana-dashboards-json \
            --from-file=mongodb-dashboard.json="${DASHBOARD_FILE}" \
            -n "${NAMESPACE}" \
            --dry-run=client -o yaml | kubectl apply -f -        

        echo "Applying Grafana ConfigMap..."
        kubectl apply -f "${MONITORING_DIR}/grafana_configmap.yaml"

        echo "Deploying Grafana..."
        kubectl apply -f "${MONITORING_DIR}/grafana.yaml"

        echo ""
        echo "Waiting for Grafana deployment to become available..."

        if kubectl rollout status deployment/grafana \
            -n "${NAMESPACE}" \
            --timeout=180s; then

            echo "✅ Grafana deployment is running."

            echo "Checking Grafana service..."

            if kubectl get service grafana -n "${NAMESPACE}" >/dev/null 2>&1; then
                echo "✅ Grafana service is available."
                echo ""
                echo "Grafana has been successfully deployed."

            else
                echo "❌ Grafana service was not found."
                exit 1
            fi
        else
            echo "❌ Grafana deployment failed to become ready within the timeout."
            exit 1
        fi

        PROMETHEUS_POD=$(kubectl get pods -n "${NAMESPACE}" \
            -l app=prometheus-server \
            -o jsonpath='{.items[0].metadata.name}')

        echo ""
        echo "------------------------------------------------------------"
        echo ""
        echo "To access Prometheus locally, run:"
        echo "kubectl port-forward -n ${NAMESPACE} pod/${PROMETHEUS_POD} 9090:9090"
        echo ""
        echo "Then browse to: http://localhost:9090"
        echo "------------------------------------------------------------"

        GRAFANA_POD=$(kubectl get pods -n "${NAMESPACE}" \
            -l app=grafana \
            -o jsonpath='{.items[0].metadata.name}')

        echo ""
        echo "------------------------------------------------------------"
        echo ""
        echo "To access Grafana locally, run:"
        echo "kubectl port-forward -n ${NAMESPACE} pod/${GRAFANA_POD} 3000:3000"
        echo ""
        echo "Then browse to: http://localhost:3000"
        echo "Default Grafana credentials:"
        echo "Username: admin"
        echo "Password: admin"
        echo "------------------------------------------------------------"
fi