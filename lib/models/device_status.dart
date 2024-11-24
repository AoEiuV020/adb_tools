enum DeviceStatus {
  connected('已连接'),
  offline('离线'),
  unauthorized('未授权'),
  connecting('连接中'),
  disconnected('已断开');

  final String label;
  const DeviceStatus(this.label);
}
