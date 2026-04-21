pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        timestamps()
        skipDefaultCheckout(true)
    }

    environment {
        GIT_REPO_URL = 'https://github.com/Kheav-Kienghok/DevOp-Final.git'
        GIT_BRANCH = 'main'

        IMAGE_NAME = 'kienghok/aupp-lms'
        IMAGE_TAG  = "${BUILD_NUMBER}"

        SONAR_SCANNER_HOME = tool 'Sonar-Scan'

        DOCKERHUB_USER = 'kienghok'
        DOCKERHUB_PASSWORD = credentials('dockerhub-password')

        AWS_CREDENTIALS = 'aws-credentials'
        AWS_DEFAULT_REGION = 'us-east-1'

        EC2_HOST = ''
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO_URL}"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('sonar-scanner') {
                        sh "${SONAR_SCANNER_HOME}/bin/sonar-scanner"
                    }
                }
                echo 'Scanning Done'
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh '''
                    trivy fs --severity CRITICAL,HIGH \
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
                    trivy image --severity CRITICAL,HIGH \
                                --ignore-unfixed \
                                --exit-code 1 \
                                --no-progress ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    echo "${DOCKERHUB_PASSWORD}" | docker login -u "${DOCKERHUB_USER}" --password-stdin
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                    docker push ${IMAGE_NAME}:latest
                    docker logout
                '''
            }
        }

        stage('Terraform (Init → Apply)') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}"
                ]]) {
                    dir('infra/terraform') {
                        sh '''
                            terraform init
                            terraform validate
                            terraform plan
                            terraform apply -auto-approve --replace="module.compute.aws_instance.this"
                        '''
                    }
                }
            }
        }

        stage('Get EC2 Host') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}"
                ]]) {
                    dir('infra/terraform') {
                        script {
                            def ec2PublicIp = ''
                            def ec2InstanceId = ''

                            // Fresh state can be briefly unavailable right after apply; retry first.
                            retry(6) {
                                ec2PublicIp = sh(
                                    script: 'terraform output -raw ec2_public_ip',
                                    returnStdout: true
                                ).trim()

                                if (!ec2PublicIp || ec2PublicIp == 'null') {
                                    echo 'ec2_public_ip not ready yet, retrying in 10s...'
                                    sleep(time: 10, unit: 'SECONDS')
                                    error('retry ec2_public_ip')
                                }
                            }

                            if (!ec2PublicIp || ec2PublicIp == 'null') {
                                ec2InstanceId = sh(
                                    script: 'terraform output -raw ec2_instance_id',
                                    returnStdout: true
                                ).trim()

                                if (ec2InstanceId && ec2InstanceId != 'null') {
                                    ec2PublicIp = sh(
                                        script: "aws ec2 describe-instances --instance-ids ${ec2InstanceId} --region ${AWS_DEFAULT_REGION} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null || true",
                                        returnStdout: true
                                    ).trim()

                                    if (ec2PublicIp == 'None') {
                                        ec2PublicIp = ''
                                    }
                                }
                            }

                            if (!ec2PublicIp || ec2PublicIp == 'null') {
                                sh 'terraform output -raw ec2_public_ip'
                                error('Unable to resolve EC2 public IP from Terraform output and AWS API.')
                            }

                            env.EC2_HOST = ec2PublicIp
                            echo "EC2 Host: ${env.EC2_HOST}"
                        }
                    }
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
                            docker compose down || true
                            docker compose up -d
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