from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
import logging
import os
from datetime import datetime

# Load environment variables
try:
    from dotenv import load_dotenv
    load_dotenv()
    logger = logging.getLogger(__name__)
    logger.info("✅ Loaded environment variables from .env file")
except ImportError:
    logger = logging.getLogger(__name__)
    logger.warning("⚠️ python-dotenv not installed, using system environment only")
except Exception as e:
    logger = logging.getLogger(__name__)
    logger.warning(f"⚠️ Could not load .env file: {str(e)}")

# Import our agents and configuration
from config.firebase_config import firebase_config, get_firestore_db
from agents.multi_agent_system import MultiAgentSystem
from agents.base_agent import UserQuery, AgentResponse

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI app
app = FastAPI(
    title="Samsung Prism Multi-Agent Banking System",
    description="AI-powered banking assistance with specialized agents",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global multi-agent system instance
multi_agent_system: Optional[MultiAgentSystem] = None

# Pydantic models for API
class QueryRequest(BaseModel):
    user_id: str
    query_text: str
    intent: Optional[str] = None
    entities: Optional[Dict[str, Any]] = None
    context: Optional[Dict[str, Any]] = None

class QueryResponse(BaseModel):
    agent_name: str
    response_text: str
    confidence: float
    action_taken: Optional[str] = None
    data: Optional[Dict[str, Any]] = None
    timestamp: str

class SystemStatus(BaseModel):
    system_name: str
    version: str
    agents_count: int
    agents: Dict[str, Any]
    confidence_threshold: float
    timestamp: str

class HealthCheck(BaseModel):
    system_healthy: bool
    agents_status: Dict[str, Any]
    database_connection: bool
    timestamp: str

# Authentication Models
class LoginRequest(BaseModel):
    email: str
    password: str

class AuthResponse(BaseModel):
    success: bool
    user_id: Optional[str] = None
    access_token: Optional[str] = None
    user_data: Optional[Dict[str, Any]] = None
    message: str

class UserRegistration(BaseModel):
    email: str
    password: str
    full_name: str
    phone: Optional[str] = None
    date_of_birth: Optional[str] = None

class UserProfile(BaseModel):
    user_id: str
    email: str
    full_name: str
    phone: Optional[str] = None
    date_of_birth: Optional[str] = None
    account_balance: Optional[float] = None
    account_number: Optional[str] = None
    created_at: str
    last_login: Optional[str] = None

@app.on_event("startup")
async def startup_event():
    """Initialize the system on startup"""
    global multi_agent_system
    
    try:
        logger.info("Initializing Samsung Prism Multi-Agent System...")
        
        # Initialize Firebase
        service_account_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if not firebase_config.initialize_firebase(service_account_path):
            raise Exception("Failed to initialize Firebase")
        
        # Test Firebase connection (skip if SKIP_CONNECTION_TEST is set)
        skip_test = os.getenv('SKIP_CONNECTION_TEST', 'false').lower() == 'true'
        if not skip_test:
            if not firebase_config.test_connection():
                logger.warning("⚠️ Firebase connection test failed - this may indicate permission issues")
                logger.warning("⚠️ To skip this test temporarily, set SKIP_CONNECTION_TEST=true in .env")
                raise Exception("Firebase connection test failed")
        else:
            logger.info("⚠️ Skipping Firebase connection test (SKIP_CONNECTION_TEST=true)")
        
        # Initialize multi-agent system
        db = get_firestore_db()
        multi_agent_system = MultiAgentSystem(db)
        
        logger.info("✅ Samsung Prism Multi-Agent System initialized successfully")
        
    except Exception as e:
        logger.error(f"❌ Failed to initialize system: {str(e)}")
        raise

def get_multi_agent_system() -> MultiAgentSystem:
    """Dependency to get multi-agent system instance"""
    if multi_agent_system is None:
        raise HTTPException(status_code=500, detail="Multi-agent system not initialized")
    return multi_agent_system

@app.get("/", summary="Root endpoint")
async def root():
    """Root endpoint with basic information"""
    return {
        "message": "Samsung Prism Multi-Agent Banking System",
        "version": "1.0.0",
        "status": "active",
        "endpoints": [
            "/query - Process user queries",
            "/health - System health check",
            "/status - System status",
            "/capabilities - Agent capabilities",
            "/docs - API documentation"
        ]
    }

@app.post("/query", response_model=QueryResponse, summary="Process user query")
async def process_query(
    request: QueryRequest,
    system: MultiAgentSystem = Depends(get_multi_agent_system)
) -> QueryResponse:
    """
    Process a user query through the multi-agent system
    
    - **user_id**: Unique identifier for the user
    - **query_text**: The user's question or request
    - **intent**: Optional intent classification
    - **entities**: Optional extracted entities
    - **context**: Optional context information
    """
    try:
        logger.info(f"Processing query from user {request.user_id}")
        
        # Create user query object
        user_query = UserQuery(
            user_id=request.user_id,
            query_text=request.query_text,
            intent=request.intent,
            entities=request.entities,
            context=request.context
        )
        
        # Process through multi-agent system
        response = await system.process_query(user_query)
        
        # Convert to API response format
        return QueryResponse(
            agent_name=response.agent_name,
            response_text=response.response_text,
            confidence=response.confidence,
            action_taken=response.action_taken,
            data=response.data,
            timestamp=response.timestamp
        )
        
    except Exception as e:
        logger.error(f"Error processing query: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Query processing failed: {str(e)}")

@app.get("/health", response_model=HealthCheck, summary="System health check")
async def health_check(
    system: MultiAgentSystem = Depends(get_multi_agent_system)
) -> HealthCheck:
    """
    Perform comprehensive system health check
    
    Returns status of:
    - Database connection
    - All agents
    - Overall system health
    """
    try:
        health_status = await system.health_check()
        
        return HealthCheck(
            system_healthy=health_status['system_healthy'],
            agents_status=health_status['agents_status'],
            database_connection=health_status['database_connection'],
            timestamp=health_status['timestamp']
        )
        
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")

@app.get("/status", response_model=SystemStatus, summary="System status")
async def get_system_status(
    system: MultiAgentSystem = Depends(get_multi_agent_system)
) -> SystemStatus:
    """
    Get detailed system status and agent information
    
    Returns:
    - System information
    - Agent count and details
    - Configuration parameters
    """
    try:
        status = system.get_system_status()
        
        return SystemStatus(
            system_name=status['system_name'],
            version=status['version'],
            agents_count=status['agents_count'],
            agents=status['agents'],
            confidence_threshold=status['confidence_threshold'],
            timestamp=status['timestamp']
        )
        
    except Exception as e:
        logger.error(f"Failed to get system status: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Status retrieval failed: {str(e)}")

@app.get("/capabilities", summary="Get agent capabilities")
async def get_capabilities(
    system: MultiAgentSystem = Depends(get_multi_agent_system)
) -> Dict[str, List[str]]:
    """
    Get capabilities of all agents in the system
    
    Returns:
    - Dictionary mapping agent names to their capabilities
    """
    try:
        return system.get_agent_capabilities()
        
    except Exception as e:
        logger.error(f"Failed to get capabilities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Capabilities retrieval failed: {str(e)}")

@app.get("/agents/{agent_name}/capabilities", summary="Get specific agent capabilities")
async def get_agent_capabilities(
    agent_name: str,
    system: MultiAgentSystem = Depends(get_multi_agent_system)
) -> Dict[str, Any]:
    """
    Get capabilities of a specific agent
    
    - **agent_name**: Name of the agent (account, loan, card, support)
    """
    try:
        all_capabilities = system.get_agent_capabilities()
        
        if agent_name not in all_capabilities:
            raise HTTPException(
                status_code=404, 
                detail=f"Agent '{agent_name}' not found. Available agents: {list(all_capabilities.keys())}"
            )
        
        return {
            "agent_name": agent_name,
            "capabilities": all_capabilities[agent_name],
            "capabilities_count": len(all_capabilities[agent_name])
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get agent capabilities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Agent capabilities retrieval failed: {str(e)}")

# Authentication Endpoints
@app.post("/auth/login", response_model=AuthResponse, summary="User login")
async def login_user(request: LoginRequest) -> AuthResponse:
    """
    Authenticate user with email and password
    
    - **email**: User's email address
    - **password**: User's password
    """
    try:
        db = get_firestore_db()
        
        # Query users collection for matching email
        users_ref = db.collection('users')
        query = users_ref.where('email', '==', request.email).limit(1)
        docs = query.get()
        
        if not docs:
            return AuthResponse(
                success=False,
                message="Invalid email or password"
            )
        
        user_doc = docs[0]
        user_data = user_doc.to_dict()
        
        # In production, use proper password hashing (bcrypt, etc.)
        # For demo purposes, we'll do simple comparison
        if user_data.get('password') == request.password:
            # Update last login
            user_doc.reference.update({
                'last_login': datetime.now().isoformat()
            })
            
            return AuthResponse(
                success=True,
                user_id=user_doc.id,
                access_token=f"token_{user_doc.id}_{datetime.now().timestamp()}",
                user_data={
                    'email': user_data.get('email'),
                    'full_name': user_data.get('full_name'),
                    'account_number': user_data.get('account_number'),
                    'account_balance': user_data.get('account_balance', 0.0)
                },
                message="Login successful"
            )
        else:
            return AuthResponse(
                success=False,
                message="Invalid email or password"
            )
            
    except Exception as e:
        logger.error(f"Login failed: {str(e)}")
        return AuthResponse(
            success=False,
            message="Login failed due to server error"
        )

@app.post("/auth/register", response_model=AuthResponse, summary="User registration")
async def register_user(request: UserRegistration) -> AuthResponse:
    """
    Register a new user
    
    - **email**: User's email address
    - **password**: User's password
    - **full_name**: User's full name
    - **phone**: User's phone number (optional)
    - **date_of_birth**: User's date of birth (optional)
    """
    try:
        db = get_firestore_db()
        
        # Check if user already exists
        users_ref = db.collection('users')
        existing_query = users_ref.where('email', '==', request.email).limit(1)
        existing_docs = existing_query.get()
        
        if existing_docs:
            return AuthResponse(
                success=False,
                message="User with this email already exists"
            )
        
        # Generate account number
        import random
        account_number = f"ACC{random.randint(100000000, 999999999)}"
        
        # Create new user
        user_data = {
            'email': request.email,
            'password': request.password,  # In production, hash this!
            'full_name': request.full_name,
            'phone': request.phone,
            'date_of_birth': request.date_of_birth,
            'account_number': account_number,
            'account_balance': 1000.0,  # Starting balance
            'created_at': datetime.now().isoformat(),
            'last_login': datetime.now().isoformat()
        }
        
        # Add user to Firestore
        doc_ref = users_ref.add(user_data)
        user_id = doc_ref[1].id
        
        return AuthResponse(
            success=True,
            user_id=user_id,
            access_token=f"token_{user_id}_{datetime.now().timestamp()}",
            user_data={
                'email': user_data.get('email'),
                'full_name': user_data.get('full_name'),
                'account_number': user_data.get('account_number'),
                'account_balance': user_data.get('account_balance')
            },
            message="Registration successful"
        )
        
    except Exception as e:
        logger.error(f"Registration failed: {str(e)}")
        return AuthResponse(
            success=False,
            message="Registration failed due to server error"
        )

@app.get("/auth/profile/{user_id}", response_model=UserProfile, summary="Get user profile")
async def get_user_profile(user_id: str) -> UserProfile:
    """
    Get user profile information
    
    - **user_id**: User's unique ID
    """
    try:
        db = get_firestore_db()
        
        user_doc = db.collection('users').document(user_id).get()
        
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_doc.to_dict()
        
        return UserProfile(
            user_id=user_id,
            email=user_data.get('email'),
            full_name=user_data.get('full_name'),
            phone=user_data.get('phone'),
            date_of_birth=user_data.get('date_of_birth'),
            account_balance=user_data.get('account_balance', 0.0),
            account_number=user_data.get('account_number'),
            created_at=user_data.get('created_at'),
            last_login=user_data.get('last_login')
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user profile: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve user profile")

# Test endpoints for development
@app.post("/test/query", summary="Test query processing")
async def test_query(
    query_text: str,
    user_id: str = "test_user",
    system: MultiAgentSystem = Depends(get_multi_agent_system)
) -> Dict[str, Any]:
    """
    Simple test endpoint for query processing
    
    - **query_text**: The query to test
    - **user_id**: User ID for testing (defaults to 'test_user')
    """
    try:
        request = QueryRequest(
            user_id=user_id,
            query_text=query_text
        )
        
        response = await process_query(request, system)
        
        return {
            "query": query_text,
            "response": response.dict(),
            "test_status": "success"
        }
        
    except Exception as e:
        return {
            "query": query_text,
            "error": str(e),
            "test_status": "failed"
        }

if __name__ == "__main__":
    import uvicorn
    
    # For development
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
