// @ts-check
const { devices } = require('@playwright/test');

const config = {
  testDir: './test',
  /* Maximum time one test can run for. */
  timeout: 30 * 1000,
  expect: {
    /**
     * Maximum time expect() should wait for the condition to be met.
     * For example in `await expect(locator).toHaveText();`
     */
    timeout: 5000
  },
   use: {
    baseURL: 'http://localhost:3000',
    viewport: {width: 1280, height: 720},
    ignoreHTTPSErrors: true,
    headless: true,
    video: 'on-first-retry',
    extraHTTPHeaders: {
      AccessControlAllowOrigin: '*',
    },
    launchOptions: {
      args: ['--allow-insecure-localhost', '--disable-web-security'
      ]
    }
   },
  
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
      },
    },

  ]
};

module.exports = config;
