/**
 * BASIC Authentication
 *
 * Simple authentication script intended to be run by Amazon Lambda to
 * provide Basic HTTP Authentication for a static website hosted in an
 * Amazon S3 bucket through Couldfront.
 *
 * https://hackernoon.com/serverless-password-protecting-a-static-website-in-an-aws-s3-bucket-bfaaa01b8666
 * https://austinlasseter.medium.com/build-a-password-protected-website-using-aws-lambda-and-cloudfront-3743cc4d09b6
 */

'use strict';

const {
  AWS_FUNCTION_NAME,
  AWS_REGION,
  AUTH_USER,
  AUTH_PASS,
}: any = process.env;

export const handler = (event: any, context: any = {}, callback: any): any => {

  // Get request and request headers
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // Configure authentication
  const authUser = AUTH_USER;
  const authPass = AUTH_PASS;
  //const authPass = Buffer.from("Y2xhcml0eTE0O......SE=", 'base64').toString('ascii');


  // Construct the Basic Auth string
  const authString = 'Basic ' + new Buffer(authUser + ':' + authPass).toString('base64');

  // Require Basic authentication
  if (typeof headers.authorization == 'undefined' || headers.authorization[0].value != authString) {
    const body = 'Unauthorized';
    const response = {
      status: '401',
      statusDescription: 'Unauthorized',
      body: body,
      headers: {
        'www-authenticate': [{key: 'WWW-Authenticate', value:'Basic'}]
      },
    };
    callback(null, response);
  }

  // Continue request processing if authentication passed
  callback(null, request); //
};
