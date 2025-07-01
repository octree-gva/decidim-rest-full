---
sidebar_position: 1
title: Safe `host` update
---

Decidim is a multi-tenant system, and you can natively define the `host` of a tenant.
`decidim-rest_full` will add some extra validation on the update of the host, to be sure the host is correctly binded before
making the change. This will enable to expose safe endpoint to update the organizaiton through API without falling in a bad state.

## General Infrastructure
![Infrastructure](/c4/images/structurizr-api-infra.png)  
The expected infrastructure used with this module include the following component: 

- A DNS service, like the ones provided by Gandi.net, infomaniak.com namecheap.org etc
- A LoadBalancer (nginx, traefik, haproxy) that will redirect the host to the right decidim server adress
- A decidim instance
- An `active-job` runner, like sidekiq, good_queue or solid_queue

## `host` validation
When updating the host from the `/system` form, we will save the `unconfirmed_host`, and check periodically the DNS resolution of this unconfirmed host.  
Once the unconfirmed host IP resolution match all your Loadbalancer ips (meaning: DNS are propagated and ready to user), then we do indeed the host updates. 

These changes are represented through `callout` in the system administration: 
1. If there is no operation pending, display information
2. If there is an operation pending, display again the information, but with a warning
![System administration panel to update host](/img/system-admin-unconfirmed_host.png)  
The general process is quiet simple, and needed little updates to the decidim code: 
![Update host process](/c4/images/structurizr-update-host.png)

To make this work, we needed two thing: 

- Be able to save additional data to an organization. 
- Be able to know what are the IP of the loadbalancer. 


## Save additional data to an organization: `extended_data`
We copy the logic from `Decidim::User` and applied it to `Decidim::Organization`, in order to save 
extra metadata (we need only `unconfirmed_host` here). This additional resource is created in a jointed table, and is exposed in the Rest API under the `system` scope. 

The Extended Data `unconfirmed_host` behaves like this: 
1. If `nil`: we have nothing to update
2. Else: we need to check if the DNS lookup of the unconfirmed host match the IPs of the loadbalancer.

**related endpoints**  
- [Update extended data](/api#tag/Organizations-Extended-Data/operation/organizationData)
- [Fetch extended data](/api#tag/Organizations-Extended-Data/operation/setOrganizationExtendedData)

## Register IPs for the loadbalancer
A configuration for the `Decidim::Restfull` module is available under `Decidim::Restfull.config.loadbalancer_ips`. 
This configuration variable is defined by default by an environnement variable `DECIDIM_REST_LOADBALANCER_IPS`.
So you can configure loadbalancer ips using two technique: 

1. **DECIDIM_REST_LOADBALANCER_IPS** (recommended)  
CSV of IPv4 or IPV6 separated by comma. Example: `127.0.0.1, ::1`.


2.  **Initializer file**  
```ruby
Decidim::Restfull.configure do |config|
  config.loadbalancer_ips = ["127.0.0.1", "::1"]
end
```

## Related Resources
- [hold configuration: configuration.rb](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/blob/main/lib/decidim/rest_full/configuration.rb)
- [command to syncronize host - syncronize_unconfirmed_host.rb](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/blob/main/app/commands/decidim/rest_full/syncronize_unconfirmed_host.rb)
- [monkey path of UpdateOrganization Form - update_organization_form_override.rb](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/blob/main/lib/decidim/rest_full/overrides/update_organization_form_override.rb)
- [`Resolv` documentation for Reverse DNS](https://github.com/ruby/resolv)
- [`IPAddr` documentation for IP parsing](https://github.com/ruby/ipaddr)