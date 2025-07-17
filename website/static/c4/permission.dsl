workspace {
  model {
    config = element "Available Permissions" "Configuration" "Central hash defining scopes and their permissions"
    
    scopes = element "API Scopes" "Doorkeeper" "Doorkeeper scopes extracted from permission keys"
    abilities = element "Abilities" "Authorization" "CanCan permissions validated against config"
    routes = element "Routes" "Routing" "Conditional route mounting based on available scopes"
    controller_action = element "Controller Action" "Controller" "Controller Action"
    
    config -> scopes "define available scopes"
    config -> abilities "define available permissions"
    config -> routes "controls mounting"
    scopes -> controller_action "control access"
    abilities -> controller_action "control access"
    routes -> controller_action "mount"
  }

  views {
    !include "./view.dsl.include"

    custom "permission-flow" {
      title "Available Permissions"
      include *
      autoLayout lr
    }
  }
}