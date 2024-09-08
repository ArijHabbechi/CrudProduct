package main

# List of sensitive keywords to avoid in ENV variables
secrets_env = [
    "passwd", "password", "pass", "secret", "key", "access", 
    "api_key", "apikey", "token", "tkn"
]

# Deny if any ENV variable contains sensitive keywords
deny[msg] {    
    input[i].Cmd == "env"
    val := input[i].Value
    contains(lower(val[_]), secrets_env[_])
    msg = sprintf("Line %d: Potential secret in ENV key found: %s", [i, val])
}

# Deny use of 'latest' tag in base images
deny[msg] {
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    contains(lower(val[1]), "latest")
    msg = sprintf("Line %d: do not use 'latest' tag for base images", [i])
}

# Deny curl/wget with piping (curl bashing)
deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    matches := regex.find_n("(curl|wget)[^|^>]*[|>]", lower(val), -1)
    count(matches) > 0
    msg = sprintf("Line %d: Avoid curl bashing", [i])
}

# Deny system package upgrades (e.g., apt-get upgrade)
upgrade_commands = ["apk upgrade", "apt-get upgrade", "dist-upgrade"]

deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, upgrade_commands[_])
    msg = sprintf("Line: %d: Do not upgrade system packages", [i])
}

# Enforce using 'COPY' instead of 'ADD'
deny[msg] {
    input[i].Cmd == "add"
    msg = sprintf("Line %d: Use COPY instead of ADD", [i])
}

# Deny if no USER command is specified (prevent root usage)
any_user {
    input[i].Cmd == "user"
}

deny[msg] {
    not any_user
    msg = "Do not run as root, use USER instead"
}

# Deny forbidden users (root, toor, UID 0)
forbidden_users = ["root", "toor", "0"]

deny[msg] {
    input[i].Cmd == "user"
    val := input[i].Value
    contains(lower(val[_]), forbidden_users[_])
    msg = sprintf("Line %d: Do not run as root: %s", [i, val])
}

# Deny use of 'sudo' command
deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(lower(val), "sudo")
    msg = sprintf("Line %d: Do not use 'sudo' command", [i])
}

