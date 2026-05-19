---
sidebar_position: 1
id: my-home-doc
slug: /
title: Overview
description: What decidim-restfull is, in Decidim terms—plus where to read next.
---

# Restfull API
**decidim-restfull** is a Rails engine that adds a **versioned HTTP API** on top of a normal Decidim instance. It exposes organizations, participatory spaces, components, and several resources (for example proposals and blogs) as JSON, with **OAuth2** access from trusted clients.

If you already know Decidim: this module does **not** replace the web UI. It lets **other systems** (mobile apps, automation, data pipelines, internal tools) work with the same tenant-bound data and permissions model you have in core.

## Documentation
| For | Documents |
|----------|------------|
| Decidim Administrator | This page, then [Installation](/install). |
| System admin | [API clients](/user_documentation/client-api-admin), then [Authentication](#authentication) below. |
| Integrator | [Integrator guide](/integrator/quickstart) first, then [OpenAPI reference](/api), [Machine-to-machine](/user_documentation/auth/client-credential-flow) and [User tokens](/user_documentation/auth/user-credential-flow) as needed. |
| Contributors and maintainers | [Developer documentation](/dev/architecture) (sidebar), and the repository [CONTRIBUTING](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/CONTRIBUTING.md) guide. |

## Overview

- **System administration**: register **API clients** (OAuth applications) per organization, with **scopes** fixed at creation time and **fine-grained permissions** editable afterward—same multi-tenant boundaries as Decidim.
- **OAuth2**: **client credentials** for service-to-service calls; **resource owner–style** flows where policy allows (see auth pages for exact parameters and constraints).
- **JSON resources**: CRUD and queries for the areas covered by this release (see the **OpenAPI** spec for the live list of paths and operations).
- **Optional mechanics** that integrators must respect: some writes return **202** with async **jobs** ([async writes](/dev/add-endpoint/async)); some reads support **conditional GET** ([HTTP cache](/dev/add-endpoint/http-cache)). Reflected in the OpenAPI description text.
- **Webhooks**: HTTP callbacks for selected domain events, with signed payloads.

## Authentication

Diagrams for the two main flows live on the dedicated pages (keep screenshots and sequence diagrams there so this overview stays short):

- [Machine-to-machine (client credentials)](/user_documentation/auth/client-credential-flow)
- [User-oriented tokens (resource owner flow)](/user_documentation/auth/user-credential-flow)

## Contract and source of truth

- **HTTP contract**: the published [OpenAPI](/api) document generated from request specs.
- **Implementation and contributor workflow**: the [GitLab repository](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full).
