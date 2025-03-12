pipeline {
    agent any 

    parameters {
        string(name: 'COMPANY_NAME', description: 'Enter the company name')
        string(name: 'EMAIL_ADDRESS', description: 'Enter the email address')
        choice(name: "COUNTRY", choices: ['cm', 'ng', 'us'], description: 'Select the country')
    }

    environment {
        GIT_REPO_URL = 'https://github.com/mihmahq/midoo-pipeline-scripts.git'
        GIT_CREDENTIALS_ID = 'github-access-token'
        STAGE = 0
        DB_NAME = ''
        DB_USER = credentials('db-user')
        DB_PASSWORD = credentials('db-password')
        DB_HOST = credentials('db-host')
        DB_PORT = credentials('db-port')
        HCLOUD_TOKEN = credentials('hcloud-token')
        HCLOUD_IMAGE_ID = 67794396  // ubuntu 22.04
        HCLOUD_DATACENTER = 'fsn1-dc14'
        MIDOO_PRIVATE_NETWORK = 'midoo-net'
        JENKINS_SSH_KEY_NAME = 'jenkins'
        ADMIN_SSH_KEY_NAME = 'kinason'
        HCLOUD_SERVER_TYPE = 'cx22'
    }

    stages{
        stage ("Git Init") {
            steps {
                script {
                    echo "Cloning repository from ${env.GIT_REPO_URL}"
                    git branch: 'main', credentialsId: env.GIT_CREDENTIALS_ID, url: env.GIT_REPO_URL
                    env.STAGE = 1
                }
            }
        }

        stage('Create Server') {
            steps {
                script {
                    echo "Creating server for ${params.COMPANY_NAME} in ${params.COUNTRY}"
                    echo "Using server image: ${params.SERVER_IMAGE}"
                    env.STAGE = 2
                    def dbName = getDatabaseName()
                    env.DB_NAME = dbName
                    def serverName = getServerName()

                    sh "source /etc/profile"

                    def createServerOutput = sh(script: """
                        hcloud server create \
                            --image ${env.HCLOUD_IMAGE_ID} \
                            --name ${serverName} \
                            --type ${env.HCLOUD_SERVER_TYPE} \
                            --datacenter ${env.HCLOUD_DATACENTER} \
                            --network ${env.MIDOO_PRIVATE_NETWORK} \
                            --ssh-key ${env.ADMIN_SSH_KEY_NAME} \
                            --ssh-key ${env.JENKINS_SSH_KEY_NAME} \
                            --output json
                    """, returnStdout: true).trim()

                    def jsonResponse = readJSON text: createServerOutput
                    def serverStatus = jsonResponse.server.status
                    echo "Server Status: ${serverStatus}"
                    echo "DB Name: ${env.DB_NAME}"
                    echo "Server Name: ${serverName}"

                    if (serverStatus == 'running') {
                        echo "Server is running! Proceeding to midoo installation..."
                    } else {
                        error "Server is not running. Status: ${serverStatus}"
                    }
                }
            }
        }

        stage ("Install Midoo") {
            steps {
                script {
                    echo "Installing Midoo on the server"
                    env.STAGE = 3

                }
            }
        }

        stage("Create Login Credentials") {
            steps {
                script {
                     echo "Creating login credentials using ${params.EMAIL_ADDRESS}"
                     env.STAGE = 4

                }
            }
        }

        stage("Send Login Credentials") {
            steps {
                script {
                    echo "Sending login credentials to ${params.EMAIL_ADDRESS}"
                    env.STAGE = 5
                }
            }
        }

        stage("Call Backend API") {
            steps {
                script {
                     echo "Calling backend API to register ${params.COMPANY_NAME}"
                     env.STAGE = 6

                }
            }
        }
    }


    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Please check the logs for details."

            if (env.STAGE > 1) {
                echo "Rolling back, destroying the server and deleting database"
                destroyServer()
                deleteDatabase()
            }
        }
    }
}

def getDatabaseName() {
    def companyName = "${params.COMPANY_NAME}".replaceAll(/[^a-zA-Z0-9]/, '').toLowerCase();

    if (companyName.length() > 8) {
        companyName = companyName.take(8);
    }
    def uuidPart = UUID.randomUUID().toString().split('-')[-1]
    return "${companyName}_${uuidPart}"
}

def getServerName() {
    def dbName = env.DB_NAME;
    def uuidPart = dbName.split('_')[1];
    def firstHalf = uuidPart[0..3];
    def secondHalf = uuidPart[4..7];
    def reversedUUIDPart = secondHalf+firstHalf;

    return "${dbName.split('_')[0]}_${reversedUUIDPart}"
}
def destroyServer() {}
def deleteDatabase() {}