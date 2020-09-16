
# Default variables
export COMPONENTE_NAME=customer-api
export COMPONENTE_URL_BAR=http://meu.httpserver:8080/meu.bar
export REPLICAS=1
export TARGET_NAMESPACE=cp4i
export BAR_VERSION=1.0.0
export ACE_VERSION=11.0.0.9-r3
export OCP_URL=https://ocp.target.server:6443
export TARGET_ENV=dev
export TRUSTSTORE_FILE=truststore.p12
export KEYSTORE_FILE=keystore.p12
export POLICY_FILE=policies.zip


op_usage() {

	echo "Exemplo: /deploy-project.sh --policy policies.zip --component customer-api --ocpurl https://c101-e.us-south.containers.cloud.ibm.com:31963 -bv 1.0.0"
	echo ""
	echo "Parametros de Deployment"
	echo "-c  | --component     Nome do componente que será implantando"
	echo "-b  | --bar           [deprecated] URL com a localização do BAR"
	echo "-r  | --replicas      Número de replicas que serão criadas do Integration Server - default 1"     
	echo "-n  | --namespace     Namespace de deployment dos recursos  - default cp4i"
	echo "-bv | --bar-version   Versão do Bar que será implantado"
	echo "-av | --ace-version   Versão do ACE que será utilidado"
	echo "-s  | --ocpurl        URL do servidor do OpenShift que será utilizado"
	echo "-e  | --environment   Ambiente que será utilizado para deployment  - default dev"
	echo "-k  | --keystore      Nome do arquivo de keystore que será utilizado na configuração - default keystore.p12"
	echo "-t  | --truststore    Nome do arquivo de truststore que será utilizado na configuração - default truststore.p12"
	echo "-p  | --policy        Nome do arquivo de policy que será utilizado na configuração - default policies.zip"
	echo "-h  | --help          Help =)"

}


op_delete() {

	oc login --token=$(oc whoami -t) --server=${OCP_URL}
	#oc adm policy add-scc-to-group anyuid system:serviceaccounts:${TARGET_NAMESPACE}
	oc delete IntegrationServer ${COMPONENTE_NAME} --ignore-not-found=true -n ${TARGET_NAMESPACE}
	oc delete Configuration ${COMPONENTE_NAME}-setdbparms --ignore-not-found=true -n ${TARGET_NAMESPACE}
	oc delete Configuration ${COMPONENTE_NAME}-truststore-${TRUSTSTORE_FILE} --ignore-not-found=true -n ${TARGET_NAMESPACE}
	oc delete Configuration ${COMPONENTE_NAME}-keystore-${KEYSTORE_FILE} --ignore-not-found=true -n ${TARGET_NAMESPACE}
	oc delete Configuration ${COMPONENTE_NAME}-accounts --ignore-not-found=true -n ${TARGET_NAMESPACE}
    oc delete Configuration ${COMPONENTE_NAME}-odbc --ignore-not-found=true -n ${TARGET_NAMESPACE}
    oc delete Configuration ${COMPONENTE_NAME}-policyproject --ignore-not-found=true -n ${TARGET_NAMESPACE}
    oc delete Configuration ${COMPONENTE_NAME}-serverconf --ignore-not-found=true -n ${TARGET_NAMESPACE}


	oc delete secret ${COMPONENTE_NAME}-setdbparms --ignore-not-found=true -n ${TARGET_NAMESPACE}
	oc delete secret ${COMPONENTE_NAME}-truststore --ignore-not-found=true -n ${TARGET_NAMESPACE}
	oc delete secret ${COMPONENTE_NAME}-keystore --ignore-not-found=true -n ${TARGET_NAMESPACE}
	oc delete secret ${COMPONENTE_NAME}-accounts --ignore-not-found=true -n ${TARGET_NAMESPACE}

}

op_deploy() {


	oc create secret generic ${COMPONENTE_NAME}-setdbparms --from-file=configuration=./initial-config-${TARGET_ENV}/setdbparms/setdbparms.txt -n ${TARGET_NAMESPACE}
	oc create secret generic ${COMPONENTE_NAME}-truststore --from-file=configuration=./initial-config-${TARGET_ENV}/truststore/${TRUSTSTORE_FILE} -n ${TARGET_NAMESPACE}
	oc create secret generic ${COMPONENTE_NAME}-keystore   --from-file=configuration=./initial-config-${TARGET_ENV}/keystore/${KEYSTORE_FILE} -n ${TARGET_NAMESPACE}
	oc create secret generic ${COMPONENTE_NAME}-accounts --from-file=configuration=./initial-config-${TARGET_ENV}/accounts/accounts.yaml -n ${TARGET_NAMESPACE}

	oc create -f ./.deploy/configuration.yaml -n ${TARGET_NAMESPACE}
	oc create -f ./.deploy/integration-server.yaml -n ${TARGET_NAMESPACE}
	
}

# Main start here

while [ "$1" != "" ]; do
    case $1 in
        -c | --component )      
			shift
            COMPONENTE_NAME="$1"
            ;;
        -b | --bar )    
			shift
            COMPONENTE_URL_BAR="$1"
            ;;
        -r | --replicas )    
			shift
            REPLICAS="$1"
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
        -s | --ocpurl )    
			shift
            OCP_URL="$1"
            ;;
        -e | --environment )    
			shift
            TARGET_ENV="$1"
            ;;   
        -k | --keytore )    
			shift
            KEYSTORE_FILE="$1"
            ;;  
        -t | --truststore )    
			shift
            TRUSTSTORE_FILE="$1"
            ;;    
        -p | --policy )    
			shift
            POLICY_FILE="$1"
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

echo "========================== DADOS DO DEPLOYMENT ======================================="
echo "Fazendo Deployment do Componente: ${COMPONENTE_NAME}"
echo "BAR VERSION: ${BAR_VERSION}"
echo "ACE VERSION: ${ACE_VERSION}"
echo "NAMESPACE: ${TARGET_NAMESPACE}"
echo "Ambiente Config: ${TARGET_ENV}"
echo "OpenShift URL: ${OCP_URL}" 
echo "======================================================================================"

echo ""
echo ""


rm -Rf ./.deploy
mkdir ./.deploy

#TODO
# Jogar o serverconf e policyproject e talvez o odbc como content usando sed dentro do configuration mapeando o base64 
# para uma variável de ambiente visto que estes componentes não suportam secret.

export B64_SERVERCONF=$(base64 ./initial-config-${TARGET_ENV}/serverconf/server.conf.yaml)
export B64_POLICYPROJ=$(base64 ./initial-config-${TARGET_ENV}/policy/${POLICY_FILE})
export B64_ODBC=$(base64 ./initial-config-${TARGET_ENV}/odbcini/odbc.ini)

#sed "s/@COMPONENTE_NAME@/${COMPONENTE_NAME}/g" integration-server.yaml | sed "s/@COMPONENTE_URL_BAR@/${COMPONENTE_URL_PROTOCOL}:\/\/${COMPONENTE_URL_HOST}:${COMPONENTE_URL_PORT}\/${COMPONENTE_URL_FILE}/g" | sed "s/@TARGET_REPOSITORY@/${TARGET_REPOSITORY}/g" | sed "s/@NAMESPACE@/${TARGET_NAMESPACE}/g" | sed "s/@VERSION@/${VERSION}/g"  > ./.deploy/integration-server.yaml
awk -v COMPONENTE_NAME=$COMPONENTE_NAME '{gsub("@COMPONENTE_NAME@",COMPONENTE_NAME);print}' integration-server.yaml | awk -v COMPONENTE_URL_BAR=$COMPONENTE_URL_BAR '{gsub("@COMPONENTE_URL_BAR@",COMPONENTE_URL_BAR);print}' | awk -v REPLICAS=$REPLICAS '{gsub("@REPLICAS@",REPLICAS);print}' | awk -v TARGET_NAMESPACE=$TARGET_NAMESPACE '{gsub("@NAMESPACE@",TARGET_NAMESPACE);print}' | awk -v KEYSTORE_FILE=$KEYSTORE_FILE '{gsub("@KEYSTORE_FILE@",KEYSTORE_FILE);print}' | awk -v TRUSTSTORE_FILE=$TRUSTSTORE_FILE '{gsub("@TRUSTSTORE_FILE@",TRUSTSTORE_FILE);print}' | awk -v ACE_VERSION=$ACE_VERSION '{gsub("@ACE_VERSION@",ACE_VERSION);print}' | awk -v BAR_VERSION=$BAR_VERSION '{gsub("@BAR_VERSION@",BAR_VERSION);print}' > ./.deploy/integration-server.yaml

#sed "s/@COMPONENTE_NAME@/${COMPONENTE_NAME}/g" configuration.yaml | sed "s/@B64_ODBC@/${B64_ODBC}/g" | sed "s/@B64_POLICYPROJ@/${B64_POLICYPROJ}/g" | sed "s/@B64_SERVERCONF@/${B64_SERVERCONF}/g" | sed "s/@NAMESPACE@/${TARGET_NAMESPACE}/g"   > ./.deploy/configuration.yaml
awk -v COMPONENTE_NAME=$COMPONENTE_NAME '{gsub("@COMPONENTE_NAME@",COMPONENTE_NAME);print}' configuration.yaml | awk -v B64_POLICYPROJ=$B64_POLICYPROJ '{gsub("@B64_POLICYPROJ@",B64_POLICYPROJ);print}' | awk -v B64_SERVERCONF=$B64_SERVERCONF '{gsub("@B64_SERVERCONF@",B64_SERVERCONF);print}' | awk -v KEYSTORE_FILE=$KEYSTORE_FILE '{gsub("@KEYSTORE_FILE@",KEYSTORE_FILE);print}' | awk -v TRUSTSTORE_FILE=$TRUSTSTORE_FILE '{gsub("@TRUSTSTORE_FILE@",TRUSTSTORE_FILE);print}' | awk -v B64_ODBC=$B64_ODBC '{gsub("@B64_ODBC@",B64_ODBC);print}' | awk -v TARGET_NAMESPACE=$TARGET_NAMESPACE '{gsub("@NAMESPACE@",TARGET_NAMESPACE);print}' > ./.deploy/configuration.yaml

if [ "$EXEC_DRY_RUN" = "1" ]; then

	echo " ============================="
	echo " EXECUTANDO EM MODO DE DRY-RUN"
	echo " ============================="
	echo ""
	echo " INTEGRATION-SERVER RESOURCE"
	echo " ============================="
	echo ""
	cat ./.deploy/integration-server.yaml
	echo ""
	echo " CONFIGURATION RESOURCE"
	echo " ============================="
	echo ""
	cat ./.deploy/configuration.yaml
	exit
else
	op_delete
	op_deploy
fi

