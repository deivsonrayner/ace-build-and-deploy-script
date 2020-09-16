export TARGET_NAMESPACE=cp4i
export IBM_ENTITLEMENT_KEY=DEFINA_AQUI_SEU_KEY
export COMPONENTE_NAME=customer-api
export ACE_VERSION=11.0.0.9-r3
export BAR_VERSION=1.0.0
# Based on reference https://www.ibm.com/support/knowledgecenter/en/SSTTDS_11.0.0/com.ibm.ace.icp.doc/certc_install_obtaininstallationimageser.html
export ACE_IMAGE=ace-server-prod@sha256:8df2fc5e76aa715e2b60a57920202cd000748476558598141a736c1b0eb1f1a3

op_setup_build() {

oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password=${IBM_ENTITLEMENT_KEY} --docker-server=cp.icr.io -n ${TARGET_NAMESPACE}

oc delete imagestream ace-server-prod --ignore-not-found=true -n ${TARGET_NAMESPACE}
echo "Creating Input ImageStream"
echo ""
oc create -f - <<EOF
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
 name: ace-server-prod
 namespace: ${TARGET_NAMESPACE}
EOF

oc tag -n ${TARGET_NAMESPACE} cp.icr.io/cp/appc/${ACE_IMAGE} ace-server-prod:${ACE_VERSION}

oc delete imagestream ${COMPONENTE_NAME} --ignore-not-found=true -n ${TARGET_NAMESPACE}
echo "Creating output ImageStream"
echo ""
oc create -f - <<EOF
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
 name: ${COMPONENTE_NAME}
 namespace: ${TARGET_NAMESPACE}
EOF

oc delete bc ${COMPONENTE_NAME} --ignore-not-found=true -n ${TARGET_NAMESPACE}
echo "Creating BuildConfig"
echo ""
oc create -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
 name: ${COMPONENTE_NAME}
 namespace: ${TARGET_NAMESPACE}
 labels:
   name: ${COMPONENTE_NAME}
spec:
 triggers: []
 source:
   type: dockerfile
   dockerfile: |-
     FROM ace-server-prod:${ACE_VERSION}
     COPY  ./bar/${COMPONENTE_NAME}.bar /home/aceuser/initial-config/bars/${COMPONENTE_NAME}.bar
 strategy:
   type: Docker
   dockerStrategy:
     from:
       kind: ImageStreamTag
       name: 'ace-server-prod:${ACE_VERSION}'
       namespace: ${TARGET_NAMESPACE} 
 output:
   to:
     kind: ImageStreamTag
     name: '${COMPONENTE_NAME}:${BAR_VERSION}'
     namespace: ${TARGET_NAMESPACE}
EOF

echo "Seting Up the Secret"
echo ""
oc set build-secret --pull bc/${COMPONENTE_NAME} ibm-entitlement-key -n ${TARGET_NAMESPACE}

}


op_usage() {

  echo "Exemplo: /setup-buildconfig.sh --component customer-api -bv 1.0.0 -av 11.0.0.9-r3 -i ace-server-prod@sha256:8df2fc5e76aa715e2b60a57920202cd000748476558598141a736c1b0eb1f1a3 -k <IBM_ENTITLEMENT_KEY>"
  echo ""
  echo "Parametros de Deployment"
  echo "-c  | --component     Nome do componente que será implantando"
  echo "-n  | --namespace     Namespace de deployment dos recursos  - default cp4i"
  echo "-bv | --bar-version   Versão do Bar que será implantado"
  echo "-av | --ace-version   Versão do ACE que será utilidado"
  echo "-i  | --ace-image     ImageStream da Versão do ACE que deverá ser utiliada"
  echo "-k  | --ibm-key       Entitlement Key para Acesso ao IBM Registry"
  echo "-h  | --help          Help =)"
  echo ""
  echo "Depois de criada a configuração de Build um build novo da imagem poderá ser feito usando:"
  echo ""
  echo "oc start-build <COMPONENTE_NAME> --from-dir=./build/"
  echo ""
}


while [ "$1" != "" ]; do
    case $1 in
        -c | --component )      
      shift
            COMPONENTE_NAME="$1"
            ;;
        -n | --namespace )    
      shift
            TARGET_NAMESPACE="$1"
            ;;
        -bv | --bar-version )    
      shift
            BAR_VERSION="$1"
            ;;  
        -av | --ace-version )    
      shift
            ACE_VERSION="$1"
            ;;
        -i | --ace-image )    
      shift
            ACE_IMAGE="$1"
            ;;
        -k | --ibm-key )    
      shift
            IBM_ENTITLEMENT_KEY="$1"
            ;;
        -dr | --dry-run )    
            EXEC_DRY_RUN=1
            ;;
        -h | --help )           
            op_usage
            exit
            ;;
        * )                    
      op_usage
            exit 1
    esac
    shift
done

echo ""
echo ""

echo "========================== Preparando BUILD CONFIG ==================================="
echo "Componente: ${COMPONENTE_NAME}"
echo "BAR VERSION: ${BAR_VERSION}"
echo "ACE VERSION: ${ACE_VERSION}"
echo "NAMESPACE: ${TARGET_NAMESPACE}"
echo "ACE IMAGE: ${ACE_IMAGE}"
echo "======================================================================================"

echo ""
echo ""


if [ "$EXEC_DRY_RUN" = "1" ]; then

  echo " ============================="
  echo " EXECUTANDO EM MODO DE DRY-RUN"
  echo " ============================="
  echo ""
  echo " Fluxo de Comandos de Configuração"
  echo " ============================="
  echo ""
  echo "STEP 1 - Criação do Secret para acesso ao Image Registry da IBM"
  echo "==================================================================================="
  echo "oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password=${IBM_ENTITLEMENT_KEY} --docker-server=cp.icr.io -n ${TARGET_NAMESPACE}"
  echo ""
  echo "STEP 2 - Delete do Input ImageStream original e criação de novo ImageStream"
  echo "==================================================================================="
  echo "oc delete imagestream ace-server-prod --ignore-not-found=true -n ${TARGET_NAMESPACE}"
  echo "oc create -f - <<EOF"
  echo "apiVersion: image.openshift.io/v1"
  echo "kind: ImageStream"
  echo "metadata:"
  echo "  name: ace-server-prod"
  echo "  namespace: ${TARGET_NAMESPACE}"
  echo "EOF"
  echo ""
  echo "STEP 3 - Criação de uma Tag para o ImageStream do ACE"
  echo "==================================================================================="
  echo "oc tag -n ${TARGET_NAMESPACE} cp.icr.io/cp/appc/${ACE_IMAGE} ace-server-prod:${ACE_VERSION}"
  echo ""
  echo "STEP 4 - Delete do Output ImageStream e criação de novo ImageStream"
  echo "==================================================================================="
  echo "oc delete imagestream ${COMPONENTE_NAME} --ignore-not-found=true -n ${TARGET_NAMESPACE}"
  echp "oc create -f - <<EOF"
  echo "apiVersion: image.openshift.io/v1"
  echo "kind: ImageStream"
  echo "metadata:"
  echo "  name: ${COMPONENTE_NAME}"
  echo "  namespace: ${TARGET_NAMESPACE}"
  echo "EOF"
  echo ""
  echo "STEP 5 - Delete do BuildConfig e criação de novo BuildConfig"
  echo "==================================================================================="
  echo "oc delete bc ${COMPONENTE_NAME} --ignore-not-found=true -n ${TARGET_NAMESPACE}"
  echo "oc create -f - <<EOF"
  echo "apiVersion: build.openshift.io/v1"
  echo "kind: BuildConfig"
  echo "metadata:"
  echo "  name: ${COMPONENTE_NAME}"
  echo "  namespace: ${TARGET_NAMESPACE}"
  echo "  labels:"
  echo "    name: ${COMPONENTE_NAME}"
  echo "spec:"
  echo "  triggers: []"
  echo "  source:"
  echo "    type: dockerfile"
  echo "    dockerfile: |-"
  echo "      FROM ace-server-prod:${ACE_VERSION}"
  echo "      COPY  ./bar/${COMPONENTE_NAME}.bar /home/aceuser/initial-config/bars/${COMPONENTE_NAME}.bar"
  echo "  strategy:"
  echo "    type: Docker"
  echo "    dockerStrategy:"
  echo "      from:"
  echo "        kind: ImageStreamTag"
  echo "        name: ace-server-prod:${ACE_VERSION}"
  echo "        namespace: ${TARGET_NAMESPACE}"
  echo "  output:"
  echo "    to:"
  echo "      kind: ImageStreamTag"
  echo "      name: '${COMPONENTE_NAME}:${BAR_VERSION}'"
  echo "      namespace: ${TARGET_NAMESPACE}"
  echo "EOF"
  echo ""
  echo "STEP 6 - Configuração do Secret no build-config"
  echo "==================================================================================="
  echo "oc set build-secret --pull bc/${COMPONENTE_NAME} ibm-entitlement-key -n ${TARGET_NAMESPACE}"

  exit
else
  op_setup_build
fi