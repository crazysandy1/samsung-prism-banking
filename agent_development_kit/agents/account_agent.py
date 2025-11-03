from typing import Dict, Any, List, Optional
import re
from datetime import datetime, timedelta
from .base_agent import BaseAgent, AgentResponse, UserQuery

class AccountAgent(BaseAgent):
    """Agent for handling balance inquiries and transactions"""
    
    def __init__(self, firebase_db):
        super().__init__("AccountAgent", firebase_db)
        self.keywords = [
            'balance', 'account', 'transaction', 'transfer', 'send money', 
            'payment', 'deposit', 'withdraw', 'statement', 'history',
            'recent transactions', 'last payment', 'money sent', 'received'
        ]
    
    async def can_handle(self, query: UserQuery) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.query_text.lower()
        
        # Check for account-related keywords
        keyword_matches = sum(1 for keyword in self.keywords if keyword in query_lower)
        keyword_score = min(keyword_matches * 0.3, 1.0)
        
        # Check for specific patterns
        patterns = [
            r'what.*balance',
            r'check.*account',
            r'transfer.*money',
            r'send.*\$',
            r'transaction.*history',
            r'recent.*payment'
        ]
        
        pattern_score = 0.0
        for pattern in patterns:
            if re.search(pattern, query_lower):
                pattern_score = 0.8
                break
        
        confidence = max(keyword_score, pattern_score)
        
        self.logger.info(f"Account agent confidence: {confidence} for query: {query.query_text[:50]}...")
        return confidence
    
    async def process_query(self, query: UserQuery) -> AgentResponse:
        """Process account-related queries"""
        try:
            query_lower = query.query_text.lower()
            user_data = await self.get_user_data(query.user_id)
            
            if not user_data:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="I couldn't find your account information. Please ensure you're logged in.",
                    confidence=0.9
                )
            
            # Balance inquiry
            if any(word in query_lower for word in ['balance', 'account balance']):
                return await self._handle_balance_inquiry(query, user_data)
            
            # Transaction history
            elif any(word in query_lower for word in ['transaction', 'history', 'statement']):
                return await self._handle_transaction_history(query, user_data)
            
            # Money transfer
            elif any(word in query_lower for word in ['transfer', 'send money', 'pay']):
                return await self._handle_transfer_request(query, user_data)
            
            # Recent transactions
            elif any(word in query_lower for word in ['recent', 'last payment', 'latest']):
                return await self._handle_recent_transactions(query, user_data)
            
            else:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="I can help you with balance inquiries, transaction history, and money transfers. What specifically would you like to know?",
                    confidence=0.6
                )
                
        except Exception as e:
            self.logger.error(f"Error processing account query: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm sorry, I encountered an error while processing your request. Please try again.",
                confidence=0.1
            )
    
    async def _handle_balance_inquiry(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle balance inquiry requests"""
        try:
            # Get balance from user data directly (Flutter app stores it in users collection)
            current_balance = user_data.get('balance', 0.0)
            account_number = user_data.get('accountNumber', 'N/A')
            
            if current_balance is not None:
                response_text = f"Your current account balance is ₹{current_balance:,.2f}."
                if account_number != 'N/A':
                    response_text += f" Account: {account_number}"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.95,
                    action_taken="balance_inquiry",
                    data={"balance": current_balance, "account_number": account_number}
                )
            else:
                # Fallback: try to get from user_balances collection if exists
                balance_ref = self.db.collection('user_balances').document(query.user_id)
                balance_doc = balance_ref.get()
                
                if balance_doc.exists:
                    balance_data = balance_doc.to_dict()
                    current_balance = balance_data.get('balance', 0.0)
                    last_updated = balance_data.get('last_updated', 'Unknown')
                    
                    response_text = f"Your current account balance is ₹{current_balance:,.2f}. Last updated: {last_updated}"
                    
                    return AgentResponse(
                        agent_name=self.agent_name,
                        response_text=response_text,
                        confidence=0.95,
                        action_taken="balance_inquiry",
                        data={"balance": current_balance, "last_updated": last_updated}
                    )
                else:
                    return AgentResponse(
                        agent_name=self.agent_name,
                        response_text="I couldn't retrieve your balance information at the moment. Please ensure your account is properly set up.",
                        confidence=0.8
                    )
                
        except Exception as e:
            self.logger.error(f"Error handling balance inquiry: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm having trouble accessing your balance information. Please try again.",
                confidence=0.5
            )
    
    async def _handle_transaction_history(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle transaction history requests"""
        try:
            # Get recent transactions - Flutter app uses 'userId' field (not 'user_id')
            transactions_ref = self.db.collection('transactions').where('userId', '==', query.user_id)
            transactions_query = transactions_ref.order_by('timestamp', direction='DESCENDING').limit(10)
            transactions = transactions_query.stream()
            
            transaction_list = []
            for doc in transactions:
                trans_data = doc.to_dict()
                transaction_list.append({
                    'amount': trans_data.get('amount', 0),
                    'type': trans_data.get('type', 'Unknown'),
                    'description': trans_data.get('description', 'No description'),
                    'timestamp': trans_data.get('timestamp', 'Unknown'),
                    'recipientName': trans_data.get('recipientName', '')
                })
            
            if transaction_list:
                response_text = f"Here are your recent transactions:\n\n"
                for i, trans in enumerate(transaction_list[:5], 1):
                    recipient_info = f" to {trans['recipientName']}" if trans['recipientName'] else ""
                    response_text += f"{i}. {trans['type'].title()}: ₹{trans['amount']:,.2f}{recipient_info} - {trans['description']}\n"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.9,
                    action_taken="transaction_history",
                    data={"transactions": transaction_list}
                )
            else:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="You don't have any recent transactions to display.",
                    confidence=0.8
                )
                
        except Exception as e:
            self.logger.error(f"Error handling transaction history: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm having trouble retrieving your transaction history. Please try again.",
                confidence=0.5
            )
    
    async def _handle_transfer_request(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle money transfer requests"""
        entities = self.extract_entities(query.query_text)
        
        # Extract amount from query
        amount = None
        if 'amount' in entities and entities['amount']:
            amount = entities['amount'][0]
        
        if amount:
            response_text = f"To transfer ₹{amount:,.2f}, please use the 'Send Money' feature in the app. I'll guide you through the process:\n\n"
            response_text += "1. Go to the 'Transfer' section\n"
            response_text += "2. Enter the recipient's details\n"
            response_text += "3. Confirm the amount and transfer\n"
            response_text += "4. Verify with OTP\n\n"
            response_text += "Is there anything specific about transfers you'd like to know?"
        else:
            response_text = "I can help you with money transfers. Please specify the amount you'd like to transfer, or use the 'Send Money' feature in the app for a guided transfer process."
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.85,
            action_taken="transfer_guidance",
            data={"suggested_amount": amount if amount else None}
        )
    
    async def _handle_recent_transactions(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle recent transactions requests"""
        try:
            # Get last 3 transactions - Flutter app uses 'userId' field
            transactions_ref = self.db.collection('transactions').where('userId', '==', query.user_id)
            recent_query = transactions_ref.order_by('timestamp', direction='DESCENDING').limit(3)
            transactions = recent_query.stream()
            
            transaction_list = []
            for doc in transactions:
                trans_data = doc.to_dict()
                transaction_list.append(trans_data)
            
            if transaction_list:
                response_text = "Your most recent transactions:\n\n"
                for i, trans in enumerate(transaction_list, 1):
                    amount = trans.get('amount', 0)
                    trans_type = trans.get('type', 'Transaction')
                    description = trans.get('description', 'No description')
                    recipient_name = trans.get('recipientName', '')
                    recipient_info = f" to {recipient_name}" if recipient_name else ""
                    response_text += f"{i}. {trans_type.title()}: ₹{amount:,.2f}{recipient_info} - {description}\n"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.9,
                    action_taken="recent_transactions",
                    data={"recent_transactions": transaction_list}
                )
            else:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="You don't have any recent transactions.",
                    confidence=0.8
                )
                
        except Exception as e:
            self.logger.error(f"Error handling recent transactions: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm having trouble retrieving your recent transactions. Please try again.",
                confidence=0.5
            )
    
    def get_capabilities(self) -> List[str]:
        """Return list of agent capabilities"""
        return [
            "Check account balance",
            "View transaction history",
            "Get recent transactions",
            "Transfer money guidance",
            "Account statement information",
            "Payment history"
        ]
