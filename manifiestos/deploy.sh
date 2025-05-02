#!/bin/bash

# --- Fail fast & sane environment ---
set -euo pipefail
IFS=$'\n\t'

# --- CONFIGURACIÓN ---
WORKDIR="$HOME/TP5Cloud"
STATIC_REPO="https://github.com/Estanislao-Tello/static-website.git"
TP5_REPO="https://github.com/Estanislao-Tello/TP5Cloud.git"
MOUNT_SRC="$WORKDIR/static-website"
MOUNT_DEST="/mnt/web"
INGRESS_DOMAIN="local.service"
HOSTS_FILE="/etc/hosts"

# --- VALIDAR DEPENDENCIAS ---
function check_dependencies() {
    echo "🔍 Verificando dependencias..."
    local deps=("git" "kubectl" "minikube")

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ Dependencia faltante: $cmd"
            exit 1
        fi
    done
    echo "✅ Todas las dependencias están presentes"
}

# --- CLONAR REPOSITORIOS ---
function clone_repos() {
    echo "📁 Clonando repositorios..."

    # Configuración para evitar errores de red durante el clone
    echo "⚙️ Configurando Git para conexiones estables..."
    git config --global http.postBuffer 524288000
    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999

    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    if [ ! -d "$WORKDIR/static-website" ]; then
        echo "⬇️ Clonando static-website..."
        git clone "$STATIC_REPO"
    else
        echo "↪️ static-website ya existe, omitiendo clone"
    fi

    if [ ! -d "$WORKDIR/TP5Cloud" ]; then
        echo "⬇️ Clonando TP5Cloud..."
        git clone "$TP5_REPO"
    else
        echo "↪️ TP5Cloud ya existe, omitiendo clone"
    fi
}


# --- INICIAR MINIKUBE ---
function start_minikube() {
    echo "🚀 Iniciando Minikube..."
    if ! minikube status &> /dev/null; then
        minikube start --mount --mount-string="$MOUNT_SRC:$MOUNT_DEST"
    else
        echo "🟢 Minikube ya está corriendo"
    fi
}

# --- ESTRUCTURA DE MANIFIESTOS ---
function create_manifest_structure() {
    echo "📁 Creando carpetas de manifiestos..."
    local base="$WORKDIR/TP5Cloud/manifiestos"
    mkdir -p "$base/deployments" "$base/services" "$base/volumes"
}

# --- APLICAR MANIFIESTOS ---
function apply_manifests() {
    echo "📄 Aplicando manifiestos..."
    local dirs=("deployments" "services" "volumes")
    for dir in "${dirs[@]}"; do
        local path="$WORKDIR/TP5Cloud/manifiestos/$dir"
        if [ -d "$path" ]; then
            kubectl apply -f "$path"
        fi
    done
}

# --- EXPONER SERVICIO ---
function expose_service() {
    echo "⏳ Esperando a que el pod esté 'Running'..."
    while [[ $(kubectl get pods -l app=static-site -o jsonpath="{.items[0].status.phase}" 2>/dev/null || echo "NotReady") != "Running" ]]; do
        sleep 2
    done

    echo "🌐 Abriendo servicio en navegador..."
    minikube service static-site-service
}

# --- CONFIGURAR INGRESS Y HOSTS ---
function configure_ingress() {
    echo "⚙️ Habilitando Ingress..."
    minikube addons enable ingress || true

    kubectl wait --namespace ingress-nginx \
      --for=condition=Ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=180s

    echo "📄 Aplicando manifiestos de Ingress..."
    local ingress_dir="$WORKDIR/TP5Cloud/manifiestos/ingress"
    if [ -d "$ingress_dir" ]; then
        kubectl apply -f "$ingress_dir"
    fi

    local MINIKUBE_IP
    MINIKUBE_IP=$(minikube ip)

    if ! grep -q "$INGRESS_DOMAIN" "$HOSTS_FILE"; then
        echo "🔧 Configurando /etc/hosts..."
        echo "$MINIKUBE_IP $INGRESS_DOMAIN" | sudo tee -a "$HOSTS_FILE"
    else
        echo "🟢 Entrada en /etc/hosts ya existe"
    fi

    echo "🌐 Ahora podés acceder a: http://$INGRESS_DOMAIN"
    xdg-open "http://$INGRESS_DOMAIN" || echo "⚠️ No se pudo abrir automáticamente el navegador."

    
}

# --- VERIFICACIÓN FINAL ---
function final_verification() {
    echo "🔎 Verificando estado final del despliegue..."

    echo -e "\n📦 Pods:"
    kubectl get pods -o wide

    echo -e "\n🔌 Servicios:"
    kubectl get svc

    echo -e "\n🌐 Ingress:"
    kubectl get ingress

    echo -e "\n📡 Verificando acceso HTTP a http://$INGRESS_DOMAIN ..."
    if curl -s --head "http://$INGRESS_DOMAIN" | grep -q "200 OK"; then
        echo "✅ La página responde correctamente con código 200"
    else
        echo "⚠️ No se recibió respuesta 200 desde http://$INGRESS_DOMAIN"
    fi
}



# --- MAIN ---
function main() {
    check_dependencies
    clone_repos
    start_minikube
    create_manifest_structure
    apply_manifests
    expose_service
    configure_ingress
    final_verification
    echo "✅ Sitio web desplegado exitosamente en Minikube"
}

main "$@"
