(function () {
  'use strict';

  function typewriterInit() {
    var lines = document.querySelectorAll('.typewriter-line');
    if (!lines.length) return;

    lines.forEach(function (line, i) {
      setTimeout(function () {
        line.classList.add('visible');
      }, 200 + i * 300);
    });

    // 添加闪烁光标到最后一行之后
    var info = document.getElementById('neofetch-info');
    if (info) {
      var cursor = document.createElement('span');
      cursor.className = 'cursor';
      cursor.setAttribute('aria-hidden', 'true');
      setTimeout(function () {
        info.appendChild(cursor);
      }, 200 + lines.length * 300);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', typewriterInit);
  } else {
    typewriterInit();
  }
})();
