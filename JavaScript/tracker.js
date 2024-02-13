<script>
function myriads_isValueETHERC20WalletAddress(value) {
  // Starts from '0x' and contains 42 symbols total.
  var result = /^0x[0-9a-fA-F]{40}$/.test(address);
  return result;
}
  
function myriads_isValueWalletAddress(value) {
  return myriads_isValueETHERC20WalletAddress(value);
}
  
function myriads_trackInputChanges() {
  var google_analytics_client_id = myriads_getClientGoogleAnalyticsId();
  console.log('[MYRIADS] - Loaded user Google Analytics ID: ', google_analytics_client_id);
  
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
  
  myriads_trackInputChanges();
});
</script>
