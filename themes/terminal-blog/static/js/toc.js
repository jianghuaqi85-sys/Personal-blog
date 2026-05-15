(function () {
  'use strict';

  function tocInit() {
    const tocNav = document.getElementById('toc-nav');
    const content = document.getElementById('post-content');
    if (!tocNav || !content) return;

    const headings = content.querySelectorAll('h2, h3');
    const links = tocNav.querySelectorAll('a');

    if (!headings.length || !links.length) return;

    // 高亮当前章节
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = entry.target.id;
            links.forEach((link) => {
              link.classList.toggle(
                'toc__link--active',
                link.getAttribute('href') === '#' + id
              );
            });
          }
        });
      },
      { rootMargin: '-80px 0px -80% 0px' }
    );

    headings.forEach((h) => observer.observe(h));
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', tocInit);
  } else {
    tocInit();
  }
})();
