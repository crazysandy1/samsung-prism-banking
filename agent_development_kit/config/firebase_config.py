import os
import json
from firebase_admin import credentials, firestore, initialize_app
import firebase_admin
from google.cloud import firestore as fs
from typing import Optional, Dict, Any
import logging

class FirebaseConfig:
    """Firebase configuration and connection manager"""
    
    def __init__(self):
        self.db: Optional[fs.Client] = None
        self.app = None
        self.logger = logging.getLogger(__name__)
        
    def initialize_firebase(self, service_account_path: Optional[str] = None):
        """Initialize Firebase connection"""
        try:
            # Check if already initialized
            if self.db is not None:
                self.logger.info("✅ Firebase already initialized")
                return True
                
            # Get configuration from environment variables
            project_id = os.getenv('FIREBASE_PROJECT_ID') or os.getenv('GOOGLE_CLOUD_PROJECT')
            credentials_path = service_account_path or os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
            
            if not project_id:
                self.logger.error("❌ No project ID found. Set FIREBASE_PROJECT_ID or GOOGLE_CLOUD_PROJECT environment variable")
                return False
            
            # Set the Google Cloud Project environment variable
            os.environ['GOOGLE_CLOUD_PROJECT'] = project_id
            
            # Check if Firebase Admin is already initialized
            if firebase_admin._apps:
                self.logger.info("🔄 Using existing Firebase Admin app")
                self.app = firebase_admin.get_app()
            else:
                if credentials_path and os.path.exists(credentials_path):
                    # Use service account file
                    self.logger.info(f"🔑 Using service account credentials: {credentials_path}")
                    cred = credentials.Certificate(credentials_path)
                    self.app = initialize_app(cred, {
                        'projectId': project_id
                    })
                else:
                    # Use default credentials or environment variables
                    self.logger.info("🔑 Using default credentials")
                    self.app = initialize_app(options={
                        'projectId': project_id
                    })
            
            # Initialize Firestore client with explicit project ID
            try:
                if credentials_path and os.path.exists(credentials_path):
                    self.db = fs.Client.from_service_account_json(credentials_path, project=project_id)
                else:
                    self.db = fs.Client(project=project_id)
            except Exception as fs_error:
                self.logger.warning(f"⚠️ Direct Firestore client failed, using Firebase Admin: {str(fs_error)}")
                self.db = firestore.client()
            
            self.logger.info(f"✅ Firebase initialized successfully for project: {project_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Firebase initialization failed: {str(e)}")
            return False
    
    def get_firestore_client(self) -> fs.Client:
        """Get Firestore client instance"""
        if not self.db:
            raise Exception("Firebase not initialized. Call initialize_firebase() first.")
        return self.db
    
    def test_connection(self) -> bool:
        """Test Firebase connection"""
        try:
            # Try a less privileged operation - just test if we can create a document reference
            # This doesn't require listing all collections
            test_doc_ref = self.db.collection('system_health').document('connection_test')
            
            # Try to get the document (this will work even if the document doesn't exist)
            test_doc = test_doc_ref.get()
            
            print(f"✅ Firebase connection test passed. Connection is working.")
            return True
        except Exception as e:
            print(f"❌ Firebase connection test failed: {str(e)}")
            return False

# Global Firebase instance
firebase_config = FirebaseConfig()

def get_firestore_db() -> fs.Client:
    """Get global Firestore database instance"""
    return firebase_config.get_firestore_client()
