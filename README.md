# xtrabackup
This image uses martinhelmich/xtrabackup as a base and tries to provide an
entrypoint to support full backup and restore procedures from within rancher

## Use case
The image is built with the following use case in mind:

- There is a running mysql flavored server(mysql, mariadb, percona xtradb) which
has `/var/lib/mysql` on a named volume[1]  
- Backups are written to a named volume on a convoy vfs - mounted to a hetzner
storagebox(cifs)  
- Restore is done by starting a new server container, shutting it down, removing
the data directory and restoring from the backup.
- A full restore is achieved by switching the sql load balancer to the new
container.
- A partial restore is done by attaching a pma to the new container and copying
the intended data.
- This is tested on a percona xtradb galera cluster

[1] it is also possible to use the image via --volumes-from on a data container
instead of having named volumes but I do not know of a way to leverage this from
within rancher as --volumes-from requires a sidekick relationship there.

## Usage
The container knows the following commands. Starting the container without a
command will prompt the container to print its usage information.

- backup
  Use xtrabackup to create a backup to /target/YY-mm-dd-HH\_ii
- restore BACKUP
  Attempts to restore the given BACKUP from /target/BACKUP
- clear
  Clears the backup directory in preparation for restoring a backup. This is
  separate from restore to allow this command to run on all hosts of a galera
  cluster
- run COMMAND
  Run the given command within the container
- help
  Print Usage

### backup

| Environment variable | xtradebug parameter | defaults to |
| -------------------- | ------------------- | ----------- |
| MYSQL\_HOST | --host $PARAM | target |
| MYSQL\_PORT | --port $PARAM | 3306 |
| MYSQL\_USER | --user $PARAM | - |
| MYSQL\_PASSWORD | --password $PARAM | - |

Current behavious is to prepare the backup fully aftyer creating it. This will
probably change in the future as we start implementing incremental backups and
preparing on utility servers.

### restore

### clear
Clean the mysql database data via `rm -Rf /var/lib/mysql/*`.  
This is intended to be used with `run on all hosts` and scheduling rule `must
have service DBSTACK/NEWDBSERVICE` to prepare the new database cluster to receive
the backup

### run COMMAND
Runs the given command as command line within the containers. This is intended
to debug the container.

### help
Prints usage.  
Currently only prints the full overview.

help [COMMAND] might be included in the future if the need arises

## Example
- Step 1: Create backup from existing data which is not within  
	
	```sh
	docker volume create --driver=convoy --name=backup
	docker run -it --volumes-from DB_DATA_VOLUME_CONTAINER -v backup:/target --link DB_SERVER_CONTAINER:target -e MYSQL\_PORT=3306 -e MYSQL\_USER=root -e MYSQL_PASSWORD='PASSWORD' ipunktbs/xtrabackup
	```
	
- Step 2: Create new PXC cluster from Rancher Catalog
- Step 3: Upgrade PXC service to match your scheduling needs
- Step 4: Stop PXC service
- Step 5: Create ipunktbs/xtrabackup service with
  - Command: clear
  - Scheduling: All hosts, must have service DBSTACK/DBSERVICE
  - Volumes: PXC\_NAMED\_MYSQL\_VOLUME:/var/lib/mysql
- Step 6: Delete the clear service after all instances have successfully finished
- Step 7: Create ipunktbs/xtrabackup service with
  - Command: restore
  - Scheduling: Scale 1, must have service DBSTACK/DBSERVICE
  - Volumes: PXC\_NAMED\_MYSQL\_VOLUME:/var/lib/mysql, backup:/target
  - Note: You might have to do this using rancher-compose until per-volume driver is available in rancher, or create the `backup` volume with a driver on all hosts
- Step 8: Start the pxc server on the server where the `restore` container ran
  and run the command `SET GLOBAL wsrep_provider_options="pc.bootstrap=1";` to
  make it the new master.
- Step 9: Start the other pxc servers and wait for the state sync
