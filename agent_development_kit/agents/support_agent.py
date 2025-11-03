from typing import Dict, Any, List, Optional
import re
from datetime import datetime
from .base_agent import BaseAgent, AgentResponse, UserQuery

class SupportAgent(BaseAgent):
    """Agent for general FAQs and non-financial help"""
    
    def __init__(self, firebase_db):
        super().__init__("SupportAgent", firebase_db)
        self.keywords = [
            'help', 'support', 'how to', 'what is', 'where is', 'when', 'why',
            'customer care', 'contact', 'branch', 'atm', 'location', 'hours',
            'complaint', 'feedback', 'problem', 'issue', 'error', 'trouble'
        ]
        self.faq_categories = {
            'general': [
                "How to open an account?",
                "What documents are required?",
                "How to update contact information?",
                "How to download mobile app?",
                "What are the bank timings?"
            ],
            'digital': [
                "How to register for internet banking?",
                "How to reset login password?",
                "How to enable/disable SMS alerts?",
                "How to download bank statements?",
                "How to use mobile banking?"
            ],
            'security': [
                "How to keep account secure?",
                "What to do if card is cloned?",
                "How to report fraud?",
                "How to change mobile number?",
                "What is two-factor authentication?"
            ],
            'services': [
                "How to apply for checkbook?",
                "How to get account certificate?",
                "How to close account?",
                "How to add nominee?",
                "How to get interest certificate?"
            ]
        }
        
        self.contact_info = {
            'customer_care': '1800-XXX-XXXX',
            'email': 'support@samsungprism.com',
            'website': 'www.samsungprism.com',
            'working_hours': 'Monday to Friday: 9:00 AM - 6:00 PM',
            'emergency': '1800-XXX-EMERGENCY'
        }
    
    async def can_handle(self, query: UserQuery) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.query_text.lower()
        
        # Check for support-related keywords
        keyword_matches = sum(1 for keyword in self.keywords if keyword in query_lower)
        keyword_score = min(keyword_matches * 0.3, 1.0)
        
        # Check for question patterns
        question_patterns = [
            r'^how\s+to\s+',
            r'^what\s+is\s+',
            r'^where\s+is\s+',
            r'^when\s+',
            r'^why\s+',
            r'help.*with',
            r'need.*help',
            r'customer.*care',
            r'contact.*number'
        ]
        
        pattern_score = 0.0
        for pattern in question_patterns:
            if re.search(pattern, query_lower):
                pattern_score = 0.8
                break
        
        # If no specific financial agent can handle it well, support agent can help
        confidence = max(keyword_score, pattern_score)
        
        # Support agent acts as fallback with moderate confidence
        if confidence < 0.3:
            confidence = 0.4  # Fallback confidence
        
        self.logger.info(f"Support agent confidence: {confidence} for query: {query.query_text[:50]}...")
        return confidence
    
    async def process_query(self, query: UserQuery) -> AgentResponse:
        """Process support-related queries"""
        try:
            query_lower = query.query_text.lower()
            
            # Contact information
            if any(word in query_lower for word in ['contact', 'phone', 'number', 'customer care']):
                return await self._handle_contact_info(query)
            
            # Branch/ATM locations
            elif any(word in query_lower for word in ['branch', 'atm', 'location', 'address', 'near me']):
                return await self._handle_location_info(query)
            
            # App/digital services help
            elif any(word in query_lower for word in ['app', 'download', 'install', 'internet banking', 'online']):
                return await self._handle_digital_help(query)
            
            # Security related
            elif any(word in query_lower for word in ['secure', 'safety', 'fraud', 'scam', 'otp']):
                return await self._handle_security_help(query)
            
            # Complaints and feedback
            elif any(word in query_lower for word in ['complaint', 'feedback', 'problem', 'issue']):
                return await self._handle_complaint_feedback(query)
            
            # General FAQ
            elif any(word in query_lower for word in ['how to', 'what is', 'where is', 'when', 'why']):
                return await self._handle_general_faq(query)
            
            # Working hours
            elif any(word in query_lower for word in ['hours', 'time', 'open', 'close', 'timing']):
                return await self._handle_working_hours(query)
            
            else:
                return await self._handle_general_support(query)
                
        except Exception as e:
            self.logger.error(f"Error processing support query: {str(e)}")
            return AgentResponse(
                agent_name=self.agent_name,
                response_text="I'm sorry, I encountered an error. Please contact our customer care at 1800-XXX-XXXX for immediate assistance.",
                confidence=0.5
            )
    
    async def _handle_contact_info(self, query: UserQuery) -> AgentResponse:
        """Handle contact information requests"""
        response_text = "📞 Contact Information:\n\n"
        response_text += f"Customer Care: {self.contact_info['customer_care']}\n"
        response_text += f"Email: {self.contact_info['email']}\n"
        response_text += f"Website: {self.contact_info['website']}\n"
        response_text += f"Emergency: {self.contact_info['emergency']}\n\n"
        
        response_text += f"🕒 Working Hours:\n{self.contact_info['working_hours']}\n\n"
        
        response_text += "📱 Other Ways to Reach Us:\n"
        response_text += "• Mobile App: Use 'Chat Support' feature\n"
        response_text += "• Social Media: @SamsungPrismBank\n"
        response_text += "• Visit any branch for in-person assistance\n\n"
        
        response_text += "💡 For faster service:\n"
        response_text += "• Keep your account number ready\n"
        response_text += "• Use the mobile app for common queries\n"
        response_text += "• Check our FAQ section first"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.95,
            action_taken="contact_info"
        )
    
    async def _handle_location_info(self, query: UserQuery) -> AgentResponse:
        """Handle branch/ATM location requests"""
        response_text = "📍 Branch & ATM Locations:\n\n"
        
        response_text += "🏦 Find Nearest Branch:\n"
        response_text += "• Mobile App: 'Locate Us' → 'Branches'\n"
        response_text += "• Website: Branch Locator tool\n"
        response_text += "• Google Maps: Search 'Samsung Prism Bank'\n"
        response_text += "• Call: 1800-XXX-XXXX for directions\n\n"
        
        response_text += "🏧 ATM Network:\n"
        response_text += "• 5000+ ATMs across the country\n"
        response_text += "• Partnership with other banks for cash withdrawals\n"
        response_text += "• Use ATM locator in mobile app\n"
        response_text += "• Available 24/7 for your convenience\n\n"
        
        response_text += "🕒 Branch Timings:\n"
        response_text += "• Monday-Friday: 10:00 AM - 4:00 PM\n"
        response_text += "• Saturday: 10:00 AM - 2:00 PM\n"
        response_text += "• Sunday: Closed\n"
        response_text += "• 2nd & 4th Saturday: Closed\n\n"
        
        response_text += "📋 Services at Branch:\n"
        response_text += "• Account opening & closure\n"
        response_text += "• Loan applications\n"
        response_text += "• Fixed deposits\n"
        response_text += "• Demat services\n"
        response_text += "• Locker facilities"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken="location_info"
        )
    
    async def _handle_digital_help(self, query: UserQuery) -> AgentResponse:
        """Handle digital services help"""
        query_lower = query.query_text.lower()
        
        if 'app' in query_lower or 'download' in query_lower:
            response_text = "📱 Samsung Prism Mobile App:\n\n"
            response_text += "Download Links:\n"
            response_text += "• Android: Google Play Store\n"
            response_text += "• iOS: Apple App Store\n"
            response_text += "• Search: 'Samsung Prism Bank'\n\n"
            
            response_text += "App Features:\n"
            response_text += "• Balance inquiry & mini statements\n"
            response_text += "• Fund transfers & bill payments\n"
            response_text += "• Card management\n"
            response_text += "• Loan applications\n"
            response_text += "• Investment services\n\n"
            
            response_text += "First Time Setup:\n"
            response_text += "1. Download and install the app\n"
            response_text += "2. Register with account number and mobile\n"
            response_text += "3. Verify with OTP\n"
            response_text += "4. Set login PIN/biometric\n"
            response_text += "5. Start banking!"
            
        elif 'internet banking' in query_lower or 'online' in query_lower:
            response_text = "💻 Internet Banking:\n\n"
            response_text += "Registration Process:\n"
            response_text += "1. Visit our website\n"
            response_text += "2. Click 'Register for Internet Banking'\n"
            response_text += "3. Enter account number and registered mobile\n"
            response_text += "4. Verify with OTP\n"
            response_text += "5. Set username and password\n\n"
            
            response_text += "Features Available:\n"
            response_text += "• Account statements and transaction history\n"
            response_text += "• Fund transfers and NEFT/RTGS\n"
            response_text += "• Bill payments and recharges\n"
            response_text += "• Tax payments and form downloads\n"
            response_text += "• Investment and insurance services\n\n"
            
            response_text += "Security Tips:\n"
            response_text += "• Never share login credentials\n"
            response_text += "• Always logout after use\n"
            response_text += "• Use secure networks only\n"
            response_text += "• Enable transaction alerts"
            
        else:
            response_text = "🔧 Digital Services Help:\n\n"
            response_text += "Available Services:\n"
            response_text += "• Mobile Banking App\n"
            response_text += "• Internet Banking\n"
            response_text += "• SMS Banking\n"
            response_text += "• WhatsApp Banking\n"
            response_text += "• Phone Banking\n\n"
            
            response_text += "Need Help With:\n"
            response_text += "• Registration and setup\n"
            response_text += "• Password reset\n"
            response_text += "• Transaction issues\n"
            response_text += "• App troubleshooting\n\n"
            
            response_text += "Contact Digital Support:\n"
            response_text += "• Call: 1800-XXX-DIGITAL\n"
            response_text += "• Chat: Use app's help section\n"
            response_text += "• Email: digital@samsungprism.com"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken="digital_help"
        )
    
    async def _handle_security_help(self, query: UserQuery) -> AgentResponse:
        """Handle security-related help"""
        response_text = "🔒 Banking Security Guidelines:\n\n"
        
        response_text += "🛡️ Keep Your Account Safe:\n"
        response_text += "• Never share PIN, password, or OTP\n"
        response_text += "• Bank will never ask for credentials over phone/email\n"
        response_text += "• Always verify bank communications\n"
        response_text += "• Use official bank app/website only\n"
        response_text += "• Enable account alerts and notifications\n\n"
        
        response_text += "⚠️ Red Flags - Be Alert:\n"
        response_text += "• Unexpected SMS/calls asking for bank details\n"
        response_text += "• Emails asking to 'verify' account information\n"
        response_text += "• Suspicious links or fake bank websites\n"
        response_text += "• Requests for remote access to your device\n\n"
        
        response_text += "🚨 If You Suspect Fraud:\n"
        response_text += "1. Immediately call our fraud helpline: 1800-XXX-FRAUD\n"
        response_text += "2. Block your cards using mobile app\n"
        response_text += "3. Change all banking passwords\n"
        response_text += "4. Check account statements for unauthorized transactions\n"
        response_text += "5. File a complaint with local police if needed\n\n"
        
        response_text += "💡 Security Features:\n"
        response_text += "• Two-factor authentication\n"
        response_text += "• Biometric login\n"
        response_text += "• Transaction limits\n"
        response_text += "• Real-time SMS alerts\n"
        response_text += "• Secure 256-bit encryption"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.95,
            action_taken="security_help"
        )
    
    async def _handle_complaint_feedback(self, query: UserQuery) -> AgentResponse:
        """Handle complaints and feedback"""
        response_text = "📝 Complaints & Feedback:\n\n"
        
        response_text += "🎯 How to Register a Complaint:\n"
        response_text += "1. 📱 Mobile App: 'Help' → 'Complaints'\n"
        response_text += "2. 📞 Customer Care: 1800-XXX-XXXX\n"
        response_text += "3. 💻 Website: Complaint Registration Form\n"
        response_text += "4. 📧 Email: complaints@samsungprism.com\n"
        response_text += "5. 🏦 Visit any branch\n\n"
        
        response_text += "📋 Information Required:\n"
        response_text += "• Account number\n"
        response_text += "• Transaction details (if applicable)\n"
        response_text += "• Date and time of incident\n"
        response_text += "• Description of issue\n"
        response_text += "• Contact information\n\n"
        
        response_text += "⏱️ Resolution Timeline:\n"
        response_text += "• ATM/Card issues: Within 7 working days\n"
        response_text += "• Account-related: Within 15 working days\n"
        response_text += "• Complex issues: Within 30 working days\n"
        response_text += "• You'll receive regular updates via SMS/email\n\n"
        
        response_text += "📈 Escalation Process:\n"
        response_text += "• Level 1: Customer Care (immediate)\n"
        response_text += "• Level 2: Branch Manager (3 days)\n"
        response_text += "• Level 3: Regional Manager (7 days)\n"
        response_text += "• External: Banking Ombudsman\n\n"
        
        response_text += "💬 Feedback:\n"
        response_text += "We value your feedback! Share your experience at:\n"
        response_text += "feedback@samsungprism.com or use app's feedback section."
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken="complaint_feedback"
        )
    
    async def _handle_general_faq(self, query: UserQuery) -> AgentResponse:
        """Handle general FAQ requests"""
        query_lower = query.query_text.lower()
        
        # Try to match with common FAQs
        if 'open account' in query_lower or 'new account' in query_lower:
            response_text = "💳 Opening a New Account:\n\n"
            response_text += "Required Documents:\n"
            response_text += "• PAN Card (mandatory)\n"
            response_text += "• Aadhaar Card\n"
            response_text += "• Address proof (utility bill/rent agreement)\n"
            response_text += "• Salary certificate/Income proof\n"
            response_text += "• 2 passport size photographs\n\n"
            
            response_text += "Process:\n"
            response_text += "1. Visit nearest branch or apply online\n"
            response_text += "2. Fill account opening form\n"
            response_text += "3. Submit documents\n"
            response_text += "4. Initial deposit (minimum ₹1,000)\n"
            response_text += "5. Account activated within 2-3 days\n\n"
            
            response_text += "Account Types Available:\n"
            response_text += "• Savings Account (Regular/Premium)\n"
            response_text += "• Current Account (Business)\n"
            response_text += "• Salary Account\n"
            response_text += "• Senior Citizen Account"
            
        elif 'update' in query_lower and any(x in query_lower for x in ['mobile', 'phone', 'number', 'address']):
            response_text = "📝 Update Contact Information:\n\n"
            response_text += "Update Mobile Number:\n"
            response_text += "• Visit branch with ID proof\n"
            response_text += "• Fill form for mobile number update\n"
            response_text += "• Verification call will be made\n"
            response_text += "• New number activated within 24 hours\n\n"
            
            response_text += "Update Address:\n"
            response_text += "• Submit new address proof\n"
            response_text += "• Fill address change form\n"
            response_text += "• Bank verification may be required\n"
            response_text += "• Updated address effective immediately\n\n"
            
            response_text += "Online Updates:\n"
            response_text += "• Some updates possible through mobile app\n"
            response_text += "• Email updates can be done online\n"
            response_text += "• Major changes require branch visit"
            
        else:
            response_text = "❓ Frequently Asked Questions:\n\n"
            
            response_text += "📋 General Banking:\n"
            for faq in self.faq_categories['general'][:3]:
                response_text += f"• {faq}\n"
            
            response_text += "\n💻 Digital Services:\n"
            for faq in self.faq_categories['digital'][:3]:
                response_text += f"• {faq}\n"
            
            response_text += "\n🔒 Security:\n"
            for faq in self.faq_categories['security'][:3]:
                response_text += f"• {faq}\n"
            
            response_text += "\n\n💡 Need specific help? Please ask your question clearly, and I'll provide detailed assistance!"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.85,
            action_taken="general_faq"
        )
    
    async def _handle_working_hours(self, query: UserQuery) -> AgentResponse:
        """Handle working hours inquiries"""
        response_text = "🕒 Working Hours & Availability:\n\n"
        
        response_text += "🏦 Branch Timings:\n"
        response_text += "• Monday to Friday: 10:00 AM - 4:00 PM\n"
        response_text += "• Saturday: 10:00 AM - 2:00 PM\n"
        response_text += "• Sunday: Closed\n"
        response_text += "• 2nd & 4th Saturday: Closed\n\n"
        
        response_text += "📞 Customer Care:\n"
        response_text += "• 24/7 availability\n"
        response_text += "• Phone: 1800-XXX-XXXX\n"
        response_text += "• Emergency: 1800-XXX-EMERGENCY\n\n"
        
        response_text += "🏧 ATM Services:\n"
        response_text += "• Available 24/7\n"
        response_text += "• Cash withdrawal anytime\n"
        response_text += "• Balance inquiry\n"
        response_text += "• Mini statement\n\n"
        
        response_text += "📱 Digital Services:\n"
        response_text += "• Mobile app: 24/7\n"
        response_text += "• Internet banking: 24/7\n"
        response_text += "• NEFT/RTGS: As per RBI timings\n"
        response_text += "• IMPS: 24/7\n\n"
        
        response_text += "🎯 Best Time to Visit:\n"
        response_text += "• Avoid 1st and last week of month\n"
        response_text += "• Morning hours are less crowded\n"
        response_text += "• Book appointment for loan consultations"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.9,
            action_taken="working_hours"
        )
    
    async def _handle_general_support(self, query: UserQuery) -> AgentResponse:
        """Handle general support requests"""
        response_text = "🎯 General Support:\n\n"
        
        response_text += "I'm here to help you with:\n"
        response_text += "• Banking procedures and processes\n"
        response_text += "• Contact information and locations\n"
        response_text += "• Digital services setup and troubleshooting\n"
        response_text += "• Security guidelines and fraud prevention\n"
        response_text += "• Complaint registration and feedback\n"
        response_text += "• General banking FAQs\n\n"
        
        response_text += "🔄 For specific banking needs:\n"
        response_text += "• Account and transactions → Ask about balance or transactions\n"
        response_text += "• Loans and EMI → Ask about loan eligibility or EMI\n"
        response_text += "• Cards → Ask about card limits or activation\n\n"
        
        response_text += "📞 Need immediate assistance?\n"
        response_text += f"• Customer Care: {self.contact_info['customer_care']}\n"
        response_text += f"• Email: {self.contact_info['email']}\n"
        response_text += "• Visit nearest branch\n\n"
        
        response_text += "💬 How can I assist you better? Please feel free to ask any specific question!"
        
        return AgentResponse(
            agent_name=self.agent_name,
            response_text=response_text,
            confidence=0.7,
            action_taken="general_support"
        )
    
    def get_capabilities(self) -> List[str]:
        """Return list of agent capabilities"""
        return [
            "Contact information and customer care",
            "Branch and ATM locations",
            "Mobile app and internet banking help",
            "Security guidelines and fraud prevention",
            "Complaint registration and feedback",
            "General banking FAQs",
            "Working hours and availability",
            "Account opening procedures",
            "Digital services troubleshooting",
            "Banking policies and procedures"
        ]
