echo "Retrieving .env file for $APP_NAME ($NODE_ENV)"

if [ "$NODE_ENV" == "production" ]; then
    aws secretsmanager get-secret-value --secret-id "$APP_NAME" > .env
else
    aws secretsmanager get-secret-value --secret-id "$APP_NAME-$NODE_ENV" > .env
fi
