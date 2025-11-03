from typing import Dict, Any, List, Optional
import re
from datetime import datetime, timedelta
from .base_agent import BaseAgent, AgentResponse, UserQuery

class CardAgent(BaseAgent):
    """Agent for managing card limits, status, and activation"""
    
    def __init__(self, firebase_db):
        super().__init__("CardAgent", firebase_db)
        self.keywords = [
            'card', 'credit card', 'debit card', 'limit', 'activate', 'block', 
            'unblock', 'pin', 'status', 'expired', 'replacement', 'statement',
            'credit limit', 'available limit', 'card details', 'cvv'
        ]
        self.card_types = {
            'credit': {
                'features': ['Credit limit', 'Reward points', 'EMI facility', 'International usage'],
                'charges': {'annual_fee': 500, 'late_payment': 750, 'over_limit': 500}
            },
            'debit': {
                'features': ['ATM withdrawals', 'Online payments', 'POS transactions', 'Account access'],
                'charges': {'annual_fee': 150, 'atm_fee': 20, 'international_fee': 150}
            }
        }
    
    async def can_handle(self, query: UserQuery) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.query_text.lower()
        
        # Check for card-related keywords
        keyword_matches = sum(1 for keyword in self.keywords if keyword in query_lower)
        keyword_score = min(keyword_matches * 0.4, 1.0)
        
        # Check for specific card patterns
        patterns = [
            r'card.*limit',
            r'activate.*card',
            r'block.*card',
            r'credit.*limit',
            r'card.*status',
            r'pin.*change',
            r'card.*expired'
        ]
        
        pattern_score = 0.0
        for pattern in patterns:
            if re.search(pattern, query_lower):
                pattern_score = 0.9
                break
        
        confidence = max(keyword_score, pattern_score)
        
        self.logger.info(f"Card agent confidence: {confidence} for query: {query.query_text[:50]}...")
        return confidence
    
    async def process_query(self, query: UserQuery) -> AgentResponse:
        """Process card-related queries"""
        try:
            query_lower = query.query_text.lower()
            user_data = await self.get_user_data(query.user_id)
            
            # Card limits
            if any(word in query_lower for word in ['limit', 'credit limit', 'available limit']):
                return await self._handle_card_limits(query, user_data)
            
            # Card activation
            elif any(word in query_lower for word in ['activate', 'activation']):
                return await self._handle_card_activation(query, user_data)
            
            # Card blocking/unblocking
            elif any(word in query_lower for word in ['block', 'unblock', 'disable', 'enable']):
                return await self._handle_card_blocking(query, user_data)
            
            # Card status
            elif any(word in query_lower for word in ['status', 'active', 'blocked', 'expired']):
                return await self._handle_card_status(query, user_data)
            
            # PIN related
            elif any(word in query_lower for word in ['pin', 'password', 'change pin']):
                return await self._handle_pin_services(query, user_data)
            
            # Card replacement
            elif any(word in query_lower for word in ['replace', 'replacement', 'new card', 'lost']):
                return await self._handle_card_replacement(query, user_data)
            
            # Card statement
            elif any(word in query_lower for word in ['statement', 'bill', 'dues', 'outstanding']):
                return await self._handle_card_statement(query, user_data)
            
            else:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="I can help you with card limits, activation, blocking/unblocking, PIN changes, and card replacement. What do you need assistance with?",
                    confidence=0.7
                )
                
        except Exception as e:
            self.logger.error(f"Error processing card query: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm sorry, I encountered an error while processing your card request. Please try again.",
                confidence=0.1
            )
    
    async def _handle_card_limits(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle card limit inquiries"""
        try:
            if not user_data:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="Please ensure you're logged in to check your card limits.",
                    confidence=0.8
                )
            
            # Get basic user info
            full_name = user_data.get('fullName', 'User')
            account_number = user_data.get('accountNumber', 'N/A')
            
            # Try to get user cards from Firebase (if collection exists)
            try:
                cards_ref = self.db.collection('user_cards').where('userId', '==', query.user_id)
                cards = list(cards_ref.stream())
                
                if cards:
                    # Process actual card data
                    response_text = f"Hi {full_name}! Your Card Limits:\n\n"
                    
                    for doc in cards:
                        card_data = doc.to_dict()
                        card_type = card_data.get('card_type', 'Unknown')
                        card_number_masked = card_data.get('card_number_masked', 'XXXX-XXXX-XXXX-XXXX')
                        
                        if card_type.lower() == 'credit':
                            total_limit = card_data.get('credit_limit', 0)
                            used_limit = card_data.get('used_limit', 0)
                            available_limit = total_limit - used_limit
                            
                            response_text += f"💳 Credit Card ({card_number_masked}):\n"
                            response_text += f"   Total Limit: ₹{total_limit:,.2f}\n"
                            response_text += f"   Used: ₹{used_limit:,.2f}\n"
                            response_text += f"   Available: ₹{available_limit:,.2f}\n\n"
                            
                        elif card_type.lower() == 'debit':
                            daily_limit = card_data.get('daily_withdrawal_limit', 50000)
                            daily_used = card_data.get('daily_used', 0)
                            daily_available = daily_limit - daily_used
                            
                            response_text += f"💳 Debit Card ({card_number_masked}):\n"
                            response_text += f"   Daily Withdrawal Limit: ₹{daily_limit:,.2f}\n"
                            response_text += f"   Used Today: ₹{daily_used:,.2f}\n"
                            response_text += f"   Available Today: ₹{daily_available:,.2f}\n\n"
                    
                    return AgentResponse(
                        agent_name=self.agent_name,
                        response_text=response_text,
                        confidence=0.95,
                        action_taken="card_limits_retrieved",
                        data={"cards_found": len(cards)}
                    )
                else:
                    # No cards found, provide general information
                    response_text = f"Hi {full_name}! I don't see any active cards linked to your account ({account_number}).\n\n"
                    response_text += f"📋 **Standard Card Limits:**\n\n"
                    response_text += f"💳 **Debit Card:**\n"
                    response_text += f"   • Daily ATM withdrawal: ₹50,000\n"
                    response_text += f"   • Daily POS transactions: ₹2,00,000\n"
                    response_text += f"   • Online transactions: ₹1,00,000\n\n"
                    response_text += f"💳 **Credit Card:**\n"
                    response_text += f"   • Credit limit varies based on income\n"
                    response_text += f"   • Typically 3-4 times monthly salary\n\n"
                    response_text += f"💡 **To get/activate cards:**\n"
                    response_text += f"Visit any Samsung Prism branch or apply online.\n"
                    response_text += f"Need help with card application?"
                    
                    return AgentResponse(
                        agent_name=self.agent_name,
                        response_text=response_text,
                        confidence=0.85,
                        action_taken="general_card_info",
                        data={"account_number": account_number}
                    )
                    
            except Exception as e:
                # If cards collection doesn't exist or query fails, provide general info
                response_text = f"Hi {full_name}! Here's general information about card limits:\n\n"
                response_text += f"📋 **Standard Samsung Prism Card Limits:**\n\n"
                response_text += f"💳 **Debit Card Limits:**\n"
                response_text += f"   • Daily ATM withdrawal: ₹50,000\n"
                response_text += f"   • Daily POS transactions: ₹2,00,000\n"
                response_text += f"   • Online transactions: ₹1,00,000\n\n"
                response_text += f"💳 **Credit Card Limits:**\n"
                response_text += f"   • Varies based on income and credit score\n"
                response_text += f"   • Typically 3-4 times monthly salary\n"
                response_text += f"   • Can be increased based on usage\n\n"
                response_text += f"💡 **For specific limits:**\n"
                response_text += f"Check the mobile app, visit branch, or call customer care.\n"
                response_text += f"Account: {account_number}"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.8,
                    action_taken="general_limit_info",
                    data={"account_number": account_number}
                )
            
            return AgentResponse(
                agent_name=self.agent_name,
                response_text=response_text,
                confidence=0.9,
                action_taken="card_limits",
                data={"cards": card_list}
            )
            
        except Exception as e:
            self.logger.error(f"Error handling card limits: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm having trouble retrieving your card limit information. Please try again later.",
                confidence=0.5
            )
    
    async def _handle_card_activation(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle card activation requests"""
        response_text = "Card Activation Process:\n\n"
        response_text += "For Credit Cards:\n"
        response_text += "1. 📞 Call our activation helpline: 1800-XXX-XXXX\n"
        response_text += "2. 💻 Use the mobile app: Go to 'Cards' → 'Activate Card'\n"
        response_text += "3. 🏧 Visit any ATM with your new card and PIN\n\n"
        
        response_text += "For Debit Cards:\n"
        response_text += "1. 🏧 Visit any bank ATM\n"
        response_text += "2. Insert card and enter the PIN received\n"
        response_text += "3. Complete any transaction (balance inquiry is enough)\n\n"
        
        response_text += "Required Information:\n"
        response_text += "• Card number (last 4 digits)\n"
        response_text += "• Date of birth\n"
        response_text += "• Mobile number registered with bank\n\n"
        
        response_text += "Need help with activation? I can guide you through the mobile app process."
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken="activation_guidance"
        )
    
    async def _handle_card_blocking(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle card blocking/unblocking requests"""
        query_lower = query.query_text.lower()
        
        if 'block' in query_lower or 'disable' in query_lower:
            response_text = "🚫 Card Blocking Options:\n\n"
            response_text += "Immediate Actions:\n"
            response_text += "1. 📱 Mobile App: Go to 'Cards' → 'Block Card'\n"
            response_text += "2. 📞 24/7 Helpline: 1800-XXX-XXXX\n"
            response_text += "3. 💬 SMS: Send 'BLOCK <last 4 digits>' to 56767\n\n"
            
            response_text += "⚠️ Important:\n"
            response_text += "• Block immediately if card is lost/stolen\n"
            response_text += "• You won't be liable for unauthorized transactions after blocking\n"
            response_text += "• Card can be unblocked later if found\n\n"
            
            response_text += "Would you like me to help you block a specific card?"
            
            action = "blocking_guidance"
            
        else:  # unblock
            response_text = "✅ Card Unblocking Process:\n\n"
            response_text += "Methods:\n"
            response_text += "1. 📱 Mobile App: 'Cards' → 'Manage Card' → 'Unblock'\n"
            response_text += "2. 📞 Customer Care: 1800-XXX-XXXX\n"
            response_text += "3. 🏦 Visit nearest branch with ID proof\n\n"
            
            response_text += "Required for verification:\n"
            response_text += "• Account number\n"
            response_text += "• Date of birth\n"
            response_text += "• Last transaction details\n"
            response_text += "• Reason for unblocking\n\n"
            
            response_text += "Note: Unblocking typically takes 2-4 hours to process."
            
            action = "unblocking_guidance"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken=action
        )
    
    async def _handle_card_status(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle card status inquiries"""
        try:
            # Get user cards status
            cards_ref = self.db.collection('user_cards').where('user_id', '==', query.user_id)
            cards = cards_ref.stream()
            
            card_list = []
            for doc in cards:
                card_data = doc.to_dict()
                card_list.append(card_data)
            
            if not card_list:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="No cards found associated with your account. Please contact customer support for assistance.",
                    confidence=0.8
                )
            
            response_text = "Your Card Status:\n\n"
            
            for card in card_list:
                card_type = card.get('card_type', 'Unknown')
                card_number_masked = card.get('card_number_masked', 'XXXX-XXXX-XXXX-XXXX')
                status = card.get('status', 'Unknown')
                expiry_date = card.get('expiry_date', 'Unknown')
                
                # Status emoji
                status_emoji = "✅" if status.lower() == 'active' else "❌" if status.lower() == 'blocked' else "⚠️"
                
                response_text += f"{status_emoji} {card_type.title()} Card ({card_number_masked}):\n"
                response_text += f"   Status: {status.title()}\n"
                response_text += f"   Expiry: {expiry_date}\n"
                
                # Additional info based on status
                if status.lower() == 'blocked':
                    response_text += f"   🚫 Blocked on: {card.get('blocked_date', 'Unknown')}\n"
                    response_text += f"   📝 Reason: {card.get('block_reason', 'Not specified')}\n"
                elif status.lower() == 'expired':
                    response_text += f"   ⏰ Expired on: {expiry_date}\n"
                    response_text += f"   📮 Replacement card status: {card.get('replacement_status', 'Not initiated')}\n"
                
                response_text += "\n"
            
            return AgentResponse(
                agent_name=self.agent_name,
                response_text=response_text,
                confidence=0.9,
                action_taken="card_status",
                data={"cards": card_list}
            )
            
        except Exception as e:
            self.logger.error(f"Error checking card status: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm having trouble retrieving your card status. Please try again later.",
                confidence=0.5
            )
    
    async def _handle_pin_services(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle PIN-related services"""
        query_lower = query.query_text.lower()
        
        if 'change' in query_lower or 'reset' in query_lower:
            response_text = "🔐 PIN Change/Reset Options:\n\n"
            response_text += "ATM Method:\n"
            response_text += "1. Insert your card at any bank ATM\n"
            response_text += "2. Select 'PIN Change' option\n"
            response_text += "3. Enter current PIN\n"
            response_text += "4. Enter new 4-digit PIN twice\n"
            response_text += "5. Confirm the change\n\n"
            
            response_text += "Mobile App Method:\n"
            response_text += "1. Login to mobile app\n"
            response_text += "2. Go to 'Cards' → 'Manage PIN'\n"
            response_text += "3. Select your card\n"
            response_text += "4. Verify with OTP\n"
            response_text += "5. Set new PIN\n\n"
            
            response_text += "Forgot PIN?\n"
            response_text += "• Call customer care: 1800-XXX-XXXX\n"
            response_text += "• Visit branch with ID proof\n"
            response_text += "• Use 'Forgot PIN' option in mobile app"
            
        else:
            response_text = "🔐 PIN Services Available:\n\n"
            response_text += "• Change PIN at ATM or mobile app\n"
            response_text += "• Reset PIN if forgotten\n"
            response_text += "• Generate PIN for new cards\n"
            response_text += "• Unlock PIN after 3 wrong attempts\n\n"
            response_text += "What specific PIN service do you need help with?"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken="pin_services"
        )
    
    async def _handle_card_replacement(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle card replacement requests"""
        response_text = "💳 Card Replacement Process:\n\n"
        response_text += "Reasons for Replacement:\n"
        response_text += "• Lost or stolen card\n"
        response_text += "• Damaged/worn out card\n"
        response_text += "• Expired card\n"
        response_text += "• Upgrade to new card type\n\n"
        
        response_text += "How to Request:\n"
        response_text += "1. 📱 Mobile App: 'Cards' → 'Request Replacement'\n"
        response_text += "2. 📞 Customer Care: 1800-XXX-XXXX\n"
        response_text += "3. 🏦 Visit any branch\n"
        response_text += "4. 💻 Internet Banking: 'Card Services'\n\n"
        
        response_text += "Processing Time:\n"
        response_text += "• Regular delivery: 7-10 working days\n"
        response_text += "• Express delivery: 2-3 working days (extra charges apply)\n\n"
        
        response_text += "Charges:\n"
        response_text += "• Debit Card: ₹150\n"
        response_text += "• Credit Card: ₹500\n"
        response_text += "• No charge for expired card replacement\n\n"
        
        response_text += "⚠️ Important: Old card will be automatically blocked once replacement is issued."
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken="replacement_guidance"
        )
    
    async def _handle_card_statement(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle card statement requests"""
        try:
            # Get credit card statements
            statements_ref = self.db.collection('card_statements').where('user_id', '==', query.user_id)
            statements_query = statements_ref.order_by('statement_date', direction='DESCENDING').limit(3)
            statements = statements_query.stream()
            
            statement_list = []
            for doc in statements:
                stmt_data = doc.to_dict()
                statement_list.append(stmt_data)
            
            if statement_list:
                response_text = "📄 Recent Credit Card Statements:\n\n"
                
                for i, stmt in enumerate(statement_list, 1):
                    card_number = stmt.get('card_number_masked', 'XXXX-XXXX-XXXX-XXXX')
                    statement_date = stmt.get('statement_date', 'Unknown')
                    total_amount = stmt.get('total_amount', 0)
                    minimum_due = stmt.get('minimum_due', 0)
                    due_date = stmt.get('due_date', 'Unknown')
                    payment_status = stmt.get('payment_status', 'Pending')
                    
                    response_text += f"{i}. Card ending {card_number[-4:]} - {statement_date}\n"
                    response_text += f"   Total Amount: ₹{total_amount:,.2f}\n"
                    response_text += f"   Minimum Due: ₹{minimum_due:,.2f}\n"
                    response_text += f"   Due Date: {due_date}\n"
                    response_text += f"   Status: {payment_status}\n\n"
                
                response_text += "💡 Tips:\n"
                response_text += "• Pay full amount to avoid interest charges\n"
                response_text += "• Set up auto-pay for timely payments\n"
                response_text += "• Download detailed statement from mobile app"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.9,
                    action_taken="statement_info",
                    data={"statements": statement_list}
                )
            else:
                response_text = "📄 Card Statement Information:\n\n"
                response_text += "No recent statements found. This could be because:\n"
                response_text += "• You have a debit card (no monthly statements)\n"
                response_text += "• New credit card with no transactions yet\n"
                response_text += "• Statements not generated yet\n\n"
                
                response_text += "To access statements:\n"
                response_text += "• Mobile App: 'Cards' → 'Statements'\n"
                response_text += "• Internet Banking: 'Card Services'\n"
                response_text += "• Email: Statements sent monthly to registered email"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.8
                )
                
        except Exception as e:
            self.logger.error(f"Error handling card statement: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm having trouble retrieving your card statements. Please try again later or check the mobile app.",
                confidence=0.5
            )
    
    def get_capabilities(self) -> List[str]:
        """Return list of agent capabilities"""
        return [
            "Check card limits (credit/debit)",
            "Card activation guidance",
            "Block/unblock cards",
            "Check card status",
            "PIN change/reset services",
            "Card replacement process",
            "Credit card statements",
            "Card features and charges information"
        ]
