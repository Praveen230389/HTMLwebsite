pipeline {
  agent any

  environment {
    SONAR_HOST_URL       = 'http://localhost:9000'
    SONAR_AUTH_TOKEN     = credentials('sonar-token')
    SSH_CREDENTIAL_ID    = 'jenkins-ssh-key'
    DOCKER_REGISTRY      = 'mydockerhubuser/html-site'
    REGISTRY_CREDENTIALS = 'dockerhub-credentials'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('My SonarQube') {
          sh """
            sonar-scanner \
              -Dsonar.projectKey=html-site \
              -Dsonar.host.url=${SONAR_HOST_URL} \
              -Dsonar.login=${SONAR_AUTH_TOKEN}
          """
        }
      }
    }

    stage('Deploy to Docker Nodes') {
      steps {
        script {
          def servers = [
            'ubuntu@3.83.13.163',
            'ubuntu@3.86.222.136',
            'ubuntu@3.91.44.187'
          ]

          def deploySteps = servers.collectEntries { server ->
            ["Deploy to ${server}" : {
              sshagent (credentials: [SSH_CREDENTIAL_ID]) {
                sh """
                  scp -o StrictHostKeyChecking=no -r * ${server}:/home/ubuntu/html-site-${BUILD_NUMBER}
                  ssh -o StrictHostKeyChecking=no ${server} '
                    cd /home/ubuntu/html-site-${BUILD_NUMBER} &&
                    docker build -t ${DOCKER_REGISTRY}:${BUILD_NUMBER} . &&
                    echo "$REG_PASS" | docker login -u "$REG_USER" --password-stdin &&
                    docker stop html-site || true &&
                    docker rm html-site || true &&
                    docker run -d --name html-site -p 8082:80 ${DOCKER_REGISTRY}:${BUILD_NUMBER}
                  '
                """
              }
            }]
          }

          parallel deploySteps
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}
