export function modifyConfig(config: Config): Config {
  // MCP über SSE auf 8003 wird via .continue/config.yaml konfiguriert.
  // Keine STDIO-/Autostart-Konfiguration hier nötig.
  return config;
}