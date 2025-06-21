# DevOps Final Project - Todo List Application

A comprehensive full-stack todo list application with advanced monitoring, security scanning, and containerized deployment using modern DevOps practices.

## 🏗️ Architecture

This project demonstrates a complete DevOps pipeline with:

- **Frontend**: Modern HTML/CSS/JavaScript with animated UI
- **Backend**: FastAPI REST API with PostgreSQL database
- **Monitoring**: Prometheus metrics collection with Grafana dashboards
- **Security**: Trivy vulnerability scanning and security-hardened containers
- **Containerization**: Docker and Docker Compose orchestration

## 🚀 Features

### Application Features
- ✅ Create, read, update, and delete todos
- ✅ Mark todos as complete/incomplete
- ✅ Real-time metrics collection
- ✅ Responsive and animated UI

### DevOps Features
- 🔒 **Security-first approach** with Alpine-based containers
- 📊 **Comprehensive monitoring** with Prometheus + Grafana
- 🛡️ **Vulnerability scanning** with Trivy security reports
- 🐳 **Containerized deployment** with Docker Compose
- 📈 **Custom metrics** for business logic monitoring

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| **Frontend** | HTML5, CSS3, JavaScript, Nginx |
| **Backend** | FastAPI, Python 3.11, SQLAlchemy |
| **Database** | PostgreSQL 17 Alpine |
| **Monitoring** | Prometheus, Grafana, Node Exporter |
| **Security** | Trivy scanner, Alpine base images |
| **Orchestration** | Docker, Docker Compose |

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd DevOps_Final
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start the application**
   ```bash
   docker-compose up -d
   ```

4. **Access the services**
   - **Todo App**: http://localhost:3000
   - **API Docs**: http://localhost:8000/docs
   - **Prometheus**: http://localhost:9090
   - **Grafana**: http://localhost:3001

## 🏃‍♂️ Development

### Environment Variables

Create a `.env` file in the project root:

```env
# Database Configuration
POSTGRES_DB=todoapp
POSTGRES_USER=todouser
POSTGRES_PASSWORD=todopass
DATABASE_URL=postgresql://todouser:todopass@database:5432/todoapp

# Grafana Configuration
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
```

### Building Individual Services

```bash
# Run the whole stack
docker compose up --build

# Build backend only
docker-compose build backend

# Build frontend only
docker-compose build frontend

# Rebuild with no cache
docker-compose build --no-cache
```

### Accessing Logs

```bash
# View all logs
docker-compose logs

# Follow specific service logs
docker-compose logs -f backend
docker-compose logs -f database
```

## 📊 Monitoring & Metrics

### Available Metrics

The application exposes custom Prometheus metrics:

| Metric | Type | Description |
|--------|------|-------------|
| `todos_total` | Counter | Total todos created |
| `todos_completed_total` | Counter | Total todos completed |
| `todos_deleted_total` | Counter | Total todos deleted |
| `todos_active` | Gauge | Current active todos |
| `http_request_duration_seconds` | Histogram | API request latency |

### Grafana Dashboards

Pre-configured dashboards available:

- **Todo Application Dashboard**: Business metrics and API performance
- **System Monitoring Dashboard**: Infrastructure metrics (CPU, memory, disk)

Access Grafana at http://localhost:3001 with credentials that you create in ```.env``` file

## 🔒 Security

### Security Scanning

Run Trivy security scans:

```bash
# Scan all images
./scripts/trivy-scan.sh

# View security summary
cat security-reports/security-summary.txt
```

### Current Security Status

Latest scan results show:
- ✅ Backend: 0 Critical, 0 High vulnerabilities
- ✅ Frontend: 0 Critical, 0 High vulnerabilities
- ✅ Grafana: 0 Critical, 0 High vulnerabilities
- ✅ Node Exporter: 0 Critical, 0 High vulnerabilities

## 🐳 Docker Services

| Service | Port | Description |
|---------|------|-------------|
| `frontend` | 3000 | Nginx-served React app |
| `backend` | 8000 | FastAPI REST API |
| `database` | 5432 | PostgreSQL database |
| `prometheus` | 9090 | Metrics collection |
| `grafana` | 3001 | Monitoring dashboards |
| `node-exporter` | 9100 | System metrics |

## 🔧 API Documentation

### Endpoints

- `GET /todos/` - List all todos
- `POST /todos/` - Create a new todo
- `GET /todos/{id}` - Get specific todo
- `PUT /todos/{id}` - Update todo
- `DELETE /todos/{id}` - Delete todo
- `GET /metrics` - Prometheus metrics

Full API documentation available at http://localhost:8000/docs