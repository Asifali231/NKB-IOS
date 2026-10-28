# Cloud Functions Configuration

The Cloud Functions source does not contain Play Console or SMTP credentials.
Manage the Play Console contact address in Play Console, separately from
transactional email delivery.

Configure these values in an untracked Firebase Functions environment file or
the deployment environment:

```text
SMTP_USER=
SMTP_PASSWORD=
JAZZCASH_MERCHANT_ID=
JAZZCASH_PASSWORD=
JAZZCASH_INTEGRITY_SALT=
```

The payment endpoints fail explicitly when JazzCash credentials are missing.
SMTP credentials are required when sending transaction email.

Do not commit environment files or credentials. If credentials were previously
stored in source or documentation, rotate them before deploying.
