---
sidebar_position: 2
title: Features
---
This module exposes configurations to enable or disable features.
By default, all features are enabled. You can configure them through an initializer (like `/config/initializers/api.rb`)

## Authentication
User of the api can use two ways of authenticate themselves: 

- `client_credentials`: Act as a service
- `passwords`: Act as a user
  - `login`: with a email/password
  - `impersonate`: with a `username` or a user `id`. 

### Configuration
```ruby
# config/initializers/api.rb
Decidim::RestFull.configure do |config|
  # Api Clients can not acts as other participant without knowing their creds.
  config.available_permissions["oauth"].delete("oauth.impersonate")
  # Api Clients can not login with participants creds
  config.available_permissions["oauth"].delete("oauth.login")
end
```

## Spaces and components
In Decidim, we have many participatory spaces by default, like assemblies, participatory processes, conferences or initiatives. 

Each spaces are composed of components, that each components have seperated features.
With this module, you can: 
- Search participatory spaces
- Get a detail of a participatory space
- Search components, filter them by spaces
- Get a detail of component

### Configuration
Spaces and components requires the `public` scope. To remove the scope, and thus forbidding completly the 
use of these, do:
```ruby
Decidim::RestFull.configure do |config|
  config.available_permissions.delete("public")
end
```

## Proposals
Proposals are a component type, they are attached to spaces and components.
You can: 

- Read published proposals
- only with a `password` grant
   - See your draft
   - Edit your draft
   - Publish a draft
   - Vote on a proposal (supports Decidim::Awesome voting weight)

To remove 



### Related resources
- [Authentication documentation](/category/authentication)