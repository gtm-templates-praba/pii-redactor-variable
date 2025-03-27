# Server-side GTM PII Redactor Variable Template

This SGTM template variable replaces sensitive data (names, emails, addresses, etc.) with the string `[*redacted*]` from URLs. Choose `page_location`, `page_referrer`, or your custom input. Select predefined values or define your own.

## Configuration Options

### URL Source

- **Page Location**: Uses `page_location` from event data object
- **Page Referrer**: Uses `page_referrer` from event data object
- **Custom URL**: Allows you to specify any URL

### PII Categories

Each category redacts multiple related parameters:

| Category     | Parameters Redacted (Case-insensitive)              |
| ------------ | --------------------------------------------------- |
| Name         | name, firstname, lastname, fullname                 |
| Email        | email, e-mail, mail                                 |
| Phone        | phone, phonenumber, mobile, tel                     |
| Address      | address, streetaddress, addressline1, addressline2  |
| Location     | city, state, zip, zipcode, postalcode, country      |
| Payment      | creditcard, cardnumber, ccnumber, cvv, expdate      |
| Identifiers  | ssn, socialsecurity, taxid, passport, driverlicense |
| User Account | username, password, accountid, userid, login        |
| Health       | medicalid, insuranceid, healthplan, condition       |
| Demographics | age, gender, dob, dateofbirth, birthdate            |

### Custom Parameters

Add any additional parameters not covered by the predefined categories.

## Example Use Case

Use this variable to remove PII from `page_location` & use it in SGTM Transformation to forward the redacted `page_location` to GA4.

Original URL:

```
https://gtm.localserver/?purpose=praba-test&src=test+page&loanAmount=1000&cname=John+Doe&firstName=John&lastname=Doe&email=john.doe%40example.com&streetAddress=123+Main+St&city=New+York&state=NY&zipCode=10001&phoneNumber=1234567890&ctry=USA
```

After processing:

```
https://gtm.localserver/?purpose=praba-test&src=test+page&loanAmount=1000&cname=[*redacted*]&firstName=[*redacted*]&lastname=[*redacted*]&email=[*redacted*]&streetAddress=[*redacted*]&city=[*redacted*]&state=[*redacted*]&zipCode=[*redacted*]&phoneNumber=[*redacted*]&ctry=[*redacted*]
```

### Screenshot

![PII Redactor Configuration](/screenshots/01.png)

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
