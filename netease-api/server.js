const fs = require('fs');
const path = require('path');
const tmpPath = require('os').tmpdir();

// 确保 anonymous_token 文件存在
const tokenPath = path.resolve(tmpPath, 'anonymous_token');
if (!fs.existsSync(tokenPath)) {
  fs.writeFileSync(tokenPath, '', 'utf-8');
}

const { serveNcmApi } = require('NeteaseCloudMusicApi/server');

serveNcmApi({
  port: 3000,
  checkVersion: false,
}).then(() => {
  console.log('NeteaseCloudMusicApi running on http://localhost:3000');
}).catch(err => {
  console.error('Failed to start:', err);
  process.exit(1);
});
