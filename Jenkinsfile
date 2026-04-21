pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        timestamps()
    }

    environment {
        GIT_REPO_URL = 'https://github.com/Kheav-Kienghok/DevOp-Final.git'
        GIT_BRANCH = 'main'

        IMAGE_NAME = 'kienghok/aupp-lms'
        IMAGE_TAG  = "${BUILD_NUMBER}"

        SONARQUBE_SERVER = 'sonarqube-server'

        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        EC2_HOST = ''
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO_URL}"
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh '''
                        sonar-scanner
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    trivy fs \
                      --severity CRITICAL,HIGH \
                      --exit-code 1 \
                      --no-progress .
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${IMAGE_TAG}", "-f app/Dockerfile ./app")
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh """
                    trivy image \
                      --severity CRITICAL,HIGH \
                      --exit-code 1 \
                      --no-progress ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKERHUB_CREDENTIALS}") {
                        docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push("latest")
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('infra/terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('infra/terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('infra/terraform') {
                    sh '''
                        terraform plan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infra/terraform') {
                    sh '''
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Get EC2 Host From Terraform Output') {
            steps {
                script {
                    env.EC2_HOST = sh(
                        script: 'cd infra/terraform && terraform output -raw ec2_public_ip',
                        returnStdout: true
                    ).trim()

                    if (!env.EC2_HOST) {
                        error('Terraform output ec2_public_ip is empty.')
                    }

                    echo "EC2 host resolved from Terraform output: ${env.EC2_HOST}"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        scp -r -o StrictHostKeyChecking=no deploy ubuntu@${EC2_HOST}:/home/ubuntu/

                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} "
                            docker pull ${IMAGE_NAME}:${IMAGE_TAG}
                            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                            
                            cd /home/ubuntu/deploy
                            docker-compose down || true
                            docker-compose up -d
                            docker ps
                        "
                    '''
                }
            }
        }

        stage('Verify Application') {
            steps {
                sh '''
                    echo "Checking application..."
                    curl -I http://${EC2_HOST}:8000 || true
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline SUCCESS'
        }
        failure {
            echo 'Pipeline FAILED'
        }
        always {
            echo 'Pipeline finished'
        }
    }
}