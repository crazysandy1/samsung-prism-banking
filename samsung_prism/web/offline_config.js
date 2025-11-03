// Offline configuration for Samsung Prism
window.addEventListener('load', function() {
  console.log('Samsung Prism - Offline configuration loaded');
  
  // Configure fallback fonts
  const style = document.createElement('style');
  style.textContent = `
    @font-face {
      font-family: 'Roboto';
      font-style: normal;
      font-weight: 400;
      src: local('Roboto'), local('Arial'), local('Helvetica'), sans-serif;
      font-display: fallback;
    }
    
    * {
      font-family: 'Roboto', 'Helvetica Neue', Arial, sans-serif !important;
    }
  `;
  document.head.appendChild(style);
  
  // Handle offline state
  function handleOffline() {
    console.log('App is offline - using cached resources');
    document.body.classList.add('offline');
  }
  
  function handleOnline() {
    console.log('App is online');
    document.body.classList.remove('offline');
  }
  
  window.addEventListener('offline', handleOffline);
  window.addEventListener('online', handleOnline);
  
  // Check initial state
  if (!navigator.onLine) {
    handleOffline();
  }
});
