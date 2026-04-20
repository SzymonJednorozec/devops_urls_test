pipeline {
    agent any

    environment {
        // Ścieżka relatywna do Twojego folderu w workspace
        // Jeśli mdo-projekt zawiera folder url_shortener_files, zostawiamy jak poniżej:
        FILES_DIR = "."
        
        // Nazwy obrazów
        BUILD_IMAGE = "url-shortener-builder"
        DEPLOY_IMAGE = "url-shortener-deploy"
    }

    stages {
        stage('Initialize Workspace') {
            steps {
                // Ta sekcja obsłuży Twoje lokalne kopiowanie przez 'docker cp'
                // Sprawdzamy czy pliki dotarły do kontenera
                sh "ls -la"
                sh "ls -la ${FILES_DIR}"
                
                // Nadanie uprawnień do skryptu smoke testu
                sh "chmod +x ${FILES_DIR}/smoke_test.sh"
            }
        }

        stage('Build Builder Image') {
            steps {
                dir("${FILES_DIR}") {
                    sh "docker build -t ${BUILD_IMAGE} -f Dockerfile.build ."
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                dir("${FILES_DIR}") {
                    // Uruchamiamy testy i czekamy na exit code
                    sh "docker-compose -f docker-compose.test.yml up --exit-code-from app-test"
                }
            }
            post {
                always {
                    dir("${FILES_DIR}") {
                        sh "docker-compose -f docker-compose.test.yml down -v"
                    }
                }
            }
        }

        stage('Build Runtime Image') {
            steps {
                dir("${FILES_DIR}") {
                    // Budowa lekkiego obrazu produkcyjnego
                    sh "docker build -t ${DEPLOY_IMAGE} -f Dockerfile.runtime ."
                }
            }
        }

        stage('Deploy & Smoke Test') {
            steps {
                dir("${FILES_DIR}") {
                    sh "docker-compose -f docker-compose.deploy.yml up -d"
                    
                    echo "Waiting for app to be ready..."
                    sh "sleep 15"
                    
                    // Odpalenie Twojego skryptu bashowego z listą URL
                    sh "./smoke_test.sh list.url"
                }
            }
            post {
                always {
                    dir("${FILES_DIR}") {
                        sh "docker-compose -f docker-compose.deploy.yml down -v"
                    }
                }
            }
        }

        stage('Publish Artifact') {
            steps {
                dir("${FILES_DIR}") {
                    script {
                        // Tworzenie paczki .tgz (standard NPM)
                        sh """
                            docker run --rm -v \$(pwd):/out ${BUILD_IMAGE} cp -r /app/package.json /app/dist /out/
                            docker run --rm -v \$(pwd):/out -w /out node:20-alpine npm pack
                        """
                        // Archiwizacja pliku w Jenkinsie
                        archiveArtifacts artifacts: '*.tgz', fingerprint: true
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline zakończony sukcesem! Artefakt .tgz jest gotowy."
        }
        failure {
            echo "Błąd w Pipeline. Sprawdź logi Smoke Testu."
        }
    }
}