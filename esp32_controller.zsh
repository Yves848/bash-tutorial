#!/usr/bin/env zsh

# Configuration
ESP32_IP_PROD="192.168.50.201"
ESP32_IP_TEST="192.168.50.202"
ESP32_IP="$ESP32_IP_PROD"  # Par défaut, utiliser la production
ESP32_ENV="Production"     # Environnement actuel
BASE_URL="http://${ESP32_IP}"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour vérifier si gum est installé
check_gum() {
    if ! command -v gum &> /dev/null; then
        echo -e "${RED}❌ Erreur: 'gum' n'est pas installé${NC}"
        echo -e "${YELLOW}💡 Pour l'installer: brew install gum${NC}"
        exit 1
    fi
}

# Fonction pour vérifier si curl est disponible
check_curl() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ Erreur: 'curl' n'est pas installé${NC}"
        exit 1
    fi
}

# Fonction pour appeler un endpoint
call_endpoint() {
    local endpoint=$1
    local url="${BASE_URL}${endpoint}"
    
    gum spin --spinner dot --title "Connexion à l'ESP32..." -- sleep 1
    
    echo -e "${BLUE}📡 Appel de l'endpoint: ${endpoint}${NC}"
    
    # Effectuer la requête POST
    response=$(curl -s -w "%{http_code}" -X POST "$url" -o /tmp/esp32_response.txt)
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✅ Succès! Endpoint ${endpoint} appelé avec succès${NC}"
        if [ -s /tmp/esp32_response.txt ]; then
            echo -e "${BLUE}📄 Réponse:${NC}"
            cat /tmp/esp32_response.txt
            echo
        fi
    else
        echo -e "${RED}❌ Erreur HTTP: $http_code${NC}"
        if [ -s /tmp/esp32_response.txt ]; then
            echo -e "${RED}Détails:${NC}"
            cat /tmp/esp32_response.txt
            echo
        fi
    fi
    
    # Nettoyer le fichier temporaire
    rm -f /tmp/esp32_response.txt
}

# Fonction pour configurer le délai
set_delay() {
    # Demander le délai avec gum
    delais=$(gum input --placeholder "Entrez le délai en secondes (ex: 30)" --prompt "⏱️  Délai: ")
    
    # Vérifier si l'utilisateur a annulé
    if [ -z "$delais" ]; then
        echo -e "${YELLOW}⚠️  Configuration du délai annulée${NC}"
        return 1
    fi
    
    # Vérifier si c'est un nombre
    if ! [[ "$delais" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}❌ Erreur: Le délai doit être un nombre entier${NC}"
        return 1
    fi
    
    local url="${BASE_URL}/delay"
    local json_data="{\"delais\": \"${delais}\"}"
    
    gum spin --spinner dot --title "Configuration du délai..." -- sleep 1
    
    echo -e "${BLUE}📡 Configuration du délai: ${delais} secondes${NC}"
    
    # Effectuer la requête POST avec JSON
    response=$(curl -s -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$json_data" \
        -o /tmp/esp32_response.txt)
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✅ Succès! Délai configuré à ${delais} secondes${NC}"
        if [ -s /tmp/esp32_response.txt ]; then
            echo -e "${BLUE}📄 Réponse:${NC}"
            cat /tmp/esp32_response.txt
            echo
        fi
    else
        echo -e "${RED}❌ Erreur HTTP: $http_code${NC}"
        if [ -s /tmp/esp32_response.txt ]; then
            echo -e "${RED}Détails:${NC}"
            cat /tmp/esp32_response.txt
            echo
        fi
    fi
    
    # Nettoyer le fichier temporaire
    rm -f /tmp/esp32_response.txt
}

# Fonction pour changer d'environnement (IP)
switch_environment() {
    echo -e "${BLUE}🔄 Environnement actuel: ${YELLOW}${ESP32_ENV}${NC} (${ESP32_IP})"
    echo
    
    env_choice=$(gum choose --cursor="👉 " --selected.foreground=212 \
        "🏭 Production (${ESP32_IP_PROD})" \
        "🧪 Test (${ESP32_IP_TEST})" \
        "❌ Annuler")
    
    case "$env_choice" in
        "🏭 Production (${ESP32_IP_PROD})")
            ESP32_IP="$ESP32_IP_PROD"
            ESP32_ENV="Production"
            BASE_URL="http://${ESP32_IP}"
            echo -e "${GREEN}✅ Basculé vers l'environnement de Production${NC}"
            ;;
        "🧪 Test (${ESP32_IP_TEST})")
            ESP32_IP="$ESP32_IP_TEST"
            ESP32_ENV="Test"
            BASE_URL="http://${ESP32_IP}"
            echo -e "${GREEN}✅ Basculé vers l'environnement de Test${NC}"
            ;;
        "❌ Annuler")
            echo -e "${YELLOW}⚠️  Changement d'environnement annulé${NC}"
            return 1
            ;;
    esac
    
    echo -e "${BLUE}🔧 Nouvel environnement: ${YELLOW}${ESP32_ENV}${NC} (${ESP32_IP})"
}

# Fonction pour récupérer les données (endpoint /data)
get_data() {
    local url="${BASE_URL}/data"
    
    gum spin --spinner dot --title "Récupération des données..." -- sleep 1
    
    echo -e "${BLUE}📊 Récupération des données depuis /data${NC}"
    
    # Effectuer la requête GET
    response=$(curl -s -w "%{http_code}" -X GET "$url" -o /tmp/esp32_response.txt)
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✅ Données récupérées avec succès${NC}"
        if [ -s /tmp/esp32_response.txt ]; then
            echo -e "${BLUE}📄 Données:${NC}"
            
            # Tenter de parser le JSON pour un affichage plus joli
            if command -v jq &> /dev/null; then
                # Si jq est disponible, formatter le JSON
                cat /tmp/esp32_response.txt | jq .
            else
                # Sinon, afficher le JSON brut mais essayer de l'extraire
                json_content=$(cat /tmp/esp32_response.txt)
                echo "$json_content"
                
                # Essayer d'extraire state et interval manuellement
                if [[ "$json_content" =~ \"state\":[[:space:]]*\"([^\"]+)\" ]]; then
                    state="${BASH_REMATCH[1]}"
                    echo -e "\n${YELLOW}🔍 État actuel: ${state}${NC}"
                fi
                
                if [[ "$json_content" =~ \"interval\":[[:space:]]*([0-9]+) ]]; then
                    interval="${BASH_REMATCH[1]}"
                    echo -e "${YELLOW}⏱️  Intervalle: ${interval} secondes${NC}"
                fi
            fi
            echo
        fi
    else
        echo -e "${RED}❌ Erreur HTTP: $http_code${NC}"
        if [ -s /tmp/esp32_response.txt ]; then
            echo -e "${RED}Détails:${NC}"
            cat /tmp/esp32_response.txt
            echo
        fi
    fi
    
    # Nettoyer le fichier temporaire
    rm -f /tmp/esp32_response.txt
}

# Fonction pour tester la connexion
test_connection() {
    gum spin --spinner dot --title "Test de connexion..." -- sleep 1
    
    if ping -c 1 -W 3000 "$ESP32_IP" &> /dev/null; then
        echo -e "${GREEN}✅ ESP32 accessible à l'adresse $ESP32_IP${NC}"
        return 0
    else
        echo -e "${RED}❌ ESP32 non accessible à l'adresse $ESP32_IP${NC}"
        return 1
    fi
}

# Fonction principale
main() {
    # Vérifications préliminaires
    check_gum
    check_curl
    
    # Interface principale
    gum style --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'ESP32 Controller' 'Contrôlez votre ESP32 facilement'
    
    echo -e "${BLUE}🔧 Configuration:${NC}"
    echo -e "   Environnement: ${YELLOW}$ESP32_ENV${NC}"
    echo -e "   IP ESP32: ${YELLOW}$ESP32_IP${NC}"
    echo -e "   Endpoints: ${YELLOW}/day${NC}, ${YELLOW}/night${NC}, ${YELLOW}/delay${NC} et ${YELLOW}/data${NC}"
    echo
    
    while true; do
        # Menu principal avec gum
        action=$(gum choose --cursor="👉 " --selected.foreground=212 \
            "🌅 Activer mode DAY" \
            "🌙 Activer mode NIGHT" \
            "⏱️  Configurer le délai" \
            "📊 Récupérer les données" \
            "🔄 Changer d'environnement" \
            "🔍 Tester la connexion" \
            "📋 Afficher la configuration" \
            "❌ Quitter")
        
        case "$action" in
            "🌅 Activer mode DAY")
                call_endpoint "/day"
                ;;
            "🌙 Activer mode NIGHT")
                call_endpoint "/night"
                ;;
            "⏱️  Configurer le délai")
                set_delay
                ;;
            "📊 Récupérer les données")
                get_data
                ;;
            "🔄 Changer d'environnement")
                switch_environment
                ;;
            "🔍 Tester la connexion")
                test_connection
                ;;
            "📋 Afficher la configuration")
                gum style --foreground 81 --border-foreground 81 --border normal \
                    --margin "1 0" --padding "1 2" \
                    "Configuration ESP32:" \
                    "• Environnement: $ESP32_ENV" \
                    "• IP: $ESP32_IP" \
                    "• URL Base: $BASE_URL" \
                    "• Endpoints: /day, /night, /delay, /data"
                ;;
            "❌ Quitter")
                echo -e "${GREEN}👋 Au revoir!${NC}"
                exit 0
                ;;
        esac
        
        echo
        gum confirm "Continuer?" || break
        echo
    done
}

# Gestion des signaux
trap 'echo -e "\n${YELLOW}⚠️  Interruption détectée${NC}"; exit 1' INT TERM

# Exécuter le script principal
main "$@"
