variable "TAG" {
  default = "7.0.11-alpine3.18"
}

group "default" {
  targets = ["dev"]
}

target "dev" {
  dockerfile = "Dockerfile"
  tags = ["atecey01/redis-cluster:${TAG}"]
}

target "release" {
  inherits = ["dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}