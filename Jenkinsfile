def OWNER = 'thangsu'
def IMAGE_NAME = 'devops-lab'
def IMAGE_REGISTRY = "${OWNER}/${IMAGE_NAME}"
def IMAGE_BRANCH_TAG = "${IMAGE_REGISTRY}:${env.BRANCH_NAME}"
def REGISTRY_CREDENTIALS = "docker_tokens"
def REGISTRY_CRD = "docker_configjson"
def KUBERNETES_MANIFEST= "kubernetes/"
def PULL_SECRET = "registry-secret"
def CLUSTER_CREDENTIALS = "dev_k8s_kubeconfig"
def STAGING_NAMESPACE = "staging"
def PRODUCTION_NAMESPACE = "production"
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
    stages{
        stage('App image'){
            stages {
                stage('Build Docker image'){
                    steps{
                        sh 'mvn install'
                    }
                }
                stage('Build app images'){
                    steps{ 
                        sh "docker build -t ${IMAGE_REGISTRY}:${env.GIT_COMMIT[0..6]} ."
                    }
                }
                stage('Push app images to Docker'){
                    steps{
                        withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIALS}",usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASS')]){
                            sh "echo ${REGISTRY_PASS} | docker login -u ${REGISTRY_USER} --password-stdin"
                            sh "docker push ${IMAGE_REGISTRY}:${env.GIT_COMMIT[0..6]}"
                        }
                    }
                }
            }
        }
        stage('Deploy to staging namespace'){
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
                            withCredentials(
                                credentialsId: "${REGISTRY_CRD}",
                                variable: 'REGISTRY_ENCODE'
                            )
                            ]){
                                sh '''
                                cat <<EOF| kubectl apply -f - 
                                apiVersion: v1
                                kind: Secret
                                metadata:
                                name: myregistrykey
                                namespace: $(echo "${REGISTRY_ENCODE}")
                                data:
                                    .dockerconfigjson: $(echo "${REGISTRY_ENCODE}")
                                type: kubernetes.io/dockerconfigjson
                                EOF

                                kubectl get pod -A
                                '''
                            }
                        }
                    }
        
                }
            }
        }
    }
}