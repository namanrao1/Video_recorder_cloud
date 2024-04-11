// // Download the helper library from https://www.twilio.com/docs/node/install
// // Set environment variables for your credentials
// // Read more at http://twil.io/secure
// const accountSid = "ACd1bf45f491869a2573bc0859700a6661";
// const authToken = "813ed4c5d36249d0a5553f0def929919";
// const verifySid = "VA894ffee703ef7341a9ab40b2771e6c60";
// const client = require("twilio")(accountSid, authToken);
//
// client.verify.v2
//     .services(verifySid)
//     .verifications.create({ to: "+917447628678", channel: "sms" })
//     .then((verification) => console.log(verification.status))
//     .then(() => {
// const readline = require("readline").createInterface({
// input: process.stdin,
// output: process.stdout,
// });
// readline.question("Please enter the OTP:", (otpCode) => {
// client.verify.v2
//     .services(verifySid)
//     .verificationChecks.create({ to: "+917447628678", code: otpCode })
//     .then((verification_check) => console.log(verification_check.status))
//     .then(() => readline.close());
// });
// });
//
//
// $url = "https://verify.twilio.com/v2/Services/VA894ffee703ef7341a9ab40b2771e6c60/Verifications"
// $params = @{ To = "+917447628678"; Channel = "sms" }
//
// $secret = "813ed4c5d36249d0a5553f0def929919" | ConvertTo-SecureString -asPlainText -Force
// $credential = New-Object System.Management.Automation.PSCredential("ACd1bf45f491869a2573bc0859700a6661", $secret)
//
// Invoke-WebRequest $url -Method Post -Credential $credential -Body $params -UseBasicParsing |
// ConvertFrom-Json | Select sid, body
//
// $checkUrl = "https://verify.twilio.com/v2/Services/VA894ffee703ef7341a9ab40b2771e6c60/VerificationCheck"
//
// $otp = Read-Host "Please enter the OTP:"
//
// $checkParams = @{ To = "+917447628678"; Code = $otp }
// Invoke-WebRequest $checkUrl -Method Post -Credential $credential -Body $checkParams -UseBasicParsing |
// ConvertFrom-Json | Select sid, body







import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
// Replace these values with your Twilio Account SID, Auth Token, and Verify Service SID
final accountSid = 'ACd1bf45f491869a2573bc0859700a6661';
final authToken = '813ed4c5d36249d0a5553f0def929919';

final verifySid = 'VA894ffee703ef7341a9ab40b2771e6c60';

// Replace this with the phone number you want to send the verification code to
final phoneNumber = '+917447628678';

// Step 1: Send the verification code
final sendUrl = 'https://verify.twilio.com/v2/Services/$verifySid/Verifications';
final sendResponse = await http.post(
Uri.parse(sendUrl),
headers: {
HttpHeaders.authorizationHeader: 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
},
body: {
'To': phoneNumber,
'Channel': 'sms',
},
);

if (sendResponse.statusCode == 201) {
print('Verification code sent to $phoneNumber');
} else {
print('Failed to send verification code');
print('Status Code: ${sendResponse.statusCode}');
print('Response Body: ${sendResponse.body}');
return;
}

// Step 2: Verify the OTP code
final otpCode = await promptForOTP();
if (otpCode == null || otpCode.isEmpty) {
print('Invalid OTP code');
return;
}

final verifyUrl = 'https://verify.twilio.com/v2/Services/$verifySid/VerificationChecks';
final verifyResponse = await http.post(
Uri.parse(verifyUrl),
headers: {
HttpHeaders.authorizationHeader: 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
},
body: {
'To': phoneNumber,
'Code': otpCode,
},
);

if (verifyResponse.statusCode == 200) {
final responseData = jsonDecode(verifyResponse.body);
print('Verification Status: ${responseData['status']}');
} else {
print('Failed to verify OTP code');
print('Status Code: ${verifyResponse.statusCode}');
print('Response Body: ${verifyResponse.body}');
}
}

Future<String?> promptForOTP() async {
stdout.write('Please enter the OTP: ');
return stdin.readLineSync();
}
