#!/usr/bin/groovy

pipeline {
  agent any
  triggers {
      cron('H H * * *')
  }
  stages {
    stage ('promotionCheck') {
        def userInput = input(
          id: 'userInput',
          message: 'Push this release to production?',
          parameters: [
            [
              $class: 'TextParameterDefinition',
              defaultValue: 'Good to go',
              description: 'Comments and notes?',
              name: 'comments'
            ]
          ]
        )
        print 'promotionCheck'
        openshiftTag(namespace: '${DEV_PROJECT}', sourceStream: 'jekyll-serve',  sourceTag: 'latest', destinationStream: 'jekyll-serve', destinationTag: 'prod')
    }
  }
}
