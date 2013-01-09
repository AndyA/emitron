Assumes:
	perl and assorted modules
	python and s3cmd

Setup S3/CloudFront
	Cloudfront needs to have a log-to bucket configured.
	
	A read-only user needs to be created/reused in AIM. The log-ro user
	can safely have its key/secret reset.

Process:
	
Fetch whatever logs needed  (note there is a 'ro log user which can safely have its key/secret reset):

  	s3cmd get  --recursive --exclude='*' s3://thespace-log-live/XXX

where XXX is the bucket name configured in CloudFront (properties). This will fetch all logs. This
can take long as per-bucket transfers are BW limited by AWS. Restrict things a bit with:

  	s3cmd get  --skip-existing --recursive --exclude='*' --include='*2013-01-07*' s3://thespace-log-live/XXX

although you still get  a lengthy wait for the directory listing.

First reparse in just the stuff we need based on the main pid of the event (defaults to the RoH)

     open.pl [directory with gzipped files] [main Pid]] > just.that.pid.log

The json of the canonical ID is fetched - and from that the PIDs of the various versions are decoded.

Beware that the resulting files are NOT ordered - some cloudfront logs are seriously out of sync
anyway - so we're posponing the sorting to much later in the process.

Split these log up into 'vierers' (defined as an IP+UserAgent string combo) with

    cat just.that.pid.log | perl split.pl

Then each of these can be turned into session sequences with

     perl session.pl [ 4 seconds [ file ]] > aggr.csv

which will create .600 files for later reparsing. These can collated with

	perl aggr.pl aggr.cvs




