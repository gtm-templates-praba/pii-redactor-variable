___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "PII Redactor",
  "description": "Replace sensitive data (names, emails, address etc) with the string [*redacted*] from URLs. Choose page_location, page_referrer, or your custom input. Select predefined values or define your own.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "GROUP",
    "name": "urIInput",
    "displayName": "",
    "groupStyle": "NO_ZIPPY",
    "subParams": [
      {
        "type": "RADIO",
        "name": "urlInputRadioButtonGroup",
        "radioItems": [
          {
            "value": "pageLocation",
            "displayValue": "Page Location",
            "help": "page_location from event data object"
          },
          {
            "value": "pageReferrer",
            "displayValue": "Page Referrer",
            "help": "page_referrer from event data object"
          },
          {
            "value": "custom",
            "displayValue": "Custom",
            "subParams": [
              {
                "type": "TEXT",
                "name": "customUrl",
                "simpleValueType": true,
                "valueHint": "https://"
              }
            ],
            "help": ""
          }
        ],
        "simpleValueType": true,
        "defaultValue": "pageLocation",
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          }
        ]
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "queryStringInput",
    "displayName": "Query strings to redact (case-insensitive)",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "GROUP",
        "name": "defaultQueryStringCheckboxGroup",
        "displayName": "",
        "groupStyle": "NO_ZIPPY",
        "subParams": [
          {
            "type": "CHECKBOX",
            "name": "name",
            "checkboxText": "Name",
            "simpleValueType": true,
            "help": "Matching values: name, firstName, lastName, fullName"
          },
          {
            "type": "CHECKBOX",
            "name": "email",
            "checkboxText": "Email",
            "simpleValueType": true,
            "help": "Matching values: email, e-mail, mail"
          },
          {
            "type": "CHECKBOX",
            "name": "phone",
            "checkboxText": "Phone",
            "simpleValueType": true,
            "help": "Matching values: phone, phoneNumber, mobile, tel"
          },
          {
            "type": "CHECKBOX",
            "name": "address",
            "checkboxText": "Address",
            "simpleValueType": true,
            "help": "Matching values: address, streetAddress, addressLine1, addressLine2"
          },
          {
            "type": "CHECKBOX",
            "name": "location",
            "checkboxText": "Location",
            "simpleValueType": true,
            "help": "Matching values: city, state, zip, zipCode, postalCode, country"
          },
          {
            "type": "CHECKBOX",
            "name": "payment",
            "checkboxText": "Payment Information",
            "simpleValueType": true,
            "help": "Matching values: creditCard, cardNumber, ccNumber, cvv, expDate"
          },
          {
            "type": "CHECKBOX",
            "name": "identifiers",
            "checkboxText": "Government Identifiers",
            "simpleValueType": true,
            "help": "Matching values: ssn, socialSecurity, taxId, passport, driverLicense"
          },
          {
            "type": "CHECKBOX",
            "name": "userAccount",
            "checkboxText": "User Account",
            "simpleValueType": true,
            "help": "Matching values: username, password, accountId, userId, login"
          },
          {
            "type": "CHECKBOX",
            "name": "healthInfo",
            "checkboxText": "Health Information",
            "simpleValueType": true,
            "help": "Matching values: medicalId, insuranceId, healthPlan, condition"
          },
          {
            "type": "CHECKBOX",
            "name": "demographics",
            "checkboxText": "Demographics",
            "simpleValueType": true,
            "help": "Matching values: age, gender, dob, dateOfBirth, birthDate"
          }
        ]
      },
      {
        "type": "SIMPLE_TABLE",
        "name": "customQueryStringsTable",
        "simpleTableColumns": [
          {
            "defaultValue": "",
            "displayName": "Add custom query strings",
            "name": "customQueryStringsColumn",
            "type": "TEXT"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

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
const main = function(data) {
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
  return url.indexOf(URL_PROTOCOL_HTTP) === 0 || url.indexOf(URL_PROTOCOL_HTTPS) === 0;
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
    paramsToRedact.push('address', 'streetaddress', 'addressline1', 'addressline2');
  }
  
  if (data.location) {
    paramsToRedact.push('city', 'state', 'zip', 'zipcode', 'postalcode', 'country');
  }
  
  if (data.payment) {
    paramsToRedact.push('creditcard', 'cardnumber', 'ccnumber', 'cvv', 'expdate');
  }
  
  if (data.identifiers) {
    paramsToRedact.push('ssn', 'socialsecurity', 'taxid', 'passport', 'driverlicense');
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
  if (data.customQueryStringsTable && getType(data.customQueryStringsTable) === 'array') {
    const customParamsTable = makeTableMap(data.customQueryStringsTable, 'customQueryStringsColumn', 'customQueryStringsColumn');
    
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
  return baseUrl + (finalParams.length ? '?' + finalParams.join('&') : '') + hash;
}

// Processes a single parameter and adds it to the finalParams array.
function processParameter(key, value, shouldRedact, finalParams) {
  const encodedKey = enc(key);
  
  getType(value) === 'array' 
    ? value.forEach(function(item) {
        finalParams.push(encodedKey + '=' + (shouldRedact ? REDACTED_STRING : enc(item)));
      })
    : finalParams.push(encodedKey + '=' + (shouldRedact ? REDACTED_STRING : enc(value)));
}

// Export the main function
return main(data);


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

@author: Praba Ponnambalam (praba@measureschool.com)
@released on: 2025/03/26


