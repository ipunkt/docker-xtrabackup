# xtrabackup
This image uses martinhelmich/xtrabackup and adds an entrypoint script which
translates environment variables into xtrabackup parameters

# Usage
If a command is given then the entrypoint will execute the command as given.
Otherwise it will run xtrabackup with parameters given in the environment:

| Environment variable | xtradebug parameter | defaults to |
| ==================== | =================== | =========== |
| MYSQL\_HOST | --host $PARAM | target |
| MYSQL\_PORT | --port $PARAM | 3306 |
| MYSQL\_USER | --user $PARAM | - |
| MYSQL\_PASSWORD | --password $PARAM | - |

Current behavious is to prepare the backup fully aftyer creating it. This will
probably change in the future as we start implementing incremental backups and
preparing on utility servers.
