// 全站迷你播放器
(function () {
  'use strict';

  var STORAGE_KEY = 'music_player_state';
  var SESSION_TTL = 30000; // sessionStorage 30 秒有效
  var SYNC_INTERVAL = 3000;

  function MiniPlayer() {
    this.audio = new Audio();
    this.tracks = [];
    this.index = 0;
    this.syncTimer = null;

    // DOM
    this.el = document.getElementById('mini-player');
    if (!this.el) return;

    this.coverImg = document.getElementById('mini-cover-img');
    this.titleEl = document.getElementById('mini-title');
    this.artistEl = document.getElementById('mini-artist');
    this.playBtn = document.getElementById('mini-play');
    this.playIcon = document.getElementById('mini-play-icon');
    this.prevBtn = document.getElementById('mini-prev');
    this.nextBtn = document.getElementById('mini-next');
    this.barEl = document.getElementById('mini-bar');
    this.playedEl = document.getElementById('mini-played');
    this.timeEl = document.getElementById('mini-time');

    this.bindEvents();
    this.restore();
  }

  MiniPlayer.prototype.bindEvents = function () {
    var self = this;

    this.playBtn.addEventListener('click', function () { self.togglePlay(); });
    this.prevBtn.addEventListener('click', function () { self.prev(); });
    this.nextBtn.addEventListener('click', function () { self.next(); });

    // 进度条拖拽
    this.barEl.addEventListener('mousedown', function (e) { self.startDrag(e); });
    document.addEventListener('mousemove', function (e) { self.onDrag(e); });
    document.addEventListener('mouseup', function () { self.endDrag(); });
    this.barEl.addEventListener('touchstart', function (e) { self.startDrag(e.touches[0]); }, { passive: true });
    document.addEventListener('touchmove', function (e) { if (self.dragging) self.onDrag(e.touches[0]); }, { passive: true });
    document.addEventListener('touchend', function () { self.endDrag(); });

    this.audio.addEventListener('timeupdate', function () {
      if (!self.dragging) self.updateProgress();
    });
    this.audio.addEventListener('loadedmetadata', function () { self.updateProgress(); });
    this.audio.addEventListener('ended', function () { self.next(); });
    this.audio.addEventListener('error', function () { self.next(); });

    // 定期同步到 localStorage + sessionStorage
    this.syncTimer = setInterval(function () { self.syncAll(); }, SYNC_INTERVAL);

    // 用 visibilitychange 保存状态（比 beforeunload 更可靠，尤其移动端）
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) {
        // 页面隐藏时保存状态
        self.syncAll();
      } else {
        // 页面恢复可见时，刷新恢复
        self.restore();
      }
    });

    // beforeunload 作为兜底
    window.addEventListener('pagehide', function () { self.syncAll(); });
  };

  // --- 恢复状态 ---
  MiniPlayer.prototype.restore = function () {
    // 音乐页面不初始化迷你播放器
    if (window.location.pathname.indexOf('/music/') === 0) {
      this.el.classList.add('mini-player--hidden');
      this.stopInlineAudio();
      return;
    }

    // 优先从 sessionStorage 恢复
    var session = this.readSession();
    if (session && session.url) {
      this.stopInlineAudio(); // 停掉 head.html 里内联启动的 Audio

      // 用 localStorage 补全完整播放列表
      var full = this.readStorage();
      this.tracks = (session.tracks && session.tracks.length > 1) ? session.tracks : (full ? full.tracks : session.tracks || []);
      this.index = session.index || 0;

      this.audio.src = session.url;
      var elapsed = session.ts ? (Date.now() - session.ts) / 1000 : 0;
      var targetTime = Math.min((session.currentTime || 0) + elapsed, (session.duration || 99999));
      this.audio.currentTime = targetTime;
      this.updateUI();

      if (session.playing) {
        this.audio.play().catch(function () {});
      }
      this.show();
      return;
    }

    // 回退到 localStorage
    var state = this.readStorage();
    if (!state || !state.tracks || !state.tracks.length) return;

    this.tracks = state.tracks;
    this.index = Math.min(state.index || 0, this.tracks.length - 1);
    var track = this.tracks[this.index];
    if (!track || !track.url) return;

    this.audio.src = track.url;
    this.audio.currentTime = state.currentTime || 0;
    this.updateUI();

    if (state.playing) {
      this.audio.play().catch(function () {});
    }
    this.show();
  };

  // 停止 head.html 内联启动的 Audio
  MiniPlayer.prototype.stopInlineAudio = function () {
    if (window.__miniAudio) {
      try { window.__miniAudio.pause(); } catch (e) {}
      window.__miniAudio = null;
    }
  };

  // --- 播放控制 ---
  MiniPlayer.prototype.togglePlay = function () {
    if (!this.tracks.length) return;
    if (this.audio.paused) {
      this.audio.play().catch(function () {});
    } else {
      this.audio.pause();
    }
    this.updatePlayIcon();
    this.syncAll();
  };

  MiniPlayer.prototype.prev = function () {
    if (!this.tracks.length) return;
    this.index = (this.index - 1 + this.tracks.length) % this.tracks.length;
    this.loadTrack();
  };

  MiniPlayer.prototype.next = function () {
    if (!this.tracks.length) return;
    this.index = (this.index + 1) % this.tracks.length;
    this.loadTrack();
  };

  MiniPlayer.prototype.loadTrack = function () {
    var track = this.tracks[this.index];
    if (!track || !track.url) return;
    this.audio.src = track.url;
    this.audio.currentTime = 0;
    this.audio.play().catch(function () {});
    this.updateUI();
    this.syncAll();
  };

  // --- UI ---
  MiniPlayer.prototype.updateUI = function () {
    var track = this.tracks[this.index];
    if (!track) return;
    this.coverImg.src = track.cover || '';
    this.titleEl.textContent = track.name || '--';
    this.artistEl.textContent = track.artist || '--';
    this.updatePlayIcon();
    this.updateProgress();
  };

  MiniPlayer.prototype.updatePlayIcon = function () {
    var paused = this.audio.paused;
    this.playIcon.innerHTML = paused
      ? '<path d="M8 5v14l11-7z" fill="currentColor"/>'
      : '<path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" fill="currentColor"/>';
  };

  MiniPlayer.prototype.updateProgress = function () {
    var current = this.audio.currentTime || 0;
    var duration = this.audio.duration || 0;
    var pct = duration > 0 ? (current / duration * 100) : 0;
    this.playedEl.style.width = pct + '%';
    this.timeEl.textContent = formatTime(current);
  };

  MiniPlayer.prototype.show = function () {
    this.el.style.display = 'flex';
    document.body.classList.add('has-mini-player');
  };

  // --- 进度条拖拽 ---
  MiniPlayer.prototype.startDrag = function (e) {
    if (!this.audio.duration) return;
    this.dragging = true;
    this.seekTo(e);
  };
  MiniPlayer.prototype.onDrag = function (e) {
    if (this.dragging) this.seekTo(e);
  };
  MiniPlayer.prototype.endDrag = function () {
    if (!this.dragging) return;
    this.dragging = false;
    this.syncAll();
  };
  MiniPlayer.prototype.seekTo = function (e) {
    var rect = this.barEl.getBoundingClientRect();
    var pct = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
    this.audio.currentTime = pct * this.audio.duration;
    this.playedEl.style.width = (pct * 100) + '%';
    this.timeEl.textContent = formatTime(this.audio.currentTime);
  };

  // --- 存储 ---
  MiniPlayer.prototype.readStorage = function () {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      var state = JSON.parse(raw);
      if (Date.now() - (state.ts || 0) > 24 * 60 * 60 * 1000) return null;
      return state;
    } catch (e) { return null; }
  };

  MiniPlayer.prototype.readSession = function () {
    try {
      var raw = sessionStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      var state = JSON.parse(raw);
      if (Date.now() - (state.ts || 0) > SESSION_TTL) return null;
      return state;
    } catch (e) { return null; }
  };

  MiniPlayer.prototype.syncAll = function () {
    if (!this.tracks.length) return;
    var track = this.tracks[this.index];
    if (!track) return;
    var now = Date.now();
    var ct = this.audio.currentTime || 0;
    var playing = !this.audio.paused;
    var dur = this.audio.duration || 0;
    try {
      // localStorage（长期）
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        tracks: this.tracks, index: this.index,
        currentTime: ct, playing: playing, ts: now
      }));
      // sessionStorage（即时接力）
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify({
        url: track.url, tracks: this.tracks, index: this.index,
        currentTime: ct, duration: dur, playing: playing, ts: now
      }));
    } catch (e) {}
  };

  // --- 工具 ---
  function formatTime(sec) {
    sec = Math.floor(sec || 0);
    var m = Math.floor(sec / 60);
    var s = sec % 60;
    return m + ':' + (s < 10 ? '0' : '') + s;
  }

  // --- 全局 API（供音乐页面调用） ---
  window.MiniPlayerState = {
    sync: function (tracks, index, currentTime, playing) {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify({
          tracks: tracks, index: index || 0,
          currentTime: currentTime || 0, playing: !!playing, ts: Date.now()
        }));
      } catch (e) {}
    },
    syncSession: function (track, index, currentTime, playing, tracks) {
      if (!track) return;
      try {
        sessionStorage.setItem(STORAGE_KEY, JSON.stringify({
          url: track.url, tracks: tracks || [], index: index || 0,
          currentTime: currentTime || 0, duration: 0, playing: !!playing, ts: Date.now()
        }));
      } catch (e) {}
    },
    clear: function () {
      localStorage.removeItem(STORAGE_KEY);
      sessionStorage.removeItem(STORAGE_KEY);
    }
  };

  // 初始化
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { new MiniPlayer(); });
  } else {
    new MiniPlayer();
  }
})();
