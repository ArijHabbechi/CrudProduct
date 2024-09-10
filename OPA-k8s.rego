package main

# Deny if the Service type is not NodePort
deny[msg] {
  input.kind = "Service"
  not input.spec.type = "NodePort"
  msg = sprintf("Service '%s' must have type NodePort", [input.metadata.name])
}

# Deny if the containers in the Deployment are not configured to run as non-root
deny[msg] {
  input.kind = "Deployment"
  some i
  not input.spec.template.spec.containers[i].securityContext.runAsNonRoot = true
  container_name := input.spec.template.spec.containers[i].name
  msg = sprintf("Container '%s' in Deployment '%s' must not run as root. Set runAsNonRoot to true.", [container_name, input.metadata.name])
}


# Deny if the Service does not have a selector defined
deny[msg] {
  input.kind = "Service"
  not input.spec.selector
  msg = sprintf("Service '%s' must have a selector to link it to the appropriate Pods.", [input.metadata.name])
}

# Deny if the Deployment does not have at least one replica
deny[msg] {
  input.kind = "Deployment"
  not input.spec.replicas >= 1
  msg = sprintf("Deployment '%s' must have at least one replica.", [input.metadata.name])
}
