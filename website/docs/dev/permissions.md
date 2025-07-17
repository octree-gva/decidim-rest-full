---
sidebar_position: 2
title: Permissions and scope
---

This Api use a classic hierarchy for permissions. 
We structure permission with `scopes` and then `permission`: 

- Scopes: `public`, `proposals`, `oauth`, ...
  - Permissions: `public.component.read`, ...

The permissions table is defined in a configuration, and will be used when we check the ability. 
```ruby
# lib/decidim/rest_full/configuration.rb
config_accessor :available_permissions do
  {
    "system" => [
      "system.organizations.read",
      "system.organizations.update",
      "system.organizations.destroy",
      "system.organizations.extended_data.read",
      "system.organizations.extended_data.update"
    ],
    "public" => [
      "public.component.read",
      "public.space.read"
    ],
    # ...
  }
end
``` 

This permission configuration is central to the authorization module, and will be used for : 
- Control which endpoints is mounted
- Control which permission can be set on client
- Control which webhooks can be sent

![permissions](/c4/images/structurizr-permission-flow.png)