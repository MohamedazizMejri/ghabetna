from fastapi_mail import ConnectionConfig

conf = ConnectionConfig(
    MAIL_USERNAME="mejria817@gmail.com",
    MAIL_PASSWORD="yilv qooz yjrp pjiw",
    MAIL_FROM="mejria817@gmail.com",
    MAIL_PORT=587,
    MAIL_SERVER="smtp.gmail.com",
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
)

