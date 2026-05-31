## 0.0.1

* Initial release.
* Added `OfflineRetryInterceptor` to automatically catch and queue network connection errors.
* Implemented `OfflineQueueDb` for persistent SQLite storage of failed POST, PUT, DELETE, and PATCH
  requests.
* Added `RetryManager` to listen for connectivity changes via `connectivity_plus` and silently
  process the queue in the background.
* Added safety checks to ignore GET requests, preventing stale data fetching upon reconnection.