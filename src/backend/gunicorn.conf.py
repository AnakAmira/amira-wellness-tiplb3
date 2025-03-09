import os
import multiprocessing
from app.core.config import settings, LOG_LEVEL, ENVIRONMENT

# Server socket binding
bind = '0.0.0.0:8000'

# Worker processes
# The recommended formula is (2 x $num_cores) + 1
# This can be overridden with an environment variable
workers = multiprocessing.cpu_count() * 2 + 1 if not os.getenv('GUNICORN_WORKERS') else int(os.getenv('GUNICORN_WORKERS'))

# Worker class - use uvicorn worker for ASGI/FastAPI compatibility
worker_class = os.getenv('GUNICORN_WORKER_CLASS', 'uvicorn.workers.UvicornWorker')

# Maximum number of simultaneous clients per worker
worker_connections = 1000

# Timeout for worker processes (in seconds)
timeout = 60

# Time to keep connections alive after requests finish (in seconds)
keepalive = 5

# Restart workers after this many requests (helps prevent memory leaks)
max_requests = 1000

# Add randomness to the max_requests value to prevent all workers from restarting at once
max_requests_jitter = 200

# How long to wait for workers to gracefully exit (in seconds)
graceful_timeout = 30

# Access log settings - output to stdout/stderr for container environments
accesslog = '-'
errorlog = '-'

# Log level - use the log level from settings or fall back to 'info'
loglevel = os.getenv('LOG_LEVEL', 'info').lower()

# Custom access log format with request timing
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(L)s'

# Process name
proc_name = 'amira_api'

# Trust X-Forwarded-* headers from all IPs when behind load balancers
forwarded_allow_ips = '*'

# Headers that determine if the connection is HTTPS
secure_scheme_headers = {'X-Forwarded-Proto': 'https'}

# --- Event Handlers ---

def on_starting(server):
    """Handler called when Gunicorn is starting up."""
    print(f"Starting Amira Wellness API server in {ENVIRONMENT} environment")
    # Could initialize resources here if needed before workers start
    
def on_exit(server):
    """Handler called when Gunicorn is shutting down."""
    print("Shutting down Amira Wellness API server")
    # Perform any final cleanup here
    
def post_fork(server, worker):
    """Handler called after a worker has been forked."""
    print(f"Worker {worker.pid} initialized")
    # Could set worker-specific configurations here

def worker_int(worker):
    """Handler called when a worker receives SIGINT or SIGQUIT."""
    print(f"Worker {worker.pid} received interrupt signal")
    # Perform graceful shutdown tasks for the worker
    
def worker_abort(worker):
    """Handler called when a worker receives SIGABRT."""
    print(f"Worker {worker.pid} aborted")
    # Emergency cleanup for the worker
    
def pre_request(worker, req):
    """Handler called just before a request is processed."""
    # Set request-specific context if needed
    pass
    
def post_request(worker, req, environ, resp):
    """Handler called after a request has been processed."""
    # Could log request metrics or perform cleanup here
    pass
    
def child_exit(server, worker):
    """Handler called when a worker exits."""
    print(f"Worker {worker.pid} exited")
    # Clean up worker-specific resources if needed