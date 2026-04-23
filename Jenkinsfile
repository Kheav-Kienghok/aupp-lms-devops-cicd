pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    /* ---------------------------
     * PARAMETERS (Optional override)
     * --------------------------- */
    parameters {
        string(
            name: 'SONAR_HOST_URL_OVERRIDE',
            defaultValue: '',
            description: 'Optional SonarQube URL (only for report, leave empty to use Jenkins config)'
        )
    }

    environment {
        /* ---------------------------
         * SOURCE
         * --------------------------- */
        GIT_REPO_URL = 'https://github.com/Kheav-Kienghok/aupp-lms-devops-cicd.git'
        GIT_BRANCH   = 'main'

        /* ---------------------------
         * SONAR
         * --------------------------- */
        SONAR_SCANNER_HOME = tool 'Sonar-Scan'
        SONAR_SERVER = 'sonar-scanner'
        SONAR_PROJECT_KEY = 'aupp-lms-backend'

        /* ---------------------------
         * DOCKER
         * --------------------------- */
        IMAGE_NAME = 'kienghok/aupp-lms'
        IMAGE_TAG  = "v${BUILD_NUMBER}"

        /* ---------------------------
         * AWS
         * --------------------------- */
        AWS_CREDENTIALS = 'aws-credentials'
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {

        /* ---------------------------
         * 1. CHECKOUT
         * --------------------------- */
        stage('Checkout') {
            steps {
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO_URL}"
            }
        }

        /* ---------------------------
         * 2. BUILD
         * --------------------------- */
        stage('Build Application') {
            steps {
                sh 'echo "Build step placeholder"'
            }
        }

        /* ---------------------------
         * 3. TEST
         * --------------------------- */
        stage('Unit Tests') {
            steps {
                sh 'echo "Run tests here"'
            }
        }

        /* ---------------------------
         * 4. SONAR ANALYSIS
         * --------------------------- */
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh """
                        ${SONAR_SCANNER_HOME}/bin/sonar-scanner
                    """
                }
            }
        }

        /* ---------------------------
         * 5. QUALITY GATE
         * --------------------------- */
        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        /* ---------------------------
         * 6. CNES REPORT GENERATION
         * --------------------------- */
        stage('Generate Sonar CNES Report') {
            steps {
                withSonarQubeEnv('sonar-scanner') {
                    script {
                        def sonarUrl = params.SONAR_HOST_URL_OVERRIDE?.trim()
                        if (!sonarUrl) {
                            sonarUrl = env.SONAR_HOST_URL
                        }

                        sh """
                            set -e

                            mkdir -p reports/sonar

                            command -v redcoffee >/dev/null 2>&1 || { echo "redcoffee is not installed on this Jenkins node"; exit 1; }

                            redcoffee generatepdf \
                                --host=${sonarUrl} \
                                --project=${SONAR_PROJECT_KEY} \
                                --path=./ \
                                --token=$SONAR_AUTH_TOKEN

                            ls -lah

                            docker run --rm \
                                -v "\$WORKSPACE":/pdf \
                                -w /pdf \
                                sergiomtzlosa/pdf2htmlex \
                                pdf2htmlEX ./generated-sonarqube-report.pdf ./reports/sonar/generated-sonarqube-report.html
                        """
                    }
                }
            }
        }

        /* ---------------------------
         * 7. PUBLISH HTML REPORT
         * --------------------------- */
        stage('Publish Sonar HTML Report') {
            steps {
                publishHTML([
                    reportDir: 'reports/sonar',
                    reportFiles: 'generated-sonarqube-report.html',
                    reportName: 'Sonar PDF Report (HTML)',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: false
                ])
            }
        }

        /* ---------------------------
         * 8. SECURITY SCAN
         * --------------------------- */
        stage('Filesystem Security Scan (Trivy)') {
            steps {
                sh """
                    trivy fs \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --no-progress ./app
                """
            }
        }

        /* ---------------------------
         * 9. DOCKER BUILD
         * --------------------------- */
        stage('Docker Build') {
            steps {
                script {
                    env.IMAGE_FULL = "${IMAGE_NAME}:${IMAGE_TAG}"
                    docker.build(env.IMAGE_FULL, "-f app/Dockerfile ./app")
                }
            }
        }

        /* ---------------------------
         * 10. CONTAINER SCAN
         * --------------------------- */
        stage('Container Security Scan (Trivy)') {
            steps {
                sh """
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --exit-code 1 \
                        --no-progress ${IMAGE_FULL}
                """
            }
        }

        /* ---------------------------
         * 11. PUSH IMAGE
         * --------------------------- */
        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                        docker push $IMAGE_FULL

                        docker tag $IMAGE_FULL $IMAGE_NAME:latest
                        docker push $IMAGE_NAME:latest

                        docker logout
                    '''
                }
            }
        }

        /* ---------------------------
         * 12. INFRASTRUCTURE
         * --------------------------- */
        stage('Provision Infrastructure') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"],
                    sshUserPrivateKey(
                        credentialsId: 'ec2-pem-content',
                        keyFileVariable: 'SSH_KEY_FILE',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    dir('infra/terraform') {
                        sh '''
                            set -e
                            chmod 400 "$SSH_KEY_FILE"

                            terraform init
                            terraform apply -auto-approve \
                                -var="ssh_private_key_path=$SSH_KEY_FILE" \
                                -var="ssh_user=$SSH_USER"
                        '''

                        script {
                            env.EC2_HOST = sh(
                                script: "terraform output -raw ec2_public_ip",
                                returnStdout: true
                            ).trim()

                            env.ANSIBLE_INVENTORY = 'infra/ansible/inventory.ini'
                        }
                    }
                }
            }
        }

        /* ---------------------------
         * 13. Deploy to EC2 with Ansible
         * --------------------------- */
        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-pem-content',
                    keyFileVariable: 'SSH_KEY_FILE',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh """
                        set -e
                        chmod 400 "\$SSH_KEY_FILE"

                        ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \\
                            --private-key "\$SSH_KEY_FILE" \\
                            -u "\$SSH_USER" \\
                            -i infra/ansible/inventory.ini \\
                            infra/ansible/playbooks/deploy.yml \\
                            --extra-vars "image_repo=${IMAGE_NAME} image_tag=${IMAGE_TAG} image_full=${IMAGE_FULL}"
                    """
                }
            }
        }

        /* ---------------------------
         * 14. SMOKE TEST
         * --------------------------- */
        stage('Smoke Test') {
            steps {
                sh """
                    curl -f http://${env.EC2_HOST}:8000 || exit 1
                """
            }
        }
    }

    /* ---------------------------
     * POST ACTIONS
     * --------------------------- */
    post {
        success {
            echo "✅ Pipeline SUCCESS — build ${BUILD_NUMBER}"
        }

        failure {
            echo "❌ Pipeline FAILED — check logs"
        }
    }
}