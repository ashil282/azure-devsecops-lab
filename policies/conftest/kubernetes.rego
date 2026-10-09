package main

import rego.v1

workloads := {"Deployment", "StatefulSet", "DaemonSet"}

containers contains c if {
    workloads[input.kind]
    some c in input.spec.template.spec.containers
}

deny contains msg if {
    some c in containers
    endswith(c.image, ":latest")
    msg := sprintf("%s: container '%s' uses the :latest tag", [input.kind, c.name])
}

deny contains msg if {
    some c in containers
    not c.securityContext.readOnlyRootFilesystem
    msg := sprintf("%s: container '%s' must set readOnlyRootFilesystem: true", [input.kind, c.name])
}

deny contains msg if {
    some c in containers
    not c.resources.limits.memory
    msg := sprintf("%s: container '%s' has no memory limit", [input.kind, c.name])
}

deny contains msg if {
    some c in containers
    not "ALL" in c.securityContext.capabilities.drop
    msg := sprintf("%s: container '%s' must drop ALL capabilities", [input.kind, c.name])
}

deny contains msg if {
    workloads[input.kind]
    input.spec.template.spec.automountServiceAccountToken != false
    msg := sprintf("%s: set automountServiceAccountToken: false", [input.kind])
}
