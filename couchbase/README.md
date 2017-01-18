Couchbase (Community)
=====================

> **Use at your own risk!!** While the software will run, it has NOT been
> tested under production loads.

## Usage

```
hab start bdangit/couchbase
```

## Notes
- **Logs are not stdout.**  They get stored under
  `/hab/svc/couchbase/var/lib/couchbase/logs`
- **Setup of a node has not been fully automated.** The packaging has
  been a vanilla setup as if you were to install Couchbase yourself. Future
  work will make the configuration of a node all from config files.
