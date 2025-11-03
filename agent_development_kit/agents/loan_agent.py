from typing import Dict, Any, List, Optional
import re
from datetime import datetime, timedelta
from .base_agent import BaseAgent, AgentResponse, UserQuery

class LoanAgent(BaseAgent):
    """Agent for handling loan eligibility and EMI queries"""
    
    def __init__(self, firebase_db):
        super().__init__("LoanAgent", firebase_db)
        self.keywords = [
            'loan', 'emi', 'eligibility', 'personal loan', 'home loan', 
            'car loan', 'education loan', 'interest rate', 'installment',
            'borrow', 'credit', 'amount eligible', 'loan status', 'repayment'
        ]
        self.loan_types = {
            'personal': {'min_salary': 25000, 'max_amount': 1000000, 'interest_rate': 10.5},
            'home': {'min_salary': 50000, 'max_amount': 10000000, 'interest_rate': 8.5},
            'car': {'min_salary': 30000, 'max_amount': 2000000, 'interest_rate': 9.0},
            'education': {'min_salary': 20000, 'max_amount': 1500000, 'interest_rate': 8.0}
        }
    
    async def can_handle(self, query: UserQuery) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.query_text.lower()
        
        # Check for loan-related keywords
        keyword_matches = sum(1 for keyword in self.keywords if keyword in query_lower)
        keyword_score = min(keyword_matches * 0.4, 1.0)
        
        # Check for specific loan patterns
        patterns = [
            r'loan.*eligible',
            r'emi.*calculator',
            r'interest.*rate',
            r'borrow.*money',
            r'personal.*loan',
            r'home.*loan',
            r'car.*loan'
        ]
        
        pattern_score = 0.0
        for pattern in patterns:
            if re.search(pattern, query_lower):
                pattern_score = 0.9
                break
        
        confidence = max(keyword_score, pattern_score)
        
        self.logger.info(f"Loan agent confidence: {confidence} for query: {query.query_text[:50]}...")
        return confidence
    
    async def process_query(self, query: UserQuery) -> AgentResponse:
        """Process loan-related queries"""
        try:
            query_lower = query.query_text.lower()
            user_data = await self.get_user_data(query.user_id)
            
            # Loan eligibility check
            if any(word in query_lower for word in ['eligible', 'eligibility', 'qualify']):
                return await self._handle_eligibility_check(query, user_data)
            
            # EMI calculation
            elif any(word in query_lower for word in ['emi', 'installment', 'monthly payment']):
                return await self._handle_emi_calculation(query, user_data)
            
            # Interest rates
            elif any(word in query_lower for word in ['interest', 'rate', 'charges']):
                return await self._handle_interest_rates(query, user_data)
            
            # Loan status
            elif any(word in query_lower for word in ['status', 'application', 'approved']):
                return await self._handle_loan_status(query, user_data)
            
            # Loan types information
            elif any(loan_type in query_lower for loan_type in self.loan_types.keys()):
                return await self._handle_loan_info(query, user_data)
            
            else:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="I can help you with loan eligibility, EMI calculations, interest rates, and loan applications. What would you like to know?",
                    confidence=0.7
                )
                
        except Exception as e:
            self.logger.error(f"Error processing loan query: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm sorry, I encountered an error while processing your loan request. Please try again.",
                confidence=0.1
            )
    
    async def _handle_eligibility_check(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle loan eligibility checks"""
        try:
            if not user_data:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="To check your loan eligibility, I need your profile information. Please ensure you're logged in.",
                    confidence=0.8
                )
            
            # Get basic user info (Flutter app stores limited data)
            full_name = user_data.get('fullName', 'User')
            account_balance = user_data.get('balance', 0)
            
            # Since detailed financial info isn't available, provide general eligibility info
            loan_type = self._extract_loan_type(query.query_text)
            
            if loan_type and loan_type in self.loan_types:
                loan_info = self.loan_types[loan_type]
                
                response_text = f"Hi {full_name}! Here's information about {loan_type.title()} Loan eligibility:\n\n"
                response_text += f"📋 **{loan_type.title()} Loan Details:**\n"
                response_text += f"• Minimum monthly salary: ₹{loan_info['min_salary']:,}\n"
                response_text += f"• Maximum loan amount: ₹{loan_info['max_amount']:,}\n"
                response_text += f"• Interest rate: {loan_info['interest_rate']}% per annum\n\n"
                response_text += f"� **General Eligibility Criteria:**\n"
                response_text += f"• Age: 21-60 years\n"
                response_text += f"• Minimum income as mentioned above\n"
                response_text += f"• Good credit history\n"
                response_text += f"• Stable employment (6+ months)\n\n"
                response_text += f"💡 **Next Steps:**\n"
                response_text += f"Visit any Samsung Prism branch with required documents for detailed eligibility assessment.\n"
                response_text += f"Would you like me to calculate EMI for a specific amount?"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.9,
                    action_taken="loan_info_provided",
                    data={"loan_type": loan_type, "loan_details": loan_info}
                )
            else:
                # General loan information
                response_text = f"Hi {full_name}! Here are our available loan options:\n\n"
                
                for loan_name, loan_info in self.loan_types.items():
                    response_text += f"🏦 **{loan_name.title()} Loan:**\n"
                    response_text += f"   • Amount: Up to ₹{loan_info['max_amount']:,}\n"
                    response_text += f"   • Rate: {loan_info['interest_rate']}% per annum\n"
                    response_text += f"   • Min. salary: ₹{loan_info['min_salary']:,}\n\n"
                
                response_text += f"💡 **To check specific eligibility:**\n"
                response_text += f"Visit our branch or call customer care for personalized assessment.\n"
                response_text += f"Ask me about specific loan types like 'personal loan' or 'home loan'!"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.85,
                    action_taken="general_loan_info",
                    data={"available_loans": self.loan_types}
                )
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.85,
                    action_taken="general_eligibility"
                )
                
        except Exception as e:
            self.logger.error(f"Error in eligibility check: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm having trouble checking your loan eligibility. Please try again or contact customer support.",
                confidence=0.5
            )
    
    async def _handle_emi_calculation(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle EMI calculation requests"""
        entities = self.extract_entities(query.query_text)
        
        # Extract loan details from query
        loan_amount = None
        if 'amount' in entities and entities['amount']:
            loan_amount = entities['amount'][0]
        
        loan_type = self._extract_loan_type(query.query_text)
        tenure_years = self._extract_tenure(query.query_text)
        
        if loan_amount and loan_type in self.loan_types:
            interest_rate = self.loan_types[loan_type]['interest_rate']
            
            if not tenure_years:
                tenure_years = 5  # Default tenure
            
            emi = self._calculate_emi(loan_amount, interest_rate, tenure_years)
            total_amount = emi * (tenure_years * 12)
            total_interest = total_amount - loan_amount
            
            response_text = f"EMI Calculation for {loan_type.title()} Loan:\n\n"
            response_text += f"💰 Loan Amount: ₹{loan_amount:,.2f}\n"
            response_text += f"📅 Tenure: {tenure_years} years\n"
            response_text += f"📊 Interest Rate: {interest_rate}% per annum\n\n"
            response_text += f"📋 EMI Details:\n"
            response_text += f"• Monthly EMI: ₹{emi:,.2f}\n"
            response_text += f"• Total Amount: ₹{total_amount:,.2f}\n"
            response_text += f"• Total Interest: ₹{total_interest:,.2f}\n"
            
            return AgentResponse(
                agent_name=self.agent_name,
                response_text=response_text,
                confidence=0.95,
                action_taken="emi_calculation",
                data={
                    "loan_amount": loan_amount,
                    "emi": emi,
                    "total_amount": total_amount,
                    "total_interest": total_interest,
                    "tenure_years": tenure_years
                }
            )
        else:
            response_text = "To calculate EMI, I need:\n"
            response_text += "• Loan amount\n• Loan type (personal/home/car/education)\n• Tenure (optional, default 5 years)\n\n"
            response_text += "Example: 'Calculate EMI for personal loan of ₹5,00,000 for 3 years'"
            
            return AgentResponse(
                agent_name=self.agent_name,
                response_text=response_text,
                confidence=0.7
            )
    
    async def _handle_interest_rates(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle interest rate inquiries"""
        loan_type = self._extract_loan_type(query.query_text)
        
        if loan_type and loan_type in self.loan_types:
            rate = self.loan_types[loan_type]['interest_rate']
            response_text = f"Current interest rate for {loan_type.title()} Loan: {rate}% per annum\n\n"
            response_text += "Note: Interest rates may vary based on:\n"
            response_text += "• Credit score\n• Income level\n• Loan amount\n• Employment type\n• Existing relationship with bank"
        else:
            response_text = "Current Interest Rates:\n\n"
            for loan, details in self.loan_types.items():
                response_text += f"• {loan.title()} Loan: {details['interest_rate']}% per annum\n"
            response_text += "\n*Rates subject to change and eligibility criteria"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken="interest_rates"
        )
    
    async def _handle_loan_status(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle loan status inquiries"""
        try:
            # Check for existing loan applications
            loans_ref = self.db.collection('loan_applications').where('user_id', '==', query.user_id)
            loans = loans_ref.stream()
            
            loan_applications = []
            for doc in loans:
                loan_data = doc.to_dict()
                loan_applications.append(loan_data)
            
            if loan_applications:
                response_text = "Your Loan Applications:\n\n"
                for i, loan in enumerate(loan_applications, 1):
                    status = loan.get('status', 'Unknown')
                    loan_type = loan.get('loan_type', 'Unknown')
                    amount = loan.get('amount', 0)
                    application_date = loan.get('application_date', 'Unknown')
                    
                    response_text += f"{i}. {loan_type.title()} Loan\n"
                    response_text += f"   Amount: ₹{amount:,.2f}\n"
                    response_text += f"   Status: {status}\n"
                    response_text += f"   Applied: {application_date}\n\n"
                
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text=response_text,
                    confidence=0.9,
                    action_taken="loan_status",
                    data={"applications": loan_applications}
                )
            else:
                return AgentResponse(
                    agent_name=self.agent_name,
                    response_text="You don't have any loan applications on record. Would you like to check your loan eligibility?",
                    confidence=0.8
                )
                
        except Exception as e:
            self.logger.error(f"Error checking loan status: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm having trouble retrieving your loan status. Please try again or contact customer support.",
                confidence=0.5
            )
    
    async def _handle_loan_info(self, query: UserQuery, user_data: Dict[str, Any]) -> AgentResponse:
        """Handle general loan information requests"""
        loan_type = self._extract_loan_type(query.query_text)
        
        if loan_type in self.loan_types:
            details = self.loan_types[loan_type]
            response_text = f"{loan_type.title()} Loan Information:\n\n"
            response_text += f"💰 Maximum Amount: ₹{details['max_amount']:,.2f}\n"
            response_text += f"📊 Interest Rate: {details['interest_rate']}% per annum\n"
            response_text += f"💵 Minimum Salary: ₹{details['min_salary']:,.2f}\n\n"
            
            if loan_type == 'personal':
                response_text += "Features:\n• No collateral required\n• Quick approval\n• Flexible tenure up to 5 years"
            elif loan_type == 'home':
                response_text += "Features:\n• Property as collateral\n• Longest tenure up to 30 years\n• Tax benefits available"
            elif loan_type == 'car':
                response_text += "Features:\n• Vehicle as collateral\n• Quick processing\n• Competitive rates"
            elif loan_type == 'education':
                response_text += "Features:\n• For higher education\n• Moratorium period available\n• Special rates for students"
            
            return AgentResponse(
                agent_name=self.agent_name,
                response_text=response_text,
                confidence=0.9,
                action_taken="loan_info"
            )
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text="I can provide information about Personal, Home, Car, and Education loans. Which one would you like to know about?",
            confidence=0.7
        )
    
    def _extract_loan_type(self, query_text: str) -> Optional[str]:
        """Extract loan type from query"""
        query_lower = query_text.lower()
        
        if 'personal' in query_lower:
            return 'personal'
        elif 'home' in query_lower or 'house' in query_lower:
            return 'home'
        elif 'car' in query_lower or 'auto' in query_lower or 'vehicle' in query_lower:
            return 'car'
        elif 'education' in query_lower or 'student' in query_lower:
            return 'education'
        
        return None
    
    def _extract_tenure(self, query_text: str) -> Optional[int]:
        """Extract loan tenure from query"""
        import re
        
        # Look for patterns like "5 years", "3 year", "24 months"
        year_match = re.search(r'(\d+)\s*years?', query_text.lower())
        if year_match:
            return int(year_match.group(1))
        
        month_match = re.search(r'(\d+)\s*months?', query_text.lower())
        if month_match:
            return int(month_match.group(1)) // 12
        
        return None
    
    def _calculate_eligibility(self, salary: float, employment_type: str, credit_score: int, loan_type: str) -> Dict[str, Any]:
        """Calculate loan eligibility"""
        criteria = self.loan_types[loan_type]
        eligible = True
        reasons = []
        
        # Check salary
        if salary < criteria['min_salary']:
            eligible = False
            reasons.append(f"Minimum salary requirement: ₹{criteria['min_salary']:,.2f}")
        
        # Check credit score
        if credit_score < 650:
            eligible = False
            reasons.append("Credit score below minimum requirement (650)")
        
        # Calculate maximum amount (60x salary or loan limit, whichever is lower)
        max_amount = min(salary * 60, criteria['max_amount'])
        
        return {
            'eligible': eligible,
            'max_amount': max_amount,
            'interest_rate': criteria['interest_rate'],
            'reasons': reasons
        }
    
    def _calculate_emi(self, principal: float, annual_rate: float, tenure_years: int) -> float:
        """Calculate EMI using standard formula"""
        monthly_rate = annual_rate / (12 * 100)
        total_months = tenure_years * 12
        
        if monthly_rate == 0:
            return principal / total_months
        
        emi = principal * monthly_rate * (1 + monthly_rate) ** total_months / ((1 + monthly_rate) ** total_months - 1)
        return round(emi, 2)
    
    def get_capabilities(self) -> List[str]:
        """Return list of agent capabilities"""
        return [
            "Check loan eligibility",
            "Calculate EMI",
            "Provide interest rates",
            "Check loan application status",
            "Personal loan information",
            "Home loan information",
            "Car loan information",
            "Education loan information"
        ]
