package tunnel

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"sync"
)

const tunnelDomain = "https://laojiang666.cn"

type Manager struct {
	cmd     *exec.Cmd
	url     string
	mu      sync.RWMutex
	urlFile string
}

// NewManager 创建隧道管理器
// cloudflaredPath: cloudflared 可执行文件路径
// port: 本地服务端口
// urlFile: 保存 URL 的文件路径
func NewManager(cloudflaredPath, port, urlFile string) *Manager {
	_ = port // 命名隧道绑定固定域名，端口在 cloudflared config.yml 中配置
	return &Manager{
		cmd:     exec.Command(cloudflaredPath, "--protocol", "http2", "tunnel", "run", "gin-chat"),
		urlFile: urlFile,
	}
}

// Start 启动 Cloudflare Tunnel 并捕获 URL
func (m *Manager) Start() error {
	stderr, err := m.cmd.StderrPipe()
	if err != nil {
		return fmt.Errorf("创建 stderr pipe 失败: %w", err)
	}

	if err := m.cmd.Start(); err != nil {
		return fmt.Errorf("启动 cloudflared 失败: %w", err)
	}

	// 写入固定域名到 URL 文件（命名隧道使用自定义域名）
	m.mu.Lock()
	m.url = tunnelDomain
	m.mu.Unlock()
	if err := os.WriteFile(m.urlFile, []byte(tunnelDomain), 0644); err != nil {
		log.Printf("[WARN] 保存隧道 URL 失败: %v", err)
	} else {
		log.Printf("Cloudflare Tunnel 固定域名: %s", tunnelDomain)
	}

	// 从 stderr 读取输出（仅用于日志监控）
	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			line := scanner.Text()

			// 输出 cloudflared 日志
			if strings.Contains(line, "ERR") || strings.Contains(line, "error") {
				log.Printf("[cloudflared] %s", line)
			}
		}
	}()

	// 等待进程结束
	go func() {
		if err := m.cmd.Wait(); err != nil {
			log.Printf("[WARN] cloudflared 进程退出: %v", err)
		}
	}()

	return nil
}

// GetURL 获取当前隧道 URL
func (m *Manager) GetURL() string {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.url
}

// Stop 停止隧道
func (m *Manager) Stop() {
	if m.cmd != nil && m.cmd.Process != nil {
		m.cmd.Process.Kill()
	}
	// 清理 URL 文件
	os.Remove(m.urlFile)
}
