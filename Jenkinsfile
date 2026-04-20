pipeline {
    agent any

    environment {
        // Obrazy Docker
        BUILD_IMAGE = "url-shortener-builder"
        DEPLOY_IMAGE = "url-shortener-deploy"
        // Zmienna FILES_DIR teraz wskazuje na bieżący folder
        FILES_DIR = "."
    }

    stages {
        stage('Checkout') {
            steps {
                // Pobieramy kod z Twojego nowego repozytorium
                git url: 'https://github.com/SzymonJednorozec/devops_urls_test.git'
            }
        }

        stage('Build Builder') {
            steps {
                // Budujemy obraz bazowy (Dockerfile.build powinien być w głównym folderze)
                sh "docker build -t ${BUILD_IMAGE} -f Dockerfile.build ."
            }
        }

        stage('Run Unit Tests') {
            steps {
                // Uruchamiamy testy z docker-compose
                sh "docker-compose -f docker-compose.test.yml up --exit-code-from app-test"
            }
            post {
                always {
                    sh "docker-compose -f docker-compose.test.yml down -v"
                }
            }
        }

        stage('Build Runtime Image') {
            steps {
                // Budujemy lekki obraz produkcyjny
                sh "docker build -t ${DEPLOY_IMAGE} -f Dockerfile.runtime ."
            }
        }

        stage('Deploy & Smoke Test') {
            steps {
                // 1. Odpalenie aplikacji i bazy
                sh "docker-compose -f docker-compose.deploy.yml up -d"
                
                // 2. Czekamy na start
                echo "Oczekiwanie na uruchomienie aplikacji..."
                sh "sleep 15"
                
                // 3. Odpalenie Twojego skryptu (smoke_test.sh w głównym folderze)
                sh "chmod +x smoke_test.sh"
                sh "./smoke_test.sh list.url"
            }
            post {
                always {
                    echo "Sprzątanie: niszczenie kontenerów deploy i bazy..."
                    sh "docker-compose -f docker-compose.deploy.yml down -v"
                }
            }
        }

        stage('Publish Artifact') {
            steps {
                // 1. Odpalenie Twojego skryptu publikacji (publish.sh w głównym folderze)
                sh "chmod +x publish.sh"
                sh "./publish.sh ${BUILD_IMAGE}"
                
                // 2. Archiwizacja paczki w Jenkinsie
                archiveArtifacts artifacts: '*.tgz', fingerprint: true
            }
        }
    }

    post {
        success {
            echo "Pipeline zakończony sukcesem! Artefakt .tgz jest dostępny w Jenkinsie."
        }
        failure {
            echo "Pipeline nie powiódł się. Sprawdź logi poszczególnych etapów."
        }
    }
}