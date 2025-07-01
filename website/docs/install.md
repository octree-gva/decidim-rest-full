---
sidebar_position: 2
slug: /install
title: Installation
description: How to install the module
---

### Support Table
| Decidim Version | Supported?  |
|-----------------|-------------|
| 0.24            | no          |
| 0.26            | no         |
| 0.27            | no         |
| 0.28            | yes |
| 0.29            | yes |

# Install the rest-full integration

**Add the gem to your Gemfile**<br />
```ruby
gem "decidim-rest_full", "~> 0.0.1"
```

**Install the module**<br />
```ruby
bundle install
```

**Copy migrations files**<br />
```ruby
bundle exec rails decidim_rest_full:install:migrations
```

**Migrate**<br />
```ruby
bundle exec rails db:migrate
```
(you can make sure migrations pass with bundle exec rails db:migrate:status)

## Environment variables

| Name | Description | Default Value |
|------|-------------|---------------|
| `DECIDIM_REST_QUEUE_NAME`| Name of the queue used by the module | `default` |
| `DECIDIM_REST_LOADBALANCER_IPS`| CSV of ips to a loadbalancer to safely save `host` attribute. See [Safe Host Update](/dev/update-hosts) | `127.0.0.1, ::1` |
| `DOCS_URL`| Base URL for this doc, to build the documentation website | `https://octree-gva.github.io/decidim-rest-full` |