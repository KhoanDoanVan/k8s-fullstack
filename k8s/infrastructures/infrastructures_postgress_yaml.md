# PostgreSQL Kubernetes Deployment Explanation and Guide

## 🔎 Giải thích các thành phần trong `Postgres.yaml`

### 1. **ConfigMap**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-init
  namespace: infrastructures
data:
  init.sql: |
    CREATE DATABASE appdb;
```
- **Mục đích**: Lưu trữ script SQL để khởi tạo database ban đầu.
- **Lý do dùng**:
  - Cho phép định nghĩa database (`appdb`) ngay khi container Postgres được khởi chạy.
  - Có thể mở rộng bằng nhiều file SQL khác (tạo schema, bảng, index…).
  - Tách biệt logic cấu hình (SQL) ra khỏi code/image.

---

### 2. **StatefulSet**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: infrastructures
spec:
  serviceName: postgres
  replicas: 1
  ...
```
- **Mục đích**: Triển khai Postgres theo dạng **StatefulSet** thay vì Deployment.
- **Lý do dùng**:
  - PostgreSQL là **stateful application** → cần lưu trữ dữ liệu bền vững.
  - StatefulSet gắn Pod với PersistentVolume, đảm bảo khi Pod restart thì dữ liệu không bị mất.
  - `replicas: 1` vì đây là cấu hình đơn giản, chưa dùng cluster/replication.

#### Bên trong StatefulSet:
- **Container**
  ```yaml
  containers:
  - name: postgres
    image: postgres:15
  ```
  - Sử dụng image chính thức của Postgres (phiên bản 15).
  - Expose port `5432` để các service khác kết nối.

- **Environment variables**
  ```yaml
  env:
  - name: POSTGRES_USER
    value: user
  - name: POSTGRES_PASSWORD
    value: pass
  - name: POSTGRES_DB
    value: appdb
  ```
  - Thiết lập user, password và database mặc định.
  - Đây là cách chuẩn để inject thông tin cấu hình vào container.

- **VolumeMount**
  ```yaml
  volumeMounts:
  - name: data
    mountPath: /var/lib/postgresql/data
  ```
  - Mount volume để Postgres lưu trữ dữ liệu bền vững tại thư mục data.

- **volumeClaimTemplates**
  ```yaml
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
  ```
  - Tạo **PersistentVolumeClaim (PVC)** động cho Pod.
  - `1Gi` dung lượng ban đầu, có thể thay đổi.
  - `ReadWriteOnce`: volume chỉ được gắn cho một node tại một thời điểm.

---

### 3. **Service**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: infrastructures
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
  clusterIP: None
```
- **Mục đích**: Expose Postgres để các ứng dụng trong cluster có thể truy cập.
- **Lý do dùng**:
  - `selector.app: postgres` → trỏ đến Pod của StatefulSet.
  - `port: 5432` → port mặc định của Postgres.
  - `clusterIP: None` → dùng để tạo **Headless Service**, cần thiết khi chạy với StatefulSet, giúp DNS có thể resolve đến từng Pod (vd: `postgres-0.postgres.infrastructures.svc.cluster.local`).

---

## 📄 Hướng dẫn triển khai (README)

### 1. Overview
This setup provides a simple **PostgreSQL** instance running on Kubernetes with persistent storage and initialization script.

### 2. Components

#### ConfigMap (`postgres-init`)
- Stores initialization SQL (`init.sql`).
- Creates the default database `appdb` when the container starts.
- Easy to extend with additional SQL scripts.

#### StatefulSet (`postgres`)
- Runs PostgreSQL as a stateful application.
- Uses the official image `postgres:15`.
- Configured with:
  - **User**: `user`
  - **Password**: `pass`
  - **Default Database**: `appdb`
- Persists data using a PersistentVolumeClaim:
  - Size: `1Gi`
  - Access mode: `ReadWriteOnce`

#### Service (`postgres`)
- Exposes PostgreSQL to other services in the cluster.
- **Headless Service** (`clusterIP: None`), required for StatefulSet.
- Accessible via DNS:
  ```
  postgres.infrastructures.svc.cluster.local:5432
  ```

### 3. Usage

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

### 4. Notes
- Storage is set to **1Gi**; adjust as needed.
- This deployment is **single-node Postgres** (no replication/HA).
- For production, consider:
  - Replication with multiple replicas.
  - Backup & restore strategy.
  - Secrets instead of plain environment variables.
