export function jobMetaKey(jobId: string) {
  return `job:${jobId}:meta`;
}

export function jobResultKey(jobId: string) {
  return `job:${jobId}:result`;
}

export function jobsPendingKey(userId: string) {
  return `jobs:pending:${userId}`;
}

export function jobsRecentKey(userId: string) {
  return `jobs:recent:${userId}`;
}

export function userJobEventsChannel(userId: string) {
  return `user:${userId}:job-events`;
}
