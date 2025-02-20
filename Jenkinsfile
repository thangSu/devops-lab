def REGISTRY_URL = 'registry.hub.docker.com'
def OWNER = 'thangsu'
def REPO_NAME = 'devops-lab'
def IMAGE_NAME = 'dev-app'

def IMAGE_REGISTRY = "${REGISTRY_URL}/${OWNER}/${REPO_NAME}/${IMAGE_NAME}"
def IMAGE_BRANCH_TAG = "${IMAGE_REGISTRY}:${env.BRANCH_NAME}"

def REGISTRY_CREDENTIALS = 'docker_tokens'
def CLUSTER_CREDENTIALS = 'dev_k8s_kubeconfig'

def KUBERNETES_MANIFEST = 'kubernetes-manifest.yaml'
def STAGING_NAMESPACE = 'staging'
def PRODUCTION_NAMESPACE = 'production'
def PULL_SECRET = "registry-${REGISTRY_CREDENTIALS}"

def DOCKER_HOST_VALUE = 'tcp://dind.default:2375'

def DOCKER_POD = """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:19.03.6
    command:
    - cat
    tty: true
    env:
    - name: DOCKER_HOST
      value: ${DOCKER_HOST_VALUE}
"""
pipeline {
  agent any
  stages {
    stage('Run Docker') {
      agent { kubernetes label: 'docker', yaml: "${DOCKER_POD}" }
      stages {
        stage('Build Docker Image') {
          steps {
            container('docker') {
              sh "docker build -t ${IMAGE_BRANCH_TAG}.${env.GIT_COMMIT[0..6]} ."
            }
          }
        }
        stage('Push Image to Registry') {
          steps {
            container('docker') {
              withCredentials([
                usernamePassword(
                  credentialsId: "${REGISTRY_CREDENTIALS}",
                  usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASS'
                )
              ]) {
                sh """
                echo ${REGISTRY_PASS} | docker login ${REGISTRY_URL} -u ${REGISTRY_USER} --password-stdin
                docker push ${IMAGE_BRANCH_TAG}.${env.GIT_COMMIT[0..6]}
                docker tag ${IMAGE_BRANCH_TAG}.${env.GIT_COMMIT[0..6]} ${IMAGE_BRANCH_TAG}
                docker push ${IMAGE_BRANCH_TAG}
                """
              }
            }
          }
        }
      }
    }
    }
}