from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
from typing import List
import os
from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import time
from fastapi import Request

load_dotenv("../")

# Database Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://username:password@localhost/todoapp")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# Database Model
class Todo(Base):
    __tablename__ = "todos"

    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, index=True)
    completed = Column(Boolean, default=False)


# Create tables
Base.metadata.create_all(bind=engine)


# Pydantic Models
class TodoCreate(BaseModel):
    description: str


class TodoUpdate(BaseModel):
    description: str = None
    completed: bool = None


class TodoResponse(BaseModel):
    id: int
    description: str
    completed: bool

    class Config:
        from_attributes = True


# FastAPI App
app = FastAPI(title="Todo List API", version="1.0.0")

# CORS middleware to allow frontend requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics
todo_counter = Counter('todos_total', 'Total number of todos created')
todo_completed_counter = Counter('todos_completed_total', 'Total number of todos completed')
todo_deleted_counter = Counter('todos_deleted_total', 'Total number of todos deleted')
active_todos_gauge = Gauge('todos_active', 'Number of active todos')
request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration')

# Middleware to measure request duration
@app.middleware("http")
async def add_request_timing(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    request_duration.observe(duration)
    return response

# Initialize Prometheus instrumentator
instrumentator = Instrumentator()
instrumentator.instrument(app).expose(app)


# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# API Endpoints

@app.get("/")
def read_root():
    return {"message": "Todo List API"}


@app.post("/todos/", response_model=TodoResponse)
def create_todo(todo: TodoCreate, db: Session = Depends(get_db)):
    db_todo = Todo(description=todo.description)
    db.add(db_todo)
    db.commit()
    db.refresh(db_todo)
    
    # Update metrics
    todo_counter.inc()
    update_active_todos_gauge(db)
    
    return db_todo


@app.get("/todos/", response_model=List[TodoResponse])
def read_todos(db: Session = Depends(get_db)):
    todos = db.query(Todo).all()
    return todos


@app.get("/todos/{todo_id}", response_model=TodoResponse)
def read_todo(todo_id: int, db: Session = Depends(get_db)):
    todo = db.query(Todo).filter(Todo.id == todo_id).first()
    if todo is None:
        raise HTTPException(status_code=404, detail="Todo not found")
    return todo


@app.put("/todos/{todo_id}", response_model=TodoResponse)
def update_todo(todo_id: int, todo_update: TodoUpdate, db: Session = Depends(get_db)):
    todo = db.query(Todo).filter(Todo.id == todo_id).first()
    if todo is None:
        raise HTTPException(status_code=404, detail="Todo not found")

    # Track if todoitem is being completed
    was_completed = todo.completed
    
    if todo_update.description is not None:
        todo.description = todo_update.description
    if todo_update.completed is not None:
        todo.completed = todo_update.completed

    db.commit()
    db.refresh(todo)
    
    # Update metrics
    if not was_completed and todo.completed:
        todo_completed_counter.inc()
    update_active_todos_gauge(db)
    
    return todo


@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int, db: Session = Depends(get_db)):
    todo = db.query(Todo).filter(Todo.id == todo_id).first()
    if todo is None:
        raise HTTPException(status_code=404, detail="Todo not found")

    db.delete(todo)
    db.commit()
    
    # Update metrics
    todo_deleted_counter.inc()
    update_active_todos_gauge(db)
    
    return {"message": "Todo deleted successfully"}


# Helper function to update active todos gauge
def update_active_todos_gauge(db: Session):
    active_count = db.query(Todo).filter(Todo.completed == False).count()
    active_todos_gauge.set(active_count)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)