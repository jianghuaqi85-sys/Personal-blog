(function () {
  'use strict';

  function copyCodeInit() {
    document.querySelectorAll('pre').forEach((pre) => {
      const btn = document.createElement('button');
      btn.className = 'copy-btn';
      btn.textContent = '复制';
      btn.setAttribute('aria-label', '复制代码');

      btn.addEventListener('click', async () => {
        const code = pre.querySelector('code');
        if (!code) return;
        try {
          await navigator.clipboard.writeText(code.textContent);
          btn.textContent = '已复制!';
          setTimeout(() => { btn.textContent = '复制'; }, 2000);
        } catch {
          btn.textContent = '失败';
          setTimeout(() => { btn.textContent = '复制'; }, 2000);
        }
      });

      pre.appendChild(btn);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', copyCodeInit);
  } else {
    copyCodeInit();
  }
})();
