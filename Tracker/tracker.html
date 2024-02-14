<script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore-compat.js"></script>
<script>
  const firebaseConfig = {
    apiKey: "AIzaSyAN41iYxOHkvh4AgXFDXra3eA-KgGLmIwY",
    authDomain: "myriads-39550.firebaseapp.com",
    projectId: "myriads-39550",
    storageBucket: "myriads-39550.appspot.com",
    messagingSenderId: "26798202385",
    appId: "1:26798202385:web:222f46c8fc57dc95639bb0"
  };

  // Initialize Firebase
  const app = firebase.initializeApp(firebaseConfig);
  const firestore = firebase.firestore();
  
  console.log("[MYRIADS] - Firestore initialized");

  function myriads_recordBinding(wallet_id, google_analytics_user_id) {
    console.log("[MYRIADS] - Recording binding: ", wallet_id, google_analytics_user_id);

    var wallet_document_ref = firestore.collection("bindings").doc(wallet_id);
    var wallet_google_analytics_ids_collection_ref = wallet_document_ref.collection("google_analytics_identifiers");

    var messageData = {
      id: google_analytics_user_id,
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    };

    wallet_google_analytics_ids_collection_ref.add(messageData)
      .then(function(docRef) {
        console.log("[MYRIADS] - Binding successfully recorded");
      })
      .catch(function(error) {
        console.error("[MYRIADS] - Failed to record binding:", error);
      });
  }
  
  function myriads_isValueETHERC20WalletAddress(value) {
    // Starts from '0x' and contains 42 symbols total.
    var result = /^0x[0-9a-fA-F]{40}$/.test(value);
    return result;
  }
    
  function myriads_isValueWalletAddress(value) {
    return myriads_isValueETHERC20WalletAddress(value);
  }
    
  function myriads_run() {
    var google_analytics_client_identifiers = myriads_getClientGoogleAnalyticsId();
    console.log('[MYRIADS] - Loaded user Google Analytics ID: ', google_analytics_client_identifiers);
    
    console.log('[MYRIADS] - Enumerating all input fields...');

    var inputFields = document.querySelectorAll('input');
    inputFields.forEach(function(input) {
      console.log('[MYRIADS] - Found input field');

      input.addEventListener('input', function(event) {
        var value = event.target.value;
        console.log('[MYRIADS] - Updated input field: ', value);
        
        var isCryptoWalletAddress = myriads_isValueWalletAddress(value);
        if (isCryptoWalletAddress) {
          console.log('[MYRIADS] - Crypto wallet address detected: ', value);
          
          google_analytics_client_identifiers.forEach(
            function(google_analytics_client_id) {
              myriads_recordBinding(value, google_analytics_client_id);
            }
          )
        }
      });
    });
  }
    
  function myriads_getClientGoogleAnalyticsId() {
    var google_analytics_identifiers = [];
    
    var cookie = {};
    document.cookie.split(';').forEach(function(el) {
      var splitCookie = el.split('=');
      var key = splitCookie[0].trim();
      var value = splitCookie[1];
      
      if (key == "_ga") {
        var google_analytics_client_id = value.substring(6);
        google_analytics_identifiers.push(google_analytics_client_id);
      }
    });
    
    return google_analytics_identifiers;
  }
    
  console.log('[MYRIADS] - Tracking script loaded. Registering for DOM loaded...');

  // Вызываем функцию отслеживания изменений при загрузке страницы
  document.addEventListener('DOMContentLoaded', function() {
    console.log('[MYRIADS] - Page DOM loaded. Starting tracking...');
    
    myriads_run();
  });
</script>
