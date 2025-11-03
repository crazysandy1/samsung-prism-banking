import os
import google.generativeai as genai
from typing import Dict, Any, Optional
import logging

class GeminiService:
    """Gemini AI service for intelligent responses"""
    
    def __init__(self):
        self.client = None
        self.model = None
        self.logger = logging.getLogger(__name__)
        self._initialize()
    
    def _initialize(self):
        """Initialize Gemini AI client"""
        try:
            api_key = os.getenv('GEMINI_API_KEY')
            if not api_key:
                self.logger.warning("⚠️ GEMINI_API_KEY not found in environment variables")
                return False
            
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel('gemini-1.5-flash')
            self.logger.info("✅ Gemini AI initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize Gemini AI: {str(e)}")
            return False
    
    async def generate_response(self, prompt: str, context: Optional[Dict[str, Any]] = None) -> str:
        """Generate response using Gemini AI"""
        try:
            if not self.model:
                return "AI service not available"
            
            # Prepare the prompt with context if provided
            full_prompt = prompt
            if context:
                context_str = "\n".join([f"{k}: {v}" for k, v in context.items()])
                full_prompt = f"Context:\n{context_str}\n\nQuery: {prompt}"
            
            response = self.model.generate_content(full_prompt)
            return response.text
            
        except Exception as e:
            self.logger.error(f"❌ Gemini AI generation failed: {str(e)}")
            return "I apologize, but I'm having trouble processing your request right now."
    
    async def analyze_intent(self, query: str) -> Dict[str, Any]:
        """Analyze user intent using Gemini AI"""
        try:
            if not self.model:
                return {"intent": "unknown", "confidence": 0.0}
            
            prompt = f"""
            Analyze the following banking query and extract:
            1. Primary intent (account_inquiry, transaction, loan, card, support)
            2. Confidence level (0.0 to 1.0)
            3. Key entities (amounts, account types, etc.)
            
            Query: "{query}"
            
            Respond in JSON format:
            {{
                "intent": "primary_intent",
                "confidence": 0.0-1.0,
                "entities": {{"key": "value"}},
                "category": "banking_category"
            }}
            """
            
            response = self.model.generate_content(prompt)
            # Parse JSON response (basic implementation)
            import json
            try:
                result = json.loads(response.text)
                return result
            except:
                # Fallback if JSON parsing fails
                return {
                    "intent": "general",
                    "confidence": 0.5,
                    "entities": {},
                    "category": "banking"
                }
                
        except Exception as e:
            self.logger.error(f"❌ Intent analysis failed: {str(e)}")
            return {"intent": "unknown", "confidence": 0.0}
    
    def is_available(self) -> bool:
        """Check if Gemini AI is available"""
        return self.model is not None

# Global Gemini service instance
gemini_service = GeminiService()
