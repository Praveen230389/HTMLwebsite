pipeline {
  agent any

  environment {
    SONAR_HOST_URL       = 'http://localhost:9000'
    SONAR_AUTH_TOKEN     = credentials('sonar-token')
    DOCKER_REGISTRY      = 'mydockerhubuser/html-site'
    REGISTRY_CREDENTIALS = 'dockerhub-credentials'
    SSH_CREDENTIAL_ID    = 'jenkins-ssh-key'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('SonarQube Analysis') {
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          withSonarQubeEnv('My SonarQube') {
            sh '''
              sonar-scanner \
                -Dsonar.projectKey=html-site \
                -Dsonar.host.url=$SONAR_HOST_URL \
                -Dsonar.login=$SONAR_AUTH_TOKEN
            '''
          }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          IMAGE_TAG = "${DOCKER_REGISTRY}:${env.BUILD_NUMBER}"
        }
        sh "docker build -t ${IMAGE_TAG} ."
      }
    }

    stage('Push to Registry') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIALS}", usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh """
            echo "$REG_PASS" | docker login -u "$REG_USER" --password-stdin
            docker push ${IMAGE_TAG}
          """
        }
      }
    }

    stage('Deploy to EC2 Instances') {
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
                  ssh -o StrictHostKeyChecking=no ${server} '
                    docker pull ${IMAGE_TAG} &&
                    docker stop html-site || true &&
                    docker rm html-site || true &&
                    docker run -d --name html-site -p 80:80 ${IMAGE_TAG}'
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
