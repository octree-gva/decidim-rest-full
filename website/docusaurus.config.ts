import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Decidim Rest API',
  tagline: 'Rest API for decidim',
  favicon: '/img/favicon.ico',

  // Set the production url of your site here
  url: 'https://octree-gva.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/decidim-rest-full/',
  trailingSlash: false,

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'octree-gva', // Usually your GitHub org/user name.
  projectName: 'decidim-module-rest-full', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  onBrokenAnchors: 'throw',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
  plugins: [
    'docusaurus-plugin-image-zoom',
    '@stackql/docusaurus-plugin-structured-data',
  ],
  presets: [
    
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
        },

        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
    [
      'redocusaurus',
      {
        specs: [
          {
            spec: './static/openapi.json',
            route: '/api/',
          },
        ],
        theme: {
          // Change with your site colors
          primaryColor: '#1890ff',
        },
      },
    ],
    
  ],
  themes: [
    [
      require.resolve("@easyops-cn/docusaurus-search-local"),
      /** @type {import("@easyops-cn/docusaurus-search-local").PluginOptions} */
      ({
        // ... Your options.
        // `hashed` is recommended as long-term-cache of index file is possible.
        hashed: true,
        indexBlog: false,
        indexDocs: true,
        docsRouteBasePath: "/",
        docsDir: ["docs"],
        // For Docs using Chinese, it is recomended to set:
        language: ["en"],
        highlightSearchTermsOnTargetPage: true

        // Customize the keyboard shortcut to focus search bar (default is "mod+k"):
        // searchBarShortcutKeymap: "s", // Use 'S' key
        // searchBarShortcutKeymap: "ctrl+shift+f", // Use Ctrl+Shift+F

        // If you're using `noIndex: true`, set `forceIgnoreNoIndex` to enable local index:
        // forceIgnoreNoIndex: true,
      }),
    ],
  ],

  themeConfig: {
    structuredData: {
      excludedRoutes: [], // array of routes to exclude from structured data generation, include custom redirects here
      verbose: true, // print verbose output to console (default: false)
      featuredImageDimensions: {
        width: 1200,
        height: 630,
      },
      authors:{
        octree: {
          authorId: "octree-gva", // unique id for the author - used as an identifier in structured data
          url: "https://octree.ch", // MUST be the same as the `url` property in the `authors.yml` file in the `blog` directory
          imageUrl: "images.squarespace-cdn.com/content/v1/62ce731e0f9b5c4a543dcd33/0b37aa26-944f-424b-ace3-1fb5ae7a1de7/octree_logo_header.png?format=1500w", // gravatar url
          sameAs: [] // synonymous entity links, e.g. github, linkedin, twitter, etc.
        },
      },
      organization: {
        name: "Octree",
        url: "https://octree.ch",
        logo: "images.squarespace-cdn.com/content/v1/62ce731e0f9b5c4a543dcd33/0b37aa26-944f-424b-ace3-1fb5ae7a1de7/octree_logo_header.png?format=1500w",
        sameAs: ["https://octree.ch"],
        email: "hello@octree.ch",
      }, 
      
      website: {
        name: "Decidim Rest API",
        url: "https://octree-gva.github.io/decidim-rest-full/",
        logo: "images.squarespace-cdn.com/content/v1/62ce731e0f9b5c4a543dcd33/0b37aa26-944f-424b-ace3-1fb5ae7a1de7/octree_logo_header.png?format=1500w",
        email: "hello@octree.ch",
      }, 
      webpage: {
        datePublished: "2025-09-08", // default is the current date
        inLanguage: "en-US", // default: en-US
      },
      breadcrumbLabelMap: {} // used to map the breadcrumb labels to a custom value
      // Replace with your project's social card
      },
      image: 'img/docusaurus-social-card.jpg',
  
    zoom: {
      selector: '.markdown img',
      background: {
        light: 'rgb(255, 255, 255)',
        dark: 'rgb(50, 50, 50)'
      },
      config: {
        // options you can specify via https://github.com/francoischalifour/medium-zoom#usage
      }
    },
    navbar: {
      title: 'Decidim Rest API',
      logo: {
        alt: 'Module Logo',
        src: 'img/logo.svg',
      },
      
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'documentationSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          to: '/api',
          position: 'left',
          label: 'API',
        },
        {
          href: 'https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full',
          label: 'GitLab',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Documentation',
              to: '/',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Stack Overflow',
              href: 'https://stackoverflow.com/questions/tagged/docusaurus',
            },
            {
              label: 'Discord',
              href: 'https://discordapp.com/invite/docusaurus',
            },
            {
              label: 'Twitter',
              href: 'https://twitter.com/docusaurus',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitLab',
              href: 'https://git.octree.ch/octree-gva/decidim-rest_full',
            },
          ],
        },
      ],
      copyright: `Powered with love @octree. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      // Default Prism bundle omits Ruby; add-endpoint docs use ```ruby fences heavily.
      additionalLanguages: ['ruby', 'yaml'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
