// Push notification support (APNs for iOS)
// This is a placeholder — full implementation requires APNs credentials

const registeredDevices = new Map(); // deviceToken -> { platform, registeredAt }

export function registerDevice(deviceToken, platform = 'ios') {
  registeredDevices.set(deviceToken, {
    platform,
    registeredAt: new Date().toISOString(),
  });
}

export function unregisterDevice(deviceToken) {
  registeredDevices.delete(deviceToken);
}

export async function sendPushNotification(title, body, data = {}) {
  // TODO: Implement APNs push
  // For now, just log
  console.log(`[Push] ${title}: ${body}`, data);
  
  // Would use something like:
  // import apn from 'apn';
  // const provider = new apn.Provider({ ... });
  // const notification = new apn.Notification({ alert: { title, body }, payload: data });
  // for (const [token] of registeredDevices) {
  //   await provider.send(notification, token);
  // }
}

export function notifyAgentComplete(agentId, agentName, summary) {
  return sendPushNotification(
    `${agentName} finished`,
    summary || 'Task completed',
    { type: 'agent_complete', agentId }
  );
}

export function notifyAgentNeedsInput(agentId, agentName, question) {
  return sendPushNotification(
    `${agentName} needs input`,
    question || 'Waiting for your response',
    { type: 'needs_input', agentId }
  );
}
