# Decidim Rest Api
This repository contains a Rails Engine describe a RestAPI for Decidim.
This works is still a work on progress (started end-2024).

## Documentation
The documentation and the API specification are in the [documentation website](https://octree-gva.github.io/decidim-rest-full/)

### Resources supported

- [ ] Organizations
- [ ] Taxonomies
- [ ] User authentification
- [ ] User Impersonation
- [ ] User Groups
- [ ] Proposals
- [ ] Vote on proposals
- [ ] Meetings
- [ ] Newsletters
- [ ] Articles
- [ ] Official Meetings
- [ ] Menu and navigation
- [ ] Term Customizers



### Scripts

**yarn docs:start**<br />
Start a docusaurus website

**yarn docs:update**<br />
Generates again the openapi spec, add it to docusaurus, and compile again.


## Update Versions
> Release a version is up to the maintainer of this repo. 

The main package.json version attribute is dispatch on versionning the ruby engine, allowing to bump the multi-repo with unique version. 

To run these scripts, change your current branch to `main` and do:

Release a patch
```
yarn version patch
git add .
git tag $(yarn postversion)
```

Release a minor
```
yarn version minor
git add .
git tag $(yarn postversion)
```

## Publish clients
The gem `rswag` generate a valid openapi spec, that then is used to 
generate node clients. We can publish these clients: 

**node-client**<br />
- `yarn gen:node-client`: sync the open-api spec with existing rswag test, and call openapi-generators
- `cd contrib/decidim-node-client && yarn publish`