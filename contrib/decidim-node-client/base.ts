/* tslint:disable */
/* eslint-disable */
/**
 * API V1
 * A RestFull API for Decidim, to be able to CRUD resources from Decidim.   _current version: 0.2.4_  ## Authentication [Get a token](https://octree-gva.github.io/decidim-rest-full/category/authentication) from our `/oauth/token` routes, following OAuth specs on Credential Flows or Resource Owner Password Credentials Flow.  ### Permissions A permission system is attached to the created OAuth application, that is designed in two levels:  - **scope**: a broad permission to access a collection of endpoints - **abilities**: a fine grained permission system that allow actions.  The scopes and abilities are manageable in your System Admin Panel.  ### Multi-tenant Decidim is multi-tenant, and this API supports it. - The **`system` scope** endpoints are available in any tenant - The tenant `host` attribute will be used to guess which tenant you are requesting.   For example, given a tenant `example.org` and `foobar.org`, the endpoint   * `example.org/oauth/token` will ask a token for the example.org organization   * `foobar.org/oauth/token` for foobar.org.
 *
 * The version of the OpenAPI document: v0.2
 *
 *
 * NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
 * https://openapi-generator.tech
 * Do not edit the class manually.
 */

import type { Configuration } from "./configuration";
// Some imports not used depending on template conditions
// @ts-ignore
import type { AxiosPromise, AxiosInstance, RawAxiosRequestConfig } from "axios";
import globalAxios from "axios";

export const BASE_PATH = "https://www.example.com/api/rest_full/v0.2".replace(
  /\/+$/,
  "",
);

/**
 *
 * @export
 */
export const COLLECTION_FORMATS = {
  csv: ",",
  ssv: " ",
  tsv: "\t",
  pipes: "|",
};

/**
 *
 * @export
 * @interface RequestArgs
 */
export interface RequestArgs {
  url: string;
  options: RawAxiosRequestConfig;
}

/**
 *
 * @export
 * @class BaseAPI
 */
export class BaseAPI {
  protected configuration: Configuration | undefined;

  constructor(
    configuration?: Configuration,
    protected basePath: string = BASE_PATH,
    protected axios: AxiosInstance = globalAxios,
  ) {
    if (configuration) {
      this.configuration = configuration;
      this.basePath = configuration.basePath ?? basePath;
    }
  }
}

/**
 *
 * @export
 * @class RequiredError
 * @extends {Error}
 */
export class RequiredError extends Error {
  constructor(
    public field: string,
    msg?: string,
  ) {
    super(msg);
    this.name = "RequiredError";
  }
}

interface ServerMap {
  [key: string]: {
    url: string;
    description: string;
  }[];
}

/**
 *
 * @export
 */
export const operationServerMap: ServerMap = {};
