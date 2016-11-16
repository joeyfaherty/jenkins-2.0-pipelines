//!groovy

def ARCHIVA_HOST = 'archiva.org'
def DOCKER_REGISTRY = "hub.docker.com"
// env.X lets us access our ENV variables
def DOCKER_IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}".replaceAll("/", "-")
def MVN_HOME = "/path/to/the/maven/installation"

// get the project version so we can re-use this to point to a specific artifact version in the rest of the script
def getProjectVersion() {
  // Pipeline Utility Steps plugin must be installed for 'readMavenPom' to work
  pom = readMavenPom file: "pom.xml"
  return pom.version
}

// A node is a step that schedules a task to run by adding it to the Jenkins build queue
// As soon as an executor slot is available on a node (the Jenkins master, or agent), the task is run on that node
// A node also allocates a workspace (file directory) on that node for the duration of the task
node ('linux') {
    // stage is the logical separation of pipeline into segments of work
    stage('Checkout') {
      timeout(time: 30, unit: 'MINUTES') {
        checkout scm
      }
    }

  stage ('Scm checkout and Maven Build') {
    // give a timeout of to the phase to ensure proper cleanup (aborted) within the given window
    timeout(time: 30, unit: 'MINUTES') {
      checkout scm
      sh("$MVN_HOME/bin/mvn -B clean install")
      // prefer stashing files over archiving
      // Stash and unstash are designed for sharing files, for example your application’s source code, between stages and nodes.
      // Archives, on the other hand, are designed for longer term file storage (e.g., intermediate binaries from your builds).
      projectVersion = getProjectVersion()
      stash includes: 'some-web-app/target/some-web-app-' + projectVersion + '.war', name: 'some-web-app'
      stash includes: 'database-scripts/target/database-scripts-' + projectVersion + '.tar.gz', name: 'database-scripts'
    }
  }

}

node ('linux') {
  stage ('Push Docker Image To Docker Hub') {
    timeout(time: 30, unit: 'MINUTES') {
      echo('fetching artifact from the previous job')
      unstash 'some-web-app'
      echo('building and publishing the container images')
      // This is using the CloudBees Docker Pipeline Plugin
      // similar to running $ export DOCKER_HOST=tcp://0.0.0.1:2375
      docker.withServer('tcp://0.0.0.1:2375') {
        docker.build("${DOCKER_REGISTRY}/some-web-app:${DOCKER_IMAGE_TAG}").push()
      }
    }
  }

  stage ('Deploy Regression') {
    timeout(time: 30, unit: 'MINUTES') {
      sh("docker compose up regression")
    }
  }

  stage ('Regression Test') {
    timeout(time: 30, unit: 'MINUTES') {
      sh("$MVN_HOME/bin/mvn clean integration-test")
    }
  }

}

node ('linux') {
    stage ('Publish Artifacts to archiva') {
      timeout(time: 30, unit: 'MINUTES') {
        if ("${env.BRANCH_NAME}" == "master") {
          echo('fetching artifacts from the previous job')
          unstash 'database-scripts'
          echo('publishing artifacts to archiva')
          projectVersion = getProjectVersion()
          withCredentials([usernamePassword(credentialsId: 'ArtifactoryLogin', usernameVariable: 'username', passwordVariable: 'password')]) {
            sh("$MVN_HOME/bin/mvn deploy:deploy-file -B
              -DgroupId=com.your.package
              -DartifactId=database-scripts
              -Dversion=${projectVersion}-${env.BUILD_NUMBER}
              -Dfile=database-scripts/target/database-scripts-${projectVersion}.tar.gz
              -DrepositoryId=database-scripts
              -Durl=http://${username}:${password}@${ARCHIVA_HOST}/path/to/your/project")
          }
        } else {
          echo('no need to publish artifacts to archiva since we are not at the master branch')
        }
      }
    }

}
