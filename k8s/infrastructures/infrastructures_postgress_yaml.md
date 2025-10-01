# PostgreSQL Deployment on Kubernetes

This setup provides a simple **PostgreSQL** instance running on Kubernetes with persistent storage and initialization script.

## Components

### 1. ConfigMap (`postgres-init`)
- Stores initialization SQL (`init.sql`).
- Creates the default database `appdb` when the container starts.
- Easy to extend with additional SQL scripts.

### 2. StatefulSet (`postgres`)
- Runs PostgreSQL as a stateful application.
- Uses the official image `postgres:15`.
- Configured with:
  - **User**: `user`
  - **Password**: `pass`
  - **Default Database**: `appdb`
- Persists data using a PersistentVolumeClaim:
  - Size: `1Gi`
  - Access mode: `ReadWriteOnce`

### 3. Service (`postgres`)
- Exposes PostgreSQL to other services in the cluster.
- **Headless Service** (`clusterIP: None`), required for StatefulSet.
- Accessible via DNS:
  ```
  postgres.infrastructures.svc.cluster.local:5432
  ```

## Usage

1. **Deploy resources**:
   ```bash
   kubectl apply -f Postgres.yaml
   ```

2. **Check Pod**:
   ```bash
   kubectl get pods -n infrastructures
   ```

3. **Connect to PostgreSQL**:
   ```bash
   kubectl exec -it -n infrastructures <postgres-pod-name> -- psql -U user -d appdb
   ```

4. **Access from another service**:
   ```
   Host: postgres.infrastructures.svc.cluster.local
   Port: 5432
   User: user
   Password: pass
   Database: appdb
   ```

## Notes
- Storage is set to **1Gi**; adjust as needed.
- This deployment is **single-node Postgres** (no replication/HA).
- For production, consider:
  - Replication with multiple replicas.
  - Backup & restore strategy.
  - Secrets instead of plain environment variables.
