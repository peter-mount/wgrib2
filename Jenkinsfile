// Repository name use, must end with / or be '' for none
repository= 'area51/'

// image prefix
imagePrefix = 'wgrib2'

// The versions to build, latest is the first.
// Note 2.0.5 is not here as it doesn't compile
versions = [ '2.0.7', '2.0.6c', '2.0.4', '2.0.3']

// The architectures to build, in format recognised by docker
architectures = [ 'amd64' ]
// For now arm64 not supported until issues are resolved, 'arm64v8'

// The slave label based on architecture
def slaveId = {
  architecture -> switch( architecture ) {
    case 'amd64':
      return 'AMD64'
    case 'arm64v8':
      return 'ARM64'
    default:
      return 'amd64'
  }
}

// The docker image name
// architecture can be '' for multiarch images
def dockerImage = {
  architecture, version -> repository + imagePrefix + ':' +
    ( architecture=='' ? '' : ( architecture + '-' ) ) +
    version
}

// The go arch
def goarch = {
  architecture -> switch( architecture ) {
    case 'amd64':
      return 'amd64'
    case 'arm32v6':
    case 'arm32v7':
      return 'arm'
    case 'arm64v8':
      return 'arm64'
    default:
      return architecture
  }
}

properties( [
  buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '7', numToKeepStr: '10')),
  disableConcurrentBuilds(),
  disableResume(),
  pipelineTriggers([
    upstream('/peter-mount/alpine-dev/master'),
  ])
])

def buildArch = {
  architecture, version -> node( slaveId( architecture ) ) {
    stage( architecture ) {
      checkout scm
      sh 'docker pull alpine'
      sh 'docker pull area51/alpine-dev'
      sh 'docker build' +
            ' -t ' + dockerImage( architecture, version ) +
            ' --build-arg version=' + version +
            ' .'
      sh 'docker push ' + dockerImage( architecture, version )
    }
  }
}

def multiArch = {
  tag, version -> stage( "MultiArch " + tag ) {
    // The manifest to publish
    multiImage = dockerImage( '', tag )

    // Create/amend the manifest with our architectures
    manifests = architectures.collect { architecture -> dockerImage( architecture, version ) }
    sh 'docker manifest create -a ' + multiImage + ' ' + manifests.join(' ')

    // For each architecture annotate them to be correct
    architectures.each {
      architecture -> sh 'docker manifest annotate' +
        ' --os linux' +
        ' --arch ' + goarch( architecture ) +
        ' ' + multiImage +
        ' ' + dockerImage( architecture, version )
    }

    // Publish the manifest
    sh 'docker manifest push -p ' + multiImage
  }
}

versions.each {
  version -> stage( version ) {
    parallel(
      'amd64': {
        buildArch( 'amd64', version )
      },
      'arm64v8': {
        buildArch( 'arm64v8', version )
      }
    )
  }
}

node( "AMD64" ) {
  versions.each {
    version -> multiArch( version, version )
  }
  multiArch( 'latest', versions[ 0 ] )
}
