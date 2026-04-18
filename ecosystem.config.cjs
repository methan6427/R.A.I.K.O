// pm2 ecosystem for R.A.I.K.O.
//
// Usage from the repo root:
//   npm run build
//   pm2 start ecosystem.config.cjs
//   pm2 save
//
// On Windows, to make pm2 itself survive reboots, install once:
//   npm install -g pm2 pm2-windows-startup
//   pm2-startup install
//   pm2 save

const path = require('node:path');

module.exports = {
  apps: [
    {
      name: 'raiko-backend',
      cwd: path.join(__dirname, 'apps', 'backend'),
      script: './dist/index.js',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
        // Auto-run migrations on every startup. Safe because migrations are
        // idempotent and tracked in the database.
        RAIKO_RUN_MIGRATIONS: 'true',
      },
      out_file: path.join(__dirname, 'apps', 'backend', 'backend.log'),
      error_file: path.join(__dirname, 'apps', 'backend', 'backend.err.log'),
      merge_logs: true,
      time: true,
    },
  ],
};
