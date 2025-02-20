def OWNER = 'thangsu'
def IMAGE_NAME = 'devops-lab'
def IMAGE_REGISTRY = "${OWNER}/${IMAGE_NAME}"
def IMAGE_BRANCH_TAG = "${IMAGE_REGISTRY}:${env.BRANCH_NAME}"

pipeline{
    agent any 
    stages{
        stage('Docker image'){
            stages {
                stage('Build Docker image'){
                    steps{
                        sh 'nvm install'
                    }
                }
                stage('Push Image to Registry'){
                    steps{
                        sh 'docker build -t ${IMAGE_BRANCH_TAG}-${env.GIT_COMMIT[0..6]} .'
                    }
                }
            }
        }
        
    }
}