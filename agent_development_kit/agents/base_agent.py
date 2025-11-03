from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from datetime import datetime
import json
import logging
from dataclasses import dataclass

@dataclass
class AgentResponse:
    """Standard response format for all agents"""
    agent_name: str
    response_text: str
    confidence: float
    action_taken: Optional[str] = None
    data: Optional[Dict[str, Any]] = None
    timestamp: str = None
    
    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'agent_name': self.agent_name,
            'response_text': self.response_text,
            'confidence': self.confidence,
            'action_taken': self.action_taken,
            'data': self.data,
            'timestamp': self.timestamp
        }

@dataclass
class UserQuery:
    """User query structure"""
    user_id: str
    query_text: str
    intent: Optional[str] = None
    entities: Optional[Dict[str, Any]] = None
    context: Optional[Dict[str, Any]] = None
    timestamp: str = None
    
    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()

class BaseAgent(ABC):
    """Base class for all banking agents"""
    
    def __init__(self, agent_name: str, firebase_db):
        self.agent_name = agent_name
        self.db = firebase_db
        self.logger = self._setup_logger()
        self.confidence_threshold = 0.7
        
    def _setup_logger(self) -> logging.Logger:
        """Setup agent-specific logger"""
        logger = logging.getLogger(f"agent.{self.agent_name}")
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                f'%(asctime)s - {self.agent_name} - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
        
        return logger
    
    @abstractmethod
    async def can_handle(self, query: UserQuery) -> float:
        """
        Determine if this agent can handle the query
        Returns confidence score (0.0 to 1.0)
        """
        pass
    
    @abstractmethod
    async def process_query(self, query: UserQuery) -> AgentResponse:
        """Process the user query and return response"""
        pass
    
    @abstractmethod
    def get_capabilities(self) -> List[str]:
        """Return list of agent capabilities"""
        pass
    
    async def log_interaction(self, query: UserQuery, response: AgentResponse):
        """Log interaction to Firebase"""
        try:
            interaction_data = {
                'user_id': query.user_id,
                'agent_name': self.agent_name,
                'query': query.query_text,
                'response': response.response_text,
                'confidence': response.confidence,
                'timestamp': datetime.now(),
                'action_taken': response.action_taken
            }
            
            # Store in Firebase
            self.db.collection('agent_interactions').add(interaction_data)
            self.logger.info(f"Logged interaction for user {query.user_id}")
            
        except Exception as e:
            self.logger.error(f"Failed to log interaction: {str(e)}")
    
    async def get_user_data(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user data from Firebase"""
        try:
            user_ref = self.db.collection('users').document(user_id)
            user_doc = user_ref.get()
            
            if user_doc.exists:
                return user_doc.to_dict()
            return None
            
        except Exception as e:
            self.logger.error(f"Failed to get user data: {str(e)}")
            return None
    
    def extract_entities(self, query_text: str) -> Dict[str, Any]:
        """Extract entities from query text (basic implementation)"""
        # This is a simple implementation - in production, use NLP libraries
        entities = {}
        
        # Extract amounts
        import re
        amount_pattern = r'[\$₹]?([\d,]+(?:\.\d{2})?)'
        amounts = re.findall(amount_pattern, query_text.lower())
        if amounts:
            entities['amount'] = [float(a.replace(',', '')) for a in amounts]
        
        # Extract account types
        account_types = ['savings', 'current', 'checking', 'credit', 'debit']
        for acc_type in account_types:
            if acc_type in query_text.lower():
                entities['account_type'] = acc_type
                break
        
        return entities
