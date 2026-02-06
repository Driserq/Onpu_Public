export function jobMetaKey(jobId) {
    return `job:${jobId}:meta`;
}
export function jobResultKey(jobId) {
    return `job:${jobId}:result`;
}
export function jobsPendingKey(userId) {
    return `jobs:pending:${userId}`;
}
export function jobsRecentKey(userId) {
    return `jobs:recent:${userId}`;
}
export function userJobEventsChannel(userId) {
    return `user:${userId}:job-events`;
}
