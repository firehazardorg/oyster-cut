const path = require('path')
const fs = require('fs')

const APPLE_SIGN_IDENTITY = process.env.APPLE_SIGN_IDENTITY
const APPLE_API_KEY_PATH = process.env.APPLE_API_KEY_PATH
const APPLE_API_KEY_ID = process.env.APPLE_API_KEY_ID
const APPLE_API_ISSUER = process.env.APPLE_API_ISSUER
const WINDOWS_MANUFACTURER = process.env.WINDOWS_MANUFACTURER || 'Oyster Contributors'

function recreateGitkeepFiles(srcBase, destBase) {
  let entries
  try { entries = fs.readdirSync(srcBase, { withFileTypes: true }) } catch { return }
  for (const entry of entries) {
    const srcPath = path.join(srcBase, entry.name)
    const destPath = path.join(destBase, entry.name)
    if (entry.isDirectory()) {
      recreateGitkeepFiles(srcPath, destPath)
    } else if (entry.name === '.gitkeep') {
      try {
        fs.mkdirSync(destBase, { recursive: true })
        fs.writeFileSync(destPath, '')
      } catch {}
    }
  }
}

module.exports = {
  packagerConfig: {
    name: 'Oyster',
    icon: './icons/logseq_big_sur.icns',
    buildVersion: "88",
    appBundleId: "com.firehazard.oyster",
    afterCopy: [
      (buildPath, _electronVersion, _platform, _arch, callback) => {
        // electron-packager excludes .gitkeep files during copy, but codesign
        // records all files in the signature. Recreate them so the seal is valid.
        recreateGitkeepFiles(
          path.join(__dirname, 'node_modules'),
          path.join(buildPath, 'node_modules')
        )
        callback()
      }
    ],
    protocols: [
      {
        "protocol": "oyster",
        "name": "oyster",
        "schemes": "oyster"
      }
    ],
    osxSign: APPLE_SIGN_IDENTITY ? {
      identity: APPLE_SIGN_IDENTITY,
      'hardened-runtime': true,
      entitlements: 'entitlements.plist',
      'entitlements-inherit': 'entitlements.plist',
      'signature-flags': 'library'
    } : undefined,
    osxNotarize: APPLE_API_KEY_PATH && APPLE_API_KEY_ID && APPLE_API_ISSUER ? {
      tool: 'notarytool',
      appleApiKey: APPLE_API_KEY_PATH,
      appleApiKeyId: APPLE_API_KEY_ID,
      appleApiIssuer: APPLE_API_ISSUER
    } : undefined,
  },
  makers: [
    {
      'name': '@electron-forge/maker-squirrel',
      'config': {
        'name': 'Oyster',
        'setupIcon': './icons/logseq.ico',
        'loadingGif': './icons/installing.gif',
        'certificateFile': process.env.CODE_SIGN_CERTIFICATE_FILE,
        'certificatePassword': process.env.CODE_SIGN_CERTIFICATE_PASSWORD,
        "rfc3161TimeStampServer": "http://timestamp.digicert.com"
      }
    },
    {
      'name': '@electron-forge/maker-wix',
      'config': {
        name: 'Oyster',
        icon: path.join(__dirname, './icons/logseq.ico'),
        language: 1033,
        manufacturer: WINDOWS_MANUFACTURER,
        appUserModelId: 'com.firehazard.oyster',
        upgradeCode: "3778eb84-a0ce-4109-9120-5d4315e0d7de",
        ui: {
          enabled: false,
          chooseDirectory: true,
          images: {
            banner: path.join(__dirname, './windows/banner.jpg'),
            background: path.join(__dirname, './windows/background.jpg')
          },
        },
        // Standard WiX template appends the unsightly "(Machine - WSI)" to the name, so use our own template
        beforeCreate: (msiCreator) => {
          return new Promise((resolve, reject) => {
            fs.readFile(path.join(__dirname,"./windows/wix.xml"), "utf8" , (err, content) => {
                if (err) {
                    reject (err);
                }
                msiCreator.wixTemplate = content;
                resolve();
            });
          });
        }
      }
    },
    {
      name: '@electron-forge/maker-dmg',
      config: {
        format: 'ULFO',
        icon: './icons/logseq_big_sur.icns',
        name: 'Oyster'
      }
    },
    {
      name: '@electron-forge/maker-zip',
      platforms: ['darwin', 'linux', 'win32'],
    },

    {
      name: 'electron-forge-maker-appimage',
      platforms: ['linux'],
      config: {
        mimeType: ["x-scheme-handler/oyster"]
      }
    }
  ],
}
