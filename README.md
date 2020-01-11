# ProFTPD Log Analyzer (PFLA)

A simple Perl script reading [ProFTPD](http://www.proftpd.org/) log files
and generating summarized report for all containing:
  * in/out transfer statistics;
  * in/out/deleted files counts;
  * transfer type binary/ASCII counts;
  * user type counts.
The report template could be customized, but variables (starting with dollar
sign) must be kept, so the script could replace them with data.

