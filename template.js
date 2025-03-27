// APIs
const decodeUriComponent = require('decodeUriComponent');
const encodeUriComponent = require('encodeUriComponent');
const getEventData = require('getEventData');
const getType = require('getType');
const makeTableMap = require('makeTableMap');
const parseUrl = require('parseUrl');

// Constants
const REDACTED_STRING = '[*redacted*]';
const URL_PROTOCOL_HTTP = 'http%3A';
const URL_PROTOCOL_HTTPS = 'https%3A';
const URL_SOURCE_PAGE_LOCATION = 'pageLocation';
const URL_SOURCE_PAGE_REFERRER = 'pageReferrer';
const URL_SOURCE_CUSTOM = 'custom';

// Helper function for URI encoding
function enc(data) {
  data = data || '';
  return encodeUriComponent(data);
}

// Main function that processes the URL and redacts specified query parameters.
const main = function (data) {
  // Get the URL based on the selected input option
  const url = getUrlFromInput(data);

  // Return early if URL is empty
  if (!url) return '';

  // Check if the entire URL is encoded and decode if needed
  const isFullyEncoded = isUrlFullyEncoded(url);
  const decodedUrl = isFullyEncoded ? decodeUriComponent(url) : url;

  // Parse the URL
  const parsedUrl = parseUrl(decodedUrl);
  if (!parsedUrl) return url;

  // Collect parameters to redact
  const paramsToRedact = collectParamsToRedact(data);

  // Return original URL if no parameters to redact
  if (paramsToRedact.length === 0) return url;

  // Process the URL and create redacted version
  const result = processUrl(parsedUrl, paramsToRedact);

  // Re-encode the URL if the input was fully encoded
  return isFullyEncoded ? encodeUriComponent(result) : result;
};

// Gets the URL from the input based on the selected option.
function getUrlFromInput(data) {
  const urlSource = data.urlInputRadioButtonGroup;
  const customUrl = data.customUrl;

  if (urlSource === URL_SOURCE_PAGE_LOCATION) {
    return getEventData('page_location') || '';
  } else if (urlSource === URL_SOURCE_PAGE_REFERRER) {
    return getEventData('page_referrer') || '';
  } else if (urlSource === URL_SOURCE_CUSTOM) {
    return customUrl || '';
  }
  return '';
}

// Checks if a URL is fully encoded.
function isUrlFullyEncoded(url) {
  return (
    url.indexOf(URL_PROTOCOL_HTTP) === 0 ||
    url.indexOf(URL_PROTOCOL_HTTPS) === 0
  );
}

// Collects all parameters that should be redacted.
function collectParamsToRedact(data) {
  const paramsToRedact = [];

  // Add default parameters if selected
  if (data.name) {
    paramsToRedact.push('name', 'firstname', 'lastname', 'fullname');
  }

  if (data.email) {
    paramsToRedact.push('email', 'e-mail', 'mail');
  }

  if (data.phone) {
    paramsToRedact.push('phone', 'phonenumber', 'mobile', 'tel');
  }

  if (data.address) {
    paramsToRedact.push(
      'address',
      'streetaddress',
      'addressline1',
      'addressline2',
    );
  }

  if (data.location) {
    paramsToRedact.push(
      'city',
      'state',
      'zip',
      'zipcode',
      'postalcode',
      'country',
    );
  }

  if (data.payment) {
    paramsToRedact.push(
      'creditcard',
      'cardnumber',
      'ccnumber',
      'cvv',
      'expdate',
    );
  }

  if (data.identifiers) {
    paramsToRedact.push(
      'ssn',
      'socialsecurity',
      'taxid',
      'passport',
      'driverlicense',
    );
  }

  if (data.userAccount) {
    paramsToRedact.push('username', 'password', 'accountid', 'userid', 'login');
  }

  if (data.healthInfo) {
    paramsToRedact.push('medicalid', 'insuranceid', 'healthplan', 'condition');
  }

  if (data.demographics) {
    paramsToRedact.push('age', 'gender', 'dob', 'dateofbirth', 'birthdate');
  }

  // Add custom parameters from the table
  if (
    data.customQueryStringsTable &&
    getType(data.customQueryStringsTable) === 'array'
  ) {
    const customParamsTable = makeTableMap(
      data.customQueryStringsTable,
      'customQueryStringsColumn',
      'customQueryStringsColumn',
    );

    for (const key in customParamsTable) {
      const param = customParamsTable[key];
      if (param && getType(param) === 'string') {
        // Decode in case the parameter was entered encoded, then convert to lowercase
        paramsToRedact.push(decodeUriComponent(param).toLowerCase());
      }
    }
  }

  return paramsToRedact;
}

// Processes the URL and creates a redacted version.
function processUrl(parsedUrl, paramsToRedact) {
  // Extract URL components directly from parsedUrl (simplified variable declaration)
  const baseUrl = parsedUrl.origin + parsedUrl.pathname;
  const hash = parsedUrl.hash || '';
  const searchParams = parsedUrl.searchParams;
  const finalParams = [];

  // Process each search parameter
  for (const key in searchParams) {
    // Skip non-parameter properties or internal properties
    if (getType(key) !== 'string' || key.charAt(0) === '_') continue;

    // Check if this parameter should be redacted
    const decodedKey = decodeUriComponent(key).toLowerCase();
    let shouldRedact = paramsToRedact.indexOf(decodedKey) !== -1;

    // Process the parameter based on its type
    processParameter(key, searchParams[key], shouldRedact, finalParams);
  }

  // Build the final URL with all parameters (simplified with ternary)
  return (
    baseUrl + (finalParams.length ? '?' + finalParams.join('&') : '') + hash
  );
}

// Processes a single parameter and adds it to the finalParams array.
function processParameter(key, value, shouldRedact, finalParams) {
  const encodedKey = enc(key);

  getType(value) === 'array'
    ? value.forEach(function (item) {
        finalParams.push(
          encodedKey + '=' + (shouldRedact ? REDACTED_STRING : enc(item)),
        );
      })
    : finalParams.push(
        encodedKey + '=' + (shouldRedact ? REDACTED_STRING : enc(value)),
      );
}

// Export the main function
return main(data);
