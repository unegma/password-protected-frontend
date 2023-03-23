For this one, run terraform first, and then upload manually to the bucket from the s3 directory

need to add a record to cloudflare (as well as certificate stuff):
CNAME disaster idofthe.cloudfront.net DNS only

* before deploying, TERRAFORM MUST BE USED TO CREATE THE BUCKET (can upload with the script in the s3 folder later)

## Certificate adding:

* Create certificate for *unegma.digital (in us-east-1) (will update to eligible for renewal when attaching cloudfront)
* dns validation (remove the . at the end of both cname records)
* copy the id into terraform variables

* Don't do this or it won't work ~~might want to change cloudfront: origins -> edit -> use website endpoint (will redeploying wipe this out??)~~

* cloudflare needs to direct to the cloudfront url
- and be dns only (not proxied)

* todo might be an issue with the bucket config (getting access denied error when logging in)
- might need to create an invalidation?
- does it continue to last or do invalidations need to be created often??
