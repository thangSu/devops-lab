def OWNER = 'thangsu'
def IMAGE_NAME = 'devops-lab'
def IMAGE_REGISTRY = "${OWNER}/${IMAGE_NAME}"
def IMAGE_BRANCH_TAG = "${IMAGE_REGISTRY}:${env.BRANCH_NAME}"
def REGISTRY_CREDENTIALS = "docker_tokens"
def REGISTRY_URL="index.docker.io"
def KUBERNETES_MANIFEST= "kubernetes/"
def PULL_SECRET = "registry-secret"
def CLUSTER_CREDENTIALS = "dev_k8s_kubeconfig"
def STAGING_NAMESPACE = "staging"
def PRODUCTION_NAMESPACE = "production"

def HELM_VALUE = "dev-app/values-jenkins.yaml"
def HELM_PROD_VALUE = "dev-app/values-prod-jenkins.yaml"
def HELM_DEV_VALUE = "dev-app/values-dev-jenkins.yaml"

def INGRESS_DEV_DOMAIN = "dev-app.kameyoko.online"
def INGRESS_RPOD_DOMAIN = "prod-app.kameyoko.online"

def KUBECTL_POD = """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: alpine/k8s:1.29.13
    command:
    - cat
    tty: true
"""
pipeline{
    agent any 
    // tools {
    //     maven 'MAVEN3.9'
    // }
    stages{
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('App image'){
            stages {
                stage('Build Docker image'){
                    tools{
                        maven "MAVEN3.9"
                        jdk 'JDK21'
                    }
                    steps{
                        sh 'mvn install'
                    }
                }
                stage('Build app images'){
                    steps{ 
                        sh "docker build -t ${IMAGE_BRANCH_TAG}:${env.GIT_COMMIT[0..6]} ."
                    }
                }
                stage('Push app images to Docker'){
                    steps{
                        withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIALS}",usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASS')]){
                            sh "echo ${REGISTRY_PASS} | docker login -u ${REGISTRY_USER} --password-stdin"
                            sh "docker push ${IMAGE_BRANCH_TAG}:${env.GIT_COMMIT[0..6]}"
                        }
                    }
                }
            }
        }
        stage('Deploy app'){
            agent { kubernetes label: 'docker', yaml: "${KUBECTL_POD}" }
            stages{
                
                stage('Deploy Image to Staging'){
                    steps{
                        container('kubectl'){
                            withCredentials([
                            file(
                                credentialsId: "${CLUSTER_CREDENTIALS}",
                                variable: 'KUBECONFIG'
                            ),
                             usernamePassword(
                            credentialsId: "${REGISTRY_CREDENTIALS}",
                            usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASS'
                            )
                            ]){
                                sh """
                                kubectl \
                                -n ${STAGING_NAMESPACE} \
                                create secret docker-registry ${PULL_SECRET} \
                                --docker-server=${REGISTRY_URL} \
                                --docker-username=${REGISTRY_USER} \
                                --docker-password=${REGISTRY_PASS} \
                                --dry-run=client \
                                -o yaml \
                                | kubectl apply -f -

                                sed \
                                -e "s|{{NAMESPACE}}|${STAGING_NAMESPACE}|g" \
                                -e "s|{{IMAGE}}|${IMAGE_REGISTRY}|g" \
                                -e "s|{{TAG}}|${env.GIT_COMMIT[0..6]}|g" \
                                -e "s|{{PULL_SECRET}}|${PULL_SECRET}|g" \
                                -e "s|{{INGRESS_DOMAIN}}|${INGRESS_DEV_DOMAIN}|g" \
                                ${HELM_VALUE} > ${HELM_DEV_VALUE}
                                
                                cat ${HELM_DEV_VALUE}
                                
                                helm upgrade --install test ./dev-app -n $STAGING_NAMESPACE -f ${HELM_DEV_VALUE}
                                k delete pod -l app=dev-rabbitmq -n $STAGING_NAMESPACE

                                """
                            }
                        }
                    }
                }
                stage("Manual review"){
                    agent none
                    steps{
                        timeout(time: 2,unit: 'DAYS'){
                            input message: 'Deploy image to production?'
                        }
                    }
                }
                stage('Deploy Image to Productions'){
                    steps{
                        container('kubectl'){
                            withCredentials([
                            file(
                                credentialsId: "${CLUSTER_CREDENTIALS}",
                                variable: 'KUBECONFIG'
                            ),
                             usernamePassword(
                            credentialsId: "${REGISTRY_CREDENTIALS}",
                            usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASS'
                            )
                            ]){
                                sh """
                                kubectl \
                                -n ${PRODUCTION_NAMESPACE} \
                                create secret docker-registry ${PULL_SECRET} \
                                --docker-server=${REGISTRY_URL} \
                                --docker-username=${REGISTRY_USER} \
                                --docker-password=${REGISTRY_PASS} \
                                --dry-run=client \
                                -o yaml \
                                | kubectl apply -f -

                                sed \
                                -e "s|{{NAMESPACE}}|${PRODUCTION_NAMESPACE}|g" \
                                -e "s|{{IMAGE}}|${IMAGE_REGISTRY}|g" \
                                -e "s|{{TAG}}|${env.GIT_COMMIT[0..6]}|g" \
                                -e "s|{{PULL_SECRET}}|${PULL_SECRET}|g" \
                                -e "s|{{INGRESS_DOMAIN}}|${INGRESS_RPOD_DOMAIN}|g" \
                                ${HELM_VALUE} > ${HELM_PROD_VALUE}
                                
                                cat ${HELM_PROD_VALUE}
                                
                                helm upgrade --install prod-app ./dev-app -n $PRODUCTION_NAMESPACE -f ${HELM_PROD_VALUE}

                                k delete pod -l app=dev-rabbitmq -n $PRODUCTION_NAMESPACE

                                """
                            }
                        }
                    }
                }
            }
        }
    }
}