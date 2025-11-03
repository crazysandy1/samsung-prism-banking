from typing import Dict, Any, List, Optional, Tuple
import asyncio
import logging
from datetime import datetime

from .base_agent import BaseAgent, AgentResponse, UserQuery
from .account_agent import AccountAgent
from .loan_agent import LoanAgent
from .card_agent import CardAgent
from .support_agent import SupportAgent

class MultiAgentSystem:
    """Manages multiple banking agents and routes queries to appropriate agents"""
    
    def __init__(self, firebase_db):
        self.db = firebase_db
        self.agents: Dict[str, BaseAgent] = {}
        self.logger = self._setup_logger()
        self.confidence_threshold = 0.6
        
        # Initialize all agents
        self._initialize_agents()
        
    def _setup_logger(self) -> logging.Logger:
        """Setup system logger"""
        logger = logging.getLogger("multi_agent_system")
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - MultiAgentSystem - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
        
        return logger
    
    def _initialize_agents(self):
        """Initialize all banking agents"""
        try:
            self.agents = {
                'account': AccountAgent(self.db),
                'loan': LoanAgent(self.db),
                'card': CardAgent(self.db),
                'support': SupportAgent(self.db)
            }
            
            self.logger.info(f"Initialized {len(self.agents)} agents successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize agents: {str(e)}")
            raise
    
    async def process_query(self, query: UserQuery) -> AgentResponse:
        """Process user query through the multi-agent system"""
        try:
            self.logger.info(f"Processing query from user {query.user_id}: {query.query_text[:100]}...")
            
            # Step 1: Get confidence scores from all agents
            agent_scores = await self._get_agent_confidence_scores(query)
            
            # Step 2: Select the best agent
            selected_agent, confidence = self._select_best_agent(agent_scores)
            
            if not selected_agent:
                return await self._handle_no_agent_selected(query)
            
            # Step 3: Process query with selected agent
            response = await selected_agent.process_query(query)
            
            # Step 4: Log the interaction
            await self._log_interaction(query, response, agent_scores)
            
            # Step 5: Enhance response with system metadata
            response = self._enhance_response(response, confidence, selected_agent.agent_name)
            
            self.logger.info(f"Query processed by {selected_agent.agent_name} with confidence {confidence}")
            
            return response
            
        except Exception as e:
            self.logger.error(f"Error processing query: {str(e)}")
            return AgentResponse(
                agent_name="SystemError",
                response_text="I'm sorry, I encountered a system error while processing your request. Please try again or contact customer support.",
                confidence=0.1
            )
    
    async def _get_agent_confidence_scores(self, query: UserQuery) -> Dict[str, Tuple[BaseAgent, float]]:
        """Get confidence scores from all agents for the query"""
        scores = {}
        
        # Run confidence checks in parallel for better performance
        tasks = []
        agent_names = []
        
        for name, agent in self.agents.items():
            tasks.append(agent.can_handle(query))
            agent_names.append(name)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for i, result in enumerate(results):
            agent_name = agent_names[i]
            agent = self.agents[agent_name]
            
            if isinstance(result, Exception):
                self.logger.error(f"Error getting confidence from {agent_name}: {str(result)}")
                confidence = 0.0
            else:
                confidence = result
            
            scores[agent_name] = (agent, confidence)
        
        return scores
    
    def _select_best_agent(self, agent_scores: Dict[str, Tuple[BaseAgent, float]]) -> Tuple[Optional[BaseAgent], float]:
        """Select the best agent based on confidence scores"""
        # Sort agents by confidence score
        sorted_agents = sorted(agent_scores.items(), key=lambda x: x[1][1], reverse=True)
        
        if not sorted_agents:
            return None, 0.0
        
        best_agent_name, (best_agent, best_confidence) = sorted_agents[0]
        
        # Log confidence scores for debugging
        score_log = ", ".join([f"{name}: {conf:.2f}" for name, (_, conf) in sorted_agents])
        self.logger.info(f"Agent confidence scores: {score_log}")
        
        # Check if confidence meets threshold
        if best_confidence >= self.confidence_threshold:
            return best_agent, best_confidence
        
        # If no agent meets threshold, use support agent as fallback
        support_agent, support_confidence = agent_scores.get('support', (None, 0.0))
        if support_agent:
            self.logger.info(f"No agent met threshold {self.confidence_threshold}, using support agent")
            return support_agent, support_confidence
        
        return None, 0.0
    
    async def _handle_no_agent_selected(self, query: UserQuery) -> AgentResponse:
        """Handle case when no suitable agent is found"""
        response_text = "I'm not sure how to help with that specific request. Here are some things I can assist you with:\n\n"
        
        # List capabilities from all agents
        response_text += "💳 Account Services:\n"
        for capability in self.agents['account'].get_capabilities()[:3]:
            response_text += f"• {capability}\n"
        
        response_text += "\n💰 Loan Services:\n"
        for capability in self.agents['loan'].get_capabilities()[:3]:
            response_text += f"• {capability}\n"
        
        response_text += "\n🔳 Card Services:\n"
        for capability in self.agents['card'].get_capabilities()[:3]:
            response_text += f"• {capability}\n"
        
        response_text += "\n🎯 General Support:\n"
        for capability in self.agents['support'].get_capabilities()[:3]:
            response_text += f"• {capability}\n"
        
        response_text += "\n💬 Please rephrase your question or contact customer care at 1800-XXX-XXXX for direct assistance."
        
        return AgentResponse(
            agent_name="MultiAgentSystem",
            response_text=response_text,
            confidence=0.5
        )
    
    async def _log_interaction(self, query: UserQuery, response: AgentResponse, agent_scores: Dict[str, Tuple[BaseAgent, float]]):
        """Log the interaction to Firebase for analytics"""
        try:
            interaction_data = {
                'user_id': query.user_id,
                'query_text': query.query_text,
                'selected_agent': response.agent_name,
                'response_text': response.response_text,
                'confidence': response.confidence,
                'agent_scores': {name: conf for name, (_, conf) in agent_scores.items()},
                'timestamp': datetime.now(),
                'session_id': query.context.get('session_id') if query.context else None
            }
            
            # Store in Firebase
            self.db.collection('multi_agent_interactions').add(interaction_data)
            
        except Exception as e:
            self.logger.error(f"Failed to log interaction: {str(e)}")
    
    def _enhance_response(self, response: AgentResponse, confidence: float, agent_name: str) -> AgentResponse:
        """Enhance response with system metadata"""
        # Add confidence and routing information
        enhanced_data = response.data or {}
        enhanced_data.update({
            'routing_confidence': confidence,
            'selected_agent': agent_name,
            'system_version': '1.0.0'
        })
        
        # Add helpful suggestions if confidence is low
        if confidence < 0.8 and response.agent_name != "MultiAgentSystem":
            response.response_text += "\n\n💡 If this doesn't answer your question completely, please contact our customer care at 1800-XXX-XXXX for personalized assistance."
        
        response.data = enhanced_data
        return response
    
    def get_system_status(self) -> Dict[str, Any]:
        """Get system status and agent information"""
        status = {
            'system_name': 'Samsung Prism Multi-Agent Banking System',
            'version': '1.0.0',
            'agents_count': len(self.agents),
            'agents': {},
            'confidence_threshold': self.confidence_threshold,
            'timestamp': datetime.now().isoformat()
        }
        
        for name, agent in self.agents.items():
            status['agents'][name] = {
                'agent_name': agent.agent_name,
                'capabilities_count': len(agent.get_capabilities()),
                'capabilities': agent.get_capabilities()
            }
        
        return status
    
    def get_agent_capabilities(self) -> Dict[str, List[str]]:
        """Get capabilities of all agents"""
        capabilities = {}
        for name, agent in self.agents.items():
            capabilities[name] = agent.get_capabilities()
        return capabilities
    
    async def health_check(self) -> Dict[str, Any]:
        """Perform system health check"""
        health_status = {
            'system_healthy': True,
            'agents_status': {},
            'database_connection': False,
            'timestamp': datetime.now().isoformat()
        }
        
        # Check database connection
        try:
            # Try to access a collection
            self.db.collection('health_check').limit(1).get()
            health_status['database_connection'] = True
        except Exception as e:
            health_status['database_connection'] = False
            health_status['database_error'] = str(e)
            health_status['system_healthy'] = False
        
        # Check each agent
        for name, agent in self.agents.items():
            try:
                # Basic agent health check
                agent_healthy = hasattr(agent, 'agent_name') and hasattr(agent, 'get_capabilities')
                health_status['agents_status'][name] = {
                    'healthy': agent_healthy,
                    'agent_name': getattr(agent, 'agent_name', 'Unknown')
                }
                
                if not agent_healthy:
                    health_status['system_healthy'] = False
                    
            except Exception as e:
                health_status['agents_status'][name] = {
                    'healthy': False,
                    'error': str(e)
                }
                health_status['system_healthy'] = False
        
        return health_status
